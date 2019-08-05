#!/bin/sh

set -eu
export LC_ALL=C

VERSION_MAJOR="${1:?}"
VERSION_MINOR="${2:?}"
VERSION_PATCH="${3:?}"
TARGET_DIR="${4:?}"
BASE_URL='https://archive.apache.org/dist/tomcat'

# Cleanup trap
TMP_PKG=$(mktemp)
cleanup() { rm -f "${TMP_PKG}"; }
trap cleanup EXIT

if [ "${VERSION_PATCH}" = 'latest' ]; then
	# Each line has the following structure:
	#   <img src="/icons/folder.gif" alt="[DIR]"> <a href="v0.0.0/">v0.0.0/</a>
	VERSION_PATCH=$(curl -fsSL "${BASE_URL}/tomcat-${VERSION_MAJOR}/" \
		| sed -n "s|^.\{1,\}href=\"v${VERSION_MAJOR}\.${VERSION_MINOR}\.\([0-9]\{1,\}\)/\{0,1\}\".\{1,\}$|\1|p" \
		| sort -n | tail -1
	)
fi

VERSION="${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}"

# Download package
PKG_URL="${BASE_URL}/tomcat-${VERSION_MAJOR}/v${VERSION}/bin/apache-tomcat-${VERSION}.tar.gz"
curl -L "${PKG_URL}" > "${TMP_PKG}"

# Check package
PKG_CHECKSUM_URL="${PKG_URL}.sha512"
PKG_CHECKSUM=$(curl -L "${PKG_CHECKSUM_URL}" | cut -f1 -d' ')
printf -- '%s %s' "${PKG_CHECKSUM}" "${TMP_PKG}" | sha512sum -c

# Extract package
mkdir -p "${TARGET_DIR}"
tar -C "${TARGET_DIR}" --strip-components=1 -xf "${TMP_PKG}"
