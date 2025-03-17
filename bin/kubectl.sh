#!/bin/bash

set -e

BIN="$(cd "$(dirname "$0")" ; pwd)"
PROJECT="$(dirname "${BIN}")"

source "${BIN}/lib-verbose.sh"

CURRENT_WORKING_DIRECTORY="$(pwd 2>/dev/null || echo "${PWD}")"
log "Current working directory: [${CURRENT_WORKING_DIRECTORY}]"

if [[ -z "${ENVIRONMENT}" ]]
then
  ENVIRONMENT='map-int'
fi
if [[ ".$1" = '.--env' ]]
then
  ENVIRONMENT="$2"
  shift 2
fi
log "Environment=[${ENVIRONMENT}]"
KUBECTL_CONF="${PROJECT}/target"

LOCAL_KUBERNETES_CONFIG="${KUBECTL_CONF}/kubeconfig.yaml"
ETC_KUBERNETES_CONFIG="${KUBECTL_CONF}/config"
if [[ ! -e "${ETC_KUBERNETES_CONFIG}" ]] && [[ -e "${LOCAL_KUBERNETES_CONFIG}" ]]
then
  sed \
      -e 's;https://127\.0\.0\.1:6443;https://172.19.0.2:6443;' \
      "${LOCAL_KUBERNETES_CONFIG}" > "${ETC_KUBERNETES_CONFIG}"
fi

TTY='false'
if [[ -t 0 ]] && [[ -t 1 ]]
then
	TTY='true'
fi

if [[ ".$1" = ".-t" ]]
then
  TTY='true'
  shift
fi

if [[ ".$1" = ".-b" ]]
then
  TTY='false'
  shift
fi

log "Use TTY: [${TTY}]"

HAS_PORTS='false'
PORTS=()

while [[ ".$1" = '.-p' || ".$1" = '.--port' ]]
do
  PORTS+=($2)
  HAS_PORTS='true'
  shift 2
done

DOCKER_ARGS=()
KUBECTL_ARGS=()

COMMAND='kubectl'
if [[ ".$1" = ".-c" ]]
then
  COMMAND="$2"
  shift 2
else
  KUBECTL_ARGS+=(--kubeconfig "${KUBECTL_CONF}/config")
fi

DAEMON_CT_NAME=''
if [[ -f "${KUBECTL_CONF}/daemon.yaml" ]]
then
  DAEMON_CT_NAME="$("${BIN}/yq.sh" '.["container-name"]' "${KUBECTL_CONF}/daemon.yaml")"
  log "DAEMON_CT_NAME=[${DAEMON_CT_NAME}]"
fi

if [[ ".${COMMAND}" = ".kubectl" && ".$1" = '.port-forward' ]]
then
  KUBECTL_ARGS+=("$1" --address '0.0.0.0') ; shift
  if [[ ".$1" = '.-n' || ".$1" = '.--namespace' ]]
  then
    KUBECTL_ARGS+=("$1" "$2")
    shift 2
  fi
  KUBECTL_ARGS+=("$1") ; shift
  if [[ ".$1" = '.-n' || ".$1" = '.--namespace' ]]
  then
    KUBECTL_ARGS+=("$1" "$2")
    shift 2
  fi
  for PORT_ASSIGNMENT in "$@"
  do
    LOCAL_PORT="${PORT_ASSIGNMENT%:*}"
    if [[ -z "${DAEMON_CT_NAME}" ]]
    then
      DOCKER_ARGS+=(-p "0.0.0.0:${LOCAL_PORT}:${LOCAL_PORT}")
    fi
  done
elif "${HAS_PORTS}"
then
  DOCKER_ARGS+=(--network public)
  for PORT in "${PORTS[@]}"
  do
    if [[ ".${PORT}" =~ ^.*:.*$ ]]
    then
      DOCKER_ARGS+=(-p "0.0.0.0:${PORT}")
    else
      DOCKER_ARGS+=(-p "0.0.0.0:${PORT}:${PORT}")
    fi
  done
fi

function run_kubectl() {
  DOCKER_COMMAND=(
    docker run --rm -i "${DOCKER_ARGS[@]}" \
      -v "${KUBECTL_CONF}:${REMOTE_ABSOLUTE_PREFIX}/home/ubuntu/.kube" \
      -v "${HOME}/.auth:${REMOTE_ABSOLUTE_PREFIX}/home/ubuntu/.auth"
      -v "${HOME}:${HOME}" \
      -w "${REMOTE_ABSOLUTE_PREFIX}${CURRENT_WORKING_DIRECTORY}"
      kubectl "$@"
  )
  log "DOCKER_COMMAND=[${DOCKER_COMMAND[*]}]"
  "${DOCKER_COMMAND[@]}"
}

function exec_kubectl() {
  local FOUND
  FOUND="$(docker ps --filter "Name=^${DAEMON_CT_NAME}\$" --format '{{.Names}}')"
  if [[ -z "${FOUND}" ]]
  then
    error "First, start daemon container in another terminal with: k-connectedk8s.sh -v"
  fi
  DOCKER_COMMAND=(
    docker exec -i "${DOCKER_ARGS[@]}" \
      -w "${REMOTE_ABSOLUTE_PREFIX}${CURRENT_WORKING_DIRECTORY}"
      "${DAEMON_CT_NAME}" "$@"
  )
  log "DOCKER_COMMAND=[${DOCKER_COMMAND[*]}]"
  "${DOCKER_COMMAND[@]}"
}

if [[ -z "${DAEMON_CT_NAME}" && ! -f "${KUBECTL_CONF}/config" ]]
then
  log 'Initialize k8s config'
  run_kubectl bash -c 'source ~/.bashrc' >/dev/null 2>&1
fi

if "${TTY}"
then
  DOCKER_ARGS+=('-t')
fi

"${SILENT}" || pwd

if "${HAS_PORTS}" || [[ -z "${DAEMON_CT_NAME}" ]]
then
  if [[ -S "${HOME}/.rd/docker.sock" ]]
  then
    DOCKER_SOCKET="${HOME}/.rd/docker.sock"
  else
    DOCKER_SOCKET='/var/run/docker.socket'
  fi
  DOCKER_ARGS+=(-v "${REMOTE_ABSOLUTE_PREFIX}${DOCKER_SOCKET}:${REMOTE_ABSOLUTE_PREFIX}/var/run/docker.sock")

  DOCKER_ARGS+=(--network='public')

  if [[ -n "${DAEMON_CT_NAME}" ]]
  then
    DOCKER_ARGS+=(--name "${DAEMON_CT_NAME}")
  fi

  run_kubectl "${COMMAND}" "${KUBECTL_ARGS[@]}" "$@"
else
  exec_kubectl "${COMMAND}" "${KUBECTL_ARGS[@]}" "$@"
fi