# Large Hadron Migrator

Rails style database migrations are a useful way to evolve your data schema in
an agile manner. Most Rails projects start like this, and at first, making
changes is fast and easy.

That is until your tables grow to millions of records. At this point, the
locking nature of `ALTER TABLE` may take your site down for an hour or more
while critical tables are migrated. In order to avoid this, developers begin
to design around the problem by introducing join tables or moving the data
into another layer. Development gets less and less agile as tables grow and
grow. To make the problem worse, adding or changing indices to optimize data
access becomes just as difficult.

> Side effects may include black holes and universe implosion.

There are few things that can be done at the server or engine level. It is
possible to change default values in an `ALTER TABLE` without locking the table.
The InnoDB Plugin provides facilities for online index creation, which is
great if you are using this engine, but only solves half the problem.

At SoundCloud we started having migration pains quite a while ago, and after
looking around for third party solutions [0] [1] [2], we decided to create our
own. We called it Large Hadron Migrator, and it is a gem for online
ActiveRecord migrations.

![LHC](http://farm4.static.flickr.com/3093/2844971993_17f2ddf2a8_z.jpg)

[The Large Hadron collider at CERN](http://en.wikipedia.org/wiki/Large_Hadron_Collider)

## The idea

The basic idea is to perform the migration online while the system is live,
without locking the table. Similar to OAK (online alter table) [2] and the
facebook tool [0], we use a copy table, triggers and a journal table.

We copy successive ranges of data from the original table to a copy table and
then rename both at the end. Since `UPDATE`, `DELETE` and `CREATE` statements
continue to hit the original table while doing this, we add tiggers to capture
these changes into a journal table.

At the end of the copying process, the journal table is replayed so that none
of these intervening mutations are lost.

The Large Hadron is a test driven Ruby solution which can easily be dropped
into an ActiveRecord migration. It presumes a single auto incremented
numerical primary key called id as per the Rails convention. Unlike the
twitter solution [1], it does not require the presence of an indexed
`updated_at` column.

## Usage

Large Hadron Migration is currently implemented as a Rails ActiveRecord
Migration.

    class AddIndexToEmails < LargeHadronMigration
      def self.up
        large_hadron_migrate :emails, :wait => 0.2 do |table_name|
          execute %Q{
            alter table %s
              add index index_emails_on_hashed_address (hashed_address)
          } % table_name
        end
      end
    end

## Migration phases

LHM runs through the following phases during a migration.

### Get the maximum primary key value for the table

When starting the migration, we remember the last insert id on the original
table. When the original table is copied into the new table, we stop at this
id. The rest of the records will be found in the journal table - see below.

### Create new table and journal table

The two tables are cloned using `SHOW CREATE TABLE`. The journal table has an
extra action field (update, delete, insert).

### Activate journalling with triggers

Triggers are created for each of the action types 'create', 'update' and
'delete'. Triggers are responsible for filling the journal table.

Because the journal table has the same primary key as the original table,
there can only ever be one version of the record in the journal table.

If the journalling trigger hits an already persisted record, it will be
replaced with the latest data and action. `ON DUPLICATE KEY` comes in handy
here. This ensures that all journal records will be consistent with the
original table.

### Perform alter statement on new table

The user supplied `ALTER TABLE` statement(s) or index changes are applied to the
new table. Our tests using InnodDB showed this to be faster than adding the
indexes at the end of the copying process.

### Copy in chunks up to max primary key value to new table

Currently InnoDB acquires a read lock on the source rows in `INSERT INTO...
SELECT`. LHM reads 35K ranges and pauses for a specified number of milliseconds
so that contention can be minimized.

### Switch new and original table names and remove triggers

The original and copy table are now atomically switched with `RENAME TABLE
original TO archive_original, copy_table TO original`. The triggers are removed
so that journalling stops and all mutations and reads now go against the
original table.

### Replay journal: insert, update, deletes

Because the chunked copy stops at the initial maximum id, we can simply replay
all inserts in the journal table without worrying about collisions.

Updates and deletes are then replayed.

## Potential issues

Locks could be avoided during the copy phase by loading records into an
outfile and then reading them back into the copy table. The facebook solution
does this and reads in 500000 rows and is faster for this reason. We plan to
add this optimization to LHM.

Data is eventually consistent while replaying the journal, so there may be
delays while the journal is replayed. The journal is replayed in a single
pass, so this will be quite short compared to the copy phase. The
inconsistency during replay is similar in effect to a slave which is slightly
behind master.

There is also a caveat with the current journalling scheme; stale journal
'update' entries are still replayed. Imagine an update to a record in the
migrated table while the journal is replaying. The journal may already contain
an update for this record, which becomes stale now. When it is replayed, the
second change will be lost. So if a record is updated twice, once before and
once during the replay window, the second update will be lost.

There are several ways this edge case could be resolved. One way would be to
add an UPDATE trigger to the main table, and delete corresponding records from
the journal while replaying. This would ensure that the journal does not
contain stale update entries.

## Near disaster at the collider

Having scratched our itch, we went ahead and got ready to roll schema and
index changes that would impact hundreds of millions of records across many
tables. There was a backlog of changes we rolled out in one go.

At the time, our MySQL slaves were regularly struggling with their replication
thread. They were often far behind master. Some of the changes were designed
to relieve this situation. Because of the slave lag, we configured the LHM to
add a bit more wait time between chunks, which made the total migration time
quite long. After running some rehersals, we agreed on the settings and rolled
out to live, expecting 5 - 7 hours to complete the migrations.

![LHC](http://farm2.static.flickr.com/1391/958035425_abb70e79b1.jpg)

Several hours into the migration, a critical fix had to be deployed to the
site. We rolled out the fix and restarted the app servers in mid migration.
This was not a good idea.

TL;DR: Never restart during migrations when removing columns with LHM.
You can restart while adding migrations as long as active record reads column 
definitions from the slave.

The information below is only relevant if you want to restart your app servers
while migrating in a master slave setup.

### When adding a column

1. Migration running on master; no effect, nothing has changed.
2. Tables switched on master. slave out of sync, migration running.
   a. Given the app server reads columns from slave on restart, nothing
      happens.
   b. Given the app server reads columns from master on restart, bad
      shitz happen, ie: queries are built with new columns, ie on :include
      the explicit column list will be built (rather than *) for the
      included table. Since it does not exist on the slave, queries will
      break here.

3. Tables switched on slave
  -  Same as 2b. Just do a cap deploy instead of cap deploy:restart.

### When removing a column

1. Migration running on master; no effect, nothing has changed.
2. Tables switched on master. slave out of sync, migration running.
   a. Given the app server reads columns from slave on restart
      - Writes against master will fail due to the additional column.
      - Reads will succeed against slaves, but not master.

   b. Given the app server reads columns from master on restart:
     - Writes against master might succeed. Old code referencing
       removed columns will fail.
     - Reads might or might not succeed, for the same reason.

## Todos

Load data into outfile instead of `INSERT INTO... SELECT`. Avoid contention and
increase speed.

Handle invalidation of 'update' entries in journal while replaying. Avoid
stale update replays.

Some other optimizations:

Deletions create gaps in the primary key id integer column. LHM has no
problems with this, but the chunked copy could be sped up by factoring this
in. Currently a copy range may be completely empty, but there will still be
a `INSERT INTO... SELECT`.

Records inserted after the last insert id is retrieved and before the triggers
are created are currently lost. The table should be briefly locked while id is
read and triggers are applied.

## Contributing

We'll check out your contribution if you:

- Provide a comprehensive suite of tests for your fork.
- Have a clear and documented rationale for your changes.
- Package these up in a pull request.

We'll do our best to help you out with any contribution issues you may have.

## License

The license is included as LICENSE in this directory.

## Footnotes

[0]: http://www.facebook.com/note.php?note\_id=430801045932 "Facebook"
[1]: https://github.com/freels/table\_migrator              "Twitter"
[2]: http://openarkkit.googlecode.com                       "OAK online alter table"
