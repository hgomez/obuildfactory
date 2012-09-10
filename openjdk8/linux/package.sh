#!/bin/sh
#

# Required vars :
#
# JVM_VERSION (ie b50)

PROJECT_NAME=openjdk8

export LC_ALL=C
export LANG=C

export DROP_DIR="$HOME/DROP_DIR"
mkdir -p $DROP_DIR

pushd rpm

rm -rf TEMP
mkdir -p TEMP
rm -rf BUILD
mkdir -p BUILD
rm -rf RPMS
mkdir -p RPMS

CPU_BUILD_ARCH=`uname -p`

if [ -z "$JDK_MODEL" ]; then
 JDK_MODEL=$CPU_BUILD_ARCH
fi

if [ -f $DROP_DIR/$PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2 ]; then
  echo "packaging JDK"
  cp $DROP_DIR/$PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2 SOURCES/j2sdk-image.tar.bz2

  rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $JVM_VERSION" --define="jdk_model $JDK_MODEL" --define="cum_jdk 0" SPECS/jdk.spec

  if [ $? != 0 ]; then
    exit -1
  fi

#  rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $JVM_VERSION" --define="jdk_model $JDK_MODEL" --define="cum_jdk 1" SPECS/jdk.spec
#
#  if [ $? != 0 ]; then
#    exit -1
#  fi

else
  echo "missing JDK image tarball $DROP_DIR/$PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2, skipping packaging"
fi

if [ -f $DROP_DIR/$PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2 ]; then
  echo "packaging JRE"
  cp $DROP_DIR/$PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2 SOURCES/j2re-image.tar.bz2

  rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $JVM_VERSION" --define="jdk_model $JDK_MODEL" --define="cum_jdk 0" SPECS/jre.spec

  if [ $? != 0 ]; then
    exit -1
  fi

#  rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $JVM_VERSION" --define="jdk_model $JDK_MODEL" --define="cum_jdk 1" SPECS/jre.spec
#
#  if [ $? != 0 ]; then
#    exit -1
#  fi

else
  echo "missing JRE image tarball $DROP_DIR/$PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2, skipping packaging"
fi

cp -rf RPMS $DROP_DIR/$PROJECT_NAME

popd
