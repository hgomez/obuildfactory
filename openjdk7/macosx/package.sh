#!/bin/sh
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8/linux)
# OBF_PROJECT_NAME (ie: openjdk7)
# OBF_BUILD_NUMBER (ie: b50)
# OBF_BASE_ARCH (provided by build.sh)
#
# Optional vars :
#
# OBF_JDK_MODEL (ie: x86_64 to override default calculated)

set -e

if [ "$XDEBUG" = "true" ]; then
  FILENAME_PREFIX="-fastdebug"
fi

JDK_ORG_BUNDLE_DIRNAME=jdk1.7.0.jdk
JRE_ORG_BUNDLE_DIRNAME=jre1.7.0.jre

JDK_DST_BUNDLE_DIRNAME=1.7.0u$FILENAME_PREFIX.jdk
JRE_DST_BUNDLE_DIRNAME=1.7.0u$FILENAME_PREFIX.jre

JDK_BUNDLE=$OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-bundle$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2
JRE_BUNDLE=$OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-bundle$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2

# 1.7.0 to be injected in Info.plist
JVM_VERSION=1.7.0

# jdk dirname in template.dmg
DMG_BUNDLE_DIR=1.7.0.jdk

#
# jdk/jre
# $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH/j2sdk-bundle-$OBF_BASE_ARCH.tar.bz2
# $JDK_ORG_BUNDLE_DIRNAME
# $JDK_DST_BUNDLE_DIRNAME
# OpenJDK-OSX-1.7
#
function build_dmg()
{
  PACKAGE_NAME=$1
  BUNDLE_FILE=$2
  SRC_BUNDLE=$3
  DST_BUNDLE=$4
  FILE_NAME=$5

  pushd $OBF_BUILD_PATH/dmg >>/dev/null

  rm -rf TEMP
  mkdir -p TEMP

  if [ -f $BUNDLE_FILE ]; then
    echo "packaging $PACKAGE_NAME"

    pushd TEMP >>/dev/null

    tar xjf $BUNDLE_FILE

    # Set Milestone and buildnumber in Info.plist
    sed -i "" -e "s|<string>$JVM_VERSION</string>|<string>$JVM_VERSION-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE</string>|" $SRC_BUNDLE/Contents/Info.plist

    cp ../template.dmg.bz2 .
    bzip2 -d template.dmg.bz2

    DMG_MOUNT_DIR=`pwd`/MOUNT_DIR
    mkdir -p $DMG_MOUNT_DIR

    hdiutil attach template.dmg -readwrite -noverify -noautoopen -noautoopenro -noautoopenrw -noautofsck -noidme -noidmereveal -noidmetrash -mountpoint $DMG_MOUNT_DIR

    rm -f $DMG_MOUNT_DIR/$DMG_BUNDLE_DIR
    mv $SRC_BUNDLE $DMG_MOUNT_DIR/$DST_BUNDLE
    cp -f ../README $DMG_MOUNT_DIR/README
    cp -f ../LEGAL $DMG_MOUNT_DIR/LEGAL

    ../SetFileIcon -image ../logo.png -file $DMG_MOUNT_DIR/$DST_BUNDLE

    hdiutil detach $DMG_MOUNT_DIR -quiet -force
    hdiutil convert template.dmg -format UDZO -imagekey zlib-level=9 -o $FILE_NAME-$OBF_BASE_ARCH-$PACKAGE_NAME-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.dmg
    rm template.dmg

    mkdir -p $OBF_DROP_DIR/$OBF_PROJECT_NAME
    mv $FILE_NAME-$OBF_BASE_ARCH-$PACKAGE_NAME-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.dmg $OBF_DROP_DIR/$OBF_PROJECT_NAME

    popd >>/dev/null
    rm -rf TEMP
  else
    echo "missing $PACKAGE_NAME bundle tarball $BUNDLE_FILE, skipping packaging"
  fi
}

# jdk/jre
# $JDK_BUNDLE
# $JDK_ORG_BUNDLE_DIRNAME
# $JDK_DST_BUNDLE_DIRNAME
# OpenJDK-OSX-1.7 (or OpenJDK-OSX-1.7-fastdebug)

build_dmg jdk $JDK_BUNDLE $JDK_ORG_BUNDLE_DIRNAME $JDK_DST_BUNDLE_DIRNAME OpenJDK-OSX-1.7$FILENAME_PREFIX
build_dmg jre $JRE_BUNDLE $JRE_ORG_BUNDLE_DIRNAME $JRE_DST_BUNDLE_DIRNAME OpenJDK-OSX-1.7$FILENAME_PREFIX
