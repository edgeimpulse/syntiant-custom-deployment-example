#!/bin/bash

# used for grepping
ARDUINO_CORE="arduino-git:mbed" # temporary !

BOARD="${ARDUINO_CORE}":nicla_voice

if [ -z "$ARDUINO_CLI" ]; then
	ARDUINO_CLI=$(which arduino-cli || true)
fi

EXPECTED_CLI_MAJOR=0
EXPECTED_CLI_MINOR=21

if [ ! -x "$ARDUINO_CLI" ]; then
    echo "Cannot find 'arduino-cli' in your PATH. Install the Arduino CLI before you continue."
    echo "Installation instructions: https://arduino.github.io/arduino-cli/latest/"
    exit 1
fi

CLI_MAJOR=$($ARDUINO_CLI version | cut -d. -f1 | rev | cut -d ' '  -f1)
CLI_MINOR=$($ARDUINO_CLI version | cut -d. -f2)
CLI_REV=$($ARDUINO_CLI version | cut -d. -f3 | cut -d ' '  -f1)

if (( CLI_MINOR < EXPECTED_CLI_MINOR)); then
    echo "You need to upgrade your Arduino CLI version (now: $CLI_MAJOR.$CLI_MINOR.$CLI_REV, but required: $EXPECTED_CLI_MAJOR.$EXPECTED_CLI_MINOR.x or higher)"
    echo "See https://arduino.github.io/arduino-cli/installation/ for upgrade instructions"
    exit 1
fi

if (( CLI_MAJOR != EXPECTED_CLI_MAJOR || CLI_MINOR != EXPECTED_CLI_MINOR )); then
    echo "You're using an untested version of Arduino CLI, this might cause issues (found: $CLI_MAJOR.$CLI_MINOR.$CLI_REV, expected: $EXPECTED_CLI_MAJOR.$EXPECTED_CLI_MINOR.x)"
fi

$ARDUINO_CLI config dump | grep 'user: '
get_library_dir() {
	local OUTPUT=$($ARDUINO_CLI config dump | grep 'user: ')
	local lib="${OUTPUT:8}"/libraries
    echo $lib
}

ARDUINO_LIB_DIR="$(get_library_dir)"
if [[ -z "$ARDUINO_LIB_DIR" ]]; then
    echo "Arduino libraries directory not found"
    exit 1s
fi

create_library_dir() {
	local OUTPUT=$($ARDUINO_CLI config dump | grep 'user: ') 
	local lib="${OUTPUT:8}"/libraries
	mkdir $OUTPUT
    mkdir $lib
}

if [ ! -d "$ARDUINO_LIB_DIR" ]; then
    echo "Creating lib folder"
    create_library_dir
fi

#$ARDUINO_CLI config dump | grep 'user: '
get_arduino_root() {
	local OUTPUT=$($ARDUINO_CLI config dump | grep 'user: ')
	local arduino_root="${OUTPUT:8}"
	echo "$arduino_root"
}
ARDUINO_ROOT_DIR="$(get_arduino_root)"

# Check for libraries - sperimental for now.
# Board lib
has_mbed_core() {
    arduino-cli core list | grep -e "arduino-git:mbed.*9.9.9"
}
HAS_ARDUINO_CORE="$(has_mbed_core)"
if [ -z "$HAS_ARDUINO_CORE" ]; then
    echo "Installing Arduino Nicla Voice core..."

    wget -O "${ARDUINO_ROOT_DIR}/hardware-mbed-git-nicla-voice-v91-imu.zip" https://cdn.edgeimpulse.com/build-system/hardware-mbed-git-nicla-voice-v91-imu.zip
    unzip "${ARDUINO_ROOT_DIR}/hardware-mbed-git-nicla-voice-v91-imu.zip" -d "${ARDUINO_ROOT_DIR}/"

    rm ${ARDUINO_ROOT_DIR}/hardware-mbed-git-nicla-voice-v91-imu.zip 
    echo "Installing Arduino Nicla Voice core OK"
fi

has_nicla_core() {
    $ARDUINO_CLI core list | grep -e "arduino:mbed_nicla.*3.1.1"  || true
}
HAS_NICLA_CORE="$(has_nicla_core)"
if [ -z "$HAS_NICLA_CORE" ]; then
    echo "Installing Arduino Nicla core..."
    $ARDUINO_CLI core update-index
    $ARDUINO_CLI core install arduino:mbed_nicla@3.1.1
    echo "Installing Arduino Nicla core OK"
fi

echo "Installing python packages"
pip3 install pyserial
echo "Done"
