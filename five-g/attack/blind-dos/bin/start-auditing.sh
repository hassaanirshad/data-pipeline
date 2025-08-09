#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"
SPADE_DIR="${ROOT_DIR}/SPADE"

pushd "${SPADE_DIR}"

auditctl --reset-lost

# Add kernel modules
./bin/spade run-util ManageAuditKernelModules \
    --controller=./lib/kernel-modules/netio_controller.ko \
    --main=./lib/kernel-modules/netio.ko \
    --ignoreProcesses=auditd,kauditd,audispd \
    --ignoreParentProcesses=auditd,kauditd,audispd \
    --netIO=true \
    --namespaces=true

# Add audit control rules
./bin/spade run-util ManageAuditControlRules \
    --syscall=default \
    --ignoreProcesses=auditd,kauditd,audispd \
    --ignoreParentProcesses=auditd,kauditd,audispd \
    --excludeProctitle=true \
    --kernelModules=true \
    --netIO=true \
    --fileIO=true \
    --memory=true \
    --fsCred=true \
    --dirChange=true \
    --rootChange=true \
    --namespaces=true \
    --ipc=true

popd