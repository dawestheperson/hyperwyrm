"""Generate the Celestial Dragon (the fourth form): a 64x64 long eastern dragon.

    python tools/sprites/celestial.py [preview.png]      # writes src/SpritesXL.js

A long S-curved body with scale texture, four clawed legs, a flowing mane, whiskers, antlers,
a beard and a plume tail, with a small pearl floating under its chin. Same palette letters as
Sprites.js (o outline, m body, d shade, h highlight, l pale, b belly, a accent, t claw, e/k eye).
"""
import json, math, os, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
N = 64

class Canvas:
    def __init__(s): s.g = [['.'] * N for _ in range(N)]
    def px(s, x, y, c):
        x = int(math.floor(x)); y = int(math.floor(y))
        if 0 <= x < N and 0 <= y < N: s.g[y][x] = c
    def get(s, x, y): return s.g[y][x] if 0 <= x < N and 0 <= y < N else '.'
    def ell(s, cx, cy, rx, ry, c, only=None):
        for y in range(max(0, int(cy - ry - 1)), min(N, int(cy + ry + 2))):
            for x in range(max(0, int(cx - rx - 1)), min(N, int(cx + rx + 2))):
                if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 <= 1 and (only is None or s.g[y][x] in only): s.g[y][x] = c
    def rect(s, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1): s.px(x, y, c)
    def line(s, x0, y0, x1, y1, c, th=1.0, th1=None):
        th1 = th if th1 is None else th1
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n; r = (th + (th1 - th) * t) / 2
            s.ell(x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, max(r, .5), max(r, .5), c)
    def bez(s, p0, p1, p2, c, th0, th1, steps=30):
        for i in range(steps + 1):
            t = i / steps
            x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
            y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
            r = (th0 + (th1 - th0) * t) / 2
            s.ell(x, y, max(r, .5), max(r, .5), c)
    def poly(s, pts, c):
        ys = [p[1] for p in pts]; xs = [p[0] for p in pts]
        for y in range(max(0, int(min(ys))), min(N, int(max(ys)) + 1)):
            for x in range(max(0, int(min(xs))), min(N, int(max(xs)) + 1)):
                px, py = x + .5, y + .5; inside = False; j = len(pts) - 1
                for i in range(len(pts)):
                    xi, yi = pts[i]; xj, yj = pts[j]
                    if (yi > py) != (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi + 1e-9) + xi: inside = not inside
                    j = i
                if inside: s.g[y][x] = c
    def rows(s): return [''.join(r) for r in s.g]

def shade(cv):
    g = cv.g; out = [r[:] for r in g]
    for y in range(N):
        for x in range(N):
            if g[y][x] != 'm': continue
            if cv.get(x, y - 1) == '.' or cv.get(x - 1, y) == '.': out[y][x] = 'h'
            if cv.get(x, y + 1) == '.' or cv.get(x + 1, y) == '.': out[y][x] = 'd'
    cv.g = out

def outline(cv, skip='fy'):
    g = cv.g; out = [r[:] for r in g]
    for y in range(N):
        for x in range(N):
            if g[y][x] != '.': continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                c = cv.get(x + dx, y + dy)
                if c != '.' and c != 'o' and c not in skip: out[y][x] = 'o'; break
    cv.g = out

# ---- the body path: a long horizontal S-curve, tail at the left, head at the upper right ---------
BASE = [(4, 27), (6, 38), (13, 46), (21, 44), (28, 49), (36, 46), (42, 41), (46, 34), (46, 27)]
def catmull(pts, per=10):
    out = []
    P = [pts[0]] + pts + [pts[-1]]
    for i in range(1, len(P) - 2):
        p0, p1, p2, p3 = P[i - 1], P[i], P[i + 1], P[i + 2]
        for k in range(per):
            t = k / per
            out.append(tuple(0.5 * ((2 * p1[a]) + (-p0[a] + p2[a]) * t + (2 * p0[a] - 5 * p1[a] + 4 * p2[a] - p3[a]) * t * t + (-p0[a] + 3 * p1[a] - 3 * p2[a] + p3[a]) * t ** 3) for a in (0, 1)))
    out.append(pts[-1])
    return out
def thick(s):        # a slim tail tip, a long even body, a slightly thinner neck
    if s < 0.15: return 1.4 + s / 0.15 * 2.6
    if s < 0.7: return 4.0 + (s - 0.15) / 0.55 * 1.8
    return 5.8 - (s - 0.7) / 0.3 * 1.2

def body_points(ph, amp, breathe=0.0):
    pts = []
    base = catmull(BASE)
    n = len(base)
    for i, (x, y) in enumerate(base):
        s = i / (n - 1)
        wob = amp * math.sin(7.0 * s - ph) * (1 - s * 0.7)
        pts.append((x, y + wob + breathe * (0.5 if s > 0.6 else 0), s))
    return pts

def draw_head(cv, hx, hy, ph, asleep=False, mouth=0):
    # antlers, branching back and up
    for k, (dx, dy, spread) in enumerate(((-2, -3, -1), (1, -4, 2))):
        cv.bez((hx + dx, hy + dy), (hx + dx - 2 + spread, hy + dy - 6), (hx + dx - 6 + spread * 2, hy + dy - 9 + math.sin(ph + k) * 0.6), 'a', 2.0, 0.8)
        cv.bez((hx + dx - 2, hy + dy - 5), (hx + dx - 5, hy + dy - 7), (hx + dx - 8, hy + dy - 6), 'a', 1.3, 0.6)
    # a pale, feathery mane sweeping back from the head
    for i in range(9):
        oy = -5 + i * 1.7; sway = math.sin(ph + i * 0.8) * 1.3
        cv.bez((hx - 2, hy + oy), (hx - 8, hy + oy - 2 + sway), (hx - 14 + sway, hy + oy + 3 + i * 0.8), 'l' if i % 2 else 'a', 2.6, 0.8)
    cv.ell(hx, hy, 6.2, 4.8, 'm')
    cv.poly([(hx + 1, hy - 3.6), (hx + 12, hy - 2.4), (hx + 13, hy + 0.6), (hx + 11, hy + 2.6), (hx + 1, hy + 4.4)], 'm')
    cv.px(hx + 12, hy - 2, '.'); cv.px(hx + 13, hy - 2, '.')
    cv.rect(hx + 3, hy + 1.6, hx + 12, hy + 2.0, 'd')
    if mouth:
        cv.poly([(hx + 4, hy + 2), (hx + 12, hy + 2), (hx + 10, hy + 6.5), (hx + 3, hy + 5.2)], 'm')
        cv.rect(hx + 5, hy + 2.6, hx + 11, hy + 4.0, 'd')
        for tx in (hx + 6, hx + 8, hx + 10): cv.px(tx, hy + 2.6, 't')
    cv.rect(hx + 10, hy - 1.5, hx + 11, hy - 0.5, 'k')
    cv.rect(hx + 1, hy - 4, hx + 5, hy - 3, 'd')
    if asleep: cv.rect(hx + 1, hy - 1.5, hx + 4, hy - 1.5, 'k')
    else:
        cv.rect(hx + 1, hy - 2.5, hx + 3, hy - 0.5, 'e'); cv.rect(hx + 2, hy - 1.8, hx + 3, hy - 0.5, 'k')
    # long, thin whiskers curling forward and down, waving
    for k, oy in enumerate((0.6, 2.2)):
        cv.bez((hx + 10, hy + oy), (hx + 17 + math.sin(ph + k) * 2, hy + oy + 3), (hx + 15, hy + oy + 11 + math.sin(ph * 1.3 + k) * 1.5), 'd', 0.9, 0.5)
    cv.bez((hx + 8, hy + 4), (hx + 9, hy + 8), (hx + 5, hy + 12 + math.sin(ph)), 'a', 1.8, 0.7)      # beard

def draw_leg(cv, x, y, dx, dy, col):
    """A short, thin, clawed leg splayed out, like the reference; (dx, dy) is where the paw goes."""
    ex, ey = x + dx, y + dy
    kx, ky = (x + ex) / 2, (y + ey) / 2 + 1.2
    cv.line(x, y, kx, ky, col, 2.6, 2.2); cv.line(kx, ky, ex, ey, col, 2.2, 1.8)
    for cx, cy in ((ex + 3, ey + 2.5), (ex + 3.5, ey - 0.5), (ex - 2.5, ey + 3), (ex + 0.5, ey + 4)): cv.line(ex, ey, cx, cy, 't', 1.0, 0.8)

def dragon(ph=0.0, mode='idle', breathe=0.0, asleep=False, mouth=0, fire=False):
    cv = Canvas()
    amp = {'walk': 4.2, 'idle': 2.6, 'fire': 1.6}.get(mode, 2.6)
    if asleep: amp = 0.8
    pts = body_points(ph, amp, breathe)
    n = len(pts)
    tx, ty, _ = pts[0]
    # the plume: a tall fan of pale strokes with a red stripe, rising from the tail tip
    for k in range(11):
        a = -math.pi / 2 - 0.95 + k * 0.19 + math.sin(ph + k * 0.7) * 0.12
        L = 21 - abs(k - 5) * 1.5
        cv.bez((tx, ty), (tx + math.cos(a) * L * 0.5 - 1, ty + math.sin(a) * L * 0.6), (tx + math.cos(a) * L, ty + math.sin(a) * L), 'a' if k % 2 else 'l', 2.4, 0.7)
    cv.bez((tx, ty), (tx + 1, ty - 9), (tx + 3 + math.sin(ph) * 1.2, ty - 17), 'm', 1.8, 0.8)
    # back spikes along the body
    for i in range(8, n - 6, 4):
        x, y, s = pts[i]
        h = 2.6 + 2.4 * s
        cv.poly([(x - 1.6, y - thick(s) / 2 + 1), (x + 1.6, y - thick(s) / 2 + 1), (x - 1.6, y - thick(s) / 2 - h)], 'a')
    sw = math.sin(ph) * 1.8 if mode == 'walk' else 0
    far = [(int(n * 0.30), (-5, 7 + sw)), (int(n * 0.72), (5, 7 - sw))]
    near = [(int(n * 0.34), (4, 8 - sw)), (int(n * 0.68), (-5 + sw, 8))]
    for idx, d in far:
        x, y, s = pts[idx]; draw_leg(cv, x, y + 1, d[0], d[1], 'd')
    for x, y, s in pts: cv.ell(x, y, thick(s) / 2 + 0.3, thick(s) / 2 + 0.3, 'm')
    for x, y, s in pts[:int(n * 0.88)]:                                              # belly plates
        if s > 0.14: cv.ell(x + 0.3, y + thick(s) * 0.3, thick(s) * 0.3, thick(s) * 0.14, 'b')
    for y in range(N):                                                               # bright orange and yellow speckles on red scales
        for x in range(N):
            if cv.g[y][x] == 'm':
                if (x * 3 + y * 5) % 7 == 0: cv.g[y][x] = 'l'
                elif (x * 5 + y * 3) % 9 == 0: cv.g[y][x] = 'a'
                elif (x + 2 * y) % 6 == 0: cv.g[y][x] = 'h'
                elif (x - 2 * y) % 6 == 0: cv.g[y][x] = 'd'
    for idx, d in near:
        x, y, s = pts[idx]; draw_leg(cv, x, y + 1, d[0], d[1], 'm')
    for i in range(int(n * 0.80), n - 2, 3):                                         # mane down the neck
        x, y, sp = pts[i]; sway = math.sin(ph + i * 0.5) * 1.4
        cv.poly([(x - thick(sp) / 2, y - 1.2), (x - thick(sp) / 2 - 6 + sway, y - 3.6 + sway), (x - thick(sp) / 2 + 1, y + 1.4)], 'l')
    hx, hy, _ = pts[-1]
    draw_head(cv, hx + 2, hy - 2 + (-2 if fire else 0), ph, asleep, mouth)
    px_, py_ = 14, 57 + math.sin(ph * 1.2) * 1.0                                      # the pearl, bobbing below
    cv.ell(px_, py_, 3.2, 3.2, 'f'); cv.ell(px_, py_, 2.1, 2.1, 'y'); cv.px(px_ - 1, py_ - 1, 'e')
    for sx, sy in ((px_ - 6, py_ - 1), (px_ + 6, py_ + 1), (px_, py_ - 6)): cv.px(sx, sy, 'y')
    shade(cv); outline(cv)
    return cv.rows()

def spiral(ph=0.0, breathe=0):
    """Resting pose: coiled up in loops, the head laid on top."""
    cv = Canvas()
    pts = []
    for i in range(0, 140):
        s = i / 139; a = -0.3 + s * 3 * math.pi
        r = 22 - s * 13
        pts.append((32 + math.cos(a) * r * 1.35, 47 + math.sin(a) * r * 0.42 - s * 6, s))
    for x, y, s in pts: cv.ell(x, y, (2.0 + 4.5 * s) / 1 * 0.9 + 0.3, (2.0 + 4.5 * s) * 0.9 + 0.3, 'm')
    for y in range(N):
        for x in range(N):
            if cv.g[y][x] == 'm':
                if (x + 2 * y) % 6 == 0: cv.g[y][x] = 'h'
                elif (x - 2 * y) % 6 == 0: cv.g[y][x] = 'd'
    cv.poly([(4, 52), (12, 45), (14, 54)], 'a')
    draw_head(cv, 34, 30 + breathe, ph, True, 0)
    shade(cv); outline(cv)
    return cv.rows()

def build():
    walk = [dragon(i / 8 * 2 * math.pi, 'walk') for i in range(8)]
    idle = [dragon(0.0, 'idle', 0), dragon(0.8, 'idle', 0.6), dragon(1.6, 'idle', 0), dragon(2.4, 'idle', 0)]
    sleep = [dragon(0.0, 'idle', 0, True), dragon(0.8, 'idle', 0.6, True)]
    curl = [spiral(0.0, 0), spiral(0.8, 1)]
    fire = [dragon(0.0, 'fire', 0), dragon(0.5, 'fire', 0.4, False, 0, True), dragon(1.0, 'fire', 0, False, 1, True), dragon(1.5, 'fire', 0, False, 1, True)]
    return {'walk': walk, 'idle': idle, 'sleep': sleep, 'curl': curl, 'fire': fire}

if __name__ == '__main__':
    data = build()
    with open(os.path.join(ROOT, 'src', 'SpritesXL.js'), 'w') as f:
        f.write('.pragma library\n\n// 64x64 frames of the fourth form (Celestial Dragon). Generated by tools/sprites/celestial.py;\n'
                '// same palette characters as Sprites.js.\nvar SIZE = 64\nvar FRAMES = ' + json.dumps(data, separators=(',', ':')) + '\n')
    if len(sys.argv) > 1:
        from PIL import Image
        pal = {'o': (20, 14, 16), 'm': (226, 71, 58), 'd': (140, 32, 34), 'h': (255, 120, 100), 'l': (255, 232, 170), 'b': (255, 214, 150),
               'a': (255, 200, 110), 't': (245, 245, 235), 'e': (255, 255, 255), 'k': (16, 16, 24), 'f': (255, 138, 36), 'y': (255, 226, 122)}
        frames = data['walk'][:4] + data['idle'][:1] + data['fire'][2:3] + data['curl'][:1] + data['sleep'][:1]
        S = 4; cols = 4; rows = (len(frames) + cols - 1) // cols
        img = Image.new('RGB', (cols * (N * S + 8) + 8, rows * (N * S + 8) + 8), (40, 44, 52))
        for k, fr in enumerate(frames):
            ox = 8 + (k % cols) * (N * S + 8); oy = 8 + (k // cols) * (N * S + 8)
            for y, row in enumerate(fr):
                for x, ch in enumerate(row):
                    if ch in pal: img.paste(pal[ch], (ox + x * S, oy + y * S, ox + x * S + S, oy + y * S + S))
        img.save(sys.argv[1])
    print('wrote src/SpritesXL.js')
