# Generates 10 arena board variants from the base board.png — each a different
# hue tint (like the reference game's selectable battle arenas).
import io
import os
import random

from PIL import Image, ImageEnhance

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACK = os.path.join(HERE, 'assets', 'back')

# hue rotation (degrees) per board index — 10 distinct arena moods
HUES = [0, 28, 60, 130, 175, 215, 265, 300, 330, 345]

def existing_ids():
    ids = set()
    for root, _, files in os.walk(HERE):
        for f in files:
            if f.endswith('.meta'):
                try:
                    for line in io.open(os.path.join(root, f), encoding='utf-8').read().splitlines():
                        if line.strip().startswith('id:'):
                            ids.add(line.strip()[3:].strip())
                except Exception:
                    pass
    return ids

def new_id(ids):
    while True:
        v = '%08x' % random.randint(0, 0xFFFFFFFF)
        if v not in ids:
            ids.add(v)
            return v

def main():
    ids = existing_ids()
    base = Image.open(os.path.join(BACK, 'board.png')).convert('RGBA')
    for i, hue in enumerate(HUES):
        im = base.convert('HSV')
        h, s, v = im.split()
        # shift hue + adjust saturation a touch per variant
        px = im.load()
        hpx = h.load()
        import colorsys
        img = base.copy()
        pix = img.load()
        for y in range(img.height):
            for x in range(img.width):
                r, g, b, a = pix[x, y]
                if a < 8:
                    continue
                hh, ss, vv = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
                hh = (hh + hue / 360.0) % 1.0
                ss = min(1.0, ss * (0.85 + 0.15 * (i % 3)))
                r2, g2, b2 = colorsys.hsv_to_rgb(hh, ss, vv)
                pix[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)
        name = 'board%d.png' % i
        img.save(os.path.join(BACK, name))
        with io.open(os.path.join(BACK, name + '.meta'), 'w', encoding='utf-8', newline='\n') as f:
            f.write('id: %s\nkind: texture\nversion: 1\nfilter: linear\n' % new_id(ids))
        print('  ', name, img.size)
    print('OK 10 boards')

main()
