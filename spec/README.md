Preparing for master slave integration tests
--------------------------------------------

# configuration

create ~/.lhm:

    mysqldir=/usr/local/mysql
    basedir=/opt/lhm-cluster
    master_port=3306
    slave_port=3307

mysqldir specifies the location of your mysql install. basedir is the
directory master and slave databases will get installed into.

# setup

You can set the integration specs up to run against a master slave setup by
running the included `bin/lhm-spec-clobber.sh` script. this deletes the configured
lhm master slave setup and reinstalls and configures a master slave setup.

Follow the manual instructions if you want more control over this process.

# manual setup

## set up instances

    bin/lhm-spec-setup-cluster.sh

## start instances

    basedir=/opt/lhm-luster
    mysqld --defaults-file="$basedir/master/my.cnf"
    mysqld --defaults-file="$basedir/slave/my.cnf"

## run the grants

    bin/lhm-spec-grants.sh

# run specs

Setup the dependency gems

    export BUNDLE_GEMFILE=gemfiles/ar-3.2_mysql2.gemfile
    bundle install

To run specs in slave mode, set the MASTER_SLAVE=1 when running tests:

    MASTER_SLAVE=1 bundle exec rake specs

# connecting

you can connect by running (with the respective ports):

    mysql --protocol=TCP -p3307

