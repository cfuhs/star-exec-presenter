#!/bin/bash

ARCH=x86_64-linux

# if you change this, be sure to change stack.yaml and config/keter.yml as well
# RESOLVER=lts-8.22
# GHC=8.0.2
RESOLVER=lts-13.9
GHC=8.6.3

APP=.stack-work/install/$ARCH/$RESOLVER/$GHC/bin/star-exec-presenter
KET=star-exec-presenter.keter

strip $APP
rm -fv $KET
tar -c --dereference --hard-dereference -z -v -f $KET $APP static config TPDB-*_XML.zip johannes_waldmann_tpdb-8.0.7_XML.zip  mario_wenzel_XML.zip 
# scp $KET termcomp.imn.htwk-leipzig.de:/opt/keter/incoming
cp -v $KET /opt/keter/incoming
