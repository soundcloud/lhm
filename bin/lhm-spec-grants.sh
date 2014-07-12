#!/bin/sh

source `dirname $0`/lhm-config.sh

master() { "$mysqldir"/bin/mysql --protocol=TCP -P $master_port -uroot; }
slave()  { "$mysqldir"/bin/mysql --protocol=TCP -P $slave_port -uroot; }

# set up master

echo "create user 'slave'@'localhost' identified by 'slave'" | master
echo "grant replication slave on *.* to 'slave'@'localhost'" | master

# set up slave

echo "change master to master_user = 'slave', master_password = 'slave', master_port = $master_port, master_host = 'localhost'" | slave
echo "start slave" | slave
echo "show slave status \G" | slave

# setup for test

echo "grant all privileges on *.* to ''@'localhost'" | master
echo "grant all privileges on *.* to ''@'localhost'" | slave

echo "create database lhm" | master
echo "create database if not exists lhm" | slave
