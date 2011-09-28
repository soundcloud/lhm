require 'benchmark'

#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek
#
#  Migrate large tables without downtime by copying to a temporary table in
#  chunks. The old table is not dropped. Instead, it is moved to
#  timestamp_table_name for verification.
#
#  WARNING:
#     - this is an unlocked online operation. updates will probably become
#       inconsistent during migration.
#     - may cause the universe to implode.
#
#  USAGE:
#
#  class AddIndexToEmails < LargeHadronMigration
#    def self.up
#      large_hadron_migrate :emails, :wait => 0.2 do |table_name|
#        execute %Q{
#          alter table %s
#            add index index_emails_on_hashed_address (hashed_address)
#        } % table_name
#      end
#    end
#  end
#
#  How to deploy large hadrons with capistrano
#  -------------------------------------------
#
#  1. Run cap deploy:update_code. The new release directory is not symlinked,
#     so that restarts will not load the new code.
#
#  2. Run rake db:migrate from the new release directory on an appserver,
#     preferably in a screen session.
#
#  3. Wait for migrations to sync to all slaves then cap deploy.
#
#  Restarting before step 2 is done
#  --------------------------------
#
#  - When adding a column
#
#  1. Migration running on master; no effect, nothing has changed.
#  2. Tables switched on master. slave out of sync, migration running.
#     a. Given the app server reads columns from slave on restart, nothing
#        happens.
#     b. Given the app server reads columns from master on restart, bad
#        shitz happen, ie: queries are built with new columns, ie on :include
#        the explicit column list will be built (rather than *) for the
#        included table. Since it does not exist on the slave, queries will
#        break here.
#
#  3. Tables switched on slave
#    -  Same as 2b. Just do a cap deploy instead of cap deploy:restart.
#
#  - When removing a column
#
#  1. Migration running on master; no effect, nothing has changed.
#  2. Tables switched on master. slave out of sync, migration running.
#     a. Given the app server reads columns from slave on restart
#        - Writes against master will fail due to the additional column.
#        - Reads will succeed against slaves, but not master.
#
#     b. Given the app server reads columns from master on restart:
#       - Writes against master might succeed. Old code referencing
#         removed columns will fail.
#       - Reads might or might not succeed, for the same reason.
#
#  tl;dr: Never restart during migrations when removing columns with large
#  hadron. You can restart while adding migrations as long as active record
#  reads column definitions from the slave.
#
#  Pushing out hotfixes while migrating in step 2
#  ----------------------------------------------
#
#  - Check out the currently running (old) code ref.
#  - Branch from this, make your changes, push it up
#  - Deploy this version.
#
#  Deploying the new version will hurt your head. Don't do it.
#
class LargeHadronMigration < ActiveRecord::Migration

  # id_window must be larger than the number of inserts
  # added to the journal table. if this is not the case,
  # inserts will be lost in the replay phase.
  def self.large_hadron_migrate(curr_table, *args, &block)
    opts = args.extract_options!.reverse_merge :wait => 0.5,
        :chunk_size => 35_000,
        :id_window => 11_000

    curr_table = curr_table.to_s
    chunk_size = opts[:chunk_size].to_i

    # we are in dev/test mode - so speed it up
    chunk_size = 10_000_000.to_i if Rails.env.development? or Rails.env.test?
    wait = opts[:wait].to_f
    id_window = opts[:id_window]

    raise "chunk_size must be >= 1" unless chunk_size >= 1

    started = Time.now.strftime("%Y_%m_%d_%H_%M_%S_%3N")
    new_table      = "lhmn_%s" % curr_table
    old_table      = "lhmo_%s_%s" % [started, curr_table]
    journal_table  = "lhmj_%s_%s" % [started, curr_table]

    last_insert_id = last_insert_id(curr_table)
    say "last inserted id in #{curr_table}: #{last_insert_id}"

    begin
      # clean tables. old tables are never deleted to guard against rollbacks.
      execute %Q{drop table if exists %s} % new_table

      clone_table(curr_table, new_table, id_window)
      clone_table_for_changes(curr_table, journal_table)

      # add triggers
      add_trigger_on_action(curr_table, journal_table, "insert")
      add_trigger_on_action(curr_table, journal_table, "update")
      add_trigger_on_action(curr_table, journal_table, "delete")

      # alter new table
      default_values = {}
      yield new_table, default_values

      insertion_columns = prepare_insertion_columns(new_table, curr_table, default_values)
      raise "insertion_columns empty" if insertion_columns.empty?

      chunked_insert \
        last_insert_id,
        chunk_size,
        new_table,
        insertion_columns,
        curr_table,
        wait

      rename_tables curr_table => old_table, new_table => curr_table
      cleanup(curr_table)

      # replay changes from the changes jornal
      replay_insert_changes(curr_table, journal_table, chunk_size, wait)
      replay_update_changes(curr_table, journal_table, chunk_size, wait)
      replay_delete_changes(curr_table, journal_table)

      old_table
    ensure
      cleanup(curr_table)
    end
  end

  def self.prepare_insertion_columns(new_table, table, default_values = {})
    {}.tap do |columns|
      (common_columns(new_table, table) | default_values.keys).each do |column|
        columns[tick(column)] = default_values[column] || tick(column)
      end
    end
  end

  def self.chunked_insert(last_insert_id, chunk_size, new_table, insertion_columns, curr_table, wait, where = "")
    # do the inserts in chunks. helps to reduce io contention and keeps the
    # undo log small.
    chunks = (last_insert_id / chunk_size.to_f).ceil
    times = []
    (1..chunks).each do |chunk|

      times << Benchmark.measure do
        execute "start transaction"

        execute %Q{
          insert into %s
          (%s)
          select %s
          from %s
          where (id between %d and %d) %s

        } % [
          new_table,
          insertion_columns.keys.join(","),
          insertion_columns.values.join(","),
          curr_table,
          ((chunk - 1) * chunk_size) + 1,
          [chunk * chunk_size, last_insert_id].min,
          where
        ]
        execute "COMMIT"
      end

      say_remaining_estimate(times, chunks, chunk, wait)

      # larger values trade greater inconsistency for less io
      sleep wait
    end
  end

  def self.chunked_update(last_insert_id, chunk_size, new_table, insertion_columns, curr_table, wait, where = "")
    # do the inserts in chunks. helps to reduce io contention and keeps the
    # undo log small.
    chunks = (last_insert_id / chunk_size.to_f).ceil
    times = []
    (1..chunks).each do |chunk|

      times << Benchmark.measure do
        execute "start transaction"

        execute %Q{
          update %s as t1
          join %s as t2 on t1.id = t2.id
          set %s
          where (t2.id between %d and %d) %s
        } % [
          new_table,
          curr_table,
          insertion_columns.keys.map { |keys| "t1.#{keys} = t2.#{keys}"}.join(","),
          ((chunk - 1) * chunk_size) + 1,
          [chunk * chunk_size, last_insert_id].min,
          where
        ]
        execute "COMMIT"
      end

      say_remaining_estimate(times, chunks, chunk, wait)

      # larger values trade greater inconsistency for less io
      sleep wait
    end
  end

  def self.last_insert_id(curr_table)
    with_master do
      connection.select_value("select max(id) from %s" % curr_table).to_i
    end
  end

  def self.table_column_names(table_name)
    with_master do
      connection.select_values %Q{
        select column_name
          from information_schema.columns
         where table_name = "%s"
           and table_schema = "%s"

      } % [table_name, connection.current_database]
    end
  end

  def self.with_master
    if ActiveRecord::Base.respond_to? :with_master
      ActiveRecord::Base.with_master do
        yield
      end
    else
      yield
    end
  end

  def self.clone_table(source, dest, window = 0, add_action_column = false)
    execute schema_sql(source, dest, window, add_action_column)
  end

  def self.common_columns(t1, t2)
    table_column_names(t1) & table_column_names(t2)
  end

  def self.clone_table_for_changes(table, journal_table)
    clone_table(table, journal_table, 0, true)
  end

  def self.rename_tables(tables = {})
    execute "rename table %s" % tables.map{ |old_table, new_table| "#{old_table} to #{new_table}" }.join(', ')
  end

  def self.add_trigger_on_action(table, journal_table, action)
    columns = table_column_names(table)
    table_alias = (action == 'delete') ? 'OLD' : 'NEW'
    fallback    = (action == 'delete') ? "`hadron_action` = 'delete'" : columns.map { |c| "#{tick(c)} = #{table_alias}.#{tick(c)}" }.join(",")

    execute %Q{
      create trigger %s
        after #{action} on %s for each row
        begin
          insert into %s (%s, `hadron_action`)
          values (%s, '#{ action }')
          ON DUPLICATE KEY UPDATE %s;
        end
    } % [trigger_name(action, table),
         table,
         journal_table,
         columns.map { |c| tick(c) }.join(","),
         columns.map { |c| "#{table_alias}.#{tick(c)}" }.join(","),
         fallback
        ]
  end

  def self.delete_trigger_on_action(table, action)
    execute "drop trigger if exists %s" % trigger_name(action, table)
  end

  def self.trigger_name(action, table)
    tick("after_#{action}_#{table}")
  end

  def self.cleanup(table)
    delete_trigger_on_action(table, "insert")
    delete_trigger_on_action(table, "update")
    delete_trigger_on_action(table, "delete")
  end

  def self.say_remaining_estimate(times, chunks, chunk, wait)
    avg = times.inject(0) { |s, t| s += t.real } / times.size.to_f
    remaining = chunks - chunk
    say "%d more chunks to go, estimated end: %s" % [
      remaining,
      Time.now + (remaining * (avg + wait))
    ]
  end

  def self.replay_insert_changes(table, journal_table, chunk_size = 10000, wait = 0.2)
    last_insert_id = last_insert_id(journal_table)
    columns = prepare_insertion_columns(table, journal_table)

    chunked_insert \
      last_insert_id,
      chunk_size,
      table,
      columns,
      journal_table,
      wait,
      "AND hadron_action = 'insert'"
  end

  def self.replay_delete_changes(table, journal_table)
    execute %Q{
      delete from #{table} where id in (
        select id from #{journal_table} where hadron_action = 'delete'
      )
    }
  end

  def self.replay_update_changes(table, journal_table, chunk_size = 10000, wait = 0.2)
    last_insert_id = last_insert_id(journal_table)
    columns = prepare_insertion_columns(table, journal_table)

    chunked_update \
      last_insert_id,
      chunk_size,
      table,
      columns,
      journal_table,
      wait,
      "AND hadron_action = 'update'"
  end

  #
  #  use show create instead of create table like. there was some weird
  #  behavior with the latter where the auto_increment of the source table
  #  got modified when updating the destination.
  #
  def self.schema_sql(source, dest, window, add_action_column = false)
    show_create(source).tap do |schema|
      schema.gsub!(/auto_increment=(\d+)/i) do
        "auto_increment=#{  $1.to_i + window }"
      end

      if add_action_column
        schema.sub!(/\) ENGINE=/,
          ", hadron_action ENUM('update', 'insert', 'delete'), INDEX hadron_action (hadron_action) USING BTREE) ENGINE=")
      end

      schema.gsub!('CREATE TABLE `%s`' % source, 'CREATE TABLE `%s`' % dest)
    end
  end

  def self.show_create(t1)
    (execute "show create table %s" % t1).fetch_row.last
  end

  def self.tick(col)
    "`#{ col }`"
  end
end
