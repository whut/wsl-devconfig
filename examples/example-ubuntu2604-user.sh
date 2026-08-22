#!/bin/sh

# NOTE: this file will be run as WSL default user in its home directory.

# https://olivergondza.github.io/2019/10/01/bash-strict-mode.html, but for POSIX
# shell. Using it, instead of BASH, to have less ways to shoot yourself in the
# foot.
set -eu
IFS=$(printf '\n\t')

# This folder will be used to add own binaries to PATH. This folder is added
# automatically to PATH in .profile (at least in Debian/Ubuntu), but only if
# exists. As there is no way to affect environment variables of parent shell, we
# will just need to ask the user to restart the shell. In Vagrant this would be
# simply done by [shell
# reset](https://developer.hashicorp.com/vagrant/docs/provisioning/shell#reset)
#
# Alternatively this folder could be created in cloud-init script, so before the
# user logs in, but this is user-specific, so should not be done there. Yet
# another alternative would be to do `exec $SHELL` but this would definitely be
# not exactly the same shell.
mkdir --parents ~/.local/bin

# IntelliJ IDEA: https://www.jetbrains.com/help/idea/installation-guide.html#standalone_linux
echo "Installing IntelliJ IDEA..."
# IIU = IntelliJ IDEA Ultimate, IU = IntelliJ IDEA Community, but as now the are unified, so it does not matter
wget --content-disposition "https://download.jetbrains.com/product?code=IIU&latest&distribution=linux"
# To enable automatic updates, install IDEA in ~/.local/opt/idea, not in /opt/idea.
mkdir --parents ~/.local/opt/idea
tar xf idea-*.tar.gz --strip-components=1 -C ~/.local/opt/idea --checkpoint=50000
rm idea-*.tar.gz
# Linking to idea, not idea.sh, because
# https://youtrack.jetbrains.com/articles/SUPPORT-A-56/How-to-handle-Consider-switching-to-a-native-launcher-notification
ln -s ~/.local/opt/idea/bin/idea ~/.local/bin/idea

# Details above.      
echo "Please restart the shell to have ~/.local/bin added to PATH."
