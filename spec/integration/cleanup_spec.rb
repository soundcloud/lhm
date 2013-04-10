# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm'

describe Lhm, "cleanup" do
  include IntegrationHelper
  before(:each) { connect_master! }

  describe "changes" do
    before(:each) do
      table_create(:users)
      Lhm.change_table(:users, :atomic_switch => false) do |t|
        t.add_column(:logins, "INT(12) DEFAULT '0'")
        t.add_index(:logins)
      end
    end

    it "should show temporary tables" do
      output = capture_stdout do
        Lhm.cleanup
      end
      output.must_include("Existing LHM backup tables")
      output.must_match(/lhma_[0-9_]*_users/)
    end

    it "should delete temporary tables" do
      Lhm.cleanup(true).must_equal(true)
      Lhm.cleanup.must_equal(true)
    end
  end
end
