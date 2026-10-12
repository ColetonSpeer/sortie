#!/bin/bash
# Local signed release APK (run via: taskset -c 0-3 choom -n 1000 -- nice -n 10 tool/build-apk.sh)
export PATH=$HOME/flutter/bin:$PATH ANDROID_HOME=$HOME/android-sdk JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
cd "$(dirname "$0")/.."
flutter build apk --release --dart-define=SORTIE_VERSION=${SORTIE_VERSION:-0.1.0-dev}
echo "exit $?"
