#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek
#

class AddNewColumn < LargeHadronMigrator
  def self.up
    large_hadron_migrate "addscolumn", :chunk_size => 100 do |table_name|
      execute %Q{
        alter table %s add column spam tinyint(1)
      } % table_name
    end
  end
end
