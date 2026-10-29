#!/bin/sh
# Builds ISO2GOD.app: Swift UI + iso2god (convert) + cover (Aurora .asset downloader).
# Needs: Xcode (full, not only Command Line Tools: SwiftUI macros), Rust (brew install rust).
set -e
cd "$(dirname "$0")"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
APP=ISO2GOD.app
C=$APP/Contents

rm -rf "$APP"
mkdir -p "$C/MacOS" "$C/Resources"

cargo install --git https://github.com/iliazeus/iso2god-rs --rev 76207d7 --locked --root build
(cd cover && cargo build --release --locked)

cp build/bin/iso2god cover/target/release/cover "$C/Resources/"
swiftc -parse-as-library -O main.swift -o "$C/MacOS/ISO2GOD"
cp Info.plist "$C/"
codesign --force --deep -s - "$APP"
echo "Built $APP"
