#
#  copyright (c) 2011, soundcloud ltd., rany keddo, tobias bielohlawek, tobias
#  schmidt
#

require File.expand_path(File.dirname(__FILE__)) + '/integration_spec_helper'

describe LargeHadronMigrator do
  before(:each) do
    execute "drop table users"
    execute fixtures(:users)
  end

  it "should replicate a large hadron migration correctly"
end

