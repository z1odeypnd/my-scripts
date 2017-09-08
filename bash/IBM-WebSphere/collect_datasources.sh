#!/bin/bash
###########################################################################
# IBM WebSphere datasource collector                                      #
#                                                                         #
# Author: Shokhin Andrey                                                  #
#                                                                         #
# https://github.com/z1odeypnd/my-scripts/tree/master/bash/IBM-WebSphere  #
###########################################################################
#
#
CUR_DATE="$(date +%F)"
HOST_NAME="$(echo "$(hostname)" | sed -e 's/\.rccf\.ru//g')"
SCR_DIR="$(cd "$(dirname ${0})" && pwd)"
RESULT_DIR="/tmp"
SCRIPT_NAME="$(basename $0)"
SCR_BASE_NAME="$(basename ${0} .sh)"
WS_DS_COL_SCR="${SCR_DIR}/${SCR_BASE_NAME}_collector_${HOST_NAME}_${CUR_DATE}.py"
WS_DS_COL_TMP="${RESULT_DIR}/${SCR_BASE_NAME}_temp_${HOST_NAME}_${CUR_DATE}.tmp"
WS_DS_COL_RESULT="${RESULT_DIR}/${SCR_BASE_NAME}_result_${HOST_NAME}_${CUR_DATE}"
PY_PASS_DEC_SCR="${SCR_DIR}/${SCR_BASE_NAME}_decoder_${HOST_NAME}_${CUR_DATE}.py"
PYTHON_PATH="$(which python 2> /dev/null)"
if $(tty -s)
then
  HAVE_TTY=1
else
  HAVE_TTY=0
fi
#
if [ "${1}" == "--silent" ]
then
  HAVE_TTY=0
fi
#
#
func_usage() {
  cat << EOF

    ${SCRIPT_NAME}

    Script for collect datasources,jndi names, jdbc URLs and passwords from 
  IBM WebSphere configuration files.
    Collected password stored in ${RESULT_DIR} named as 
  ${SCR_BASE_NAME}_result_{HOST_NAME}_{CURRENT_DATE}.csv.
    For example: ${WS_DS_COL_RESULT}.csv

    USAGE:
  ${SCRIPT_NAME} lo|nlo|nlowps

    Examples:
  ${SCRIPT_NAME} lo
  ${SCRIPT_NAME} NLO
  ${SCRIPT_NAME} nlowps

EOF
}
#
#
func_find_profile_path() {
  case ${1} in
    lo|LO)
      if [ -d "/opt/esb/profiles62/dmgr" ]
      then
        PROFILE_PATH="/opt/esb/profiles62/dmgr"
      elif [ -d "/opt/esb/profiles/dmgr" ]
      then
        PROFILE_PATH="/opt/esb/profiles/dmgr"
      else
        echo "[ERROR] Profile path not found. Exit."
        exit 1
      fi
      ;;
    nlo|nonlo|NLO|NONLO)
      if [ -d "/opt/esb/profiles62/dmgr" ]
      then
        PROFILE_PATH="/opt/esb/profiles62/dmgr"
      elif [ -d "/opt/esb/profiles/dmgr" ]
      then
        PROFILE_PATH="/opt/esb/profiles/dmgr"
      else
        echo "[ERROR] Profile path not found. Exit."
        exit 1
      fi
      ;;
    wps|WPS|nlowps|NLOWPS|nonlowps|NONLOWPS)
      if [ -d "/opt/esb/nonlowpsprod/profiles/dmgr" ]
      then
        PROFILE_PATH="/opt/esb/nonlowpsprod/profiles/dmgr"
      elif [ -d "/opt/esb/nonlowpspreprod/profiles/dmgr" ]
      then
        PROFILE_PATH="/opt/esb/nonlowpspreprod/profiles/dmgr"
      elif [ -d "/opt/esb/nonlowpstest2/profiles/dmgr" ]
      then
        PROFILE_PATH="/opt/esb/nonlowpstest2/profiles/dmgr"
      else
        echo "[ERROR] Profile path not found. Exit."
        exit 1
      fi
      ;;
    help)
      func_usage
      exit 0
      ;;
    *)
      func_usage >&2
      exit 1
      ;;
  esac
  WS_ADMIN_SCR="${PROFILE_PATH}/bin/wsadmin.sh"
  WS_ADMIN_RUN="${WS_ADMIN_SCR} -lang jython -conntype none -f"
  SEC_XML="$(find ${PROFILE_PATH}/config/cells/*/ -type f -prune -name "security.xml")"
  WS_DS_COL_SCR="${SCR_DIR}/${SCR_BASE_NAME}_${1}_collector_${HOST_NAME}_${CUR_DATE}.py"
  WS_DS_COL_TMP="${RESULT_DIR}/${SCR_BASE_NAME}_${1}_temp_${HOST_NAME}_${CUR_DATE}.tmp"
  WS_DS_COL_RESULT="${RESULT_DIR}/${SCR_BASE_NAME}_${1}_result_${HOST_NAME}_${CUR_DATE}"
  PY_PASS_DEC_SCR="${SCR_DIR}/${SCR_BASE_NAME}_${1}_decoder_${HOST_NAME}_${CUR_DATE}.py"
}
#
# Create jython script
func_create_ds_collector() {
  if [ ${HAVE_TTY} -eq 1 ]
  then
    cat << EOF >&1
[$(date +%F\ %H:%M:%S)] [INFO] Started.

EOF
  fi
#
  if [ ${HAVE_TTY} -eq 1 ]
  then
    cat << EOF >&1
[$(date +%F\ %H:%M:%S)] [INFO] Create wsadmin script.

EOF
  fi
  cat << EOF > "${WS_DS_COL_SCR}"
jaasAliasList = AdminConfig.list('JAASAuthData').splitlines()
for eachCell in AdminConfig.list('Cell').splitlines():
  cellName = AdminConfig.showAttribute(eachCell, 'name')
  for eachClusterServer in AdminConfig.list('ServerCluster', eachCell).splitlines():
    clusterName = AdminConfig.showAttribute(eachClusterServer, 'name')
    for eachDatasource in AdminConfig.list("DataSource", eachClusterServer).splitlines():
      dsJndiName = AdminConfig.showAttribute(eachDatasource, 'jndiName')
      dsAuthAlias = ""
      dsUserId = ""
      dsURL = ""
      dbName = ""
      dbSrvName = ""
      dbPortNum = ""
      dsPass = ""
      dsProviderType = ""
      dsProviderType = AdminConfig.showAttribute(eachDatasource, 'providerType')
      propSet = AdminConfig.showAttribute(eachDatasource, 'propertySet')
      resPropList = AdminConfig.list('J2EEResourceProperty', propSet).splitlines()
      try:
        dsAuthAlias = str(AdminConfig.showAttribute(eachDatasource, 'authDataAlias'))
      except:
        dsAuthAlias = ""
      if dsAuthAlias:
        if dsAuthAlias.find("None") != -1:
          dsAuthAlias = ""
        if dsAuthAlias.find("(") != -1:
          dsAuthAlias = ""
      else:
        dsAuthAlias = ""
      if dsAuthAlias:
        for jaasAlias in jaasAliasList:
          jaasAliasName = AdminConfig.showAttribute(jaasAlias, 'alias')
          if jaasAliasName == dsAuthAlias:
            dsUserId = AdminConfig.showAttribute(jaasAlias, 'userId')
      for resProperty in resPropList:
        propName = AdminConfig.showAttribute(resProperty, 'name')
        propValue = AdminConfig.showAttribute(resProperty, 'value')
        if propName == "URL" and propValue != "":
          dsURL = propValue
        if propName == "databaseName" and propValue != "":
          dbName = propValue
        if propName == "serverName" and propValue != "":
          dbSrvName = propValue
        if propName == "portNumber" and propValue != "":
          dbPortNum = propValue
        if propName == "user" and propValue != "" and dsUserId == "":
          dsUserId = propValue
        if propName == "password" and propValue != "" and dsPass == "":
          dsPass = propValue
      if dsURL == "":
        if dbSrvName != "" and dbName != "" and dbPortNum != "":
          try:
            if dsProviderType.find("ybase") != -1:
              dsURL = "jdbc:sybase:Tds:%s:%s/%s" % (dbSrvName, dbPortNum, dbName)
            else:
              dsURL = "%s:%s:%s" % (dbSrvName, dbPortNum, dbName)
          except:
            dsURL = "%s:%s:%s" % (dbSrvName, dbPortNum, dbName)
      print '%s;%s;%s;%s;%s;%s;%s;' % (cellName, clusterName, dsJndiName, dsAuthAlias, dsUserId, dsURL, dsPass)
EOF
}
#
# Run jython script
func_ds_collect() {
  if [ ${HAVE_TTY} -eq 1 ]
  then
    cat << EOF >&1
[$(date +%F\ %H:%M:%S)] [INFO] Start wsadmin script.
EOF
  fi

  ${WS_ADMIN_RUN} "${WS_DS_COL_SCR}" | egrep -v "^WASX.*" > "${WS_DS_COL_TMP}"

  if [ ${HAVE_TTY} -eq 1 ]
  then
    cat << EOF >&1
[$(date +%F\ %H:%M:%S)] [INFO] End wsadmin script.

EOF
  fi
}
#
# Create python script for decode XOR-passwords
func_create_decoder() {
  if [ ${HAVE_TTY} -eq 1 ]
  then
    cat << EOF >&1
[$(date +%F\ %H:%M:%S)] [INFO] Create XOR-decoding script.
EOF
  fi
  cat << EOF > "${PY_PASS_DEC_SCR}"
import sys
import binascii

def xorsum(val1, val2):
  password = ''
  for a, b in zip(val1, val2):
    password = ''.join([password, chr(ord(a) ^ ord(b))])
  return password

def decode_xor(xor_str):
  xor_str = xor_str.replace('{xor}', '')
  value1 = binascii.a2b_base64(xor_str)
  value2 = '_' * len(value1)
  return xorsum(value1, value2)


if __name__ == '__main__':
  if len(sys.argv) > 1:
    print decode_xor(sys.argv[1])
elif __name__ == 'main':
  if len(sys.argv) > 0:
    print decode_xor(sys.argv[0])
EOF
}
#
# Run XOR-decoding
func_decode_xor_pass() {
  XOR_DB_PASS="${1}"
  if [ ! -z "${XOR_DB_PASS}" ] 
  then
    if [ ! -z "${PYTHON_PATH}" ]
    then
      CLEAN_DB_PASS="$(${PYTHON_PATH} ${PY_PASS_DEC_SCR} ${XOR_DB_PASS})"
    else
      CLEAN_DB_PASS="$(${WS_ADMIN_RUN} ${PY_PASS_DEC_SCR} ${XOR_DB_PASS} | egrep -v "^WASX.*")"
    fi
  else
    CLEAN_DB_PASS=""
  fi
  echo "${CLEAN_DB_PASS}"
}
#
#
func_create_result_csv() {
  DS_STRINGS_ARRAY=($(cat ${WS_DS_COL_TMP}))
  cat << EOF > "${WS_DS_COL_RESULT}.csv"
"Cell";"Cluster";"JNDI name";"JAAS alias";"UserID";"URL";"XOR DB Pass";"Clean DB Pass";
EOF
#  echo '"Cell";"Cluster";"JNDI name";"JAAS alias";"UserID";"URL";"XOR DB Pass";"Clean DB Pass";' > "${WS_DS_COL_RESULT}.csv"
  for DS_STRING in ${DS_STRINGS_ARRAY[@]}
  do
    CELL_NAME="$(echo "${DS_STRING}" | awk -F ";" '{print $1}')"
    CLUSTER_NAME="$(echo "${DS_STRING}" | awk -F ";" '{print $2}')"
    JNDI_NAME="$(echo "${DS_STRING}" | awk -F ";" '{print $3}')"
    JAAS_ALIAS="$(echo "${DS_STRING}" | awk -F ";" '{print $4}')"
    USER_ID="$(echo "${DS_STRING}" | awk -F ";" '{print $5}')"
    DB_URL="$(echo "${DS_STRING}" | awk -F ";" '{print $6}')"
    DB_PASS="$(echo "${DS_STRING}" | awk -F ";" '{print $7}')"
    if [ ! -z "${JAAS_ALIAS}" ] && [ -z "${DB_PASS}" ]
    then
      XOR_AUTH_PASS="$(grep "alias=\"${JAAS_ALIAS}\"" "${SEC_XML}" | sed -e 's/.*password="//g' -e 's/"\ .*//g' -e 's/"\/.*//g')"
      
    else
      XOR_AUTH_PASS="${DB_PASS}"
    fi
#
    if [ ! -z "${XOR_AUTH_PASS}" ]
    then
      if [ ${HAVE_TTY} -eq 1 ]
      then
        cat << EOF >&1
[$(date +%F\ %H:%M:%S)] [INFO] Start decode XOR-password for JNDI "${JNDI_NAME}".
EOF
      fi
      CLEAN_AUTH_PASS="$(func_decode_xor_pass ${XOR_AUTH_PASS})"
      if [ ${HAVE_TTY} -eq 1 ]
      then
        cat << EOF >&1
[$(date +%F\ %H:%M:%S)] [INFO] End decode XOR-password for JNDI "${JNDI_NAME}".

EOF
      fi
    else
      CLEAN_AUTH_PASS=""
    fi
    cat << EOF >> "${WS_DS_COL_RESULT}.csv"
"${CELL_NAME}";"${CLUSTER_NAME}";"${JNDI_NAME}";"${JAAS_ALIAS}";"${USER_ID}";"${DB_URL}";"${XOR_AUTH_PASS}";"${CLEAN_AUTH_PASS}";
EOF
  done
}
#
#
func_cleanup() {
  rm "${WS_DS_COL_SCR}"
  rm "${WS_DS_COL_TMP}"
  rm "${PY_PASS_DEC_SCR}"
  find "${SCR_DIR}/" -type f -name "${SCR_BASE_NAME}_*" -mtime +2 -exec rm {} \;
}
#
#
func_find_profile_path ${1}
func_cleanup &>/dev/null
func_create_ds_collector
func_ds_collect
func_create_decoder
func_create_result_csv
func_cleanup &>/dev/null
