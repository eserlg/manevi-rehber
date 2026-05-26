from pathlib import Path
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"

ICONS = {
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


def rounded_rectangle(draw, xy, radius, fill):
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def build_icon(size):
    scale = size / 1024
    image = Image.new("RGB", (size, size), "#0f7d63")
    draw = ImageDraw.Draw(image)

    draw.ellipse(
        (
            int(92 * scale),
            int(84 * scale),
            int(932 * scale),
            int(924 * scale),
        ),
        fill="#168c70",
    )
    draw.ellipse(
        (
            int(174 * scale),
            int(154 * scale),
            int(850 * scale),
            int(830 * scale),
        ),
        outline="#d5b66a",
        width=max(2, int(24 * scale)),
    )

    # Dome
    draw.pieslice(
        (
            int(286 * scale),
            int(286 * scale),
            int(738 * scale),
            int(738 * scale),
        ),
        180,
        360,
        fill="#f8f5ec",
    )
    draw.rectangle(
        (
            int(286 * scale),
            int(512 * scale),
            int(738 * scale),
            int(728 * scale),
        ),
        fill="#f8f5ec",
    )

    # Minarets
    rounded_rectangle(
        draw,
        (
            int(216 * scale),
            int(360 * scale),
            int(302 * scale),
            int(728 * scale),
        ),
        int(28 * scale),
        "#f8f5ec",
    )
    rounded_rectangle(
        draw,
        (
            int(722 * scale),
            int(360 * scale),
            int(808 * scale),
            int(728 * scale),
        ),
        int(28 * scale),
        "#f8f5ec",
    )
    draw.polygon(
        [
            (int(259 * scale), int(252 * scale)),
            (int(204 * scale), int(366 * scale)),
            (int(314 * scale), int(366 * scale)),
        ],
        fill="#f8f5ec",
    )
    draw.polygon(
        [
            (int(765 * scale), int(252 * scale)),
            (int(710 * scale), int(366 * scale)),
            (int(820 * scale), int(366 * scale)),
        ],
        fill="#f8f5ec",
    )

    # Door and windows
    draw.rounded_rectangle(
        (
            int(450 * scale),
            int(570 * scale),
            int(574 * scale),
            int(728 * scale),
        ),
        radius=int(52 * scale),
        fill="#0f7d63",
    )
    for x in (360, 626):
        draw.ellipse(
            (
                int((x - 34) * scale),
                int(560 * scale),
                int((x + 34) * scale),
                int(628 * scale),
            ),
            fill="#0f7d63",
        )

    # Crescent
    draw.ellipse(
        (
            int(616 * scale),
            int(196 * scale),
            int(724 * scale),
            int(304 * scale),
        ),
        fill="#d5b66a",
    )
    draw.ellipse(
        (
            int(646 * scale),
            int(180 * scale),
            int(752 * scale),
            int(286 * scale),
        ),
        fill="#168c70",
    )

    return image


def main():
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    for filename, size in ICONS.items():
        build_icon(size).save(ICON_DIR / filename)


if __name__ == "__main__":
    main()
