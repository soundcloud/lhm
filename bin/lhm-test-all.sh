#!/bin/sh

for gemfile in gemfiles/*.gemfile; do
  BUNDLE_GEMFILE=$gemfile bundle install
  BUNDLE_GEMFILE=$gemfile bundle exec rake
done
