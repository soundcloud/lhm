#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek
#

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require "migrate/add_new_column"

describe "LargeHadronMigration", "integration" do
  include SpecHelper

  before(:each) { recreate }

  it "should add new column" do

    table("addscolumn") do |t|
      t.string :title
      t.integer :rating
      t.timestamps
    end

    truthiness_column "addscolumn", "title", "varchar"
    truthiness_column "addscolumn", "rating", "int"
    truthiness_column "addscolumn", "created_at", "datetime"
    truthiness_column "addscolumn", "updated_at", "datetime"

    ghost = AddNewColumn.up

    truthiness_column "addscolumn", "title", "varchar"
    truthiness_column "addscolumn", "rating", "int"
    truthiness_column "addscolumn", "spam", "tinyint"
    truthiness_column "addscolumn", "created_at", "datetime"
    truthiness_column "addscolumn", "updated_at", "datetime"
  end

  it "should have same row data" do
    table "addscolumn" do |t|
      t.string :text
      t.integer :number
      t.timestamps
    end

    1200.times do |i|
      random_string = (0...rand(25)).map{65.+(rand(25)).chr}.join
      sql "INSERT INTO `addscolumn` SET
            `id`         = #{i+1},
            `text`       = '#{random_string}',
            `number`     = '#{rand(255)}',
            `updated_at` = NOW(),
            `created_at` = NOW()"
    end

    ghost = AddNewColumn.up

    truthiness_rows "addscolumn", ghost
  end
end


describe "LargeHadronMigration", "rename" do
  include SpecHelper

  before(:each) do
    recreate
  end

  it "should rename multiple tables" do
    table "renameme" do |t|
      t.string :text
    end

    table "renamemetoo" do |t|
      t.integer :number
    end

    LargeHadronMigration.rename_tables("renameme" => "renameme_new", "renamemetoo" => "renameme")

    truthiness_column "renameme", "number", "int"
    truthiness_column "renameme_new", "text", "varchar"
  end

end

describe "LargeHadronMigration", "triggers" do
  include SpecHelper

  before(:each) do
    recreate

    table "triggerme" do |t|
      t.string :text
      t.integer :number
      t.timestamps
    end

    LargeHadronMigration.clone_table_for_changes \
      "triggerme",
      "triggerme_changes"
  end

  it "should create a table for triggered changes" do
    truthiness_column "triggerme_changes", "hadron_action", "varchar"
  end

  it "should trigger on insert" do
    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "insert"

      # test
    sql("insert into triggerme values (111, 'hallo', 5, NOW(), NOW())")
    sql("select * from triggerme_changes where id = 111").tap do |res|
      res.fetch_hash.tap do |row|
        row['hadron_action'].should == 'insert'
        row['text'].should == 'hallo'
      end
    end
  end

  it "should trigger on update" do

    # setup
    sql "insert into triggerme values (111, 'hallo', 5, NOW(), NOW())"
    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "update"

    # test
    sql("update triggerme set text = 'goodbye' where id = '111'")
    sql("select * from triggerme_changes where id = 111").tap do |res|
      res.fetch_hash.tap do |row|
        row['hadron_action'].should == 'update'
        row['text'].should == 'goodbye'
      end
    end
  end

  it "should trigger on delete" do

    # setup
    sql "insert into triggerme values (111, 'hallo', 5, NOW(), NOW())"
    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "delete"

    # test
    sql("delete from triggerme where id = '111'")
    sql("select * from triggerme_changes where id = 111").tap do |res|
      res.fetch_hash.tap do |row|
        row['hadron_action'].should == 'delete'
        row['text'].should == 'hallo'
      end
    end
  end

  it "should trigger on create and update" do
    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "insert"

    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "update"

    # test
    sql "insert into triggerme values (111, 'hallo', 5, NOW(), NOW())"
    sql("update triggerme set text = 'goodbye' where id = '111'")

    sql("select count(*) AS cnt from triggerme_changes where id = 111").tap do |res|
      res.fetch_hash.tap do |row|
        row['cnt'].should == '1'
      end
    end
  end

  it "should trigger on multiple update" do
    sql "insert into triggerme values (111, 'hallo', 5, NOW(), NOW())"
    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "update"

    # test
    sql("update triggerme set text = 'goodbye' where id = '111'")
    sql("update triggerme set text = 'hallo again' where id = '111'")

    sql("select count(*) AS cnt from triggerme_changes where id = 111").tap do |res|
      res.fetch_hash.tap do |row|
        row['cnt'].should == '1'
      end
    end
  end

  it "should trigger on inser, update and delete" do
    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "insert"

    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "update"

    LargeHadronMigration.add_trigger_on_action \
      "triggerme",
      "triggerme_changes",
      "delete"

    # test
    sql "insert into triggerme values (111, 'hallo', 5, NOW(), NOW())"
    sql("update triggerme set text = 'goodbye' where id = '111'")
    sql("delete from triggerme where id = '111'")

    sql("select count(*) AS cnt from triggerme_changes where id = 111").tap do |res|
      res.fetch_hash.tap do |row|
        row['cnt'].should == '1'
      end
    end
  end

  it "should cleanup triggers" do
    %w(insert update delete).each do |action|
      LargeHadronMigration.add_trigger_on_action \
        "triggerme",
        "triggerme_changes",
        action
    end

    LargeHadronMigration.cleanup "triggerme"

    # test
    sql("insert into triggerme values (111, 'hallo', 5, NOW(), NOW())")
    sql("update triggerme set text = 'goodbye' where id = '111'")
    sql("delete from triggerme where id = '111'")

    sql("select count(*) AS cnt from triggerme_changes where id = 111").tap do |res|
      res.fetch_hash.tap do |row|
        row['cnt'].should == '0'
      end
    end
  end

end

describe "LargeHadronMigration", "replaying changes" do
  include SpecHelper

  before(:each) do
    recreate

    table "source" do |t|
      t.string :text
      t.integer :number
      t.timestamps
    end

    table "source_changes" do |t|
      t.string :text
      t.integer :number
      t.string :hadron_action
      t.timestamps
    end
  end

  it "should replay inserts" do
    sql %Q{
      insert into source (id, text, number, created_at, updated_at)
           values (1, 'hallo', 5, NOW(), NOW())
    }

    sql %Q{
      insert into source_changes (id, text, number, created_at, updated_at, hadron_action)
           values (2, 'goodbye', 5, NOW(), NOW(), 'insert')
    }

    sql %Q{
      insert into source_changes (id, text, number, created_at, updated_at, hadron_action)
           values (3, 'goodbye', 5, NOW(), NOW(), 'delete')
    }

    LargeHadronMigration.replay_insert_changes("source", "source_changes")

    sql("select * from source where id = 2").tap do |res|
      res.fetch_hash.tap do |row|
        row['text'].should == 'goodbye'
      end
    end

    sql("select count(*) as cnt from source where id = 3").tap do |res|
      res.fetch_hash.tap do |row|
        row['cnt'].should == '0'
      end
    end
  end


  it "should replay updates" do
    sql %Q{
      insert into source (id, text, number, created_at, updated_at)
           values (1, 'hallo', 5, NOW(), NOW())
    }

    sql %Q{
      insert into source_changes (id, text, number, created_at, updated_at, hadron_action)
           values (1, 'goodbye', 5, NOW(), NOW(), 'update')
    }

    LargeHadronMigration.replay_update_changes("source", "source_changes")

    sql("select * from source where id = 1").tap do |res|
      res.fetch_hash.tap do |row|
        row['text'].should == 'goodbye'
      end
    end
  end

  it "should replay deletes" do
    sql %Q{
      insert into source (id, text, number, created_at, updated_at)
           values (1, 'hallo', 5, NOW(), NOW()),
                  (2, 'schmu', 5, NOW(), NOW())
    }

    sql %Q{
      insert into source_changes (id, text, number, created_at, updated_at, hadron_action)
           values (1, 'goodbye', 5, NOW(), NOW(), 'delete')
    }

    LargeHadronMigration.replay_delete_changes("source", "source_changes")

    sql("select count(*) as cnt from source").tap do |res|
      res.fetch_hash.tap do |row|
        row['cnt'].should == '1'
      end
    end
  end

end

describe "LargeHadronMigration", "units" do
  include SpecHelper

  it "should return correct schema" do
    recreate
    table "source" do |t|
      t.string :text
      t.integer :number
      t.timestamps
    end

    sql %Q{
      insert into source (id, text, number, created_at, updated_at)
           values (1, 'hallo', 5, NOW(), NOW()),
                  (2, 'schmu', 5, NOW(), NOW())
    }

    schema = LargeHadronMigration.schema_sql("source", "source_changes", 1000)

    schema.should_not include('`source`')
    schema.should include('`source_changes`')
    schema.should include('1003')
  end
end

