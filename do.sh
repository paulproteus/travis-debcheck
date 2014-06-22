#!/bin/sh
set -e  # Fail on errors

sudo apt-get install git-buildpackage

# Get latest alpine packaging
git clone https://alioth.debian.org/anonscm/git/collab-maint/alpine.git

# Make sure it builds outside a pbuilder
cd alpine
git-buildpackage buildpackage

exit 0  # skip pbuilder for now

# Create a pbuilder chroot
sudo apt-get install ubuntu-dev-tools
pbuilder-dist sid create
pbuilder-dist sid build ../*.dsc

