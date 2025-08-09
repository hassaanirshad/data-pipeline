#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"
SRC_LOGS_DIR="/var/log/audit"
DST_LOGS_DIR="${ROOT_DIR}/logs/audit"

mkdir -p "${DST_LOGS_DIR}"

# Copy all the logs.
sudo cp "${SRC_LOGS_DIR}"/audit.log* "${DST_LOGS_DIR}"/

# Change ownership for ease of accessibility later on.
sudo chown ${USER}:${USER} "${DST_LOGS_DIR}/*"
