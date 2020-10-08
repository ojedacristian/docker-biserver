#!/bin/sh

set -eu
export LC_ALL=C

WEBINFDIR="${CATALINA_BASE:?}/webapps/${WEBAPP_PENTAHO_DIRNAME:?}/WEB-INF"
CLASSPATH=$(find "${WEBINFDIR:?}/lib" "${CATALINA_BASE:?}/lib" -type d -printf '%p:%p/*:')

TMPCLASSPATH=$(mktemp -d)
trap 'rm -rf ${TMPCLASSPATH:?}; trap - EXIT; exit 0' EXIT TERM INT HUP

if [ -e "${WEBINFDIR:?}"/classes/kettle-password-encoder-plugins.xml ]; then
	cp "${WEBINFDIR:?}"/classes/kettle-password-encoder-plugins.xml "${TMPCLASSPATH:?}"
fi

cd "${BISERVER_HOME:?}"/"${SOLUTIONS_DIRNAME:?}"/system/kettle/
exec java \
		-classpath "${CLASSPATH:?}:${TMPCLASSPATH:?}" \
		-Dlog4j.configuration=file:"${WEBINFDIR:?}/classes/log4j.xml" \
		org.pentaho.di.pan.Pan -initialDir "${BISERVER_HOME:?}" "$@"
