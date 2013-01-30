# Large Hadron Migrator [![Build Status](https://secure.travis-ci.org/soundcloud/large-hadron-migrator.png?branch=master)][4]

Rails style database migrations are a useful way to evolve your data schema in
an agile manner. Most Rails projects start like this, and at first, making
changes is fast and easy.

That is until your tables grow to millions of records. At this point, the
locking nature of `ALTER TABLE` may take your site down for an hour or more
while critical tables are migrated. In order to avoid this, developers begin
to design around the problem by introducing join tables or moving the data
into another layer. Development gets less and less agile as tables grow and
grow. To make the problem worse, adding or changing indices to optimize data
access becomes just as difficult.

> Side effects may include black holes and universe implosion.

There are few things that can be done at the server or engine level. It is
possible to change default values in an `ALTER TABLE` without locking the
table. The InnoDB Plugin provides facilities for online index creation, which
is great if you are using this engine, but only solves half the problem.

At SoundCloud we started having migration pains quite a while ago, and after
looking around for third party solutions, we decided to create our
own. We called it Large Hadron Migrator, and it is a gem for online
ActiveRecord and DataMapper migrations.

![LHC](http://farm4.static.flickr.com/3093/2844971993_17f2ddf2a8_z.jpg)

[The Large Hadron collider at CERN](http://en.wikipedia.org/wiki/Large_Hadron_Collider)

## The idea

The basic idea is to perform the migration online while the system is live,
without locking the table. In contrast to [OAK][0] and the
[facebook tool][1], we only use a copy table and triggers.

The Large Hadron is a test driven Ruby solution which can easily be dropped
into an ActiveRecord or DataMapper migration. It presumes a single auto
incremented numerical primary key called id as per the Rails convention. Unlike
the [twitter solution][2], it does not require the presence of an indexed
`updated_at` column.

## Requirements

Lhm currently only works with MySQL databases and requires an established
ActiveRecord or DataMapper connection.

It is compatible and [continuously tested][4] with Ruby 1.8.7 and Ruby 1.9.x,
ActiveRecord 2.3.x and 3.x (mysql and mysql2 adapters), as well as DataMapper
1.2 (dm-mysql-adapter).

Lhm also works with dm-master-slave-adapter, it'll bind to the master before
running the migrations.

## Installation

Install it via `gem install lhm` or add `gem "lhm"` to your Gemfile.

## Usage

You can invoke Lhm directly from a plain ruby file after connecting ActiveRecord
to your mysql instance:

```ruby
require 'lhm'

ActiveRecord::Base.establish_connection(
  :adapter => 'mysql',
  :host => '127.0.0.1',
  :database => 'lhm'
)

# or with DataMapper
Lhm.setup(DataMapper.setup(:default, 'mysql://127.0.0.1/lhm'))

# and migrate
Lhm.change_table :users do |m|
  m.add_column :arbitrary, "INT(12)"
  m.add_index  [:arbitrary_id, :created_at]
  m.ddl("alter table %s add column flag tinyint(1)" % m.name)
end
```

To use Lhm from an ActiveRecord::Migration in a Rails project, add it to your
Gemfile, then invoke as follows:

```ruby
require 'lhm'

class MigrateUsers < ActiveRecord::Migration
  def self.up
    Lhm.change_table :users do |m|
      m.add_column :arbitrary, "INT(12)"
      m.add_index  [:arbitrary_id, :created_at]
      m.ddl("alter table %s add column flag tinyint(1)" % m.name)
    end
  end

  def self.down
    Lhm.change_table :users do |m|
      m.remove_index  [:arbitrary_id, :created_at]
      m.remove_column :arbitrary
    end
  end
end
```

Using dm-migrations, you'd define all your migrations as follows, and then call
`migrate_up!` or `migrate_down!` as normal.

```ruby
require 'dm-migrations/migration_runner'
require 'lhm'

migration 1, :migrate_users do
  up do
    Lhm.change_table :users do |m|
      m.add_column :arbitrary, "INT(12)"
      m.add_index  [:arbitrary_id, :created_at]
      m.ddl("alter table %s add column flag tinyint(1)" % m.name)
    end
  end

  down do
    Lhm.change_table :users do |m|
      m.remove_index  [:arbitrary_id, :created_at]
      m.remove_column :arbitrary
    end
  end
end
```

**Note:** Lhm won't delete the old, leftover table. This is on purpose, in order
to prevent accidental data loss.

## Table rename strategies

There are two different table rename strategies available: LockedSwitcher and
AtomicSwitcher.

For all setups which use replication and a MySQL version
affected by the the [binlog bug #39675](http://bugs.mysql.com/bug.php?id=39675),
we recommend the LockedSwitcher strategy to avoid replication issues. This
strategy locks the table being migrated and issues two ALTER TABLE statements.
The AtomicSwitcher uses a single atomic RENAME TABLE query and should be favored
in setups which do not suffer from the mentioned replication bug.

Lhm chooses the strategy automatically based on the used MySQL server version,
but you can override the behavior with an option:

```ruby
Lhm.change_table :users, :atomic_switch => true do |m|
  # ...
end
```

## Contributing

We'll check out your contribution if you:

  * Provide a comprehensive suite of tests for your fork.
  * Have a clear and documented rationale for your changes.
  * Package these up in a pull request.

We'll do our best to help you out with any contribution issues you may have.

## License

The license is included as LICENSE in this directory.

## Similar solutions

  * [OAK: online alter table][0]
  * [Facebook][1]
  * [Twitter][2]
  * [pt-online-schema-change][3]

[0]: http://openarkkit.googlecode.com
[1]: http://www.facebook.com/note.php?note\_id=430801045932
[2]: https://github.com/freels/table_migrator
[3]: http://www.percona.com/doc/percona-toolkit/2.1/pt-online-schema-change.html
[4]: http://travis-ci.org/soundcloud/large-hadron-migrator
