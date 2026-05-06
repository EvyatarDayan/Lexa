from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def gradient_color(stops, x_norm: float):
    if x_norm <= 0:
        return stops[0]
    if x_norm >= 1:
        return stops[-1]
    segment_count = len(stops) - 1
    segment = min(int(x_norm * segment_count), segment_count - 1)
    local_start = segment / segment_count
    local_end = (segment + 1) / segment_count
    local_t = (x_norm - local_start) / (local_end - local_start)
    c1 = stops[segment]
    c2 = stops[segment + 1]
    return (
        lerp(c1[0], c2[0], local_t),
        lerp(c1[1], c2[1], local_t),
        lerp(c1[2], c2[2], local_t),
    )


def load_font(size: int):
    candidates = [
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main():
    text = "Lexa"
    width, height = 1800, 900
    background = (255, 255, 255)
    image = Image.new("RGB", (width, height), background)
    draw = ImageDraw.Draw(image)

    font = load_font(360)
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (width - text_w) // 2
    y = (height - text_h) // 2 - 25

    mask = Image.new("L", (width, height), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.text((x, y), text, fill=255, font=font)

    gradient = Image.new("RGB", (width, height), background)
    grad_pixels = gradient.load()

    # Same color order used in SearchView: blue -> red -> yellow -> green.
    stops = [
        (66, 133, 244),
        (234, 67, 53),
        (251, 188, 5),
        (52, 168, 83),
    ]

    start_x = x
    end_x = x + text_w
    span = max(end_x - start_x, 1)
    for px in range(width):
        t = (px - start_x) / span
        color = gradient_color(stops, t)
        for py in range(height):
            grad_pixels[px, py] = color

    image.paste(gradient, (0, 0), mask)
    out_dir = Path(__file__).resolve().parent
    jpg_path = out_dir / "lexa-title.jpg"
    image.save(jpg_path, "JPEG", quality=95, optimize=True)
    print(f"Saved {jpg_path}")

    # Transparent PNG export (same artwork, alpha outside text).
    transparent = Image.new("RGBA", (width, height), (255, 255, 255, 0))
    gradient_rgba = gradient.convert("RGBA")
    transparent.paste(gradient_rgba, (0, 0), mask)
    png_path = out_dir / "lexa-title-transparent.png"
    transparent.save(png_path, "PNG", optimize=True)
    print(f"Saved {png_path}")


if __name__ == "__main__":
    main()
