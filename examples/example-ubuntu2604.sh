#!/bin/sh

# NOTE: this file will be run as root (via sudo) in WSL default user home
# directory.

# https://olivergondza.github.io/2019/10/01/bash-strict-mode.html, but for POSIX
# shell. Using it, instead of BASH, to have less ways to shoot yourself in the
# foot.
set -eu
IFS=$(printf '\n\t')

# Java JDK 25 from Adoptium Temurin: https://adoptium.net/installation/linux#deb-installation-on-debian-or-ubuntu
# Could just use OpenJDK from Ubuntu, it is also OK, but we like Temurin:)
echo Configuring Adoptium Temurin repository...
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor > /etc/apt/trusted.gpg.d/adoptium.gpg
echo "deb https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" > /etc/apt/sources.list.d/adoptium.list

# appstream is used to provide data (especially app icons) for GUI "app stores"
# Removing it deletes /etc/apt/apt.conf.d/50appstream, which disables downloading
# those icons during each `apt-get update`, saving few megabytes of download.
#
# Also `echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99no-translations`
# could be done to also disable downloading extended English package descriptions,
# but they would affect `apt show` or `apt search`, so not doing it.
echo Purging appstream...
apt-get purge appstream --yes

echo Updating package list...
apt-get update

echo Upgrading all packages...
apt-get upgrade --verbose-versions --yes

# Install Java JDK 25 from Adoptium Temurin, as configured above
echo Installing Adoptium Temurin JDK 25...
# --no-install-recommends would drop some extra fonts and two ALSA packages, no not doing that, as we will use GUI in WSL
apt-get install temurin-25-jdk --verbose-versions --yes

# JQ
echo Installing jq...
# --no-install-recommends would drop nothing
apt-get install jq --verbose-versions --yes

# libnspr4 is apparently used by IntelliJ IDEA, so installing it to avoid
# "~/.local/opt/idea/plugins/jcef-plugin/jcef/cef_server: error while loading
# shared libraries: libnspr4.so: cannot open shared object file: No such file or
# directory" when for example starting the welcome guide.
echo "Installing libnspr4 (used by IntelliJ IDEA)..."
apt-get install libnspr4 --verbose-versions

# Enable async-profiler to work without root privileges
echo "Enabling kernel profiling without root privileges (used by async-profiler in IntelliJ IDEA)..."
cat <<EOF > /etc/sysctl.d/99-async-profiler.conf
# IntelliJ IDEA prompted that async-profiler needs those to collect information
# without root privileges. Details in
# https://github.com/async-profiler/async-profiler/blob/master/docs/GettingStarted.md,
# https://www.jetbrains.com/help/idea/custom-profiler-configurations.html#adjust-kernel
# and finally in https://www.kernel.org/doc/Documentation/sysctl/kernel.txt.
kernel/perf_event_paranoid = 1
kernel/kptr_restrict = 0
EOF

# Maven: https://maven.apache.org/install.html#binary-distribution
echo Installing Apache Maven...
# MAVEN_VERSION based on https://github.com/Contrum/install-maven
MAVEN_VERSION=$(curl -sSfL https://dlcdn.apache.org/maven/maven-3/ | grep -oP '3\.\d+\.\d+/' | tail -1 | tr -d '/')
wget https://dlcdn.apache.org/maven/maven-3/"$MAVEN_VERSION"/binaries/apache-maven-"$MAVEN_VERSION"-bin.tar.gz
mkdir /opt/apache-maven
tar xf apache-maven-"$MAVEN_VERSION"-bin.tar.gz --strip-components=1 -C /opt/apache-maven/
ln -s /opt/apache-maven/bin/mvn /usr/local/bin/mvn
rm apache-maven-"$MAVEN_VERSION"-bin.tar.gz
