# Working on this badge project

Read README.md and docs/PROTOCOL.md before changing the codec or transport. The target is a 48×12 **monochrome** badge. Its colored front cover does not make it RGB.

Keep rendering in render.py separate from wire encoding in BadgeProtocol.swift and CoreBluetooth transport in ble-scan.swift. Preserve the approved keeper demo when experimenting: generate new assets under a distinct filename, unless the user requests a keeper edit.

Verified monochrome frames are 96 bytes: 48 left-to-right columns, two vertical MSB-first bytes per column. There is no two-byte suffix between animation frames. Do not reintroduce the RGB reference layout. A successful BLE acknowledgement does not prove correct visual output.

Follow the user's requested scope. A request to upload a revised badge animation authorizes replacing current display content. Do not send delete-all, change passwords, or make unrelated device changes. For ordinary local artwork edits, proceed without unnecessary confirmation. Ask for visual feedback when physical behavior cannot be observed.

Validate frame dimensions, glyph fit, and requested timing; compile Swift after Swift changes. Do not upload to hardware merely to test a documentation edit. Use badge-only or sanitized evidence; do not commit nearby-device scans, credentials, compiler caches, or binaries.

Be concise and practical. Distinguish visual confirmation, packet acknowledgements, inference, and untested behavior. If no Mac/Bluetooth tools are available, create usable local assets and give the owner the exact upload command rather than claiming an upload.
