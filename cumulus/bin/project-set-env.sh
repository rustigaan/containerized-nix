#!/bin/echo Source_this_script:

PROJECT_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" || exit ; pwd)"
PROJECT_DIR="$(dirname "${PROJECT_BIN}")"
PROJECT_NAME="$(basename "${PROJECT_DIR}")"
WORK_AREA="$(dirname "${PROJECT_DIR}")"

export PROJECT_BIN PROJECT_DIR PROJECT_NAME WORK_AREA

function remove-dirs() {
  local LIST="$1"
  shift
  echo "${LIST}" | tr ':' '\012' \
    | while read D
      do
        I="true"
        for R in "$@"
        do
          if [[ ".${D}" = ".${R}" ]]
          then
            I="false"
            break
          fi
        done
        if "${I}"
        then
          echo "${D}"
        fi
      done \
    | tr '\012' : \
    | sed -e 's/:$//'
}

function find-bin-dirs() {
  local TOP="$1"
  local DEPTH="$2"
  find "${TOP}" -maxdepth "${DEPTH}" \( -type d -name node_modules -prune -type f \) -o -type d -name bin \
    | sed -e 's:/bin$:/!:' \
    | sort \
    | sed -e 's@/!$@/bin@'
}

M='3'

while read B
do
  PATH="$(remove-dirs "${PATH}" "${B}")"
  ## echo "Removed [${B}] from [${PATH}]"
done < <(find-bin-dirs "${WORK_AREA}" "$(($M + 1))")

read -d '' -r AWK_SCRIPT <<'EOT'
{
  if (seen[$0] == "") {
    seen[$0] = "+";
    print $0;
  }
}
EOT

PATH="$(find-bin-dirs "${PROJECT_DIR}" "${M}" | tr '\012' ':' | sed -e 's/:$//'):${PATH}"
PATH="$(echo "${PATH}" | tr ':' '\012' | awk "${AWK_SCRIPT}" - | tr '\012' ':')"
PATH="${PATH%:}"

if [ -f "${PROJECT_BIN}/bashrc.sh" ]
then
  source "${PROJECT_BIN}/bashrc.sh"
fi

export PS1="${PROJECT_NAME}:\W \u\$ "
echo -n -e "\033]0;${PROJECT_NAME}\a"

alias k="${PROJECT_BIN}/kubectl.sh"

export K_ENV='k3s'
