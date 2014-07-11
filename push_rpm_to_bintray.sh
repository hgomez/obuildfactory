#!/bin/bash
#
# push_rpm_to_bintray.sh - henri.gomez@gmail.com
# 
# This script push a rpm package to Bintray repo
#

function usage() {
  echo "$0 username api_key repo_name rpm_file site_url"
  exit 0
}

if [ $# -lt 5 ]; then
 usage
fi

BINTRAY_USER=$1
BINTRAY_APIKEY=$2
BINTRAY_REPO=$3
RPM_FILE=$4
BASE_DESC=$5

if [ "$XDEBUG" = "true" ]; then
  CURL_CMD="curl -v -L --write-out %{http_code} --output curl-command.log -u$BINTRAY_USER:$BINTRAY_APIKEY"
else
  CURL_CMD="curl -L --write-out %{http_code} --silent --output /dev/null -u$BINTRAY_USER:$BINTRAY_APIKEY"
fi

BINTRAY_ACCOUNT=$BINTRAY_USER

RPM_NAME=`rpm --queryformat "%{NAME}" -qp $RPM_FILE`
RPM_VERSION=`rpm --queryformat "%{VERSION}" -qp $RPM_FILE`
RPM_RELEASE=`rpm --queryformat "%{RELEASE}" -qp $RPM_FILE`
RPM_ARCH=`rpm --queryformat "%{ARCH}" -qp $RPM_FILE`
RPM_LICENSE=`rpm --queryformat "%{LICENSE}" -qp $RPM_FILE`
RPM_DESCRIPTION=`rpm --queryformat "%{DESCRIPTION}" -qp $RPM_FILE`

REPO_FILE_PATH=`basename $RPM_FILE`
DESC_URL=$BASE_DESC

if [ -z "$RPM_NAME" ] || [ -z "$RPM_VERSION" ] || [ -z "$RPM_RELEASE" ] || [ -z "$RPM_ARCH" ]; then
  echo "no RPM metadata information in $RPM_FILE, skipping."
  exit -1
fi

echo "RPM_NAME=$RPM_NAME, RPM_VERSION=$RPM_VERSION, RPM_RELEASE=$RPM_RELEASE, RPM_ARCH=$RPM_ARCH"
echo "BINTRAY_USER=$BINTRAY_USER, BINTRAY_REPO=$BINTRAY_REPO, RPM_FILE=$RPM_FILE, BASE_DESC=$BASE_DESC"

echo "Deleting package from Bintray.."
HTTP_CODE=`$CURL_CMD -H "Content-Type: application/json" -X DELETE https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$RPM_NAME`

if [ "$HTTP_CODE" != "200" ]; then
 echo "can't delete package -> $HTTP_CODE"
else
 echo "Package deleted"
fi

for LOOP in 0 1 2
do

  echo "Creating package on Bintray, attempt #$LOOP ..."
  DATA_JSON="{ \"name\": \"$RPM_NAME\", \"desc\": \"${RPM_DESCRIPTION}\", \"desc_url\": \"$DESC_URL\", \"labels\": \"\", \"licenses\": [ \"$RPM_LICENSE\" ]}"

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
  HTTP_CODE=`$CURL_CMD -T $RPM_FILE -u$BINTRAY_USER:$BINTRAY_APIKEY -H "X-Bintray-Package:$RPM_NAME" -H "X-Bintray-Version:$RPM_VERSION-$RPM_RELEASE" "https://api.bintray.com/content/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$REPO_FILE_PATH;publish=1"`

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

