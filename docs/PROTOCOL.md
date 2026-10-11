# Verified badge findings

Observed October 11, 2026 on `iledcolor-012B`, physical 48×12 monochrome matrix, with red/blue/green/white cover. Apparent colors come from the cover, not RGB pixels.

## GATT

All UUIDs below expand as `0000XXXX-0000-1000-8000-00805F9B34FB`.

| Primary service | Characteristic | Properties |
|---|---|---|
| A950 | A951 | write without response |
| A950 | A952 | write without response |
| A950 | A953 | notify |
| AE00 | AE01 | write without response |
| AE00 | AE02 | notify |

No reads, write-with-response, or indications were advertised. AE00 is unexplored. Advertisement service AF30 differs from connected services. Initial maximum write length was 20 bytes without response; it increased after connection negotiation. The uploader recalculates the limit after subscribing and uses at most 492 program-data bytes per fragment. A reported write-with-response maximum does not grant that property to a characteristic.

Advertisement decoding reports width 48, height 12, monochrome color type 1, firmware 9. Raw manufacturer data is retained only in the local evidence.

## Wire framing

`54 | command:u8 | length:u16be | payload | checksum:u16be`

Length is payload length plus two checksum bytes. Checksum is the low 16 bits of the sum of all preceding bytes. Fragment acknowledgements are an exception: length 5, but 11 bytes overall, carrying fragment ID `u32be` and status byte.

A951 carries control commands, A952 bulk fragments/completion, A953 replies. Subscribe before writing. Upload uses command 06 announce (`programId:u32be`, `length:u32be`, three reserved zeros), command 00 numbered fragments (`wrapId:u32be`, `chunkLength:u16be`, data), then command 01 with payload 01. Each stage is acknowledgement-driven. Success status is 01; cached status 03 is logged and currently exits rather than retrying. Upload timeout is 180 seconds overall.

Brightness 30 percent: TX `540900031e007e`, RX `54090003010061`, visually confirmed. Other brightness values were not tested. Animation-count query `540d0003000064` was echoed and supplies no usable count.

## Program packages and pixels

24-byte outer header: CRC32C program ID, partition count, three reserved zeros, four big-endian u32 partition offsets relative to byte 24. CRC32C uses reflected Castagnoli polynomial 0x82F63B78 over the partition content.

22-byte partition header: x/y/width/height (u16be each), three reserved zeros, type byte, frame count (u16be), effect/velocity/residence/border/luminance bytes, three reserved zeros. Current uploads use one full-screen partition, effect 0, velocity 0, luminance 30. Type 1 displays one bitmap; type 2 handles the verified animation.

Spatial packing is **column16**: columns left-to-right; two bytes per column; rows 0–7 in first byte, rows 8–11 in high four bits of second byte, low four bits zero. Bits are MSB-first. Each frame is exactly 96 bytes. Static NASA was visually confirmed readable.

**No two-byte frame suffix for monochrome animation.** The initial RGB-reference suffix produced column drift: Greg scrolled and the phrase appeared column-by-column. Removing it produced the visually approved animation. Row-major packing also produced gibberish. These traces are retained as failed experiments.

Residence requests frameMs/20 ticks. The renderer currently requests 100 ms/frame. Exact timing is unmeasured; animation and looping were visually approved. Playback continues after the Mac disconnects. Power-cycle persistence has not been tested.

## Keeper artwork

NASA graphic → Hi! I'm → Greg → Your Tour Guide → animated rocket → USS GORMAN → loop. 191 frames; requested duration 19.1 seconds. Greg is stationary and tall mixed case; the introduction is a separate page. Phrase and rocket move two pixels/frame. NASA and USS GORMAN use uniform 4×7 letters, including an N with a two-pixel center diagonal. Greg approved this version as the keeper.

## Provenance and remaining work

Initial candidate wire framing and package layout: [set4npl/ledsign](https://github.com/set4npl/ledsign/blob/main/PROTOCOL.md), tested by its author on other models. Badge-specific packing and monochrome frame boundaries were established through local trials and visual feedback. No iOS app trace was captured. This does not establish that every app operation uses the same format.

`evidence/` preserves sanitized operation traces; unrelated nearby advertisements were removed. Further work: measure timing, test persistent playlists/power cycling, handle cached-program reuse, broaden image/font/device support, and validate additional firmware.
