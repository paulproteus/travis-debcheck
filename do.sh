#!/bin/bash
set -e  # Fail on errors
set -x  # Verbosity all the way

EXTRA_GIT_BUILDPACKAGE_ARGS="--git-ignore-new"
SKIP_PBUILDER=true

sudo apt-get install git-buildpackage

# Get latest alpine packaging
git clone https://alioth.debian.org/anonscm/git/collab-maint/alpine.git

# Make sure it builds outside a pbuilder
cd alpine
git-buildpackage $EXTRA_GIT_BUILDPACKAGE_ARGS

if [[ "$SKIP_PBUILDER" -eq "true" ]] ; then
    exit 0  # skip pbuilder for now
fi

# Create a pbuilder chroot
sudo apt-get install ubuntu-dev-tools
pbuilder-dist sid create
pbuilder-dist sid build ../*.dsc

