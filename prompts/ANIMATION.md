# Make an animation — any LLM

```text
Use this repository to create the following 48×12 monochrome badge animation:
[DESCRIBE THE SCENES, WORDING, TIMING, AND MOTION]

Read AGENTS.md and docs/PROTOCOL.md. Generate an independent JSON asset,
preserving nasa-demo.json unless I request its replacement. Use this schema:
{"width":48,"height":12,"frameMs":100,"packing":"column16",
 "frames":[["48 binary digits per row, twelve rows per frame"]]}

Every real row must contain exactly 48 characters, each 0 or 1. Every frame
must have twelve rows. frameMs must be a multiple of 20 between 20 and 5100.
frameMs applies to the entire sequence: create repeated frames for holds,
and choose movement step sizes for different scrolling speeds. There is
no independent per-frame timing field yet.

Keep letters within the physical grid. Preserve mixed case if requested;
the generic --text renderer uppercases text, so extend the mixed-case glyph
renderer if necessary. Favor native pixel artwork over shrinking photographs.
Treat cover colors as position-dependent, not programmable RGB colors.

Validate dimensions, fit, and sequence content. Give a preview if your tools
support it and the exact upload command:
zsh build.sh
./badge-tool --upload YOUR-ASSET.json

Only upload if I request it and hardware tools are available. Do not erase
all programs or change unrelated badge settings. Ask me to confirm actual
display appearance after a hardware test.
```
