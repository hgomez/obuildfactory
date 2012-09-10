#!/bin/sh
#

# Required vars :
#
# BASE_URL (ie: http://www.obuildfactory.org)
# BASE_PATH (ie: /home/jenkinsa/upload)
#
# BASE_ARCH (i386 or x86_64)
# DISTRIBUTION (centos, fedora, opensuse...)
# RELEASE_VERSION (5, 6, 121)
#
# GPG_ID (ie: packagers@obuildfactory.org)
# GPG_PASSWORD (ie: 123456)
# UPLOADER_USER_ID (ie: henri)
# UPLOAD_HOST (ie: packages.obuildfactory.org)

DEST_ARCH=$BASE_ARCH

if [ "$DISTRIBUTION" = "opensuse" ]; then
  if [ "$BASE_ARCH" = "i386" ]; then
    DEST_ARCH=i586
  fi
fi

UPLOAD_DIR=$BASE_PATH/$DISTRIBUTION/$RELEASE_VERSION/$DEST_ARCH
YUM_REPO_DIR=$BASE_PATH/$DISTRIBUTION/$RELEASE_VERSION/$DEST_ARCH
YUM_INDEX_DIR=$YUM_REPO_DIR

if [ "$DISTRIBUTION" = "opensuse" ]; then
  YUM_INDEX_DIR=$BASE_PATH/$DISTRIBUTION/$RELEASE_VERSION
fi

echo "### signing RPMS ###"
for RPM_FILE in $PWD/linux/rpm/RPMS/*/*.rpm; do
  ./linux/rpmsign-batch.expect $GPG_ID $GPG_PASSWORD $RPM_FILE
done

if [ "$XUPLOAD" = "true" ]; then

  [ "$DISTRIBUTION" = "centos" ] && [ "$RELEASE_VERSION" = "5" ] && CREATE_REPO_OPT="-s sha1"

  echo "### creating upload directory ###"
  ssh $UPLOADER_USER_ID@$UPLOAD_HOST -o StrictHostKeyChecking=no "mkdir -p $UPLOAD_DIR"

  echo "### copying RPMs to upload directory $UPLOAD_DIR ###"
  scp linux/rpm/RPMS/*/*.rpm $UPLOADER_USER_ID@$UPLOAD_HOST:$UPLOAD_DIR
  echo "### moving RPMs from upload directory to final destination ###"
  ssh $UPLOADER_USER_ID@$UPLOAD_HOST "mkdir -p $YUM_REPO_DIR"
  ssh $UPLOADER_USER_ID@$UPLOAD_HOST "mv $UPLOAD_DIR/* $YUM_REPO_DIR"

  echo "### reindexing YUM repository ###"
  ssh $UPLOADER_USER_ID@$UPLOAD_HOST "createrepo --update $CREATE_REPO_OPT $YUM_INDEX_DIR"
  echo "### signing repomd.xml ###"
  ssh $UPLOADER_USER_ID@$UPLOAD_HOST "gpg --yes --batch --passphrase=$GPG_PASSWORD --armor --sign $YUM_INDEX_DIR/repodata/repomd.xml" 

fi