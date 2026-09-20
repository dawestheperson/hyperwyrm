"""Generate the upright dance frames (moonwalk, poses, spin) as src/SpriteDance.js.

    python tools/sprites/dance.py [preview.png]

The Wyvern and Emperor Dragon rear up on two legs (fedora, sparkly glove); the Wyrmling has no
legs, so it rears up and sways like a snake. Heads come from serp.py so they match the walking art.
"""
import json, math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit import Canvas, shade, outline, PAL, png, N
from serp import head

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
BELLY = {0: 'b', 1: 'b', 2: 'l'}

def hat(cv, hx, hy, tip=False):
    cv.ell(hx + 0.5, hy - 4.3, 5.6, 1.15, 'k')               # brim
    cv.rect(hx - 2.4, hy - 8.4, hx + 3.3, hy - 4.4, 'k')     # crown
    cv.rect(hx - 2.4, hy - 5.6, hx + 3.3, hy - 5.0, 'y')     # band
    cv.px(hx - 2.4, hy - 8.4, '.'); cv.px(hx + 3.3, hy - 8.4, '.')

def glove(cv, x, y):
    cv.rect(int(x) - 1, int(y) - 1, int(x), int(y), 'e')
    cv.px(x + 1.5, y - 2, 'y'); cv.px(x - 2, y - 1.5, 'y')  # sparkle

def leg(cv, hip, foot, flat, col='m'):
    cv.line(hip[0], hip[1], foot[0], foot[1] - 1.2, col, 3.0, 2.3)
    if flat: cv.ell(foot[0] + 1.6, foot[1], 3.0, 1.3, 'l')
    else:    # up on the toes: the foot points down
        cv.ell(foot[0] + 0.6, foot[1] - 0.2, 1.3, 2.2, 'l')

def biped(stage, pose, sway=0.0, lift=0):
    """pose: 'A','B','C','D' moonwalk cycle | 'point' | 'lean' | 'hat' | 'toe'"""
    cv = Canvas(); hx, hy = 19 + sway * 0.6, 9 - lift
    hip = (14 + sway, 21 - lift)
    # tail, flicked up behind
    cv.bez(hip, (7, 24), (3, 18 - lift), 'm', 4.4, 1.3)
    cv.poly([(1.5, 17 - lift), (4.5, 15.5 - lift), (5, 19.5 - lift)], 'a')
    # far arm, far leg (behind the body)
    sh = (15.5 + sway * 0.5, 14 - lift)
    far_hand = (12.5, 19 - lift) if pose != 'lean' else (11, 17 - lift)
    cv.line(sh[0] - 1, sh[1], far_hand[0], far_hand[1], 'd', 2.0, 1.6)
    legs = {'A': ((17.5, 30), True, (10, 30), False), 'B': ((15, 30), True, (13, 30), False),
            'C': ((11.5, 30), False, (18, 30), True), 'D': ((14, 30), True, (15.5, 30), False)}
    key = pose if pose in legs else 'B'
    fxn, flat_n, fxf, flat_f = legs[key][0][0], legs[key][1], legs[key][2][0], legs[key][3]
    fy = 30 - lift * 1.0
    leg(cv, (hip[0] - 1, hip[1]), (fxf, fy), flat_f, 'd')                 # far leg
    # torso: a chest column from neck to hips, belly on the front
    cv.bez((hx - 3, hy + 3), (hx - 7, 15 - lift), hip, 'm', 6.0, 6.4)
    cv.bez((hx - 1.4, hy + 4), (hx - 4, 15 - lift), (hip[0] + 2.2, hip[1] - 1), BELLY[stage], 2.0, 2.4)
    leg(cv, (hip[0] + 1, hip[1]), (fxn, fy), flat_n, 'm')                 # near leg
    # near arm
    if pose == 'point':   hand = (24.5, 8 - lift)
    elif pose == 'hat':   hand = (hx + 1.5, hy - 4.4)
    elif pose == 'lean':  hand = (22.5, 21 - lift)
    else:                 hand = (21.5 + sway * 0.4, 18 - lift)
    elb = ((sh[0] + hand[0]) / 2 + 1.2, (sh[1] + hand[1]) / 2 + 1.5)
    cv.bez(sh, elb, hand, 'm', 2.6, 2.0)
    glove(cv, hand[0], hand[1])
    head(cv, stage, hx, hy, 0.0, 'idle', False, False)
    hat(cv, hx, hy)
    shade(cv); outline(cv)
    return cv.rows()

def rearing_snake(stage, phase):
    """The Wyrmling has no legs: it rears up and sways."""
    cv = Canvas(); hx, hy = 17 + 2.2 * math.sin(phase), 9
    pts = []
    for i in range(0, 25):
        s = i / 24
        y = hy + 3 + s * 19
        x = hx - 1 + 3.6 * math.sin(phase + s * 5.2) * (0.35 + 0.8 * s) - 1.5 * s
        pts.append((x, y, 5.6 - 2.2 * s))
    cv.bez((pts[-1][0], 22), (6, 27), (4, 22 + 1.5 * math.sin(phase)), 'm', 3.0, 1.2)
    for (x, y, t) in pts: cv.ell(x, y, t / 2 + 0.3, t / 2 + 0.3, 'm')
    for (x, y, t) in pts[:20]: cv.ell(x + t * 0.28, y, 0.9, 1.6, 'b')
    cv.ell(13, 29.6, 5.5, 1.5, 'm')                                        # a coil at the base
    head(cv, stage, hx, hy, 0.0, 'idle', False, False)
    hat(cv, hx, hy)
    hand = (hx + 5.5, 16 + 1.5 * math.sin(phase))
    shade(cv); outline(cv)
    return cv.rows()

def squash(rows, s, mirror=False):
    """Turn the sprite edge-on by scaling columns about the centre (a pixel-level 'spin')."""
    out = []
    cx = 15.5
    for r in rows:
        new = ['.'] * N
        for x in range(N):
            sx = int(round(cx + (x - cx) / s))
            if 0 <= sx < N and r[sx] != '.': new[x] = r[sx]
        line = ''.join(new)
        out.append(line[::-1] if mirror else line)
    return out

def build():
    out = {}
    for stage in (0, 1, 2):
        if stage == 0:
            moon = [rearing_snake(0, p) for p in (0.0, 1.6, 3.1, 4.7)]
            pose = [rearing_snake(0, 0.8), rearing_snake(0, 2.4), rearing_snake(0, 3.9), rearing_snake(0, 5.5)]
            base = moon[0]
        else:
            moon = [biped(stage, k, sw) for k, sw in (('A', 0.6), ('B', 0), ('C', -0.6), ('D', 0))]
            pose = [biped(stage, 'point', 0), biped(stage, 'lean', 0), biped(stage, 'hat', 0), biped(stage, 'toe', 0, lift=1)]
            base = moon[1]
        spin = [squash(base, 0.7), squash(base, 0.35), squash(base, 0.35, True), squash(base, 0.7, True), squash(base, 1.0, True),
                squash(base, 0.7, True), squash(base, 0.35, True), squash(base, 0.35), squash(base, 0.7)]
        if stage == 0: spin = [f for f in spin]
        out[str(stage)] = {'moon': moon, 'pose': pose, 'spin': spin}
    return out

if __name__ == '__main__':
    data = build()
    with open(os.path.join(ROOT, 'src', 'SpriteDance.js'), 'w') as f:
        f.write('.pragma library\n\n// Upright dance frames: moonwalk cycle, poses (point, lean, hat tip, toe stand) and a spin.\n'
                '// Generated by tools/sprites/dance.py; do not edit by hand. Same palette as Sprites.js.\n'
                'var DANCE = ' + json.dumps(data, separators=(',', ':')) + '\n')
    if len(sys.argv) > 1:
        pal = {**PAL, 'b': (255, 214, 170), 'l': (255, 205, 110), 'a': (255, 184, 77), 'm': (226, 71, 58), 'd': (140, 32, 34), 'h': (255, 120, 100)}
        frames = []
        for st in ('1', '2', '0'):
            for k in ('moon', 'pose'): frames += data[st][k]
        png(frames, sys.argv[1], S=5, cols=8, pal=pal)
    print('wrote src/SpriteDance.js')
