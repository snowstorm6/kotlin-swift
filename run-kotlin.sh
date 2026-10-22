#!/bin/sh
# Chạy game rắn bản Kotlin trong Terminal (dùng tab Terminal của Android Studio cũng được).
set -e
cd "$(dirname "$0")/android"
./gradlew -q :terminal:installDist
exec terminal/build/install/snake/bin/snake
