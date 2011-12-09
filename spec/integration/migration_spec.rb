#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/integration_spec_helper'

describe LargeHadronMigration do
  describe "changes" do
    before(:each) do
      execute "drop table users"
      execute fixture(:users)
    end

    it "should add a column" do
      hadron_change_table("users") do |t|
        t.add_column :logins, "INT(12)", "DEFAULT 0"
      end

      column(:users, :logins, "int(12)", "default 0").must_exist
      satisfies_user_fixture.must_equal true
    end

    it "should remove a column" do
      hadron_change_table("users") do |t|
        t.remove_column :logins
      end

      column(:users, :logins, "INT(12)").wont_exist
      satisfies_user_fixture.must_equal true
    end

    it "should add an index" do
      hadron_change_table("users") do |t|
        t.add_index :logins, :created_at
      end

      column(:users, :logins, "INT(12)").wont_exist
      satisfies_user_fixture.must_equal true
    end

    it "should remove an index" do
      hadron_change_table("users") do |t|
        t.remove_index :logins, :created_at
      end

      column(:users, :logins, "INT(12)").wont_exist
      satisfies_user_fixture.must_equal true
    end

    it "should accept a ddl statement" do
      hadron_change_table("users") do |t|
        t.execute "alter t %s add column flag tinyint(1)" % t.name
      end

      column(:users, :logins, "INT(12)").wont_exist
      satisfies_user_fixture.must_equal true
    end

    def satisfies_user_fixture?
      col(:users, "id", "INT(11)") &&
      col(:users, "reference", "INT(11)", "DEFAULT NULL") &&
      col(:users, "username", "VARCHAR(255)", "DEFAULT NULL") &&
      col(:users, "created_at", "DATETIME", "DEFAULT NULL") &&
      col(:users, "comment", "VARCHAR(20)", "DEFAULT NOT NULL")
      key(:users, "index_users_on_username_and_created_at", ["username", "created_at"]) &&
      unq(:users, "index_users_on_reference", ["reference"]) &&
      pri(:users, "id")
    end
  end
end
