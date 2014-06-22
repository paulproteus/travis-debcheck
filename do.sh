#!/bin/bash
set -e  # Fail on errors
set -x  # Verbosity all the way

GIT_IGNORE_NEW="true"  # hack for now
USE_ALIOTH="false"
SKIP_PBUILDER="false"
BUILD_JUST_SOURCE_IN_TRAVIS="true"
DPKG_SOURCE_COMMIT="true"  # hack for now
DO_NOT_SIGN=true

export DEBEMAIL=asheesh@asheesh.org
export DEBFULLNAME="Asheesh Laroia"
export CCACHEDIR=$HOME/ccache
mkdir -p "$CCACHEDIR"

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

if [[ "$DPKG_SOURCE_COMMIT" == "true" ]] ; then
    EXTRA_GIT_BUILDPACKAGE_ARGS="$EXTRA_GIT_BUILDPACKAGE_ARGS --source-option=--auto-commit"
else
    EXTRA_GIT_BUILDPACKAGE_ARGS="$EXTRA_GIT_BUILDPACKAGE_ARG"
fi

if [[ "$BUILD_JUST_SOURCE_IN_TRAVIS" == "true" ]] ; then
    EXTRA_GIT_BUILDPACKAGE_ARGS="$EXTRA_GIT_BUILDPACKAGE_ARGS -S"
else
    EXTRA_GIT_BUILDPACKAGE_ARGS="$EXTRA_GIT_BUILDPACKAGE_ARG"
fi

if [[ "$DO_NOT_SIGN" == "true" ]] ; then
    EXTRA_GIT_BUILDPACKAGE_ARGS="$EXTRA_GIT_BUILDPACKAGE_ARGS -us -uc"
else
    EXTRA_GIT_BUILDPACKAGE_ARGS="$EXTRA_GIT_BUILDPACKAGE_ARG"
fi


sudo apt-get install git-buildpackage

# Get latest alpine packaging
git clone "$GIT_URL" alpine
cd alpine
git checkout origin/pristine-tar -b pristine-tar
git checkout origin/upstream -b upstream
git checkout master

# Tell git on Travis who we are
git config --global user.email travis-ci@asheesh.org
git config --global user.name "Asheesh Laroia (on travis-ci.org)"

# Make sure it builds outside a pbuilder
sudo apt-get build-dep alpine  # I realize this is the previous version
git dch -N "2.11+dfsg-1"
git dch -a
git add debian/changelog
git commit -m 'Adding dch -a changelog'
git-buildpackage $EXTRA_GIT_BUILDPACKAGE_ARGS  # intentionally not quoted

if [[ "$SKIP_PBUILDER" == "true" ]] ; then
    exit 0  # skip pbuilder for now
fi

# Create a pbuilder chroot
sudo apt-get install ubuntu-dev-tools
wget https://ftp-master.debian.org/keys/archive-key-7.0.asc
gpg --import $PWD/archive-key-7.0.asc
pbuilder-dist sid create --debootstrapopts --keyring=$HOME/.gnupg/pubring.gpg --mirror http://cdn.debian.net/debian/
pbuilder-dist sid build ../*.dsc

