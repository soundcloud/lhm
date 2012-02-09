# 1.0.0 (Febuary 09, 2012)

* added change_column
* final 1.0 release

# 1.0.0.rc8 (Febuary 09, 2012)

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
