#!/bin/sh

set -e
set -u

. `dirname $0`/lhm-config.sh

lhmkill() {
  echo killing lhm-cluster
  ps -ef | sed -n "/[m]ysqld.*lhm-cluster/p" | awk '{ print $2 }' | xargs kill
  echo running homebrew mysql instance
  launchctl load -w ~/Library/LaunchAgents/homebrew.mxcl.mysql.plist
  sleep 2
}

echo stopping homebrew running mysql instance
ls -lrt -d -1 ~/Library/LaunchAgents/* |  grep 'mysql.plist' | xargs launchctl unload -w

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
