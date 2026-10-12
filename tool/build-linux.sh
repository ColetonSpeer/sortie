#!/bin/bash
# Local release build for this laptop (run via: taskset -c 0-3 choom -n 1000 -- nice -n 10 tool/build-linux.sh)
export PATH=$HOME/flutter/bin:$PATH CC=/usr/bin/clang CXX=/usr/bin/clang++
cd "$(dirname "$0")/.."
flutter build linux --release --dart-define=SORTIE_VERSION=${SORTIE_VERSION:-0.1.0-dev}
echo "exit $?"
