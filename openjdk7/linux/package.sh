#!/bin/bash
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8/linux)
# OBF_PROJECT_NAME (ie: openjdk7)
# OBF_BUILD_NUMBER (ie: u12-b01)
#
# Optional vars :
#
# OBF_JDK_MODEL (ie: x86_64 to override default calculated)

PACKAGE_NAME="jdk-1.7.0-openjdk"
PACKAGE_DESCRIPTION="OpenJDK 7 native package"

pushd $OBF_BUILD_PATH/rpm >>/dev/null

if [ "$XDEBUG" = "true" ]; then

    FILENAME_PREFIX="-fastdebug"
    DESCRIPTION_ADDON=" (with FastDebug support inside)"

fi

if [ "$XUSE_FPM" = "true" ]; then

    if [ -z "$XPACKAGE_MODE" ]; then
        if [ -x /usr/bin/apt-get ]; then
            XPACKAGE_MODE=deb
        else
            XPACKAGE_MODE=rpm
        fi
    fi

    if [ "$XDEBUG" = "true" ]; then
        FILENAME_PREFIX="-fastdebug"
    fi

    CPU_BUILD_ARCH=`uname -m`

    if [ -z "$OBF_JDK_MODEL" ]; then
     OBF_JDK_MODEL=$CPU_BUILD_ARCH
    fi

    mkdir -p tmp/$OBF_PROJECT_NAME
    pushd tmp/$OBF_PROJECT_NAME
    tar xvjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2
    XDEST_DIR=opt/obuildfactory/$PACKAGE_NAME-$OBF_JDK_MODEL$FILENAME_PREFIX
    rm -rf $XDEST_DIR
    mkdir -p $XDEST_DIR
    mv j2sdk-image/* $XDEST_DIR

    rm -rf *.$XPACKAGE_MODE

    fpm --verbose -s dir -t $XPACKAGE_MODE -n $OBF_PROJECT_NAME$FILENAME_PREFIX -v "1.7.0-$OBF_BUILD_NUMBER" --category language -m "Henri Gomez <henri.gomez@gmail.com>" \
    --url https://github.com/hgomez/obuildfactory/ \
    --license "GPL-2.0" \
    --description "$PACKAGE_DESCRIPTION$DESCRIPTION_ADDON" \
    -C . opt

    mv *.$XPACKAGE_MODE $OBF_DROP_DIR/$OBF_PROJECT_NAME

    popd

else

    [ "$XPACKAGE_MODE" = "generic" ] && PKG_DIR="GENERIC" || PKG_DIR="RPMS"

    rm -rf TEMP
    mkdir -p TEMP
    rm -rf BUILD
    mkdir -p BUILD
    rm -rf $PKG_DIR
    mkdir -p $PKG_DIR
    mkdir -p SOURCES

    CPU_BUILD_ARCH=`uname -m`

    if [ -z "$OBF_JDK_MODEL" ]; then
     OBF_JDK_MODEL=$CPU_BUILD_ARCH
    fi

    if [ "$XDEBUG" = "true" ]; then
        FILENAME_PREFIX="-fastdebug"
    fi

    if [ -f $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 ]; then
      echo "packaging JDK"
      cp $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 SOURCES/j2sdk-image.tar.bz2

      if [ "$XPACKAGE_MODE" = "generic" ]; then
        tar -xjf SOURCES/j2sdk-image.tar.bz2 -C TEMP

        find TEMP/j2sdk-image -name '*.diz' | xargs rm
        (cd TEMP/j2sdk-image && rm -rf demo sample man src.zip)

        REVISION=$(echo $OBF_BUILD_NUMBER | sed 's/^u\(.*\)-b.*$/\1/')
        JDK_DIR="jdk1.7.0_$REVISION"
        mv TEMP/j2sdk-image TEMP/$JDK_DIR
        tar -cJf GENERIC/$PACKAGE_NAME-$OBF_BASE_ARCH-1.7.0_$OBF_BUILD_NUMBER.tar.xz -C TEMP $JDK_DIR
      else
        rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $OBF_BUILD_NUMBER" \
                   --define="jdk_type $FILENAME_PREFIX" --define="jdk_model $OBF_JDK_MODEL" --define="cum_jdk 0" \
                   SPECS/jdk.spec
      fi

      if [ $? != 0 ]; then
        exit -1
      fi

    else
      echo "missing JDK image tarball $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2, skipping packaging"
    fi

    if [ -f $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 ]; then
      echo "packaging JRE"
      cp $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 SOURCES/j2re-image.tar.bz2

      if [ "$XPACKAGE_MODE" = "generic" ]; then
        echo "No generic JRE packaging yet."
      else
        rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="jvm_version $OBF_BUILD_NUMBER" \
                     --define="jdk_type $FILENAME_PREFIX" --define="jdk_model $OBF_JDK_MODEL" --define="cum_jdk 0" \
                     SPECS/jre.spec
      fi

      if [ $? != 0 ]; then
        exit -1
      fi

    else
      echo "missing JRE image tarball $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2, skipping packaging"
    fi

    if [ "$XPACKAGE_MODE" = "generic" ]; then
      mv GENERIC/*.tar.xz $OBF_DROP_DIR/$OBF_PROJECT_NAME
    else
      mv RPMS/*/*.rpm $OBF_DROP_DIR/$OBF_PROJECT_NAME
    fi

fi
