from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).absolute().parents[1]
MASTER_ICON_PATH = ROOT / "assets" / "branding" / "app_icon_master.png"


def _vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (size, size))
    draw = ImageDraw.Draw(image)
    height = size - 1
    for y in range(size):
        mix = y / height
        color = tuple(
            int(top[index] * (1 - mix) + bottom[index] * mix)
            for index in range(3)
        )
        draw.line((0, y, size, y), fill=(*color, 255))
    return image


def _rounded_mask(size: int, inset: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        (inset, inset, size - inset, size - inset),
        radius=radius,
        fill=255,
    )
    return mask


def _draw_shield(draw: ImageDraw.ImageDraw, center_x: int, center_y: int) -> None:
    top = center_y - 220
    bottom = center_y + 210
    points = [
        (center_x, top),
        (center_x + 138, top + 34),
        (center_x + 222, top + 112),
        (center_x + 206, center_y + 56),
        (center_x + 124, bottom - 40),
        (center_x, bottom),
        (center_x - 124, bottom - 40),
        (center_x - 206, center_y + 56),
        (center_x - 222, top + 112),
        (center_x - 138, top + 34),
        (center_x, top),
    ]
    draw.line(points, fill="white", width=24, joint="curve")


def _draw_portrait(draw: ImageDraw.ImageDraw, center_x: int, center_y: int) -> None:
    face = (center_x - 56, center_y - 116, center_x + 56, center_y - 4)
    draw.ellipse(face, outline="white", width=12)

    draw.arc(
        (center_x - 88, center_y - 158, center_x + 88, center_y + 10),
        start=192,
        end=340,
        fill="white",
        width=14,
    )
    draw.arc(
        (center_x - 122, center_y - 106, center_x - 6, center_y + 78),
        start=260,
        end=58,
        fill="white",
        width=14,
    )
    draw.arc(
        (center_x - 16, center_y - 106, center_x + 128, center_y + 128),
        start=128,
        end=274,
        fill="white",
        width=14,
    )

    draw.line(
        (
            center_x - 18,
            center_y - 12,
            center_x - 38,
            center_y + 126,
            center_x - 118,
            center_y + 190,
            center_x + 118,
            center_y + 190,
            center_x + 38,
            center_y + 126,
            center_x + 18,
            center_y - 12,
        ),
        fill="white",
        width=12,
        joint="curve",
    )
    draw.line(
        (center_x - 48, center_y + 88, center_x, center_y + 138, center_x + 48, center_y + 88),
        fill="white",
        width=12,
        joint="curve",
    )

    draw.arc(
        (center_x - 34, center_y - 54, center_x + 34, center_y + 4),
        start=18,
        end=162,
        fill="white",
        width=8,
    )
    draw.ellipse((center_x - 16, center_y - 72, center_x - 6, center_y - 60), fill="white")
    draw.ellipse((center_x + 6, center_y - 72, center_x + 16, center_y - 60), fill="white")


def generate_master_icon(size: int = 1024) -> Image.Image:
    canvas = _vertical_gradient(size, (76, 20, 164), (52, 17, 143))
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (64, 72, size - 64, size - 48),
        radius=98,
        fill=(26, 5, 76, 190),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas.alpha_composite(shadow)

    card = _vertical_gradient(size, (167, 33, 211), (83, 23, 184))
    card_mask = _rounded_mask(size, inset=48, radius=102)
    canvas = Image.composite(card, canvas, card_mask)

    inner_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    inner_shadow_draw = ImageDraw.Draw(inner_shadow)
    inner_shadow_draw.rounded_rectangle(
        (182, 170, size - 182, size - 194),
        radius=94,
        fill=(25, 6, 80, 140),
    )
    inner_shadow = inner_shadow.filter(ImageFilter.GaussianBlur(20))
    canvas.alpha_composite(inner_shadow)

    inner = _vertical_gradient(size, (170, 53, 224), (82, 26, 180))
    inner_mask = _rounded_mask(size, inset=174, radius=96)
    canvas = Image.composite(inner, canvas, inner_mask)

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.ellipse((184, 110, size - 120, 520), fill=(255, 255, 255, 28))
    highlight = highlight.filter(ImageFilter.GaussianBlur(24))
    canvas.alpha_composite(highlight)

    icon_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    icon_draw = ImageDraw.Draw(icon_layer)
    _draw_shield(icon_draw, center_x=size // 2, center_y=492)
    _draw_portrait(icon_draw, center_x=size // 2, center_y=470)

    glow = icon_layer.filter(ImageFilter.GaussianBlur(6))
    glow = ImageChops.multiply(glow, Image.new("RGBA", (size, size), (255, 255, 255, 120)))
    canvas.alpha_composite(glow)
    canvas.alpha_composite(icon_layer)

    return canvas.convert("RGBA")


def _save_png(source: Image.Image, destination: Path, size: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    source.resize((size, size), Image.Resampling.LANCZOS).save(destination)


def _export_platform_icons(master: Image.Image) -> None:
    android_sizes = {
        "mipmap-mdpi/ic_launcher.png": 48,
        "mipmap-hdpi/ic_launcher.png": 72,
        "mipmap-xhdpi/ic_launcher.png": 96,
        "mipmap-xxhdpi/ic_launcher.png": 144,
        "mipmap-xxxhdpi/ic_launcher.png": 192,
    }
    for relative_path, size in android_sizes.items():
        _save_png(master, ROOT / "android" / "app" / "src" / "main" / "res" / relative_path, size)

    ios_sizes = {
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
    ios_root = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for file_name, size in ios_sizes.items():
        _save_png(master, ios_root / file_name, size)

    mac_sizes = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }
    mac_root = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for file_name, size in mac_sizes.items():
        _save_png(master, mac_root / file_name, size)

    web_sizes = {
        ROOT / "web" / "favicon.png": 32,
        ROOT / "web" / "icons" / "Icon-192.png": 192,
        ROOT / "web" / "icons" / "Icon-512.png": 512,
        ROOT / "web" / "icons" / "Icon-maskable-192.png": 192,
        ROOT / "web" / "icons" / "Icon-maskable-512.png": 512,
    }
    for destination, size in web_sizes.items():
        _save_png(master, destination, size)

    windows_icon = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    windows_icon.parent.mkdir(parents=True, exist_ok=True)
    master.save(
        windows_icon,
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


def main() -> None:
    MASTER_ICON_PATH.parent.mkdir(parents=True, exist_ok=True)
    master = generate_master_icon()
    master.save(MASTER_ICON_PATH)
    _export_platform_icons(master)
    print(f"Generated icon assets at {MASTER_ICON_PATH}")


if __name__ == "__main__":
    main()
