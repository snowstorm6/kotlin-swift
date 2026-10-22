#!/bin/sh
# Chạy game rắn bản Swift trong Terminal.
set -e
cd "$(dirname "$0")/ios"
swift build -q
exec .build/debug/snake
