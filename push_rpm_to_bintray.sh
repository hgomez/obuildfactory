#!/bin/sh
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

BINTRAY_ACCOUNT=$BINTRAY_USER

RPM_NAME=`rpm --queryformat "%{NAME}" -qp $RPM_FILE`
RPM_VERSION=`rpm --queryformat "%{VERSION}" -qp $RPM_FILE`
RPM_RELEASE=`rpm --queryformat "%{RELEASE}" -qp $RPM_FILE`
RPM_ARCH=`rpm --queryformat "%{ARCH}" -qp $RPM_FILE`

if [ -z "$RPM_NAME" ] || [ -z "$RPM_VERSION" ] || [ -z "$RPM_RELEASE" ] || [ -z "$RPM_ARCH" ]; then
  echo "no RPM metadata information in $RPM_FILE, skipping."
  exit -1
fi

echo "RPM_NAME=$RPM_NAME, RPM_VERSION=$RPM_VERSION, RPM_RELEASE=$RPM_RELEASE, RPM_ARCH=$RPM_ARCH"
echo "BINTRAY_USER=$BINTRAY_USER, BINTRAY_APIKEY=$BINTRAY_APIKEY, BINTRAY_REPO=$BINTRAY_REPO, RPM_FILE=$RPM_FILE, BASE_DESC=$BASE_DESC"

echo "@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@ delete package @@@"
echo "@@@@@@@@@@@@@@@@@@@@@@"
curl -vvf -u$BINTRAY_USER:$BINTRAY_APIKEY -H "Content-Type: application/json" -X DELETE https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$RPM_NAME

echo "@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@ create package @@@"
echo "@@@@@@@@@@@@@@@@@@@@@@"
curl -vvf -u$BINTRAY_USER:$BINTRAY_APIKEY -H "Content-Type: application/json" -X POST https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/ --data "{ \"name\": \"$RPM_NAME\", \"desc\": \"$RPM_NAME package\", \"desc_url\": \"$BASE_DESC/$RPM_NAME\", \"labels\": \"\" }"

#echo "@@@@@@@@@@@@@@@@@@@@@@"
#echo "@@@ delete version @@@"
#echo "@@@@@@@@@@@@@@@@@@@@@@"
#curl -vvf -u$BINTRAY_USER:$BINTRAY_APIKEY -X DELETE https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$RPM_NAME/versions/$RPM_VERSION-$RPM_RELEASE

echo "@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@ create version @@@"
echo "@@@@@@@@@@@@@@@@@@@@@@"
curl -vvf -u$BINTRAY_USER:$BINTRAY_APIKEY -H "Content-Type: application/json" -X POST https://api.bintray.com/packages/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$RPM_NAME/versions --data "{ \"name\": \"$RPM_VERSION-$RPM_RELEASE\", \"release_notes\": \"auto\", \"release_url\": \"$BASE_DESC/$RPM_NAME\", \"released\": \"\" }"

echo "@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@ upload content @@@"
echo "@@@@@@@@@@@@@@@@@@@@@@"
curl -vvf -T $RPM_FILE -u$BINTRAY_USER:$BINTRAY_APIKEY -H "X-Bintray-Package:$RPM_NAME" -H "X-Bintray-Version:$RPM_VERSION-$RPM_RELEASE" https://api.bintray.com/content/$BINTRAY_ACCOUNT/$BINTRAY_REPO/

echo "@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@@ publish content @@@"
echo "@@@@@@@@@@@@@@@@@@@@@@@"
curl -vvf -u$BINTRAY_USER:$BINTRAY_APIKEY -H "Content-Type: application/json" -X POST https://api.bintray.com/content/$BINTRAY_ACCOUNT/$BINTRAY_REPO/$RPM_NAME/$RPM_VERSION-$RPM_RELEASE/publish --data "{ \"discard\": \"false\" }"

