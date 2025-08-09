#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"
SPADE_DIR="${ROOT_DIR}/SPADE"

pushd "${SPADE_DIR}"

# Remove kernel modules
./bin/spade run-util ManageAuditKernelModules \
    --controller=./lib/kernel-modules/netio_controller.ko \
    --remove=true

# Remove audit control rules
./bin/spade run-util ManageAuditControlRules \
    --syscall=default \
    --remove=true

popd


records_lost=$(auditctl -s | grep lost | cut -d ' ' -f 2)
echo "Number of audit records lost: ${records_lost}."