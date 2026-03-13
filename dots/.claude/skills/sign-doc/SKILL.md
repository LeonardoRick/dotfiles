---
name: sign-doc
description: Sign .docx and .pdf documents by placing a signature image at the signature line. Use when the user asks to sign, add signature to, or stamp a document. Supports Word (.docx) and PDF (.pdf) files.
---

Sign documents by inserting a signature image into `.docx` or `.pdf` files.

## Structure

```
sign-doc/
  SKILL.md                # This file
  .venv/                  # Python venv with python-docx, pymupdf, Pillow
  scripts/
    sign_docx.py          # Sign .docx files
    sign_pdf.py           # Sign .pdf files
    remove_background.py  # Remove white background from signature screenshots
```

## Prerequisites

This skill bundles a `.venv/` with all required Python packages (`python-docx`, `pymupdf`, `Pillow`).

If the `.venv/` is missing or broken, recreate it:
```bash
python3 -m venv ~/.claude/skills/sign-doc/.venv
~/.claude/skills/sign-doc/.venv/bin/pip install python-docx pymupdf Pillow
```

## Signature Images

Signature images are stored in:
```
~/Library/CloudStorage/OneDrive-Personal/MeusDocumentos/Signatures/
```

- The default signature file is `signature.png`
- It should be a `.png` with transparent background
- If multiple signatures exist, list them and ask the user which one to use

### Creating a signature (if none exists)

If the user doesn't have a signature image, guide them through this process:

1. **On Mac**: Open any PDF in Preview > Markup toolbar (pen icon) > click **Signatures** dropdown > **Create Signature** > draw with trackpad or camera
2. **On iPhone/iPad**: Open any PDF in Files > Markup > tap **+** > **Signature** > draw with finger
3. **Take a screenshot** of the signature (Cmd+Shift+4 on Mac, or screenshot on iPhone)
4. **Send/save the screenshot** — the agent will process it

Once the user provides the screenshot:
1. Run the background removal script to make it transparent:
   ```bash
   ~/.claude/skills/sign-doc/.venv/bin/python3 ~/.claude/skills/sign-doc/scripts/remove_background.py \
     "<screenshot_path>" \
     --output ~/Library/CloudStorage/OneDrive-Personal/MeusDocumentos/Signatures/signature.png
   ```
2. Confirm the result looks good (offer to open it)
3. The signature is now ready for use

## Removing background from a signature image

If the user provides a signature screenshot with a white background, process it first:
```bash
~/.claude/skills/sign-doc/.venv/bin/python3 ~/.claude/skills/sign-doc/scripts/remove_background.py \
  "<input_image>" \
  --output "<output_path>" \
  --threshold 240 \
  --padding 10
```

- `--threshold` controls how aggressive the background removal is (0-255, default 240)
- `--padding` adds pixels of space around the cropped signature (default 10)

## Signing a .docx file

Run the bundled script:
```bash
~/.claude/skills/sign-doc/.venv/bin/python3 ~/.claude/skills/sign-doc/scripts/sign_docx.py \
  "<docx_path>" \
  "<signature_image_path>" \
  --width 5.0 \
  --output "<optional_output_path>"
```

The script:
- Searches for signature markers ("Atenciosamente", "Assinatura", "____", "Signature", etc.)
- Places the signature image after the marker
- Replaces placeholder underline lines (`____`) with the signature
- Falls back to appending at the end if no marker is found
- NEVER overwrites the original — saves as `<name>_signed.docx`

## Signing a .pdf file

Run the bundled script:
```bash
~/.claude/skills/sign-doc/.venv/bin/python3 ~/.claude/skills/sign-doc/scripts/sign_pdf.py \
  "<pdf_path>" \
  "<signature_image_path>" \
  --width 150 \
  --height 60 \
  --output "<optional_output_path>"
```

The script:
- Searches ALL pages for signature markers (not just the last page)
- Places the signature image below the marker
- Ensures the image stays within page bounds
- Falls back to bottom-left of the last page if no marker is found
- NEVER overwrites the original — saves as `<name>_signed.pdf`

## Workflow

1. Resolve the file path (expand `~`, handle relative paths)
2. Check the file extension (`.docx` or `.pdf`)
3. Find the signature image in the Signatures folder
4. If no signature image exists:
   - Guide the user through creating one (see "Creating a signature" above)
   - If the user provides a screenshot, run `remove_background.py` first
   - Save the processed signature to the Signatures folder
5. Run the appropriate script (`sign_docx.py` or `sign_pdf.py`)
6. Report the output file path
7. Offer to open the signed document

## Important Notes

- Always create a `_signed` copy, never modify the original
- If the signature image doesn't exist, stop and guide the user through creating one — don't proceed without it
- For PDFs, the visual signature is an image overlay, NOT a cryptographic/digital signature
- For legal validity in Portugal, recommend the user also sign via Chave Movel Digital for important documents
- The user may provide the file path as an argument or reference it in conversation
