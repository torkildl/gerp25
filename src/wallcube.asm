* Effect that generates "wall of cubes". Each row of cubes can move horizontally. The wall zooms in and out.
* The effect relies on precalced 2d coordinates, hidden face removal and lighting for the cube


        include "src/_main.i"
        include "src/tables.i"
        include "src/wallcube.i"
        include "common-timings.i"


SCREEN_W = 320
SCREEN_H = 256
WCUBE_MAX_SIZE = 192                            * maximum size of cube (only cube frame, no lef/right border)
WCUBE_MAX_ANIM = 128
WCUBE_MIN_SIZE = 16                             * minimum size of cube

WCUBE_BITMAP_W = SCREEN_W*2                     * double size
WCUBE_DRAWBUF_PLANE = ((WCUBE_BITMAP_W/8)*(WCUBE_MAX_SIZE+2)) * full row of cubes in one plane 
WCUBE_DRAWBUF_BUFSIZE = WCUBE_DRAWBUF_PLANE*2   * two planes
WCUBE_MAX_ROWS = (SCREEN_H/WCUBE_MIN_SIZE)+2
WCUBE_COPPER_BUFSIZE = SCREEN_H*32
LINEBUFFER_SZ = ((LOGO_PIX_H+2)+1)*(SCREEN_W/8)

WCUBE_CHIPREQ_BUFFER = WCUBE_DRAWBUF_BUFSIZE+WCUBE_COPPER_BUFSIZE+LINEBUFFER_SZ+128

WCUBE_YSTART = $2b
WCUBE_YSTOP = $0fe

LOGO_PIX_W = 33
LOGO_PIX_H = 6


Wallcube_Precalc:
        jsr     MemFlip                         * flip memory direction to allocate in the "right" direction
        
        ALLOC_PUBLIC WallCubeVars_SIZEOF,WallCubeVars
        move.l  WallCubeVars,a5

        * allocate memory within 64k for front buffer
        ALLOC_CHIP_ALIGNED WCUBE_DRAWBUF_BUFSIZE*2,a0
        move.l  a0,frontbuffer(a5)
        add.l   #WCUBE_DRAWBUF_BUFSIZE,a0
        move.l  a0,backbuffer(a5)

        ALLOC_CHIP_ALIGNED (WCUBE_MAX_ANIM*8)*(SCREEN_W/8),a1
        move.l  a1,plotbuffer(a5)


        ALLOC_CHIP WCUBE_COPPER_BUFSIZE*2,a0
        move.l  a0,frontcopper(a5)
        add.l   #WCUBE_DRAWBUF_BUFSIZE,a0
        move.l  a0,backcopper(a5)

        * Prereq: 2d coordinates, normals and lighting data
        ALLOC_PUBLIC WCUBE_MAX_SIZE*WCUBE_MAX_SIZE,a0
        move.l  a0,scaling_table(a5)            * max_size words for scaling table        
        move.w  #WCUBE_MAX_SIZE-1,d7
.newtab
        moveq   #0,d1
        move.w  #WCUBE_MAX_SIZE,d1
        sub.w   d7,d1                           * scale of this table
        asl.w   #6,d1
        divu.w  #WCUBE_MAX_SIZE,d1              * scale coefficient

        moveq   #0,d2

        move.w  #WCUBE_MAX_SIZE-1,d6
.newpt
        add.w   d1,d2                           * x(t-1) + dx
        move.w  d2,d3
        asr.w   #6,d3
        move.b  d3,(a0)+                        * save

        dbf     d6,.newpt
        dbf     d7,.newtab

        * Prepare copperlists. Puncture so there is no overflow anything
        move.l  frontcopper(a5),a0
        move.l  #-2,(a0)
        move.l  backcopper(a5),a0
        move.l  #-2,(a0)

        * fill plane
        move.l  #fillline,d0
        lea.l   Fillplane,a0
        move.w  d0,6(a0)
        swap    d0
        move.w  d0,2(a0)

        * backbuffer in d0
        lea.l   highbpls,a0
        move.l  frontbuffer(a5),d0
        move.l  #$00e00000,d1
        swap    d0
        move.w  d0,d1
        move.l  #$00080000,d2
        swap    d0
        move.l  d1,(a0)+
        add.l   d2,d1
        move.l  d1,(a0)+

        * plot logo in dot form in plot buffer
        * move from left end towards the right end
        lea.l   custom,a6
        move.l  plotbuffer(a5),a0
        move.w  #0,a4                           * cubesize counter
.newsize
        add.w   #1,a4
        move.w  a4,d0                           * get current cube size

        move.w  d0,d1
        subq    #1,d1                           * avoid setting off room for size 0
        mulu    #8*SCREEN_W/8,d1
        move.l  a0,a1
        add.l   d1,a1                           * current plotbuffer

        * establish where we will plot -- focus on middle of line        
        move.w  d0,d2
        move.w  #SCREEN_W/2,d1                  * middle of visible part of bitmap
        lsr.w   #1,d2
        sub.w   d2,d1                           * move half a cube to the left
        move.w  d0,d2

        mulu    #(LOGO_PIX_W-1)/2,d2            * the number of pixels to subtract from d1: half of the logo is on the left of the middle pixel
        sub.w   d2,d1                           * now we have the start position of the pixels to be plotted

        WAIT_BLIT
        move.l  #$01000000,bltcon0(a6)        
        move.l  a1,bltdpt(a6)
        clr.w   bltdmod(a6)
        move.l  #-1,bltafwm(a6)
        move.w  #(8*64)+20,bltsize(a6)

        lea.l   (SCREEN_W/8)(a1),a1             * skip the first, empty line
        lea.l   40*3(a1),a2                     * for expedient plotting

        lea.l   logopixels-LOGO_PIX_H,a3        * start before the table due to the looping
        moveq   #LOGO_PIX_W-1,d7
        moveq   #0,d2
        WAIT_BLIT
.nextpix
        lea.l   LOGO_PIX_H(a3),a3               * next pixel column in logo
        move.w  d1,d5                           * get current pixel boundary
        add.w   d0,d1                           * move counter one pixel to the right
        move.w  d1,d6                           * the right boundary
        
        * we know the pixel is visible
        tst.w   d5                              * is the left border within screen?
        bgt.s   .correctleft
        tst.w   d6
        blt.s   .decpix                         * no plotting, return to top and skip the coming pixel data
        moveq   #0,d5                           * this means that d5 is left of screen, but needs to be plotted anyway
.correctleft
        cmp.w   #SCREEN_W,d6
        blt.s   .correctright
        cmp.w   #SCREEN_W,d5                    * is the left border also inside, or outside?
        bgt.s   .decpix                         * completely outside, skip it
        move.w  #SCREEN_W,d6
.correctright
        * d5 is left border, must be plotted. d6 is right border must be plotted
        move.w  d5,d4
        lsr.w   #3,d4
        and.w   #$7,d5
        moveq   #7,d3
        sub.w   d5,d3
        * start: d3 is bit, d4 is byte offset
        move.w  d6,d2
        lsr.w   #3,d6
        and.w   #$7,d2
        moveq   #7,d5
        sub.w   d2,d5
        * end: d5 is bit, d6 is byte offset
        move.w  d6,$dff180

        move.b  (a3)+,d2
        beq.s   .pixel1
        bchg    d3,(a1,d4)
        bchg    d5,(a1,d6)
.pixel1        
        move.b  (a3)+,d2
        beq.s   .pixel2
        bchg    d3,40*1(a1,d4)
        bchg    d5,40*1(a1,d6)
.pixel2
        move.b  (a3)+,d2
        beq.s   .pixel3
        bchg    d3,40*2(a1,d4)
        bchg    d5,40*2(a1,d6)
.pixel3
        move.b  (a3)+,d2
        beq.s   .pixel4
        bchg    d3,40*3(a1,d4)
        bchg    d5,40*3(a1,d6)
.pixel4
        move.b  (a3)+,d2
        beq.s   .pixel5
        bchg    d3,40*1(a2,d4)
        bchg    d5,40*1(a2,d6)
.pixel5
        move.b  (a3)+,d2
        beq.s   .pixel6
        bchg    d3,40*2(a2,d4)
        bchg    d5,40*2(a2,d6)
.pixel6
        lea.l   -6(a3),a3
.decpix
        dbf     d7,.nextpix


        * quick fix for pixels?
        cmp.w   #1,a4
        bne.s   .fix01
        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix01  cmp.w   #2,a4
        bne.s   .fix02
        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix02  cmp.w   #3,a4
        bne.s   .fix03
        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix03  cmp.w   #4,a4
        bne.s   .fix04
        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix04  cmp.w   #5,a4
        bne.s   .fix05
*        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix05  cmp.w   #6,a4
        bne.s   .fix06
*        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix06  cmp.w   #7,a4
        bne.s   .fix07
*        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix07  cmp.w   #8,a4
        bne.s   .fix08
*        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix08  cmp.w   #9,a4
        bne.s   .fix09
*        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix09  cmp.w   #10,a4
        bne.s   .fix10
*        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix10  cmp.w   #11,a4
        bne.s   .fix11
        bchg    #0,39(a1)                       * last pixel of first line
        bra     .donefix
.fix11  cmp.w   #12,a4
        bne.s   .fix12
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix12
        cmp.w   #13,a4
        bne.s   .fix13
        bchg    #0,39(a1)                       * last pixel of last line
        bra     .donefix
.fix13
        cmp.w   #14,a4
        bne.s   .fix14
        bchg    #0,39(a1)                       * last pixel of last line
        bra     .donefix
.fix14
        cmp.w   #15,a4
        bne.s   .fix15
        bchg    #0,39(a1)                       * last pixel of last line
        bra     .donefix
.fix15
        cmp.w   #16,a4
        bne.s   .fix16
        bra     .donefix
.fix16
        cmp.w   #17,a4
        bne.s   .fix17
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix17
        cmp.w   #18,a4
        bne.s   .fix18
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix18
        cmp.w   #19,a4
        bne.s   .fix19
*        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bra     .donefix
.fix19
        cmp.w   #20,a4
        bne.s   .fix20
        bchg    #0,39+0(a2)                     * last pixel of last line
        bra     .donefix
.fix20
        cmp.w   #21,a4
        bne.s   .fix21
        bchg    #0,39+0(a2)                     * last pixel of last line
        bra     .donefix
.fix21
        cmp.w   #22,a4
        bne.s   .fix22
        bchg    #0,39+80(a1)                    * last pixel of last line
        bra     .donefix
.fix22
        cmp.w   #23,a4
        bne.s   .fix23
        bchg    #0,39+80(a1)                    * last pixel of last line
        bra     .donefix
.fix23
        cmp.w   #24,a4
        bne.s   .fix24
        bchg    #0,39+80(a1)                    * last pixel of last line
        bra     .donefix
.fix24
        cmp.w   #25,a4
        bne.s   .fix25
        bchg    #0,39+40(a1)                    * last pixel of last line
        bra     .donefix
.fix25
        cmp.w   #26,a4
        bne.s   .fix26
        bchg    #0,39+40(a1)                    * last pixel of last line
        bra     .donefix
.fix26
        cmp.w   #27,a4
        bne.s   .fix27
        bchg    #0,39+40(a1)                    * last pixel of last line
        bra     .donefix
.fix27
        cmp.w   #28,a4
        bne.s   .fix28
        bchg    #0,39+40(a1)                    * last pixel of last line
        bra     .donefix
.fix28
        cmp.w   #29,a4
        bne.s   .fix29
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix29
        cmp.w   #30,a4
        bne.s   .fix30
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix30
        cmp.w   #31,a4
        bne.s   .fix31
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix31
        cmp.w   #32,a4
        bne.s   .fix32
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix32
        cmp.w   #33,a4
        bne.s   .fix33
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix33
        cmp.w   #34,a4
        bne.s   .fix34
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix34
        cmp.w   #35,a4
        bne.s   .fix35
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+40(a1)                    * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
        bchg    #0,39+0(a2)                     * last pixel of last line
        bchg    #0,39+40(a2)                    * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.fix35
        cmp.w   #64,a4
        blt.s   .not46
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+80(a2)                    * last pixel of last line
        bra     .donefix
.not46
        cmp.w   #87,a4
        blt.s   .not87
        bchg    #0,39(a1)                       * last pixel of last line
        bchg    #0,39+80(a1)                    * last pixel of last line
.not87
        * now we must fill the pixel gaps.
        * a1 contains start of last buffer
.donefix
        lea.l   (8*SCREEN_W/8)-2(a1),a1         * end of buffer
        moveq   #0,d0
        WAIT_BLIT
        move.l  #$09f00012,bltcon0(a6)
        move.l  a1,bltapt(a6)
        move.l  a1,bltdpt(a6)
        move.w  d0,bltamod(a6)
        move.w  d0,bltdmod(a6)
        move.l  #-1,bltafwm(a6)
        move.w  #(8*64)+(SCREEN_W/16),bltsize(a6) * wider blit than usual due to restrictions
        
        cmp.w   #WCUBE_MAX_SIZE,a4
        blt     .newsize

        * plotbuffer high word
        move.l  plotbuffer(a5),d0
        lea.l   plothigh,a0
        swap    d0
        move.w  d0,2(a0)

        * set initial values
        move.w  #$4200,curr_bplcon
        move.w  #5,zoomlevel
        move.w  #0,drawwall
        * set palette
        move.l  #OutPalette,current_palette
        rts


Wallcube_Effect:
        jsr     MemFreeLast                     * free memory reserved be previous effect (in the other mem direction)
        jsr     SetBgTask

        lea.l   Script,a0
        jsr     Commander_Init
        
        lea.l   custom,a6
        jsr     WaitEOF
        move.l  WallCubeVars,a5
        move.l  frontcopper(a5),cop2lc(a6)
        lea     Maincop,a0
        move.l  a0,cop1lc(a6)

.mainloop
        jsr     UpdateFrame
        jsr     VSyncWithBgTask

        jsr     PartOver
        blt     .mainloop

        move.w  #WALLCUBE_ENDCOL,BlankBg
        rts


CPULINES = 64
UpdateFrame:
        move.l  routine,d0
        tst.l   d0
        beq     .noroutine
        move.l  d0,a0
        jsr     (a0)
.noroutine
        rts

Wallcube_routine:
        * initialize new copperlist
        move.l  WallCubeVars,a5

        move.w  zoomlevel,d0                    * this indicates the width/height of the cube
        move.w  d0,cubesize(a5)                 * save for later use

        * clear the visible screen
        move.w  d0,d1
        add.w   d1,d1
        lsl.w   #6,d1                           * number of lines of clearing blit_width
        or.w    #WCUBE_BITMAP_W/16,d1           * bltsize
        lea.l   custom,a6                       * custom
        move.l  backbuffer(a5),a0
        WAIT_BLIT
        move.l  #$01000000,bltcon0(a6)          * only d ch, descending mode
        move.l  #-1,bltafwm(a6)                 * no mask
        move.l  a0,bltdpt(a6)                   * backbuffer is the start of bitmap to be cleared
        move.w  #0,bltdmod(a6)
        move.w  d1,bltsize(a6)                  * start clearing

        * start drawing procedure
        move.w  #SCREEN_W*2,d1
        sub.w   cubesize(a5),d1
        lsr.w   #1,d1
        move.w  d1,cubexoffset(a5)

        * look up scaling table for drawing
        move.l  scaling_table(a5),a1
        move.w  zoomlevel,d1
        mulu.w  #WCUBE_MAX_SIZE,d1
        *lsl.w   #8,d1
        adda.l  d1,a1
        * find right set of coords, for now pretend it's tempcube
        lea.l   RotatedCubePoints2d,a3
        add.w   #1,Cubeframe
        and.w   #CUBE_FRAMES-1,Cubeframe
        move.w  Cubeframe,d0
        move.w  d0,d1
        lsl.w   #5,d0
        lea.l   (a3,d0.w),a3
        lea.l   FrontBackColor,a2
        lsl.w   #3,d1
        lea.l   (a2,d1.w),a2
        move.w  #(WCUBE_BITMAP_W/8)*2,d4        * bitmap width, times 2 for interleaved
        lea.l   CubeFaces,a4
        move.w  #5,d7                           * number of faces
.newface
        btst    d7,1(a2)                        * visible face?
        bne.s   .drawface  
        adda.l  #18,a4
        dbf     d7,.newface
        bra     .enddraw
.drawface
        move.w  (a4)+,d5                        * d6 is color
        move.w  #4-1,d6                         * num edges
.newedge
        move.w  (a4)+,d2                        * first vertex
        add.w   d2,d2
        add.w   d2,d2
        move.w  (a3,d2.w),d0
        move.b  (a1,d0.w),d0                    * new x
        move.w  2(a3,d2.w),d1
        move.b  (a1,d1.w),d1                    * new y

        move.w  (a4)+,d3                        * x2
        add.w   d3,d3
        add.w   d3,d3
        move.w  (a3,d3.w),d2
        move.b  (a1,d2.w),d2                    * new x
        move.w  2(a3,d3.w),d3
        move.b  (a1,d3.w),d3                    * new y

        add.w   cubexoffset(a5),d0
        add.w   cubexoffset(a5),d2

        * x and y are set. now we must move X's relative to middle of screen. I.e. for 64pix cube: (bitmap_w/2)-(cubesize/2)

        btst    #0,d5                           * first bit of colors
        beq.s   .nopl1                          * don't draw on first plane
        movem.l d0-d7/a1-a5,-(sp)
        WAIT_BLIT
        move.l  backbuffer(a5),a0
        bsr     BlitterEdgeLine
        movem.l (sp)+,d0-d7/a1-a5
.nopl1  btst    #1,d5
        beq.s   .nopl2
        move.l  backbuffer(a5),a0
        add.l   #(WCUBE_BITMAP_W/8),a0          * move to second interleaved bitplane
        movem.l d0-d7/a1-a5,-(sp)
        WAIT_BLIT
        bsr     BlitterEdgeLine
        movem.l (sp)+,d0-d7/a1-a5
.nopl2
        dbf     d6,.newedge
        dbf     d7,.newface
.enddraw
        * now proceed with filling the polygons
        move.l  backbuffer(a5),a0
        move.w  cubexoffset(a5),d0
        lsr.w   #4,d0
        add.w   d0,d0
        lea.l   (a0,d0.w),a1                    * xpos in bytes

        move.w  cubesize(a5),d0                 * size of actual cube boundingbox
        move.w  #WCUBE_BITMAP_W/8,d5

        move.w  d0,d1                           * height in lines of one plane
        add.w   d1,d1                           * number of lines in two planes
        move.w  d1,d2                           
        mulu    d5,d2                           * end of the last line of the lines to fill
        subq    #2,d2                           * subtract for descending mode 

        move.w  d0,d3
        lsr.w   #4,d3
        addq    #2,d3                           * number of word to blit

        move.w  d5,d4                           * width of bitmap one plane
        sub.w   d3,d4                           * subtract #word to get modulo
        sub.w   d3,d4                           * subtract #word to get modulo --> this is the modulo

        sub.w   d4,d2                           * subtract the modulo from the buffer end ptr
        lea.l   (a1,d2.w),a1                    * dptr

        lsl.w   #6,d1
        or.w    d3,d1                           * bltsize

        ; BLIT_HOG
        WAIT_BLIT
        ; BLIT_UNHOG
        move.l  #-1,bltafwm(a6)                 * no mask
        move.l  #$09f00012,bltcon0(a6)          * only d ch
        move.l  a1,bltapt(a6)                   * backbuffer is the end of fill sector
        move.l  a1,bltdpt(a6)                   * backbuffer is the end of fill sector
        move.w  d4,bltamod(a6)                  * set modulo
        move.w  d4,bltdmod(a6)                  * set modulo
        move.w  d1,bltsize(a6)

        * start making the copperlist
        * preamble with registers fixed over screen (i.e. cop2lc, the bitmap high pointers)
        * write preamble to copperlist
        move.l  backcopper(a5),a0               * address of the copper list
        move.l  frontcopper(a5),d0
        move.w  #$0084,(a0)+
        swap    d0
        move.w  d0,(a0)+
        move.w  #$0086,(a0)+
        swap    d0
        move.w  d0,(a0)+

        * set overall palette
        move.l  #$0180,d0
        move.l  current_palette,a2
        move.l  #$0002,d1
        move.w  #16-1,d7
.col
        move.w  d0,(a0)+
        move.w  (a2)+,(a0)+
        add.w   d1,d0
        dbf     d7,.col

        move.l  #$01004200,d0
        move.w  curr_bplcon,d0
        move.l  d0,(a0)+        
        * calculate dx and dy for copperlist
        move.w  cubesize(a5),d0                 * this indicates the width/height of the cube
        move.w  #SCREEN_H/2,d2                  * start in the middle of the screen
        move.w  d0,d3
        lsr.w   #1,d3                           * substract half a cube 
        sub.w   d3,d2                           * this should be ok regardless of size of cube. cube is never>256
.find_dy
        sub.w   d0,d2                           * substract next cube from middle
        bgt.s   .find_dy                        * go on until in the negative
        tst.w   d2
        beq.s   .noremainder
        * there is a remainder, so we should adjust the first row of cubes
        move.w  d2,d3
        neg.w   d3
        mulu    #(WCUBE_BITMAP_W/8)*2,d3        * mul with line length * planes
        move.w  d2,d4                           
        add.w   d0,d4                           * now we have a different height for this first row: d4 counter for cube height
.noremainder
        move.l  backbuffer(a5),d5
        move.l  #$00e20014,d1                   * the main bplptrs for resetting the cube
        move.l  #$00ea0064,d2
        add.w   d5,d1
        add.w   d5,d2
        move.l  d1,d5
        add.w   d3,d5
        move.l  d2,d6
        add.w   d3,d6
        move.l  d5,(a0)+                        * pre screen cube bplptrs
        move.l  d6,(a0)+
        move.l  d1,a3
        move.l  d2,a4

        *d1/d2 bplptrs for cubes; d4 counter for cube height; 
        *d7 line decrementer        

        * prepare logo bplptr stuff
        move.l  plotbuffer(a5),a1
        move.w  d0,d1
        subq    #1,d1
        mulu    #8*SCREEN_W/8,d1
        lea.l   (a1,d1.w),a1                    * first line of logo (empty)
        move.l  #$00ee0000,d6
        move.w  a1,d6                           ' d6 is logo bplptr'

        * ensure the bitplane will start with zero unless any other info comes up
        move.l  d6,(a0)+

        * determine: how many cubes to skip (0-some)
        moveq   #8-1,d3                         * logo lines counter
        moveq   #0,d5                           * pixel lines to skip

        move.w  #SCREEN_H/2,d1
        move.w  d0,d2
        lsr.w   #1,d2
        sub.w   d2,d1                           * start of middle logo line

        move.w  d0,d2
        add.w   d2,d2
        add.w   d2,d2                           * go four pixels back
        sub.w   d2,d1                           * now we're at the top of the logo -linewise

        moveq   #0,d5                           * a counter for visible shifts

        move.w  d1,d2
        add.w   d0,d2

        tst.w   d2                              * is the first line of the logo 
        bpl.s   .visible_first                  * first line is visible

        * the first shift is not visible!
        moveq   #0,d3                           * then we can start at any time
        add.w   #SCREEN_W/8,d6                  * and we can start with the next line as bplptr
        addq    #1,d5   
        bra     .loopstart

.visible_first
        move.l  d6,(a0)+                        
        move.w  d1,d3
        subq    #1,d3

.loopstart
        * d3 = counter logo line; d6 = bplptr of current logoline
        * d5 counter of skippable logo lines
        move.w  #(WCUBE_YSTART*$100)+$df,d0     * this is the line counter start line
        *move.w  #SCREEN_H-1,d7
        moveq   #0,d7
.newline
        move.w  d0,(a0)+
        move.w  #$fffe,(a0)+

        * descrement cube height counter
        subq    #1,d4
        bne.s   .nocube
        move.w  cubesize(a5),d4
        move.l  a3,(a0)+
        move.l  a4,(a0)+

        cmp.w   d3,d7                           * raster line in d3 not reached yet
        blt.s   .nocube                         *skip logo stuff
        cmp.w   #8,d5
        beq.s   .nocube
        move.w  #$00ee,(a0)+                    * set bplptr for cube
        move.w  d6,(a0)+
        add.w   #SCREEN_W/8,d6                  * update bplptr with next line
        addq    #1,d5
.nocube
        add.w   #$0100,d0                       * move to next line
        addq    #1,d7
        cmp.w   #SCREEN_H,d7
        bne.s   .newline
        *        dbf     d7,.newline
        move.w  d0,(a0)+
        move.w  #$fffe,(a0)+
        move.l  #$01000200,(a0)+
        move.l  #-2,(a0)+

        tst.w   drawwall
        beq     .postcopy

        * Copy cubes to the left in ascending blitter mode     
        move.l  backbuffer(a5),a0
        move.w  cubexoffset(a5),a4              * "main" cube x position (left edge) on bitmap; counter for # cubes
.nextcube
        move.w  cubexoffset(a5),d0              * get original x position
        move.w  cubesize(a5),d2                 * size of cube (width and height)
        move.w  a4,d1
        sub.w   d2,d1                           * left cube's x position (destination)

        move.w  d2,d3                           * get cubesize
        add.w   d3,d3                           * height of cube bitmap
        lsl.w   #6,d3                           * bltsize lines

        move.w  d2,d5
        lsr.w   #4,d5                           * cube width in words
        addq    #2,d5                           * add two words: one for including the pixels before the word boundary and another for possible shifting.
        move.w  d5,d4                           * save width of blit
        or.w    d3,d5                           * bltsize ready

        add.w   d4,d4                           * blit width in bytes
        move.w  #(WCUBE_BITMAP_W/8),d3          * get bitmap width in bytes
        sub.w   d4,d3                           * modulo for all ch

        move.w  d0,d6                           * get current x position
        lsr.w   #4,d6                           * reduce to word offset
        add.w   d6,d6                           * byte offset of source
        lea.l   (a0,d6.w),a1                    * source pointer

        move.w  d1,d6                           * byte offset of destination x
        lsr.w   #4,d6
        add.w   d6,d6
        lea.l   (a0,d6.w),a2                    * destination address: move d6 bytes 

        move.w  d0,d4                           * source x position of cube
        and.w   #$f,d4                          * get within-word x-pos
        move.w  d1,d6                           * get destination x
        and.w   #$f,d6                          * within-word x-position of dest cube

        sub.w   d4,d6                           * effective shift value
        bge.s   .noswitchshift                  * if the value is positive all clear
        add.w   #16,d6                          * if the value is negative we need to add one word to the shift
        lea.l   -2(a2),a2                       * and move the destination pointer one word back
.noswitchshift
        move.l  #$0bfa,d2
        
        ror.w   #4,d6                           * position shift bits
        or.w    d6,d2                           * bltcon
        swap    d2
        *blit the cube
        WAIT_BLIT
        move.l  d2,bltcon0(a6)                  * bltcon0
        move.l  #-1,bltafwm(a6)                 * mask
        move.l  a1,bltapt(a6)
        move.l  a2,bltcpt(a6)
        move.l  a2,bltdpt(a6)
        move.w  d3,bltdmod(a6)                  * modulos
        move.w  d3,bltamod(a6)
        move.w  d3,bltcmod(a6)
        move.w  d5,bltsize(a6)

        * repeat this process, if there is still room on the sides
        move.w  a4,d1
        move.w  cubesize(a5),d2
        sub.w   d2,d1
        move.w  d1,a4                           * this will be used in the logo plotting below

        sub.w   #SCREEN_W/2,d1
        tst.w   d1
        bgt     .nextcube

        * we now have a full set of cubes on the left. Let's copy those cubes to the right side of the first middle cube 
        lea.l   blittermasks,a3
        move.l  backbuffer(a5),a0
        move.w  a4,d0                           * pixel position containing the first pixel of source data
        move.w  cubexoffset(a5),d1              * start of rightmost, original cube
        move.w  d1,d2                           * save end xpos of data
        sub.w   d0,d2                           * width of copy blit
        move.w  cubesize(a5),d3                 * where does the blit go?
        add.w   d3,d1                           * destination xpos

        add.w   d3,d3                           * height of cube bitmap
        lsl.w   #6,d3                           * bltsize lines

        lsr.w   #4,d2                           * in words
        addq    #2,d2                           * with extra room for shifting, in words
        move.w  d2,d4                           * save width of blit
        or.w    d2,d3                           * bltsize ready

        add.w   d4,d4                           * blit width in bytes
        move.w  #(WCUBE_BITMAP_W/8),d5          * get bitmap width in bytes
        sub.w   d4,d5                           * modulo for all ch

        move.w  d0,d6                           * get current x position
        lsr.w   #4,d6                           * reduce to word offset
        add.w   d6,d6                           * byte offset of source
        lea.l   (a0,d6.w),a1                    * source pointer

        move.w  d1,d6                           * byte offset of destination x
        lsr.w   #4,d6
        add.w   d6,d6
        lea.l   (a0,d6.w),a2                    * destination address: move d6 bytes 

        move.w  d0,d4                           * source x position of cube
        and.w   #$f,d4                          * get within-word x-pos

        move.w  #$ffff,d7
        lsr.w   d4,d7                           * diff first word mask
        swap    d7
        move.w  #$0,d7                          * full lastword mask

        move.w  d1,d6                           * get destination x
        and.w   #$f,d6                          * within-word x-position of dest cube

        sub.w   d4,d6                           * effective shift value
        bge.s   .noswitchshift2                 * if the value is positive all clear
        add.w   #16,d6                          * if the value is negative we need to add one word to the shift
        and.w   #$f,d6
        lea.l   -2(a2),a2                       * and move the destination pointer one word back
.noswitchshift2
        move.l  #$0bfa,d2

        ror.w   #4,d6                           * position shift bits
        or.w    d6,d2                           * bltcon
        swap    d2
        *blit the cube
        WAIT_BLIT
        move.l  d2,bltcon0(a6)                  * bltcon0
        move.l  d7,bltafwm(a6)                  * mask
        move.l  a1,bltapt(a6)
        move.l  a2,bltcpt(a6)
        move.l  a2,bltdpt(a6)
        move.w  d5,bltdmod(a6)                  * modulos
        move.w  d5,bltamod(a6)
        move.w  d5,bltcmod(a6)
        move.w  d3,bltsize(a6)

.postcopy
        * switch pointers to buffers
        move.l  backbuffer(a5),d0
        move.l  frontbuffer(a5),d3
        move.l  d3,backbuffer(a5)
        move.l  d0,frontbuffer(a5)

        move.l  backcopper(a5),d0
        move.l  frontcopper(a5),d3
        move.l  d3,backcopper(a5)
        move.l  d0,frontcopper(a5)

        rts

blackscreen
        move.l  WallCubeVars,a5
        move.l  backcopper(a5),a0
        move.l  frontcopper(a5),d0
        move.w  #$0084,(a0)+
        swap    d0
        move.w  d0,(a0)+
        move.w  #$0086,(a0)+
        swap    d0
        move.w  d0,(a0)+
        move.l  #-2,(a0)+
        * switch pointers to buffers
        move.l  backbuffer(a5),d0
        move.l  frontbuffer(a5),d3
        move.l  d3,backbuffer(a5)
        move.l  d0,frontbuffer(a5)

        move.l  backcopper(a5),d0
        move.l  frontcopper(a5),d3
        move.l  d3,backcopper(a5)
        move.l  d0,frontcopper(a5)

        rts

blittermasks:
        dc.l    $ffff0000
        dc.l    $7fff0000
        dc.l    $3fff0000
        dc.l    $1fff0000
        dc.l    $0fff0000
        dc.l    $07ff0000
        dc.l    $03ff0000
        dc.l    $01ff0000
        dc.l    $00ff0000
        dc.l    $007f0000
        dc.l    $003f0000
        dc.l    $001f0000
        dc.l    $000f0000
        dc.l    $00070000
        dc.l    $00030000
        dc.l    $00010000
        dc.l    $00000000



LINE_MINTERM = $4a                              ; xor
;----------------------------------------------------------------------------------
; Draw blitter edge line for blitter area fill
; The routine assumes that the blitter is idle when called
; The routine will exit with the blitter active
; in	d0.w	x0
;	d1.w	y0
;	d2.w	x1
;	d3.w	y1
;	d4.w	bytes per row in bitplane
;	a0	bitplane
;	a6	$dff000

BlitterEdgeLine
        move.w  d4,a1
		
        cmp.w   d1,d3
        bge.s   .downward
        exg     d0,d2
        exg     d1,d3
.downward

        sub.w   d0,d2
        sub.w   d1,d3
		
        move.w  d2,d4
        bpl.s   .positiveDX
        neg.w   d4
.positiveDX
        move.w  d3,d5
        bpl.s   .positiveDY
        neg.w   d5
.positiveDY
        move.w  d4,d6
        sub.w   d5,d6
        add.l   d6,d6
        move.w  d3,d6
        add.l   d6,d6
        move.w  d2,d6
        add.l   d6,d6
        swap    d6
        and.w   #7,d6
        lea     .octant_lookup,a2
        move.b  (a2,d6.w),d6
        or.w    #BLTCON1F_SING|BLTCON1F_LINE,d6

        cmp.w   d4,d5
        bls.s   .absDyLessThanAbsDx
        exg     d4,d5
.absDyLessThanAbsDx

        move.w  d5,d7
        add.w   d7,d7
        sub.w   d4,d7
        add.w   d7,d7
        ext.l   d7
        move.l  d7,bltapt(a6)
        bpl.s   .positiveGradient
        or.w    #BLTCON1F_SIGN,d6
.positiveGradient

        add.w   d4,d4
        add.w   d4,d4
        add.w   d5,d5
        add.w   d5,d5
        move.w  d5,bltbmod(a6)
        sub.w   d4,d5
        move.w  d5,bltamod(a6)
        lsr.w   #2,d4

        move.w  #$8000,bltadat(a6)
        move.l  #$ffffffff,bltafwm(a6)

        move.w  d0,d2
        and.w   #$f,d2
        ror.w   #4,d2
		
        move.w  #$ffff,bltbdat(a6)

        move.w  a1,d7
        mulu.w  d1,d7
        add.l   d7,a0
        move.w  d0,d7
        lsr.w   #4,d7
        add.w   d7,d7
        add.w   d7,a0
        move.l  a0,bltcpt(a6)
        move.l  #blitter_temp_output_word,bltdpt(a6)
		
        move.w  a1,bltcmod(a6)
        move.w  a1,bltdmod(a6)

        or.w    #BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|LINE_MINTERM,d2
        move.w  d2,bltcon0(a6)
        move.w  d6,bltcon1(a6)
        addq.w  #1,d4
        lsl.w   #6,d4
        addq.w  #2,d4
        move.w  d4,bltsize(a6)
        rts
		
.octant_lookup
        dc.b    BLTCON1F_SUD                    ; octant 7
        dc.b    BLTCON1F_SUD|BLTCON1F_AUL       ; octant 4
        dc.b    BLTCON1F_SUD|BLTCON1F_SUL       ; octant 0
        dc.b    BLTCON1F_SUD|BLTCON1F_SUL|BLTCON1F_AUL ; octant 3
        dc.b    0                               ; octant 6
        dc.b    BLTCON1F_SUL                    ; octant 5
        dc.b    BLTCON1F_AUL                    ; octant 1
        dc.b    BLTCON1F_SUL|BLTCON1F_AUL       ; octant 2


        section wallcubedata,data

routine: dc.l   blackscreen

Script: 
        dc.l    20,CmdMoveIW,140,zoomlevel
        dc.l    21,CmdMoveIL,Wallcube_routine,routine
        dc.l    149,CmdMoveIL,blackscreen,routine
        dc.l    150,CmdMoveIW,1,drawwall
        dc.l    220,CmdMoveIW,85,zoomlevel
        dc.l    221,CmdMoveIL,Wallcube_routine,routine
        dc.l    329,CmdMoveIL,blackscreen,routine
        dc.l    330,CmdMoveIW,30,zoomlevel
        dc.l    331,CmdMoveIL,Wallcube_routine,routine
        dc.l    450,CmdLerpWord, 8,6,zoomlevel
        dc.l    600,CmdLerpPal,16-1,5,LogoPalette,WallPalette,current_palette
        dc.l    651,CmdLerpWord,40,5,zoomlevel
        dc.l    901,CmdLerpWord,80,7,zoomlevel
        dc.l    1150,CmdMoveIW,0,drawwall
        dc.l    1150,CmdLerpWord,192,7,zoomlevel
        dc.l    1200,CmdLerpPal,16-1,5,WallPalette,WhitePalette,current_palette
        * fade to white
        dc.l    0,0

curr_bplcon: dc.w $4200
current_palette: dc.l OutPalette


WallCubeVars: dc.l 0
rsreset
cubesize: rs.w  1
frontbuffer: rs.l 1
frontcopper: rs.l 1
backbuffer: rs.l 1
backcopper: rs.l 1
scaling_table: rs.l 1
cubexoffset: rs.w 1
plotbuffer: rs.l 1
logoypos: rs.w  9

WallCubeVars_SIZEOF so

        * bitplane 1: plane 1 of cube
        * bitplane 2: fill      (320x256)
        * bitplane 3: plane 2 of cube
        * bitplane 4: logo lines (320x256)

LogoPalette:
        dc.w    $000,$6a8,$6a8,$6a8             * %0000 backgr, %0001 plane1, %0010 fill, %0011 plane1+fill
        dc.w    $6a8,$6a8,$6a8,$6a8             * %0100 plane2, %0101 plane2+plane1, %0110 plane2+fill, %0111 plane2+plane1+fill
        dc.w    $fff,$fff,$6a8,$000             * %1000 logo+backgr, %1001 logo+plane1, %1010 logo+fill, %1011 logo+plane1+fill
        dc.w    $fff,$fff,$f0f,$fff             * %1100 logo+plane2, %1101 logo+plane2+plane1, %1110 logo+plane2+fill, %1111 logo+plane2+plane1+fill

WallPalette:
        dc.w    $000,$fff,$6a8,$000             * %1000 logo+backgr, %1001 logo+plane1, %1010 logo+fill, %1011 logo+plane1+fill
        dc.w    $fff,$fff,$f0f,$fff             * %1100 logo+plane2, %1101 logo+plane2+plane1, %1110 logo+plane2+fill, %1111 logo+plane2+plane1+fill
        dc.w    $fff,$fff,$6a8,$000             * %1000 logo+backgr, %1001 logo+plane1, %1010 logo+fill, %1011 logo+plane1+fill
        dc.w    $fff,$fff,$f0f,$fff             * %1100 logo+plane2, %1101 logo+plane2+plane1, %1110 logo+plane2+fill, %1111 logo+plane2+plane1+fill

WhitePalette:
        dc.w    $000,$fff,$fff,$fff             * %1000 logo+backgr, %1001 logo+plane1, %1010 logo+fill, %1011 logo+plane1+fill
        dc.w    $fff,$fff,$fff,$fff             * %1000 logo+backgr, %1001 logo+plane1, %1010 logo+fill, %1011 logo+plane1+fill
        dc.w    $fff,$fff,$fff,$fff             * %1000 logo+backgr, %1001 logo+plane1, %1010 logo+fill, %1011 logo+plane1+fill
        dc.w    $fff,$fff,$fff,$fff             * %1000 logo+backgr, %1001 logo+plane1, %1010 logo+fill, %1011 logo+plane1+fill

OutPalette:
        dc.w    $000,$6a8,$6a8,$6a8             * %0000 backgr, %0001 plane1, %0010 fill, %0011 plane1+fill
        dc.w    $6a8,$6a8,$6a8,$6a8             * %0100 plane2, %0101 plane2+plane1, %0110 plane2+fill, %0111 plane2+plane1+fill
        dc.w    $fff,$fff,$6a8,$000             * %1000 logo+backgr, %1001 logo+plane1, %1010 logo+fill, %1011 logo+plane1+fill
        dc.w    $fff,$fff,$f0f,$fff             * %1100 logo+plane2, %1101 logo+plane2+plane1, %1110 logo+plane2+fill, %1111 logo+plane2+plane1+fill

BlackPalette: blk.w 16,$000

zoomlevel: dc.l 0
drawwall: dc.w  0

logopixels:
        dc.b    1,0,0,0,0,0
        dc.b    1,0,0,0,0,0
        dc.b    1,1,1,1,1,1
        dc.b    1,0,0,0,0,0
        dc.b    1,0,0,0,0,0
        dc.b    0,0,0,0,0,0
        dc.b    0,1,1,1,1,1
        dc.b    1,0,0,1,0,0
        dc.b    1,0,0,1,0,0
        dc.b    0,1,1,1,1,1
        dc.b    0,0,0,0,0,0
        dc.b    1,1,1,1,1,1
        dc.b    0,0,0,0,0,1
        dc.b    0,0,0,0,0,1
        dc.b    0,0,0,0,0,1
        dc.b    0,0,0,0,0,0
        dc.b    1,1,1,1,1,1
        dc.b    1,0,1,0,0,1
        dc.b    1,0,1,0,0,1
        dc.b    1,0,0,0,0,1
        dc.b    0,0,0,0,0,0
        dc.b    1,1,1,1,1,1
        dc.b    0,1,0,0,0,0
        dc.b    0,0,1,0,0,0
        dc.b    0,0,0,1,0,0
        dc.b    1,1,1,1,1,1
        dc.b    0,0,0,0,0,0
        dc.b    1,0,0,0,0,0
        dc.b    1,0,0,0,0,0
        dc.b    1,1,1,1,1,1
        dc.b    1,0,0,0,0,0
        dc.b    1,0,0,0,0,0
        dc.b    0,0,0,0,0,0
logopixels_end
        even

        section chipdata, data_c

fillline: blk.b SCREEN_W/8,$ff
blitter_temp_output_word dc.w 0

Blankcop dc.l   -2
Maincop:
        dc.w    $008e,$2c81,$0090,$2cc1,$0092,$0038,$0094,$00d0
        dc.w    $0180,$0000,$0100,$0200,$0102,$0000
        dc.w    $010a,$0000-40,$0108,((WCUBE_BITMAP_W/8)/2)+(WCUBE_BITMAP_W/8)
Fillplane:
        dc.w    $00e4,$0000,$00e6,$0000
highbpls:
        dc.w    $00e0,$0000
        dc.w    $00e8,$0000
plothigh:
        dc.w    $00ec,$0000                     * low word gets set in routine
thecopjmp:
        dc.w    copjmp2,$0000

