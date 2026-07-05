#!/bin/bash
set -e

FLUTTER_VERSION="3.44.4"
FLUTTER_DIR="/opt/flutter"
ARCHIVE="stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

# Install Flutter SDK
if [ ! -x ${FLUTTER_DIR}/bin/flutter ]; then
  curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/${ARCHIVE}" \
    -o /tmp/flutter.tar.xz
  tar -xf /tmp/flutter.tar.xz -C /opt
fi

git config --global --add safe.directory ${FLUTTER_DIR}
export PATH=${FLUTTER_DIR}/bin:$PATH

flutter config --no-analytics
flutter --version
flutter pub get
flutter build web --release --no-tree-shake-icons