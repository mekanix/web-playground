#!/bin/sh

export BIN_DIR=`dirname $0`
export PROJECT_ROOT="${BIN_DIR}/.."
. "${PROJECT_ROOT}/services/backend/name.py"
export backend_app_name=${app_name}
export OFFLINE=${OFFLINE:="no"}
export SYSPKG=${SYSPKG:="no"}
export REGGAE=${REGGAE:="no"}
export service=$1
shift

if [ -z "${service}" ]; then
  echo "Usage: $0 <service list>" >&2
  echo "  where service list must contain at least one service" >&2
  exit 1
fi

# Start first service
if [ "${REGGAE}" = "yes" ]; then
  sudo tmux new-session -s "${backend_app_name}" -d "make -C services/${service} devel"
else
  "${BIN_DIR}/download_repos.sh"
  tmux new-session -s "${backend_app_name}" -d "env OFFLINE=${OFFLINE} SYSPKG=${SYSPKG} ${PROJECT_ROOT}/services/${service}/bin/init.sh && env OFFLINE=${OFFLINE} SYSPKG=${SYSPKG} ${PROJECT_ROOT}/services/${service}/bin/devel.sh"
fi

# Start all other services
export service=$1
while [ ! -z "${service}" ]; do
  if [ "${REGGAE}" = "yes" ]; then
    sudo tmux split-window -h -p 50 -t 0 "make -C services/${service} BACKEND_URL=http://${backend_hostname}:5000 devel"
  else
    tmux split-window -h -p 50 -t 0 "env OFFLINE=${OFFLINE} ${PROJECT_ROOT}/services/${service}/bin/init.sh && env OFFLINE=${OFFLINE} BACKEND_URL=http://${backend_hostname}:5000 ${PROJECT_ROOT}/services/${service}/bin/devel.sh"
  fi
  shift
  export service=$1
done

# Automatically arrange tmux panes and attach to it
if [ "${REGGAE}" = "yes" ]; then
  sudo tmux select-layout tiled
  sudo tmux a -t "${backend_app_name}"
else
  tmux select-layout tiled
  tmux a -t "${backend_app_name}"
fi
