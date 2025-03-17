#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/lib-verbose.sh"

FAILED_TO_BUILD=()
(
  cd "${PROJECT}/docker"
  for D in *
  do
    DOCKER_DIR="${PROJECT}/docker/${D}"
    [[ -d "${DOCKER_DIR}" ]] || continue

    info "Building image: [${D}]"
    cd "${PROJECT}/docker/${D}"
    if "${BIN}/docker-build-cwd.sh"
    then
      :
    else
      FAILED_TO_BUILD+=("${D}")
    fi
  done
  if [[ "${#FAILED_TO_BUILD[@]}" -gt 0 ]]
  then
    error "Some containers failed to build: [${FAILED_TO_BUILD[*]}]"
  fi
)
