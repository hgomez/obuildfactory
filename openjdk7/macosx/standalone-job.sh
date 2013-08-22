#!/bin/bash
#

set -e
export OBF_PROJECT_NAME=openjdk7

#
# Prepare Drop DIR
#
if [ -z $OBF_DROP_DIR ]; then
  export OBF_DROP_DIR=`pwd`/OBF_DROP_DIR
fi

#
# Provide Main Variables to Scripts
#
if [ -z "$OBF_BUILD_PATH" ]; then
  export OBF_BUILD_PATH=`pwd`/obuildfactory/$OBF_PROJECT_NAME/macosx
fi

if [ -z "$OBF_SOURCES_PATH" ]; then
  export OBF_SOURCES_PATH=`pwd`/sources/$OBF_PROJECT_NAME
  mkdir -p `pwd`/sources
fi

if [ ! -d $OBF_SOURCES_PATH ]; then
  hg clone http://hg.openjdk.java.net/jdk7u/jdk7u $OBF_SOURCES_PATH
else
  pushd $OBF_SOURCES_PATH >>/dev/null
  hg update
  if [ -d .pc ]; then
    quilt pop -a
    rm -r .pc
  fi
  popd >>/dev/null
fi

pushd $OBF_SOURCES_PATH >>/dev/null

#
# Updating sources for Mercurial repo
#
sh ./get_source.sh

#
# Update sources to provided tag XUSE_TAG (if defined)
#
if [ ! -z "$XUSE_TAG" ]; then
  echo "using tag $XUSE_TAG"
  sh ./make/scripts/hgforest.sh update $XUSE_TAG
fi

popd >>/dev/null

if [ "$(uname -s)" = 'Darwin' -o "$(uname -o)" = 'Darwin' ]; then
  #
  # Correct the PATH, so that split is /usr/bin/split
  # (on Mac OS X, it should be the BSD version which accepts the -p argument).
  #
  if [ "$(which split 2>/dev/null)" != '/usr/bin/split' ]; then
    PATH="/usr/bin:${PATH}"
  fi

  #
  # On Mac OS X 10.6, compiler warnings are inevitable.
  # Make sure they're non-fatal.
  #
  if [ "$(sw_vers | grep 'ProductVersion' | awk '{print $2}' | sed 's/\.[0-9]$//g')" = "10.6" ]; then
    export COMPILER_WARNINGS_FATAL='false'
  fi
fi

#
# Mercurial repositories updated, call Jenkins job now
#
$OBF_BUILD_PATH/jenkins-job.sh
