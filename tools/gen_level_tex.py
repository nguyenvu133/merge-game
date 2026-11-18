# Regenerates monster textures for levels 2..8 of ALL 21 elements keeping the
# ORIGINAL level-1 color (user: "L6 bị mất mầu" — the old hue-rotate pass
# shifted each level to a totally different hue). New look: same hue, slightly
# brighter per level so levels still read as distinct evolutions.
import io
import os

from PIL import Image, ImageEnhance

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MON = os.path.join(HERE, 'assets', 'monsters')

ELEMENTS = ['fire', 'water', 'earth', 'wind', 'lightning', 'ice', 'steam', 'lava',
            'ember', 'mud', 'mist', 'dust', 'plasma', 'frostfire', 'thunder',
            'glacier', 'crystal', 'permafrost', 'storm', 'blizzard', 'hail']

def main():
    made = 0
    for el in ELEMENTS:
        p1 = os.path.join(MON, '%s1.png' % el)
        if not os.path.exists(p1):
            print('  skip (no L1):', el)
            continue
        base = Image.open(p1).convert('RGBA')
        for lv in range(2, 9):
            # brightness grows gently with level (1.00 -> 1.35), hue untouched
            img = ImageEnhance.Brightness(base).enhance(1.0 + 0.05 * (lv - 1))
            out = os.path.join(MON, '%s%d.png' % (el, lv))
            img.save(out)
            made += 1
        print('  %s L2-8 done' % el)
    print('OK regenerated %d level textures (original colors kept)' % made)

main()
