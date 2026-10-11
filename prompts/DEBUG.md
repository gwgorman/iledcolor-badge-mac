# Diagnose a display problem — any LLM

```text
Help diagnose this iLEDCOLOR badge behavior: [OBSERVED PROBLEM]

Read this repository's AGENTS.md, docs/PROTOCOL.md, codec, transport, and
relevant evidence. Do not assume RGB packing or that ACK means correct pixels.

Known facts: readable static text uses column16 packing, 96 bytes/frame;
monochrome animation works without a two-byte frame suffix. Row-major data
produced gibberish; adding the RGB suffix caused one-column drift.

First inspect the existing asset, header, frame count, byte lengths, frame
boundaries, and rendering. Then test the smallest useful hypothesis while
keeping the approved keeper asset intact. Separate static pixel mapping
from animation timing. Obtain visual feedback only where hardware evidence
is needed. Do not require an iPhone logging profile for routine experiments.

Record the attempted change, packet response, actual observed appearance,
and remaining uncertainty. Give a concrete fix and validation evidence.
```
