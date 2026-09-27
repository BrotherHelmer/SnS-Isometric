#!/usr/bin/env python3
"""Generate simple icon textures for building types in the C&C-style bar."""

import numpy as np
from PIL import Image, ImageDraw
import os

SIZE = 64
OUTPUT_DIR = "assets/settlement/ui/building_icons"

def create_icon(name, bg_color, fg_color, shape="rect"):
    """Create a simple building icon."""
    img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background
    if shape == "rect":
        draw.rectangle([8, 16, SIZE-8, SIZE-8], fill=bg_color, outline=(0, 0, 0, 200), width=2)
    elif shape == "tower":
        draw.rectangle([16, 8, SIZE-16, SIZE-8], fill=bg_color, outline=(0, 0, 0, 200), width=2)
        draw.rectangle([20, 4, SIZE-20, 12], fill=fg_color, outline=(0, 0, 0, 200), width=1)
    elif shape == "house":
        # Roof triangle
        draw.polygon([(SIZE//2, 12), (10, 28), (SIZE-10, 28)], fill=fg_color, outline=(0, 0, 0, 200))
        # House body
        draw.rectangle([12, 28, SIZE-12, SIZE-8], fill=bg_color, outline=(0, 0, 0, 200), width=2)
    elif shape == "industrial":
        draw.rectangle([8, 20, SIZE-8, SIZE-8], fill=bg_color, outline=(0, 0, 0, 200), width=2)
        draw.rectangle([16, 12, 28, 22], fill=fg_color, outline=(0, 0, 0, 150), width=1)
    
    # Detail accent
    if shape in ["rect", "industrial"]:
        draw.rectangle([SIZE//2 - 6, SIZE - 20, SIZE//2 + 6, SIZE - 12], fill=fg_color, outline=(0, 0, 0, 150), width=1)
    
    return img

icons = {
    "road": ("Road", (139, 121, 94, 255), (89, 81, 64, 255), "rect"),
    "house": ("House", (169, 147, 107, 255), (119, 147, 107, 255), "house"),
    "lumber_camp": ("Lumber", (139, 111, 71, 255), (107, 67, 35, 255), "industrial"),
    "quarry": ("Quarry", (154, 149, 136, 255), (122, 117, 104, 255), "rect"),
    "farm": ("Farm", (212, 184, 106, 255), (196, 168, 80, 255), "house"),
    "sawmill": ("Sawmill", (90, 74, 58, 255), (74, 58, 42, 255), "industrial"),
    "bakery": ("Bakery", (200, 82, 74, 255), (168, 56, 48, 255), "house"),
    "storehouse": ("Storehouse", (138, 122, 90, 255), (106, 90, 58, 255), "rect"),
    "wall": ("Wall", (154, 149, 136, 255), (122, 117, 104, 255), "rect"),
    "watchtower": ("Tower", (106, 74, 74, 255), (200, 74, 74, 255), "tower"),
    "barracks": ("Barracks", (106, 74, 74, 255), (90, 58, 58, 255), "rect"),
    "lumen_pillar": ("Lumen", (107, 198, 224, 255), (75, 166, 192, 255), "tower"),
    "outpost": ("Outpost", (139, 111, 71, 255), (200, 82, 74, 255), "tower"),
    "clear": ("Clear", (89, 121, 89, 255), (59, 91, 59, 255), "rect"),
}

os.makedirs(OUTPUT_DIR, exist_ok=True)

for key, (name, bg, fg, shape) in icons.items():
    icon = create_icon(name, bg, fg, shape)
    path = f"{OUTPUT_DIR}/{key}.png"
    icon.save(path)
    print(f"Generated: {path}")

print(f"\n✓ Generated {len(icons)} building icons")
