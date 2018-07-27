#!/bin/sh

set -eu
export LC_ALL=C

. /opt/scripts/set-utils.sh

########

#BISERVER_KETTLE_WAS_RENAMED=false
if [ "${BISERVER_KETTLE_DIRNAME}" != "${BISERVER_KETTLE_DEFAULT_DIRNAME}" ]; then
	logInfo "Kettle directory was renamed to \"${BISERVER_KETTLE_DIRNAME}\""
	#BISERVER_KETTLE_WAS_RENAMED=true
	if [ ! -e "${BISERVER_HOME}"/"${BISERVER_KETTLE_DIRNAME}" ]; then
		if [ "${BISERVER_MULTI_SETUP_ENABLED}" = true ]; then
			logInfo 'Creating kettle symlink...'
			ln -rs "${BISERVER_HOME:?}"/"${BISERVER_KETTLE_DEFAULT_DIRNAME}"/ "${BISERVER_HOME}"/"${BISERVER_KETTLE_DIRNAME}"
		else
			logInfo 'Moving kettle directory...'
			cp -a "${BISERVER_HOME:?}"/"${BISERVER_KETTLE_DEFAULT_DIRNAME}"/ "${BISERVER_HOME}"/"${BISERVER_KETTLE_DIRNAME}"
			rm -r "${BISERVER_HOME:?}"/"${BISERVER_KETTLE_DEFAULT_DIRNAME}"/
		fi
	fi
fi

#BISERVER_SOLUTIONS_DIRNAME_WAS_RENAMED=false
if [ "${BISERVER_SOLUTIONS_DIRNAME}" != "${BISERVER_SOLUTIONS_DEFAULT_DIRNAME}" ]; then
	logInfo "Solutions directory was renamed to \"${BISERVER_SOLUTIONS_DIRNAME}\""
	#BISERVER_SOLUTIONS_DIRNAME_WAS_RENAMED=true
	if [ ! -e "${BISERVER_HOME}"/"${BISERVER_SOLUTIONS_DIRNAME}" ]; then
		if [ "${BISERVER_MULTI_SETUP_ENABLED}" = true ]; then
			logInfo 'Copying solutions directory...'
			cp -a "${BISERVER_HOME:?}"/"${BISERVER_SOLUTIONS_DEFAULT_DIRNAME}"/ "${BISERVER_HOME}"/"${BISERVER_SOLUTIONS_DIRNAME}"
		else
			logInfo 'Moving solutions directory...'
			cp -a "${BISERVER_HOME:?}"/"${BISERVER_SOLUTIONS_DEFAULT_DIRNAME}"/ "${BISERVER_HOME}"/"${BISERVER_SOLUTIONS_DIRNAME}"
			rm -r "${BISERVER_HOME:?}"/"${BISERVER_SOLUTIONS_DEFAULT_DIRNAME}"/
		fi
	fi
fi

#BISERVER_DATA_DIRNAME_WAS_RENAMED=false
if [ "${BISERVER_DATA_DIRNAME}" != "${BISERVER_DATA_DEFAULT_DIRNAME}" ]; then
	logInfo "Data directory was renamed to \"${BISERVER_DATA_DIRNAME}\""
	#BISERVER_DATA_DIRNAME_WAS_RENAMED=true
	if [ ! -e "${BISERVER_HOME}"/"${BISERVER_DATA_DIRNAME}" ]; then
		if [ "${BISERVER_MULTI_SETUP_ENABLED}" = true ]; then
			logInfo 'Copying data directory...'
			cp -a "${BISERVER_HOME:?}"/"${BISERVER_DATA_DEFAULT_DIRNAME}"/ "${BISERVER_HOME}"/"${BISERVER_DATA_DIRNAME}"
		else
			logInfo 'Moving data directory...'
			cp -a "${BISERVER_HOME:?}"/"${BISERVER_DATA_DEFAULT_DIRNAME}"/ "${BISERVER_HOME}"/"${BISERVER_DATA_DIRNAME}"
			rm -r "${BISERVER_HOME:?}"/"${BISERVER_DATA_DEFAULT_DIRNAME}"/
		fi
	fi
fi

########

#BISERVER_WEBAPP_PENTAHO_WAS_RENAMED=false
if [ "${BISERVER_WEBAPP_PENTAHO_DIRNAME}" != "${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME}" ]; then
	logInfo "Pentaho webapp directory was renamed to \"${BISERVER_WEBAPP_PENTAHO_DIRNAME}\""
	#BISERVER_WEBAPP_PENTAHO_WAS_RENAMED=true
	if [ ! -e "${CATALINA_BASE}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DIRNAME}" ]; then
		if [ "${BISERVER_MULTI_SETUP_ENABLED}" = true ]; then
			logInfo 'Copying Pentaho webapp directory...'
			cp -a "${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME}"/ "${CATALINA_BASE}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DIRNAME}"
		else
			logInfo 'Moving Pentaho webapp directory...'
			cp -a "${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME}"/ "${CATALINA_BASE}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DIRNAME}"
			rm -r "${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME}"/
		fi
	fi
fi

BISERVER_WEBAPP_PENTAHO_STYLE_WAS_RENAMED=false
if [ "${BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME}" != "${BISERVER_WEBAPP_PENTAHO_STYLE_DEFAULT_DIRNAME}" ]; then
	logInfo "Pentaho style webapp directory was renamed to \"${BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME}\""
	BISERVER_WEBAPP_PENTAHO_STYLE_WAS_RENAMED=true
	if [ ! -e "${CATALINA_BASE}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME}" ]; then
		if [ "${BISERVER_MULTI_SETUP_ENABLED}" = true ]; then
			logInfo 'Copying Pentaho style webapp directory...'
			cp -a "${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DEFAULT_DIRNAME}"/ "${CATALINA_BASE}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME}"
		else
			logInfo 'Moving Pentaho style webapp directory...'
			cp -a "${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DEFAULT_DIRNAME}"/ "${CATALINA_BASE}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME}"
			rm -r "${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DEFAULT_DIRNAME}"/
		fi
	fi
fi

#
# This recursive replacement has dangerous implications compared to the benefits it brings.
# Uncomment only if there is a bug related to the rename operation.
#
#if [ "${BISERVER_WEBAPP_PENTAHO_WAS_RENAMED}" = true ]; then
#	logInfo 'Updating references of Pentaho webapp...'
#	find \
#		"${BISERVER_HOME:?}/${BISERVER_SOLUTIONS_DIRNAME}" \
#		"${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DIRNAME}" \
#		"${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME}" \
#		-type f \( -iname '*.html' -o -iname '*.jsp' \) \
#		-exec sed -i "s|/${BISERVER_WEBAPP_PENTAHO_DEFAULT_DIRNAME_RE}/|/${BISERVER_WEBAPP_PENTAHO_DIRNAME_SUBST}/|g" '{}' \;
#fi
#

if [ "${BISERVER_WEBAPP_PENTAHO_STYLE_WAS_RENAMED}" = true ]; then
	logInfo 'Updating references of Pentaho style webapp...'
	find \
		"${BISERVER_HOME:?}"/"${BISERVER_SOLUTIONS_DIRNAME}" \
		"${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_DIRNAME}" \
		"${CATALINA_BASE:?}"/webapps/"${BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME}" \
		-type f \( -iname '*.css' -o -iname '*.html' -o -iname '*.jsp' -o -iname '*.properties' -o -iname '*.xsl' \) \
		-exec sed -i "s|/${BISERVER_WEBAPP_PENTAHO_STYLE_DEFAULT_DIRNAME_RE}/|/${BISERVER_WEBAPP_PENTAHO_STYLE_DIRNAME_SUBST}/|g" '{}' \;
fi
