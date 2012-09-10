#!/bin/sh

if [ -z "$BASE_URL" ]; then
  echo "missing BASE_URL, build aborted..."
  exit -1
fi

# prepare fresh directories
rm -rf BUILD RPMS SRPMS TEMP
mkdir -p BUILD RPMS SRPMS TEMP

# Build using rpmbuild (use double-quote for define to have shell resolv vars !)
rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="BASE_URL $BASE_URL" SPECS/obuildfactory-centos-repo.spec
rpmbuild -bb --define="_topdir $PWD" --define="_tmppath $PWD/TEMP" --define="BASE_URL $BASE_URL" SPECS/obuildfactory-fedora-repo.spec

