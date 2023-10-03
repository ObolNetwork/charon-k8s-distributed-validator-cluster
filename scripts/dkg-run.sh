#!/bin/bash

if [ "$1" = "" ]
then
  echo "Usage: $0 <cluster name to be deployed>"
  exit -1
fi

set -uo pipefail

CLUSTER_NAME=$1

# override the env vars
OLDIFS=$IFS
IFS='
'
export $(< ../envs/${CLUSTER_NAME}.env)
IFS=$OLDIFS

# Check if the custom P2P relays argument is provided
if [ "$2" != "" ]; then
  CHARON_P2P_RELAYS=$2
fi

# create the namespace
nsStatus=`kubectl get namespace ${CLUSTER_NAME} --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "$nsStatus" ]; then
    echo "Cluster (${CLUSTER_NAME}) not found, creating a new one."
    kubectl create namespace ${CLUSTER_NAME} --dry-run=client -o yaml | kubectl apply -f -
fi

# set current namespace
kubectl config set-context --current --namespace=${CLUSTER_NAME}

echo "running dkg for cluster: ${CLUSTER_NAME}"

parse_date() {
  local date_str=$1
  local hour=${date_str:11:2}
  local minute=${date_str:14:2}
  local second=${date_str:17:2}

  local date_seconds=$((10#$hour * 3600 + 10#$minute * 60 + 10#$second))
  echo $date_seconds
}

# Deploy dkg jobs
IFS=','
node_index=0

total_jobs=${NODES}
for ((i=1; i<=total_jobs; i++))
do
export NODE_NAME="node$node_index"
eval "cat <<EOF
$(<./templates/charon-dkg-job.yaml)
EOF
" | kubectl apply -f - &
((node_index=node_index+1)) 
done

jobs_completed=0
timeout=60  # Timeout in seconds
start_time=$(date +%s)
# Wait for one job to complete
while [[ $jobs_completed -lt 1 ]]; do
  job_status=$(kubectl get job $NODE_NAME-job -n $CLUSTER_NAME -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}')
  if [[ $job_status == "True" ]]; then
    ((jobs_completed=jobs_completed+1))
  fi

  # Check if the timeout is exceeded
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
  if [[ $elapsed_time -gt $timeout ]]; then
    echo "Timeout exceeded. Job did not complete within the specified time. Check Relay logs for errors."
    exit 1
  fi

  sleep 5
done

# Retrieve and print the job durations and statuses
total_duration=0
for ((i=0; i<total_jobs; i++)); do
  export NODE_NAME="node${i}"
  job_start_time=$(kubectl get job $NODE_NAME-job -n $CLUSTER_NAME -o jsonpath='{.status.startTime}')
  job_completion_time=$(kubectl get job $NODE_NAME-job -n $CLUSTER_NAME -o jsonpath='{.status.completionTime}')
  job_status=$(kubectl get job $NODE_NAME-job -n $CLUSTER_NAME -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}')

  # Parse the job start and completion times
  start_seconds=$(parse_date "$job_start_time")
  completion_seconds=$(parse_date "$job_completion_time")

  # Calculate the job duration in seconds
  duration_seconds=$((completion_seconds - start_seconds))
  ((total_duration=total_duration+duration_seconds))
  echo "Job $NODE_NAME took $duration_seconds and has status: $job_status"
done
# Calculate the average duration
average_duration=$((total_duration / total_jobs))
echo "Average job duration: $average_duration seconds"

kubectl delete jobs --all -n $CLUSTER_NAME

# Check if the average duration is less than the threshold
threshold=30
if [[ $average_duration -lt $threshold ]]; then
  echo "Job completed successfully."
  exit 0
else
  echo "Job duration exceeds threshold. Failed."
  exit 1
fi
