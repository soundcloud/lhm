Preparing for master slave integration tests
--------------------------------------------

You can set the integration specs up to run against a master slave setup by
running the included `setup-cluster` script.

# set up instances

spec/config/setup-cluster

# start instances

basedir=/opt/lhm-cluster
mysqld --defaults-file="$basedir/master/my.cnf"
mysqld --defaults-file="$basedir/slave/my.cnf"

# run the grants

spec/config/grants

# run specs

To run specs in slave mode, set the SLAVE=1 when running tests:

  SLAVE=1 rake specs
