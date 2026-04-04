#!/usr/bin/env python3
"""Generate Whispr app icon - minimal mic with waveform bars."""

from PIL import Image, ImageDraw
import math
import os

SIZE = 1024
PADDING = 120

def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill)

def generate_icon():
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background - dark rounded square
    bg_radius = 220
    draw_rounded_rect(draw, [PADDING//2, PADDING//2, SIZE - PADDING//2, SIZE - PADDING//2],
                      bg_radius, fill=(20, 20, 25, 255))

    # Subtle gradient overlay (lighter at top)
    overlay = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    for y in range(SIZE):
        alpha = int(30 * (1 - y / SIZE))
        overlay_draw.line([(0, y), (SIZE, y)], fill=(255, 255, 255, alpha))
    img = Image.alpha_composite(img, overlay)
    draw = ImageDraw.Draw(img)

    cx, cy = SIZE // 2, SIZE // 2 - 20

    # Waveform bars - 7 bars centered
    bar_color = (100, 140, 255, 255)  # Blue
    bar_width = 36
    bar_gap = 18
    bar_heights = [0.3, 0.55, 0.85, 1.0, 0.85, 0.55, 0.3]
    max_bar_height = 320
    num_bars = len(bar_heights)
    total_width = num_bars * bar_width + (num_bars - 1) * bar_gap
    start_x = cx - total_width // 2

    for i, h in enumerate(bar_heights):
        bx = start_x + i * (bar_width + bar_gap)
        bh = int(h * max_bar_height)
        by_top = cy - bh // 2
        by_bottom = cy + bh // 2
        bar_radius = bar_width // 2
        draw.rounded_rectangle(
            [bx, by_top, bx + bar_width, by_bottom],
            radius=bar_radius,
            fill=bar_color
        )

    # Small mic icon below waveform
    mic_color = (180, 190, 220, 200)
    mic_cx = cx
    mic_top = cy + 200
    mic_w = 32
    mic_h = 50
    mic_radius = mic_w // 2

    # Mic body
    draw.rounded_rectangle(
        [mic_cx - mic_w//2, mic_top, mic_cx + mic_w//2, mic_top + mic_h],
        radius=mic_radius,
        fill=mic_color
    )

    # Mic arc
    arc_w = 56
    arc_top = mic_top - 5
    draw.arc(
        [mic_cx - arc_w//2, arc_top, mic_cx + arc_w//2, mic_top + mic_h + 10],
        start=0, end=180,
        fill=mic_color, width=5
    )

    # Mic stem
    draw.line(
        [(mic_cx, mic_top + mic_h + 10), (mic_cx, mic_top + mic_h + 30)],
        fill=mic_color, width=5
    )

    # Save at multiple sizes
    output_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'Resources', 'AppIcon.appiconset')

    sizes = {
        'icon_16x16.png': 16,
        'icon_16x16@2x.png': 32,
        'icon_32x32.png': 32,
        'icon_32x32@2x.png': 64,
        'icon_128x128.png': 128,
        'icon_128x128@2x.png': 256,
        'icon_256x256.png': 256,
        'icon_256x256@2x.png': 512,
        'icon_512x512.png': 512,
        'icon_512x512@2x.png': 1024,
    }

    for filename, size in sizes.items():
        resized = img.resize((size, size), Image.LANCZOS)
        resized.save(os.path.join(output_dir, filename))
        print(f"  {filename} ({size}x{size})")

    print("Icon generated!")

if __name__ == '__main__':
    generate_icon()
