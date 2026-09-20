import math
N=32
class Canvas:
    def __init__(s): s.g=[['.']*N for _ in range(N)]
    def px(s,x,y,c):
        x=int(math.floor(x)); y=int(math.floor(y))
        if 0<=x<N and 0<=y<N: s.g[y][x]=c
    def get(s,x,y):
        return s.g[y][x] if 0<=x<N and 0<=y<N else '.'
    def ell(s,cx,cy,rx,ry,c,only=None):
        for y in range(N):
            for x in range(N):
                if ((x+.5-cx)/rx)**2+((y+.5-cy)/ry)**2<=1:
                    if only is None or s.g[y][x] in only: s.g[y][x]=c
    def rect(s,x0,y0,x1,y1,c):
        for y in range(int(y0),int(y1)+1):
            for x in range(int(x0),int(x1)+1): s.px(x,y,c)
    def disk(s,cx,cy,r,c):
        s.ell(cx,cy,r,r,c)
    def line(s,x0,y0,x1,y1,c,th=1.0,th1=None):
        th1=th if th1 is None else th1
        n=int(max(abs(x1-x0),abs(y1-y0))*2)+1
        for i in range(n+1):
            t=i/n
            x=x0+(x1-x0)*t; y=y0+(y1-y0)*t
            r=(th+(th1-th)*t)/2
            s.ell(x,y,max(r,.5),max(r,.5),c)
    def bez(s,p0,p1,p2,c,th0,th1,steps=24):
        prev=None
        for i in range(steps+1):
            t=i/steps
            x=(1-t)**2*p0[0]+2*(1-t)*t*p1[0]+t*t*p2[0]
            y=(1-t)**2*p0[1]+2*(1-t)*t*p1[1]+t*t*p2[1]
            r=(th0+(th1-th0)*t)/2
            s.ell(x,y,max(r,.5),max(r,.5),c)
    def poly(s,pts,c):
        for y in range(N):
            for x in range(N):
                px,py=x+.5,y+.5
                inside=False
                j=len(pts)-1
                for i in range(len(pts)):
                    xi,yi=pts[i];xj,yj=pts[j]
                    if (yi>py)!=(yj>py) and px<(xj-xi)*(py-yi)/(yj-yi+1e-9)+xi: inside=not inside
                    j=i
                if inside: s.g[y][x]=c
    def rows(s): return [''.join(r) for r in s.g]

BODY=set('mdhla')
def shade(cv,chars='m'):
    """rim light top-left (h), rim shadow bottom-right (d) on plain body pixels"""
    g=cv.g
    out=[r[:] for r in g]
    for y in range(N):
        for x in range(N):
            if g[y][x]!='m': continue
            up=cv.get(x,y-1); lf=cv.get(x-1,y); dn=cv.get(x,y+1); rt=cv.get(x+1,y)
            if up=='.' or lf=='.': out[y][x]='h'
            if dn=='.' or rt=='.': out[y][x]='d'
    cv.g=out

def outline(cv, skip='fy'):
    g=cv.g
    out=[r[:] for r in g]
    for y in range(N):
        for x in range(N):
            if g[y][x]!='.': continue
            for dx,dy in((1,0),(-1,0),(0,1),(0,-1)):
                c=cv.get(x+dx,y+dy)
                if c!='.' and c!='o' and c not in skip: out[y][x]='o';break
    cv.g=out

PAL={ # preview palette (green)
 'o':(20,32,24),'m':(76,175,80),'d':(46,125,50),'h':(129,199,132),'l':(200,230,201),
 'a':(230,238,90),'w':(56,142,60),'v':(30,90,40),'e':(255,255,255),'k':(16,16,24),
 'f':(255,120,30),'y':(255,220,80),'t':(245,245,235),
}
def png(frames,path,S=8,cols=4,pal=PAL):
    import zlib,struct
    rows=(len(frames)+cols-1)//cols
    Wp=cols*(N*S+8)+8;Hp=rows*(N*S+8)+8
    img=[[(34,36,42)]*Wp for _ in range(Hp)]
    for n,g in enumerate(frames):
        cx=8+(n%cols)*(N*S+8);cy=8+(n//cols)*(N*S+8)
        for y,r in enumerate(g):
            for x,ch in enumerate(r):
                if ch in pal:
                    for dy in range(S):
                        for dx in range(S): img[cy+y*S+dy][cx+x*S+dx]=pal[ch]
    raw=b''.join(b'\x00'+bytes(v for px in row for v in px) for row in img)
    def c(t,d): q=struct.pack('>I',len(d))+t+d; return q+struct.pack('>I',zlib.crc32(t+d))
    open(path,'wb').write(b'\x89PNG\r\n\x1a\n'+c(b'IHDR',struct.pack('>IIBBBBB',Wp,Hp,8,2,0,0,0))+c(b'IDAT',zlib.compress(raw))+c(b'IEND',b''))
