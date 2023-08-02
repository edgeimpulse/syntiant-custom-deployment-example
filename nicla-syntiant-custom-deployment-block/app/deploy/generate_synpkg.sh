#!/bin/bash
set -e
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

echo "generate_synpkg for NDP120"

TEMPDIR=/tmp/build
mkdir $TEMPDIR

# Build the package via an API call to the deployment block
python3 -u $SCRIPTPATH/generate_synpkg_api.py --metadata /home/input/deployment-metadata.json --posterior_parameters posterior_parameters.json --out_directory $TEMPDIR

rm -rf /app/firmware/src/model-parameters
# rm -rf /app/firmware/src/tflite-model
# rm -rf /app/firmware/src/utensor-model
rm -f /app/firmware/*.bin
rm -f /app/firmware/*.elf

# rm -rf $TEMPDIR/tflite-model
cp -r $TEMPDIR/* /app/firmware/src/

cd /app/firmware

#Check if project uses microphone or IMU
if grep -q '"type": "syntiant-imu"' /home/input/deployment-metadata.json; then
    echo "Building firmware for IMU..."
    ./arduino-build.sh --build --with-imu
else
    echo "Building firmware for Audio..."
    ./arduino-build.sh --build
fi

mkdir -p /tmp/dist
#skip for now
cp -r $SCRIPTPATH/flash-scripts/* /tmp/dist
cp -f *.elf /tmp/dist
cp $TEMPDIR/ei_model* /tmp/dist/ndp120
cp $TEMPDIR/ph_params.json /tmp/dist/ndp120 # adding posterior params. Can be useful for debug


cd /tmp/dist
zip -r -X ./deployment.zip . > /dev/null     # I still want stderr messages!

mkdir -p /home/output
cp deployment.zip /home/output/deployment-nicla-syntiant.zip
