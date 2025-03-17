#!/bin/false

HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" || return ; pwd)"

alias k=kubectl

KUBE_CONFIG="${HOME}/.kube/config"

ENV_SCRIPT="${HOME}/.kube/env.sh"
if [[ -f "${ENV_SCRIPT}" ]]
then
  (
    cd "$(dirname "${ENV_SCRIPT}")" || exit
    # shellcheck disable=SC1090
    source "${ENV_SCRIPT}"
  )
  KUBE_YML="${HOME}/.kube/kube.yml"
  if [[ -f "${KUBE_YML}" ]]
  then
    cp "${KUBE_YML}" "${KUBE_CONFIG}"
  fi
fi

ls -l "${KUBE_CONFIG}" || true
if [[ -f "${KUBE_CONFIG}" ]]
then
  KUBECONFIG="${KUBE_CONFIG}"
  export KUBECONFIG
fi
