#!/bin/bash
#

export OBF_PROJECT_NAME=openjdk8-lambda

#
# Safe Environment
#
export LC_ALL=C
export LANG=C

#
# Prepare Drop DIR
#
export DROP_DIR="$HOME/DROP_DIR"
mkdir -p $DROP_DIR

#
# Provide Main Variables to Scripts
#
if [ -z "$OBF_BUILD_PATH" ]; then
  export OBF_BUILD_PATH=`pwd`/obuildfactory/$OBF_PROJECT_NAME/linux
fi

if [ -z "$OBF_SOURCES_PATH" ]; then
  export OBF_SOURCES_PATH=`pwd`/sources
fi

pushd $OBF_SOURCES_PATH >>/dev/null

export OBF_HG_TAGS=`hg tags | grep lambda | head -1 | sed "s/lambda//" | cut -d ' ' -f 1 | sed 's/^-//'`
export OBF_MILESTONE=`echo $HG_TAGS | sed "s/-/./g"`

popd >>/dev/null

if [ "$XBUILD" = "true" ]; then
  $OBF_BUILD_PATH/build.sh

  if [ $? != 0 ]; then
    exit -1
  fi

fi

if [ "$XTEST" = "true" ]; then
  $OBF_BUILD_PATH/test.sh

  if [ $? != 0 ]; then
    exit -1
  fi

fi

if [ "$XPACKAGE"  = "true" ]; then
  $OBF_BUILD_PATH/package.sh

  if [ $? != 0 ]; then
    exit -1
  fi

fi

if [ "$XDEPLOY"  = "true" ]; then
  $OBF_BUILD_PATH/deploy.sh

  if [ $? != 0 ]; then
    exit -1
  fi

fi
