#!/usr/bin/env python3
"""Generate HueHaven app icon — cafe boba theme.

Produces:
  assets/icon.png                  512x512 main icon (Play Store + Godot)
  assets/icon_foreground.png       432x432 adaptive icon foreground (Android)
  assets/icon_background.png       432x432 solid background (Android adaptive)

Design: warm cream squircle with a tall slender boba glass in the center,
stacked with taro/peach/matcha/milktea pearls and a mint paper straw
poking out the top. Walnut wood border for the icon edge.
"""
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(ROOT, "assets")
os.makedirs(ASSETS, exist_ok=True)

# Cafe boba palette
BG_TOP = (245, 235, 218)
BG_BOT = (220, 200, 175)
ACCENT = (232, 155, 122)
WALNUT = (138, 110, 79)
ESPRESSO = (61, 42, 26)
RIM_CREAM = (245, 224, 178)

TARO = (158, 124, 184)
MATCHA = (125, 190, 130)
MILKTEA = (184, 142, 92)
PEACH = (232, 160, 133)
STRAW_MINT = (170, 210, 185)


def render_icon(size, with_squircle=True):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")

    if with_squircle:
        radius = int(size * 0.22)
        grad = Image.new("RGBA", (size, size), BG_BOT + (255,))
        gd = ImageDraw.Draw(grad)
        for y in range(size):
            t = y / size
            r = int(BG_TOP[0] + (BG_BOT[0] - BG_TOP[0]) * t)
            g = int(BG_TOP[1] + (BG_BOT[1] - BG_TOP[1]) * t)
            b = int(BG_TOP[2] + (BG_BOT[2] - BG_TOP[2]) * t)
            gd.line([(0, y), (size, y)], fill=(r, g, b, 255))
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (0, 0, size - 1, size - 1), radius=radius, fill=255
        )
        bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        bg.paste(grad, (0, 0), mask)
        img = Image.alpha_composite(img, bg)
        d = ImageDraw.Draw(img, "RGBA")

        # Soft warm peach glow at top
        glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gd2 = ImageDraw.Draw(glow)
        for r_glow in range(int(size * 0.42), 0, -8):
            alpha = int(28 * (1 - r_glow / (size * 0.42)))
            gd2.ellipse((size * 0.5 - r_glow, size * 0.12 - r_glow,
                         size * 0.5 + r_glow, size * 0.12 + r_glow),
                        fill=ACCENT + (alpha,))
        glow_masked = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        glow_masked.paste(glow, (0, 0), mask)
        img = Image.alpha_composite(img, glow_masked)
        d = ImageDraw.Draw(img, "RGBA")

    cx = size / 2
    cy = size / 2

    # Glass cup proportions — slightly wider, slightly taller
    glass_w = size * 0.42
    glass_h = size * 0.74
    glass_x = cx - glass_w / 2
    glass_y = cy - glass_h / 2 + size * 0.04

    # --- LAYER ORDER (back to front): straw → glass body → pearls → glass rim ---

    # 1. Paper straw — drawn FIRST so pearls will cover its lower half
    straw_w = max(10, int(size * 0.07))
    straw_h = int(size * 0.62)
    straw_x = cx + size * 0.04   # offset slightly to the right
    straw_y = glass_y - straw_h * 0.45
    _draw_paper_straw(img, straw_x, straw_y, straw_w, straw_h, STRAW_MINT)

    # 2. Glass body fill — translucent warm cream, covers lower half of straw
    d.rounded_rectangle(
        (glass_x, glass_y, glass_x + glass_w, glass_y + glass_h),
        radius=int(size * 0.05),
        fill=(248, 235, 215, 180)
    )
    # Left wall highlight (drawn before pearls so they cover it)
    d.rectangle(
        (glass_x + 4, glass_y + 8, glass_x + 9, glass_y + glass_h - 20),
        fill=(255, 255, 255, 200)
    )
    # Right wall shadow
    d.rectangle(
        (glass_x + glass_w - 9, glass_y + 8, glass_x + glass_w - 4, glass_y + glass_h - 20),
        fill=ESPRESSO + (160,)
    )
    # Base shadow
    d.rectangle(
        (glass_x + 5, glass_y + glass_h - 16, glass_x + glass_w - 5, glass_y + glass_h - 5),
        fill=ESPRESSO + (210,)
    )

    # 3. THREE stacked boba pearls — sized to comfortably fit
    ball_r = glass_w * 0.30
    pearls = [TARO, PEACH, MATCHA]  # bottom -> top
    inner_pad = ball_r * 0.4 + 6
    bottom_y = glass_y + glass_h - inner_pad - ball_r
    top_y = glass_y + inner_pad + ball_r
    if len(pearls) > 1:
        step = (bottom_y - top_y) / (len(pearls) - 1)
    else:
        step = 0
    for i, col in enumerate(pearls):
        by = bottom_y - i * step
        _draw_glass_ball(img, cx, by, ball_r, col)

    # 4. Cream rim drawn LAST so it sits in front of pearls visually
    rim_h = max(4, int(size * 0.026))
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle(
        (glass_x + 3, glass_y, glass_x + glass_w - 3, glass_y + rim_h),
        fill=RIM_CREAM + (255,)
    )
    d.rectangle(
        (glass_x + 3, glass_y + rim_h, glass_x + glass_w - 3, glass_y + rim_h + 3),
        fill=ESPRESSO + (170,)
    )

    # 5. Walnut border on the glass
    d.rounded_rectangle(
        (glass_x, glass_y, glass_x + glass_w, glass_y + glass_h),
        radius=int(size * 0.05),
        outline=WALNUT, width=max(2, int(size / 160))
    )

    if with_squircle:
        # Walnut outer border on the icon
        radius = int(size * 0.22)
        d_outer = ImageDraw.Draw(img, "RGBA")
        d_outer.rounded_rectangle(
            (0, 0, size - 1, size - 1), radius=radius,
            outline=WALNUT + (200,), width=max(3, int(size / 130))
        )

    return img


def _draw_glass_ball(img, cx, cy, r, color):
    d = ImageDraw.Draw(img, "RGBA")
    shadow = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).ellipse(
        (cx - r * 1.05, cy + r * 0.18 - r * 1.05, cx + r * 1.05, cy + r * 0.18 + r * 1.05),
        fill=(0, 0, 0, 70)
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(1, r * 0.10)))
    img.alpha_composite(shadow)
    d = ImageDraw.Draw(img, "RGBA")
    er, eg, eb = [int(c * 0.55) for c in color]
    d.ellipse((cx - r - 1, cy - r - 1, cx + r + 1, cy + r + 1), fill=(er, eg, eb, 225))
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*color, 215))
    cr, cg, cb = [min(255, int(c * 1.15)) for c in color]
    d.ellipse((cx - r * 0.78, cy - r * 0.72, cx + r * 0.78, cy + r * 0.84), fill=(cr, cg, cb, 155))
    hl_x = cx - r * 0.28
    hl_y = cy - r * 0.38
    for radius_mult, alpha in [(0.50, 30), (0.38, 60), (0.26, 110), (0.16, 180), (0.09, 235)]:
        rr = r * radius_mult
        d.ellipse((hl_x - rr, hl_y - rr, hl_x + rr, hl_y + rr), fill=(255, 255, 255, alpha))


def _draw_paper_straw(img, x, y, w, h, color):
    d = ImageDraw.Draw(img, "RGBA")
    # White paper base
    d.rounded_rectangle((x, y, x + w, y + h), radius=int(w * 0.45), fill=(252, 245, 232, 255))
    # Candy stripes — diagonal mint
    stripe_h = w * 0.7
    gap = w * 0.5
    i = 0
    while True:
        ty = y - 4 + i * (stripe_h + gap)
        if ty > y + h:
            break
        pts = [
            (x, ty),
            (x + w, ty + w * 0.35),
            (x + w, ty + w * 0.35 + stripe_h),
            (x, ty + stripe_h),
        ]
        d.polygon(pts, fill=color + (240,))
        i += 1
    # Clip stripes to straw shape with a mask
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((x, y, x + w, y + h), radius=int(w * 0.45), fill=255)
    # Apply mask in-place by compositing
    bg = Image.new("RGBA", img.size, (0, 0, 0, 0))
    bg.paste(img, (0, 0), mask)
    # Now bg has only the masked content
    # Overlay it back onto a transparent copy of img minus the straw area
    inv = Image.new("L", img.size, 255)
    ImageDraw.Draw(inv).rounded_rectangle((x, y, x + w, y + h), radius=int(w * 0.45), fill=0)
    outside = Image.new("RGBA", img.size, (0, 0, 0, 0))
    outside.paste(img, (0, 0), inv)
    img_new = Image.alpha_composite(outside, bg)
    # Copy back into img
    img.paste(img_new, (0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    # Subtle top opening shadow
    d.ellipse((x + w * 0.15, y - 1, x + w * 0.85, y + 5), fill=(180, 150, 120, 220))


def main():
    icon_512 = render_icon(512, with_squircle=True)
    icon_512.save(os.path.join(ASSETS, "icon.png"))

    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    inner = render_icon(280, with_squircle=False)
    fg.paste(inner, ((432 - 280) // 2, (432 - 280) // 2), inner)
    fg.save(os.path.join(ASSETS, "icon_foreground.png"))

    bg = Image.new("RGBA", (432, 432), (*BG_BOT, 255))
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
