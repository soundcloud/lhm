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
running the included `lhm-spec-clobber` script. this deletes the configured
lhm master slave setup and reinstalls and configures a master slave setup.

Follow the manual instructions if you want more control over this process.

# manual setup

## set up instances

    lhm-spec-setup-cluster

## start instances

    basedir=/opt/lhm-luster
    mysqld --defaults-file="$basedir/master/my.cnf"
    mysqld --defaults-file="$basedir/slave/my.cnf"

## run the grants

    lhm-spec-grants

## run specs

To run specs in slave mode, set the SLAVE=1 when running tests:

    MASTER_SLAVE=1 rake specs

# connecting

you can connect by running (with the respective ports):

    mysql --protocol=TCP -p3307

