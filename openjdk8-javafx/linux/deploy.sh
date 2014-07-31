#!/bin/bash
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project, ie obuildfactory/openjdk8-lambda/linux)
#
# OBF_BASE_URL (ie: http://www.obuildfactory.org)
# OBF_BASE_PATH (ie: /home/jenkinsa/www)
# OBF_UPLOAD_PATH (ie: /home/jenkinsa/upload)
#
# OBF_BASE_ARCH (i386, x86_64, or ppc64)
# OBF_DISTRIBUTION (centos, fedora, opensuse...)
# OBF_RELEASE_VERSION (5, 6, 121)
#
# OBF_GPG_ID (ie: packagers@obuildfactory.org)
# OBF_GPG_PASSWORD (ie: 123456)
# OBF_UPLOADER_USER_ID (ie: henri)
# OBF_UPLOAD_HOST (ie: packages.obuildfactory.org)

DEST_ARCH=$OBF_BASE_ARCH

if [ "$OBF_DISTRIBUTION" = "opensuse" ]; then
  if [ "$OBF_BASE_ARCH" = "i386" ]; then
    DEST_ARCH=i586
  fi
fi

UPLOAD_DIR=$OBF_UPLOAD_PATH/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$DEST_ARCH
YUM_REPO_DIR=$OBF_BASE_PATH/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION/$DEST_ARCH
YUM_INDEX_DIR=$YUM_REPO_DIR

if [ "$OBF_DISTRIBUTION" = "opensuse" ]; then
  YUM_INDEX_DIR=$OBF_BASE_PATH/$OBF_DISTRIBUTION/$OBF_RELEASE_VERSION
fi

echo "### signing RPMS ###"
for RPM_FILE in $OBF_BUILD_PATH/rpm/RPMS/*/*.rpm; do
  $OBF_BUILD_PATH/rpmsign-batch.expect $OBF_GPG_ID $OBF_GPG_PASSWORD $RPM_FILE
done

[ "$OBF_DISTRIBUTION" = "centos" ] && [ "$OBF_RELEASE_VERSION" = "5" ] && CREATE_REPO_OPT="-s sha1"

echo "### creating upload directory ###"
ssh $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST -o StrictHostKeyChecking=no "mkdir -p $UPLOAD_DIR"

echo "### copying RPMs to upload directory $UPLOAD_DIR ###"
scp $OBF_BUILD_PATH/rpm/RPMS/*/*.rpm $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST:$UPLOAD_DIR
echo "### moving RPMs from upload directory to final destination ###"
ssh $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST "mkdir -p $YUM_REPO_DIR"
ssh $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST "mv $UPLOAD_DIR/* $YUM_REPO_DIR"

echo "### reindexing YUM repository ###"
ssh $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST "createrepo --update $CREATE_REPO_OPT $YUM_INDEX_DIR"
echo "### signing repomd.xml ###"
ssh $OBF_UPLOADER_USER_ID@$OBF_UPLOAD_HOST "gpg --yes --batch --passphrase=$OBF_GPG_PASSWORD --armor --sign $YUM_INDEX_DIR/repodata/repomd.xml"
