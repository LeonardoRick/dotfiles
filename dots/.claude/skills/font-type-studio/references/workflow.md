# Font Type Studio Workflow

This skill builds a reusable local workspace for a font session.

The goal is simple: start from a real font, keep a live preview open while the conversation evolves, and export the current result as installable font files plus a specimen page.

## Workspace Layout

```text
font-type-studio/<slug>/
  source/
    <downloaded font files>
    <license text>
  generated/
    <edited preview/export binaries when metric or glyph edits are active>
  preview/
    index.html
  export/
    desktop/
    web/
      fonts/
      stylesheet.css
    specimen.html
    manifest.json
  session.json
```

## Preview Server

Preferred startup:

```bash
python3 scripts/font_workbench.py init --query "Syne" --workspace ./font-type-studio/syne --serve --open
```

Manual restart:

```bash
python3 scripts/font_workbench.py serve --workspace ./font-type-studio/<slug> --open
```

This serves the workspace locally, defaults to `http://127.0.0.1:4173/preview/index.html`, and uses server-sent events to reload the page whenever files in the workspace change.

What the preview is for:

- inspect the current font state across multiple sizes
- inspect uppercase, lowercase, numbers, and punctuation together
- compare the current session text in a specimen layout
- see metric and glyph-edit settings reflected in the generated preview font

To stop a background server:

```bash
python3 scripts/font_workbench.py stop --workspace ./font-type-studio/<slug>
```

## Session Data

`session.json` stores:

- source family and metadata
- download provenance
- available axes and current values
- font-wide metric edits such as width scale, height scale, tracking, and baseline shift
- glyph-specific outline edits such as per-glyph scaling and shifting
- sample text
- descriptors gathered during the conversation
- freeform notes about requested edits
- export family draft
- generated naming suggestions

This file is the source of truth for the session.

- conversational changes update it
- the preview is regenerated from it
- export uses it to build the current font package

## Supported Conversational Edits

Best supported:

- variable axis adjustments
- metric edits for width, height, spacing, and baseline alignment
- glyph-specific outline transforms on real exported binaries
- specimen text changes
- tone descriptors
- naming direction
- export packaging

Examples:

- "make it wider and shorter" -> `width_scale` and `height_scale`
- "raise the baseline a bit" -> `baseline_shift`
- "make the A slightly shorter" -> glyph edit on `A` with `scale_y`
- "push the S a little right" -> glyph edit on `S` with `shift_x`

## Natural Example Session

Example user request:

`Can you make some changes on the Syne font? Open a server, show me all the characters and sizes, then make it wider, shorter, and better aligned.`

Typical response flow:

1. Initialize the workspace with live preview enabled.
2. Tell the user the preview URL.
3. Mention what they are looking at in the page:
   - glyph atlas
   - size ramp
   - sample text
   - current metric and glyph edits
4. Apply a sensible first pass such as:
   - `width_scale=1.05`
   - `height_scale=0.92`
   - a small `baseline_shift` or `tracking` change if needed
5. Ask the user to describe what still feels off.
6. If they call out specific letters like `A`, `S`, `y`, `g`, or `R`, use glyph edits for those next.

Example follow-up prompts that map well to the current implementation:

- "Make the capitals sit together more evenly."
- "The lowercase feels too tall, shorten it a little more."
- "The S still feels too wide on the left side."
- "Move the A up a touch and tighten its spacing."
- "This is close - export this version and suggest names."

Partially supported:

- static family selection by available files
- CSS aliasing for web installs
- internal family renaming when `fontTools` is installed
- approximating edge/corner changes through affine glyph transforms

Not supported in the current implementation:

- point-by-point bezier editing of glyph outlines
- selective redrawing of a corner, spur, serif, or terminal with node-level control
- generating entirely original font binaries from scratch
- converting to optimized WOFF2 locally without dependencies

## Bundled Dependencies

This skill includes a local virtualenv at `.venv/` for `fontTools`-powered editing.

If you need to refresh it manually:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install fonttools brotli
```

That powers internal font-family renaming, axis instancing, metric edits, and glyph outline transforms.

## Important Export Behavior

If the session only changes variable axes, the result can still behave like a variable-font workflow.

If the session applies metric edits or glyph-specific outline edits, the skill generates edited binaries in `generated/` and exports those as the current result. In practice, that means the exported result is treated as a static edited font snapshot of the session.

## License Notes

The current implementation targets Google Fonts families because they have consistent metadata, downloadable sources, and clear licensing. The exported manifest always records the upstream family, repo path, and license file.
