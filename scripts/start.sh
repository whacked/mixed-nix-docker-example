#!/usr/bin/env bash

MY_PATH=${BASH_SOURCE[0]}
MY_DIR=$(dirname $MY_PATH)
if [ -e $MY_DIR/paths.sh ]; then
    source $MY_DIR/paths.sh
fi

# detect if we are in a git repo and set ROOT_DIR accordingly
GIT_TOPLEVEL=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$GIT_TOPLEVEL" ]; then
    ROOT_DIR=$GIT_TOPLEVEL
    SRC_DIR=$ROOT_DIR
else
    # assume docker directory layout
    ROOT_DIR=$(realpath $(dirname $(realpath ${BASH_SOURCE[0]}))/../..)
    BIN_DIR=$ROOT_DIR/bin
    SRC_DIR=$ROOT_DIR/src
    export PATH=$BIN_DIR:$PATH
fi

pushd $SRC_DIR/webserver > /dev/null
# try this if you encounter a silent failure after poetry announces
# the install plan (see https://github.com/python-poetry/poetry/issues/3412)
# export LC_ALL=en_US.UTF-8
source $(poetry env info -p)/bin/activate
popd > /dev/null

start-server() {
    # caddy run --config ./Caddyfile &
    pushd $SRC_DIR/webserver > /dev/null
    {
        source $(poetry env info -p)/bin/activate
        uvicorn webserver.main:app --host 0.0.0.0 --port 18000
    }
    popd > /dev/null
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] then
    start-server &
    caddy run --config $SRC_DIR/Caddyfile
else
    # not in container; assume `source $MY_PATH` and just load the env/functions
    :
fi
