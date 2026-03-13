---
name: font-type-studio
description: Build a conversational font workbench from a real online font family, keep a live HTML specimen updated as the session evolves, and export desktop/web-ready font packages with naming suggestions.
license: Complete terms in references/workflow.md
---

This skill turns a real font family into a collaborative font workbench.

In plain terms: it starts from a real online font, opens a live specimen page, lets the session adjust that font in controlled ways, and exports installable files when the user is happy.

Use it when the user wants to:

- start from an existing real font family name
- find and download the source online
- preview the typeface in a single live HTML specimen
- iteratively refine the look in conversation
- export desktop and web install files plus a specimen page
- brainstorm a final font family name based on the session

The helper script lives at `scripts/font_workbench.py`.

## What This Skill Does Well

- Searches Google Fonts metadata by the real family name the user gives you
- Downloads the source font files plus license text from the Google Fonts repository when possible
- Builds a workspace with a persistent `session.json` and a single `preview/index.html`
- Keeps that HTML updated as the user asks for changes
- Can serve the preview locally with auto-refresh while the conversation continues
- Supports conversational refinement through variable font axes, specimen text, descriptors, notes, metric edits, glyph outline edits, and export naming
- Exports a package with:
  - a single specimen HTML
  - desktop font files
  - website font files and CSS
  - a manifest with provenance, license, and session notes

## What It Actually Edits

This skill can edit a font in three practical layers:

- `Variable axes`: weight, width, slant, optical size, and any other axes exposed by the chosen family
- `Font-wide metrics`: width/height scaling, tracking, baseline shift, ascender shift, and descender shift
- `Glyph-specific transforms`: per-glyph scaling and shifting, plus spacing adjustments for specific glyphs like `A`, `S`, or `y`

These are real edits to the generated preview/export binaries, not just CSS tricks.

## What It Does Not Do Yet

- It does not do freehand point-by-point bezier editing
- It does not redraw arbitrary corners or terminals with full type-design precision
- It does not preserve edited output as a fully variable font once metric or glyph edits are baked in
- It does not turn an existing family into a completely original typeface from scratch

## Important Constraints

- This workflow is strongest with variable fonts because conversational edits map cleanly onto axes like `wght`, `wdth`, `slnt`, `opsz`, `CASL`, `MONO`, and similar.
- The bundled local virtualenv is used for `fontTools`-powered metric and outline edits.
- Metric edits and glyph outline edits currently export static binaries based on the current axis settings; they do not preserve a fully variable edited font.
- Glyph outline editing currently means affine edits to real outlines and spacing for specific glyphs. In user terms: the skill can squash, stretch, shift, and rebalance glyphs, but it cannot yet grab individual nodes and redraw curves manually.
- Always preserve and surface source licensing details before export.

## Conversation Style

- Be collaborative and iterative.
- Keep one live workspace throughout the session.
- After each meaningful edit request, update the session and regenerate `preview/index.html`.
- Prefer running the preview server so the browser auto-refreshes when the session changes.
- When you need a decision, ask one focused question only after doing everything else you can.

## Default Workflow

1. If the user did not provide a font name, ask for the real font family name.
2. Search for the family:

   ```bash
   python3 "$CLAUDE_SKILL_DIR/scripts/font_workbench.py" search --query "<font name>"
   ```

3. Pick the exact match when available. If there are multiple close matches, present the top few and recommend one.
4. Initialize a workspace and start the preview server immediately:

   ```bash
   python3 "$CLAUDE_SKILL_DIR/scripts/font_workbench.py" init --query "<font name>" --workspace "./font-type-studio/<slug>" --serve --open
   ```

5. Give the user the preview URL returned by `init`.

   If the workspace already exists or the user wants to restart the server manually:

   ```bash
   python3 "$CLAUDE_SKILL_DIR/scripts/font_workbench.py" serve --workspace "./font-type-studio/<slug>" --open
   ```

   If the user does not want a server, fall back to the file preview:
   - `font-type-studio/<slug>/preview/index.html`
   To stop a background preview server:

   ```bash
   python3 "$CLAUDE_SKILL_DIR/scripts/font_workbench.py" stop --workspace "./font-type-studio/<slug>"
   ```

6. For each edit request, translate the request into the closest supported changes:
    - axis changes via `--axis TAG=value`
    - font-wide metric changes via `--metric name=value`
    - glyph-specific outline edits via `--glyph-edit "A:scale_x=1.04,scale_y=0.96,shift_y=10"`
    - specimen text via `--sample-text`
    - mood descriptors via `--descriptor`
    - session notes via `--note`
   - preferred export family via `--export-family`

   Example:

    ```bash
    python3 "$CLAUDE_SKILL_DIR/scripts/font_workbench.py" update --workspace "./font-type-studio/<slug>" --axis wght=650 --metric width_scale=1.08 --metric height_scale=0.92 --glyph-edit "A:scale_y=0.95,shift_y=10" --descriptor sharper --note "Asked for a denser editorial feeling"
    ```

7. After updating, tell the user the preview HTML was regenerated; if the preview server is running, remind them the page should refresh automatically.
8. When the user is ready to export, first generate naming ideas:

   ```bash
   python3 "$CLAUDE_SKILL_DIR/scripts/font_workbench.py" suggest --workspace "./font-type-studio/<slug>"
   ```

9. Ask the user for the final export family name and include 3-5 suggested names from the session.
10. Export the package:

   ```bash
   python3 "$CLAUDE_SKILL_DIR/scripts/font_workbench.py" export --workspace "./font-type-studio/<slug>" --export-family "<final name>"
   ```

11. Return the exported paths:
   - `font-type-studio/<slug>/export/specimen.html`
   - `font-type-studio/<slug>/export/web/stylesheet.css`
   - `font-type-studio/<slug>/export/desktop/`
   - `font-type-studio/<slug>/export/manifest.json`

## Interpreting User Feedback

Translate natural language requests into axes or session updates wherever possible.

- "make it heavier" -> raise `wght`
- "narrow it" -> lower `wdth`
- "more italic" or "more slanted" -> adjust `ital` or `slnt`
- "friendlier" or "more playful" -> raise axes like `CASL`, `SOFT`, `ROND`, `WONK` when available
- "more technical" or "more mono" -> raise `MONO`
- "better for tiny UI text" -> lower `opsz` or document the desired text-size use case
- "more dramatic contrast" -> raise `CTRS`, `GRAD`, `XOPQ`, `YOPQ`, or similar if available
- "make it bigger and shorter" -> raise `width_scale` and lower `height_scale`
- "align the letters better" -> tune `baseline_shift`, `ascender_shift`, `descender_shift`, `tracking`, and glyph-specific `shift_y`
- "edit the A/S/y edges" -> use targeted `--glyph-edit` transforms for those glyphs, explain that this currently means geometric reshaping rather than point-level redrawing, and record the exact intent in notes

If the family lacks the axis the user wants, say so plainly and offer the closest available alternative.

When a user asks for something like "round this corner" or "soften that edge", be honest about the implementation level:

- If a transform-based glyph edit can get close, do it
- If the request needs true node editing, say that the current skill does not yet support that exact depth of editing

## Good User Prompts

These are the kinds of prompts this skill should handle naturally in conversation:

- "Start a Syne session and open the live preview."
- "Can you make some changes on Syne and show me all characters and sizes first?"
- "Make Syne a bit wider and shorter."
- "Improve the vertical alignment so the letters feel more even with each other."
- "Make the A slightly shorter and move it up a touch."
- "Push the S a little to the right and make it feel less cramped."
- "Try to soften the edges a bit if possible."
- "Export this version and suggest a few names based on what we changed."

## Syne Example

If the user says something like:

`Can you make some changes on the Syne font? I want it bigger and shorter, better aligned, and I want to inspect it live.`

Then the skill should generally do this:

1. Start the Syne workspace with the preview server.
2. Show the preview URL.
3. Explain that `Syne` exposes a `wght` axis directly, while width/height/alignment changes will be done through metric edits.
4. Apply a reasonable first pass, for example:
   - slightly increase `width_scale`
   - slightly decrease `height_scale`
   - adjust `baseline_shift` or spacing if alignment seems off
5. Tell the user the page should refresh automatically.
6. Keep iterating from their feedback.

## Export Rules

- Always preserve the original source family, source URL, and license in the manifest.
- Do not imply the font was newly drawn from scratch when it is a remixed or configured source family.
- For web output, the exported CSS may alias the font under the chosen export name even if the desktop binary keeps the original internal naming.
- If `fontTools` is available, the script can rename internal font metadata during export. If not, mention the limitation clearly.

For extra detail on capabilities, session fields, and optional dependencies, see `references/workflow.md`.
