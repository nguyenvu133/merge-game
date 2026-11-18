# Renders a SINGLE boss sprite PNG (rest/idle pose) from the .kine's pixelforge
# parts — so the boss can be shown as a plain .png instead of the Kine2D rig
# (user request: show .png temporarily). Part world positions come straight
# from pixelforge.json part.x/y (canvas center coords), like the old renderer.
import io
import json
import os
import zipfile
import base64
from PIL import Image

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def render_boss(kine_rel, out_rel):
    kine = os.path.join(HERE, kine_rel)
    z = zipfile.ZipFile(kine)
    pix = json.loads(z.read('pixelforge.json'))
    cw = (pix.get('workspace') or {}).get('width') or 960
    ch = (pix.get('workspace') or {}).get('height') or 600
    parts = pix['parts']
    # load images
    imgs = []
    for p in parts:
        src = p.get('src', '')
        if src.startswith('data:image/png;base64,'):
            im = Image.open(io.BytesIO(base64.b64decode(src.split(',', 1)[1]))).convert('RGBA')
        else:
            im = Image.open(io.BytesIO(z.read('assets/' + p['name'] + '.png'))).convert('RGBA')
        imgs.append((p, im))
    # canvas at 2x for quality, then downscale
    canvas = Image.new('RGBA', (cw * 2, ch * 2), (0, 0, 0, 0))
    for p, im in imgs:
        x = p.get('x', cw / 2) * 2
        y = p.get('y', ch / 2) * 2
        w = im.width
        h = im.height
        canvas.paste(im, (int(x - w / 2), int(y - h / 2)), im)
    # crop to non-empty bbox
    bbox = canvas.getbbox()
    if bbox:
        canvas = canvas.crop(bbox)
    canvas = canvas.resize((canvas.width // 2, canvas.height // 2), Image.LANCZOS)
    out = os.path.join(HERE, out_rel)
    canvas.save(out)
    print('OK ->', out_rel, canvas.size)

render_boss('assets/Kine/pixelforge-nguoi-da.kine', 'assets/Kine/boss_nguoi_da.png')
render_boss('assets/Kine/pixelforge-bong-xanh-nuoc.kine', 'assets/Kine/monter3_rig.png')
