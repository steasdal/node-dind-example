# node-dind-example

This project contains a super simple Node.js "hello world" app that we'll build into a Docker image
with a super nifty (and totally bonkers) docker-in-docker build.

## Running the Node.js app locally

If you'd like to experience the "hello world" awesomeness without running the Docker build, try
the following:

   * install Node.js
   * run `npm install`
   * run `npm start`

The app should now be running at [localhost:5000](http://localhost:5000/).

## Running the Node.js app in Docker

    docker run -p 5000:5000 --name node-dind-example --rm steasdal/node-dind-example

Once again, you should be able to hit the app at [localhost:5000](http://localhost:5000/). 

## Running the docker-in-docker build.

The `build.sh` script is the real star of the show here.  Dive right in and have a look.  You'll need
to have Docker installed to run it.  This script will setup a docker-in-docker environment, run the
Docker build (e.g. process the Dockerfile) from within the "internal" Docker container, attempt to
push the resulting image up to the official Docker hub and then clean up after itself.

The build script will look for a Docker config file (config.json) in a ~/.docker directory.  If you don't
have one, the script will display a warning but continue on.  You'll then also see warnings from the
"internal" section of the build script when it attempts to push the freshly built image up to the official
Docker hub.  Again, just ignore those warnings.

## Automated Build  [![Build Status](https://travis-ci.org/steasdal/node-dind-example.png)](https://travis-ci.org/steasdal/node-dind-example)
This project builds automatically on [Travis CI](https://travis-ci.org/).  Build results are available here:

   * [https://travis-ci.org/steasdal/node-dind-example](https://travis-ci.org/steasdal/node-dind-example)

## Docker Image
Successful docker-in-docker builds result in a fresh docker image pushed to the official Docker Hub:

   * [https://hub.docker.com/r/steasdal/node-dind-example/](https://hub.docker.com/r/steasdal/node-dind-example/)