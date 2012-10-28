#!/bin/bash
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8/macosx)
# OBF_SOURCES_PATH (absolute path of project sources)
# OBF_PROJECT_NAME (ie: openjdk8)
# OBF_MILESTONE (ie: u8-b10)

function cacerts_gen()
{
  local DESTCERTS=$1
  local TMPCERTSDIR=`mktemp -d certs`
  
  pushd $TMPCERTSDIR
  curl -L http://curl.haxx.se/ca/cacert.pem -o cacert.pem
  cat cacert.pem | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{ print $0; }' > cacert-clean.pem
  rm -f cacerts cert_*
  split  -p "-----BEGIN CERTIFICATE-----" cacert-clean.pem cert_

  export JAVA_HOME=`/usr/libexec/java_home -v 1.6`

  for CERT_FILE in cert_*; do
    ALIAS=$(basename ${CERT_FILE})
    echo yes | keytool -import -alias ${ALIAS} -keystore cacerts -storepass 'changeit' -file ${CERT_FILE} || :
    rm -f $CERT_FILE
  done

  unset JAVA_HOME
  
  rm -f cacert.pem cacert-clean.pem
  mv cacerts $DESTCERTS

  popd
  rm -rf $TMPCERTSDIR
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

#
# Build using old build system
# 
function build_old()
{
  echo "### using old build system ###"
  
  NUM_CPUS=`sysctl -n hw.ncpu`

  export MILESTONE="$OBF_BUILD_NUMBER"
  export BUILD_NUMBER="$OBF_BUILD_DATE"
  
  export LD_LIBRARY_PATH=
  export ALT_BOOTDIR=`/usr/libexec/java_home -v 1.7`
  export ALLOW_DOWNLOADS=true
  export ALT_CACERTS_FILE=$OBF_DROP_DIR/cacerts
  export ALT_BOOTDIR=$ALT_BOOTDIR
  export ALT_DROPS_DIR=$OBF_DROP_DIR
  export HOTSPOT_BUILD_JOBS=$NUM_CPUS
  export PARALLEL_COMPILE_JOBS=$NUM_CPUS
  export JAVA_HOME=

  if [ "$XDEBUG" = "true" ]; then
    export SKIP_FASTDEBUG_BUILD=false
  fi

  case $OBF_BASE_ARCH in
  	x86_64)
		export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/macosx-x86_64
  	;;
  	i386)
  		export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/macosx-i586
  	;;
  	universal)
  		export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/macosx-universal
  	;;
  esac
  
  # Set Company Name to OBuildFactory
  sed -i "" -e "s|COMPANY_NAME = N/A|COMPANY_NAME = $BUNDLE_VENDOR|g" $OBF_SOURCES_PATH/jdk/make/common/shared/Defs.gmk
  
  pushd $OBF_SOURCES_PATH >>/dev/null
  make ALLOW_DOWNLOADS=true SA_APPLE_BOOT_JAVA=true ALWAYS_PASS_TEST_GAMMA=true ALT_BOOTDIR=$ALT_BOOTDIR ALT_DROPS_DIR=$DROP_DIR HOTSPOT_BUILD_JOBS=$NUM_CPUS PARALLEL_COMPILE_JOBS=$NUM_CPUS
  popd >>/dev/null
}

#
# Build using new build system
# 
function build_new()
{
    echo "### using new build system ###"

    pushd $OBF_SOURCES_PATH/common/makefiles >>/dev/null
  
    # patch common/autoconf/version.numbers
    mv ../autoconf/version.numbers ../autoconf/version.numbers.orig 
    cat ../autoconf/version.numbers.orig | grep -v "MILESTONE" | grep -v "JDK_BUILD_NUMBER" | grep -v "COMPANY_NAME" > ../autoconf/version.numbers

    export JDK_BUILD_NUMBER=$OBF_BUILD_DATE
    export MILESTONE=$OBF_MILESTONE
    export COMPANY_NAME=$BUNDLE_VENDOR

    mkdir -p $OBF_WORKSPACE_PATH/.ccache

    case $OBF_BASE_ARCH in
    	x86_64)
  			export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/macosx-x86_64
    	;;
    	i386)
    		export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/macosx-i586
    	;;
    	universal)
    		export IMAGE_BUILD_DIR=$OBF_SOURCES_PATH/build/macosx-universal
    	;;
    esac

    if [ "$XDEBUG" = "true" ]; then
	    sh ../autoconf/configure --with-boot-jdk=$OBF_BOOTDIR --with-cacerts-file=$OBF_DROP_DIR/cacerts --with-ccache-dir=$OBF_WORKSPACE_PATH/.ccache --enable-debug
	else
	    sh ../autoconf/configure --with-boot-jdk=$OBF_BOOTDIR --with-cacerts-file=$OBF_DROP_DIR/cacerts --with-ccache-dir=$OBF_WORKSPACE_PATH/.ccache
    fi

    make images

    # restore original common/autoconf/version.numbers
    mv ../autoconf/version.numbers.orig ../autoconf/version.numbers

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
    mkdir -p $OBF_DROP_DIR/$OBF_PROJECT_NAME

    pushd $IMAGE_BUILD_DIR >>/dev/null
	
    if [ "$XDEBUG" = "true" ]; then
    	FILENAME_PREFIX="-fastdebug"
    fi
	
    tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 j2sdk-image$FILENAME_PREFIX
    tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-image$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 j2re-image$FILENAME_PREFIX
	popd >>/dev/null

    pushd $IMAGE_BUILD_DIR/j2sdk-bundle >>/dev/null
    tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2sdk-bundle$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 jdk1.7.0.jdk
	popd >>/dev/null

    pushd $IMAGE_BUILD_DIR/j2re-bundle >>/dev/null
    tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/j2re-bundle$FILENAME_PREFIX-$OBF_BASE_ARCH-$OBF_BUILD_NUMBER-$OBF_BUILD_DATE.tar.bz2 jre1.7.0.jre
	popd >>/dev/null
  
    echo "produced tarball files under $OBF_DROP_DIR/$OBF_PROJECT_NAME"
    ls -l $OBF_DROP_DIR/$OBF_PROJECT_NAME/*$OBF_BUILD_NUMBER-$OBF_BUILD_DATE*
}

#
# Build start here
#

export JDK_BUNDLE_VENDOR="OBuildFactory"
export BUNDLE_VENDOR="OBuildFactory"

echo "Calculated MILESTONE=$OBF_MILESTONE, BUILD_NUMBER=$OBF_BUILD_NUMBER"

#
# Ensure cacerts are available
#
ensure_cacert

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
