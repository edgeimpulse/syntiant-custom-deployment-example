FROM --platform=linux/amd64 python:3.8-slim-bullseye

WORKDIR /app

RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y wget  unzip tree zip
RUN apt-get install -y build-essential

COPY requirements.txt ./requirements.txt

RUN pip3 --no-cache-dir install -r requirements.txt

COPY app/deploy/ ./

ENTRYPOINT ["bash", "generate_synpkg_lib.sh"]
