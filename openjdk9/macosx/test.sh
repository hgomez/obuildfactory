#!/bin/bash
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project build scripts, ie obuildfactory/openjdk9/linux)
# OBF_SOURCES_PATH (absolute path of project sources)
#

#
# Install JTReg (http://openjdk.java.net/jtreg)
#
function ensure_jtreg()
{
  if [ ! -f $OBF_DROP_DIR/jtreg/win32/bin/jtreg ]; then

    JTREG_VERSION=b05

    if [ ! -f $OBF_DROP_DIR/jtreg-$JTREG_VERSION.zip ]; then
      curl -L http://www.java.net/download/openjdk/jtreg/promoted/4.1/b05/jtreg-4.1-bin-b05_29_nov_2012.zip -o $OBF_DROP_DIR/jtreg-$JTREG_VERSION.zip
    fi

    rm -rf $OBF_DROP_DIR/jtreg

    mkdir $OBF_DROP_DIR/jtreg

    pushd $OBF_DROP_DIR >>/dev/null

    unzip jtreg-$JTREG_VERSION.zip

    popd >>/dev/null

  fi
}

ensure_jtreg

if [ "$XDEBUG" = "true" ]; then

  case $OBF_BASE_ARCH in
    x86_64)
      BUILD_PROFILE=macosx-x86_64-normal-server-fastdebug
      ;;
    i386)
      BUILD_PROFILE=macosx-x86-normal-server-fastdebug
      ;;
    universal)
      BUILD_PROFILE=macosx-universal-normal-server-fastdebug
      ;;
  esac

else

  case $OBF_BASE_ARCH in
    x86_64)
      BUILD_PROFILE=macosx-x86_64-normal-server-release
      ;;
    i386)
      BUILD_PROFILE=macosx-x86-normal-server-release
      ;;
    universal)
      BUILD_PROFILE=macosx-universal-normal-server-release
      ;;
  esac

fi

export PRODUCT_HOME=$OBF_SOURCES_PATH/build/$BUILD_PROFILE/images/j2sdk-image
export JT_HOME=$OBF_DROP_DIR/jtreg

pushd $OBF_SOURCES_PATH/test >>/dev/null
if [ "$XCLEAN" = "true" ]; then
  CONF=$BUILD_PROFILE ALT_OUTPUTDIR=$OBF_SOURCES_PATH/build/$BUILD_PROFILE make clean
fi
CONF=$BUILD_PROFILE ALT_OUTPUTDIR=$OBF_SOURCES_PATH/build/$BUILD_PROFILE make
popd >> /dev/null
