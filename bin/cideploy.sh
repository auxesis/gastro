#!/bin/bash

# Exit immediately if any commands return non-zero
set -e
# Output the commands we run
set -x

# Download + cache the cf cli
if [ ! -e "~/bin/cf" ]; then
  wget 'https://cli.run.pivotal.io/stable?release=linux64-binary&source=github' -O cf.tar.gz
  tar zxvf cf.tar.gz -C ~/bin
fi
export PATH=$PATH:~/bin

# Login to cf (these environment variables must be exported by CI)
set +x
cf login -a $CF_API -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE
set -x

# Update the blue app
cf unmap-route blue cfapps.io -n gotgastro
cf unmap-route blue gotgastroagain.com
cf push blue -f manifest.yml
cf map-route blue cfapps.io -n gotgastro
cf map-route blue gotgastroagain.com

# Update the green app
cf unmap-route green cfapps.io -n gotgastro
cf unmap-route green gotgastroagain.com
cf push green -f manifest.yml
cf map-route green cfapps.io -n gotgastro
cf map-route green gotgastroagain.com
