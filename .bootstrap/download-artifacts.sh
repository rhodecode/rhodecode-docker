#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
# e.g 4.24.1
source ../.env
VER=$RC_VERSION
INSTALLER_URL=https://dls.rhodecode.com/dls/N2E2ZTY1NzA3NjYxNDA2NTc1NjI3MTcyNzA2MjcxNzIyZTcwNjI3YQ==/rhodecode-control/latest-linux-ee

echo "Downloading Artifacts for version: $VER"

MANIFEST=https://dls.rhodecode.com/linux/MANIFEST
CACHE_DIR=../.cache
VER_REGEX="$VER+x86_64"

echo "Downloading locale-archive"
curl -L https://dls.rhodecode.com/assets/locale-archive -J -O
mv -v locale-archive $CACHE_DIR

ARTS=$(curl -s $MANIFEST | grep --ignore-case "$VER_REGEX" | cut -d ' ' -f 2)

# vcsserver/ce/ee
echo "Found following $ARTS"

for url in $ARTS; do
    echo "Downloading $url"
    curl -L ${url} -J -O
done

## rhodecode control
#for url in $(curl -s $MANIFEST | grep --ignore-case -E 'control.+\+x86_64' | cut -d ' ' -f 2); do
#    echo "Downloading $url"
#    curl -L ${url} -J -O
#done

## installer
echo "Downloading installer from $INSTALLER_URL"
curl -L $INSTALLER_URL -J -O

INSTALLER=$(ls -Art RhodeCode-installer-* | tail -n 1)
if [[ -n $INSTALLER ]]; then
  chmod +x "${INSTALLER}"
fi

mv -v "${INSTALLER}" $CACHE_DIR
mv -v *.bz2 $CACHE_DIR
