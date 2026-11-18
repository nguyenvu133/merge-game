# Generates monster textures for the 9 NEW hybrid elements (v47):
# plasma, frostfire, thunder, glacier, crystal, permafrost, storm, blizzard, hail
# Each = 50/50 blend of its two parent base-element textures, per level 1..8,
# plus a small hue rotation per level for visual level distinction.
# Also writes the .meta (unique 8-hex id, scans all existing metas first).
import io
import os
import random

from PIL import Image, ImageOps

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MON = os.path.join(HERE, 'assets', 'monsters')

# element -> (parentA, parentB)
PAIRS = {
    'plasma':     ('fire', 'lightning'),
    'frostfire':  ('fire', 'ice'),
    'thunder':    ('water', 'lightning'),
    'glacier':    ('water', 'ice'),
    'crystal':    ('earth', 'lightning'),
    'permafrost': ('earth', 'ice'),
    'storm':      ('wind', 'lightning'),
    'blizzard':   ('wind', 'ice'),
    'hail':       ('lightning', 'ice'),
}

def existing_ids():
    ids = set()
    for root, _, files in os.walk(HERE):
        for f in files:
            if f.endswith('.meta'):
                try:
                    txt = io.open(os.path.join(root, f), encoding='utf-8').read()
                except Exception:
                    continue
                for line in txt.splitlines():
                    line = line.strip()
                    if line.startswith('id:'):
                        ids.add(line[3:].strip())
    return ids

def new_id(existing):
    while True:
        v = '%08x' % random.randint(0, 0xFFFFFFFF)
        if v not in existing:
            existing.add(v)
            return v

def blend_pair(a_name, b_name, lv):
    pa = os.path.join(MON, '%s%d.png' % (a_name, lv))
    pb = os.path.join(MON, '%s%d.png' % (b_name, lv))
    ia = Image.open(pa).convert('RGBA')
    ib = Image.open(pb).convert('RGBA')
    w, h = max(ia.width, ib.width), max(ia.height, ib.height)
    ia = ia.resize((w, h), Image.LANCZOS)
    ib = ib.resize((w, h), Image.LANCZOS)
    out = Image.blend(ia, ib, 0.5)
    # subtle hue per level so each level reads distinct
    shift = (lv - 1) * 10
    if shift:
        out = ImageOps.colorize(out.convert('L'), (30, 20, 40), (255, 235, 230)).convert('RGBA')
        # tint-blend back: keep blend result, apply hue via HSV rotation
        hsv = out.convert('HSV')
        hh, ss, vv = hsv.split()
        import colorsys
        px = out.load()
        for y in range(out.height):
            for x in range(out.width):
                r, g, b, a = px[x, y]
                if a < 8:
                    continue
                hh2, ss2, vv2 = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)
                hh2 = (hh2 + shift / 360.0) % 1.0
                r2, g2, b2 = colorsys.hsv_to_rgb(hh2, ss2, vv2)
                px[x, y] = (int(r2 * 255), int(g2 * 255), int(b2 * 255), a)
    return out

def main():
    ids = existing_ids()
    made = 0
    for el, (a, b) in PAIRS.items():
        for lv in range(1, 9):
            img = blend_pair(a, b, lv)
            base = os.path.join(MON, '%s%d.png' % (el, lv))
            img.save(base)
            meta = base + '.meta'
            with io.open(meta, 'w', encoding='utf-8', newline='\n') as f:
                f.write('id: %s\nkind: texture\nversion: 1\nfilter: linear\n' % new_id(ids))
            made += 1
            print('  %s%d.png' % (el, lv))
    print('OK generated %d hybrid textures' % made)

main()
