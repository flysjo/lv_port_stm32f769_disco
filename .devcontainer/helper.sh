#!/bin/bash
set -e
# set -x

WORKDIR=/data
REPO_ROOT_DIR="$( cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd -P)"
DOCKER_FOLDER="${REPO_ROOT_DIR}/.devcontainer"
DOCKER_IMAGE_NAME=$(basename $(dirname $DOCKER_FOLDER) | tr '[:upper:]' '[:lower:]')

# Detect environment of docker command
INTERACTIVE_OPTS="-"
# Check if STDIN file is pipe. If not, it is "regular" STDIN
[[ -p /dev/fd/0 ]] || INTERACTIVE_OPTS="${INTERACTIVE_OPTS}i"
# Check if STDIN descriptor is associated with a terminal device
[[ -t 0 ]] && INTERACTIVE_OPTS="${INTERACTIVE_OPTS}t"
[[ "${INTERACTIVE_OPTS}" == "-" ]] && INTERACTIVE_OPTS=""

help() {
    echo "This helper script have some sub commands to manage this docker image"
    echo "  $0 <command>"
    echo "     clean       Cleans all hanging images and containers (not labeled or running)"
    echo "     cleanall    clean + removes named image created by this script"
    echo "     save_image  stores the image in a compressed file"
    echo "     build       builds the image"
    echo "     run [args]  runs image, bash if no argument, otherwise runs the commands given and exists"
}

clean() {
    echo Removing unused containers and images
    docker rm $(docker ps -qa --no-trunc --filter "status=exited")
    docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')
}

cleanall() {
    clean
    docker rmi --force $DOCKER_IMAGE_NAME || exit $?
}

save_image() {
    if [[ -x "$(command -v pxz)" ]]; then
        COMPRESSION_TOOL=$(command -v pxz)
    else
        COMPRESSION_TOOL=$(command -v xz)
    fi
    echo "Saving Docker image using compression tool: $COMPRESSION_TOOL"

    # Save images
    set -o pipefail               # Turn on failing the command, if any command in pipe fails
    destfile=${DOCKER_IMAGE_NAME}.tar.xz
    docker save ${DOCKER_IMAGE_NAME}:latest | $COMPRESSION_TOOL > $destfile
    echo "    File $destfile successfully created."
    echo "    To restore, run:"
    echo "        $COMPRESSION_TOOL -cd $destfile | docker load"
}

build() {
    cd $DOCKER_FOLDER && \
        docker build \
        --build-arg USER_UID=$(id -u) \
        --build-arg USERNAME=$USER \
        -f Dockerfile -t $DOCKER_IMAGE_NAME . $*
}

create_volume() {
    name=$1
    shift
    docker volume rm $name > /dev/null | true
    docker volume create $* $name > /dev/null
}

run() {
    if [ -z "$*" ]; then
        args="bash"
    else
        args=$*
    fi
    env | grep -E "IDF|GITHUB|RUNNER|PUBLISH|ATLASSIAN" > env.list || true
    echo IDF_CCACHE_ENABLE=0 >> env.list
    echo "Running docker container ($DOCKER_IMAGE_NAME) with args: $args"
    cmd="docker run ${INTERACTIVE_OPTS} --privileged --rm
        --env-file=./env.list
        --net=host
        --user=$(id -u):$(id -g)
        --volume /etc/passwd:/etc/passwd:ro
        --volume /etc/group:/etc/group:ro
        --volume /etc/timezone:/etc/timezone:ro
        --volume /etc/localtime:/etc/localtime:ro
        --volume $(pwd):$WORKDIR
        -w $WORKDIR
        $DOCKER_IMAGE_NAME $args"
    $cmd
    rm env.list
}

if [ -z "$*" ]; then
    help
else
    cmd="$1"
    shift
    $cmd $*
fi
