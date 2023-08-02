FROM --platform=linux/amd64 python:3.8-slim-bullseye

WORKDIR /app

RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y wget  unzip tree zip
RUN apt-get install -y build-essential

COPY requirements.txt ./requirements.txt

RUN pip3 --no-cache-dir install -r requirements.txt

# install the Arduino CLI
RUN wget https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh && \
    sh ./install.sh 0.21.0 && \
    rm ./install.sh && \
    ln -s /app/bin/arduino-cli /usr/bin/arduino-cli

# Install Arduino dependencies
COPY firmware-arduino-nicla-voice firmware/
RUN cd firmware && /bin/bash arduino-build.sh
RUN rm -rf ./firmware/*.bin
RUN rm -rf ./firmware/*.elf

# Build base firmware
RUN rm -rf ./firmware/*.bin
RUN rm -rf ./firmware/*.elf
RUN cd ./firmware && mv *.ino firmware.ino && /bin/bash ./arduino-build.sh --build && \
    rm firmware.ino.*

COPY app/deploy/ ./

ENTRYPOINT ["bash", "generate_synpkg.sh"]
