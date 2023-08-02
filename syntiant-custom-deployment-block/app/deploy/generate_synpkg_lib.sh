#!/bin/bash
set -e
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

echo "generate_synpkg for NDP120"

TEMPDIR=/tmp/build
mkdir $TEMPDIR

# Build the package via an API call to the deployment block
python3 -u $SCRIPTPATH/generate_synpkg_api.py --metadata /home/input/deployment-metadata.json --posterior_parameters posterior_parameters.json --out_directory $TEMPDIR


cd $TEMPDIR # Go to syntiant model files
zip -r -X ./deployment.zip . > /dev/null     # I still want stderr messages!

mkdir -p /home/output
cp deployment.zip /home/output/deployment-nicla-syntiant.zip
