"""Generate the head of the Celestial Dragon (the fourth form).

    python tools/sprites/celestial.py [preview.png]      # writes src/SpritesXL.js

A long S-curved body with scale texture, four clawed legs, a flowing mane, whiskers, antlers,
a beard and a plume tail, with a small pearl floating under its chin. Same palette letters as
Sprites.js (o outline, m body, d shade, h highlight, l pale, b belly, a accent, t claw, e/k eye).
"""
import json, math, os, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
N = 32

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

def draw_head(cv, hx, hy, ph, asleep=False, mouth=0):
    # antlers, branching back and up
    for k, (dx, dy, spread) in enumerate(((-2, -3, -1), (1, -4, 2))):
        cv.bez((hx + dx, hy + dy), (hx + dx - 2 + spread, hy + dy - 6), (hx + dx - 6 + spread * 2, hy + dy - 9 + math.sin(ph + k) * 0.6), 'a', 2.0, 0.8)
        cv.bez((hx + dx - 2, hy + dy - 5), (hx + dx - 5, hy + dy - 7), (hx + dx - 8, hy + dy - 6), 'a', 1.3, 0.6)
    # a pale, feathery mane sweeping back from the head
    for i in range(6):
        oy = -5 + i * 1.9; sway = math.sin(ph + i * 0.8) * 1.3
        cv.bez((hx - 2, hy + oy), (hx - 6, hy + oy - 2 + sway), (hx - 11 + sway, hy + oy + 2 + i * 0.6), 'l' if i % 2 else 'a', 1.8, 0.7)
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


def draw_claw_leg(cv, x, y, dx, dy, col):
    ex, ey = x + dx, y + dy
    cv.line(x, y, (x + ex) / 2, (y + ey) / 2 + 0.8, col, 2.6, 2.2); cv.line((x + ex) / 2, (y + ey) / 2 + 0.8, ex, ey, col, 2.2, 1.8)
    for cx, cy in ((ex + 2, ey + 1.8), (ex + 2.4, ey - 0.4), (ex - 1.6, ey + 2), (ex + 0.4, ey + 2.6)): cv.line(ex, ey, cx, cy, 't', 0.9, 0.7)

def head_frame(ph=0.0, breathe=0.0, asleep=False, mouth=0, fire=False, low=0):
    """The head, mane, antlers, whiskers and the top of the neck; the long body is drawn by the game."""
    cv = Canvas()
    hx, hy = 18, 13 + low + (0 if not fire else -1) + breathe * 0.4
    # the neck rises from the lower left, where the game attaches the long body
    cv.bez((0, 31), (5, 29 + math.sin(ph) * 0.6), (hx - 3, hy + 4), 'm', 7.5, 6.5)
    cv.bez((1, 32), (6, 30 + math.sin(ph) * 0.6), (hx - 1, hy + 6), 'b', 2.2, 1.8)          # belly, front of the neck
    for y in range(N):
        for x in range(N):
            if cv.g[y][x] == 'm':
                if (x * 3 + y * 5) % 7 == 0: cv.g[y][x] = 'l'
                elif (x * 5 + y * 3) % 9 == 0: cv.g[y][x] = 'a'
    draw_claw_leg(cv, 9, 27, 3, 4, 'm')                                            # a front paw, tucked under the neck
    draw_head(cv, hx, hy, ph, asleep, mouth)
    shade(cv); outline(cv)
    return cv.rows()

def build():
    walk = [head_frame(i / 8 * 2 * math.pi, math.sin(i / 8 * 2 * math.pi)) for i in range(8)]
    idle = [head_frame(0.0, 0), head_frame(0.8, 0.6), head_frame(1.6, 0), head_frame(2.4, 0.6)]
    sleep = [head_frame(0.0, 0, True, 0, False, 2), head_frame(0.8, 0.6, True, 0, False, 2)]
    fire = [head_frame(0.0), head_frame(0.5, 0.4, False, 0, True), head_frame(1.0, 0, False, 1, True), head_frame(1.5, 0, False, 1, True)]
    return {'walk': walk, 'idle': idle, 'sleep': sleep, 'curl': sleep, 'fire': fire}

if __name__ == '__main__':
    data = build()
    with open(os.path.join(ROOT, 'src', 'SpritesXL.js'), 'w') as f:
        f.write('.pragma library\n\n// 32x32 head frames of the fourth form (Celestial Dragon). Its long body is drawn by SerpentBody.qml.\n'
                '// Generated by tools/sprites/celestial.py; same palette characters as Sprites.js.\n'
                'var SIZE = 32\nvar ANCHOR = { x: 3, y: 28 }      // where the neck leaves the frame: the body attaches here\n'
                'var FRAMES = ' + json.dumps(data, separators=(',', ':')) + '\n')
    if len(sys.argv) > 1:
        from PIL import Image
        pal = {'o': (20, 14, 16), 'm': (226, 71, 58), 'd': (140, 32, 34), 'h': (255, 120, 100), 'l': (255, 232, 170), 'b': (255, 214, 150),
               'a': (255, 200, 110), 't': (245, 245, 235), 'e': (255, 255, 255), 'k': (16, 16, 24), 'f': (255, 138, 36), 'y': (255, 226, 122)}
        frames = data['walk'][:4] + data['idle'][:1] + data['fire'][2:3] + data['sleep'][:1] + data['fire'][1:2]
        S = 8; cols = 4; rows = 2
        img = Image.new('RGB', (cols * (N * S + 8) + 8, rows * (N * S + 8) + 8), (40, 44, 52))
        for k, fr in enumerate(frames):
            ox = 8 + (k % cols) * (N * S + 8); oy = 8 + (k // cols) * (N * S + 8)
            for y, row in enumerate(fr):
                for x, ch in enumerate(row):
                    if ch in pal: img.paste(pal[ch], (ox + x * S, oy + y * S, ox + x * S + S, oy + y * S + S))
        img.save(sys.argv[1])
    print('wrote src/SpritesXL.js')
