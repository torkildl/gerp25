* Scrolling truchet tiles with text overlay
*       
        incdir  include
        include hw.i
        include src/_main.i
        include src/truchet.i
        include common-timings.i

TILE_W = 16
TILE_H = 16
TILE_ORDER = $fec92941
TILENUM = 64                                    * 64 * 16 = 1024 pixels wide and tall map, 
                                                * which means we can modulo xpos/ypos 511 and be ok.
TILEMAP_W = TILENUM*TILE_W
TILEMAP_H = TILENUM*TILE_H

COP_BUF_SIZE = 4*1024

SCREEN_W = 352
SCREEN_H = 272

START_Y = $1c                                   *$2c+$80-(SCREEN_H/2)-1
STOP_Y = START_Y+SCREEN_H                       ;-TILE_H+1

TILEMAP_SZ = TILENUM*(TILE_W/8)*TILE_H
DRAWBUF_SZ = (SCREEN_W/8)*(SCREEN_H+16)
CHIPREQ = (COP_BUF_SIZE+TILEMAP_SZ+DRAWBUF_SZ)


truchet_precalc:
        jsr     MemFlip
        lea.l   custom,a6

        ALLOC_PUBLIC Truchet_Vars_SIZEOF,a5
        move.l  a5,Truchet_Vars

        move.l  #0,credits_data(a5)

        * Prepare copperlists. Puncture so there is no overflow anything
        ALLOC_CHIP COP_BUF_SIZE,a0
        move.l  a0,frontcopper(a5)
        move.l  #-2,(a0)
        ALLOC_CHIP COP_BUF_SIZE,a0
        move.l  a0,backcopper(a5)
        move.l  #-2,(a0)
        * allocate room for tilemap
        ALLOC_CHIP TILEMAP_SZ,tilemap_ptr(a5)
        * allocate space for drawing buffer
        ALLOC_CHIP DRAWBUF_SZ*3,a0              * a0 start
        move.l  a0,a1
        move.l  a0,frontbuffer(a5)
        add.l   #DRAWBUF_SZ,a0
        move.l  a0,backbuffer(a5)
        add.l   #DRAWBUF_SZ,a0
        move.l  a0,a2                           * end for clearing
        move.l  a0,a3                           * end of fillbuffer
        move.l  a0,fillbuffer(a5)
        move.l  a0,d2
        add.l   #DRAWBUF_SZ,a0                  * this is the end of final buffer
        lea.l   CopFill,a4
        move.w  d2,6(a4)
        swap    d2
        move.w  d2,2(a4)                

        moveq   #0,d0
        moveq   #0,d1
        moveq   #0,d2
        moveq   #0,d3
        moveq   #0,d4
        moveq   #0,d5
        moveq   #0,d6
        moveq   #0,d7
.clrbit
        movem.l d0-d7,-(a2)
        cmp.l   a1,a2
        bne.s   .clrbit
        moveq.l #-1,d0
        moveq.l #-1,d1
        moveq.l #-1,d2
        moveq.l #-1,d3
        moveq.l #-1,d4
        moveq.l #-1,d5
        moveq.l #-1,d6
        moveq.l #-1,d7
.fillbit
        movem.l d0-d7,-(a0)
        cmp.l   a0,a3
        bne.s   .fillbit

        * make the tilemap
        lea.l   truchet_tile,a1
        lea.l   mirrored_tile,a2
        lea.l   TILE_H*(TILE_W/8)(a2),a0
        move.w  #TILE_H-1,d7
.nrow
        move.w  (a1)+,-(a0)
        dbf     d7,.nrow
        lea.l   -TILE_H*(TILE_W/8)(a1),a1
        move.l  tilemap_ptr(a5),a0
        move.l  #TILE_ORDER,d6

        move.w  #(TILEMAP_W-TILE_W)/8,d0
        move.w  #TILENUM-1,d7
.anothertile
        WAIT_BLIT
        move.l  #$090f0000,bltcon0(a6)
        move.l  #-1,bltafwm(a6)
        move.w  #0,bltamod(a6)
        move.l  a1,bltapt(a6)
        move.w  d0,bltdmod(a6)
        move.l  a0,bltdpt(a6)
        move.w  #(TILE_H*64)+(TILE_W/16),bltsize(a6)
        adda.l  #2,a0
        ror.l   d6
        btst    #0,d6
        beq.s   .noswitch
        exg.l   a1,a2
.noswitch
        dbf     d7,.anothertile

        lea.l   A_tileoffsets(a5),a0
        move.l  a0,a1
        adda.l  #2,a0
        move.w  #(TILENUM/2)-2,d7
.ntile  jsr     Random32
        and.w   #(TILENUM/2)-1,d0
        add.w   d0,d0
        move.w  d0,(a0)+
        dbf     d7,.ntile
        * copy the first 32 row offsets to the next 32 row offsets (includign the first zero)
        move.w  #(TILENUM/2)-1,d7
.ntile2
        move.w  (a1)+,(a0)+
        dbf     d7,.ntile2

        lea.l   CopMods,a0
        move.w  #-2+((TILEMAP_W-SCREEN_W)/8),d0
        move.w  #-2,d1                          * odd numbered planes
        move.w  d1,2(a0)
        move.w  d0,6(a0)

        rts                                     ; Return


truchet_effect: 
        jsr     MemFreeLast
        jsr     SetBgTask

        lea.l   Script,a0
        jsr     Commander_Init

        move.l  Truchet_Vars,a5
        lea.l   custom,a6

        move.l  frontcopper(a5),cop2lc(a6)
        jsr     WaitEOF
        move.l  #Maincop,cop1lc(a6)
.mainloop
        bsr     truchet_mainsegment
        jsr     VSyncWithBgTask
        jsr     PartOver
        blt.s   .mainloop      
        rts

A_XSPEED = 2
A_XSPEED2 = -3
A_YSPEED = 3
A_YSPEED2 = -4

TILEMAP_RAD_X = 256
TILEMAP_RAD_Y = 256


truchet_mainsegment:
        move.l  Truchet_Vars,a5
        lea.l   custom,a6        
        * copper preamble
        move.l  backbuffer(a5),a0               * set bitplane for credits
        WAIT_BLIT
        move.l  #$01000000,bltcon0(a6)
        move.l  #-1,bltafwm(a6)
        move.w  #0,bltdmod(a6)
        move.l  a0,bltdpt(a6)
        move.w  #((SCREEN_H*64)+(SCREEN_W/16)),bltsize(a6)

        move.l  a0,d0                           * the draw buffer is on plane 1
        move.l  backcopper(a5),a0
        move.w  #$00e2,(a0)+
        move.w  d0,(a0)+
        swap    d0
        move.w  #$00e0,(a0)+
        move.w  d0,(a0)+

        * set colors
        move.w  #8-1,d7
        move.w  #$0180,d0
        move.l  current_palette,a2
.ncol   move.w  d0,(a0)+
        addq    #2,d0
        move.w  (a2)+,d1
        move.w  d1,(a0)+
        dbf     d7,.ncol

        lea.l   Sin,a2
        move.w  A_tilex(a5),d0
        add.w   #A_XSPEED,d0
        move.w  d0,A_tilex(a5)
        and.w   #$7fe,d0                        * sine table lookup
        move.w  (a2,d0.w),d0
        asr.w   #6,d0                           * get to +/-$4000 to +/-128

        move.w  A_tilex2(a5),d1
        add.w   #A_XSPEED2,d1
        move.w  d1,A_tilex2(a5)
        and.w   #$7fe,d1                        * sine table lookup
        move.w  (a2,d1.w),d1
        asr.w   #6,d1                           * get to +/-$4000 to +/-128

        add.w   d1,d0
        add.w   #512,d0                         * midpoint of tilemap
        and.w   #$1ff,d0                        * but modulo it to not overshoot on the xaxis

        move.w  A_tiley(a5),d2
        add.w   #A_YSPEED,d2
        move.w  d2,A_tiley(a5)
        and.w   #$7fe,d2                        * sine table lookup
        move.w  (a2,d2.w),d2
        asr.w   #6,d2                           * get to +/-$4000 to +/-128

        move.w  A_tiley2(a5),d1
        add.w   #A_YSPEED2,d1
        move.w  d1,A_tiley2(a5)
        and.w   #$7fe,d1                        * sine table lookup
        move.w  (a2,d1.w),d1
        asr.w   #6,d1                           * get to +/-$4000 to +/-128

        add.w   d2,d1
        add.w   #512,d1                         * midpoint of tilemap
        and.w   #$1ff,d1                        * but modulo it to not overshoot on the xaxis

        * d0 and d1 as with absolute X and Y values (0-1023), we can move around on the tilemap
        * the x value refers to actual position on the tilemap

        move.w  d0,d2                           * scroll value 102
        move.w  #15,d4
        and.w   #$f,d2
        sub.w   d2,d4                           * shift value
        lsl.w   #4,d4

        lsr.w   #4,d0                           * adjust bplptrs for xaxis
        add.w   d0,d0                           * pixels to adjust bplptrs with

        lea.l   A_tileoffsets(a5),a1            * list of tilemap offsets
        move.w  d1,d3
        lsr.w   #4,d3                           * hvor mange rader nedover skal vi?
        add.w   d3,d3
        lea.l   (a1,d3.w),a1                    * address of byte offset for first line

        move.w  d1,d6                           * get y
        and.w   #$f,d6                          * hvor i tile'n er vi på yaksen?
        move.w  #TILE_H,d7
        sub.w   d6,d7                           * remaining lines = height of first line: d7 remaining line counter
        mulu    #TILEMAP_W/8,d6                 * bytes to add to first bitplaneptr

        move.l  #$01003200,(a0)+                * only one bitplane
        move.w  #$0102,(a0)+                    * scroll is the same for all lines
        move.w  d4,(a0)+

        move.w  #START_Y-1,d4                   * y counter
        move.w  #STOP_Y,d1
        moveq   #0,d2
.newrow
        move.b  d4,(a0)+
        move.b  #$df,(a0)+
        move.w  #$fffe,(a0)+

        * establish bplptr
        moveq   #0,d5
        move.w  (a1)+,d5                        * byte offset for correct y line
        add.w   d0,d5                           * add base address
        and.l   #$3e,d5                         * modulo 32 tiles (512 pix)
        add.w   d6,d5                           * if first line, d6 may be nonzero
        add.l   tilemap_ptr(a5),d5              * base address for all lines

        * set bplptrs for one line
        move.w  #$00e4,(a0)+
        swap    d5
        move.w  d5,(a0)+
        swap    d5
        move.w  #$00e6,(a0)+
        move.w  d5,(a0)+
        moveq   #0,d6

        tst.w   d2
        bne.s   .nofix
        cmp.w   #$f0,d4
        blt.s   .nofix

        moveq   #1,d2                           * if we are here, there will be a ffdf
        cmp.w   #$ff,d4
        beq.s   .nofix                          * but wait until next row if it is exactly on $ff
        move.l  #$ffdffffe,(a0)+                * fix it if it is not
.nofix
        add.w   d7,d4                           *
        move.w  #TILE_H,d7                      * make sure remaining lines are appr height

        cmp.w   d1,d4
        blt.s   .newrow

        cmp.w   #STOP_Y,d1
        bge.s   .noadd
        move.w  #STOP_Y,d1
.noadd
        move.b  d1,(a0)+
        move.b  #$df,(a0)+
        move.w  #$fffe,(a0)+
        move.l  #$01000200,(a0)+

        move.l  frontcopper(a5),d3
        swap    d3
        move.w  #$0084,(a0)+
        move.w  d3,(a0)+
        move.w  #$0086,(a0)+
        swap    d3
        move.w  d3,(a0)+
        move.l  #-2,(a0)+

        move.l  effect,d0
        beq.s   .noeffect
        move.l  d0,a1
        jsr     (a1)
.noeffect

        * switch pointers to buffers
        move.l  backbuffer(a5),d0
        move.l  frontbuffer(a5),d3
        exg     d0,d3
        move.l  d0,backbuffer(a5)
        move.l  d3,frontbuffer(a5)

        move.l  backcopper(a5),d0
        move.l  frontcopper(a5),d3
        exg     d0,d3
        move.l  d0,backcopper(a5)
        move.l  d3,frontcopper(a5)

        rts

truchet_logosegment:
        * draw the credits based on info in script
        move.l  credits_data(a5),d0             * base bitmap address
        beq     .nodraw
        move.l  d0,a0
        move.w  credits_offsetx(a5),d0
        move.w  credits_offsety(a5),d1          * y position

        lea.l   Sin,a1                          * find sine value
        move.w  credits_sin1(a5),d2
        add.w   credits_sinspeed1(a5),d2
        move.w  d2,credits_sin1(a5)
        and.w   #$7fe,d2
        move.w  (a1,d2.w),d2                    * sin value (+/-$4000)
        asr.w   #8,d2
        asr.w   #2,d2
        add.w   #16,d2                          * 0-31
        add.w   d2,d1
        mulu    #SCREEN_W/8,d1                  * y offset on bitmap
        add.w   d0,d1
        move.l  backbuffer(a5),a2
        adda.w  d1,a2                           * destination address

        * how wide a blit?
        move.w  credits_currw(a5),d0
        cmp.w   #144,d0
        beq.s   .noaddw
        addq    #1,d0
        move.w  d0,credits_currw(a5)
.noaddw
        move.w  d0,d1
        lsr.w   #4,d0
        move.l  #$ffffffff,d2                   * D1   ; Start with all bits set; full lw for bltafwm+bltlfwm
        and.w   #$f,d1                          * how many extra bits?
        beq.s   .nomask
        addq    #1,d0                           * this many words (round wdown +1)
        subq    #1,d1
        move.w  #0,d2
.maskit
        lsr.w   #1,d2
        or.w    #$8000,d2
        dbf     d1,.maskit
.nomask
        move.w  #144/16,d1
        sub.w   d0,d1   
        add.w   d1,d1                           * bitmap modulo     
        move.w  #SCREEN_W/16,d3
        sub.w   d0,d3
        add.w   d3,d3

        move.w  #32*64,d4
        or.w    d0,d4
        WAIT_BLIT
        move.l  #$09f00000,bltcon0(a6)
        move.l  a0,bltapt(a6)
        move.l  a2,bltdpt(a6)
        move.l  d2,bltafwm(a6)
        
        move.w  d1,bltamod(a6)
        move.w  d3,bltdmod(a6)
        move.w  d4,bltsize(a6)

        * first blit is done, now move 32 lines ahead in the bitmap, and blit the next line and then the whole thing
        adda.w  #32*SCREEN_W/8,a2               * move down to the next destination
        adda.w  #32*(144/8),a0                  * move down on the source bitmap
                                                * d modulo is the same
        move.w  d0,d5
        add.w   d5,d5
        neg.w   d5                              * a modulo is negative, repeating every line

        move.w  credits_sin2(a5),d6
        add.w   credits_sinspeed2(a5),d6
        move.w  d6,credits_sin2(a5)
        and.w   #$7fe,d6
        move.w  (a1,d6.w),d6                    * sin value (+/-$4000)
        asr.w   #8,d6
        asr.w   #1,d6
        add.w   #33,d6                          * 0-31
        move.w  d6,d7
        lsl.w   #6,d6
        or.w    d0,d6                           * bltsize for line-repeater

        WAIT_BLIT
        move.l  #$09f00000,bltcon0(a6)
        move.l  a0,bltapt(a6)
        move.l  a2,bltdpt(a6)
        move.l  d2,bltafwm(a6)
        move.w  d5,bltamod(a6)
        move.w  d3,bltdmod(a6)
        move.w  d6,bltsize(a6)

        mulu    #SCREEN_W/8,d7
        adda.w  d7,a2
        * second half blit
        WAIT_BLIT
        move.l  #$09f00000,bltcon0(a6)
        move.l  a0,bltapt(a6)
        move.l  a2,bltdpt(a6)
        move.l  d2,bltafwm(a6)
        move.w  d1,bltamod(a6)
        move.w  d3,bltdmod(a6)
        move.w  d4,bltsize(a6)
.nodraw
        rts

truchet_creditssegment:
        * draw the credits based on info in script
        move.l  credits_data(a5),d0             * base bitmap address
        beq     .nodraw
        move.l  d0,a0
        move.w  credits_offsetx(a5),d0
        move.w  credits_offsety(a5),d1          * y position

        lea.l   Sin,a1                          * find sine value
        move.w  credits_sin1(a5),d2
        add.w   credits_sinspeed1(a5),d2
        move.w  d2,credits_sin1(a5)
        and.w   #$7fe,d2
        move.w  (a1,d2.w),d2                    * sin value (+/-$4000)
        asr.w   #8,d2
        asr.w   #2,d2
        add.w   #16,d2                          * 0-31
        add.w   d2,d1
        mulu    #SCREEN_W/8,d1                  * y offset on bitmap
        add.w   d0,d1
        move.l  backbuffer(a5),a2
        adda.w  d1,a2                           * destination address

        * how wide a blit?
        move.w  credits_currw(a5),d0
        cmp.w   #128,d0
        beq.s   .noaddw
        addq    #1,d0
        move.w  d0,credits_currw(a5)
.noaddw
        move.w  d0,d1
        lsr.w   #4,d0
        move.l  #$ffffffff,d2                   * D1   ; Start with all bits set; full lw for bltafwm+bltlfwm
        and.w   #$f,d1                          * how many extra bits?
        beq.s   .nomask
        addq    #1,d0                           * this many words (round wdown +1)
        subq    #1,d1
        move.w  #0,d2
.maskit
        lsr.w   #1,d2
        or.w    #$8000,d2
        dbf     d1,.maskit
.nomask
        move.w  #128/16,d1
        sub.w   d0,d1   
        add.w   d1,d1                           * bitmap modulo     
        move.w  #SCREEN_W/16,d3
        sub.w   d0,d3
        add.w   d3,d3

        move.w  #32*64,d4
        or.w    d0,d4
        WAIT_BLIT
        move.l  #$09f00000,bltcon0(a6)
        move.l  a0,bltapt(a6)
        move.l  a2,bltdpt(a6)
        move.l  d2,bltafwm(a6)
        
        move.w  d1,bltamod(a6)
        move.w  d3,bltdmod(a6)
        move.w  d4,bltsize(a6)

        * first blit is done, now move 32 lines ahead in the bitmap, and blit the next line and then the whole thing
        adda.w  #32*SCREEN_W/8,a2               * move down to the next destination
        adda.w  #32*(128/8),a0                  * move down on the source bitmap
                                                * d modulo is the same
        move.w  d0,d5
        add.w   d5,d5
        neg.w   d5                              * a modulo is negative, repeating every line

        move.w  credits_sin2(a5),d6
        add.w   credits_sinspeed2(a5),d6
        move.w  d6,credits_sin2(a5)
        and.w   #$7fe,d6
        move.w  (a1,d6.w),d6                    * sin value (+/-$4000)
        asr.w   #8,d6
        asr.w   #2,d6
        add.w   #17,d6                          * 0-31
        move.w  d6,d7
        lsl.w   #6,d6
        or.w    d0,d6                           * bltsize for line-repeater

        WAIT_BLIT
        move.l  #$09f00000,bltcon0(a6)
        move.l  a0,bltapt(a6)
        move.l  a2,bltdpt(a6)
        move.l  d2,bltafwm(a6)
        move.w  d5,bltamod(a6)
        move.w  d3,bltdmod(a6)
        move.w  d6,bltsize(a6)

        mulu    #SCREEN_W/8,d7
        adda.w  d7,a2
        * second half blit
        WAIT_BLIT
        move.l  #$09f00000,bltcon0(a6)
        move.l  a0,bltapt(a6)
        move.l  a2,bltdpt(a6)
        move.l  d2,bltafwm(a6)
        move.w  d1,bltamod(a6)
        move.w  d3,bltdmod(a6)
        move.w  d4,bltsize(a6)
.nodraw
        rts


SetLogoEffect:
        move.l  Truchet_Vars,a1
        move.l  #truchet_logosegment,effect
        move.l  #pastiche_logo,credits_data(a1)
        move.w  #16,credits_offsetx(a1)         * offset in bytes
        move.w  #48,credits_offsety(a1)
        move.w  #-37,credits_sinspeed1(a1)
        move.w  #19,credits_sinspeed2(a1)
        move.w  #0,credits_currw(a1)            * maximum columns to plot
        move.w  #0,credits_dx(a1)               * maximum columns to plot
        rts

SetCreditsCode:
        move.l  Truchet_Vars,a1
        move.l  #truchet_creditssegment,effect
        move.l  #credits_code,credits_data(a1)
        move.w  #22,credits_offsetx(a1)         * offset in bytes
        move.w  #32,credits_offsety(a1)
        move.w  #37,credits_sinspeed1(a1)
        move.w  #13,credits_sinspeed2(a1)
        move.w  #0,credits_currw(a1)            * maximum columns to plot
        move.w  #1,credits_dx(a1)               * maximum columns to plot
        rts
SetCreditsGfx:
        move.l  Truchet_Vars,a1
        move.l  #credits_gfx,credits_data(a1)
        move.w  #16,credits_offsetx(a1)
        move.w  #64,credits_offsety(a1)
        move.w  #27,credits_sinspeed1(a1)
        move.w  #39,credits_sinspeed2(a1)
        move.w  #0,credits_currw(a1)
        rts
SetCreditsSfx:
        move.l  Truchet_Vars,a1
        move.l  #credits_music,credits_data(a1)
        move.w  #4,credits_offsetx(a1)
        move.w  #112,credits_offsety(a1)
        move.w  #-17,credits_sinspeed1(a1)
        move.w  #19,credits_sinspeed2(a1)
        move.w  #0,credits_currw(a1)
        rts
RemoveCredits:
        move.l  Truchet_Vars,a1
        move.l  #0,credits_data(a1)
        rts

CREDITS_MAXX = 128
CREDITS_MAXDOTS = 16

current_palette: dc.l white_palette
white_palette: dc.w $000,$fff,$fff,$fff,$fff,$fff,$fff,$fff
truchet_palette: dc.w $000,$000,$000,$000,$257,$d70,$37a,$f80
gfxtwist_palette: blk.w 8,GFXTWIST_BACKCOL

pastiche_dots: incbin "assets/pastiche_logo_indexes.dots"
        even
Script:
        dc.l    50,CmdLerpPal,8-1,5,white_palette,truchet_palette,current_palette
        dc.l    100,SetLogoEffect
        dc.l    400,SetCreditsCode
        dc.l    700,SetCreditsGfx
        dc.l    1000,SetCreditsSfx
        dc.l    1300,RemoveCredits
        dc.l    1500,CmdLerpPal,8-1,6,truchet_palette,gfxtwist_palette,current_palette
        dc.l    0,0

effect: dc.l    0

        section truchetbss,bss

Truchet_Vars: ds.l 1

        rsreset
bounce_y: rs.w  128
credits_data: rs.l 1
credits_currw: rs.w 1
credits_offsety rs.w 1
credits_offsetx rs.w 1
credits_dx: rs.w 1
credits_sinspeed1: rs.w 1
credits_sinspeed2: rs.w 1
credits_sin1: rs.w 1
credits_sin2: rs.w 1
fillbuffer: rs.l 1
frontcopper rs.l 1
backcopper rs.l 1
frontbuffer rs.l 1
backbuffer rs.l 1
tilemap_ptr rs.l 1
A_tiley: rs.w   1
A_tilex: rs.w   1
A_tiley2: rs.w  1
A_tilex2: rs.w  1
A_tileoffsets: rs.w 128
Truchet_Vars_SIZEOF so


        section truchet_chip,data_c

pastiche_logo: incbin "assets/pastiche.raw"
credits_code: incbin "assets/credits_code.raw"
credits_gfx: incbin "assets/credits_gfx.raw"
credits_music: incbin "assets/credits_music.raw"


Maincop:
        dc.w    $008e
        dc.b    START_Y&$ff,$81                 
        dc.w    $0090
        dc.b    STOP_Y&$ff,$c1                  
        dc.w    $0092,$0028,$0094,$00d8,$0100,$0200
CopMods:
        dc.w    $0108,$0000,$010a,$0000
CopFill:
        dc.w    $00e8,$0000,$00ea,$0000
CopCols:
        dc.w    $0180,$0000,$0182,$0fff
        dc.w    $0184,$0fff,$0186,$0fff
        dc.w    $0188,$0fff,$018a,$0fff
        dc.w    $018c,$0fff,$018e,$0fff
thecopjmp:
        dc.w    copjmp2,$0000
        dc.l    -2


truchet_tile:
                *0123456789012345
        dc.w    %0000001111000000
        dc.w    %0000001111000000
        dc.w    %0000001111000000
        dc.w    %0000001111000000
        dc.w    %0000011110000000
        dc.w    %0000011100000000
        dc.w    %0001110000000000
        dc.w    %0011100000000111
        dc.w    %1111100000011111
        dc.w    %1110000000111100
        dc.w    %0000000001110000
        dc.w    %0000000011110000
        dc.w    %0000000111100000
        dc.w    %0000000111000000
        dc.w    %0000001111000000
        dc.w    %0000001111000000


mirrored_tile:
        blk.b   mirrored_tile-truchet_tile,0
