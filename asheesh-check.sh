#!/bin/bash
set -e  # Fail on errors
set -x  # Verbosity all the way

source .generated-config

# Turn config into other things
if [[ "$GIT_IGNORE_NEW" == "true" ]] ; then
    BUILDPACKAGE_ARGS="--git-ignore-new"
else
    BUILDPACKAGE_ARGS=""
fi

if [[ "$DPKG_SOURCE_COMMIT" == "true" ]] ; then
    BUILDPACKAGE_ARGS="$BUILDPACKAGE_ARGS --source-option=--auto-commit"
else
    BUILDPACKAGE_ARGS="$BUILDPACKAGE_ARGS"
fi

if [[ "$BUILD_JUST_SOURCE_IN_TRAVIS" == "true" ]] ; then
    BUILDPACKAGE_ARGS="$BUILDPACKAGE_ARGS -S"
else
    BUILDPACKAGE_ARGS="$BUILDPACKAGE_ARGS"
fi

if [[ "$DO_NOT_SIGN" == "true" ]] ; then
    BUILDPACKAGE_ARGS="$BUILDPACKAGE_ARGS -us -uc"
else
    BUILDPACKAGE_ARGS="$BUILDPACKAGE_ARGS"
fi

# Upgrade pbuilder
sudo apt-get install pbuilder
wget http://mirrors.kernel.org/ubuntu/pool/main/p/pbuilder/pbuilder_0.215ubuntu7_all.deb
sudo dpkg -i pbuilder*deb

# Always pretend to be Asheesh
export DEBEMAIL=asheesh@asheesh.org
export DEBFULLNAME="Asheesh Laroia"

# Always disable pbuilder ccache (this is a temporary VM, and
# moreover, permissions lulz occur if we use ccache on travis-ci
# for some reason)
echo "CCACHEDIR=" | sudo tee -a /etc/pbuilderrc

# Always install git-buildpackage, because we need it for some
# packages.
sudo apt-get install git-buildpackage

# Tell git on Travis who we are
git config --global user.email travis-ci@asheesh.org
git config --global user.name "Asheesh Laroia (on travis-ci.org)"

# Make sure it builds outside a pbuilder
sudo apt-get build-dep   # I realize this is the previous version
git dch -a -N "2.11+dfsg1-1"
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
pbuilder-dist sid create --debootstrapopts --keyring=$HOME/.gnupg/pubring.gpg --mirror http://cdn.debian.net/debian/ || pbuilder-dist sid create --debootstrapopts --keyring=$HOME/.gnupg/pubring.gpg --mirror http://mirror.mit.edu/debian/


# Before building, add a hook to run lintian
mkdir ~/pbuilderhooks
cp /usr/share/doc/pbuilder/examples/B90lintian $HOME/pbuilderhooks
echo "HOOKDIR=$HOME/pbuilderhooks/" >> ~/.pbuilderrc
# FIXME: also run piuparts or something else???

pbuilder-dist sid build ../*.dsc

# Make sure get-orig-source works
debian/rules get-orig-source

