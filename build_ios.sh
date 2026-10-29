#!/bin/sh
# Build trên macOS runner (GitHub Actions). Máy Linux không có Xcode/iOS SDK.
set -e
cd "$(dirname "$0")"
xcrun --sdk iphoneos clang++ -arch arm64 -miphoneos-version-min=14.0 \
  -std=c++17 -fobjc-arc -x objective-c++ \
  mod.cpp CleanMenu.mm \
  -framework UIKit -framework Foundation -framework QuartzCore -framework CoreGraphics \
  -shared -o cleanmod.dylib
ls -lh cleanmod.dylib
file cleanmod.dylib
