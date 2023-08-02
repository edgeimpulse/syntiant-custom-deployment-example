#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
PROJECT=firmware-syntiant-nicla
# used for grepping
# used for grepping
ARDUINO_CORE="arduino:mbed_nicla"
ARDUINO_CORE_VERSION="3.5.5"
BOARD="${ARDUINO_CORE}":nicla_voice
EXPECTED_CLI_MAJOR=0
EXPECTED_CLI_MINOR=21

if [ -z "$ARDUINO_CLI" ]; then
	ARDUINO_CLI=$(which arduino-cli || true)
fi

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

#$ARDUINO_CLI config dump | grep 'user: '
get_arduino_root() {
	local OUTPUT=$($ARDUINO_CLI config dump | grep 'user: ')
	local arduino_root="${OUTPUT:8}"
	echo "$arduino_root"
}
ARDUINO_ROOT_DIR="$(get_arduino_root)"

# Check for libraries
# Board lib
has_mbed_core() {
    $ARDUINO_CLI core list | grep -e "${ARDUINO_CORE}.*${ARDUINO_CORE_VERSION}"
}
HAS_ARDUINO_CORE="$(has_mbed_core)"
if [ -z "$HAS_ARDUINO_CORE" ]; then
    echo "Installing Arduino Nicla Voice core..."
    $ARDUINO_CLI core update-index
    $ARDUINO_CLI core install "${ARDUINO_CORE}@${ARDUINO_CORE_VERSION}"

    echo "Installing Arduino Nicla Voice core OK"
fi

# Functions
echo "Finding Nicla Voice"

has_serial_port() {
    (arduino-cli board list | grep "nicla_voice" || true) | cut -d ' ' -f1
}
SERIAL_PORT=$(has_serial_port)

if [ -z "$SERIAL_PORT" ]; then
    echo "Cannot find a connected Arduino Nicla Voice development board (via 'arduino-cli board list')."
    exit 1
fi

echo "Finding Nicla Voice OK"

echo "Flashing board"
cd "$SCRIPTPATH"
arduino-cli upload -p $SERIAL_PORT --fqbn  $BOARD --input-file firmware.ino.elf

echo "Flashing done. Use the flash_mac_model.command if you need to update the external flash"
