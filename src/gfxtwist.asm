* Bitmap twister in 16 colors
* Further features:
* - X-sine-movement
* - Multisine twist and stretch
* Anim:
*
*
*
* Further optimizations:
* Combine the two nolines loops into one!
* Change fade in/out system to blitter-based: have one array of bplcon0 values, modify this per frame, and blit it in.
* 
* - Precalc animation patterns?
* - Calculate modulo rather than raw bplptrs
* - Optimize C2P for speed (only 4bpls), and avoid large code chunks

        incdir  "include"
        include "hw.i
        include "src/_main.i"
        include "src/commander.i"
        include "src/gfxtwist.i"
        include "common-timings.i"        

NOLINES = 272

START_Y = $1c
DRAWSCREEN = 0
SHOWSCREEN = 4

CHIP_BITMAPS = $8000*5
COPWAIT_LEN = 52
CHIP_COPWAITS = COPWAIT_LEN*(NOLINES+1)
CHIP_ALLCOPPERS = (2*CHIP_COPWAITS)
CHIP_BPLCONTAB = NOLINES*4
CHIP_ALLOC = CHIP_ALLCOPPERS+CHIP_BITMAPS       + CHIP_BPLCONTAB

TEXTURE_RESET = $3ff                            * 0-2k-1
TWIST_RESET = $fc00                             * 2k-64k-1  
SINE32_RESET = $ffe

FaceTwist_Precalc:
        jsr     MemFlip

        bsr     gfxtwist_allocmem               * align-allocate chipmem
        bsr     gfxtwist_initbplcontab
        bsr     gfxtwist_calcsinetabs           * make sine tabs
        bsr     gfxtwist_makexpostab            * make table for 102, ddf
        bsr     gfxtwist_preparecoppers         * make coppers  in chipmem
   
        clr.w   gfxtwist_animframe              * create frame #0
        bsr     gfxtwist_preanimateall          * convert from chunky to bitplanes a 2k
        move.w  #GFXTWIST_BACKCOL,gfxtwist_mainpalette
        move.w  #1,cops_ready
.nojob
        rts

FaceTwist_Vbi:
        bsr     gfxtwist_setcolors
        rts

gfxtwist_setcolors:
        move.l  current_palette,a0
        lea.l   gfxtwist_copcols+2,a1           * to palette
        move.w  #16-1,d7
.setcol
        move.w  (a0)+,(a1)
        lea.l   4(a1),a1
        dbf     d7,.setcol
        rts

saved_task: dc.l 0
FaceTwist_Effect:
        move.l  a0,saved_task
.wait
        jsr     VSyncWithBgTask
        tst.w   cops_ready
        beq     .wait
        jsr     MemFreeLast                     * free memory alloc from previous effect
        move.l  saved_task,a0
        jsr     SetBgTask

        lea.l   Script,a0                       * This is our effect script
        jsr     Commander_Init                  * Set up any frame-counting lerps


        bsr     movesprites
        lea.l   custom,a6
        lea.l   gfxtwist_copperptrs,a0
        jsr     WaitEOF
        move.l  SHOWSCREEN(a0),cop2lc(a6)       * dynamic part
        move.l  #gfxtwist_maincopper,cop1lc(a6) * fixed part
        bsr     setsprites

        lea.l   FaceTwist_Vbi,a1
        move.l  a1,VBlankInterrupt              * this starts the effect
*        move.w  #DMAF_SETCLR|DMAF_SPRITE,dmacon(a6)

.FaceTwist_Waitloop:
        bsr     gfxtwist_createframe

        jsr     VSyncWithBgTask
        jsr     PartOver
        blt.s   .FaceTwist_Waitloop

        move.w  #GFXTWIST_ENDCOL,BlankBg       
*        move.l  (sp)+,d0
        rts


* routine to allocate enough memory for 64k bitplanes in whole chunks
* allocates and saves chunk and bitplane ptrs.
gfxtwist_allocmem:
        move.l  #CHIP_ALLOC,d0
        jsr     MemAllocChip
        
        move.l  a0,d1                           * this is the base address

        move.l  d1,d2
        and.l   #$ffff0000,d2                   * this is the base address of the bitmaps
        add.l   #$10000,d2                      * make sure we're not overwriting
        move.l  d2,d3
        sub.l   d1,d3                           * "lost" mem due to alignment.

        move.l  #CHIP_BPLCONTAB,d4
        cmp.l   d4,d3
        bmi.s   .bpls
        move.l  d1,bplcontab_ptr                * alloc 2k
        sub.l   d4,d3                           * remaining lost
        add.l   d4,d1
.bpls
        lea.l   gfxtwist_bitplaneptrs,a1        * save here
        rept    4                         
        move.l  d2,(a1)+                        * save bplptr
        add.l   #$8000,d2                       * next bpl
        endr

        lea.l   gfxtwist_copperptrs,a1
        move.l  #CHIP_COPWAITS,d4        

.aptr   sub.l   d4,d3                           * check if there is room for a copperlist in front
        bmi.s   .noptr                          * nope!
        move.l  d1,(a1)+                        * save a copperptr
        add.l   d4,d1                           * spent place
        cmp.l   #gfxtwist_copperptrs+8,a1
        beq.s   .allptr
        bra     .aptr
.noptr  

.pptr   cmp.l   #gfxtwist_copperptrs+8,a1
        beq.s   .allptr
        move.l  d2,(a1)+                        * save a copperptr
        add.l   #CHIP_COPWAITS,d2
        bra     .pptr
.allptr
        tst.l   bplcontab_ptr
        bne.s   .fini
        move.l  d2,bplcontab_ptr
.fini

        move.l  #32*1024,d0
        jsr     MemAllocPublic

        move.l  a0,gfxtwist_chunkybuffer
        add.l   #16*1024,a0

        move.l  a0,gfxtwist_xpostab
        add.l   #4*1024,a0

        move.l  a0,gfxtwist_sine0_32
        add.l   #4*1024,a0

        move.l  a0,gfxtwist_sine0_128
        add.l   #4*1024,a0

        rts

gfxtwist_initbplcontab:
        move.l  bplcontab_ptr,a0
        move.w  #NOLINES-1,d7
.init   move.w  #$8200,(a0)+
        dbf     d7,.init
        rts
gfxtwist_makexpostab:
        move.l  gfxtwist_xpostab,a0
        move.w  #512-1,d7
        moveq   #0,d0
.newpos
        move.w  d0,d2
        lsr.w   #1,d2
        move.w  d2,d3                           * save
        and.w   #$f,d3                          * $102
        move.w  d3,d4
        lsl.w   #4,d4
        or.w    d3,d4
        lsr.w   #1,d2                           * divide by 2
        and.w   #$fffc,d2                       * round off to 8s
        addi.w  #$30,d2                         * ddfstrt
        move.w  d2,d3
        addi.w  #$58,d3                         * ddfstop

        move.w  d2,(a0)+                        * ddfstrt
        move.w  d3,(a0)+                        * ddfstop
        move.w  d4,(a0)+                        * bplcon1
        move.w  #0,(a0)+                        * dummy
        addq    #1,d0
        dbf     d7,.newpos
        rts
        *	one hires twister: 16bts wide, ddfstop=ddfstrt+$18, modulo = 


gfxtwist_calcsinetabs:
        lea.l   Sin2048,a0
        move.l  gfxtwist_sine0_32,a1
        move.l  gfxtwist_sine0_128,a2
        move.w  #2047,d7
.newsine
        move.w  (a0)+,d0
        ext.l   d0
        move.l  d0,d1

        asl.l   #7,d0
        swap    d0
        add.w   #32,d0
        lsl.w   #3,d0
        move.w  d0,(a1)+

        asr.l   #7,d1
        add.w   #128,d1
        lsl.w   #3,d1
        move.w  d1,(a2)+
				
        dbf     d7,.newsine
        rts

* animpattern: en linje per frame. linjen indikerer hvilken texel som skal plukkes til bpls
* chunkybuffer: mellomlager for frames med mappet texture
* texture: selve bilde i chunky mode
*

* hack to fill in the first line of next frame, when we have multiple twisters onscreen
; lea.l		gfxtwist_bitplaneptrs,a0		*fourth plane
; movem.l		(a0)+,a1-a5
; adda.l		#$10000,a1						* after fourth plane
; rept			(128/32)*4	
; move.l		(a0)+,(a1)+
; endr
   
gfxtwist_preanimateall:
.newframe
        bsr     gfxtwist_preanimateframe
        add.w   #1,gfxtwist_animframe
        cmp.w   #32,gfxtwist_animframe
        blt.s   .newframe
        rts

gfxtwist_preanimateframe:
        move.l  gfxtwist_chunkybuffer,a0        * destination chunky
        lea.l   gfxtwist_texture,a1             * orig texture
        lea.l   gfxtwist_animpattern,a3         * animation chunky
        lea.l   gfxtwist_animmask,a4
        lea.l   gfxtwist_animlight,a5
        move.w  gfxtwist_animframe,d0
        mulu    #128,d0
        add.l   d0,a3                           * move to correct line in twister
        add.l   d0,a4
        add.l   d0,a5
        moveq   #0,d0                           * we start out with line 0
        move.w  #63,d7                          * each bitplane is 128x128
.aniline
        move.w  #127,d6
.anibyte
        move.w  #127,d1                         * x = 127-d6
        sub.w   d6,d1                           * d1 = x-position in animation
        moveq   #0,d2
        move.b  (a3,d1.w),d2                    * get which texel to plot (back=$80)
        add.w   d0,d2                           * add lines to texel offset
        move.b  (a1,d2.w),d3                    * get color from texture
        sub.b   (a5,d1.w),d3                    * adjust for lighting
        bgt     .nema
        moveq   #1,d3
.nema
        and.b   (a4,d1.w),d3                    * mask out pixels that should not have color
        move.b  d3,(a0)+                        * plot texel in chunkybuffer
        dbf     d6,.anibyte
        add.w   #128,d0                         * add 128 bytes (one line) in the texture offset
        dbf     d7,.aniline

        * remove the first and second texture line to avoid bugs
        moveq   #0,d0
        moveq   #0,d1
        moveq   #0,d2
        moveq   #0,d3
        moveq   #0,d4
        moveq   #0,d5
        moveq   #0,d6
        moveq   #0,d7
        move.l  gfxtwist_chunkybuffer,a0        * the chunkybuffer
        lea.l   128(a0),a1                      * end of first line
        movem.l d0-d7,-(a1)                     * wipe first line of chunkybuffer (128 bytes)
        movem.l d0-d7,-(a1)
        movem.l d0-d7,-(a1)
        movem.l d0-d7,-(a1)
        lea.l   8192(a0),a2                     * end of last line (of chunkybuffer)
        movem.l d0-d7,-(a2)                     * wipe first line of chunkybuffer (128 bytes)
        movem.l d0-d7,-(a2)
        movem.l d0-d7,-(a2)
        movem.l d0-d7,-(a2)

        lea.l   gfxtwist_bitplaneptrs,a5
        movem.l (a5)+,a1-a4                     * a1-a4 represents four bitplanes
        moveq   #0,d0
        move.w  gfxtwist_animframe,d0
        mulu    #1024,d0
        add.l   d0,a1
        add.l   d0,a2
        add.l   d0,a3
        add.l   d0,a4
        bsr     gfxtwist_c2p4bits
        rts


gfxtwist_c2p4bits:
        move.l  #$cccc3333,d5
        move.l  #$3333cccc,d6
        move.l  #$55555555,d7

.Loop   move.l  #1023,d4
.RowLoop move.l (a0)+,d0
        lsl.l   #4,d0
        or.l    (a0)+,d0
        move.l  d0,d1
        and.l   d6,d0
        and.l   d5,d1
        lsr.w   #2,d0
        swap    d0
        add.w   d0,d0
        add.w   d0,d0
        or.l    d1,d0
        swap    d0
        move.l  d0,d2
        lsr.l   #7,d2
        move.l  d0,d1
        and.l   d7,d0
        eor.l   d0,d1
        move.l  d2,d3
        and.l   d7,d3
        eor.l   d3,d2
        or.l    d2,d0
        or.l    d3,d1
        lsr.l   #1,d1
        move.b  d0,(a3)+                        ; 3rd
        swap    d0
        move.b  d0,(a1)+                        ; 1st
        move.b  d1,(a4)+                        ; 4th
        swap    d1
        move.b  d1,(a2)+                        ; 2nd
        dbf     d4,.RowLoop
        rts

gfxtwist_preparecoppers:
        * prep the main copperlist
        lea.l   gfxtwist_bitplaneptrs,a5
        movem.l (a5)+,d1-d4
        swap    d1
        swap    d2
        swap    d3
        swap    d4
        and.l   #$ffff,d1
        and.l   #$ffff,d2
        and.l   #$ffff,d3
        and.l   #$ffff,d4
        add.l   #$00e00000,d1
        add.l   #$00e40000,d2
        add.l   #$00e80000,d3
        add.l   #$00ec0000,d4

        lea.l   gfxtwist_copperptrs,a0          * copperpointers
        move.l  (a0)+,a1                        * prepare one copperlist
        move.l  (a0)+,a2                        * get second list ptr
        move.l  a1,d5                           * store start of first list
        move.l  a2,d6
        move.l  #(START_Y*$1000000)|$dffffe,d0
        move.w  #NOLINES-1,d7                   * make NOLINES copwaits
.newline
        move.l  d0,(a1)+                        * wait          0
        move.l  #$00920038,(a1)+                * ddfstrt       4
        move.l  #$00940070,(a1)+                * ddfstop       8
        move.l  #$01020000,(a1)+                * bplcon1       12
        move.l  #$00e20000,(a1)+                * bpl1          16
        move.l  #$00e60000,(a1)+                * bpl2          20
        move.l  #$00ea0000,(a1)+                * bpl3          24
        move.l  #$00ee0000,(a1)+                * bpl4          28
        move.l  d1,(a1)+                        * bpl1          32
        move.l  d2,(a1)+                        * bpl2          36
        move.l  d3,(a1)+                        * bpl3          40
        move.l  d4,(a1)+                        * bpl4          44
        move.l  #$0100c200,(a1)+                * bplcon0       48
        add.l   #$01000000,d0                   * total         52
        dbf     d7,.newline
        move.l  #$01800000,(a1)+
        move.l  #$01000200,(a1)+        
        move.l  #$2fdffffe,(a1)+
        move.l  #$00840000,(a1)+                * high word cop2lc
        move.l  #$00860000,(a1)+                * low word cop2lc
        move.l  #-2,(a1)+                       * copper end
        move.l  #$deadcafe,(a1)+                * end fill symbol

        move.l  a1,d0                           * end of copperlist
        sub.l   d5,d0                           * substract start for length of copperlist
        move.l  d0,d3                           * save in d3
        
        lsr.w   #1,d0                           * longwords
        subq    #1,d0                           * add one for rounding

        lea.l   gfxtwist_copperptrs,a0          * copperpointers
        move.l  (a0)+,a1
        move.l  (a0)+,a2                        * the ptrs of copperlist start
        move.l  a1,d1                           * first list
        move.l  a2,d2                           * second list
.copyw  move.w  (a1)+,(a2)+                     * copy first to second
        dbf     d0,.copyw

        move.w  d2,-10(a1)                      * move low w of second list into first list cop2lc entry 
        move.w  d1,-10(a2)                      * move low w of first list into second list cop2lc entry
        swap    d2
        swap    d1
        move.w  d2,-14(a1)                      * move high w of second list into first list cop2lc entry 
        move.w  d1,-14(a2)                      * move high w of first list into second list cop2lc entry
        rts

* Animation dims:
* Start X position
* Speed in X position waves
* Start in Y position
* Speed in Y position waves/steps
* Start Twist position
* Speed in Twist position waves
*
* u pto 8 dims = 16 bytes per frame
* 16*50*90 = 72k data


* a0 sinetab
* d0 sine1
* d1 sine2
* d2 scratch
* d5 delta-sine1
* d6 delta-sine2
* a1 output 
* d7 linecounter
* a3 xpostab
* a4 scratch

* det er moduloen som fucker det opp
* kanskje like greit å ta texture flyt og twist i en egen loop med mer kontroll?
* alle registre ledige i 32bit
* kan undersøke mer 

gfxtwist_createframe:
        bsr     movesprites
        lea.l   gfxtwist_copperptrs,a6
        move.l  DRAWSCREEN(a6),a6               * copperptr for DRAWSCR
        lea.l   COPWAIT_LEN-2(a6),a4
        lea.l   custom,a5
        move.l  bplcontab_ptr,a0
        * do the appropriate wipe
        tst.w   wipeout
        beq.s   .nowipe
        move.w  wipeout,d0
        and.w   #$fffe,d0
        add.w   d0,d0
        eor.w   #%0100000000000000,(a0,d0.w)
        move.w  #(NOLINES-1)*2,d1
        sub.w   d0,d1
        eor.w   #%0100000000000000,(a0,d1.w)
        sub.w   #2,wipeout

.nowipe

.wblt:
        btst    #DMAB_BLTDONE,dmaconr(a5)
        bne.s   .wblt

        move.l  #$09f00000,bltcon0(a5)
        move.l  #-1,bltafwm(a5)
        move.l  a0,bltapth(a5)
        clr.w   bltamod(a5)
        lea.l   COPWAIT_LEN-2(a6),a4
        move.l  a4,bltdpth(a5)
        move.w  #COPWAIT_LEN-2,bltdmod(a5)
        move.w  #NOLINES*64+1,bltsize(a5)

        * pointer to the new copperlist in a6
        move.l  gfxtwist_animroutine,a0
        jsr     (a0)
        
        * now we are done making the new copperlist
        * so it should be made available
        lea.l   gfxtwist_copperptrs,a0
        move.l  DRAWSCREEN(a0),d0
        move.l  SHOWSCREEN(a0),d1
        move.l  d1,DRAWSCREEN(a0)
        move.l  d0,SHOWSCREEN(a0)
*        move.w  #GFXTWIST_BACKCOL,$dff180
        rts


gfxtwist_swingtwister:
        * get speeds and states
        lea.l   Animspeeds,a0
        lea.l   Animstates,a2
        move.l  gfxtwist_sine0_32,a1
        move.l  gfxtwist_xpostab,a3
        move.w  AS_xbase1(a2),d0                * get state1
        add.w   AS_xbase1(a0),d0                * add speed1
        move.w  d0,AS_xbase1(a2)                * save state1
        and.w   #SINE32_RESET,d0

        move.w  AS_xbase2(a2),d1                *  xspeed2
        add.w   AS_xbase2(a0),d1
        move.w  d1,AS_xbase2(a2)
        and.w   #SINE32_RESET,d1
* now d0/d1 = xbase1  & xbase2

        move.w  AS_xperline1(a0),d2             * Get per-line change rates
        move.w  AS_xperline2(a0),d3             * Get per-line change rates
* now d2/d3 = xperline1  & xperline2

        move.l  gfxtwist_sine0_128,a2
        lea.l   6(a6),a5                        * a6 is start of copwait, move ahead to ddf
        move.w  delta_ddf,d5

        move.w  #SINE32_RESET,d7
        rept    NOLINES
* d0,d2,d1,d3,d5  

        and.w   d7,d0
        move.w  (a2,d0.w),d4                    * 0-128 value from sinewave1
        add.w   d2,d0

        and.w   d7,d1
        add.w   (a1,d1.w),d4                    * sinewave1
        add.w   d3,d1

* d4 is now x-position, but need offset in xpostab
        lea.l   (a3,d4.w),a4                    * xpos entry
        move.w  (a4)+,d4
        move.w  d4,(a5)                         * move stuff to copperlist
        add.w   d5,d4
        move.w  d4,4(a5)
        move.w  2(a4),8(a5)                     * move stuff		 d2 free again

        lea.l   COPWAIT_LEN(a5),a5
        endr

        lea.l   Animspeeds,a0
        lea.l   Animstates,a2
        move.w  AS_texturebase(a2),d0           * texturebase
        add.w   AS_texturebase(a0),d0           * move the first line
        move.w  d0,AS_texturebase(a2)           * save the current offset
        and.w   #TEXTURE_RESET,d0               * reset the texture if beyond $800
        move.w  AS_textureperline(a0),d2        * speed per line
* d0 = texturebase 

        move.w  AS_twistbase(a2),d1             *  twistbase
        add.w   AS_twistbase(a0),d1
        move.w  d1,AS_twistbase(a2)
        and.w   #TWIST_RESET,d1
* d1 = twistbase
        move.w  AS_twistperline(a0),d3
* d1 + d3 = texturespeed & twistspeed

        move.w  d0,d7			
        or.w    d1,d7
        and.w   #$fff0,d7                       * correct bplptrs

        lea.l   18(a6),a5                       * a6 is start; move to bplptrs

        move.w  #$8000,d6
        move.w  #$7ff0,d7
        rept    NOLINES
* d0, d2, d4, d3, d5
   
        add.w   d2,d0                           * add texture speed

        move.w  d0,d4                           * move texture state to d4
        and.w   #TEXTURE_RESET,d4

        add.w   d3,d1                           * new twist state
        move.w  d1,d5
        and.w   #TWIST_RESET,d5                 * new twist state

        or.w    d5,d4                           * add twist state to d4
        and.w   d7,d4                           * adjust the full bplptr
        move.w  d4,d5
        or.w    d6,d5
        move.w  d4,(a5)                         * bplptr0
        move.w  d5,4(a5)                        * bplptr1
        move.w  d4,8(a5)                        * bplptr2
        move.w  d5,12(a5)                       * bplptr3

        lea.l   COPWAIT_LEN(a5),a5

        endr
        rts


; turning_movement:
;         * get speeds and states
;         lea.l   Animspeeds,a0
;         lea.l   Animstates,a1

;         move.w  AS_xbase1(a1),d0                * get state1
;         add.w   AS_xbase1(a0),d0                * add speed1
;         move.w  d0,AS_xbase1(a1)                * save state1
;         and.w   #SINE32_RESET,d0

;         move.w  AS_xbase2(a1),d1                *  xspeed2
;         add.w   AS_xbase2(a0),d1
;         move.w  d1,AS_xbase2(a1)
;         and.w   #SINE32_RESET,d1
; * now d0/d1 = xbase1 & xbase2

;         lea.l   gfxtwist_sine0_32,a2
;         lea.l   gfxtwist_sine0_128,a3
;         move.w  (a3,d0.w),d2                    * 0-128 value from sinewave1
;         add.w   (a2,d1.w),d2                    * sinewave1
; * d4 is now xpos at start

; * look up offsets in xpostab
;         lea.l   gfxtwist_xpostab,a4
;         move.w  (a4,d2.w),d4                    * xpos entry
;         move.w  d4,d5            
;         add.w   delta_ddf,d5                    * ddfstop value
;         move.w  4(a4,d2.w),d6                   * $102-value   


;         move.w  AS_texturebase(a1),d0           * texturebase
;         add.w   AS_texturebase(a0),d0           * move the first line
;         and.w   #TEXTURE_RESET,d0               * reset the texture if beyond $800
;         move.w  d0,AS_texturebase(a1)           * save the current offset
; * d0 is now texture base pos

;         move.w  AS_twistbase(a1),d1             *  twistbase
;         add.w   AS_twistbase(a0),d1
;         and.w   #TWIST_RESET,d1
;         move.w  d1,AS_twistbase(a1)
; * d1 = twistbase

;         move.w  current_lag,d7                  * number of lines to hold x/twist movement
;         cmp.w   #NOLINES,d7
;         bgt.s   .atmax
;         addq    #1,d7
;         move.w  d7,current_lag

; .atmax:
;         lea.l   6(a6),a5                        * skip the wait and ddf
; .holdline:

; * plot x-pos values into copperlist
;         move.w  d4,(a5)                         * move stuff to copperlist
;         move.w  d5,4(a5)
;         move.w  d6,8(a5)                        * move stuff		 d2 free again

;         add.w   AS_textureperline(a0),d0        * add texture speed
;         and.w   #TEXTURE_RESET,d0
;         move.w  d0,d2
;         or.w    d1,d2
;         and.w   #$fff0,d2                       * correct bplptrs
;         move.w  d2,12(a5)
;         move.w  d2,16(a5)
;         move.w  d2,20(a5)
;         move.w  d2,24(a5)

;         lea.l   COPWAIT_LEN(a5),a5
;         dbf     d7,.holdline

;         move.w  #(NOLINES-1),d7
;         sub.w   current_lag,d7

;         lea.l   Animspeeds,a0
;         lea.l   Animstates,a2
;         lea.l   gfxtwist_sine0_32,a1
;         lea.l   gfxtwist_xpostab,a3
;         move.w  AS_xbase1(a2),d0                * get state1
; *   add.w		AS_xbase1(a0),d0				* add speed1
; *   move.w	d0,AS_xbase1(a2)				* save state1
;         and.w   #SINE32_RESET,d0

;         move.w  AS_xbase2(a2),d1                *  xspeed2
; *   add.w		AS_xbase2(a0),d1
; *   move.w	d1,AS_xbase2(a2)
;         and.w   #SINE32_RESET,d1
; * now d0/d1 = xbase1  & xbase2

;         move.w  AS_xperline1(a0),d2             * Get per-line change rates
;         move.w  AS_xperline2(a0),d3             * Get per-line change rates
; * now d2/d3 = xperline1  & xperline2

;         lea     gfxtwist_sine0_128,a2
; ; lea.l		gfxtwist_copwaits-gfxtwist_copperdata(a6),a5
; ; lea.l		6(a5),a5
;         move.l  a5,a6
;         move.w  delta_ddf,d5

;         move.w  d7,d6
; .setxpos   
; *rept		gfxtwist_nolines
; * d0,d2,d1,d3,d5  

;         and.w   #SINE32_RESET,d0
;         move.w  (a2,d0.w),d4                    * 0-128 value from sinewave1
;         add.w   d2,d0

;         and.w   #SINE32_RESET,d1
;         add.w   (a1,d1.w),d4                    * sinewave1
;         add.w   d3,d1

; * d4 is now x-position, but need offset in xpostab
;         lea.l   (a3,d4.w),a4                    * xpos entry
;         move.w  (a4)+,d4
;         move.w  d4,(a5)                         * move stuff to copperlist
;         add.w   d5,d4
;         move.w  d4,4(a5)
;         move.w  2(a4),8(a5)                     * move stuff		 d2 free again

;         lea.l   COPWAIT_LEN(a5),a5
;         dbf     d6,.setxpos

;         move.l  a6,a5
;         lea.l   Animspeeds,a0
;         lea.l   Animstates,a2
;         move.w  AS_texturebase(a2),d0           * texturebase
;         add.w   AS_texturebase(a0),d0           * move the first line
;         move.w  d0,AS_texturebase(a2)           * save the current offset
;         and.w   #TEXTURE_RESET,d0               * reset the texture if beyond $800
;         move.w  AS_textureperline(a0),d2        * speed per line
; * d0 = texturebase 

;         move.w  AS_twistbase(a2),d1             *  twistbase
;         add.w   AS_twistbase(a0),d1
;         move.w  d1,AS_twistbase(a2)
;         and.w   #TWIST_RESET,d1
; * d1 = twistbase
;         move.w  AS_twistperline(a0),d3
; * d1 + d3 = texturespeed & twistspeed

;         move.w  d7,d6

;         move.w  d0,d7			
;         or.w    d1,d7
;         and.w   #$fff0,d7                       * correct bplptrs

; ; lea.l		gfxtwist_copwaits-gfxtwist_copperdata(a6),a5
; ; lea.l		18(a5),a5
; .setbpls
; *rept			gfxtwist_nolines
; * d0, d2, d4, d3, d5
   
;         add.w   d2,d0                           * add texture speed
;         move.w  d0,d4                           * move texture state to d4
;         and.w   #TEXTURE_RESET,d4

;         add.w   d3,d1                           * new twist state
;         move.w  d1,d5
;         and.w   #TWIST_RESET,d5                 * new twist state

;         or.w    d5,d4                           * add twist state to d4
;         and.w   #$fff0,d4                       * adjust the full bplptr

;         move.w  d4,12(a5)                       * bplptr0
;         move.w  d4,16(a5)                       * bplptr1
;         move.w  d4,20(a5)                       * bplptr2
;         move.w  d4,24(a5)                       * bplptr3

;         lea.l   COPWAIT_LEN(a5),a5

;         dbf     d6,.setbpls
;         rts



* set sprite pointers
setsprites:
        lea.l   spritescopper+2,a2
        lea.l   logosprites,a1
        move.w  #6-1,d7
.newsprite move.l (a1)+,d0
        move.w  d0,4(a2)
        swap    d0
        move.w  d0,(a2)
        lea.l   8(a2),a2
        dbf     d7,.newsprite
        rts

sprites_xpos: dc.w 512                          *448                          *(320+128-48)+48
movesprites:
        lea.l   logosprites,a0
        move.w  #6-1,d7
        move.w  sprites_xpos,d0
        moveq   #0,d4
.newspr	
        moveq   #0,d1
        move.w  d0,d1
        move.l  d1,d2
        lsr.l   #1,d2
        and.l   #$ff,d2                         * high bits
        swap    d2
        and.l   #$1,d1                          * low bit
        move.l  (a0)+,a1
        move.l  (a1),d3
        and.l   #$ff00fffe,d3                   * reset pos
        or.l    d2,d1
        or.l    d1,d3
        move.l  d3,(a1)

        add.w   d4,d0
        eor.w   #$10,d4
        dbf     d7,.newspr
.nomove


        rts


        section data,data

        rsreset
AS_xbase1 rs.w  1
AS_xbase2 rs.w  1
AS_xperline1 rs.w 1
AS_xperline2 rs.w 1
AS_texturebase rs.w 1
AS_textureperline rs.w 1
AS_twistbase rs.w 1
AS_twistperline rs.w 1
AS_sizeof so

Animstates: blk.w AS_sizeof,0
Animspeeds:		
Xbase1  dc.w    0                               * Xbase1
Xbase2  dc.w    0                               * Xbase2
Xperline1 dc.w  0                               * xperline1
Xperline2 dc.w  0                               * xperline2
texturebase: dc.w 0                             * texturebase
textureperline: dc.w 12                         * textureperline
twistbase: dc.w 0                               * twistbase
twistperline: dc.w 0                            * twistperline
delta_ddf: dc.w $0018
cops_ready: dc.w 0
wipeout: dc.w   0
bplcontab_ptr: dc.l 0                           * ptr to bplcontab in chipmem
gfxtwist_animframe: dc.w 0
gfxtwist_bitplaneptrs: dc.l 0,0,0,0             * pointers to bitplanedata in 64k segments
gfxtwist_copperptrs: dc.l 0,0,0
gfxtwist_chunkybuffer: dc.l 0
gfxtwist_sine0_32: dc.l 0
gfxtwist_sine0_128: dc.l 0
gfxtwist_xpostab: dc.l 0                        *blk.w 4*512,0                 * table of xpos input to bplcon1+ddf
current_lag: dc.w 0

gfxtwist_animroutine: dc.l gfxtwist_swingtwister
current_palette: dc.l gfxtwist_mainpalette
gfxtwist_animpattern: incbin "./assets/animribbon.raw"
gfxtwist_animmask: incbin "./assets/animribbonmask.raw"
gfxtwist_animlight: incbin "./assets/animribbonlight.raw"
gfxtwist_mainpalette: incbin "./assets/stein.palette"
gfxtwist_texture: incbin "./assets/stein.chunky"


Script:
        dc.l    1,CmdMoveIW, 12, texturebase
        dc.l    1,CmdMoveIW, 221*7, twistbase
        dc.l    1,CmdMoveIW, 7, Xperline1
        dc.l    1,CmdMoveIW, 17, Xbase1
        dc.l    1,CmdMoveIW, 23, Xbase2
        dc.l    1,CmdMoveIW, NOLINES+2, wipeout
        dc.l    99,CmdMoveIW, DMAF_SETCLR|DMAF_SPRITE,dmacon+custom 
        dc.l    100,CmdLerpWord, 400, 6, sprites_xpos
        dc.l    150,CmdLerpWord, 239, 7, twistperline
        dc.l    500,CmdLerpPal, 16-1,5,FillData,gfxtwist_mainpalette,current_palette
        dc.l    500,CmdAddIW,$4,delta_ddf
        dc.l    502,CmdAddIW,$4,delta_ddf
        dc.l    504,CmdAddIW,$4,delta_ddf
        dc.l    506,CmdAddIW,$4,delta_ddf
        dc.l    508,CmdAddIW,$4,delta_ddf
        dc.l    510,CmdAddIW,$4,delta_ddf
        dc.l    512,CmdAddIW,$4,delta_ddf
        dc.l    614,CmdAddIW,$4,delta_ddf
        dc.l    700,CmdLerpPal, 16-1,5,FillData,gfxtwist_mainpalette,current_palette
        dc.l    700,CmdAddIW,$4,delta_ddf
        dc.l    702,CmdAddIW,$4,delta_ddf
        dc.l    704,CmdAddIW,$4,delta_ddf
        dc.l    706,CmdAddIW,$4,delta_ddf
        dc.l    708,CmdAddIW,$4,delta_ddf
        dc.l    710,CmdAddIW,$4,delta_ddf
        dc.l    712,CmdAddIW,$4,delta_ddf
        dc.l    714,CmdAddIW,$4,delta_ddf
        dc.l    850,CmdMoveIW, NOLINES, wipeout
        dc.l    0,0

;	palette for: TLN_Logo_iso_03Vert
;	Sat Jan 25 2025 06:08:56 GMT+0100 (Central European Standard Time)
        dc.w    $0bcb
        dc.w    $0000
        dc.w    $016b
        dc.w    $018d
        dc.w    $05ae
        dc.w    $09cf
        dc.w    $0047
        dc.w    $0cef
        dc.w    $0123
        dc.w    $0fff

        section chipdata, data_c

gfxtwist_maincopper:
        dc.w    $008e,$2251,$0090,$37d1         * diw
        dc.w    $0180,$0000
gfxtwist_copcols:						
        dc.w    $0180,$0456,$0182,$0000,$0184,$0456,$0186,$0456
        dc.w    $0188,$0456,$018a,$0000,$018c,$0456,$018e,$0456
        dc.w    $0190,$0456,$0192,$0000,$0194,$0456,$0196,$0456
        dc.w    $0198,$0456,$019a,$0000,$019c,$0456,$019e,$0456
spritescopper:
        dc.w    $0120,$0000,$0122,$0000,$0124,$0000,$0126,$0000
        dc.w    $0128,$0000,$012a,$0000,$012c,$0000,$012e,$0000
        dc.w    $0130,$0000,$0132,$0000,$0134,$0000,$0136,$0000
        dc.w    $0138,$0000,$013a,$0000,$013c,$0000,$013e,$0000
spritescols:
;	copperlist for: TLN_Logo_iso_03Vert
;	Sat Jan 25 2025 06:07:06 GMT+0100 (Central European Standard Time)
        dc.w    $01a0,$0bcb
        dc.w    $01a2,$0000
        dc.w    $01a4,$016b
        dc.w    $01a6,$018d
        dc.w    $01a8,$05ae
        dc.w    $01aa,$09cf
        dc.w    $01ac,$0047
        dc.w    $01ae,$0cef
        dc.w    $01b0,$0123
        dc.w    $01b2,$0fff
gfxtwist_cop2: 
        dc.w    copjmp2,$0000


        even
        include "./assets/sprites.asm"
        even



