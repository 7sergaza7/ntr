#!/bin/bash
# Manual rollback script for Argo Rollouts
# Usage: ./rollback.sh [bluegreen|canary]

NAMESPACE=nodejs-api
if [ "$1" == "bluegreen" ]; then
  kubectl-argo-rollout undo nodeapi-bluegreen -n $NAMESPACE
elif [ "$1" == "canary" ]; then
  kubectl-argo-rollout undo nodeapi-canary -n $NAMESPACE
else
  echo "Specify strategy: bluegreen or canary"
  exit 1
fi
