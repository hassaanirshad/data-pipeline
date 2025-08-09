#!/bin/bash

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../ && pwd )"
OAI_5G_DOCKER_DIR="${ROOT_DIR}/OAI-5G-Docker"
OAI_5G_DOCKER_DEMO_DIR="${OAI_5G_DOCKER_DIR}/sbir-p1-demo/nr-rfsim"

# The number of seconds to run the activity for before stop.
ACTIVITY_RUN_TIME=$((3*60))

pushd "${OAI_5G_DOCKER_DEMO_DIR}"

# Using run_gnb_2_demo.sh, and kill_gnb_2_demo.sh as templates. Excluded mobiflow because not required.

docker-compose up -d oai-cu-2 oai-du-2
sleep 15s
docker-compose up -d oai-nr-ue-6 
sleep 5s
docker-compose up -d oai-blind-dos-ue-victim
sleep 15s
docker-compose up -d oai-blind-dos-ue-attacker 

date
echo "Going to sleep for ${ACTIVITY_RUN_TIME}s"
sleep ${ACTIVITY_RUN_TIME}s
echo "Woke up"
date

docker-compose down oai-cu-2 oai-du-2
docker-compose down oai-nr-ue-6 oai-blind-dos-ue-victim oai-blind-dos-ue-attacker

popd