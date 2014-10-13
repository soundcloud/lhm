#!/bin/sh

if [ -z ${LHM_TEST_CONFIG+x} ] ; then
  source $HOME/.lhm
else
  source $LHM_TEST_CONFIG
fi
