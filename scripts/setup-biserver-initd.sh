#!/bin/sh

set -eu
export LC_ALL=C

. /opt/scripts/set-utils.sh

########

execPattern="\.\(sh\|run\)$"
tarPattern="\.\(tar\|tar\.gz\|tgz\|tar\.bz2\|tbz2\|tar\.xz\|txz\)$"
zipPattern="\.\(zip\|kar\)$"

matches() {
	string="${1:?}"
	pattern="${2:?}"
	printf -- '%s' "${string}" | grep -q "${pattern}"
}

extractArchive() {
	source="${1:?}"
	target="${2:?}"
	if matches "${source}" "${tarPattern}"; then
		tar -C "${target}" -xf "${source}"
	elif matches "${source}" "${zipPattern}"; then
		unzip -qod "${target}" "${source}"
	fi
}

copyDirectory() {
	source="${1:?}"
	target="${2:?}"
	cp -fa "${source}"/. "${target}"

	# Execute ERB files
	recursiveExecuteErbs() {
		for path in "${1:?}"/*; do
			if [ -d "${path}" ]; then
				recursiveExecuteErbs "${path}"
			elif matches "${path}" "\.erb$"; then
				printf "%s\n" "[INFO] Executing ERB file: ${path}"
				dirname=${path%/*}; basename=$(basename "${path}" .erb)
				output=${target}${dirname##${source}}/${basename}
				erb -T - "${output}.erb" > "${output}"
			fi
		done
	}
	recursiveExecuteErbs "${source}"

	# Compress directories ending in .zip, .pfm or .pgus
	recursiveZipDirs() {
		for zip in "${1:?}"/*; do
			if [ -d "${zip}" ]; then
				if matches "${zip}" "\.\(zip\|pfm\|pgus\)$"; then
					printf "%s\n" "[INFO] Compressing directory: ${zip}"
					dirname=${zip%/*}; basename=${zip##*/}
					output=${target}${dirname##${source}}/${basename}
					(cd "${output}" || exit; zip -qmr ../"${basename}.tmp" ./)
					rmdir "${output}"; mv "${output}.tmp" "${output}"
				else
					recursiveZipDirs "${zip}"
				fi
			fi
		done
	}
	recursiveZipDirs "${source}"
}

isPentahoPlugin() {
	source="${1:?}"
	if [ -d "${source}" ]; then
		if [ -f "${source}"/plugin.xml ]; then
			return 0
		fi
	elif [ -f "${entry}" ]; then
		if matches "${source}" "${tarPattern}"; then
			if tar -tf "${source}" | grep -q '^.*/plugin\.xml$'; then
				return 0
			fi
		elif matches "${source}" "${zipPattern}"; then
			if unzip -Z1 "${source}" | grep -q '^.*/plugin\.xml$'; then
				return 0
			fi
		fi
	fi
	return 1
}

initdFromDir() {
	directory="${1:?}"
	_LC_COLLATE=${LC_COLLATE-}; LC_COLLATE=C
	for entry in "${directory}"/*; do
		if [ -d "${entry}" ]; then
			# Copy directories
			case "${entry}" in
				*.__root__)
					logInfo "Copying directory \"${entry}\" to root directory..."
					copyDirectory "${entry}"/. "${BISERVER_HOME}"
					;;
				*.__webapp_pentaho__)
					logInfo "Copying directory \"${entry}\" to Pentaho webapp directory..."
					copyDirectory "${entry}"/. "${CATALINA_BASE}"/webapps/"${WEBAPP_PENTAHO_DIRNAME}"
					;;
				*.__webapp_pentaho_style__)
					logInfo "Copying directory \"${entry}\" to Pentaho Style webapp directory..."
					copyDirectory "${entry}"/. "${CATALINA_BASE}"/webapps/"${WEBAPP_PENTAHO_STYLE_DIRNAME}"
					;;
				*.__pentaho_solutions__)
					logInfo "Copying directory \"${entry}\" to solutions directory..."
					copyDirectory "${entry}"/. "${BISERVER_HOME}"/"${SOLUTIONS_DIRNAME}"
					;;
				*.__data__)
					logInfo "Copying directory \"${entry}\" to data directory..."
					copyDirectory "${entry}"/. "${BISERVER_HOME}"/"${DATA_DIRNAME}"
					;;
				*.__plugin__)
					logInfo "Installing plugin \"${entry}\"..."
					copyDirectory "${entry}"/. "${BISERVER_HOME}"/"${SOLUTIONS_DIRNAME}"/system
					;;
				*)
					# Determine if it is a Pentaho plugin
					if isPentahoPlugin "${entry}"; then
						logInfo "Installing plugin \"${entry}\"..."
						copyDirectory "${entry}"/. "${BISERVER_HOME}"/"${SOLUTIONS_DIRNAME}"/system
					else
						logInfo "Copying directory \"${entry}\" to root directory..."
						copyDirectory "${entry}"/. "${BISERVER_HOME}"
					fi
					;;
			esac
		elif [ -f "${entry}" ]; then
			# Execute shell scripts
			if matches "${entry}" "${execPattern}"; then
				logInfo "Executing script \"${entry}\""
				[ -x "${entry}" ] || chmod +x "${entry}"
				cd "${BISERVER_HOME}" && "${entry}"
			# Extract archives
			elif matches "${entry}" "\(${tarPattern}\|${zipPattern}\)"; then
				case "${entry}" in
					*.__root__.*)
						logInfo "Extracting file \"${entry}\" to root directory..."
						extractArchive "${entry}" "${BISERVER_HOME}"
						;;
					*.__webapp_pentaho__.*)
						logInfo "Extracting file \"${entry}\" to Pentaho webapp directory..."
						extractArchive "${entry}" "${CATALINA_BASE}"/webapps/"${WEBAPP_PENTAHO_DIRNAME}"
						;;
					*.__webapp_pentaho_style__.*)
						logInfo "Extracting file \"${entry}\" to Pentaho Style webapp directory..."
						extractArchive "${entry}" "${CATALINA_BASE}"/webapps/"${WEBAPP_PENTAHO_STYLE_DIRNAME}"
						;;
					*.__pentaho_solutions__.*)
						logInfo "Extracting file \"${entry}\" to solutions directory..."
						extractArchive "${entry}" "${BISERVER_HOME}"/"${SOLUTIONS_DIRNAME}"
						;;
					*.__data__.*)
						logInfo "Extracting file \"${entry}\" to data directory..."
						extractArchive "${entry}" "${BISERVER_HOME}"/"${DATA_DIRNAME}"
						;;
					*.__plugin__.*)
						logInfo "Installing plugin \"${entry}\"..."
						extractArchive "${entry}" "${BISERVER_HOME}"/"${SOLUTIONS_DIRNAME}"/system
						;;
					*)
						# Determine if it is a Pentaho plugin
						if isPentahoPlugin "${entry}"; then
							logInfo "Installing plugin \"${entry}\"..."
							extractArchive "${entry}" "${BISERVER_HOME}"/"${SOLUTIONS_DIRNAME}"/system
						else
							logInfo "Extracting file \"${entry}\" to root directory..."
							extractArchive "${entry}" "${BISERVER_HOME}"
						fi
						;;
					esac
			else
				logWarn "Ignoring file \"${entry}\""
			fi
		else
			logWarn "Ignoring entry \"${entry}\""
		fi
	done
	LC_COLLATE=$_LC_COLLATE
}

if [ -d "${BISERVER_INITD}" ]; then
	initdFromDir "${BISERVER_INITD}"
fi
