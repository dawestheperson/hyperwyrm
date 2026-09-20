import math,sys
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from kit import *

CFG={
 0:dict(x0=25.0,L=24.0,y0=20.5,drop=5.5,amp=3.0,k=1.9,th0=6.6,th1=1.2,N=48,sq=True,taper=2.4,legs=[],ground=None,mane=0,tail_flame=False),
 1:dict(x0=22.0,L=20.5,y0=9.5,drop=9.0,amp=4.0,k=1.55,th0=6.0,th1=1.3,N=46,legs=[(0.24,'d'),(0.32,'m'),(0.58,'d'),(0.66,'m')],ground=None,mane=1,tail_flame=True),
 2:dict(x0=20.6,L=19.6,y0=13.0,drop=6.5,amp=4.8,k=1.5,th0=8.6,th1=1.8,N=50,legs=[(0.22,'d'),(0.30,'m'),(0.56,'d'),(0.64,'m')],ground=None,mane=2,tail_flame=True),
}

def head(cv,stage,hx,hy,ph,mode,blink,asleep,fire=0):
    if stage==0:
        X=int(round(hx)); Y=int(round(hy))
        cv.rect(X-4,Y-4,X+5,Y+3,'m')
        for (cx,cy) in ((X-4,Y-4),(X+5,Y-4),(X-4,Y+3)): cv.px(cx,cy,'.')
        cv.rect(X+5,Y-1,X+7,Y+2,'m'); cv.px(X+7,Y-1,'.'); cv.px(X+7,Y+2,'.')
        cv.poly([(X-3.5,Y-3.5),(X-0.5,Y-3.5),(X-1.5,Y-6.2),(X-4.5,Y-7)],'a')
        cv.poly([(X+1.5,Y-3.5),(X+4.5,Y-3.5),(X+5.4,Y-7),(X+2.4,Y-6)],'a')
        if asleep or blink:
            for x in (X-2,X-1,X+2,X+3): cv.px(x,Y-1,'k')
        else:
            for ex in (X-2,X+2):
                cv.rect(ex,Y-2,ex+1,Y-1,'k'); cv.px(ex,Y-2,'e')
        cv.px(X+6,Y,'k')
        for x in range(X+1,X+7): cv.px(x,Y+2,'d')
        if (mode=='walk' and math.sin(ph*2)>0) or (mode=='idle' and blink):
            cv.px(X+8,Y+1,'f'); cv.px(X+9,Y+1,'f'); cv.px(X+10,Y,'f'); cv.px(X+10,Y+2,'f')
    elif stage==2:
        grand_head(cv,hx,hy,ph,mode,blink,asleep,fire)
    else:
        big=False
        cv.ell(hx+0.5,hy,4.6 if big else 4.2,3.7 if big else 3.5,'m')
        X=int(round(hx)); Y=int(round(hy))
        cv.rect(X+2,Y-1,X+7,Y+2,'m')                 # boxy muzzle
        cv.px(X+7,Y-1,'.')                            # bevelled top-front corner
        for x in range(X+3,X+8): cv.px(x,Y+1,'d')     # mouth line
        cv.px(X+6,Y,'k')                              # nostril
        cv.bez((X+5.5,Y+2.9),(X+5.9,Y+4.4),(X+5.0,Y+6.2),'a',1.4,0.9)              # beard under the jaw
        cv.bez((hx-1,hy-3),(hx-2.5,hy-6),(hx-5.5,hy-6.5),'a',2.4,0.8)
        cv.bez((hx+1.5,hy-3.2),(hx+1,hy-6.2),(hx-1.6,hy-8),'a',2.4,0.8)
        cv.poly([(hx-4,hy-1),(hx-1,hy-3),(hx-2,hy+3),(hx-7,hy+1)],'a')
        if asleep or blink:
            for dx in (1,2,3): cv.px(hx+dx,hy-0.8,'k')
        else:
            cv.rect(hx+1,hy-2,hx+3,hy,'e'); cv.rect(hx+2,hy-1,hx+3,hy,'k')
        # Whiskers: short, thin, pointing forward off the upper lip (a Chinese
        # dragon's, not a beard), with only a hair of sway.
        if big:
            px_,py_=hx+2.5,hy+9.5+math.sin(ph)*1.6
            cv.disk(px_,py_,2.6,'f'); cv.disk(px_,py_,1.6,'y'); cv.px(px_-1,py_-1,'e')


MOUTH={}

def grand_head(cv,hx,hy,ph,mode,blink,asleep,fire=0):
    """The Grand Dragon's head: bigger, branched antlers, a flowing crest, long
    whiskers and a small chin tuft (all steady: only a hair of sway)."""
    if fire!=0: hy=hy-(0.8 if fire<2 else 1.1)   # head lifts to breathe
    cv.ell(hx+0.5,hy,5.1,4.1,'m')                 # skull
    X=int(round(hx)); Y=int(round(hy))
    dj=0
    if fire>0:                                    # open mouth: square jaws
        dj=max(1,int(round([0,1.6,3.0,4.2][fire]*0.7)))
        cv.rect(X+2,Y-1,X+8,Y+1,'m'); cv.px(X+8,Y-1,'.')      # upper muzzle
        cv.rect(X+3,Y+2,X+8,Y+1+dj,'k')                       # dark throat
        cv.rect(X+2,Y+2+dj,X+7,Y+3+dj,'m')                    # dropped lower jaw
        cv.px(X+5,Y+1+dj,'f'); cv.px(X+6,Y+1+dj,'f')          # tongue / glow
        MOUTH['x']=X+9.6; MOUTH['y']=Y+1.5+dj/2.0
    else:
        cv.rect(X+2,Y-1,X+8,Y+3,'m')              # boxy muzzle
        cv.px(X+8,Y-1,'.')                        # bevelled top-front corner
        for x in range(X+3,X+9): cv.px(x,Y+2,'d') # mouth line
        cv.px(X+7,Y,'k'); cv.px(X+6,Y,'k')        # nostrils
    jb=Y+3+(dj if fire>0 else 0)                                                    # bottom of the jaw
    cv.bez((X+6.0,jb+0.8),(X+6.6,jb+3.0),(X+5.0,jb+5.4),'a',1.8,0.9)                # beard, only below the jaw
    # branched antlers (two prongs each)
    cv.bez((hx-1.2,hy-4.0),(hx-3.2,hy-8.0),(hx-7.4,hy-9.0),'a',3.0,0.8)
    cv.bez((hx-3.4,hy-6.4),(hx-3.8,hy-9.0),(hx-5.8,hy-11.0),'a',2.0,0.8)
    cv.bez((hx+2.0,hy-4.2),(hx+1.4,hy-8.2),(hx-1.6,hy-10.4),'a',3.0,0.8)
    cv.bez((hx+1.6,hy-7.0),(hx+3.2,hy-9.2),(hx+2.6,hy-11.6),'a',2.0,0.8)
    # crest sweeping back from the skull
    cv.poly([(hx-4.5,hy-2.5),(hx-1,hy-4),(hx-2.5,hy+2.5),(hx-8.5,hy+0.8)],'a')
    if asleep or blink or fire>=2:
        for dx in (1,2,3): cv.px(hx+dx,hy-1.0,'k')
    else:
        cv.rect(hx+1,hy-2.5,hx+3,hy-0.5,'e'); cv.rect(hx+2,hy-1.5,hx+3,hy-0.5,'k')
    if fire>=2:
        my=hy+2.3+[0,1.6,3.0,4.2][fire]*0.4
        for i in range(4):
            cv.px(hx+9.6+i*0.9,my-1+ (i%2),'f'); cv.px(hx+9.6+i*0.9,my+ (i%2)*0.5,'y')
    # a few twinkles around the crown
    for i,(dx,dy) in enumerate(((-8,-10),(5,-12),(-12,-4),(9,-8))):
        if math.sin(ph*2+i*1.9)>0.25: cv.px(hx+dx,hy+dy,'y')

def serp(stage,p=0.0,mode='walk',blink=False,breathe=0,asleep=False,fire=0):
    c=CFG[stage]; cv=Canvas(); ph=2*math.pi*p
    amp=c['amp']*({'walk':1.0,'idle':0.55,'fire':0.4}.get(mode,0.3))
    if asleep: amp=c['amp']*0.25
    bob=0
    def path(s):
        x=c['x0']-c['L']*s
        y=c['y0']+c['drop']*(math.sqrt(s) if c.get('sq') else s)+amp*math.sin(2*math.pi*c['k']*s-ph)*(0.35+0.65*s)+breathe*0.6-bob*(1-s)
        return x,y
    def th(s):
        t0,t1=c['th0'],c['th1']
        if c.get('taper'): return t1+(t0-t1)*(1-s**c['taper'])
        return t0-(t0-t1)*0.75*s/0.7 if s<0.7 else (t0-(t0-t1)*0.75)*(1-(s-0.7)/0.3)+t1*0.8
    N_=c['N']
    pts=[(path(i/N_),th(i/N_),i/N_) for i in range(N_+1)]
    hx,hy=pts[0][0]
    # ---- tail flame (behind)
    (tx,ty),_,_=pts[-1]
    if c['tail_flame']:
        cv.poly([(tx-4,ty-2),(tx+1,ty-1),(tx+1.5,ty+3),(tx-1,ty+1.2)],'a')
        cv.poly([(tx-3.5,ty+3),(tx-0.5,ty+0.5),(tx-1,ty+5.5)],'a')
        if stage==2:
            cv.poly([(tx-1,ty-3.5),(tx+2.5,ty-1.5),(tx+1,ty+1)],'a')
            cv.poly([(tx+0.5,ty+2),(tx+3,ty+3.5),(tx-0.5,ty+6.5)],'a')
    else:
        cv.poly([(tx-2.5,ty-1),(tx+1.2,ty-0.5),(tx+0.5,ty+2.5),(tx-1.5,ty+1)],'a')
    # ---- mane / back plates (behind body)
    if c['mane']:
        step=3 if stage==2 else 4
        for i in range(3,int(N_*0.88),step):
            (x,y),t,s=pts[i]
            h=(3.6-2.4*s) if stage==2 else 2.4
            cv.poly([(x-1.8,y-t/2+1.2),(x+1.4,y-t/2+1.2),(x-1.2,y-t/2-h)],'a')
    else:
        for i in range(4,int(N_*0.7),4):
            (x,y),t,s=pts[i]
            cv.poly([(x-1.5,y-t/2+1.2),(x+1.3,y-t/2+1.2),(x-0.3,y-t/2-2.2)],'a')
    # ---- legs (behind body)
    for si,col in c['legs']:
        (x,y),t,s=pts[int(si*N_)]
        top=y+t/2-1
        if c['ground']:
            near=(col=='m')
            phs=(math.pi if not near else 0)+si*6
            sw=math.sin(ph+phs) if mode=='walk' else 0
            lift=max(0,math.sin(ph+phs))*2.2 if mode=='walk' else 0
            fx=x+1.0+ (math.cos(ph+phs)*2.2 if mode=='walk' else 0)
            fy=c['ground']-lift
            cv.line(x,top,fx,fy-1,col,3.0 if stage==0 else 2.6,2.6 if stage==0 else 2.2)
            cv.ell(fx+0.8,fy-0.2,2.6,1.4,'l')
        else:
            sw=math.sin(ph*2+si*9)*0.9 if mode=='walk' else 0
            cv.line(x,top,x-1+sw,y+t/2+3,'d',2.2,1.6)
            cv.px(x-2+sw,y+t/2+3.6,'t'); cv.px(x-1+sw,y+t/2+3.8,'t')
    # ---- body
    for (x,y),t,s in pts:
        cv.ell(x,y,t/2+0.3,t/2+0.3,'m')
    if True:
        for yy in range(32):
            for xx in range(32):
                if cv.g[yy][xx]=='m' and (xx+2*yy)%5==0: cv.g[yy][xx]='h'
    for (x,y),t,s in pts[:int(N_*0.78)]:
        yy=int(y+t/2-0.4)
        if stage==2:                      # a broad golden belly band
            for dy in (0,1,2):
                if cv.get(int(x),yy-dy)=='m': cv.px(int(x),yy-dy,'l')
        else:
            for dy in (0,1):
                if cv.get(int(x),yy-dy)=='m': cv.px(int(x),yy-dy,'l'); break
    head(cv,stage,hx,hy,ph,mode,blink,asleep,fire)
    shade(cv); outline(cv)
    return cv.rows()

if __name__=='__main__':
    pal={**PAL,'m':(226,71,58),'d':(140,32,34),'h':(255,120,100),'l':(255,205,110),'a':(255,184,77)}
    for st in (0,1,2):
        png([serp(st,i/8) for i in range(8)],'/tmp/omg_s%d.png'%st,S=5,cols=4,pal=pal)


def curl(stage, breathe=0):
    """Resting pose: the body coiled on the ground, head laid on top, eyes shut."""
    cv=Canvas(); c=CFG[stage]
    cx,cy=16.0,24.3
    R0,RY=11.5,4.6
    br=1+0.07*breathe
    N_=48
    pts=[]
    for i in range(N_+1):
        s_=i/N_
        phi=-0.25*math.pi - s_*2.35*math.pi
        rr=1-0.72*s_
        x=cx+R0*rr*math.cos(phi)
        y=cy+RY*rr*br*math.sin(phi)-(1.0 if s_<0.12 else 0)
        t=c['th0']*(1-0.55*s_)*0.95*br+1.0
        pts.append(((x,y),t,s_))
    (tx,ty),_,_=pts[-1]
    if stage>=1:
        cv.poly([(tx-2,ty-1.5),(tx+2,ty-1),(tx+1,ty+2.5),(tx-1.5,ty+1.5)],'a')
    # far-to-near so the front of the coil overlaps the back
    order=sorted(pts,key=lambda p:p[0][1])
    if stage>=1:
        for (x,y),t,s_ in order:
            if s_>0.06 and int(s_*N_)%3==0:
                cv.poly([(x-1.6,y-t/2+1.2),(x+1.2,y-t/2+1.2),(x-0.8,y-t/2-2.0)],'a')
    for (x,y),t,s_ in order:
        cv.ell(x,y,t/2+0.3,t/2+0.3,'m')
    if stage>=1:
        for yy in range(32):
            for xx in range(32):
                if cv.g[yy][xx]=='m' and (xx+2*yy)%5==0: cv.g[yy][xx]='h'
    for (x,y),t,s_ in pts[:int(N_*0.5)]:
        yy=int(y+t/2-0.4)
        for dy in (0,1):
            if cv.get(int(x),yy-dy)=='m': cv.px(int(x),yy-dy,'l'); break
    (hx,hy),_,_=pts[0]
    hy_head={0:hy-3.0,1:hy-1.8,2:hy-1.8}[stage]
    head(cv,stage,hx-3.0,hy_head,0.0,'idle',False,True)
    shade(cv); outline(cv)
    return cv.rows()
