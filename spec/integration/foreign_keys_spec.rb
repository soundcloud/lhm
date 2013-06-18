# Copyright (c) 2011 - 2013, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek, Tobias
# Schmidt

require File.expand_path(File.dirname(__FILE__)) + '/integration_helper'

require 'lhm'

describe Lhm do
  include IntegrationHelper

  before(:each) { connect_master! }

  before(:each) do
    # Be absolutely sure it is not there
    execute 'drop table if exists fk_example'
    table_create(:users)
    table_create(:fk_example)
  end

  after(:each) do
    # Clean it up since it could cause trouble
    execute 'drop table if exists fk_example'
  end

  it 'should handle tables with foriegn keys' do
    Lhm.change_table(:fk_example) do |t|
      t.add_column(:new_column, "INT(12) DEFAULT '0'")
    end
  end
end
