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
  export OBF_DROP_DIR=`pwd`/OBF_DROP_DIR
fi

#
# Provide Main Variables to Scripts
#
if [ -z "$OBF_BUILD_PATH" ]; then
  export OBF_BUILD_PATH=`pwd`/obuildfactory/$OBF_PROJECT_NAME/linux
fi

if [ -z "$OBF_SOURCES_PATH" ]; then
  export OBF_SOURCES_PATH=`pwd`/sources/$OBF_PROJECT_NAME
  mkdir -p `pwd`/sources
fi

if [ -z "$OBF_WORKSPACE_PATH" ]; then
  export OBF_WORKSPACE_PATH=`pwd`
fi

if [ ! -d $OBF_SOURCES_PATH ]; then
  hg clone http://hg.openjdk.java.net/jdk9/jdk9 $OBF_SOURCES_PATH
fi

pushd $OBF_SOURCES_PATH >>/dev/null

#
# Updating sources for Mercurial repo
#
sh ./get_source.sh

if [ -n "$XUSE_UPDATE" ]; then
  XUSE_TAG=`hg tags | grep "jdk8u$XUSE_UPDATE" | head -1 | cut -d ' ' -f 1`
fi

#
# Update sources to provided tag XUSE_TAG (if defined)
#
if [ ! -z "$XUSE_TAG" ]; then
  echo "using tag $XUSE_TAG"
  sh ./make/scripts/hgforest.sh update --clean $XUSE_TAG
fi

popd >>/dev/null

#
# Mercurial repositories updated, call Jenkins job now
#
$OBF_BUILD_PATH/jenkins-job.sh
