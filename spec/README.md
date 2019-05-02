# Preparing for master slave integration tests

## Configuration

create ~/.lhm:

    mysqldir=/usr/local/mysql
    basedir=~/lhm-cluster
    master_port=3306
    slave_port=3307

mysqldir specifies the location of your mysql install. basedir is the
directory master and slave databases will get installed into.

## Automatic setup

### Run

    bin/lhm-spec-clobber.sh

You can set the integration specs up to run against a master slave setup by
running the included that. This deletes the configured lhm master slave setup and reinstalls and configures a master slave setup.

Follow the manual instructions if you want more control over this process.

## Manual setup

### set up instances

    bin/lhm-spec-setup-cluster.sh

### start instances

    basedir=/opt/lhm-luster
    mysqld --defaults-file="$basedir/master/my.cnf"
    mysqld --defaults-file="$basedir/slave/my.cnf"

### run the grants

    bin/lhm-spec-grants.sh

## run specs

Setup the dependency gems

    export BUNDLE_GEMFILE=gemfiles/ar-4.2_mysql2.gemfile
    bundle install
    
**Note:** `bundle install` fails to compile `mysql` gem's native dependencies with Ruby >= 2.4. If you see those errors, try with Ruby 2.3.3 for now.

To run specs in slave mode, set the MASTER_SLAVE=1 when running tests:

    MASTER_SLAVE=1 bundle exec rake specs

# connecting

you can connect by running (with the respective ports):

    mysql --protocol=TCP -p3307

