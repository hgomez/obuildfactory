#!/bin/bash
#
# push_deb_to_bintray.sh - henri.gomez@gmail.com
# 
# This script push a deb package to Bintray repo
#

function usage() {
  echo "$0 username api_key repo_name deb_file site_url"
  exit 0
}

if [ $# -lt 5 ]; then
 usage
fi

BINTRAY_USER=$1
BINTRAY_APIKEY=$2
BINTRAY_REPO=$3
DEB_FILE=$4
BASE_DESC=$5

if [ "$XDEBUG" = "true" ]; then
  CURL_CMD="curl -v -L --write-out %{http_code} --output curl-command.log -u$BINTRAY_USER:$BINTRAY_APIKEY"
else
  CURL_CMD="curl -L --write-out %{http_code} --silent --output /dev/null -u$BINTRAY_USER:$BINTRAY_APIKEY"
fi

BINTRAY_ACCOUNT=$BINTRAY_USER

DEB_NAME=`dpkg-deb --showformat=\$\{Package\} -W $DEB_FILE`
DEB_VERSION=`dpkg-deb --showformat=\$\{Version\} -W $DEB_FILE`
DEB_RELEASE=1
DEB_ARCH=`dpkg-deb --showformat=\$\{Architecture\} -W $DEB_FILE`
DEB_LICENSE=`dpkg-deb --showformat=\$\{License\} -W $DEB_FILE`
DEB_DESCRIPTION=`dpkg-deb --showformat=\$\{Description\} -W $DEB_FILE`

REPO_FILE_PATH=`basename $DEB_FILE`
DESC_URL=$BASE_DESC

if [ -z "$DEB_NAME" ] || [ -z "$DEB_VERSION" ] || [ -z "$DEB_RELEASE" ] || [ -z "$DEB_ARCH" ]; then
  echo "no DEB metadata information in $DEB_FILE, skipping."
  exit -1
fi

echo "DEB_NAME=$DEB_NAME, DEB_VERSION=$DEB_VERSION, DEB_RELEASE=$DEB_RELEASE, DEB_ARCH=$DEB_ARCH"
echo "BINTRAY_USER=$BINTRAY_USER, BINTRAY_REPO=$BINTRAY_REPO, DEB_FILE=$DEB_FILE, BASE_DESC=$BASE_DESC"

echo "Deleting package from Bintray.."
HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X DELETE https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$DEB_NAME`

if [ "$HTTP_CODE" != "200" ]; then
 echo "can't delete package -> $HTTP_CODE"
else
 echo "Package deleted"
fi

for LOOP in 0 1 2
do

  echo "Creating package on Bintray, attempt #$LOOP ..."
  DATA_JSON="{ \"name\": \"$DEB_NAME\", \"desc\": \"${DEB_DESCRIPTION}\", \"desc_url\": \"$DESC_URL\", \"labels\": \"\", \"licenses\": [ \"$DEB_LICENSE\" ]}"

  if [ "$XDEBUG" = "true" ]; then
    echo "DATA_JSON=$DATA_JSON"
  fi

  HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X POST https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/ --data "$DATA_JSON"`

  if [ "$HTTP_CODE" != "201" ]; then
    echo "can't create package -> $HTTP_CODE"
    echo "sleeping before retrying..."
    sleep 10
    CREATED="NOK"
  else
    echo "Package created"
    CREATED="OK"
    break
  fi

done

if [ "$CREATED" != "OK" ]; then
  echo "failed to create package after many attempts, aborting"
  exit -1
fi

for LOOP in 0 1 2
do

  echo "Uploading package to Bintray, attempt #$LOOP ..."
  HTTP_CODE=`$CURL_CMD -T $DEB_FILE -u$BINTRAY_USER:$BINTRAY_APIKEY -H "X-Bintray-Package:$DEB_NAME" -H "X-Bintray-Version:$DEB_VERSION-$DEB_RELEASE" "https://api.bintray.com/content/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$REPO_FILE_PATH;publish=1"`

  if [ "$HTTP_CODE" != "201" ]; then
    echo "failed to upload package -> $HTTP_CODE"
    echo "sleeping before retrying..."
    sleep 10
    CREATED="NOK"
  else
    echo "Package uploaded"
    CREATED="OK"
    break
  fi

done

if [ "$CREATED" != "OK" ]; then
  echo "failed to upload package after many attempts, aborting"
  exit -1
fi

exit 0

