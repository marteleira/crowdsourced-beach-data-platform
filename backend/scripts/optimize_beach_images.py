"""
Optimize beach cover photos in static/beaches/:
  - Resize to max 1080px wide (keep aspect ratio)
  - Re-encode as JPEG quality 78 (progressive)
  - Normalize extension to .jpg (lowercase)
  - Overwrite in place
"""
import os
import sys
from pathlib import Path

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from PIL import Image

MAX_WIDTH = 1080
QUALITY   = 78
IMAGES_DIR = Path(__file__).parent.parent / "static" / "beaches"


def optimize(path: Path) -> None:
    with Image.open(path) as img:
        original_size = path.stat().st_size
        w, h = img.size

        # Convert to RGB (handles RGBA/P mode JPEGs)
        if img.mode != "RGB":
            img = img.convert("RGB")

        if w > MAX_WIDTH:
            new_h = round(h * MAX_WIDTH / w)
            img = img.resize((MAX_WIDTH, new_h), Image.LANCZOS)
            new_dims = f"{MAX_WIDTH}x{new_h}"
        else:
            new_dims = f"{w}x{h} (unchanged)"

        # Normalize to lowercase .jpg
        out_path = path.with_suffix(".jpg")

        img.save(out_path, "JPEG", quality=QUALITY, optimize=True, progressive=True)

    # Remove original if extension was uppercased
    if path != out_path:
        path.unlink()

    new_size = out_path.stat().st_size
    saved_pct = (1 - new_size / original_size) * 100
    print(f"  {out_path.name}: {original_size // 1024}KB → {new_size // 1024}KB  ({saved_pct:+.0f}%)  {new_dims}")


def main() -> None:
    exts = {".jpg", ".jpeg", ".JPG", ".JPEG", ".png", ".PNG", ".webp"}
    images = sorted(p for p in IMAGES_DIR.iterdir() if p.suffix in exts)

    if not images:
        print("No images found in", IMAGES_DIR)
        return

    print(f"Optimizing {len(images)} image(s) in {IMAGES_DIR}\n")
    for img_path in images:
        optimize(img_path)
    print("\nDone.")


if __name__ == "__main__":
    main()
