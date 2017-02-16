# 3.0.0

* Drop support for throttle and stride options. Use `throttler`, instead:
```
Lhm.change_table :users, throttler: [:time_throttler, {stride: x}] do
end
```
* #118 - Truncate long trigger names. (@sj26)
* #114 - Update chunker requirements (@bjk-soundcloud)
* #98 - Add slave lag throttler. (@camilo, @jasonhl)
* #92 - Fix check for table requirement before starting a lhm.(@hannestyden)
* #93 - Makes the atomic switcher retry on metadata locks (@camilo)
* #63 - Sets the LHM's session lock wait timeout variables (@camilo)
* #75 - Remove DataMapper and ActiveRecord 2.x support (@camilo)

# 2.2.0 (Jan 16, 2015)

* #84 - Require index names to be strings or symbols (Thibaut)
* #39 - Adding the ability to rename columns (erikogan)
* #67 - Allow for optional time filter on .cleanup (joelr)

# 2.1.0 (July 31, 2014)

* #48 - Add percentage output for migrations (@arthurnn)
* #60 - Quote table names (@spickermann)
* #59 - Escape table name in select_limit and select_start methods (@stevehodgkiss)
* #57 - Ensure chunking 'where' clause handled separately (@rentalcustard)
* #54 - Chunker handle stride changes (@rentalcustard)
* #52 - Implement ability to control timeout and stride from Throttler (@edmundsalvacion)
* #51 - Ensure Lhm.cleanup removes temporary triggers (@edmundsalvacion)
* #46 - Allow custom throttler (@arthurnn)

# 2.0.0 (July 10, 2013)

* #44 - Conditional migrations (@durran)

# 1.3.0 (May 28, 2013)

* Add Lhm.cleanup method for removing copy tables, thanks @bogdan
* Limit copy table names to 64 characters, thanks @charliesome

# 1.2.0 (February 22, 2013)

* Added DataMapper support, no API changes for current users. Refer to the
  README for information.
* Documentation updates. Thanks @tiegz and @vinbarnes.

# 1.1.0 (April 29, 2012)

* Add option to specify custom index name
* Add mysql2 compatibility
* Add AtomicSwitcher

# 1.0.3 (February 23, 2012)

* Improve change_column

# 1.0.2 (February 17, 2012)

* closes https://github.com/soundcloud/large-hadron-migrator/issues/11
  this critical bug could cause data loss. table parser was replaced with
  an implementation that reads directly from information_schema.

# 1.0.1 (February 09, 2012)

* released to rubygems

# 1.0.0 (February 09, 2012)

* added change_column
* final 1.0 release

# 1.0.0.rc8 (February 09, 2012)

* removed spec binaries from gem bins

# 1.0.0.rc7 (January 31, 2012)

* added SqlHelper.annotation into the middle of trigger statements. this
  is for the benefit of the killer script which should not kill trigger
  statements.

# 1.0.0.rc6 (January 30, 2012)

* added --confirm to kill script; fixes to kill script

# 1.0.0.rc5 (January 30, 2012)

* moved scripts into bin, renamed, added to gem binaries

# 1.0.0.rc4 (January 29, 2012)

* added '-- lhm' to the end of statements for more visibility

# 1.0.0.rc3 (January 19, 2012)

* Speedup migrations for tables with large minimum id
* Add a bit yard documentation
* Fix issues with index creation on reserved column names
* Improve error handling
* Add tests for replication
* Rename public API method from `hadron_change_table` to `change_table`
* Add tests for ActiveRecord 2.3 and 3.1 compatibility

# 1.0.0.rc2 (January 18, 2012)

* Speedup migrations for tables with large ids
* Fix conversion of milliseconds to seconds
* Fix handling of sql errors
* Add helper to create unique index
* Allow index creation on prefix of column
* Quote column names on index creation
* Remove ambiguous method signature
* Documentation fix
* 1.8.7 compatibility

# 1.0.0.rc1 (January 15, 2012)

* rewrite.

# 0.2.1 (November 26, 2011)

* Include changelog in gem

# 0.2.0 (November 26, 2011)

* Add Ruby 1.8 compatibility
* Setup travis continuous integration
* Fix record lose issue
* Fix and speed up specs

# 0.1.4

* Merged [Pullrequest #9](https://github.com/soundcloud/large-hadron-migrator/pull/9)

# 0.1.3

* code cleanup
* Merged [Pullrequest #8](https://github.com/soundcloud/large-hadron-migrator/pull/8)
* Merged [Pullrequest #7](https://github.com/soundcloud/large-hadron-migrator/pull/7)
* Merged [Pullrequest #4](https://github.com/soundcloud/large-hadron-migrator/pull/4)
* Merged [Pullrequest #1](https://github.com/soundcloud/large-hadron-migrator/pull/1)

# 0.1.2

* Initial Release
