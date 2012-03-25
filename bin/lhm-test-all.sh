#!/bin/sh

for gemfile in gemfiles/*.gemfile
do
  if !(BUNDLE_GEMFILE=$gemfile bundle install &&
       BUNDLE_GEMFILE=$gemfile bundle exec rake)
  then
    exit 1
  fi
done
