"""Generate the five stage-3 forms (64x32 frames) as src/SpritesForms.js.

    python tools/sprites/forms.py [preview.png]

Each form is a long serpentine dragon built with serp.py (stage 3: twice as long as the others)
plus its own adornments: celestial (clouds, halo), spiritual (storm, lightning, rain),
earth (fins, water), treasure (coins, gems, a hoard) and skeleton (bones, ribs, ghost fire).
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

# ---------------------------------------------------------------- celestial (Tianlong)
def cel_adorn(cv, pts, ph, mode, head):
    for i in range(6):                                          # clouds carrying it along, under the belly
        (x, y), t, s = spot(pts, 0.12 + i * 0.15)
        blob(cv, x + math.sin(ph + i) * 0.8, y + t / 2 + 2.2, 2.0 + (i % 2) * 0.8, 'c', 'c'); cv.px(x, y + t / 2 + 3.6, 'g')
    (x, y), t, s = spot(pts, 0.08)                              # a long silk ribbon streaming back from the neck
    cv.bez((x - 2, y - 1), (x - 12, y - 8 + math.sin(ph) * 2), (x - 26 + math.sin(ph + 1) * 2, y - 3), 'c', 2.4, 0.8)
def cel_post(cv, pts, ph, mode, head):
    hx, hy = head
    for a in range(0, 360, 12):                                 # a golden halo behind the head
        px = hx + 1 + 9.5 * math.cos(math.radians(a)); py = hy - 1 + 8.5 * math.sin(math.radians(a))
        if cv.get(int(px), int(py)) == '.' and math.sin(math.radians(a) * 2 + ph) > -0.5: cv.px(px, py, 'n')
    for i, (dx, dy) in enumerate(((-12, -9), (12, -8), (-6, 12), (4, -13))):
        if math.sin(ph * 2 + i * 1.7) > 0.1: cv.px(hx + dx, hy + dy, 'y')

# ---------------------------------------------------------------- spiritual (Shenlong)
def spi_adorn(cv, pts, ph, mode, head):
    for i in range(5):                                          # a storm cloud riding on its back
        (x, y), t, s = spot(pts, 0.25 + i * 0.13)
        blob(cv, x + math.sin(ph * 0.7 + i) * 1.2, y - t / 2 - 3.6 - (i % 2), 3.0 + (i % 2), 'g', 'c')
    (x, y), t, s = spot(pts, 0.85)                              # a swirl of wind at the tail
    cv.bez((x - 3, y), (x - 8, y - 6 + math.sin(ph) * 2), (x - 3, y - 10), 'c', 1.4, 0.6)
def spi_post(cv, pts, ph, mode, head):
    hx, hy = head
    (x, y), t, s = spot(pts, 0.4)
    if math.sin(ph * 2) > -0.2:                                 # a fork of lightning
        lx, ly = x + 2, y - t / 2 - 6
        for dx, dy in ((0, 0), (-1, 2), (1, 3), (-1, 5), (0, 7)): cv.px(lx + dx, ly + dy, 'y')
    for i in range(9):                                          # rain, slanting down
        rx = (i * 7 + int(ph * 4)) % 64; ry = (i * 5 + int(ph * 9 + i * 3)) % 30
        if cv.get(rx, ry) == '.': cv.px(rx, ry, 'u'); cv.px(rx - 1, ry + 1, 'u')

# ---------------------------------------------------------------- earth (Dilong)
def ear_adorn(cv, pts, ph, mode, head):
    for i in range(3, len(pts) - 8, 5):                         # fish-like fins along the back
        (x, y), t, s = pts[i]
        cv.poly([(x - 2.4, y - t / 2 + 1), (x + 1.6, y - t / 2 + 1), (x - 1.0, y - t / 2 - 4 - math.sin(ph + i) * 0.6)], 'u')
        cv.px(x - 1, y - t / 2 - 1, 's')
def ear_post(cv, pts, ph, mode, head):
    for x in range(64):                                         # a stream flowing along the ground
        y = 30 + int(round(math.sin(x * 0.55 - ph * 2) * 0.9))
        for yy in (y, y + 1):
            if 0 <= yy < 32 and cv.get(x, yy) == '.': cv.px(x, yy, 'u' if yy == y else 's')
        if x % 6 == int(ph * 2) % 6 and cv.get(x, y - 1) == '.': cv.px(x, y - 1, 'c')
    for i in range(4):
        dx = (i * 17 + int(ph * 5)) % 60 + 2; dy = 24 - int(abs(math.sin(ph + i)) * 6)
        if cv.get(dx, dy) == '.': cv.px(dx, dy, 'c')

# ---------------------------------------------------------------- treasure (Fuzanglong)
def tre_adorn(cv, pts, ph, mode, head): pass
def tre_post(cv, pts, ph, mode, head):
    hx, hy = head
    for y in range(32):                                         # coin scales
        for x in range(64):
            if cv.g[y][x] in 'mh' and (x * 3 + y * 5) % 8 == 0: cv.g[y][x] = 'n'
            elif cv.g[y][x] == 'l': cv.g[y][x] = 'n'
    cv.px(hx + 3, hy - 3, 'f'); cv.px(hx + 3, hy - 4, 'e')       # a gem in the brow
    for i in range(14):                                         # its hoard
        x = 3 + i; y = 30 - int(3 * math.exp(-((i - 6) / 4.5) ** 2))
        for yy in range(y, 32):
            if cv.get(x, yy) == '.': cv.px(x, yy, 'n' if (x + yy) % 3 else 'q')
    for gx, gy, c in ((6, 27, 'f'), (9, 28, 'u'), (4, 29, 'f')): cv.px(gx, gy, c)
    for i, (dx, dy) in enumerate(((5, 24), (10, 26), (2, 27))):
        if math.sin(ph * 2 + i * 2.1) > 0.2: cv.px(dx, dy, 'y')

# ---------------------------------------------------------------- skeleton
def ske_adorn(cv, pts, ph, mode, head): pass
def ske_post(cv, pts, ph, mode, head):
    hx, hy = head
    for y in range(32):                                         # ribs: dark gaps across the body
        for x in range(64):
            if cv.g[y][x] in 'mhl' and x % 4 == 1 and 12 < x < 50: cv.g[y][x] = 'b'
    for (x, y), t, s in pts[6:int(len(pts) * 0.9):3]:           # a bare spine
        if cv.get(int(x), int(y - t / 2)) in 'mhdo.': cv.px(int(x), int(y - t / 2), 'l')
    cv.rect(hx + 1, hy - 3, hx + 3, hy - 1, 'k'); cv.px(hx + 2, hy - 2, 'f')      # hollow, glowing eye socket
    for x in range(int(hx) + 3, int(hx) + 9):
        if cv.get(x, int(hy) + 2) != '.': cv.px(x, int(hy) + 2, 't' if x % 2 else 'k')  # teeth

FORMS = {'celestial': (cel_adorn, cel_post), 'spiritual': (spi_adorn, spi_post), 'earth': (ear_adorn, ear_post),
         'treasure': (tre_adorn, tre_post), 'skeleton': (ske_adorn, ske_post)}

def build(form):
    adorn, post = FORMS[form]
    ang = lambda i, n: i / n
    walk = [S.serp(3, ang(i, 8), 'walk', adorn=adorn, post=post) for i in range(8)]
    idle = [S.serp(3, 0.0, 'idle', breathe=0, adorn=adorn, post=post), S.serp(3, 0.25, 'idle', breathe=1, adorn=adorn, post=post),
            S.serp(3, 0.5, 'idle', breathe=0, adorn=adorn, post=post), S.serp(3, 0.75, 'idle', breathe=0, blink=True, adorn=adorn, post=post)]
    sleep = [S.serp(3, 0.0, 'idle', asleep=True, adorn=adorn, post=post), S.serp(3, 0.3, 'idle', breathe=1, asleep=True, adorn=adorn, post=post)]
    curl = [S.curl(3, 0, adorn, post), S.curl(3, 1, adorn, post)]
    fire = []
    for k in range(4): fire.append(S.serp(3, k * 0.1, 'fire', fire=k, adorn=adorn, post=post))
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
        skel = dict(pal, m=(214, 216, 204), d=(150, 153, 140), h=(240, 242, 234), l=(232, 234, 224), b=(50, 50, 58), a=(125, 255, 207), w=(180, 182, 170), f=(125, 255, 176))
        names = list(FORMS); S_ = 4; cols = 2; rows = 3
        img = Image.new('RGB', (cols * (64 * S_ + 8) + 8, rows * (32 * S_ + 8) + 8), (40, 44, 52))
        for k, nm in enumerate(names):
            fr = data[nm]['walk'][2]; p = skel if nm == 'skeleton' else pal
            ox = 8 + (k % cols) * (64 * S_ + 8); oy = 8 + (k // cols) * (32 * S_ + 8)
            for y, row in enumerate(fr):
                for x, ch in enumerate(row):
                    if ch in p: img.paste(p[ch], (ox + x * S_, oy + y * S_, ox + x * S_ + S_, oy + y * S_ + S_))
        img.save(sys.argv[1])
    print('wrote src/SpritesForms.js; fire mouth', mouth)
