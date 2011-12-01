require "active_record"
require "benchmark"

#
#  Copyright (c) 2011, SoundCloud Ltd., Rany Keddo, Tobias Bielohlawek
#
#  Migrate large tables without downtime by copying to a temporary table in
#  chunks. The old table is not dropped. Instead, it is moved to
#  timestamp_table_name for verification.
#
#  WARNING:
#     - may cause the universe to implode.
#
module LargeHadronMigrator
end

