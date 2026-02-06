#!/usr/bin/python
import numpy as np
import math
import os
import vg
from PIL import Image

def write_uint16(f,x):
    f.write(x.to_bytes(2, byteorder="big", signed=False))
# Take each pixel, and find new X pos
# Plot the pixel
# Each color has two pixels to form arond 60 pixels (30 colors, one background, one spare)
infilename = "/home/torkildl/amiga/gerp/assets/pastiche.png"
myimg = Image.open(infilename)

imgwidth = myimg.width
imgheight = myimg.height


outfilename = "/home/torkildl/amiga/pastiche/megasine/data/backagain-pixels.dat"
outfile = open(outfilename, "wb")


maxperx = 0
for x in range(0,imgwidth):
    state = 0
    numthisx = 0
    thiscol = [0,0,0,0,0,0,0,0]
    px = state
    for y in range(0,imgheight):
        px = myimg.getpixel((x,y))
        if px!=state:
            thiscol[numthisx] = y
            numthisx = numthisx+1
            # Write out the pixel Y pos here
            # print("Change from ", state, " to ", px, " at pos", (x,y))
        state = px
        if numthisx>maxperx: maxperx=numthisx
    stopw = 0
    for i in range(0,len(thiscol)):
        if stopw==0:
            write_uint16(outfile,thiscol[i])
        if thiscol[i]==0: stopw=1

myimg.close()
outfile.close()
