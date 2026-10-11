# Continue this project — any LLM

Copy the prompt below into an assistant with this repository attached or accessible. A link alone may require the assistant to browse or ask for the files. This works with Max/Codex and other coding assistants; direct BLE access requires tools running on the owner's Mac.

```text
You are helping me continue the iLEDCOLOR badge project in this repository.
Read AGENTS.md, README.md, docs/PROTOCOL.md, render.py, BadgeProtocol.swift,
and ble-scan.swift first. Report what is verified and what remains untested.

The physical target is iledcolor-012B: 48×12 monochrome, with a colored
red/blue/green/white cover. It is not independently RGB. Rendering stays
separate from BLE transport and protocol encoding.

The approved keeper is:
NASA graphic → Hi! I'm → Greg → Your Tour Guide → animated rocket →
USS GORMAN → loop.
Greg is tall mixed case, centered and stationary. Hi! I'm is a separate
page. Your Tour Guide and rocket move two pixels per frame. NASA and
USS GORMAN use matching 4×7 capitals, with a two-pixel diagonal center in N.
There are 191 frames requesting 100 ms each; exact dwell is not measured.

IMPORTANT: pack each frame as 96 bytes, two vertical MSB-first bytes per
column, left to right. Do not append the two-byte RGB frame suffix.
That caused Greg to drift and the phrase to render column-by-column.

My next request is: [INSERT REQUEST]

Implement the request, preserve existing keeper assets unless I ask to
change them, validate the result, and give me the files and exact commands.
If I request an upload and you have local Mac Bluetooth access, upload it
and record the response. If you cannot access hardware, say so and provide
the upload command. Never claim physical success from an ACK alone.
Keep explanations short and move forward with routine reversible work.
```
