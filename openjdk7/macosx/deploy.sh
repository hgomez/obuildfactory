#!/bin/sh
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8-lambda/linux)
#
# OBF_BASE_URL (ie: http://www.obuildfactory.org)
# OBF_BASE_PATH (ie: /home/jenkinsa/www)
# OBF_UPLOAD_PATH (ie: /home/jenkinsa/upload)
#
# OBF_BASE_ARCH (i386, x86_64 or universal)
# OBF_RELEASE_VERSION (10.6, 10.7, 10.8)
#
# OBF_GPG_ID (ie: packagers@obuildfactory.org)
# OBF_GPG_PASSWORD (ie: 123456)
# OBF_UPLOADER_USER_ID (ie: henri)
# OBF_UPLOAD_HOST (ie: packages.obuildfactory.org)

set -e

UPLOAD_DIR=$OBF_UPLOAD_PATH/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH
DMG_REPO_DIR=$OBF_BASE_PATH/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH

echo "### creating upload directory ###"
ssh $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST -o StrictHostKeyChecking=no "mkdir -p $UPLOAD_DIR"

echo "### copying DMGs to upload directory $UPLOAD_DIR ###"
scp $OBF_DROP_DIR/$OBF_PROJECT_NAME/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$OBF_BASE_ARCH/*.dmg $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST:$UPLOAD_DIR
echo "### moving DMGs from upload directory to final destination ###"
ssh $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST "mkdir -p $DMG_REPO_DIR"
ssh $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST "mv $UPLOAD_DIR/* $DMG_REPO_DIR"
