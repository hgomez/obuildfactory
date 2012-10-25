#!/bin/bash
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8/macosx)
# OBF_SOURCES_PATH (absolute path of project sources)
# OBF_PROJECT_NAME (ie: openjdk7)
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

#
# Build FreeType for embedding
#
function ensure_freetype()
{
  if [ ! -f $OBF_DROP_DIR/freetype/lib/libfreetype.dylib ]; then
	  
	  FREETYPE_VERSION=2.4.10

	  if [ ! -f $OBF_DROP_DIR/freetype-$FREETYPE_VERSION.tar.bz2 ]; then
	    curl -L http://download.savannah.gnu.org/releases/freetype/freetype-$FREETYPE_VERSION.tar.bz2 -o $OBF_DROP_DIR/freetype-$FREETYPE_VERSION.tar.bz2
	  fi

	  if [ ! -d $OBF_DROP_DIR/freetype-patches ]; then
	    mkdir -p $OBF_DROP_DIR/freetype-patches
	    curl -L https://trac.macports.org/export/92468/trunk/dports/print/freetype/files/patch-modules.cfg.diff -o $OBF_DROP_DIR/freetype-patches/patch-modules.cfg.diff
	    curl -L https://trac.macports.org/export/92468/trunk/dports/print/freetype/files/patch-src_base_ftrfork.c.diff -o $OBF_DROP_DIR/freetype-patches/patch-src_base_ftrfork.c.diff
	  fi

	  rm -rf freetype-$FREETYPE_VERSION
	  rm -rf $OBF_DROP_DIR/freetype

	  tar xvjf $OBF_DROP_DIR/freetype-$FREETYPE_VERSION.tar.bz2
	  pushd freetype-$FREETYPE_VERSION >>/dev/null

	  for i in $OBF_DROP_DIR/freetype-patches/*; do
	    echo "applying patch $i"
	    patch -p0 <$i
	  done

	  ./configure --prefix=$OBF_DROP_DIR/freetype CC=/usr/bin/clang 'CFLAGS=-pipe -Os -arch i386 -arch x86_64' \
      'LDFLAGS=-arch i386 -arch x86_64' CXX=/usr/bin/clang++ 'CXXFLAGS=-pipe -Os -arch i386 -arch x86_64' \
      --disable-static --with-old-mac-fonts
	  make install

#	  cp $OBF_DROP_DIR/freetype/lib/libfreetype.6.dylib $OBF_DROP_DIR/freetype/lib/libfreetype.dylib
#	  install_name_tool -id @rpath/libfreetype.dylib $OBF_DROP_DIR/freetype/lib/libfreetype.dylib	  
	  
	  popd >>/dev/null
	  rm -rf freetype-$FREETYPE_VERSION
	  
  fi

  export ALT_FREETYPE_LIB_PATH=$OBF_DROP_DIR/freetype/lib
  export ALT_FREETYPE_HEADERS_PATH=$OBF_DROP_DIR/freetype/include
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
  export ALT_BOOTDIR=`/usr/libexec/java_home -v 1.6`
  export ALLOW_DOWNLOADS=true
  export ALT_CACERTS_FILE=$OBF_DROP_DIR/cacerts
  export ALT_BOOTDIR=$ALT_BOOTDIR
  export ALT_DROPS_DIR=$OBF_DROP_DIR
  export HOTSPOT_BUILD_JOBS=$NUM_CPUS
  export PARALLEL_COMPILE_JOBS=$NUM_CPUS
  export JAVA_HOME=

  case $CPU_BUILD_ARCH in
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
    mkdir -p $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH
    tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2 j2sdk-image
    tar cjf $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH/j2re-image-$CPU_BUILD_ARCH.tar.bz2 j2re-image
  
    echo "produced tarball files under $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH"
    ls -l $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH/j2sdk-image-$CPU_BUILD_ARCH.tar.bz2
    ls -l $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH/j2re-image-$CPU_BUILD_ARCH.tar.bz2
  
    popd
}

#
# Build start here
#

if [ "$XUSE_UNIVERSAL" = "true" ]; then
  export CPU_BUILD_ARCH=universal
else
  export CPU_BUILD_ARCH=`uname -m`
  rm -f $OBF_BUILD_PATH/patches/universal-build.patch
fi


export JDK_BUNDLE_VENDOR="OBuildFactory"
export BUNDLE_VENDOR="OBuildFactory"

echo "Calculated MILESTONE=$OBF_MILESTONE, BUILD_NUMBER=$OBF_BUILD_NUMBER"

#
# Ensure cacerts are available
#
ensure_cacert

#
# Ensure FreeType are built
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