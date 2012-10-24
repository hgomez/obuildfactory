#!/bin/sh
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8/linux)
# OBF_PROJECT_NAME (ie: openjdk8)
# OBF_BUILD_NUMBER (ie: b50)
# CPU_BUILD_ARCH (provided by build.sh or computed from machine/XUSE_UNIVERSAL)
#
# Optional vars :
#
# OBF_JDK_MODEL (ie: x86_64 to override default calculated)

if [ -z "$CPU_BUILD_ARCH" ]; then
  if [ "$XUSE_UNIVERSAL" = "true" ]; then
    export CPU_BUILD_ARCH=universal
  else
    export CPU_BUILD_ARCH=`uname -m`
  fi
fi

pushd $OBF_BUILD_PATH/dmg >>/dev/null

rm -rf TEMP
mkdir -p TEMP

if [ -f $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2 ]; then
  echo "packaging JDK"
  cp $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2 SOURCES/j2sdk-image.tar.bz2

  pushd TEMP >>/dev/null

  mkdir -p $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH
  mv *.dmg $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH
  
  popd >>/dev/null

  if [ $? != 0 ]; then
    exit -1
  fi

  
else
  echo "missing JDK image tarball $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2, skipping packaging"
fi

if [ -f $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2 ]; then
  echo "packaging JRE"
  cp $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2 SOURCES/j2re-image.tar.bz2

  pushd TEMP >>/dev/null

  mkdir -p $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH
  mv *.dmg $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH

  popd >>/dev/null

  if [ $? != 0 ]; then
    exit -1
  fi

else
  echo "missing JRE image tarball $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2, skipping packaging"
fi
