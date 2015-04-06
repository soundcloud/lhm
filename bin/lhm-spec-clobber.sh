#!/bin/sh

set -e
set -u

. `dirname $0`/lhm-config.sh

lhmkill() {
  echo killing lhm-cluster
  ps -ef | sed -n "/[m]ysqld.*lhm-cluster/p" | awk '{ print $2 }' | xargs kill
  sleep 2
}

echo removing $basedir
rm -rf "$basedir"

echo setting up cluster
bin/lhm-spec-setup-cluster.sh

echo staring instances
mysqld --defaults-file="$basedir/master/my.cnf" 2>&1 >$basedir/master/lhm.log &
mysqld --defaults-file="$basedir/slave/my.cnf" 2>&1 >$basedir/slave/lhm.log &
sleep 5

echo running grants
bin/lhm-spec-grants.sh

# SIGTERM=15 SIGINT=2
trap lhmkill 15 2

echo ready to run tests
wait
