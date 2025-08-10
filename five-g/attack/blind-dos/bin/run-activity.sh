#!/bin/bash

###
# Using run_gnb_2_demo.sh, and kill_gnb_2_demo.sh as templates. Excluded mobiflow because not required.
###

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"

OUTPUT_DIR="${ROOT_DIR}/output"
ACTIVITY_LOG="${OUTPUT_DIR}/run-activity.log"

OAI_5G_DOCKER_DIR="${ROOT_DIR}/OAI-5G-Docker"
OAI_5G_DOCKER_DEMO_DIR="${OAI_5G_DOCKER_DIR}/sbir-p1-demo/nr-rfsim"

# The number of seconds to run benign activity before attack.
PRE_ATTACK_BENIGN_RUN_TIME=$((1*60))

# The number of seconds to run benign activity after attack.
POST_ATTACK_BENIGN_RUN_TIME=$((1*60))

# The number of seconds to run the attack activity for.
ATTACK_RUN_TIME=$((1*60))


function write_to_activity_log () {
    local msg="${1}"
    local d=$(date)
    echo "{\"date\": \"${d}\", \"msg\": \"${msg}\"}" >> "${ACTIVITY_LOG}"
}

function clear_activity_log () {
    if [ -f "${ACTIVITY_LOG}" ]; then
        truncate -s 0 "${ACTIVITY_LOG}"
    fi
}

function setup () {
    mkdir -p "${OUTPUT_DIR}"
    clear_activity_log
}

function run_pre_attack () {
    docker-compose up -d oai-cu-2 oai-du-2
    sleep 15s
    docker-compose up -d oai-nr-ue-6
    sleep 5s
    docker-compose up -d oai-blind-dos-ue-victim
}

function start_attack () {
    docker-compose up -d oai-blind-dos-ue-attacker
}

function sleep_long () {
    local sleep_seconds="${1}"
    date
    echo "Going to sleep for ${sleep_seconds}s"
    sleep ${sleep_seconds}s
    echo "Woke up"
    date
}

function wait_while_attack () {
    sleep_long "${ATTACK_RUN_TIME}"
}

function wait_pre_attack () {
    sleep_long "${PRE_ATTACK_BENIGN_RUN_TIME}"
}

function wait_post_attack () {
    sleep_long "${POST_ATTACK_BENIGN_RUN_TIME}"
}

function stop_attack () {
    docker-compose down oai-blind-dos-ue-attacker
}

function run_post_attack () {
    docker-compose down oai-cu-2 oai-du-2
    docker-compose down oai-nr-ue-6 oai-blind-dos-ue-victim
}

function main () {
    setup

    write_to_activity_log "Started"

    write_to_activity_log "Going to start pre-attack activity"
    run_pre_attack
    write_to_activity_log "Started pre-attack activity"
    sleep 15s

    wait_pre_attack

    write_to_activity_log "Going to start attack"
    start_attack
    write_to_activity_log "Attack started"
    sleep 15s

    wait_while_attack

    write_to_activity_log "Going to stop attack"
    stop_attack
    write_to_activity_log "Attack stopped"
    sleep 10s

    wait_post_attack

    write_to_activity_log "Going to start post-attack activity"
    run_post_attack
    write_to_activity_log "Started post-attack activity"

    write_to_activity_log "Stopped"
}

pushd "${OAI_5G_DOCKER_DEMO_DIR}"
main
popd
