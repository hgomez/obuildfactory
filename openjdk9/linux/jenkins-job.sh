#!/bin/bash
#

export OBF_PROJECT_NAME=openjdk9
TAG_FILTER=jdk9

#
# Safe Environment
#
export LC_ALL=C
export LANG=C

#
# Prepare Drop DIR
#

if [ -z "$OBF_DROP_DIR" ]; then
  export OBF_DROP_DIR="$HOME/OBF_DROP_DIR"
fi

if [ "$XCLEAN" = "true" ]; then
  rm -rf $OBF_DROP_DIR
fi

mkdir -p $OBF_DROP_DIR

#
# Provide Main Variables to Scripts
#
if [ -z "$OBF_BUILD_PATH" ]; then
  export OBF_BUILD_PATH=`pwd`/obuildfactory/$OBF_PROJECT_NAME/linux
fi

if [ -z "$OBF_SOURCES_PATH" ]; then
  export OBF_SOURCES_PATH=`pwd`/sources
fi

if [ -z "$OBF_WORKSPACE_PATH" ]; then
  export OBF_WORKSPACE_PATH=`pwd`
fi

pushd $OBF_SOURCES_PATH >>/dev/null

#
# OBF_MILESTONE will contains build tag number and name, ie b56 but without dash inside (suited for RPM packages)
# OBF_BUILD_NUMBER will contains build number, ie b56
# OBF_BUILD_DATE will contains build date, ie 20120908
#
# Build System concats OBF_MILESTONE, - and OBF_BUILD_DATE, ie b56-20120908
#
export OBF_MILESTONE=`hg identify | cut -d ' ' -f 2 | cut -d '/' -f 1`

if [ "$OBF_MILESTONE" = "tip" ]; then
  OBF_MILESTONE=`hg tags | grep $TAG_FILTER | head -1 | cut -d ' ' -f 1`
fi

export OBF_BUILD_NUMBER=`echo $OBF_MILESTONE | sed "s/$TAG_FILTER//" | sed 's/^-//'`
export OBF_BUILD_DATE=`date +%Y%m%d`
export OBF_BASE_ARCH=`uname -m`

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
