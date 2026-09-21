"""Generate the five stage-3 forms (64x32 frames) as src/SpritesForms.js.

    python tools/sprites/forms.py [preview.png]

Each form is a long serpentine dragon built with serp.py (stage 3: twice as long as the others)
plus its own adornments: celestial (halo; sleeps on a cloud), spiritual (a ghost), earth (bark, vines and leaves),
treasure (a body of gold coins, rubies and sapphires; sleeps on a pile of gold) and zombie.
"""
import json, math, os, sys
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
import kit
kit.W, kit.H = 64, 32
import serp as S
from kit import Canvas

ROOT = os.path.abspath(os.path.join(HERE, '..', '..'))
S.CFG[3] = dict(x0=51.0, L=47.0, y0=11.0, drop=9.0, amp=4.2, k=2.6, th0=8.6, th1=1.7, N=110,
                legs=[(0.16, 'd'), (0.23, 'm'), (0.52, 'd'), (0.60, 'm')], ground=None, mane=2, tail_flame=True)

def spot(pts, s):                      # the body point nearest s (0 head .. 1 tail)
    return pts[max(0, min(len(pts) - 1, int(s * (len(pts) - 1))))]

def blob(cv, x, y, r, c, hi=None):
    cv.ell(x, y, r * 1.25, r, c)
    if hi: cv.ell(x - r * 0.3, y - r * 0.35, r * 0.6, r * 0.45, hi)

def body_cols(pts):
    """column -> (centre y, thickness) of the body, from the path points."""
    cols = {}
    for (x, y), t, s in pts:
        cols[int(x)] = (y, t)
    return cols

def bed(cv, kind):
    """What it sleeps on: a puffy cloud (celestial) or a mound of gold coins (treasure), under and around the body."""
    if kind == 'cloud':
        blobs = [(8, 28.5, 7, 3.6), (18, 27.2, 8, 4.4), (30, 26.6, 9, 5.0), (42, 27.4, 8, 4.4), (53, 28.4, 7, 3.6), (26, 29.6, 12, 3), (40, 29.8, 12, 3)]
        for cx, cy, rx, ry in blobs:
            cv.ell(cx, cy, rx, ry, 'c', only='.')
        for y in range(20, 32):                                  # shade the underside of the cloud
            for x in range(64):
                if cv.get(x, y) == 'c' and cv.get(x, y + 1) in ('.', 'g') and y >= 29: cv.px(x, y, 'g')
                elif cv.get(x, y) == 'c' and y >= 30: cv.px(x, y, 'g')
    else:
        for x in range(4, 60):
            top = 31 - int(6 * math.exp(-((x - 32) / 17.0) ** 2) + 1.2 * math.sin(x * 0.9))
            for y in range(top, 32):
                if cv.get(x, y) != '.': continue
                cv.px(x, y, 'n' if (x + y) % 3 else 'q')
        for gx, gy, c in ((16, 29, 'f'), (24, 27, 'u'), (32, 26, 'f'), (40, 27, 'u'), (47, 29, 'f'), (28, 27, 'y'), (37, 26, 'y')): cv.px(gx, gy, c)

# ---------------------------------------------------------------- celestial (Tianlong): sky dragon, halo, sleeps on a cloud
def cel_adorn(cv, pts, ph, mode, head):
    hx, hy = head                                               # a solid golden halo ring, glowing behind the head
    cx, cy = hx + 1.0, hy - 0.5
    for a in range(0, 360, 2):
        for r in (8.6, 9.6):
            x = cx + r * math.cos(math.radians(a)); y = cy + r * 0.95 * math.sin(math.radians(a))
            cv.px(x, y, 'n')
    for a in range(200, 300, 2):                                # a bright highlight along the upper left
        cv.px(cx + 9.1 * math.cos(math.radians(a)), cy + 9.1 * 0.95 * math.sin(math.radians(a)), 'y')
def cel_post(cv, pts, ph, mode, head):
    hx, hy = head
    for i, (dx, dy) in enumerate(((-12, -9), (12, -8), (-6, 12), (4, -13))):
        if math.sin(ph * 2 + i * 1.7) > 0.1: cv.px(hx + dx, hy + dy, 'y')
    if mode in ('sleep', 'curl'): bed(cv, 'cloud')

# ---------------------------------------------------------------- spiritual (Shenlong): a ghostly spirit (drawn translucent by the game)
def spi_adorn(cv, pts, ph, mode, head):
    (x, y), t, s = spot(pts, 0.85)                              # a swirl of wind at the tail
    cv.bez((x - 3, y), (x - 8, y - 6 + math.sin(ph) * 2), (x - 3, y - 10), 'c', 1.4, 0.6)
def spi_post(cv, pts, ph, mode, head):
    for i in range(10):                                         # wisps of mist drifting off it
        rx = (i * 11 + int(ph * 6)) % 62 + 1; ry = (i * 7 + int(ph * 5 + i * 3)) % 26 + 2
        if cv.get(rx, ry) == '.': cv.px(rx, ry, 'c')

# ---------------------------------------------------------------- earth (Dilong): bark, vines and leaves
def ear_adorn(cv, pts, ph, mode, head):
    for i in range(3, len(pts) - 8, 4):                         # leaves sprouting along the back
        (x, y), t, s = pts[i]
        sway = math.sin(ph + i * 0.4) * 0.8
        cv.poly([(x - 2.6, y - t / 2 + 1), (x + 0.4, y - t / 2 + 0.6), (x + 1.4 + sway, y - t / 2 - 3.6), (x - 1.6 + sway, y - t / 2 - 4.4)], 'n')
        cv.px(x - 1, y - t / 2 - 1, 'q')
def ear_post(cv, pts, ph, mode, head):
    cols = body_cols(pts)
    for y in range(32):                                         # bark: vertical grain and knots
        for x in range(64):
            if cv.g[y][x] in 'mh':
                if x % 3 == 0 and (y * 2 + x) % 7 < 4: cv.g[y][x] = 'd'
                elif (x * 7 + y * 11) % 31 == 0: cv.g[y][x] = 'o'
    for vine, ph0 in enumerate((0.0, 2.1)):                     # two vines winding round the body, with little leaves
        for x in range(4, 50):
            if x not in cols: continue
            yc, t = cols[x]
            y = yc + math.sin(x * 0.75 + ph0) * t * 0.32
            if cv.get(x, int(y)) not in '.o': cv.px(x, y, 'a')
            if x % 5 == vine and cv.get(x, int(y) - 1) not in '.': cv.px(x, y - 1, 'n'); cv.px(x + 1, y - 2, 'n')

# ---------------------------------------------------------------- treasure (Fuzanglong): gold coins, rubies and sapphires
def tre_adorn(cv, pts, ph, mode, head): pass
def tre_post(cv, pts, ph, mode, head):
    hx, hy = head
    for y in range(32):
        for x in range(64):
            if cv.g[y][x] in 'mhdl':
                cx, cy = x % 4, y % 3
                c = 'l' if (cx, cy) == (1, 1) else ('d' if cx == 0 or cy == 0 else 'm')      # a coin: shine in the middle, dark edges
                if (x * 7 + y * 3) % 23 == 0: c = 'f'                                     # ruby
                elif (x * 3 + y * 7) % 29 == 0: c = 'u'                                   # sapphire
                cv.g[y][x] = c
    cv.px(hx + 3, hy - 3, 'f'); cv.px(hx + 3, hy - 4, 'e')       # a ruby in the brow
    for i, (dx, dy) in enumerate(((-9, -8), (10, -6), (-4, 12))):
        if math.sin(ph * 2 + i * 2.1) > 0.2: cv.px(hx + dx, hy + dy, 'y')
    if mode in ('sleep', 'curl'): bed(cv, 'gold')

# ---------------------------------------------------------------- zombie: rotting, stitched, groaning
def zom_adorn(cv, pts, ph, mode, head): pass
def zom_post(cv, pts, ph, mode, head):
    hx, hy = head
    cols = body_cols(pts)
    for y in range(32):
        for x in range(64):
            if cv.g[y][x] in 'mhd' and (x * 5 + y * 7) % 13 == 0: cv.g[y][x] = 'b'            # rotting patches
    for x in range(22, 46):                                     # exposed ribs on the flank
        if x not in cols or x % 3 != 1: continue
        yc, t = cols[x]
        for yy in range(int(yc - t * 0.1), int(yc + t * 0.4)):
            if cv.get(x, yy) in 'mhdb': cv.px(x, yy, 'l' if yy % 2 == 0 else 'b')
    for x in (12, 30, 47):                                      # crude stitches
        if x in cols:
            yc, t = cols[x]
            for k in range(-2, 3): cv.px(x + (k % 2), yc + k * 1.4, 'k')
    for i in range(3):                                          # ooze dripping
        dy = int((ph * 3 + i * 1.7) % 4)
        cv.px(hx + 7 - i * 2, hy + 6 + dy, 'f')
    cv.px(hx + 2, hy + 1, 'd'); cv.px(hx + 3, hy + 1, 'd')      # heavy bags under the eye

FORMS = {'celestial': (cel_adorn, cel_post), 'spiritual': (spi_adorn, spi_post), 'earth': (ear_adorn, ear_post),
         'treasure': (tre_adorn, tre_post), 'zombie': (zom_adorn, zom_post)}

def build(form):
    adorn, post = FORMS[form]
    asleep = lambda mode: (lambda cv, pts, ph, m, head: adorn(cv, pts, ph, mode, head))
    asleep_post = lambda mode: (lambda cv, pts, ph, m, head: post(cv, pts, ph, mode, head))
    walk = [S.serp(3, i / 8, 'walk', adorn=adorn, post=post) for i in range(8)]
    idle = [S.serp(3, 0.0, 'idle', breathe=0, adorn=adorn, post=post), S.serp(3, 0.25, 'idle', breathe=1, adorn=adorn, post=post),
            S.serp(3, 0.5, 'idle', breathe=0, adorn=adorn, post=post), S.serp(3, 0.75, 'idle', breathe=0, blink=True, adorn=adorn, post=post)]
    if form == 'zombie':                                        # a zombie never sleeps: its "sleep" frames are just idle
        sleep = idle[:2]; curl = idle[:2]
    else:
        sleep = [S.serp(3, 0.0, 'idle', asleep=True, adorn=asleep('sleep'), post=asleep_post('sleep')),
                 S.serp(3, 0.3, 'idle', breathe=1, asleep=True, adorn=asleep('sleep'), post=asleep_post('sleep'))]
        curl = [S.curl(3, 0, asleep('curl'), asleep_post('curl')), S.curl(3, 1, asleep('curl'), asleep_post('curl'))]
    fire = [S.serp(3, k * 0.1, 'fire', fire=k, adorn=adorn, post=post) for k in range(4)]
    return {'walk': walk, 'idle': idle, 'sleep': sleep, 'curl': curl, 'fire': fire}

if __name__ == '__main__':
    data = {f: build(f) for f in FORMS}
    mouth = dict(S.MOUTH)
    with open(os.path.join(ROOT, 'src', 'SpritesForms.js'), 'w') as f:
        f.write('.pragma library\n\n// The five stage-3 forms, 64x32 frames. Generated by tools/sprites/forms.py; do not edit by hand.\n'
                '// celestial, spiritual, earth, treasure, skeleton. Extra palette letters: c cloud, g storm cloud, u water,\n'
                '// s deep water, n gold, q dark gold.\nvar W = 64\nvar H = 32\nvar MOUTH = ' + json.dumps({'x': mouth.get('x', 61), 'y': mouth.get('y', 15)}) +
                '\nvar FORMS = ' + json.dumps(data, separators=(',', ':')) + '\n')
    if len(sys.argv) > 1:
        from PIL import Image
        pal = {'o': (20, 14, 16), 'm': (226, 71, 58), 'd': (140, 32, 34), 'h': (255, 120, 100), 'l': (255, 205, 110), 'b': (255, 214, 150),
               'a': (255, 184, 77), 't': (245, 245, 235), 'e': (255, 255, 255), 'k': (16, 16, 24), 'f': (255, 138, 36), 'y': (255, 226, 122),
               'w': (150, 40, 40), 'c': (242, 246, 255), 'g': (139, 151, 181), 'u': (74, 168, 232), 's': (45, 111, 184), 'n': (255, 210, 63), 'q': (201, 162, 39)}
        skel = pal
        names = list(FORMS); S_ = 4; cols = 2; rows = 3
        img = Image.new('RGB', (cols * (64 * S_ + 8) + 8, rows * (32 * S_ + 8) + 8), (40, 44, 52))
        for k, nm in enumerate(names):
            fr = data[nm]['walk'][2]; p = pal
            ox = 8 + (k % cols) * (64 * S_ + 8); oy = 8 + (k // cols) * (32 * S_ + 8)
            for y, row in enumerate(fr):
                for x, ch in enumerate(row):
                    if ch in p: img.paste(p[ch], (ox + x * S_, oy + y * S_, ox + x * S_ + S_, oy + y * S_ + S_))
        img.save(sys.argv[1])
    print('wrote src/SpritesForms.js; fire mouth', mouth)
