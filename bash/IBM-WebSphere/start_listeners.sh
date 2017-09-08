#!/bin/bash
###########################################################################
#                                                                         #
# Start lisneners IBM WebSphere Bus                                       #
#                                                                         #
# Author: Shokhin Andrey                                                  #
#                                                                         #
# https://github.com/z1odeypnd/my-scripts/tree/master/bash/IBM-WebSphere  #
###########################################################################

SCRIPT_DIR="$(cd $(dirname ${0}) && pwd)"
JYTHON_SCRIPT="${SCRIPT_DIR}/listeners_start.py"
WSADMIN_LOCAL_PATH="${SCRIPT_DIR}/wsadmin.sh"
#
# Change here
WSADMIN_PATH_ARRAY=("/first/path/to/dmgr/bin/wsadmin.sh" "/second/path/to/dmgr/bin/wsadmin.sh")
EXIT_CODE=0
#
if $(tty -s)
then
  HAVE_TTY=true
else
  HAVE_TTY=false
fi
func_search_wsadmin () {
  if [ -f "${WSADMIN_LOCAL_PATH}" ]
  then
    WSADMIN_SCRIPT="${WSADMIN_LOCAL_PATH}"
  else
    for WSADMIN_PATH in ${WSADMIN_PATH_ARRAY[@]}
    do
      if [ -f "${WSADMIN_PATH}" ]
      then
        if ${HAVE_TTY}
        then
          echo "WSADMIN_SCRIPT founded as ${WSADMIN_PATH}."
        fi
        WSADMIN_SCRIPT="${WSADMIN_PATH}"
        break
      fi
    done
    #
    if [ -z "${WSADMIN_SCRIPT}" ]
    then
      if ${HAVE_TTY}
      then
        echo "[$(date +%F\ %H:%M:%S)] [ERROR] Wsadmin.sh script not found. Exit."
      fi
      exit 1
    fi
  fi
}

func_search_jython () {
  if [ ! -f ${JYTHON_SCRIPT} ]
  then
    if ${HAVE_TTY}
    then
      echo "[$(date +%F\ %H:%M:%S)] [ERROR] Jython script \"${JYTHON_SCRIPT}\" not found. Exit."
    fi
    exit 1
  fi
}

func_start_listeners () {
  if ${HAVE_TTY}
  then
    echo "[$(date +%F\ %H:%M:%S)] [INFO] Start jython script."
  fi
  ${WSADMIN_SCRIPT} -lang jython -f ${JYTHON_SCRIPT}
  EXIT_CODE=${?}
}

#
func_search_wsadmin
func_search_jython
func_start_listeners

#
if ${HAVE_TTY}
then
  if [ ${EXIT_CODE} -eq 0 ]
  then
    echo "[$(date +%F\ %H:%M:%S)] [INFO] Done. Exit code ${EXIT_CODE}"
  else
    echo "[$(date +%F\ %H:%M:%S)] [WARN] Done. Exit code ${EXIT_CODE}"
  fi
fi
#
exit ${EXIT_CODE}
