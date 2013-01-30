#!/bin/sh

set -e
set -u

source ~/.lhm

lhmkill() {
  echo killing lhm-cluster
  ps -ef | sed -n "/[m]ysqld.*lhm-cluster/p" | awk '{ print $2 }' | xargs kill
  sleep 2
}

echo stopping other running mysql instance
launchctl remove com.mysql.mysqld || { echo launchctl did not remove mysqld; }
"$mysqldir"/bin/mysqladmin shutdown || { echo mysqladmin did not shut down anything; }

lhmkill

echo removing $basedir
rm -rf "$basedir"

echo setting up cluster
bin/lhm-spec-setup-cluster.sh

echo staring instances
"$mysqldir"/bin/mysqld --defaults-file="$basedir/master/my.cnf" 2>&1 >$basedir/master/lhm.log &
"$mysqldir"/bin/mysqld --defaults-file="$basedir/slave/my.cnf" 2>&1 >$basedir/slave/lhm.log &
sleep 5

echo running grants
bin/lhm-spec-grants.sh

trap lhmkill SIGTERM SIGINT

wait
