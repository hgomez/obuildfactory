#!/bin/sh
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8/linux)
# OBF_PROJECT_NAME (ie: openjdk8)
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
 OBF_JDK_MODEL=$OBF_BASE_ARCH
fi


if [ -f $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 ]; then
  echo "packaging JDK"
  cp $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 SOURCES/j2sdk-image.tar.bz2

  rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $OBF_BUILD_NUMBER" --define="jdk_model $OBF_JDK_MODEL" --define="cum_jdk 0" SPECS/jdk.spec

  if [ $? != 0 ]; then
    exit -1
  fi

else
  echo "missing JDK image tarball $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2, skipping packaging"
fi

if [ -f $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 ]; then
  echo "packaging JRE"
  cp $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 SOURCES/j2re-image.tar.bz2

  rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $OBF_BUILD_NUMBER" --define="jdk_model $OBF_JDK_MODEL" --define="cum_jdk 0" SPECS/jre.spec

  if [ $? != 0 ]; then
    exit -1
  fi

else
  echo "missing JRE image tarball $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2, skipping packaging"
fi

cp -rf RPMS $OBF_DROP_DIR/$OBF_PROJECT_NAME
