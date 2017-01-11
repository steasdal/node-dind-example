#!/bin/bash

if [ -z ${INSIDE_THE_DOCKER_CLIENT+x} ]; then

    echo "*** Entering the EXTERNAL section of build script $0 ***"

    # Create a unique identifier for this build based
    # on the first eleven characters of the git hash.
    GIT_HASH=$(git rev-parse --verify --short=11 HEAD)
    echo "git hash: ${GIT_HASH}"

    # Capture a list of docker volumes before the build
    VOLUMES_BEFORE_BUILD_FILENAME=volumes-before-build-${GIT_HASH}.txt
    docker volume ls -q > ${VOLUMES_BEFORE_BUILD_FILENAME}

    DOCKER_IMAGE_NAME=steasdal/dind-example
    echo "docker image name: ${DOCKER_IMAGE_NAME}"

    DOCKER_HOST=docker-host-${GIT_HASH}
    echo "docker host: ${DOCKER_HOST}"

    DOCKER_CLIENT=docker-client-${GIT_HASH}
    echo "docker client: ${DOCKER_CLIENT}"

    STORAGE_DRIVER=`docker info | grep 'Storage Driver:' | awk '{print $NF}'`
    echo "storage driver: ${STORAGE_DRIVER}"

    echo "Starting docker host ${DOCKER_HOST} with storage driver: ${STORAGE_DRIVER}"
    docker run --privileged --name ${DOCKER_HOST} -d docker:dind --storage-driver=${STORAGE_DRIVER}

    echo "Starting build in docker client: ${DOCKER_CLIENT}"
    docker run -v $PWD:/tmp \
               -w /tmp \
               -e "GIT_HASH=${GIT_HASH}" \
               -e "DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME}" \
               -e "INSIDE_THE_DOCKER_CLIENT=TRUE" \
               --name ${DOCKER_CLIENT} \
               --link ${DOCKER_HOST}:docker \
               --rm docker:latest sh $0

    echo "Stopping and removing docker host: ${DOCKER_HOST}"
    docker stop ${DOCKER_HOST} && docker rm ${DOCKER_HOST}

    # Capture a list of docker volumes after the build
    VOLUMES_AFTER_BUILD_FILENAME=volumes-after-build-${GIT_HASH}.txt
    docker volume ls -q > ${VOLUMES_AFTER_BUILD_FILENAME}

    echo "deleting docker volume(s) created during the build"
    docker volume rm $(comm -13 ${VOLUMES_BEFORE_BUILD_FILENAME} ${VOLUMES_AFTER_BUILD_FILENAME})

    echo "cleaning up text files"
    rm ${VOLUMES_BEFORE_BUILD_FILENAME}
    rm ${VOLUMES_AFTER_BUILD_FILENAME}

    echo "*** Exiting the EXTERNAL section of build script $0 ***"

else

    echo "*** Entering the INTERNAL section of build script $0 ***"

    echo "building ${DOCKER_IMAGE_NAME} image with 'latest' and '${GIT_HASH}' tags"
    docker build --no-cache=true --force-rm=true --pull \
                 -f Dockerfile \
                 -t ${DOCKER_IMAGE_NAME}:latest \
                 -t ${DOCKER_IMAGE_NAME}:${GIT_HASH} .

    #echo "pushing ${DOCKER_IMAGE_NAME}:latest to docker repo "
    #docker push ${DOCKER_IMAGE_NAME}:latest

    #echo "pushing ${DOCKER_IMAGE_NAME}:${GIT_HASH} to docker repo "
    #docker push ${DOCKER_IMAGE_NAME}:${GIT_HASH}

    echo "*** Exiting the INTERNAL section of build script $0 ***"

fi
