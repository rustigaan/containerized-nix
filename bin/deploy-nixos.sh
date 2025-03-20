#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/lib-verbose.sh"

function k() {
  "${BIN}/kubectl.sh" "$@"
}

function helm() {
  COMMAND=(k "${FLAGS_INHERIT[@]}" -c helm "$@")
  log "Command: [${COMMAND[*]}]"
  "${COMMAND[@]}"
}

helm template nixos "${PROJECT}/helm/nixos" -f "${PROJECT}/helm/nixos/values.yaml" -f "${PROJECT}/helm/nixos/values/${K_ENV}.yaml" \
  | k apply -f -
