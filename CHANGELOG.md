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
