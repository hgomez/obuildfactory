#!/bin/sh
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8-lambda/linux)
# OBF_PROJECT_NAME (ie: openjdk8-lambda)
# OBF_BUILD_NUMBER (ie: b50)
#
# Optional vars :
#
# OBF_JDK_MODEL (ie: x86_64 to override default calculated)

pushd $OBF_BUILD_PATH/rpm >>/dev/null

rm -rf TEMP
mkdir -p TEMP
rm -rf BUILD
mkdir -p BUILD
rm -rf RPMS
mkdir -p RPMS
mkdir -p SOURCES

CPU_BUILD_ARCH=`uname -p`

if [ -z "$OBF_JDK_MODEL" ]; then
 OBF_JDK_MODEL=$CPU_BUILD_ARCH
fi

if [ -f $DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2 ]; then
  echo "packaging JDK"
  cp $DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2 SOURCES/j2sdk-image.tar.bz2

  rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $OBF_BUILD_NUMBER" --define="jdk_model $OBF_JDK_MODEL" --define="cum_jdk 0" SPECS/jdk.spec

  if [ $? != 0 ]; then
    exit -1
  fi

else
  echo "missing JDK image tarball $DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2, skipping packaging"
fi

if [ -f $DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2 ]; then
  echo "packaging JRE"
  cp $DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2 SOURCES/j2re-image.tar.bz2

  rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $OBF_BUILD_NUMBER" --define="jdk_model $OBF_JDK_MODEL" --define="cum_jdk 0" SPECS/jre.spec

  if [ $? != 0 ]; then
    exit -1
  fi

else
  echo "missing JRE image tarball $DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2, skipping packaging"
fi

cp -rf RPMS $DROP_DIR/$OBF_PROJECT_NAME
