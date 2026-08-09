#!/usr/bin/env python3
"""Generate LandMile App Store screenshots from raw simulator screenshots.

This keeps the screenshot design reproducible: edit CAPTIONS or layout constants,
then run this script from the repo root:

    python3 scripts/generate_app_store_screenshots.py
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS_DIR = ROOT / "screenshots"
OUTPUT_DIR = SCREENSHOTS_DIR / "final"

CANVAS_SIZE = (1284, 2778)
BACKGROUND = (13, 92, 99)
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)

FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Arial Black.ttf",
    "/System/Library/Fonts/Supplemental/Impact.ttf",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
]

TITLE_SIZE = 180
SUBTITLE_SIZE = 84
TITLE_Y = 124
SUBTITLE_Y = 322
LINE_SPACING = 26

PHONE_WIDTH = 930
PHONE_Y = 585
FRAME_PADDING = 22
FRAME_RADIUS = 72
SCREEN_RADIUS = 54
BOTTOM_CROP_OVERFLOW = 40

CAPTIONS = [
    {
        "source": "Simulator Screenshot - iPhone 17 Pro - 2026-06-02 at 09.29.57.png",
        "output": "01-turn-miles.png",
        "title": "TRACK",
        "subtitle": ["EVERY MILE", "AUTOMATICALLY"],
    },
    {
        "source": "Simulator Screenshot - iPhone 17 Pro - 2026-06-02 at 09.29.54.png",
        "output": "02-track-automatically.png",
        "title": "SAVE",
        "subtitle": ["THOUSANDS IN", "TAX DEDUCTIONS"],
    },
    {
        "source": "Simulator Screenshot - iPhone 17 Pro - 2026-06-02 at 09.30.33.png",
        "output": "03-export-irs-reports.png",
        "title": "EXPORT",
        "subtitle": ["IRS-READY", "MILEAGE REPORTS"],
    },
    {
        "source": "Simulator Screenshot - iPhone 17 Pro - 2026-06-02 at 10.57.59.png",
        "output": "04-tag-trips.png",
        "title": "TAG",
        "subtitle": ["TRIPS TO", "PROPERTIES"],
    },
]


def font(size: int) -> ImageFont.FreeTypeFont:
    for candidate in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    return ImageFont.load_default()


def draw_centered_text(draw: ImageDraw.ImageDraw, text: str, y: int, size: int) -> None:
    text_font = font(size)
    bbox = draw.textbbox((0, 0), text, font=text_font)
    width = bbox[2] - bbox[0]
    x = (CANVAS_SIZE[0] - width) // 2
    draw.text((x, y), text, fill=WHITE, font=text_font)


def draw_centered_lines(draw: ImageDraw.ImageDraw, lines: Iterable[str], y: int, size: int) -> None:
    text_font = font(size)
    current_y = y
    for line in lines:
        bbox = draw.textbbox((0, 0), line, font=text_font)
        width = bbox[2] - bbox[0]
        height = bbox[3] - bbox[1]
        x = (CANVAS_SIZE[0] - width) // 2
        draw.text((x, current_y), line, fill=WHITE, font=text_font)
        current_y += height + LINE_SPACING


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def make_phone(raw: Image.Image) -> Image.Image:
    raw = raw.convert("RGB")
    scale = PHONE_WIDTH / raw.width
    screen_size = (PHONE_WIDTH, round(raw.height * scale))
    screen = raw.resize(screen_size, Image.Resampling.LANCZOS)

    frame_size = (screen.width + FRAME_PADDING * 2, screen.height + FRAME_PADDING * 2)
    frame = Image.new("RGBA", frame_size, (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame)
    frame_draw.rounded_rectangle(
        (0, 0, frame_size[0] - 1, frame_size[1] - 1),
        radius=FRAME_RADIUS,
        fill=BLACK,
    )

    screen_rgba = screen.convert("RGBA")
    screen_rgba.putalpha(rounded_mask(screen.size, SCREEN_RADIUS))
    frame.alpha_composite(screen_rgba, (FRAME_PADDING, FRAME_PADDING))
    return frame


def create_screenshot(item: dict[str, object]) -> Image.Image:
    canvas = Image.new("RGB", CANVAS_SIZE, BACKGROUND)
    draw = ImageDraw.Draw(canvas)

    title = str(item["title"])
    title_size = int(item.get("title_size", TITLE_SIZE))
    draw_centered_text(draw, title, TITLE_Y, title_size)
    draw_centered_lines(draw, item["subtitle"], int(item.get("subtitle_y", SUBTITLE_Y)), SUBTITLE_SIZE)  # type: ignore[arg-type]

    raw_path = SCREENSHOTS_DIR / str(item["source"])
    phone = make_phone(Image.open(raw_path))
    phone_x = (CANVAS_SIZE[0] - phone.width) // 2
    canvas_rgba = canvas.convert("RGBA")
    canvas_rgba.alpha_composite(phone, (phone_x, PHONE_Y))

    # App Store previews can crop at the bottom; keep the original tall phone feel
    # while allowing the phone to run slightly past the visible canvas.
    return canvas_rgba.crop((0, 0, CANVAS_SIZE[0], CANVAS_SIZE[1] - BOTTOM_CROP_OVERFLOW)).resize(CANVAS_SIZE)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for item in CAPTIONS:
        output_path = OUTPUT_DIR / str(item["output"])
        image = create_screenshot(item)
        image.save(output_path)
        print(f"Saved {output_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
