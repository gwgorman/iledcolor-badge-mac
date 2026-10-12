# iLEDCOLOR badge controller for Mac

Created by **Greg Gorman with Max (OpenAI Codex)**.

A small CoreBluetooth command-line tool for a 48×12 monochrome LED badge advertising as `iledcolor-012B`. Its red/blue/green/white front cover supplies apparent color; the pixels are not independently RGB.

## Quick start

Requires macOS, Swift command-line developer tools, and Python 3 for rendering. Allow Bluetooth access when macOS requests it. Power on the badge near the Mac and disconnect the iPhone app.

```sh
zsh build.sh
./badge-tool                         # enumerate GATT, no writes
./badge-tool --brightness 30
python3 render.py --demo --out nasa-demo.json
./badge-tool --upload nasa-demo.json
```

The demo is NASA graphic → Hi! I'm → Greg → Your Tour Guide → animated rocket → USS GORMAN → loop. It contains 191 locally rendered frames, requesting 100 ms per frame.

```sh
python3 render.py --text 'HELLO GREG' --out hello.json
./badge-tool --upload hello.json
```

Long text is rendered as scrolling frames. The general 3×5 font supports A–Z and spaces; the demo uses proportional mixed-case lettering up to 11 pixels tall for Greg and Tour Guide, NASA and USS GORMAN use matching 4×7 capitals with a two-pixel diagonal center in N. Arbitrary static bitmaps and frame sequences can be supplied as JSON: `width:48`, `height:12`, `frameMs:100`, `packing:"column16"`, and `frames`, each containing twelve strings of 48 binary digits.

## What is verified

- Live service and characteristic discovery on this badge.
- Brightness command at 30%, acknowledged and visually confirmed.
- Upload transaction acknowledgements.
- Static NASA text readable with vertical packing: two MSB-first bytes per column, 96 bytes per frame.

The original horizontal packing produced gibberish and is retained only as a debugging alternative. Greg visually confirmed the final animation, stationary name, scrolling phrase, rocket, and matching 4×7 labels, and approved this version as the keeper. Exact timing has not been measured; power-cycle persistence still needs confirmation. No original iOS app trace was captured. The implementation is an experimental interoperability tool, not a complete protocol specification.

## Prompts for Max and other LLMs

Copy a prompt into your assistant and provide this repository:

- [Continue the project](prompts/CONTINUE.md)
- [Create a new animation](prompts/ANIMATION.md)
- [Diagnose a display problem](prompts/DEBUG.md)

[AGENTS.md](AGENTS.md) also gives repository-aware assistants the hardware constraints and working conventions. Any assistant can generate frames; live upload needs Bluetooth tools running on your Mac.

## Code layout

- `ble-scan.swift`: CoreBluetooth discovery, writes, notifications, upload state machine, and JSONL logging.
- `BadgeProtocol.swift`: wire framing, checksums, program packaging, and monochrome pixel encoding.
- `render.py`: local artwork/text/frame generation; no BLE dependencies.
- `docs/PROTOCOL.md`: device findings, packet examples, and remaining questions.
- `evidence/`: sanitized operation events; advertisements and peripheral identifiers are omitted.

Uploads replace the currently displayed content. The tool does not send delete-all. It targets the exact badge name, case-insensitively; general device selection is future work.

## Next work

Measure animation timing, test power-cycle persistence, handle cached programs, support per-frame timing and imported images, add device selection, and improve fonts/artwork.

## Protocol reference

Initial wire-format candidate: [set4npl/ledsign](https://github.com/set4npl/ledsign/blob/main/PROTOCOL.md). Its author tested other panel sizes. Local traces and visual checks established this badge's monochrome column packing. This project is not affiliated with the badge vendor or NASA.

## Keeper version

Approved October 11, 2026. `Hi! I'm` holds for a requested 2 seconds, then the taller mixed-case `Greg` holds still for 3 seconds. `Your Tour Guide` and the rocket advance two pixels per 100 ms frame. The loop has 191 frames, nominally 19.1 seconds. Actual dwell has not been timed. Monochrome animation frames are exactly 96 bytes with no RGB frame suffix.

The public repository is a clean snapshot of the approved local keeper. Original local history and full badge traces remain with the owner.

## About Greg

Greg Gorman is an electrical engineer with a BSEE from the University of
Missouri. His projects bring together electrical systems, HVAC, radio,
smart-home telemetry, hardware, and software. Greg brings the real-world
context, engineering judgment, hands-on testing, and final call on what works.

This project started with a small LED badge for Greg's NASA tour-guide
costume. Greg tested every revision on the actual badge, caught the pixel
packing and animation problems, and refined the lettering and timing until
it became the keeper: a tiny introduction, a name, a tour-guide invitation,
a passing rocket, and an USS GORMAN Easter egg.

## About Max

Max is Greg's AI engineering collaborator, powered by OpenAI Codex. The name
came out of a debugging session involving Greg's Jandy pool cleaner. Greg had
been calling the assistant “Chat” and asked what name it would choose for
itself.

The first suggestion was **Vector**, for magnitude and direction. Greg
immediately answered with the line from *Airplane!*: “What's the vector,
Victor?” After an engineer's roll call—Maxwell, Ohm, Kirchhoff, Faraday,
Tesla, Nyquist, and others—the choice became **Max**, short for Maxwell,
after James Clerk Maxwell. Greg said, “I like Max,” and the name stuck.

Greg and Max have since worked together on HVAC, electrical, smart-home,
radio, hardware, and software projects. Greg supplies the goals, field
experience, physical testing, and final judgment; Max helps investigate,
design, code, document, and debug. Here, that collaboration turned a
scrolling-text badge into a locally rendered animation tool—and left reusable
prompts so Max or another LLM can pick up the next idea.

## License

The original code and accompanying documentation are released under the
[MIT License](LICENSE). Copyright © 2026 Greg Gorman.

Project credits do not imply endorsement by OpenAI, NASA, or the badge vendor.
