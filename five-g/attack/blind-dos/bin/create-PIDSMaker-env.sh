#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"
PIDSMAKER_DIR="${ROOT_DIR}/PIDSMaker"

ENV_FILE_PATH="${PIDSMAKER_DIR}/.env"

cat <<EOF > "${ENV_FILE_PATH}"
INPUT_DIR=./data
ARTIFACTS_DIR=./artifacts
DOCKER_PORT=8888
COMPOSE_PROJECT_NAME=pidsmaker
HOST_UID=$(id -u)
HOST_GID=$(id -g)
USER_NAME=$(id -un)
EOF
