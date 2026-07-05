"""Generate Manevi Rehber app icons at all required sizes.

Renders a soft pastel mosque + crescent composition and writes:
  * iOS  AppIcon.appiconset (every size required by Xcode)
  * Android mipmap-{m,h,x,xx,xxx}hdpi/ic_launcher.png + ic_launcher_round.png
  * Web   web/favicon.png + web/icons/Icon-* + Icon-maskable-*

Run from the repo root with Pillow installed:
  python tools/generate_icons.py
"""

from __future__ import annotations

from pathlib import Path
from typing import Final

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]

IOS_ICON_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
WEB_DIR = ROOT / "web"
BRAND_DIR = ROOT / "assets" / "brand"

# Pastel sage palette (matches lib/core/constants/colors.dart)
BG_LIGHT: Final = (221, 238, 210)   # #DDEED2
BG_MID: Final = (168, 213, 186)    # #A8D5BA
BG_DARK: Final = (134, 183, 154)   # #86B79A
DOME_LIGHT: Final = (253, 248, 240) # #FDF8F0
DOME_DARK: Final = (241, 232, 210)  # #F1E8D2
WALL_LIGHT: Final = (253, 248, 240)
WALL_DARK: Final = (233, 222, 194)
OUTLINE: Final = (201, 188, 147)   # #C9BC93
GOLD: Final = (217, 181, 117)      # #D9B575
DOOR: Final = (90, 154, 127)       # #5A9A7F
SHADOW: Final = (15, 58, 42)       # #0f3a2a

# 1024-grid design coordinates
CANVAS = 1024
RADIUS = 220


def _radial_background(size: int) -> Image.Image:
    """Radial sage gradient approximated with nested ellipses."""
    img = Image.new("RGB", (size, size), BG_DARK)
    draw = ImageDraw.Draw(img)
    steps = 120
    for i in range(steps, 0, -1):
        t = i / steps
        r = int(BG_DARK[0] + (BG_LIGHT[0] - BG_DARK[0]) * (1 - t * 0.55))
        g = int(BG_DARK[1] + (BG_LIGHT[1] - BG_DARK[1]) * (1 - t * 0.55))
        b = int(BG_DARK[2] + (BG_LIGHT[2] - BG_DARK[2]) * (1 - t * 0.55))
        bbox = (
            int(size * 0.21 * t),
            int(size * 0.16 * t),
            int(size * (1 - 0.21 * t)),
            int(size * (1 - 0.16 * t)),
        )
        draw.ellipse(bbox, fill=(r, g, b))
    return img


def _rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=radius, fill=255
    )
    return mask


def _vertical_gradient(size: int, top: tuple, bottom: tuple, bbox) -> Image.Image:
    """Vertical gradient clipped to the given bbox (x0,y0,x1,y1)."""
    x0, y0, x1, y1 = bbox
    w, h = max(1, x1 - x0), max(1, y1 - y0)
    grad = Image.new("RGB", (w, h), top)
    px = grad.load()
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        for x in range(w):
            px[x, y] = (r, g, b)
    return grad


def _paste_gradient(
    base: Image.Image, bbox, top: tuple, bottom: tuple, scale: int
) -> None:
    """Composite a vertical gradient inside bbox with anti-aliased mask edges."""
    grad = _vertical_gradient(base.width, top, bottom, bbox)
    grad_resized = grad.resize((bbox[2] - bbox[0], bbox[3] - bbox[1]))
    base.paste(grad_resized, (bbox[0], bbox[1]))


def _scale(v: int, scale: int) -> int:
    return v * scale


def _draw_composition(
    size: int, maskable: bool = False, fg_scale: float = 1.0
) -> Image.Image:
    """Draw the full logo on a square canvas of the given size."""
    s = 4 if size <= 256 else 2  # supersample factor
    big = size * s
    c = CANVAS
    comp = c
    img = _radial_background(big)

    # soft inner vignette handled by gradient; rounded corners mask applied later
    draw = ImageDraw.Draw(img)

    fg = fg_scale if not maskable else 0.66
    cx_offset = (1 - fg) / 2  # keep composition centered

    def tx(v: int) -> int:
        return int((cx_offset * c + v * fg) * (big / c))

    def ty(v: int) -> int:
        return int((cx_offset * c + v * fg) * (big / c))

    def txy(box: tuple) -> tuple:
        return (tx(box[0]), ty(box[1]), tx(box[2]), ty(box[3]))

    outline_w = max(2, int(6 * s * fg))

    # ground shadow
    shadow_bbox = (tx(192), ty(760), tx(832), ty(820))
    shadow = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse(
        shadow_bbox, fill=(*SHADOW, 36)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(10 * s)))
    img = Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB")
    draw = ImageDraw.Draw(img)

    # side minarets
    minaret_left = txy((208, 392, 272, 752))
    minaret_right = txy((752, 392, 816, 752))
    _paste_gradient(img, minaret_left, WALL_LIGHT, WALL_DARK, s)
    _paste_gradient(img, minaret_right, WALL_LIGHT, WALL_DARK, s)
    draw.rounded_rectangle(minaret_left, radius=int(30 * s * fg),
                           outline=OUTLINE, width=outline_w)
    draw.rounded_rectangle(minaret_right, radius=int(30 * s * fg),
                           outline=OUTLINE, width=outline_w)
    # minaret caps
    draw.ellipse(
        (tx(218), ty(350), tx(262), ty(394)), fill=OUTLINE
    )
    draw.ellipse(
        (tx(762), ty(350), tx(806), ty(394)), fill=OUTLINE
    )

    # wall / base
    wall = txy((300, 486, 724, 752))
    _paste_gradient(img, wall, WALL_LIGHT, WALL_DARK, s)
    draw.rounded_rectangle(wall, radius=int(56 * s * fg),
                           outline=OUTLINE, width=outline_w)

    # dome (upper half ellipse on top of wall)
    dome_bbox = txy((300, 312, 724, 504))
    dome_grad = _vertical_gradient(
        big, DOME_LIGHT, DOME_DARK, dome_bbox
    )
    dome_grad = dome_grad.resize((dome_bbox[2] - dome_bbox[0],
                                  dome_bbox[3] - dome_bbox[1]))
    dome_mask = Image.new("L", (big, big), 0)
    md = ImageDraw.Draw(dome_mask)
    md.pieslice(dome_bbox, 180, 360, fill=255)
    md.rectangle(
        (dome_bbox[0], dome_bbox[3] - int((dome_bbox[3] - dome_bbox[1]) * 0.35),
         dome_bbox[2], dome_bbox[3]), fill=255
    )
    img.paste(dome_grad, (dome_bbox[0], dome_bbox[1]), dome_mask.crop(dome_bbox))
    draw = ImageDraw.Draw(img)
    draw.pieslice(dome_bbox, 180, 360,
                  outline=OUTLINE, width=outline_w)
    draw.line(
        (dome_bbox[0], dome_bbox[3] - 1, dome_bbox[2] - 1, dome_bbox[3] - 1),
        fill=OUTLINE, width=outline_w,
    )

    # dome soft shading overlay
    shade_bbox = dome_bbox
    shade_img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade_img)
    sd.pieslice(shade_bbox, 180, 360,
                fill=(*SHADOW, 26))
    shade_img = shade_img.filter(ImageFilter.GaussianBlur(int(8 * s)))
    img = Image.alpha_composite(img.convert("RGBA"),
                                shade_img).convert("RGB")
    draw = ImageDraw.Draw(img)

    # finial
    draw.rounded_rectangle(
        (tx(498), ty(272), tx(526), ty(316)),
        radius=int(6 * s * fg), fill=OUTLINE,
    )

    # gold crescent above dome
    crescent_outer = (tx(574), ty(194), tx(660), ty(280))
    crescent_inner = (tx(596), ty(178), tx(680), ty(264))
    draw.ellipse(crescent_outer, fill=GOLD)
    draw.ellipse(crescent_inner, fill=BG_MID)

    # arched doorway
    door_box = txy((476, 608, 548, 752))
    door_arch = (door_box[0], door_box[1] - int((door_box[3] - door_box[1]) * 0.55),
                 door_box[2], door_box[3])
    draw.pieslice((door_box[0], door_box[1] - int(34 * s * fg),
                   door_box[2], door_box[3] + int(34 * s * fg)),
                  180, 360, fill=DOOR)
    draw.rectangle((door_box[0], door_box[1], door_box[2], door_box[3]),
                   fill=DOOR)

    # small arched windows
    for window_x in (366, 614):
        wb = (tx(window_x), ty(620), tx(window_x + 44), ty(720))
        draw.pieslice((wb[0], wb[1] - int(22 * s * fg),
                       wb[2], wb[3] + int(22 * s * fg)),
                      180, 360, fill=DOOR)
        draw.rectangle((wb[0], wb[1], wb[2], wb[3]), fill=DOOR)

    # apply rounded-square mask (skip for maskable → full bleed)
    if not maskable:
        mask = _rounded_mask(big, int(RADIUS * s * (big / c)))
        rounded = Image.new("RGBA", (big, big), (0, 0, 0, 0))
        rounded.paste(img, (0, 0), mask)
        img = rounded.convert("RGB")
    else:
        # subtle inner frame highlight for maskable safe area
        img = img.convert("RGB")

    return img.resize((size, size), Image.LANCZOS)


def _save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG", optimize=True)


def build_ios() -> None:
    icons = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, size in icons.items():
        _save(_draw_composition(size), IOS_ICON_DIR / name)


def build_android() -> None:
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in sizes.items():
        out = ANDROID_RES / folder
        _save(_draw_composition(size), out / "ic_launcher.png")
        _save(_draw_composition(size), out / "ic_launcher_round.png")


def build_web() -> None:
    _save(_draw_composition(16), WEB_DIR / "favicon.png")
    _save(_draw_composition(192), WEB_DIR / "icons" / "Icon-192.png")
    _save(_draw_composition(512), WEB_DIR / "icons" / "Icon-512.png")
    _save(_draw_composition(192, maskable=True), WEB_DIR / "icons" / "Icon-maskable-192.png")
    _save(_draw_composition(512, maskable=True), WEB_DIR / "icons" / "Icon-maskable-512.png")


def build_brand() -> None:
    _save(_draw_composition(1024), BRAND_DIR / "icon.png")
    _save(_draw_composition(512, maskable=True), BRAND_DIR / "icon-maskable.png")


def main() -> None:
    build_ios()
    build_android()
    build_web()
    build_brand()
    print("Icons generated for iOS, Android, Web, and brand assets.")


if __name__ == "__main__":
    main()