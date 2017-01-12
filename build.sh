#!/bin/bash

if [ -z ${INSIDE_THE_DOCKER_CLIENT+x} ]; then

    echo "*** Entering the EXTERNAL section of build script $0 ***"

    # Create a unique identifier for this build based
    # on the first eleven characters of the git hash.
    GIT_HASH=$(git rev-parse --verify --short=11 HEAD)
    echo "Git hash: ${GIT_HASH}"

    # Capture a list of docker volumes before the build
    VOLUMES_BEFORE_BUILD_FILENAME=volumes-before-build-${GIT_HASH}.txt
    docker volume ls -q > ${VOLUMES_BEFORE_BUILD_FILENAME}

    DOCKER_IMAGE_NAME=steasdal/node-dind-example
    echo "Docker image name: ${DOCKER_IMAGE_NAME}"

    DOCKER_HOST=docker-host-${GIT_HASH}
    echo "Docker host: ${DOCKER_HOST}"

    DOCKER_CLIENT=docker-client-${GIT_HASH}
    echo "Docker client: ${DOCKER_CLIENT}"

    STORAGE_DRIVER=`docker info | grep 'Storage Driver:' | awk '{print $NF}'`
    echo "Storage driver: ${STORAGE_DRIVER}"

    # Spin up the DOCKER_HOST container that'll host the docker daemon for the DOCKER_CLIENT
    # to use.  Note the "dind" tag.  Using the same storage driver as the host docker system
    # guarantees best possible disk performance.  See the docker-in-docker documentation for
    # more info:  https://hub.docker.com/_/docker/
    echo "Starting docker host ${DOCKER_HOST} with storage driver: ${STORAGE_DRIVER}"
    docker run --privileged --name ${DOCKER_HOST} -d docker:dind --storage-driver=${STORAGE_DRIVER}

    # Ok, here we go.  This is where things really start to get fun.  Let's walk
    # through the following gargantuan docker run command line by line, shall we?
    #
    # 1) Mount local docker config file with docker hub creds into the DOCKER_CLIENT container
    #    so that the push to the official Docker hub works.
    # 2) Create a tmp directory in the DOCKER_CLIENT container.
    # 3) Set that tmp directory as the working directory.
    # 4) Set the GIT_HASH environment variable in the DOCKER_CLIENT container.
    # 5) Set the DOCKER_IMAGE_NAME environment variable in the DOCKER_CLIENT container
    # 6) Set the INSIDE_THE_DOCKER_CLIENT environment variable in the internal docker container.
    #    This is the trigger that tells this script to execute the INTERNAL section of itself.
    # 7) Set a name for the DOCKER_CLIENT container.
    # 8) Link the DOCKER_CLIENT container to DOCKER_HOST container that we just spun up.
    #    The DOCKER_CLIENT container will use the docker daemon running in DOCKER_HOST since
    #    it has no docker daemon itself.
    # 9) Lastly, spin up the DOCKER_CLIENT container and tell it to execute this very build
    #    script.  The $0 variable resolves to the name of this script.  Since we mounted $PWD
    #    into the DOCKER_CLIENT container's working directtory, this script will be right
    #    there and ready to go.  Again, because we've set the INSIDE_THE_DOCKER_CLIENT
    #    environment variable on the DOCKER_CLIENT container, this script will execute its
    #    internal section.

    echo "Starting build in docker client: ${DOCKER_CLIENT}"
    docker run -v ~/.docker/config.json:/root/.docker/config.json \
               -v $PWD:/tmp \
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

    # If we're here, we're running in the internal docker container.  Dockerception, baby!
    # Time to run the docker build.  Since we've mounted the contents of $PWD into this
    # container's working directory, the Dockerfile should have come along for the ride.
    # All of the environment variables that we're using below should have been injected
    # into this container's context by the external docker run command.
    #
    # Let's kick off the build and tag it with two tags:  "latest" and $GIT_HASH
    echo "building ${DOCKER_IMAGE_NAME} image with 'latest' and '${GIT_HASH}' tags"
    docker build --no-cache=true --force-rm=true --pull \
                 -f Dockerfile \
                 -t ${DOCKER_IMAGE_NAME}:latest \
                 -t ${DOCKER_IMAGE_NAME}:${GIT_HASH} .

    echo "pushing ${DOCKER_IMAGE_NAME}:latest to docker repo "
    docker push ${DOCKER_IMAGE_NAME}:latest

    echo "pushing ${DOCKER_IMAGE_NAME}:${GIT_HASH} to docker repo "
    docker push ${DOCKER_IMAGE_NAME}:${GIT_HASH}

    echo "*** Exiting the INTERNAL section of build script $0 ***"

fi
