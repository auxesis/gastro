#!/bin/bash

# Download the cf cli
wget 'https://cli.run.pivotal.io/stable?release=linux64-binary&source=github' -O cf.tar.gz
tar zxvf cf.tar.gz -C bin
export PATH=$PATH:$(pwd)/bin

# Login to cf (these environment variables must be exported by CI)
cf login -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE

# Deploy the app
cf push
