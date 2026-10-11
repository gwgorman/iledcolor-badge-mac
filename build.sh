#!/bin/zsh
set -eu
cd "${0:A:h}"
mkdir -p .build/swift-cache
swiftc -module-cache-path "$PWD/.build/swift-cache" BadgeProtocol.swift ble-scan.swift -o badge-tool
echo "Built $PWD/badge-tool"
