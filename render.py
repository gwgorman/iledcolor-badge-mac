#!/usr/bin/env python3
"""48x12 local pixel renderer. No BLE or protocol dependencies."""
import argparse, json, math
from pathlib import Path

FONT = dict(zip('ABCDEFGHIJKLMNOPQRSTUVWXYZ ', [
'010101111101101','110101110101110','011100100100011','110101101101110',
'111100110100111','111100110100100','011100101101011','101101111101101',
'111010010010111','001001001101010','101101110101101','100100100100111',
'101111111101101','101111111111101','010101101101010','110101110100100',
'010101101111011','110101110101101','011100010001110','111010010010010',
'101101101101111','101101101101010','101101111111101','101101010101101',
'101101010010010','111001010100111','000000000000000']))
FONT['N']='101101111101101'

# Uniform 4x7 capitals; both labels use identical letter widths.
LABEL_FONT = {
 'N':['1001','1101','1101','1011','1011','1001','1001'],
 'A':['0110','1001','1001','1111','1001','1001','1001'],
 'S':['0111','1000','1000','0110','0001','0001','1110'],
 'U':['1001','1001','1001','1001','1001','1001','0110'],
 'G':['0110','1001','1000','1011','1001','1001','0110'],
 'O':['0110','1001','1001','1001','1001','1001','0110'],
 'R':['1110','1001','1001','1110','1010','1001','1001'],
 'M':['1001','1111','1111','1001','1001','1001','1001'],
 ' ':['0000']*7,
}

def label_text(f,s):
    width=sum(4 if c==' ' else 5 for c in s)-1
    x=(48-width)//2
    for c in s:
        for y,row in enumerate(LABEL_FONT[c]):
            for xx,pixel in enumerate(row):
                if pixel=='1': dot(f,x+xx,y+2)
        x+=4 if c==' ' else 5
    return f

# Proportional mixed-case lettering drawn specifically for an 11-pixel height.
TALL = {
 'H':['10001','10001','10001','10001','11111','10001','10001','10001','10001','00000','00000'],
 'I':['111','010','010','010','010','010','010','010','111','000','000'],
 '!':['1','1','1','1','1','1','0','0','1','0','0'],
 "'":['1','1','0','0','0','0','0','0','0','0','0'],
 'm':['00000','00000','11010','10101','10101','10101','10101','10101','10101','00000','00000'],
 'G':['01110','10001','10000','10000','10111','10001','10001','10001','01110','00000','00000'],
 'T':['11111','00100','00100','00100','00100','00100','00100','00100','00100','00000','00000'],
 'Y':['10001','10001','10001','01010','00100','00100','00100','00100','00100','00000','00000'],
 'r':['000','000','110','101','100','100','100','100','100','000','000'],
 'e':['0000','0000','0110','1001','1001','1111','1000','1001','0110','0000','0000'],
 'g':['00000','00000','01111','10001','10001','10001','01111','00001','00001','10001','01110'],
 'o':['0000','0000','0110','1001','1001','1001','1001','1001','0110','0000','0000'],
 'u':['0000','0000','1001','1001','1001','1001','1001','1001','0111','0000','0000'],
 'i':['1','0','1','1','1','1','1','1','1','0','0'],
 'd':['0001','0001','0111','1001','1001','1001','1001','1001','0111','0000','0000'],
 ' ':['000']*11,
}

def tall_text(s,wide=False,x=None):
    glyphs=[TALL[c] for c in s]
    width=sum(len(g[0]) for g in glyphs)+len(glyphs)-1
    scale=2 if wide and width*2<=48 else 1
    f=blank()
    if x is None: x=(48-width*scale)//2
    for glyph in glyphs:
        for y,row in enumerate(glyph):
            for xx,c in enumerate(row):
                if c=='1':
                    for dx in range(scale): dot(f,x+xx*scale+dx,y)
        x+=(len(glyph[0])+1)*scale
    return f

def blank(): return [[0]*48 for _ in range(12)]
def dot(f,x,y):
    if 0<=x<48 and 0<=y<12: f[y][x]=1
def text(f,s,y=3,x=None):
    if x is None: x=(48-text_width(s))//2
    for c in s.upper():
        glyph=FONT.get(c,FONT[' '])
        width=len(glyph)//5
        for yy in range(5):
            for xx in range(width):
                if glyph[yy*width+xx]=='1': dot(f,x+xx,y+yy)
        x+=width+1
    return f
def text_width(s): return sum(len(FONT.get(c,FONT[' ']))//5+1 for c in s.upper())-1
def rows(f): return [''.join(map(str,row)) for row in f]

def nasa():
    f=blank()
    for t in range(120):
        a=t*math.tau/120
        dot(f,round(23.5+20*math.cos(a)),round(5.5+5*math.sin(a)))
    label_text(f,'NASA')
    for x,y in [(6,2),(39,2),(8,9),(37,9)]: dot(f,x,y)
    return f

def rocket(x,t):
    f=blank()
    shape=['    ##      ',' ########   ','########### ',' ########   ','    ##      ']
    for y,row in enumerate(shape):
        for xx,c in enumerate(row):
            if c=='#': dot(f,x+xx,y+3)
    for xx in range(3+t%3): dot(f,x-1-xx,5)
    for xx,yy in [(3,1),(16,9),(29,2),(43,10)]: dot(f,xx,yy)
    return f

def demo():
    frames=[]
    for f,n in [(nasa(),20),(tall_text("Hi! I'm"),20),(tall_text('Greg',wide=True),30)]:
        frames.extend([rows(f)]*n)
    phrase='Your Tour Guide'
    width=sum(len(TALL[c][0])+1 for c in phrase)-1
    for x in range(48,-width-1,-2): frames.append(rows(tall_text(phrase,x=x)))
    for t,x in enumerate(range(-12,49,2)): frames.append(rows(rocket(x,t)))
    frames.extend([rows(label_text(blank(),'USS GORMAN'))]*25)
    frames.extend([rows(blank())]*5)
    return frames

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--text'); p.add_argument('--demo',action='store_true')
    p.add_argument('--frame-ms',type=int,default=100)
    p.add_argument('--out',type=Path,required=True)
    a=p.parse_args()
    if not 20<=a.frame_ms<=5100 or a.frame_ms%20: p.error('frame-ms must be a multiple of 20 from 20 to 5100')
    if a.text is not None:
        s=a.text.upper()
        if any(c not in FONT for c in s): p.error('text supports letters A-Z and spaces')
        width=text_width(s)
        frames=([rows(text(blank(),s))] if width<=48 else [rows(text(blank(),s,x=x)) for x in range(48,-width-1,-1)])
    else: frames=demo()
    a.out.write_text(json.dumps(dict(width=48,height=12,frameMs=a.frame_ms,packing='column16',frames=frames)))
    print(f'{len(frames)} frames, {len(frames)*a.frame_ms/1000:.1f}s: {a.out}')

if __name__=='__main__': main()
