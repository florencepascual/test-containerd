#!/bin/bash

set -ue

# Start the docker daemon in the background
bash /usr/local/bin/dockerd-entrypoint.sh &

# Check if the dockerd has started
DAEMON="dockerd"
while ! /usr/bin/pgrep $DAEMON && ! docker stats --no-stream
do
    echo "Waiting for Docker"
    sleep 2
    pid=`/usr/bin/pgrep $DAEMON`
    echo "$DAEMON pid:$pid"  2>&1 | tee -a ${LOG}
    if [[ ! -z ${DOCKER_SECRET_AUTH+z} ]] && [ ! -d /root/.docker ]
    then
        mkdir /root/.docker
        echo "$DOCKER_SECRET_AUTH" > /root/.docker/config.json
        echo "Docker login" 2>&1 | tee -a ${LOG}
    fi
    echo "Launching docker info" 2>&1 | tee -a ${LOG}
    docker info 2>&1 | tee -a ${LOG}
done

ctr -v

exit 0
