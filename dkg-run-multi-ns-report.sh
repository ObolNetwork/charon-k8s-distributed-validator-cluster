#!/bin/bash

if [ "$1" = "" ]; then
  echo "Usage: $0 <cluster name>"
  exit -1
fi

CLUSTER_NAME=$1

total_jobs=$(kubectl get job -n $CLUSTER_NAME --no-headers | wc -l)

if [ $total_jobs -eq 0 ]; then
  echo "No jobs found for cluster: $CLUSTER_NAME"
  exit 1
fi

echo "Checking job status for cluster: $CLUSTER_NAME"

timeout=60  # Timeout in seconds
start_time=$(date +%s)

# Wait for any job to complete or timeout
while true; do
  jobs_info=$(kubectl get job -n $CLUSTER_NAME --no-headers)
  first_job_status=$(echo "$jobs_info" | awk 'NR==1{print $2}')
  if [[ $first_job_status == "1/1" ]]; then
    break
  fi

  # Check if the timeout is exceeded
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
  if [[ $elapsed_time -gt $timeout ]]; then
    echo "$CLUSTER_NAME - Timeout exceeded. Failed."
    exit 1
  fi

  sleep 5
done

echo "Jobs completed for cluster: $CLUSTER_NAME"

max_duration=0
while IFS= read -r job_info; do
  job_name=$(echo "$job_info" | awk '{print $1}')
  job_status=$(echo "$job_info" | awk '{print $3}')
  job_duration=$(echo "$job_info" | awk '{print $4}' | tr -d '[:alpha:]')

  if [[ $job_duration -gt $max_duration ]]; then
    max_duration=$job_duration
  fi

  echo "Job $job_name has status: $job_status"
done <<< "$jobs_info"

echo "Max job duration for cluster $CLUSTER_NAME: $max_duration"
