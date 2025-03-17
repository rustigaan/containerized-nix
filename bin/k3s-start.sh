#!/usr/bin/env bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

DETACH='true'
if [[ ".$1" = '.--foreground' ]]
then
  DETACH='false'
fi

COMPOSE_FLAGS=()
if "${DETACH}"
then
  COMPOSE_FLAGS+=(-d)
fi

function docker_compose () {
  DOCKER_COMPOSE_PATH="$(type -p docker-compose || true)"
  if [[ -z "${DOCKER_COMPOSE_PATH}" ]]
  then
    docker compose "$@"
  else
    docker-compose "$@"
  fi
}

# change versions if needed
export K3S_VERSION=v1.30.2-k3s2
export REGISTRY_VERSION=2.8.3

(
  cd "${PROJECT}"
  mkdir -p target
  rm -f target/config

  # start the local kubernetes cluster
  docker_compose up "${COMPOSE_FLAGS[@]}"
)