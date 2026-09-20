"""Render the pixel art in src/Sprites.js and src/Foods.js to PNGs for the docs.

    python tools/docs/render_art.py          # writes docs/art/*.png

Needs Node (to read the QML-flavoured JS files) and Pillow.
"""
import json, pathlib, subprocess
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "docs" / "art"
NODE = r"""
const fs = require('fs'), src = (f) => 'var SF = { W: 64, H: 32, MOUTH: {}, FORMS: {} };' + fs.readFileSync(f, 'utf8').replace('.pragma library', '').replace(/^\.import.*$/mg, '');
const load = (f, names) => new Function(src(f) + '; return {' + names + '}')();
const S = load(process.argv.slice(-2)[0], 'FRAMES, COLORS, palette');
const F = load(process.argv.slice(-2)[1], 'ART, PAL, KINDS');
const X = load(process.argv.slice(-2)[0].replace('Sprites', 'SpritesForms'), 'FORMS');
const B = load(process.argv.slice(-2)[1].replace('Foods', 'Badges'), 'LIST, ART');
const pal = {}; for (const c of Object.keys(S.COLORS)) pal[c] = S.palette(c, false);
console.log(JSON.stringify({ frames: S.FRAMES, pal, food: F.ART, foodPal: F.PAL, kinds: F.KINDS, badges: B.LIST, badgeArt: B.ART, xl: X.FORMS }));
"""

def hexrgb(h):
    if h.startswith("rgb"):
        return tuple(int(float(v)) for v in h[h.index("(") + 1:h.index(")")].split(",")[:3]) + (255,)
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)

def dark(h, f): return "#%02x%02x%02x" % tuple(int(int(h[i:i + 2], 16) * f) for i in (1, 3, 5))
def light(h, f): return "#%02x%02x%02x" % tuple(int(int(h[i:i + 2], 16) + (255 - int(h[i:i + 2], 16)) * f) for i in (1, 3, 5))

def draw(img, rows, pal, ox, oy, scale):
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in pal:
                px = Image.new("RGBA", (scale, scale), hexrgb(pal[ch]))
                img.paste(px, (ox + x * scale, oy + y * scale))

def sheet(cells, scale, pad=8, cols=None):
    """cells: list of (rows, palette). Returns a transparent contact sheet."""
    cols = cols or len(cells)
    w = max(len(c[0][0]) for c in cells) * scale
    h = max(len(c[0]) for c in cells) * scale
    n = (len(cells) + cols - 1) // cols
    img = Image.new("RGBA", (cols * (w + pad) + pad, n * (h + pad) + pad), (0, 0, 0, 0))
    for i, (rows, pal) in enumerate(cells):
        draw(img, rows, pal, pad + (i % cols) * (w + pad), pad + (i // cols) * (h + pad), scale)
    return img

def main():
    data = json.loads(subprocess.check_output(
        ["node", "-e", NODE, "--", str(ROOT / "src/Sprites.js"), str(ROOT / "src/Foods.js")], text=True))
    OUT.mkdir(parents=True, exist_ok=True)
    fr, pal = data["frames"], data["pal"]
    sheet([(fr["egg"]["idle"][0], pal["red"])] + [(fr[str(s)]["idle"][0], pal["red"]) for s in (0, 1, 2)], 8).save(OUT / "evolution.png")
    skel = dict(pal["red"], o="#1c1c22", m="#d6d8cc", d="#969a8c", h="#f0f2ea", l="#e8eae0", b="#32323a", a="#7dffcf", w="#b4b6aa", f="#7dffb0")
    extra = dict(c="#f2f6ff", g="#8b97b5", u="#4aa8e8", s="#2d6fb8", n="#ffd23f", q="#c9a227")
    sheet([(data["xl"][f]["walk"][2], dict(skel if f == "skeleton" else pal["red"], **extra)) for f in ("celestial", "spiritual", "earth", "treasure", "skeleton")], 6, cols=2).save(OUT / "final-forms.png")
    sheet([(fr["2"]["idle"][0], pal[c]) for c in pal], 6).save(OUT / "colors.png")
    sheet([(data["food"][k], data["foodPal"]) for k in data["kinds"] + ["poop"]], 8).save(OUT / "foods.png")
    badge_pal = lambda t: {"o": dark(t, .55), "h": light(t, .6), "l": t, "m": dark(t, .75), "L": "#4fb85a", "y": "#ffe27a", "w": "#ffffff", "k": "#4a3626", "r": "#e8484f"}
    sheet([(data["badgeArt"][b["id"]], badge_pal(b["color"])) for b in data["badges"]], 8, cols=7).save(OUT / "badges.png")
    for s in (0, 1, 2):
        sheet([(fr[str(s)]["walk"][i], pal["red"]) for i in range(8)], 6).save(OUT / f"walk-stage{s}.png")
    print("wrote", *sorted(p.name for p in OUT.glob("*.png")))

if __name__ == "__main__":
    main()
