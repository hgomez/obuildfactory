#!/bin/sh
#

# Required vars :
#
# OBF_BUILD_PATH (absolute path of project build scripts, ie obuildfactory/openjdk8/linux)
# OBF_SOURCES_PATH (absolute path of project sources)
#

set -e

pushd $OBF_BUILD_PATH >>/dev/null

echo "test later"

popd >> /dev/null
