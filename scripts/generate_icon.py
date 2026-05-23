#!/usr/bin/env python3
"""Generate HueHaven app icon — replicates the in-game logo procedurally.
Produces three files:
  assets/icon.png                  512x512 main icon (Play Store + Godot config)
  assets/icon_foreground.png       432x432 adaptive icon foreground (Android)
  assets/icon_background.png       432x432 solid background (Android adaptive)
"""
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")
os.makedirs(ASSETS, exist_ok=True)

# Palette (matches Style.gd)
BG_TOP = (34, 48, 74)         # #22304A
BG_BOT = (14, 24, 40)          # #0E1828
ACCENT = (255, 140, 90, 255)   # #FF8C5A
ACCENT_GLOW = (255, 140, 90)
LAVENDER = (158, 124, 184)     # #9E7CB8
TEAL = (122, 184, 196)         # #7AB8C4
SAGE = (125, 190, 130)         # #7DBE82
CYAN_RIM = (140, 200, 240)


def render_icon(size: int, with_squircle: bool = True) -> Image.Image:
    """Render the logo at `size` x `size`. If with_squircle is False, draws
    just the foreground (transparent background) — for adaptive icons."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")

    if with_squircle:
        # Vertical gradient background inside a rounded square
        radius = int(size * 0.22)
        # Draw gradient
        grad = Image.new("RGBA", (size, size), (0, 0, 0, 255))
        gd = ImageDraw.Draw(grad)
        for y in range(size):
            t = y / size
            r = int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
            g = int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
            b = int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
            gd.line([(0, y), (size, y)], fill=(r, g, b, 255))
        # Mask to squircle
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, size - 1, size - 1), radius=radius, fill=255
        )
        bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        bg.paste(grad, (0, 0), mask)
        img = Image.alpha_composite(img, bg)
        d = ImageDraw.Draw(img, "RGBA")

        # Cool cyan rim glow (top + bottom) — radial gradients masked by squircle
        glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gld = ImageDraw.Draw(glow, "RGBA")
        # Top glow strip
        for y in range(int(size * 0.5)):
            alpha = int((1 - y / (size * 0.5)) * 40)
            gld.line([(0, y), (size, y)], fill=(*CYAN_RIM, alpha))
        # Bottom glow strip
        for y in range(int(size * 0.5)):
            yy = size - 1 - y
            alpha = int((1 - y / (size * 0.5)) * 32)
            gld.line([(0, yy), (size, yy)], fill=(*CYAN_RIM, alpha))
        # Mask glow to squircle
        glow_masked = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        glow_masked.paste(glow, (0, 0), mask)
        img = Image.alpha_composite(img, glow_masked)
        d = ImageDraw.Draw(img, "RGBA")

    # ----- The test-tube + balls (drawn directly, no squircle mask) -----
    cx = size / 2
    cy = size / 2

    # Tube — capsule shape (vertical)
    tube_w = size * 0.38
    tube_h = size * 0.80
    tube_x = cx - tube_w / 2
    tube_y = cy - tube_h / 2

    # Tube backdrop (translucent cool wash)
    tube_radius = tube_w / 2  # fully rounded → capsule
    capsule = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cd = ImageDraw.Draw(capsule, "RGBA")
    # Stack 3 layered fills for gradient feel
    cd.rounded_rectangle(
        (tube_x, tube_y, tube_x + tube_w, tube_y + tube_h),
        radius=tube_radius, fill=(140, 200, 240, 16)
    )
    # Gradient via thin horizontal lines clipped by capsule mask
    cap_mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(cap_mask).rounded_rectangle(
        (tube_x, tube_y, tube_x + tube_w, tube_y + tube_h),
        radius=tube_radius, fill=255
    )
    glass = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    gd2 = ImageDraw.Draw(glass)
    for y in range(int(tube_y), int(tube_y + tube_h)):
        t = (y - tube_y) / tube_h
        r = int(166 + (89 - 166) * t)
        g = int(217 + (140 - 217) * t)
        b = int(250 + (191 - 250) * t)
        a = int(42 + (28 - 42) * t)
        gd2.line([(0, y), (size, y)], fill=(r, g, b, a))
    glass_clipped = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glass_clipped.paste(glass, (0, 0), cap_mask)
    img = Image.alpha_composite(img, glass_clipped)
    d = ImageDraw.Draw(img, "RGBA")
    # Tube outer rim
    d.rounded_rectangle(
        (tube_x, tube_y, tube_x + tube_w, tube_y + tube_h),
        radius=tube_radius, outline=(140, 205, 242, 150), width=max(2, int(size / 200))
    )
    # Left vertical highlight on the tube
    hl_y0 = tube_y + tube_radius * 0.5
    hl_y1 = tube_y + tube_h - tube_radius * 0.5
    d.rectangle(
        (tube_x + size * 0.012, hl_y0, tube_x + size * 0.012 + max(2, size / 200), hl_y1),
        fill=(255, 255, 255, 60)
    )

    # Three balls — top to bottom: lavender / teal / sage
    ball_r = tube_w * 0.32
    inner_pad = ball_r * 0.4 + size * 0.012
    top_y = tube_y + inner_pad + ball_r
    bot_y = tube_y + tube_h - inner_pad - ball_r
    step = (bot_y - top_y) / 2
    ball_colors = [LAVENDER, TEAL, SAGE]
    for i, col in enumerate(ball_colors):
        by = top_y + step * i
        _draw_glass_ball(img, cx, by, ball_r, col)

    if with_squircle:
        # Subtle accent border around the squircle
        radius = int(size * 0.22)
        d_outer = ImageDraw.Draw(img, "RGBA")
        d_outer.rounded_rectangle(
            (0, 0, size - 1, size - 1), radius=radius,
            outline=(*CYAN_RIM, 60), width=max(2, int(size / 160))
        )

    return img


def _draw_glass_ball(img: Image.Image, cx, cy, r, color):
    """Layered glassy ball — matches the in-game multi-layer render."""
    d = ImageDraw.Draw(img, "RGBA")
    # Soft cast shadow (slightly down + offset, blurred via larger semi-transparent ellipse)
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse(
        (cx - r * 1.05, cy + r * 0.18 - r * 1.05, cx + r * 1.05, cy + r * 0.18 + r * 1.05),
        fill=(0, 0, 0, 55)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(1, r * 0.08)))
    img.alpha_composite(shadow)
    d = ImageDraw.Draw(img, "RGBA")
    # Edge ring (darker shade)
    er, eg, eb = [int(c * 0.55) for c in color]
    d.ellipse((cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1), fill=(er, eg, eb, 215))
    # Body
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*color, 200))
    # Brighter core
    cr, cg, cb = [min(255, int(c * 1.15)) for c in color]
    d.ellipse((cx - r * 0.78, cy - r * 0.72, cx + r * 0.78, cy + r * 0.84), fill=(cr, cg, cb, 140))
    # Bottom rim reflection
    d.ellipse((cx - r * 0.5, cy + r * 0.18, cx + r * 0.5, cy + r * 0.68), fill=(255, 255, 255, 45))
    # Top-left highlight stack
    hl_x = cx - r * 0.28
    hl_y = cy - r * 0.38
    for radius_mult, alpha in [(0.50, 25), (0.38, 50), (0.26, 90), (0.16, 160), (0.09, 220)]:
        rr = r * radius_mult
        d.ellipse((hl_x - rr, hl_y - rr, hl_x + rr, hl_y + rr), fill=(255, 255, 255, alpha))


def main():
    # 1. Main icon — 512x512 with squircle background
    icon_512 = render_icon(512, with_squircle=True)
    icon_512.save(os.path.join(ASSETS, "icon.png"))

    # 2. Adaptive icon foreground — 432x432, just the test-tube on transparent
    # Android will scale + crop this; the visible safe-zone is the center 264x264
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    # Render the tube+balls at a smaller scale so it fits in the safe zone
    inner = render_icon(264, with_squircle=False)
    fg.paste(inner, ((432 - 264) // 2, (432 - 264) // 2), inner)
    fg.save(os.path.join(ASSETS, "icon_foreground.png"))

    # 3. Adaptive icon background — solid dark navy
    bg = Image.new("RGBA", (432, 432), (*BG_BOT, 255))
    # Add subtle gradient
    bgd = ImageDraw.Draw(bg)
    for y in range(432):
        t = y / 432
        r = int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
        g = int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
        b = int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
        bgd.line([(0, y), (432, y)], fill=(r, g, b, 255))
    bg.save(os.path.join(ASSETS, "icon_background.png"))

    print(f"Wrote: {os.path.join(ASSETS, 'icon.png')} (512x512)")
    print(f"Wrote: {os.path.join(ASSETS, 'icon_foreground.png')} (432x432)")
    print(f"Wrote: {os.path.join(ASSETS, 'icon_background.png')} (432x432)")


if __name__ == "__main__":
    main()
