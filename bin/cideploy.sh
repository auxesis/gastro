#!/bin/bash

# Exit immediately if any commands return non-zero
set -e
# Output the commands we run
set -x

# Download the cf cli
wget 'https://cli.run.pivotal.io/stable?release=linux64-binary&source=github' -O cf.tar.gz
tar zxvf cf.tar.gz -C bin
export PATH=$PATH:$(pwd)/bin

# Login to cf (these environment variables must be exported by CI)
cf login -a $CF_API -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE

# Update the blue app
cf unmap-route blue cfapps.io -n gotgastro
cf unmap-route blue gotgastroagain.com -n gotgastro
cf push blue --no-hostname --no-manifest --no-route -i 1 -m 128M
cf map-route blue cfapps.io -n gotgastro
cf map-route blue gotgastroagain.com -n gotgastro

# Update the green app
cf unmap-route green cfapps.io -n gotgastro
cf unmap-route green gotgastroagain.com -n gotgastro
cf push green --no-hostname --no-manifest --no-route -i 1 -m 128M
cf map-route green cfapps.io -n gotgastro
cf map-route green gotgastroagain.com -n gotgastro
