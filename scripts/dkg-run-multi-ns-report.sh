#!/bin/bash

if [ "$1" = "" ]; then
  echo "Usage: $0 <base cluster name>"
  exit 1
fi

COPY_FROM_CLUSTER_NAME="charon-dkg-test"
BASE_CLUSTER_NAME=$1

# Load environment variables
OLDIFS=$IFS
IFS=$'\n'
export $(< ./envs/${COPY_FROM_CLUSTER_NAME}.env)
IFS=$OLDIFS

# Read the CLUSTERS field from the environment file
if [ -z "$CLUSTERS" ]; then
  echo "CLUSTERS field not found in ./envs/${COPY_FROM_CLUSTER_NAME}.env"
  exit 1
fi

# Process each cluster
for (( index=1; index<=CLUSTERS; index++ )); do
  FULL_CLUSTER_NAME="${BASE_CLUSTER_NAME}-${index}"

  total_jobs=$(kubectl get job -n $FULL_CLUSTER_NAME --no-headers | wc -l)

  if [ $total_jobs -eq 0 ]; then
    echo "No jobs found for cluster: $FULL_CLUSTER_NAME"
    echo "$FULL_CLUSTER_NAME;0/1;0"
    index=$((index + 1))
    continue
  fi

  timeout=60  # Timeout in seconds
  start_time=$(date +%s)

  # Wait for any job to complete or timeout
  while true; do
    jobs_info=$(kubectl get job -n $FULL_CLUSTER_NAME --no-headers)
    first_job_status=$(echo "$jobs_info" | awk 'NR==1{print $2}')
    if [[ $first_job_status == "Complete" ]]; then
      break
    fi

    # Check if the timeout is exceeded
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [[ $elapsed_time -gt $timeout ]]; then
      echo "$FULL_CLUSTER_NAME - Timeout exceeded. Failed."
      echo "$FULL_CLUSTER_NAME;0/1;0"
      index=$((index + 1))
      continue 2
    fi

    sleep 5
  done

  max_duration=0
  while IFS= read -r job_info; do
    job_name=$(echo "$job_info" | awk '{print $1}')
    job_status=$(echo "$job_info" | awk '{print $2}')
    job_duration=$(echo "$job_info" | awk '{print $4}' | grep -oE '[0-9]+')

    if [[ $job_duration -gt $max_duration ]]; then
      max_duration=$job_duration
    fi
  done <<< "$jobs_info"

  echo "$FULL_CLUSTER_NAME;$first_job_status;$max_duration"
done
