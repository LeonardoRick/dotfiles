#!/usr/bin/env python3
"""
Remove white/light background from a signature image, producing a transparent PNG.

Usage:
    python remove_background.py <input_image> [--output path] [--threshold 240]

Converts white/near-white pixels to transparent, keeping the dark signature ink.
Also auto-crops to the signature bounds with a small padding.
"""

import argparse
import os
import sys
from pathlib import Path

from PIL import Image


def remove_background(
    input_path: str,
    output_path: str | None = None,
    threshold: int = 240,
    padding: int = 10,
) -> str:
    """Remove white background from a signature image.

    Args:
        input_path: Path to the source image
        output_path: Optional output path. Defaults to <original>_transparent.png
        threshold: Brightness threshold (0-255). Pixels brighter than this become transparent.
        padding: Pixels of padding to add around the cropped signature.

    Returns:
        The path to the output image
    """
    input_path = os.path.expanduser(input_path)

    if not os.path.exists(input_path):
        print(f"Error: Image not found: {input_path}", file=sys.stderr)
        sys.exit(1)

    if output_path is None:
        base = Path(input_path)
        output_path = str(base.parent / f"{base.stem}_transparent.png")

    img = Image.open(input_path).convert("RGBA")
    pixels = img.load()
    width, height = img.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # If pixel is white/near-white, make it transparent
            if r > threshold and g > threshold and b > threshold:
                pixels[x, y] = (255, 255, 255, 0)

    # Auto-crop to the signature bounds
    bbox = img.getbbox()
    if bbox:
        # Add padding
        left = max(0, bbox[0] - padding)
        top = max(0, bbox[1] - padding)
        right = min(img.width, bbox[2] + padding)
        bottom = min(img.height, bbox[3] + padding)
        img = img.crop((left, top, right, bottom))

    img.save(output_path, "PNG")
    print(f"Transparent signature saved to: {output_path}")
    return output_path


def main():
    parser = argparse.ArgumentParser(description="Remove white background from a signature image")
    parser.add_argument("input_path", help="Path to the source image")
    parser.add_argument("--output", help="Output file path (default: <original>_transparent.png)")
    parser.add_argument(
        "--threshold",
        type=int,
        default=240,
        help="Brightness threshold 0-255. Pixels above this become transparent (default: 240)",
    )
    parser.add_argument(
        "--padding",
        type=int,
        default=10,
        help="Padding in pixels around the cropped signature (default: 10)",
    )
    args = parser.parse_args()

    remove_background(args.input_path, args.output, args.threshold, args.padding)


if __name__ == "__main__":
    main()
