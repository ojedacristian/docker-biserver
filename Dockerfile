FROM docker.io/ubuntu:18.04

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		apt-transport-https \
		apt-utils \
		bash \
		bzip2 \
		ca-certificates \
		curl \
		diffutils \
		dnsutils \
		file \
		findutils \
		gnupg \
		gzip \
		iputils-ping \
		jq \
		libarchive-tools \
		locales \
		lsb-release \
		lzip \
		lzma \
		lzop \
		mime-support \
		nano \
		netcat-openbsd \
		openjdk-8-jdk \
		openssl \
		rsync \
		ruby \
		runit \
		tar \
		tzdata \
		unzip \
		xxd \
		xz-utils \
		zip \
	&& rm -rf /var/lib/apt/lists/*

# Install PostgreSQL client
RUN export DEBIAN_FRONTEND=noninteractive \
	&& printf '%s\n' 'deb https://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
	&& curl -fsSL 'https://www.postgresql.org/media/keys/ACCC4CF8.asc' | apt-key add - \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		postgresql-client-12 \
	&& rm -rf /var/lib/apt/lists/*

# Install MySQL client
RUN export DEBIAN_FRONTEND=noninteractive \
	&& printf '%s\n' 'deb https://repo.mysql.com/apt/ubuntu/ bionic mysql-8.0' > /etc/apt/sources.list.d/mysql.list \
	&& curl -fsSL 'https://repo.mysql.com/RPM-GPG-KEY-mysql' | apt-key add - \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		mysql-client \
	&& rm -rf /var/lib/apt/lists/*

# Install Tini
COPY --from=docker.io/hectormolinero/tini:latest --chown=root:root /usr/bin/tini /usr/bin/tini

# Install Supercronic
COPY --from=docker.io/hectormolinero/supercronic:latest --chown=root:root /usr/bin/supercronic /usr/bin/supercronic

# Create users and groups
ENV BISERVER_USER_UID=1000
ENV BISERVER_USER_GID=1000
RUN printf '%s\n' 'Creating users and groups...' \
	&& groupadd \
		--gid "${BISERVER_USER_GID:?}" \
		biserver \
	&& useradd \
		--uid "${BISERVER_USER_UID:?}" \
		--gid "${BISERVER_USER_GID:?}" \
		--shell "$(command -v bash)" \
		--home-dir /var/cache/biserver/ \
		--create-home \
		biserver

# Setup locale
RUN printf '%s\n' 'en_US.UTF-8 UTF-8' > /etc/locale.gen
RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8 ||:
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Setup timezone
ENV TZ=UTC
RUN ln -snf "/usr/share/zoneinfo/${TZ:?}" /etc/localtime
RUN printf '%s\n' "${TZ:?}" > /etc/timezone

# Copy build scripts
COPY --chown=root:root scripts/build/ /usr/share/biserver/build/

# Java environment
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
RUN update-java-alternatives --set java-1.8.0-openjdk-amd64

# Tomcat environment
ENV CATALINA_HOME="/var/lib/biserver/tomcat"
ENV CATALINA_BASE="${CATALINA_HOME}"
ENV CATALINA_PID="${CATALINA_BASE}/bin/catalina.pid"
ENV CATALINA_OPTS_JAVA_XMS=1024m
ENV CATALINA_OPTS_JAVA_XMX=4096m
ENV CATALINA_OPTS_EXTRA=

# Install Tomcat
ARG TOMCAT_MAJOR_VERSION=8
ARG TOMCAT_MINOR_VERSION=5
ARG TOMCAT_PATCH_VERSION=latest
RUN printf '%s\n' 'Installing Tomcat...' \
	# Install dependencies
	&& RUN_PKGS="libapr1 libssl1.1" \
	&& BUILD_PKGS="make gcc libapr1-dev libssl-dev" \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		${RUN_PKGS:?} ${BUILD_PKGS:?} \
	# Download Tomcat
	&& /usr/share/biserver/build/download-tomcat.sh \
		"${TOMCAT_MAJOR_VERSION:?}" \
		"${TOMCAT_MINOR_VERSION:?}" \
		"${TOMCAT_PATCH_VERSION:?}" \
		/tmp/tomcat/ \
	# Install Tomcat
	&& mkdir -p "${CATALINA_HOME:?}" "${CATALINA_BASE:?}" \
	&& (cd /tmp/tomcat/ \
		&& mv ./bin/ "${CATALINA_HOME:?}" \
		&& mv ./lib/ "${CATALINA_HOME:?}" \
		&& mv ./conf/ "${CATALINA_BASE:?}" \
		&& mkdir "${CATALINA_BASE:?}"/conf/Catalina/ \
		&& mkdir "${CATALINA_BASE:?}"/logs/ \
		&& mkdir "${CATALINA_BASE:?}"/temp/ \
		&& mkdir "${CATALINA_BASE:?}"/webapps/ \
		&& mkdir "${CATALINA_BASE:?}"/work/ \
	) \
	# Build and install Tomcat Native Library
	&& mkdir /tmp/tomcat-native/ \
	&& (cd /tmp/tomcat-native/ \
		&& tar --strip-components=1 -xf "${CATALINA_HOME:?}"/bin/tomcat-native.tar.gz \
		&& cd ./native/ && ./configure --prefix="${CATALINA_HOME:?}" \
		&& make && make install \
	) \
	# Hide version number
	&& mkdir -p "${CATALINA_HOME:?}"/lib/org/apache/catalina/util/ \
	&& bsdtar -xOf "${CATALINA_HOME:?}"/lib/catalina.jar org/apache/catalina/util/ServerInfo.properties \
		| sed 's|^\(server\.info\)=.*$|\1=Apache Tomcat|g' \
		> "${CATALINA_HOME:?}"/lib/org/apache/catalina/util/ServerInfo.properties \
	# Set permissions
	&& find \
		"${CATALINA_HOME:?}" "${CATALINA_BASE:?}" \
		-exec chown -h biserver:biserver '{}' ';' \
		-exec sh -c 'if [ -d "$1" ]; then chmod 755 "$1"; fi' _ '{}' ';' \
		-exec sh -c 'if [ -f "$1" ]; then chmod 644 "$1"; fi' _ '{}' ';' \
		-exec sh -c 'if [ -f "$1" ] && [ "${1##*.}" = "sh" ]; then chmod 755 "$1"; fi' _ '{}' ';' \
	# Cleanup
	&& apt-get purge -y ${BUILD_PKGS:?} \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/* \
	&& find /tmp/ -mindepth 1 -delete

# Copy Tomcat libraries and jars.json file
COPY --chown=biserver:biserver config/biserver/tomcat/lib/ "${CATALINA_BASE}"/lib/

# Download Tomcat libraries from jars.json file
RUN printf '%s\n' 'Downloading Tomcat libraries...' \
	&& jsonFile="${CATALINA_BASE:?}"/lib/jars.json \
	&& jarsCount="$(jq -r '.|length-1' "${jsonFile:?}")" \
	&& for i in $(seq 0 "${jarsCount:?}"); do \
		filename=$(jq -r --arg i "${i:?}" '.[$i|tonumber].filename' "${jsonFile:?}"); \
		checksum=$(jq -r --arg i "${i:?}" '.[$i|tonumber].checksum' "${jsonFile:?}"); \
		download=$(jq -r --arg i "${i:?}" '.[$i|tonumber].download' "${jsonFile:?}"); \
		output="${CATALINA_BASE:?}"/lib/"${filename:?}" \
		&& printf '%s\n' "Downloading \"${filename:?}\"..." \
		&& curl -Lo "${output:?}" "${download:?}" \
		&& printf '%s\n' "Verifying checksum..." \
		&& printf '%s\n' "${checksum:?}  ${output:?}" | sha256sum -c \
		&& chown biserver:biserver "${output:?}"; \
	done && rm -f "${jsonFile:?}"

# Pentaho BI Server environment
ENV BISERVER_HOME="/var/lib/biserver"
ENV BISERVER_INITD="/etc/biserver.init.d"

ARG KETTLE_DIRNAME="kettle"
ENV KETTLE_DIRNAME="${KETTLE_DIRNAME}"
ENV KETTLE_DEFAULT_DIRNAME="${KETTLE_DIRNAME}"

ARG SOLUTIONS_DIRNAME="pentaho-solutions"
ENV SOLUTIONS_DIRNAME="${SOLUTIONS_DIRNAME}"
ENV SOLUTIONS_DEFAULT_DIRNAME="${SOLUTIONS_DIRNAME}"

ARG DATA_DIRNAME="data"
ENV DATA_DIRNAME="${DATA_DIRNAME}"
ENV DATA_DEFAULT_DIRNAME="${DATA_DIRNAME}"

ARG WEBAPP_PENTAHO_DIRNAME="pentaho"
ENV WEBAPP_PENTAHO_DIRNAME="${WEBAPP_PENTAHO_DIRNAME}"
ENV WEBAPP_PENTAHO_DEFAULT_DIRNAME="${WEBAPP_PENTAHO_DIRNAME}"

ARG WEBAPP_PENTAHO_STYLE_DIRNAME="pentaho-style"
ENV WEBAPP_PENTAHO_STYLE_DIRNAME="${WEBAPP_PENTAHO_STYLE_DIRNAME}"
ENV WEBAPP_PENTAHO_STYLE_DEFAULT_DIRNAME="${WEBAPP_PENTAHO_STYLE_DIRNAME}"

# Install Pentaho BI Server
ARG BISERVER_VERSION='9.0.0.0-423'
ARG BISERVER_MAVEN_REPO='https://repo.stratebi.com/repository/pentaho-mvn/'
#ARG BISERVER_MAVEN_REPO='https://nexus.pentaho.org/content/groups/omni/'
RUN printf '%s\n' 'Installing Pentaho BI Server...' \
	# Download Pentaho BI Server
	&& /usr/share/biserver/build/download-biserver.sh "${BISERVER_VERSION:?}" "${BISERVER_MAVEN_REPO:?}" /tmp/biserver/ \
	# Install Pentaho BI Server
	&& mkdir -p \
		"${BISERVER_HOME:?}"/"${KETTLE_DIRNAME:?}" \
		"${BISERVER_HOME:?}"/"${SOLUTIONS_DIRNAME:?}" \
		"${BISERVER_HOME:?}"/"${DATA_DIRNAME:?}" \
		"${CATALINA_BASE:?}"/webapps/"${WEBAPP_PENTAHO_DIRNAME:?}" \
		"${CATALINA_BASE:?}"/webapps/"${WEBAPP_PENTAHO_STYLE_DIRNAME:?}" \
	&& (cd /tmp/biserver/ \
		&& bsdtar -C "${BISERVER_HOME:?}"/"${KETTLE_DIRNAME:?}" --strip-components=3 -xf ./pentaho-solutions.zip 'pentaho-solutions/system/kettle/*' \
		&& bsdtar -C "${BISERVER_HOME:?}"/"${SOLUTIONS_DIRNAME:?}" --strip-components=1 --exclude 'pentaho-solutions/system/kettle/*' -xf ./pentaho-solutions.zip \
		&& bsdtar -C "${BISERVER_HOME:?}"/"${DATA_DIRNAME:?}" --strip-components=1 -xf ./pentaho-data.zip \
		&& bsdtar -C "${CATALINA_BASE:?}"/webapps/"${WEBAPP_PENTAHO_DIRNAME:?}" -xf ./pentaho.war \
		&& bsdtar -C "${CATALINA_BASE:?}"/webapps/"${WEBAPP_PENTAHO_STYLE_DIRNAME:?}" -xf ./pentaho-style.war \
	) \
	# Set permissions
	&& find \
		"${BISERVER_HOME:?}" \
		-exec chown -h biserver:biserver '{}' ';' \
		-exec sh -c 'if [ -d "$1" ]; then chmod 755 "$1"; fi' _ '{}' ';' \
		-exec sh -c 'if [ -f "$1" ]; then chmod 644 "$1"; fi' _ '{}' ';' \
		-exec sh -c 'if [ -f "$1" ] && [ "${1##*.}" = "sh" ]; then chmod 755 "$1"; fi' _ '{}' ';' \
	# Cleanup
	&& find /tmp/ -mindepth 1 -delete

# Copy Tomcat config
COPY --chown=biserver:biserver config/biserver/tomcat/conf/ "${CATALINA_BASE}"/conf/
COPY --chown=biserver:biserver config/biserver/tomcat/webapps/ROOT/ "${CATALINA_BASE}"/webapps/ROOT/
COPY --chown=biserver:biserver config/biserver/tomcat/webapps/pentaho/ "${CATALINA_BASE}"/webapps/"${WEBAPP_PENTAHO_DIRNAME}"/
COPY --chown=biserver:biserver config/biserver/tomcat/webapps/pentaho-style/ "${CATALINA_BASE}"/webapps/"${WEBAPP_PENTAHO_STYLE_DIRNAME}"/

# Copy Pentaho BI Server config
COPY --chown=biserver:biserver config/biserver/pentaho-solutions/ "${BISERVER_HOME}"/"${SOLUTIONS_DIRNAME}"/
COPY --chown=biserver:biserver config/biserver/data/ "${BISERVER_HOME}"/"${DATA_DIRNAME}"/
COPY --chown=biserver:biserver config/biserver/*.* "${BISERVER_HOME}"/
COPY --chown=root:root config/biserver.init.d/ "${BISERVER_INITD}"/

# Copy crontab
COPY --chown=root:root config/crontab /etc/crontab

# Copy runtime scripts
COPY --chown=root:root scripts/bin/ /usr/share/biserver/bin/

# Copy services
COPY --chown=biserver:biserver scripts/service/ /usr/share/biserver/service/

# Don't declare volumes, let the user decide
#VOLUME "${BISERVER_HOME}"/"${SOLUTIONS_DIRNAME}"/system/jackrabbit/repository/
#VOLUME "${BISERVER_HOME}"/"${DATA_DIRNAME}/hsqldb/"
#VOLUME "${CATALINA_BASE}"/logs/

# Switch to Pentaho BI Server directory
WORKDIR "${BISERVER_HOME}"

# Drop root privileges
USER biserver:biserver

# Start all services
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/bin/runsvdir", "-P", "/usr/share/biserver/service/"]
