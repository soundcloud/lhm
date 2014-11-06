#!/bin/sh

set -e
set -u

source ~/.lhm

lhmkill() {
  echo killing lhm-cluster
  ps -ef | sed -n "/[m]ysqld.*lhm-cluster/p" | awk '{ print $2 }' | xargs kill
  echo running homebrew mysql instance
  ls -lrt -d -1 ~/Library/LaunchAgents/* |  grep -e 'mysql|mariadb.plist' | xargs launchctl load -w
  sleep 2
}

echo stopping homebrew running mysql instance
ls -lrt -d -1 ~/Library/LaunchAgents/* |  grep -e 'mysql|mariadb.plist' | xargs launchctl unload -w

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
