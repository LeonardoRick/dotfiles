#!/usr/bin/env python3
"""
Sign a .pdf file by inserting a signature image at the signature marker.

Usage:
    python sign_pdf.py <pdf_path> <signature_image_path> [--width pts] [--height pts] [--output path]

The script searches for common signature markers on each page and places
the image below the marker. Falls back to the bottom-left of the last page.

NEVER overwrites the original file — creates a _signed copy.
"""

import argparse
import os
import sys
from pathlib import Path

import fitz  # PyMuPDF


SIGNATURE_MARKERS = [
    "Atenciosamente",
    "Assinatura",
    "____",
    "Signature",
    "Signed by",
    "Sincerely",
    "Regards",
    "Com os melhores cumprimentos",
    "Cordialmente",
]


def find_signature_position(doc: fitz.Document) -> tuple[int, fitz.Point] | None:
    """Search all pages for a signature marker and return (page_index, point)."""
    for page_idx in range(len(doc)):
        page = doc[page_idx]
        for marker in SIGNATURE_MARKERS:
            results = page.search_for(marker)
            if results:
                rect = results[0]
                # Place signature below the marker text with some padding
                point = fitz.Point(rect.x0, rect.y1 + 10)
                return page_idx, point
    return None


def sign_pdf(
    pdf_path: str,
    signature_path: str,
    width: float = 150.0,
    height: float = 60.0,
    output_path: str | None = None,
) -> str:
    """Insert signature image into a .pdf file.

    Args:
        pdf_path: Path to the source .pdf file
        signature_path: Path to the signature image (.png recommended)
        width: Width of the signature image in points
        height: Height of the signature image in points
        output_path: Optional output path. Defaults to <original>_signed.pdf

    Returns:
        The path to the signed document
    """
    pdf_path = os.path.expanduser(pdf_path)
    signature_path = os.path.expanduser(signature_path)

    if not os.path.exists(pdf_path):
        print(f"Error: Document not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists(signature_path):
        print(f"Error: Signature image not found: {signature_path}", file=sys.stderr)
        sys.exit(1)

    if output_path is None:
        base = Path(pdf_path)
        output_path = str(base.parent / f"{base.stem}_signed{base.suffix}")

    doc = fitz.open(pdf_path)
    result = find_signature_position(doc)

    if result is not None:
        page_idx, point = result
        page = doc[page_idx]
    else:
        # Fallback: bottom-left of last page
        page = doc[-1]
        point = fitz.Point(72, page.rect.height - 150)

    # Build the signature rectangle
    sig_rect = fitz.Rect(point.x, point.y, point.x + width, point.y + height)

    # Ensure the signature doesn't go off the page
    if sig_rect.y1 > page.rect.height - 20:
        sig_rect.y0 = page.rect.height - height - 20
        sig_rect.y1 = page.rect.height - 20

    if sig_rect.x1 > page.rect.width - 20:
        sig_rect.x0 = page.rect.width - width - 20
        sig_rect.x1 = page.rect.width - 20

    page.insert_image(sig_rect, filename=signature_path)

    doc.save(output_path)
    doc.close()

    print(f"Signed document saved to: {output_path}")
    return output_path


def main():
    parser = argparse.ArgumentParser(description="Sign a .pdf document with an image signature")
    parser.add_argument("pdf_path", help="Path to the .pdf file to sign")
    parser.add_argument("signature_path", help="Path to the signature image (.png)")
    parser.add_argument("--width", type=float, default=150.0, help="Signature width in points (default: 150)")
    parser.add_argument("--height", type=float, default=60.0, help="Signature height in points (default: 60)")
    parser.add_argument("--output", help="Output file path (default: <original>_signed.pdf)")
    args = parser.parse_args()

    sign_pdf(args.pdf_path, args.signature_path, args.width, args.height, args.output)


if __name__ == "__main__":
    main()
