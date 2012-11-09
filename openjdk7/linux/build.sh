#!/bin/bash
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8/linux)
# OBF_SOURCES_PATH (absolute path of project sources)
# OBF_PROJECT_NAME (ie: openjdk7)
# OBF_MILESTONE (ie: u8-b10)

function cacerts_gen()
{
  local DESTCERTS=$1
  local TMPCERTSDIR=`mktemp -d`
  
  pushd $TMPCERTSDIR
  curl -L http://curl.haxx.se/ca/cacert.pem -o cacert.pem
  cat cacert.pem | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{ print $0; }' > cacert-clean.pem
  rm -f cacerts cert_*
# split  -p "-----BEGIN CERTIFICATE-----" cacert-clean.pem cert_
  csplit -k -f cert_ cacert-clean.pem "/-----BEGIN CERTIFICATE-----/" {*}

  for CERT_FILE in cert_*; do
    ALIAS=$(basename ${CERT_FILE})
    echo yes | keytool -import -alias ${ALIAS} -keystore cacerts -storepass 'changeit' -file ${CERT_FILE} || :
    rm -f $CERT_FILE
  done

  rm -f cacert.pem cacert-clean.pem
  mv cacerts $DESTCERTS

  popd
  rm -rf $TMPCERTSDIR
}

function ensure_ant()
{
  if [ ! -d $OBF_DROP_DIR/ant ]; then
    mkdir -p $OBF_DROP_DIR/ant
    pushd $OBF_DROP_DIR/ant
    curl -L http://mirrors.ircam.fr/pub/apache/ant/binaries/apache-ant-1.8.4-bin.tar.gz -o apache-ant-1.8.4-bin.tar.gz
    tar xzf apache-ant-1.8.4-bin.tar.gz
    mv apache-ant-1.8.4/* .
    rmdir apache-ant-1.8.4
    rm -f apache-ant-1.8.4-bin.tar.gz
    popd
  fi

  export PATH=$OBF_DROP_DIR/ant/bin:$PATH
}

function ensure_cacert()
{
  if [ ! -f $OBF_DROP_DIR/cacerts ]; then
    echo "no cacerts found, regenerate it..."
    cacerts_gen $OBF_DROP_DIR/cacerts
  else
    if test `find "$OBF_DROP_DIR/cacerts" -mtime +7`
    then
      echo "cacerts older than one week, regenerate it..."
      cacerts_gen $OBF_DROP_DIR/cacerts
    fi
  fi
}

function check_version()
{
    local version=$1 check=$2
    local winner=$(echo -e "$version\n$check" | sed '/^$/d' | sort -nr | head -1)
    [[ "$winner" = "$version" ]] && return 0
    return 1
}

function ensure_freetype()
{
  FT_VER=`freetype-config --ftversion`
  check_version "2.3" $FT_VER

  if [ $? == 0 ]; then

    if [ ! -d $OBF_DROP_DIR/freetype ]; then
      pushd $OBF_DROP_DIR
      curl -L http://freefr.dl.sourceforge.net/project/freetype/freetype2/2.4.10/freetype-2.4.10.tar.bz2 -o freetype-2.4.10.tar.bz2
      tar xjf freetype-2.4.10.tar.bz2
      cd freetype-2.4.10
      mkdir -p $OBF_DROP_DIR/freetype
      ./configure --prefix=$OBF_DROP_DIR/freetype
      make 
      make install
      popd
    fi

    export ALT_FREETYPE_LIB_PATH=$OBF_DROP_DIR/freetype/lib
    export ALT_FREETYPE_HEADERS_PATH=$OBF_DROP_DIR/freetype/include

  fi
}

#
# Build using old build system
# 
function build_old()
{
  echo "### using old build system ###"
  
  NUM_CPUS=`grep "processor" /proc/cpuinfo | sort -u | wc -l`

  export MILESTONE="$OBF_BUILD_NUMBER"
  export BUILD_NUMBER="$OBF_BUILD_DATE"
  export LD_LIBRARY_PATH=
  export ALT_BOOTDIR=$JAVA_HOME
  export ALLOW_DOWNLOADS=true
  export ALT_CACERTS_FILE=$OBF_DROP_DIR/cacerts
  export ALT_BOOTDIR=$ALT_BOOTDIR
  export ALT_DROPS_DIR=$OBF_DROP_DIR
  export HOTSPOT_BUILD_JOBS=$NUM_CPUS
  export PARALLEL_COMPILE_JOBS=$NUM_CPUS
  export ANT_HOME=$ANT_HOME
  export JAVA_HOME=
  
  if [ "$CPU_BUILD_ARCH" = "x86_64" ]; then
    export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/linux-amd64
  else
    export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/linux-i586
  fi

  # Set Company Name to OBuildFactory
  sed -i "s|COMPANY_NAME = N/A|COMPANY_NAME = $BUNDLE_VENDOR|g" $OBF_SOURCES_PATH/jdk/make/common/shared/Defs.gmk
  
  pushd $OBF_SOURCES_PATH >>/dev/null
  make sanity
  make all
  popd >>/dev/null
}

#
# Build using new build system
# 
function build_new()
{
 echo "not yet"
 exit -1
}

#
# Verify build 
#
function test_build()
{
  if [ -x $IMAGE_BUILD_DIR/j2sdk-image/bin/java ]; then
    $IMAGE_BUILD_DIR/j2sdk-image/bin/java -version
  else
    echo "can't find java into JDK $IMAGE_BUILD_DIR/j2sdk-image, build failed" 
    exit -1
   fi

   if [ -x $IMAGE_BUILD_DIR/j2re-image/bin/java ]; then
     $IMAGE_BUILD_DIR/j2re-image/bin/java -version
   else
     echo "can't find java into JRE $IMAGE_BUILD_DIR/j2re-image, build failed" 
     exit -1
    fi
}

#
# Archives build 
#
function archive_build()
{
    pushd $IMAGE_BUILD_DIR
    mkdir -p $OBF_DROP_DIR/$OBF_PROJECT_NAME
    tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2 j2sdk-image
    tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2 j2re-image
  
    echo "produced tarball files under $OBF_DROP_DIR/$OBF_PROJECT_NAME"
    ls -l $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2
    ls -l $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image-$CPU_BUILD_ARCH.tar.bz2
  
    popd
}

#
# Build start here
#

CPU_BUILD_ARCH=`uname -p`

export JDK_BUNDLE_VENDOR="OBuildFactory"
export BUNDLE_VENDOR="OBuildFactory"

echo "Calculated MILESTONE=$OBF_MILESTONE, BUILD_NUMBER=$OBF_BUILD_NUMBER"

#
# Ensure cacerts are available
#
ensure_cacert

#
# Ensure Ant is available
#
ensure_ant

#
# Ensure freetype is correct one 
# 
ensure_freetype

#
# Build JDK/JRE images
#
if [ "$XUSE_NEW_BUILD_SYSTEM" = "true" ]; then
  build_new
else
  build_old
fi
	  
#
# Test Build
#
test_build

#
# Archive Builds
#
archive_build