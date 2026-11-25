# Draws the splash artwork. Regenerate with:
#   python3 tool/make_splash.py android/app/src/main/res /usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf icons
# Needs Pillow.
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

BG = (111, 78, 55)          # coffee brown
SS = 4                      # supersample
random.seed(7)

def bean(w, h, angle):
    W, H = int(w * SS), int(h * SS)
    pad = 8 * SS
    im = Image.new('RGBA', (W + 2 * pad, H + 2 * pad), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    box = (pad, pad, pad + W, pad + H)
    d.ellipse(box, fill=(52, 30, 17, 255))
    # Highlight toward the upper left.
    hl = Image.new('RGBA', im.size, (0, 0, 0, 0))
    ImageDraw.Draw(hl).ellipse(
        (pad + W * .12, pad + H * .08, pad + W * .7, pad + H * .62), fill=(120, 74, 42, 200))
    hl = hl.filter(ImageFilter.GaussianBlur(W * .08))
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).ellipse(box, fill=255)
    im = Image.composite(Image.alpha_composite(im, hl), im, mask)
    d = ImageDraw.Draw(im)
    # S-shaped crease along the long axis.
    cx, cy = pad + W / 2, pad + H / 2
    pts = []
    for i in range(41):
        t = i / 40
        x = pad + W * (.1 + .8 * t)
        y = cy + math.sin((t - .5) * math.pi * 2) * H * .09
        pts.append((x, y))
    d.line(pts, fill=(28, 15, 8, 255), width=int(H * .1), joint='curve')
    d.line([(x, y - H * .06) for x, y in pts[6:35]], fill=(95, 58, 33, 160), width=int(H * .03))
    im = im.rotate(angle, resample=Image.BICUBIC, expand=True)
    return im.resize((im.width // SS, im.height // SS), Image.LANCZOS)

def pile(canvas, cx, base_y, bw, bh):
    rows = [5, 4, 3, 2, 1]
    beans = []
    for r, n in enumerate(rows):
        y = base_y - r * bh * .62
        x0 = cx - (n - 1) * bw * .86 / 2
        for i in range(n):
            x = x0 + i * bw * .86 + random.uniform(-6, 6)
            beans.append((x, y + random.uniform(-5, 5), random.uniform(-35, 35)))
    # Soft shadow under the pile.
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((cx - bw * 2.6, base_y + bh * .1, cx + bw * 2.6, base_y + bh * .7),
                               fill=(40, 22, 10, 140))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(18)))
    for x, y, a in beans:
        b = bean(bw, bh, a)
        canvas.alpha_composite(b, (int(x - b.width / 2), int(y - b.height / 2)))

def text(canvas, s, font, cx, y):
    d = ImageDraw.Draw(canvas)
    l, t, r, b = d.textbbox((0, 0), s, font=font)
    d.text((cx - (r - l) / 2 - l, y - t), s, font=font, fill=(255, 255, 255, 255))
    return y + (b - t)

def render(size, fontpath, bg=True):
    # Splash icon: 288dp square, content inside the central 192dp circle.
    k = size / 1152
    c = Image.new('RGBA', (size, size), BG + (255,) if bg else (0, 0, 0, 0))
    pile(c, size / 2, 545 * k, 112 * k, 74 * k)
    f1 = ImageFont.truetype(fontpath, int(118 * k))
    f2 = ImageFont.truetype(fontpath, int(84 * k))
    y = text(c, 'Coffee', f1, size / 2, 635 * k)
    text(c, 'Calculator', f2, size / 2, y + 22 * k)
    return c

if __name__ == '__main__':
    out, font = sys.argv[1], sys.argv[2]
    if sys.argv[3:] == ['icons']:
        for name, px in [('mdpi', 288), ('hdpi', 432), ('xhdpi', 576), ('xxhdpi', 864), ('xxxhdpi', 1152)]:
            import os
            os.makedirs(f'{out}/drawable-{name}', exist_ok=True)
            render(1152, font, bg=False).resize((px, px), Image.LANCZOS).save(f'{out}/drawable-{name}/splash.png', optimize=True)
        sys.exit()
    im = render(1152, font)
    d = ImageDraw.Draw(im)
    if len(sys.argv) > 3:  # preview with the safe circle drawn
        d.ellipse((192, 192, 960, 960), outline=(255, 0, 0, 255), width=3)
    im.save(out)
