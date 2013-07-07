#!/bin/bash
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8-lambda/linux)
# OBF_SOURCES_PATH (absolute path of project sources)
# OBF_PROJECT_NAME (ie: openjdk8-lambda)
# OBF_MILESTONE (ie: b56-lambda)
#
# build mercurial : http://hg.openjdk.java.net/build-infra/jdk8/
#
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
  if [ ! -x $OBF_DROP_DIR/ant/bin/ant ]; then
    mkdir -p $OBF_DROP_DIR/ant
    pushd $OBF_DROP_DIR/ant
    curl -L http://archive.apache.org/dist/ant/binaries/apache-ant-1.8.4-bin.tar.gz -o apache-ant-1.8.4-bin.tar.gz
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

    export OBF_FREETYPE_DIR=$OBF_DROP_DIR/freetype
    export OBF_FREETYPE_LIB_PATH=$OBF_FREETYPE_DIR/lib
    export OBF_FREETYPE_HEADERS_PATH=$OBF_FREETYPE_DIR/include

  fi
}

#
# Under RHEL/CentOS/Fedora, switch to dynamic linking for C++
# Andrew from RH recommand it for all Gnu/Linux distributions
#
function set_stdcpp_mode()
{
  if [ `uname` = "Linux" ]; then
      export STATIC_CXX=false
  fi
}

#
# Determine BUILD JVM to use
#
function ensure_java7() 
{
  if [ ! -z "$OBF_JAVA7_HOME" ]; then
    export OBF_BOOTDIR=$OBF_JAVA7_HOME
    return
  fi
	  
  if [ "$CPU_BUILD_ARCH" = "x86_64" ]; then

    if [ -d /opt/obuildfactory/jdk-1.7.0-openjdk-x86_64 ]; then
      export OBF_BOOTDIR=/opt/obuildfactory/jdk-1.7.0-openjdk-x86_64
    else
      echo "missing required Java 7, aborting..."
    fi
    
  else

  if [ -d /opt/obuildfactory/jdk-1.7.0-openjdk-i686 ]; then
    export OBF_BOOTDIR=/opt/obuildfactory/jdk-1.7.0-openjdk-i686
  else
    echo "missing required Java 7, aborting..."
  fi

  fi
}

#
# Build using old build system
# 
function build_old()
{
  echo "### using old build system ###"
  
  NUM_CPUS=`grep "processor" /proc/cpuinfo | sort -u | wc -l`

  export BUILD_NUMBER="$OBF_BUILD_DATE"
  export MILESTONE="$OBF_MILESTONE"

  export ALT_BOOTDIR=$OBF_BOOTDIR
  export LD_LIBRARY_PATH=
  export JAVA_HOME=
  export ALLOW_DOWNLOADS=true
  export ALT_CACERTS_FILE=$OBF_DROP_DIR/cacerts
  export ALT_BOOTDIR=$ALT_BOOTDIR
  export ALT_DROPS_DIR=$OBF_DROP_DIR
  export HOTSPOT_BUILD_JOBS=$NUM_CPUS
  export PARALLEL_COMPILE_JOBS=$NUM_CPUS
  export ANT_HOME=$ANT_HOME
  export ALT_FREETYPE_LIB_PATH=$OBF_FREETYPE_LIB_PATH
  export ALT_FREETYPE_HEADERS_PATH=$OBF_FREETYPE_HEADERS_PATH
  export STATIC_CXX=false

  if [ "$XDEBUG" = "true" ]; then
    export SKIP_FASTDEBUG_BUILD=false
  fi
  
  if [ "$CPU_BUILD_ARCH" = "x86_64" ]; then
    export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/linux-amd64
  else
    export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/linux-i586
  fi

  if [ "$XCLEAN" = "true" ]; then
    rm -rf $IMAGE_BUILD_DIR
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
  echo "### using new build system ###"

  if [ "$CPU_BUILD_ARCH" = "x86_64" ]; then
    export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/linux-x86_64-normal-server-release/images
  else
    export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/linux-x86-normal-server-release/images
  fi
  
  pushd $OBF_SOURCES_PATH/common/makefiles >>/dev/null
  
  # patch common/autoconf/version.numbers
  if [ -f ../autoconf/version.numbers ]; then
    mv ../autoconf/version.numbers ../autoconf/version.numbers.orig 
    cat ../autoconf/version.numbers.orig | grep -v "MILESTONE" | grep -v "JDK_BUILD_NUMBER" | grep -v "COMPANY_NAME" > ../autoconf/version.numbers
  fi

  export JDK_BUILD_NUMBER=$OBF_BUILD_DATE
  export MILESTONE=$OBF_MILESTONE
  export COMPANY_NAME=$BUNDLE_VENDOR

  rm -rf $OBF_WORKSPACE_PATH/.ccache
  mkdir -p $OBF_WORKSPACE_PATH/.ccache

  if [ "$XDEBUG" = "true" ]; then

	  if [ "$CPU_BUILD_ARCH" = "x86_64" ]; then
	    BUILD_PROFILE=linux-x86_64-normal-server-fastdebug
	  else
  	    BUILD_PROFILE=linux-x86-normal-server-fastdebug
	  fi
  
	  bash ../autoconf/configure --with-boot-jdk=$OBF_BOOTDIR --with-freetype=$OBF_DROP_DIR/freetype --with-cacerts-file=$OBF_DROP_DIR/cacerts --with-ccache-dir=$OBF_WORKSPACE_PATH/.ccache --enable-debug \
                               --with-build-number=$OBF_BUILD_DATE --with-milestone=$OBF_MILESTONE

  else

	  if [ "$CPU_BUILD_ARCH" = "x86_64" ]; then
	    BUILD_PROFILE=linux-x86_64-normal-server-release
	  else
	    BUILD_PROFILE=linux-x86-normal-server-release
	  fi
  
	  bash ../autoconf/configure --with-boot-jdk=$OBF_BOOTDIR --with-freetype=$OBF_FREETYPE_DIR --with-cacerts-file=$OBF_DROP_DIR/cacerts --with-ccache-dir=$OBF_WORKSPACE_PATH/.ccache \
                               --with-build-number=$OBF_BUILD_DATE --with-milestone=$OBF_MILESTONE

  fi

  export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/$BUILD_PROFILE/images

  if [ "$XCLEAN" = "true" ]; then
	  CONT=$BUILD_PROFILE make clean
  fi
  
  CONT=$BUILD_PROFILE make images

  # restore original common/autoconf/version.numbers
  if [ -f ../autoconf/version.numbers.orig ]; then
    mv ../autoconf/version.numbers.orig ../autoconf/version.numbers
  fi

  popd >>/dev/null
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

  if [ "$XDEBUG" = "true" ]; then
  	FILENAME_PREFIX="-fastdebug"
  fi
		
  tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 j2sdk-image
  tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 j2re-image
  
  echo "produced tarball files under $OBF_DROP_DIR/$OBF_PROJECT_NAME"
  ls -l $OBF_DROP_DIR/$OBF_PROJECT_NAME/2sdk-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2
  ls -l $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2
  
  popd
}

#
# Build start here
#

CPU_BUILD_ARCH=`uname -m`

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
# Set correct GCC mode
#
set_stdcpp_mode

#
# Select Java 7 (32 / 64bits)
#
ensure_java7

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
