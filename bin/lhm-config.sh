#!/bin/sh

if [ -z ${LHM_TEST_CONFIG+x} ] ; then
  . $HOME/.lhm
else
  . $LHM_TEST_CONFIG
fi
