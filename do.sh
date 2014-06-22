#!/bin/bash
set -e  # Fail on errors
set -x  # Verbosity all the way

GIT_IGNORE_NEW="true"  # hack for now
USE_ALIOTH="false"
SKIP_PBUILDER=true

## Pick which one to build -- the Asheesh fork, or the Alioth packaging
if [[ "$USE_ALIOTH" == "true" ]] ; then
    GIT_URL="https://alioth.debian.org/anonscm/git/collab-maint/alpine.git"
else
    GIT_URL="https://github.com/paulproteus/alpine-packaging.git"
fi

if [[ "$GIT_IGNORE_NEW" == "true" ]] ; then
    EXTRA_GIT_BUILDPACKAGE_ARGS="--git-ignore-new"
else
    EXTRA_GIT_BUILDPACKAGE_ARGS=""
fi

sudo apt-get install git-buildpackage

# Get latest alpine packaging
git clone "$GIT_URL" alpine

# Make sure it builds outside a pbuilder
cd alpine
sudo apt-get build-dep alpine  # I realize this is the previous version
git-buildpackage $EXTRA_GIT_BUILDPACKAGE_ARGS  # intentionally not quoted

if [[ "$SKIP_PBUILDER" == "true" ]] ; then
    exit 0  # skip pbuilder for now
fi

# Create a pbuilder chroot
sudo apt-get install ubuntu-dev-tools
pbuilder-dist sid create
pbuilder-dist sid build ../*.dsc

