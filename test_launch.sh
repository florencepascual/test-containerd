#!/bin/bash

set -ue

# Start the docker daemon in the background
bash /usr/local/bin/dockerd-entrypoint.sh &

# Check if the dockerd has started
TIMEOUT=10
DAEMON="dockerd"
i=0
echo $DAEMON
while [ $i -lt $TIMEOUT ] && ! /usr/bin/pgrep $DAEMON
do
    i=$((i+1))
    sleep 2
done

pid=`/usr/bin/pgrep $DAEMON`

if [ -z "$pid" ]
then
    echo "$DAEMON has not started after $(($TIMEOUT*2)) seconds"
    exit 1
else
    while (! docker stats --no-stream)
    do
        echo "Waiting for Docker to launch"
        sleep 1
    done
    echo "Found $DAEMON pid:$pid"
    if [[ ! -z ${DOCKER_SECRET_AUTH+z} ]] && [ ! -d /root/.docker ]
    then
        mkdir /root/.docker
        echo "$DOCKER_SECRET_AUTH" > /root/.docker/config.json
        echo "Docker login"
    fi
    echo "Launching docker info"
    docker info
fi

ctr -v

exit 0
