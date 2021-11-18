#!/bin/bash

set -ue

set -o allexport
source env.list

LOG=log_${DOCKER_VERS}.log
export LOG

PATH_DOCKERFILE="test"

for PACKTYPE in DEBS RPMS
do
    echo "## Looking for distro type: ${PACKTYPE} ##" 2>&1 | tee -a ${LOG}

    for DISTRO in ${!PACKTYPE}
    do
        echo "## Looking for ${DISTRO} ##" 2>&1 | tee -a ${LOG}
        DISTRO_NAME="$(cut -d'-' -f1 <<<"${DISTRO}")"
        DISTRO_VERS="$(cut -d'-' -f2 <<<"${DISTRO}")"

	# Get all environment variables
        IMAGE_NAME="t_docker_${DISTRO_NAME}_${DISTRO_VERS}"
        CONT_NAME="t_docker_run_${DISTRO_NAME}_${DISTRO_VERS}"
        BUILD_LOG="build_${DISTRO_NAME}_${DISTRO_VERS}.log"

        export DISTRO_NAME
        export DISTRO_VERS

        echo "### # Copying the packages and the dockerfile for ${DISTRO} # ###" 2>&1 | tee -a ${LOG}
        # Building the test image
        echo "### ## Building the test image: ${IMAGE_NAME} ## ###" 2>&1 | tee -a ${LOG}
        docker build -t ${IMAGE_NAME} --build-arg DISTRO_NAME=${DISTRO_NAME} --build-arg DISTRO_VERS=${DISTRO_VERS} --build-arg DOCKER_VERS --build-arg CONTAINERD_VERS . 2>&1 | tee ${DIR_TEST}/${BUILD_LOG}

        if [[ $? -ne 0 ]]; then
            echo "ERROR: docker build failed for ${DISTRO}, see details from '${BUILD_LOG}'" 2>&1 | tee -a ${LOG}
            continue
        else
            echo "Docker build for ${DISTRO} done" 2>&1 | tee -a ${LOG}
        fi

        echo "### ### Running the tests from the container: ${CONT_NAME} ### ###" 2>&1 | tee -a ${LOG}
        docker run -d -v /workspace:/workspace -v ${PATH_SCRIPTS}:${PATH_SCRIPTS} --env DOCKER_SECRET_AUTH --env DISTRO_NAME --env DISTRO_VERS --env PATH_SCRIPTS --env DIR_TEST --env LOG --privileged --name ${CONT_NAME} ${IMAGE_NAME}
        status_code="$(docker container wait $CONT_NAME)"
        if [[ ${status_code} -ne 0 ]]; then
            echo "ERROR: The test suite failed for ${DISTRO}. See details from '${TEST_LOG}'" 2>&1 | tee -a ${LOG}
            docker logs $CONT_NAME 2>&1 | tee ${DIR_TEST}/${TEST_LOG}
        else
            docker logs $CONT_NAME 2>&1 | tee ${DIR_TEST}/${TEST_LOG}
            echo "Tests done" 2>&1 | tee -a ${LOG}
        fi

        echo "### ### # Cleanup: ${CONT_NAME} # ### ###"
        docker stop ${CONT_NAME}
        docker rm ${CONT_NAME}
        docker image rm ${IMAGE_NAME}
	popd
        rm -rf tmp
    done
done
