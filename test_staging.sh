#!/bin/bash

set -ue

set -o allexport
source ${ENV_FILE}

DIR_TEST=test_${DOCKER_VERS}_${CONTAINERD_VERS}
mkdir $DIR_TEST

LOG=${DIR_TEST}/log_${DOCKER_VERS}.log
export LOG

PATH_DOCKERFILE="test"

for PACKTYPE in DEBS RPMS
do
    echo "## Looking for distro type: ${PACKTYPE} ##" 2>&1 | tee -a ${LOG}
    cp test_launch.sh ${PATH_DOCKERFILE}-${PACKTYPE}
    for DISTRO in ${!PACKTYPE}
    do
        echo "## Looking for ${DISTRO} ##" 2>&1 | tee -a ${LOG}
        DISTRO_NAME="$(cut -d'-' -f1 <<<"${DISTRO}")"
        DISTRO_VERS="$(cut -d'-' -f2 <<<"${DISTRO}")"

	# Get all environment variables
        IMAGE_NAME="t_docker_${DISTRO_NAME}_${DISTRO_VERS}"
        CONT_NAME="t_docker_run_${DISTRO_NAME}_${DISTRO_VERS}"
        BUILD_LOG="build_${DISTRO_NAME}_${DISTRO_VERS}.log"
        TEST_LOG="test_${DISTRO_NAME}_${DISTRO_VERS}.log"

        export DISTRO_NAME
        export DISTRO_VERS

        # Building the test image
        echo "### ## Building the test image: ${IMAGE_NAME} ## ###" 2>&1 | tee -a ${LOG}
        docker build -t ${IMAGE_NAME} --build-arg DISTRO_NAME=${DISTRO_NAME} --build-arg DISTRO_VERS=${DISTRO_VERS} --build-arg DOCKER_VERS=${DOCKER_VERS} --build-arg CONTAINERD_VERS=${CONTAINERD_VERS} ${PATH_DOCKERFILE}-${PACKTYPE} 2>&1 | tee ${DIR_TEST}/${BUILD_LOG}

        echo "### ### Running the tests from the container: ${CONT_NAME} ### ###" 2>&1 | tee -a ${LOG}
        docker run -d -v /workspace:/workspace --env DOCKER_SECRET_AUTH --env DISTRO_NAME --env DISTRO_VERS --env LOG --privileged --name ${CONT_NAME} ${IMAGE_NAME}

        status_code="$(docker container wait $CONT_NAME)"

        if [[ ${status_code} -ne 0 ]]; then
            docker logs $CONT_NAME | tee ${DIR_TEST}/${TEST_LOG}
        else
            docker logs $CONT_NAME | tee ${DIR_TEST}/${TEST_LOG}
        fi
        echo "### ### # Cleanup: ${CONT_NAME} # ### ###"
        docker stop ${CONT_NAME}
        docker rm ${CONT_NAME}
        docker image rm ${IMAGE_NAME}
    done
done
