#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
#  Schmidt
#

require 'lhm'
require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

class AddColumnTestMigration < ActiveRecord::Migration
  extend Lhm

  def self.up
    hadron_change_table(:users) do |t|
      t.add_column(:logins, "INT(12) DEFAULT '0'")
    end
  end
end

class RemoveColumnTestMigration < ActiveRecord::Migration
  extend Lhm

  def self.up
    hadron_change_table(:users) do |t|
      t.remove_column(:comment)
    end
  end
end

class AddIndexTestMigration < ActiveRecord::Migration
  extend Lhm

  def self.up
    hadron_change_table(:users) do |t|
      t.add_index([:comment, :created_at])
    end
  end
end

class AddUniqueIndexTestMigration < ActiveRecord::Migration
  extend Lhm

  def self.up
    hadron_change_table(:users) do |t|
      t.add_unique_index(:comment)
    end
  end
end

class RemoveIndexTestMigration < ActiveRecord::Migration
  extend Lhm

  def self.up
    hadron_change_table(:users) do |t|
      t.remove_index([:username, :created_at])
    end
  end
end

class DdlTestMigration < ActiveRecord::Migration
  extend Lhm

  def self.up
    hadron_change_table(:users) do |t|
      t.ddl("alter table %s add column flag tinyint(1)" % t.name)
    end
  end
end

class ParallelTestMigration < ActiveRecord::Migration
  extend Lhm

  def self.up
    hadron_change_table(:users, :stride => 10, :throttle => 97) do |t|
      t.add_column(:parallel, "INT(10) DEFAULT '0'")
    end
  end
end

describe Lhm do
  include IntegrationHelper

  before(:each) { connect! }

  describe "changes" do
    before(:each) do
      table_create(:users)
    end

    it "should add a column" do
      AddColumnTestMigration.up

      table_read(:users).columns["logins"].must_equal({
        :type => "int(12)",
        :metadata => "DEFAULT '0'"
      })
    end

    it "should copy all rows" do
      23.times { |n| execute("insert into users set reference = '#{ n }'") }

      AddColumnTestMigration.up

      count_all("users").must_equal(23)
    end

    it "should remove a column" do
      RemoveColumnTestMigration.up

      table_read(:users).columns["comment"].must_equal nil
    end

    it "should add an index" do
      AddIndexTestMigration.up

      key?(table_read(:users), [:comment, :created_at]).must_equal(true)
    end

    it "should add a unqiue index" do
      AddUniqueIndexTestMigration.up

      key?(table_read(:users), :comment, :unique).must_equal(true)
    end

    it "should remove an index" do
      RemoveIndexTestMigration.up

      key?(table_read(:users), [:username, :created_at]).must_equal(false)
    end

    it "should apply a ddl statement" do
      DdlTestMigration.up

      table_read(:users).columns["flag"].must_equal({
        :type => "tinyint(1)",
        :metadata => "DEFAULT NULL"
      })
    end

    describe "parallel" do
      it "should perserve inserts during migration" do
        50.times { |n| execute("insert into users set reference = '#{ n }'") }

        insert = Thread.new do
          10.times do |n|
            execute("insert into users set reference = '#{ 100 + n }'")
            sleep(0.17)
          end
        end

        ParallelTestMigration.up

        insert.join

        count_all(:users).must_equal(60)
      end

      it "should perserve deletes during migration" do
        50.times { |n| execute("insert into users set reference = '#{ n }'") }

        delete = Thread.new do
          10.times do |n|
            execute("delete from users where id = '#{ n + 1 }'")
            sleep(0.17)
          end
        end

        ParallelTestMigration.up

        delete.join

        count_all(:users).must_equal(40)
      end
    end
  end
end

