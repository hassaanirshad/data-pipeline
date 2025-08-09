#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"
SRC_LOGS_DIR="/var/log/audit"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DST_LOGS_DIR="${SRC_LOGS_DIR}/archive_${TIMESTAMP}"

sudo service auditd stop

sudo mkdir -p "${DST_LOGS_DIR}"

sudo mv "${SRC_LOGS_DIR}"/audit.log* "${DST_LOGS_DIR}/"

sudo service auditd start
