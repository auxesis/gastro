#!/bin/bash

bundle install
mysql -u ubuntu -e 'SHOW DATABASES'
bundle exec rake
