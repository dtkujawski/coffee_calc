# Draws the splash artwork. Regenerate with:
#   python3 tool/make_splash.py android/app/src/main/res /usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf icons
#   python3 tool/make_splash.py android/app/src/main/res - launcher
# Needs Pillow.
import os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

BG = (111, 78, 55)          # coffee brown
SS = 4                      # supersample

PILE = Image.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'assets', 'bean_pile.png')).convert('RGBA')

def pile(canvas, cx, base_y, width):
    """Pastes the bean pile photo centered at cx with its bottom at base_y."""
    h = round(PILE.height * width / PILE.width)
    p = PILE.resize((round(width), h), Image.LANCZOS)
    # Soft shadow under the pile.
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((cx - width * .48, base_y - width * .05, cx + width * .48, base_y + width * .05),
                               fill=(40, 22, 10, 150))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(width * .03)))
    canvas.alpha_composite(p, (round(cx - width / 2), round(base_y - h)))

def text(canvas, s, font, cx, y):
    d = ImageDraw.Draw(canvas)
    l, t, r, b = d.textbbox((0, 0), s, font=font)
    d.text((cx - (r - l) / 2 - l, y - t), s, font=font, fill=(255, 255, 255, 255))
    return y + (b - t)

def render(size, fontpath, bg=True):
    # Splash icon: 288dp square, content inside the central 192dp circle.
    k = size / 1152
    c = Image.new('RGBA', (size, size), BG + (255,) if bg else (0, 0, 0, 0))
    pile(c, size / 2, 560 * k, 560 * k)
    f1 = ImageFont.truetype(fontpath, int(118 * k))
    f2 = ImageFont.truetype(fontpath, int(84 * k))
    y = text(c, 'Coffee', f1, size / 2, 635 * k)
    text(c, 'Calculator', f2, size / 2, y + 22 * k)
    return c

if __name__ == '__main__':
    out, font = sys.argv[1], sys.argv[2]
    if sys.argv[3:] == ['launcher']:
        # Adaptive icon foreground: 108dp, pile kept inside the 66dp safe circle.
        for name, px in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216), ('xxhdpi', 324), ('xxxhdpi', 432)]:
            n = px * 4
            fg = Image.new('RGBA', (n, n), (0, 0, 0, 0))
            w = n * 60 / 108
            pile(fg, n / 2, n / 2 + w * PILE.height / PILE.width / 2, w)
            fg = fg.resize((px, px), Image.LANCZOS)
            os.makedirs(f'{out}/mipmap-{name}', exist_ok=True)
            fg.save(f'{out}/mipmap-{name}/ic_launcher_foreground.png', optimize=True)
            # Legacy square icon (48dp): brown with the pile.
            lp = px * 48 // 108
            n = lp * 4
            big = Image.new('RGBA', (n, n), BG + (255,))
            w = n * .8
            pile(big, n / 2, n / 2 + w * PILE.height / PILE.width / 2, w)
            big.resize((lp, lp), Image.LANCZOS).save(f'{out}/mipmap-{name}/ic_launcher.png', optimize=True)
        sys.exit()
    if sys.argv[3:] == ['icons']:
        for name, px in [('mdpi', 288), ('hdpi', 432), ('xhdpi', 576), ('xxhdpi', 864), ('xxxhdpi', 1152)]:
            os.makedirs(f'{out}/drawable-{name}', exist_ok=True)
            render(1152, font, bg=False).resize((px, px), Image.LANCZOS).save(f'{out}/drawable-{name}/splash.png', optimize=True)
        sys.exit()
    im = render(1152, font)
    d = ImageDraw.Draw(im)
    if len(sys.argv) > 3:  # preview with the safe circle drawn
        d.ellipse((192, 192, 960, 960), outline=(255, 0, 0, 255), width=3)
    im.save(out)
