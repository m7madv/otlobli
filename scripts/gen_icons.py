import os
from PIL import Image, ImageDraw

SRC = r"C:\Users\MOHAMMAD\Downloads\IMG_2976.PNG"
RES = os.path.join("android", "app", "src", "main", "res")

LEGACY_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}
FOREGROUND_SIZES = {k: v * 2.25 for k, v in LEGACY_SIZES.items()}  # 108dp base -> px

CONTENT_BBOX = (368, 1062, 3630, 3268)  # measured cart bbox on the 4096x4096 source
SAFE_FRACTION = 0.62  # fraction of the 108dp adaptive viewport the cart should occupy


def load_source():
    return Image.open(SRC).convert("RGBA")


def make_legacy(src, size):
    sq = src.convert("RGB").resize((size, size), Image.LANCZOS)
    return sq


def make_round(square_rgb):
    size = square_rgb.size[0]
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, size, size), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(square_rgb, (0, 0))
    out.putalpha(mask)
    return out


def make_cutout(src):
    crop = src.crop(CONTENT_BBOX).convert("RGB")
    w, h = crop.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px_in = crop.load()
    px_out = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px_in[x, y]
            a = min(255, max(r, g, b) * 3)
            px_out[x, y] = (r, g, b, a)
    return out


def make_foreground(cutout, canvas_size):
    canvas_size = int(round(canvas_size))
    cw, ch = cutout.size
    target_w = canvas_size * SAFE_FRACTION
    scale = target_w / cw
    new_w, new_h = int(round(cw * scale)), int(round(ch * scale))
    resized = cutout.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    ox = (canvas_size - new_w) // 2
    oy = (canvas_size - new_h) // 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def main():
    src = load_source()
    cutout = make_cutout(src)

    for density, size in LEGACY_SIZES.items():
        d = os.path.join(RES, f"mipmap-{density}")
        square = make_legacy(src, size)
        square_rgba = square.convert("RGBA")
        square_rgba.save(os.path.join(d, "ic_launcher.png"))
        make_round(square).save(os.path.join(d, "ic_launcher_round.png"))

        fg_size = FOREGROUND_SIZES[density]
        fg = make_foreground(cutout, fg_size)
        fg.save(os.path.join(d, "ic_launcher_foreground.png"))
        print(density, "legacy", square.size, "foreground", fg.size)

    # Play Store high-res listing icon (512x512, flat square, no transparency)
    os.makedirs("store-assets", exist_ok=True)
    store_icon = src.convert("RGB").resize((512, 512), Image.LANCZOS)
    store_icon.save(os.path.join("store-assets", "ic_launcher-512.png"))
    print("store icon saved")


if __name__ == "__main__":
    main()
