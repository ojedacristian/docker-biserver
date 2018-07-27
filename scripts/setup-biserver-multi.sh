#!/bin/sh

set -eu
export LC_ALL=C

. /opt/scripts/set-utils.sh

########

ROOT_WEBAPP_DIRNAME=$(printf -- '%s' "${BISERVER_SETUP_JSON}" | jq -r '.root')
ROOT_WEBAPP_DIRNAME_SUBST=$(quoteSubst "${ROOT_WEBAPP_DIRNAME}")

BISERVER_LIST=$(printf -- '%s' "${BISERVER_SETUP_JSON}" | jq -c '.servers|map(select(.enabled))')
BISERVER_COUNT=$(printf -- '%s' "${BISERVER_LIST}" | jq -r '.|length-1')

WAS_DEFAULT_NAME_FOUND=false

_IFS=${IFS}; IFS="$(printf '\nx')"; IFS="${IFS%x}"
for server_index in $(seq 0 "${BISERVER_COUNT}"); do
	server=$(printf -- '%s' "${BISERVER_LIST}" | jq --arg i "${server_index}" ".[\$i|tonumber]")
	name=$(printf -- '%s' "${server}" | jq -r '.name')
	env_map=$(printf -- '%s' "${server}" | jq '.env')
	env_keys=$(printf -- '%s' "${env_map}" | jq -r 'keys[]')

	if [ "${name}" = "${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME}" ]; then
		WAS_DEFAULT_NAME_FOUND=true
	fi

	logInfo "Configuring \"${name}\" server..."

	( # Server environment
		export BISERVER_MULTI_SETUP_ENABLED=true

		if [ "${name}" = "${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME}" ]; then
			#export BISERVER_KETTLE_DIRNAME="${BISERVER_KETTLE_DEFAULT_DIRNAME}"
			export BISERVER_SOLUTIONS_DIRNAME="${BISERVER_SOLUTIONS_DEFAULT_DIRNAME}"
			export BISERVER_DATA_DIRNAME="${BISERVER_DATA_DEFAULT_DIRNAME}"
			export BISERVER_WEBAPP_PENTAHO_DIRNAME="${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME}"
			export BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME="${BISERVER_WEBAPP_PENTAHO_STYLE_DEFAULT_DIRNAME}"
		else
			#export BISERVER_KETTLE_DIRNAME="${name}-kettle"
			export BISERVER_SOLUTIONS_DIRNAME="${name}-solutions"
			export BISERVER_DATA_DIRNAME="${name}-data"
			export BISERVER_WEBAPP_PENTAHO_DIRNAME="${name}"
			export BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME="${name}-style"
		fi

		for env_key in ${env_keys}; do
			env_value=$(printf -- '%s' "${env_map}" | jq -r --arg k "${env_key}" ".[\$k]")
			export "${env_key}=${env_value}"
		done

		/opt/scripts/setup-biserver.sh
	)
done
IFS=${_IFS}

########

sed -r \
	-e "s|%ROOT_WEBAPP_DIRNAME%|${ROOT_WEBAPP_DIRNAME_SUBST}|g" \
	"${CATALINA_BASE}"/webapps/ROOT/index.html.tmpl \
	> "${CATALINA_BASE}"/webapps/ROOT/index.html

########

if [ "${WAS_DEFAULT_NAME_FOUND}" != true ]; then
	rm -rf \
		"${BISERVER_HOME:?}"/"${BISERVER_SOLUTIONS_DEFAULT_DIRNAME}"/ \
		"${BISERVER_HOME:?}"/"${BISERVER_DATA_DEFAULT_DIRNAME}"/ \
		"${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME}"/ \
		"${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DEFAULT_DIRNAME}"/
fi
