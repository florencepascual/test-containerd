#!/bin/bash

set -ue

# Start the dockerd and wait for it to start
source /usr/local/bin/dockerd-starting.sh

ctr -v

exit 0
