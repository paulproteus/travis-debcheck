#!/bin/sh
sudo apt-get install git-buildpackage

git clone https://alioth.debian.org/anonscm/git/collab-maint/alpine.git

cd alpine
gbp buildpackage

