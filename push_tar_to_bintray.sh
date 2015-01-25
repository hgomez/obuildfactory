#!/bin/bash
#
# push_PACKAGE_to_bintray.sh - henri.gomez@gmail.com
#                            - christophe@labouisse.org
#
# This script push a generic package to Bintray repo
#

function usage() {
  echo "$0 username api_key repo_name PACKAGE_file site_url"
  exit 0
}

function doWithRetry() {
  local func=$1
  local maxLoop=2
  for LOOP in $(seq 0 $maxLoop)
  do
    if $func $LOOP; then
      RESULT="OK"
      break
    else
      RESULT="NOK"
      if [ "$LOOP" != "$maxLooop" ]; then
        echo "sleeping before retrying..."
        sleep 10
      fi
    fi
  done

  if [ "$RESULT" != "OK" ]; then
    echo "failed after many attempts, aborting"
    exit -1
  fi
}

function createPackage() {
  echo "Creating package on Bintray, attempt #$1 ..."
  DATA_JSON="{ \"name\": \"$PACKAGE_NAME\", \"desc\": \"${PACKAGE_DESCRIPTION}\", \"desc_url\": \"$DESC_URL\", \"labels\": \"\", \"licenses\": [ \"$PACKAGE_LICENSE\" ]}"

  if [ "$XDEBUG" = "true" ]; then
    echo "DATA_JSON=$DATA_JSON"
  fi

  HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X POST https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/ --data "$DATA_JSON"`

  if [ "$HTTP_CODE" != "201" ]; then
    echo "can't create package -> $HTTP_CODE"
    echo "sleeping before retrying..."
    return -1
  else
    echo "Package created"
    return 0
  fi
}

function createVersion() {
  echo "Creating version on Bintray, attempt #$1 ..."
  DATA_JSON="{ \"name\": \"$BINTRAY_VERSION\", \"desc\": \"Version to be uploaded\" }"

  if [ "$XDEBUG" = "true" ]; then
    echo "DATA_JSON=$DATA_JSON"
  fi

  HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X POST https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$PACKAGE_NAME/versions --data "$DATA_JSON"`

  if [ "$HTTP_CODE" != "201" ]; then
    echo "can't create version -> $HTTP_CODE"
    echo "sleeping before retrying..."
    return -1
  else
    echo "Version created"
    return 0
  fi
}

function updateVersion() {
  echo "Updating version on Bintray, attempt #$1 ..."
  DATA_JSON="{ \"desc\": \"$BINTRAY_VERSION-$PACKAGE_BUILD\", \"vcs_tag\": \"$BINTRAY_VERSION-$PACKAGE_BUILD\" }"

  if [ "$XDEBUG" = "true" ]; then
    echo "DATA_JSON=$DATA_JSON"
  fi

  HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X PATCH https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$PACKAGE_NAME/versions/$BINTRAY_VERSION --data "$DATA_JSON"`

  if [ "$HTTP_CODE" != "200" ]; then
    echo "can't update version -> $HTTP_CODE"
    echo "sleeping before retrying..."
    return -1
  else
    echo "Version updated"
    return 0
  fi
}

function uploadPackage() {
  echo "Uploading package to Bintray, attempt #$1 ..."
  HTTP_CODE=`$CURL_CMD -T $PACKAGE_FILE -H "X-Bintray-Package:$PACKAGE_NAME" -H "X-Bintray-Version:$BINTRAY_VERSION" "https://api.bintray.com/content/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$REPO_FILE_PATH;publish=1;override=1"`

  if [ "$HTTP_CODE" != "201" ]; then
    echo "failed to upload package -> $HTTP_CODE"
    echo "sleeping before retrying..."
    return -1
  else
    echo "Package uploaded"
    return 0
  fi
}

if [ $# -lt 5 ]; then
 usage
fi

BINTRAY_USER=$1
BINTRAY_APIKEY=$2
BINTRAY_REPO=$3
PACKAGE_FILE=$4
BASE_DESC=$5

if [ "$XDEBUG" = "true" ]; then
  CURL_CMD="curl -v -L --write-out %{http_code} --output curl-command.log -u$BINTRAY_USER:$BINTRAY_APIKEY"
else
  CURL_CMD="curl -L --write-out %{http_code} --silent --output curl-command.log -u$BINTRAY_USER:$BINTRAY_APIKEY"
fi

BINTRAY_ACCOUNT=$BINTRAY_USER

BASE=`basename $PACKAGE_FILE`
PACKAGE_NAME=`echo $BASE | cut -d - -f 1-4`
PACKAGE_VERSION=`echo $BASE | cut -d - -f 5 | cut -d _ -f 1`
PACKAGE_RELEASE=`echo $BASE | cut -d - -f 5 | cut -d _ -f 2`
PACKAGE_BUILD=`echo $BASE | cut -d - -f 5- | cut -d _ -f 2 | cut -d . -f 1 | cut -d b -f 2`
PACKAGE_ARCH=`echo $BASE | cut -d - -f 4`
PACKAGE_EXT=`echo $BASE | sed 's/^.*\.tar/tar/'`
PACKAGE_LICENSE="GPL-2.0"
PACKAGE_DESCRIPTION="Generic version of $PACKAGE_NAME $PACKAGE_VERSION-$PACKAGE_RELEASE"

# Removing the build number from the repo file path
REPO_FILE_PATH=$PACKAGE_NAME-${PACKAGE_VERSION}_$PACKAGE_RELEASE.$PACKAGE_EXT
DESC_URL=$BASE_DESC
BINTRAY_VERSION=$PACKAGE_VERSION-$PACKAGE_RELEASE

if [ -z "$PACKAGE_NAME" ] || [ -z "$PACKAGE_VERSION" ] || [ -z "$PACKAGE_RELEASE" ] || [ -z "$PACKAGE_ARCH" ]; then
  echo "Cannot extract package data from $PACKAGE_FILE, skipping."
  exit -1
fi

echo "PACKAGE_NAME=$PACKAGE_NAME, PACKAGE_VERSION=$PACKAGE_VERSION, PACKAGE_RELEASE=$PACKAGE_RELEASE, PACKAGE_BUILD=$PACKAGE_BUILD, PACKAGE_ARCH=$PACKAGE_ARCH"
echo "BINTRAY_USER=$BINTRAY_USER, BINTRAY_REPO=$BINTRAY_REPO, PACKAGE_FILE=$PACKAGE_FILE, BASE_DESC=$BASE_DESC"

if [ "$XCLEAN" = "true" ]; then
  echo "Deleting package from Bintray.."
  HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X DELETE https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$PACKAGE_NAME`

  if [ "$HTTP_CODE" != "200" ]; then
    echo "can't delete package -> $HTTP_CODE"
    exit -1
  else
    echo "Package deleted"
  fi
fi

# Check if package exists
HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$PACKAGE_NAME`

if [ "$HTTP_CODE" != "200" ]; then
  echo "Creating package"
  doWithRetry createPackage
fi

if [ "$XCLEAN_VERSION" = "true" ]; then
  echo "Deleting version $BINTRAY_VERSION from Bintray.."
  HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X DELETE https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$PACKAGE_NAME/version/$BINTRAY_VERSION`

  if [ "$HTTP_CODE" != "200" ]; then
    echo "can't delete version -> $HTTP_CODE"
    exit -1
  else
    echo "Version deleted"
  fi
fi

# Check if version exists
HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$PACKAGE_NAME/versions/$BINTRAY_VERSION`

if [ "$HTTP_CODE" != "200" ]; then
  echo "Creating new version"
  doWithRetry createVersion
else
  RELEASED_VERSION=$(cat curl-command.log | sed 's/^.*"vcs_tag":"\([^"]*\)".*$/\1/')
  if [ $RELEASED_VERSION = "$BINTRAY_VERSION-$PACKAGE_BUILD" ]; then
    echo "Already deployed"
    exit 0
  fi
fi

doWithRetry uploadPackage
doWithRetry updateVersion

exit 0
