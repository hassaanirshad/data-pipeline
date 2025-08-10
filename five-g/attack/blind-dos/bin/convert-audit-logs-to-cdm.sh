#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"

CDM_DIR="${ROOT_DIR}/cdm"
AUDIT_LOGS_DIR="${ROOT_DIR}/logs/audit"

SPADE_DIR="${ROOT_DIR}/SPADE"
SPADE_LOG_FILE="${SPADE_DIR}/log/current.log"

CDM_OUTPUT_FILE="${CDM_DIR}/output.json"
AUDIT_LOG_FILE="${AUDIT_LOGS_DIR}/audit.log"


function wait_for_text_in_log_file () {
    local log_file="${1}"
    local log_text="${2}"
    local msg_at_start="${3}"
    local msg_at_exceeded_timeout="${4}"
    local timeout_seconds="${5}"
    local interval=10  # Check every 10 seconds
    local elapsed=0

    echo "${msg_at_start}"

    while (( elapsed < timeout_seconds )); do
        if grep -q "${log_text}" "${log_file}"; then
            return 0
        fi

        # Print elapsed every 60 seconds
        if (( elapsed % 60 == 0 )); then
            echo "Time elapsed ${elapsed}s out of ${timeout_seconds}s"
        fi

        sleep "${interval}"
        (( elapsed += interval ))
    done

    echo "${msg_at_exceeded_timeout}"
    echo "Timeout exceeded ${timeout_seconds}s"
    return 1
}

function wait_for_text_in_spade_log_file () {
    local log_file="${SPADE_LOG_FILE}"
    local log_text="${1}"
    local msg_at_start="${2}"
    local msg_at_exceeded_timeout="${3}"
    local timeout_seconds="${4}"
    wait_for_text_in_log_file \
        "${log_file}" \
        "${log_text}" \
        "${msg_at_start}" \
        "${msg_at_exceeded_timeout}" \
        "${timeout_seconds}"
    return $?
}

function setup () {
    mkdir -p "${CDM_DIR}"
    rm "${SPADE_LOG_FILE}"
}

function spade_start () {
    local spade_client_config_file="${SPADE_DIR}/cfg/spade.client.Control.config"

    if [ -f "${spade_client_config_file}" ]; then
        truncate -s 0 "${spade_client_config_file}"
    fi

    ./bin/spade start
    sleep 5s

    if [[ -f "./spade.pid" ]]; then
        local spade_pid
        spade_pid=$(cat ./spade.pid)

        if kill -0 "${spade_pid}" 2>/dev/null; then
            echo "SPADE started"
            return 0
        fi
    fi

    echo "Failed to start SPADE"
    return 1
}

function spade_stop () {
    ./bin/spade stop

    wait_for_text_in_spade_log_file \
        "Shutting down SPADE" \
        "Waiting for SPADE to gracefully stop" \
        "Failed to stop SPADE gracefully. Killing SPADE" \
        "60"
    
    if [ "$?" -eq 1 ]; then
        ./bin/spade kill
    fi

    echo "SPADE stopped"
}

function spade_execute_cmd () {
    local cmd="${1}"
    echo "${cmd}" | ./bin/spade control &>/dev/null
    echo "Executed SPADE command: ${cmd}"
}

function spade_add_cdm_storage () {
    local cmd=""
    cmd="${cmd}add storage CDM "
    cmd="${cmd}ssl=false "
    cmd="${cmd}output=${CDM_OUTPUT_FILE} "
    spade_execute_cmd "${cmd}"
    wait_for_text_in_spade_log_file \
        "Storage added: class spade.storage.CDM" \
        "Waiting for CDM storage to be added" \
        "Failed to add CDM storage" \
        "60"
    return $?
}

function spade_remove_cdm_storage () {
    local cmd=""
    cmd="${cmd}remove storage CDM "
    spade_execute_cmd "${cmd}"
    wait_for_text_in_spade_log_file \
        "removeStorageCommand INFO: Shutting down storage" \
        "Waiting for CDM storage to be removed" \
        "Failed to remove CDM storage" \
        "300"
    return $?
}

function spade_add_audit_reporter () {
    local cmd=""
    cmd="${cmd}add reporter Audit "
    cmd="${cmd}inputLog=${AUDIT_LOG_FILE} "
    cmd="${cmd}rotate=true "
    cmd="${cmd}waitForLog=true "
    cmd="${cmd}netIO=true "
    cmd="${cmd}fileIO=true "
    cmd="${cmd}memorySyscalls=true "
    cmd="${cmd}fsids=true "
    cmd="${cmd}cwd=true "
    cmd="${cmd}rootFS=true "
    cmd="${cmd}namespaces=true "
    cmd="${cmd}IPC=true "
    cmd="${cmd} "
    spade_execute_cmd "${cmd}"
    wait_for_text_in_spade_log_file \
        "Audit launch INFO: Successfully launched reporter" \
        "Waiting for Audit reporter to be added" \
        "Failed to add Audit reporter" \
        "120"
    return $?
}

function spade_remove_audit_reporter () {
    wait_for_text_in_spade_log_file \
        "Exiting event reader thread for SPADE audit bridge" \
        "Waiting for Audit reporter to finish processing logs" \
        "Audit reporter failed to process logs within reasonable time" \
        "1200"
    local interim_result=$?
    if [ "${interim_result}" -eq 1 ]; then
        return 1
    fi

    local cmd=""
    cmd="${cmd}remove reporter Audit "
    spade_execute_cmd "${cmd}"
    wait_for_text_in_spade_log_file \
        "removeCommand INFO: Reporter shut down" \
        "Waiting for Audit reporter to be removed" \
        "Failed to remove Audit reporter" \
        "60"
    return $?
}

function main () {
    setup

    spade_start
    if [ "$?" -eq 1 ]; then
        return 1
    fi

    sleep 10s

    spade_add_cdm_storage
    if [ "$?" -eq 1 ]; then
        spade_stop
        return 1
    fi

    sleep 10s

    spade_add_audit_reporter
    if [ "$?" -eq 1 ]; then
        spade_stop
        return 1
    fi

    sleep 10s

    spade_remove_audit_reporter
    if [ "$?" -eq 1 ]; then
        spade_stop
        return 1
    fi

    sleep 10s

    spade_remove_cdm_storage
    if [ "$?" -eq 1 ]; then
        spade_stop
        return 1
    fi

    sleep 10s

    spade_stop

    return 0
}


pushd "${SPADE_DIR}"
main
popd