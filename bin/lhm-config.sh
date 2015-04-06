#!/bin/sh

if [ -z ${LHM_TEST_CONFIG+x} ] ; then
  . $HOME/.lhm
else
  . $LHM_TEST_CONFIG
fi

if [ -x "$mysqldir/bin/mysqld" ]; then
  mysqld_bin="$mysqldir/bin/mysqld"
elif [ -x "$mysqldir/sbin/mysqld" ]; then
  mysqld_bin="$mysqldir/sbin/mysqld"
else
  echo "Couldn't find mysqld"
  exit 1
fi

if [ -x "$mysqldir/bin/mysql" ]; then
  mysql_bin="$mysqldir/bin/mysql"
elif [ -x "$mysqldir/sbin/mysql" ]; then
  mysql_bin="$mysqldir/sbin/mysql"
else
  echo "Couldn't find mysql"
  exit 1
fi

if [ -x "$mysqldir/bin/mysql_install_db" ]; then
  install_bin="$mysqldir/bin/mysql_install_db"
elif [ -x "$mysqldir/sbin/mysql_install_db" ]; then
  install_bin="$mysqldir/sbin/mysql_install_db"
else
  echo "Couldn't find mysql_install_db"
  exit 1
fi
