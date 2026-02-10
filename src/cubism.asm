CUBISM_BPLWIDTH = (192*2)  
CUBISM_BPLHEIGHT = 192
CUBISM_BPLSIZE = ((CUBISM_BPLWIDTH/8)*CUBISM_BPLHEIGHT)
CUBISM_BPLDEPTH = 4
CUBISM_SCREEN_SIZE = CUBISM_BPLSIZE*CUBISM_BPLDEPTH
CUBISM_DRAWBUFFER_SIZE = 192*CUBISM_BPLHEIGHT*2/8

CUBISM_COPPER_SIZE = 4096
* Size of the basic cube drawing
CUBISM_DRAWWIDTH = 192
CUBISM_DRAWHEIGHT = 192
CUBISM_DRAWPLANE = CUBISM_DRAWWIDTH*CUBISM_DRAWHEIGHT/8
CUBISM_DRAWSKIP = CUBISM_BPLWIDTH-CUBISM_DRAWWIDTH

CUBISM_SEGBPLSIZE = CUBISM_BPLWIDTH*CUBISM_SEGMENTHEIGHT/8
CUBISM_SEGMENTS = 6
*CUBISM_STARTLINE = $3fae						* plan is to start showing stuff at line $4c = 78
CUBISM_STARTLINE = $3fb7fffe					* plan is to start showing stuff at line $4c = 78
CUBISM_START_Y = $3f	
CUBISM_SEGMENTHEIGHT = 32
CUBISM_BACKCOL = $423
HRIGHT = $bf
HLEFT = $5f

* Offset to current segment list
CUBISM_SEG_ROUTINE = 0
CUBISM_SEG_STATE = 4
CUBISM_SEG_WAIT = 6
CUBISM_SEG_XPOS = 8
CUBISM_SEG_BYTEOFFSET = 10
CUBISM_SEG_SCROLLREG = 12
CUBISM_ANIM_MOVEIN = 2
CUBISM_ANIM_SWITCH = 4
CUBISM_ANIM_STAY = 1
CUBISM_ANIM_MOVEOUT = 3
CUBISM_ANIM_RESTART = 5
CUBISM_ANIM_MOVEOUT_R = 6
CUBISM_ANIM_MOVEIN_R = 7

CUBISM_SPIRAL_YSPD = 3

CHESS_GRID_STEPS = 4
CHESS_LINES_PER_FACE = (CHESS_GRID_STEPS+1)*2
CHESS_LINES_PER_FRAME = CHESS_LINES_PER_FACE*6
CHESS_LINE_WORDS = 4
CHESS_FRAME_WORDS = 1+(CHESS_LINES_PER_FRAME*CHESS_LINE_WORDS)
CHESS_FRAME_SIZE = CHESS_FRAME_WORDS*2
CHESS_TOTAL_SIZE = CHESS_FRAME_SIZE*CUBE_FRAMES
CHESS_DIST = 650
CHESS_FOCAL = 256
CHESS_CENTERX = 96
CHESS_CENTERY = 96
CHESS_MAXXY = 191

* Spacecut polygon precalc
SPACECUT_DEPTH = 0
SPACECUT_MAX_POINTS = 6
SPACECUT_FRAME_WORDS = 1+(SPACECUT_MAX_POINTS*2)
SPACECUT_FRAME_SIZE = SPACECUT_FRAME_WORDS*2
SPACECUT_TOTAL_SIZE = SPACECUT_FRAME_SIZE*CUBE_FRAMES
SPACECUT_TMP_X0 = 2+(SPACECUT_MAX_POINTS*4)
SPACECUT_TMP_Y0 = SPACECUT_TMP_X0+2
SPACECUT_CLIP_MAX_POINTS = 8

		incdir	"include"
		include	"hw.i"
		include	"hardware/blitbits.i"
		include	"hardware/dmabits.i"
		include	"hardware/intbits.i"

		include	"src/_main.i"
		include	"src/commander.i"
		include	"src/cubism.i"

* Memory map
*
* Each buffer, front or back, has 64k
* (192*2)*5/8 = 46080 bytes for bitmaps: front (2), back(2) OR dots OR lines
* AND some extra
* AND copperlist
*
* $x0000: start
* 384x193x2/8 = front cube + extra lines for scrolling 
* 384x192x2/8 = 
*

Cubism_Precalc:
		jsr		MemFlip

		ALLOC_PUBLIC cubism_vars_SIZEOF,a5
		move.l	a5,cubism_vars

		ALLOC_CHIP_ALIGNED CUBISM_SCREEN_SIZE,cubism_frontbuffer(a5)
		ALLOC_CHIP_ALIGNED CUBISM_SCREEN_SIZE,cubism_backbuffer(a5)

		ALLOC_CHIP CUBISM_COPPER_SIZE,cubism_frontcopper(a5)
		ALLOC_CHIP CUBISM_COPPER_SIZE,cubism_backcopper(a5)

		move.l	cubism_frontcopper(a5),d0
		move.l	d0,a0
		move.l	cubism_backcopper(a5),a1
		move.l	a1,d1
		move.l	cubism_frontbuffer(a5),d2
		move.l	cubism_backbuffer(a5),d3

		move.l	a0,a3

		* backcopper to cop2lc in frontcopper
		swap	d1
		move.w	#$0084,(a0)+
		move.w	d1,(a0)+
		swap	d1
		move.w	#$0086,(a0)+
		move.w	d1,(a0)+
		
		* frontcopper to cop2lc in backcopper
		swap	d0
		move.w	#$0084,(a1)+
		move.w	d0,(a1)+
		swap	d0
		move.w	#$0086,(a1)+
		move.w	d0,(a1)+

		* frontbuffer/backbuffer bplptrs are set per-segment below

		move.l	a0,d0
		sub.l	a3,d0				* offset for segments in copperlist
		move.l	d0,cubism_coppreamble(a5)

y set CUBISM_START_Y

		rept	6
			move.l	a0,d0
			move.b	#y,(a0)+		* HRIGHT WAIT
			move.b	#y,(a1)+
			move.b	#HRIGHT,(a0)+
			move.b	#HRIGHT,(a1)+
			move.w	#$fffe,(a0)+
			move.w	#$fffe,(a1)+
			move.l	#$01800000,(a0)+
			move.l	#$01800000,(a1)+
			* set bplptrs for 4 bpls (high + low words)
			move.l	#$01002200,(a0)+
			move.l	#$01002200,(a1)+
			move.l	#$01020000,(a0)+
			move.l	#$01020000,(a1)+
			move.l	#$00e00000,(a0)+
			move.l	#$00e00000,(a1)+
			move.l	#$00e20000,(a0)+
			move.l	#$00e20000,(a1)+
			move.l	#$00e40000,(a0)+
			move.l	#$00e40000,(a1)+
			move.l	#$00e60000,(a0)+
			move.l	#$00e60000,(a1)+
			move.l	#$00e80000,(a0)+
			move.l	#$00e80000,(a1)+
			move.l	#$00ea0000,(a0)+
			move.l	#$00ea0000,(a1)+
			move.l	#$00ec0000,(a0)+
			move.l	#$00ec0000,(a1)+
			move.l	#$00ee0000,(a0)+
			move.l	#$00ee0000,(a1)+
col set $182
			rept	15
				move.w 	#col,(a0)+
				move.w 	#$0000,(a0)+
				move.w 	#col,(a1)+
				move.w 	#$0000,(a1)+
col set col+2
			endr
y set y+1
			move.b	#y,(a0)+		* HRIGHT WAIT
			move.b	#y,(a1)+
			move.b	#HLEFT,(a0)+			* HLEFT wait
			move.b	#HLEFT,(a1)+
			move.w	#$fffe,(a0)+
			move.w	#$fffe,(a1)+
			move.l	#$01800000+CUBISM_BACKCOL,(a0)+
			move.l	#$01800000+CUBISM_BACKCOL,(a1)+

			rept	31
			move.b	#y,(a0)+		* HRIGHT WAIT
			move.b	#y,(a1)+
			move.b	#HRIGHT,(a0)+
			move.b	#HRIGHT,(a1)+
			move.w	#$fffe,(a0)+
			move.w	#$fffe,(a1)+
			move.l	#$01800000,(a0)+
			move.l	#$01800000,(a1)+
y set y+1
			move.b	#y,(a0)+		* HRIGHT WAIT
			move.b	#y,(a1)+
			move.b	#HLEFT,(a0)+			* HLEFT wait
			move.b	#HLEFT,(a1)+
			move.w	#$fffe,(a0)+
			move.w	#$fffe,(a1)+
			move.l	#$01800000+CUBISM_BACKCOL,(a0)+
			move.l	#$01800000+CUBISM_BACKCOL,(a1)+
			endr
			move.l 	a0,d1
		endr
		sub.l	d0,d1
		move.l	d1,cubism_copseglen(a5)
		move.l	#$01000200,(a0)+
		move.l	#$01000200,(a1)+
		* end copperlists
		move.l	#-2,(a0)
		move.l	#-2,(a1)


		ALLOC_CHIP CUBISM_DRAWBUFFER_SIZE,cubism_drawbuffer(a5)

		ALLOC_CHIP CUBISM_SEGBPLSIZE*2,cubism_noiseptr(a5)
	
		bsr		cubism_initanimation
		bsr		cubism_preparenoise
		*		bsr		cubism_precalc_spacecut
		*bsr		cubism_precalc_chesslines
		rts

Cubism_Effect:
		jsr		SetBgTask
		jsr		MemFreeLast						* free memory reserved be previous effect (in the other mem direction)

		move.l	cubism_vars,a5
		move.l	cubism_frontbuffer(a5),a0
		WAIT_BLIT
		move.l	#$01000000,bltcon0(a6)
		move.l	a0,bltdpt(a6)
		clr.w	bltdmod(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#(CUBISM_BPLHEIGHT*2*64)+(CUBISM_BPLWIDTH/16),bltsize(a6)

		move.l	cubism_backbuffer(a5),a0
		WAIT_BLIT
		move.l	#$01000000,bltcon0(a6)
		move.l	a0,bltdpt(a6)
		clr.w	bltdmod(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#(CUBISM_BPLHEIGHT*2*64)+(CUBISM_BPLWIDTH/16),bltsize(a6)
		WAIT_BLIT

		lea.l	Script,a0
		jsr		Commander_Init

		lea.l	custom,a6
		jsr		WaitEOF
		move.l	cubism_vars,a5
		move.l	cubism_backcopper(a5),a0
		move.w	#DMAF_MASTER|DMAF_COPPER,dmacon(a6)		* turn off copper
		move.l	#cubism_maincopper,cop1lc(a6)	* run the main coplist
		move.l	a0,cop2lc(a6)				* install new cop2lc
		move.w	#0,copjmp1(a6)					* strobe copper to reset copper pc
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER|DMAF_COPPER,dmacon(a6)		* turn on copper again

.mainloop
		bsr		cubism_updateframe
		jsr		VSyncWithBgTask
        jsr     PartOver
        blt.s   .mainloop

.endofpart
		rts
		
*
*

;--------------------------------------------------------------------
* Size of the three bitpflane playfields

cubism_updateframe:
		move.w	Cubeframe,d0		
		add.w	#1,d0
		and.w	#CUBE_FRAMES-1,d0
		move.w	d0,Cubeframe
		lsl.w	#3,d0
		lea.l	FrontBackColor,a0
		lea.l	(a0,d0.w),a0
		move.l	a0,FrontBackThisFrame	

		bsr		cubism_newdraw
		bsr		cubism_animate					* move segments around
	
		* BUILDCOPPER
		move.l	cubism_vars,a5
		move.l	cubism_backcopper(a5),a0		* get copperptrs
		add.l	cubism_coppreamble(a5),a0

		move.l	#CUBISM_STARTLINE,d0			* current segment's vertical position
		move.l	cubism_backbuffer(a5),d1		* here's the 
		lea.l	cubism_current_segments,a1		* list of segment types

		rept	6
			move.l	CUBISM_SEG_ROUTINE(a1),a3		* get segment routine pointer from list
			move.w	CUBISM_SEG_BYTEOFFSET(a1),d5	* get scroll offset and byteoffset for bitplanes
			move.w	CUBISM_SEG_SCROLLREG(a1),d2		* get scroll offset and byteoffset for bitplanes
			jsr		(a3)							* produce segment: d0 = current screen vpos,d1 = segment screen addrFess,d2 = offsets for bplptr/bplcon1,a0 = copperlist
			adda.l	#16,a1
			add.l	#CUBISM_SEGMENTHEIGHT*$1000000,d0	* wait another 32 lines
			add.l	#CUBISM_SEGBPLSIZE,d1			* move basic cube down one segment (32 lines)
			move.l	cubism_vars,a5
			add.l	cubism_copseglen(a5),a0
		endr

		move.l	cubism_frontcopper(a5),d0
		move.l	cubism_backcopper(a5),d1
		move.l	d1,cubism_frontcopper(a5)
		move.l	d0,cubism_backcopper(a5)

		move.l	cubism_frontbuffer(a5),d0
		move.l	cubism_backbuffer(a5),d1
		move.l	d1,cubism_frontbuffer(a5)
		move.l	d0,cubism_backbuffer(a5)

		rts

CLEARLINES = 192+64

cubism_newdraw:
		* simple blitter clear
		lea.l	custom,a6
		move.l	cubism_vars,a5
		move.l	cubism_drawbuffer(a5),a0
		WAIT_BLIT
		move.l	#$01000000,bltcon0(a6)
		move.l	a0,bltdpt(a6)
		clr.w	bltdmod(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#(CLEARLINES*64)+CUBISM_DRAWWIDTH/16,bltsize(a6)

		lea.l	CUBISM_DRAWPLANE*2(a0),a0
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#0,d4
		moveq	#0,d5
		moveq	#0,d6
		moveq	#0,d7
		sub.l	a1,a1
		sub.l	a2,a2
		sub.l	a3,a3
		sub.l	a4,a4
		rept	64
		movem.l	d0-d7/a1-a4,-(a0)
		endr		
		* find right set of coords
		lea.l	RotatedCubePoints2d,a3
		and.w	#CUBE_FRAMES-1,Cubeframe
		move.w	Cubeframe,d0
		move.w	d0,d1
		lsl.w	#5,d0
		lea.l	(a3,d0.w),a3
		move.l	FrontBackThisFrame,a2
		move.w	#(CUBISM_DRAWWIDTH/8),d4		* bitmap width, times 2 for interleaved
		lea.l	CubeFaces,a4
		move.w	#5,d7							* number of faces
.newface
		btst	d7,1(a2)						* visible face?
		bne.s	.drawface  
		adda.l	#18,a4
		dbf		d7,.newface
		bra		.enddraw
.drawface
		move.w	(a4)+,d5						* d6 is color
		move.w	#4-1,d6							* num edges
.newedge
		move.w	(a4)+,d2						* first vertex
		add.w	d2,d2
		add.w	d2,d2
		move.w	(a3,d2.w),d0
		move.w	2(a3,d2.w),d1

		move.w	(a4)+,d3						* x2
		add.w	d3,d3
		add.w	d3,d3
		move.w	(a3,d3.w),d2
		move.w	2(a3,d3.w),d3

		btst	#0,d5							* first bit of colors
		beq.s	.nopl1							* don't draw on first plane
		movem.l	d0-d7/a1-a5,-(sp)
		WAIT_BLIT
		move.l	cubism_drawbuffer(a5),a0
		bsr		cubism_drawedgeline
		movem.l	(sp)+,d0-d7/a1-a5
.nopl1	btst	#1,d5
		beq.s	.nopl2
		move.l	cubism_drawbuffer(a5),a0
		add.l	#CUBISM_DRAWPLANE,a0			* move to second interleaved bitplane
		movem.l	d0-d7/a1-a5,-(sp)
		WAIT_BLIT
		bsr		cubism_drawedgeline
		movem.l	(sp)+,d0-d7/a1-a5
.nopl2
		dbf		d6,.newedge
		dbf		d7,.newface
.enddraw
		* fill the area, and copy to viewport
		move.l	cubism_vars,a5
		move.l	cubism_drawbuffer(a5),a1
		lea.l	(CUBISM_DRAWPLANE*2)-2(a1),a1
		move.l	cubism_backbuffer(a5),a2
		move.l	#(CUBISM_BPLSIZE*2)-(CUBISM_DRAWSKIP/8),d0
		lea.l	-2(a2,d0.w),a2

		sub.l	#(CUBISM_BPLWIDTH/8)/2,a2

		moveq	#0,d0
		move.w	#CUBISM_DRAWSKIP/8,d1

		WAIT_BLIT
		move.l	#-1,bltafwm(a6)					* no mask
		move.l	#$09f00012,bltcon0(a6)			* only d ch
		move.l	a1,bltapt(a6)					* backbuffer is the end of fill sector
		move.l	a2,bltdpt(a6)					* backbuffer is the end of fill sector
		move.w	d0,bltamod(a6)					* set modulo
		move.w	d1,bltdmod(a6)					* set modulo
		move.w	#(CUBISM_DRAWHEIGHT*2*64)+(CUBISM_DRAWWIDTH/16),bltsize(a6)
		rts


cubism_emptysegment:
		move.w	#$0200,10(a0)			* turn off the segment
		rts

cubism_glenzsegment:
		* d1 = current bplptr for first bitplane
		move.w	#$4200,10(a0)					* after wait, col0, and $0100 (4 bpls)
		move.w	d2,14(a0)						* bplcon1

		move.w	d5,d6
		ext.l	d6
		add.l	d1,d6							* d6 = full address for plane 1
		move.w	d6,22(a0)						* low word
		swap	d6
		move.w	d6,18(a0)						* high word
		swap	d6
		add.l	#CUBISM_BPLSIZE,d6				* plane 2
		move.w	d6,30(a0)						* low word
		swap	d6
		move.w	d6,26(a0)						* high word
		swap	d6
		add.l	#CUBISM_BPLSIZE,d6				* plane 3
		move.w	d6,38(a0)						* low word
		swap	d6
		move.w	d6,34(a0)						* high word
		swap	d6
		add.l	#CUBISM_BPLSIZE,d6				* plane 4
		move.w	d6,46(a0)						* low word
		swap	d6
		move.w	d6,42(a0)						* high word
		swap	d6

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4
		move.l	cubism_glenzpalette,a5

		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),50(a0)

		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),54(a0)

		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),58(a0)
		rts

		swap	d2								* get bplptr byteoffset down to lower bits
		move.w	d2,d5							* move to empty d5
		ext.l	d5								* clear upper bits
		add.l	d1,d5							* add screen address to d5:  now d5 contains screen address _and_ byteoffset for segment
		swap	d2								* swap back to d2 = scroll registers

		move.l	#$01004200,(a0)+				* set number of bitplanes from start
		move.w	#$0102,(a0)+					* set scroll register
		move.w	d2,(a0)+						* ... to value supplied in d2

		move.w	#3,d6							* number of bitplanes to set: glenz has 4
		move.w	#$00e0,d4						* first bplptr code
.bpl	move.w	d4,(a0)+						* set high word bplptr code
		swap	d5
		move.w	d5,(a0)+						* set hihg word bplptr
		swap	d5
		addq.w	#2,d4
		move.w	d4,(a0)+						* lower word bplptrs code
		move.w	d5,(a0)+						* set lower word of bplptr
		addq.w	#2,d4
		add.l	#CUBISM_BPLSIZE,d5				* add bplsize to set ptrs for next bpl
		dbf		d6,.bpl							* bitplane loop

				* glenz color setup: 4 colors banks a 4-1 colors.
				* $01800000,$01820000,$01840000,$01860000    %00XX
				* $01880000,$018a0000,$018c0000,$018e0000		%01XX
				* $01900000,$01920000,$01940000,$01960000		%10XX
				* $01980000,$019a0000,$019c0000,$019e0000		%11XX

		move.l	cubism_glenzpalette,a5
		move.l	#$01800000+CUBISM_BACKCOL,(a0)+	* set background colors
		move.l	#$01880000+CUBISM_BACKCOL,(a0)+
		move.l	#$01900000+CUBISM_BACKCOL,(a0)+
		move.l	#$01980000+CUBISM_BACKCOL,(a0)+

*		lea.l	cubism_colorintensities,a4
.newcol
		move.w	(a4)+,d4						* color id
		add.w	d4,d4							* id's are in numbers 1-3 etc.. multiply with 2
		add.w	#$180,d4						* color register ok
		move.w	d4,(a0)+						* mark first color register
		move.w	(a4)+,d6						* get cosine for visible face
		lsr		#3,d6							* cosine to 0-15 colors = 0-30 bytes
		add.w	d6,d6
		move.w	(a5,d6.w),(a0)+					* get color from palette and install in copperlist
		add.w	#$0008,d4						* next color relevant for this face is the color %01XX
		move.w	d4,(a0)+						* always something "behind",we make color %01XX the same
		subq.w	#2,d6
		bpl.w	.cansub0						* if yes,dont reduce further
		moveq	#0,d6							* reduce intensity by 1
.cansub0
		move.w	(a5,d6.w),(a0)+					* install in copperlist
		subq.w	#2,d6
		bpl.w	.cansub1						* if yes,dont reduce further
		moveq	#0,d6							* reduce intensity by 1
.cansub1
		add.w	#$0008,d4						* next color is %10XX  (an invisible face with color id 2)
		and.w	#$1e,d6
		move.w	d4,(a0)+						* set color register
		move.w	(a5,d6.w),(a0)+					* we've reduced the color intensity and install it
		subq.w	#4,d6
		bpl.w	.cansub2						* if yes,dont reduce further
		moveq	#0,d6							* reduce intensity by 1
.cansub2
		add.w	#$0008,d4						* next color is %11XX,color id 3 but not on the front
		move.w	d4,(a0)+						* put it in the copperlist
		move.w	(a5,d6.w),(a0)+					* we've reduced the color intensity and install it

		cmp.w	#$ffff,(a4)
		bne.s	.newcol
		rts



cubism_purple_glenzsegment:
		move.l	#cubism_pal_peach,cubism_glenzpalette
		bra		cubism_glenzsegment
		rts
cubism_gold_glenzsegment:
		move.l	#cubism_pal_gold,cubism_glenzpalette
		bra		cubism_glenzsegment
		rts
cubism_granny_glenzsegment:
		move.l	#cubism_pal_granny,cubism_glenzpalette
		bra		cubism_glenzsegment
		rts
cubism_granny_blenksegment:
		move.l	#cubism_pal_granny,cubism_blenkpalette
		bra		cubism_blenksegment
		rts
cubism_purple_blenksegment:
		move.l	#cubism_pal_purple,cubism_blenkpalette
		bra		cubism_blenksegment
		rts
cubism_gold_blenksegment:
		move.l	#cubism_pal_purple,cubism_blenkpalette
		bra		cubism_blenksegment
		rts
cubism_red_blenksegment:
		move.l	#cubism_pal_red,cubism_blenkpalette
		bra		cubism_blenksegment
		rts
cubism_crayola_blenksegment:
		move.l	#cubism_pal_crayola,cubism_blenkpalette
		bra		cubism_blenksegment
		rts
cubism_crayola_glenzsegment:
		move.l	#cubism_pal_crayola,cubism_glenzpalette
		bra		cubism_glenzsegment
		rts
cubism_blue_blenksegment:
		move.l	#cubism_pal_blue,cubism_blenkpalette
		bra		cubism_blenksegment
		rts
cubism_grey_blenksegment:
		move.l	#cubism_pal_grey,cubism_blenkpalette
		bra		cubism_blenksegment
		rts

* BLENK VECTOR: requires screen address in d1,copperlist address in a0. kills d4-d6
* scroll in d2
*
* Segment structure: WAIT (4), COL0, BPLCON0, BPLCON1, BPLPTR1-4, COL0, COL1-15
* 4 bytes per instruction
cubism_blenksegment:
		* d1 = current bplptr for first bitplane
		* a0 = start of copper segment
		move.w	#$2200,10(a0)					* after wait, col0, and $0100
		move.w	d2,14(a0)						* bplcon1
		move.w	d5,d6
		ext.l	d6
		add.l	d1,d6							* d6 = full address for plane 1
		move.w	d6,22(a0)						* low word
		swap	d6
		move.w	d6,18(a0)						* high word
		swap	d6
		add.l	#CUBISM_BPLSIZE,d6				* plane 2
		move.w	d6,30(a0)						* low word
		swap	d6
		move.w	d6,26(a0)						* high word
		swap	d6

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4
		move.l	cubism_blenkpalette,a5

		*move.w	#$182,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),50(a0)

		*move.w	#$184,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),54(a0)

		*move.w	#$186,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),58(a0)
		rts

	cubism_codersegment:
		move.w	#$2200,10(a0)					* after wait, col0, and $0100
		move.w	d2,14(a0)						* bplcon1
		move.w	d5,d6
		ext.l	d6
		add.l	d1,d6							* d6 = full address for plane 1
		move.w	d6,22(a0)						* low word
		swap	d6
		move.w	d6,18(a0)						* high word
		swap	d6
		add.l	#CUBISM_BPLSIZE,d6				* plane 2
		move.w	d6,30(a0)						* low word
		swap	d6
		move.w	d6,26(a0)						* high word
		swap	d6

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4

		move.l	#cubism_pal_red,a5
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),50(a0)

		move.l	#cubism_pal_green,a5
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),54(a0)

		move.l	#cubism_pal_blue,a5
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),58(a0)
		rts


	cubism_spiralsegment:
		move.w	#$3200,10(a0)					* after wait, col0, and $0100
		move.w	d2,14(a0)						* bplcon1
		move.w	d5,d6
		ext.l	d6
		add.l	d1,d6							* d6 = full address for plane 1
		move.w	d6,22(a0)						* low word
		swap	d6
		move.w	d6,18(a0)						* high word
		swap	d6
		add.l	#CUBISM_BPLSIZE,d6				* plane 2
		move.w	d6,30(a0)						* low word
		swap	d6
		move.w	d6,26(a0)						* high word
		swap	d6

		move.l	cubism_spiralptr,d6				* plane 3 uses spiral buffer
		move.w	d6,38(a0)						* low word
		swap	d6
		move.w	d6,34(a0)						* high word
		swap	d6

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4

		move.l	#cubism_pal_green,a5
		move.w	(a4),d4							* color id
		move.w	(a5,d4.w),50(a0)				* color 1
		move.w	2(a4),d4
		move.w	(a5,d4.w),54(a0)				* color 2
		move.w	4(a4),d4
		move.w	(a5,d4.w),58(a0)				* color 3

		move.w	#CUBISM_BACKCOL,62(a0)			* color 4 (stencil only)

		move.l	#cubism_pal_granny,a5
		move.w	(a4),d4
		move.w	(a5,d4.w),66(a0)				* color 5
		move.w	2(a4),d4
		move.w	(a5,d4.w),70(a0)				* color 6
		move.w	4(a4),d4
		move.w	(a5,d4.w),74(a0)				* color 7
		rts


cubism_noisesegment:
		* d1 = current bplptr for first bitplane
		move.w	#$3200,10(a0)					* after wait, col0, and $0100
		move.w	d2,14(a0)						* bplcon1
		move.w	d5,d6
		ext.l	d6
		add.l	d1,d6							* d6 = full address for plane 1
		move.w	d6,22(a0)						* low word
		swap	d6
		move.w	d6,18(a0)						* high word
		swap	d6
		add.l	#CUBISM_BPLSIZE,d6				* plane 2
		move.w	d6,30(a0)						* low word
		swap	d6
		move.w	d6,26(a0)						* high word
		swap	d6

		move.l	cubism_vars,a5
		move.l	d0,d7							* save d0
		jsr		Random32
		and.l	#$3ff,d0
		add.l	cubism_noiseptr(a5),d0			* switch noise buffers
		move.l	d0,d6							* plane 3 pointer
		move.l	d7,d0							* restore d0

		move.w	d6,38(a0)						* low word
		swap	d6
		move.w	d6,34(a0)						* high word
		swap	d6

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4

		move.w	#0,50(a0)						* color 1
		move.w	#0,54(a0)						* color 2
		move.w	#0,58(a0)						* color 3
		move.w	#CUBISM_BACKCOL,62(a0)			* color 4 (stencil only)

		move.l	cubism_noisepalette,a5
		move.w	(a4),d4
		move.w	(a5,d4.w),66(a0)				* color 5
		move.w	2(a4),d4
		move.w	(a5,d4.w),70(a0)				* color 6
		move.w	4(a4),d4
		move.w	(a5,d4.w),74(a0)				* color 7
		rts

CUBISM_MAXXPOS = CUBISM_BPLWIDTH
CUBISM_XPOSTABLEN = 4*CUBISM_MAXXPOS
cubism_initanimation:
		* TODO: prepare table of xpositions frmo 0 to 383.
		* each table entry should have a word lenght byte offsets and a word length scroll register value (for bplcon1)

		move.l	cubism_vars,a5
		ALLOC_PUBLIC CUBISM_XPOSTABLEN,cubism_xpostable(a5)
		move.l	cubism_xpostable(a5),a0
		move.l	a0,a1
		* current xpos
		moveq	#0,d0
.newxpos
		move.w	d0,d1	* current xpos

		* convert pixels to coarse byte offset + fine scroll
		move.w	d1,d4
		lsr.w	#4,d4							*	get bytes from pixels
		add.w	d4,d4							* word align ** now offset to be added to bplptrs

		and.w	#$f,d1							* the scroll value

		move.w	d1,d2							* copy scroll reg value
		lsl.l	#4,d1							* move 4 bits higher for next playfield
		or.w	d1,d2							* combine playfields scroll register input
.noscroll
		move.w	d4,(a0)+						* set byteoffset (word aligned) for bplptrs
		move.w	d2,(a0)+						* set value for scroll register

		addq	#1,d0
		cmp.w	#CUBISM_MAXXPOS,d0
		blt		.newxpos
		nop

		* old code
		lea.l	cubism_moving_pattern,a1
		lea.l	cubism_sine256,a2
		move.w	#$7f,d7							* 128 values
		move.w	#$7e,d0							* +2 below lands on sine index $80 (left edge)
.newpos
		add.w	#2,d0
		move.w	(a2,d0.w),d1
		muls	#96*8,d1						* multiple -1 to 1 with 96 (halfway)
		swap	d1
		move.w	#192,d2							* we start at 192
		sub.w	d1,d2							* this is the new xpos in pixels
		move.w	d2,(a1)+

		dbf		d7,.newpos

		lea.l	cubism_animation_starts,a0
		lea.l	cubism_animation_scripts,a5
		lea.l	cubism_current_segments,a1
		move.w	#CUBISM_SEGMENTS-1,d7
.initlist
		move.l	(a0)+,(a5)+
		move.l	cubism_segment_types,CUBISM_SEG_ROUTINE(a1)
		bsr		cubism_nextanimstep
		adda.l	#$10,a1
		dbf		d7,.initlist
		rts



cubism_animate:									* animate the cube and its segments
		add.w	#1,cubism_animframe				* let the cube spin one frame ahead

		lea.l	cubism_current_segments,a1		* segment list
		move.w	#CUBISM_SEGMENTS-1,d7
.nextsegment
		move.w	CUBISM_SEG_WAIT(a1),d1
		subq.w	#1,d1
		move.w	d1,CUBISM_SEG_WAIT(a1)
		tst.w	d1
		bpl.s	.notdonewaiting
		bsr		cubism_nextanimstep
		bra		.nonewcmd
.notdonewaiting
		move.w	CUBISM_SEG_STATE(a1),d0
	* are we moving out?
	cmp.w	#CUBISM_ANIM_MOVEOUT,d0
	bne.s	.notmovingout
	sub.w	#2,CUBISM_SEG_XPOS(a1)			* prev word in the move table
	cmp.w	#$00,CUBISM_SEG_XPOS(a1)
		bpl.w	.nonewcmd
		move.w	#CUBISM_ANIM_STAY,CUBISM_SEG_STATE(a1)
		bsr		cubism_nextanimstep
	move.w	#$0,CUBISM_SEG_XPOS(a1)
	bra		.nonewcmd
.notmovingout
	* are we moving out to the right?
	cmp.w	#CUBISM_ANIM_MOVEOUT_R,d0
	bne.s	.notmovingout_r
	add.w	#2,CUBISM_SEG_XPOS(a1)
	cmp.w	#$fe,CUBISM_SEG_XPOS(a1)		* max index in table
	ble.w	.nonewcmd
	move.w	#CUBISM_ANIM_STAY,CUBISM_SEG_STATE(a1)
	bsr		cubism_nextanimstep
	move.w	#$fe,CUBISM_SEG_XPOS(a1)
	bra		.nonewcmd
.notmovingout_r
	* are we moving in from the right?
	cmp.w	#CUBISM_ANIM_MOVEIN_R,d0
	bne.s	.notmovingin_r
	sub.w	#2,CUBISM_SEG_XPOS(a1)
	cmp.w	#$80,CUBISM_SEG_XPOS(a1)
	bge.w	.nonewcmd
	bsr		cubism_nextanimstep
	move.w	#$80,CUBISM_SEG_XPOS(a1)
	bra		.nonewcmd
.notmovingin_r
	* are we moving in?
	cmp.w	#CUBISM_ANIM_MOVEIN,d0
	bne.s	.notmovingin
	add.w	#2,CUBISM_SEG_XPOS(a1)
	cmp.w	#$7e,CUBISM_SEG_XPOS(a1)		* $80 -2 = 126
		blt.w	.nonewcmd
		bsr		cubism_nextanimstep
		move.w	#$7e,CUBISM_SEG_XPOS(a1)
.notmovingin
.nonewcmd

	; * convert current xpos to byteoffset and scroll
	; lea.l	cubism_moving_pattern,a2
	; move.w	CUBISM_SEG_XPOS(a1),d2
	; and.w	#$fe,d2
	; move.w	(a2,d2.w),d4					* xpos in pixels

	; * convert pixels to coarse byte offset + fine scroll
	; move.w	d4,d3							* save xpos for later

	; lsr.w	#4,d4							*	get bytes from pixels
	; add.w	d4,d4							* word align ** now offset to be added to bplptrs
	; sub.w	#2,d4

	; and.w	#$f,d3							* the scroll value
	; move.w	#16,d2
	; sub.w	d3,d2
	; and.w	#$f,d2							* if no bits are set,we don't need to scroll
	; tst.w	d2								* do we scroll?
	; beq.s	.noscroll

	; move.w	d2,d3							* copy scroll reg value
	; lsl.l	#4,d3							* move 4 bits higher for next playfield
	; or.w	d3,d2							* combine playfields scroll register input
	; addq	#2,d4							* subtract two bytes (one word) from bplptrs,for scrolling right

	move.l	cubism_vars,a5
	move.l	cubism_xpostable(a5),a5
	move.w	256*4(a5),CUBISM_SEG_BYTEOFFSET(a1)
	move.w	2+256*4(a5),CUBISM_SEG_SCROLLREG(a1)

; .noscroll
; 	move.w	d4,CUBISM_SEG_BYTEOFFSET(a1)	* set byteoffset (word aligned) for bplptrs
; 	move.w	d2,CUBISM_SEG_SCROLLREG(a1)		* set value for scroll register

.finito
		adda.l	#16,a1							* move to next segment
		dbf		d7,.nextsegment

		*** animate spiral pattern
		lea.l	cubism_sine256,a1
		lea.l	cubism_spiral_positions,a0
		move.w	(a0),d0
		add.w	#CUBISM_SPIRAL_YSPD,d0
		and.w	#$1fe,d0
		move.w	d0,(a0)

		moveq	#0,d1
		move.w	(a1,d0.w),d1
		add.w	#$8000,d1
		rol.l	#8,d1
		swap	d1								* ypos
		mulu.w	#50,d1							* offset on spiral buffer

		lea.l	cubism_spiral,a0
		adda.l	d1,a0
		move.l	a0,cubism_spiralptr
		rts

cubism_nextanimstep:
		lea.l	cubism_animation_scripts,a2
		moveq	#CUBISM_SEGMENTS-1,d5
		sub.w	d7,d5
		add.w	d5,d5
		add.w	d5,d5
		move.l	(a2,d5.w),a3					* pointer to animation script
		move.w	(a3)+,d4

				* does the routine needs restarting?
		cmp.w	#CUBISM_ANIM_RESTART,d4
		bne.s	.norestart
		lea.l	cubism_animation_starts,a4
		move.l	(a4,d5.w),a3					* get pointer to start of script
		move.w	(a3)+,d4						* get first anim cmd
.norestart
				* are we switching routine?
		cmp.w	#CUBISM_ANIM_SWITCH,d4
		bne.s	.notswitching
		move.w	(a3)+,d4
		add.w	d4,d4
		add.w	d4,d4
		lea.l	cubism_segment_types,a4
		move.l	(a4,d4.w),CUBISM_SEG_ROUTINE(a1)

				* Now we're done switching,and we move on to the next anim step
		move.w	(a3)+,d4

.notswitching
		cmp.w	#CUBISM_ANIM_STAY,d4
		bne.s	.nostay
		move.w	d5,CUBISM_SEG_STATE(a1)
		move.w	(a3)+,CUBISM_SEG_WAIT(a1)
		move.l	a3,(a2,d5.w)					* save animation script pointer
		rts
.nostay
	cmp.w	#CUBISM_ANIM_MOVEIN,d4
	bne.s	.notmovingin
	move.w	d4,CUBISM_SEG_STATE(a1)
	move.w	(a3)+,CUBISM_SEG_WAIT(a1)
	move.l	a3,(a2,d5.w)					* save animation script pointer
	rts
.notmovingin
	cmp.w	#CUBISM_ANIM_MOVEOUT,d4
	bne.s	.notmovingout
	move.w	d4,CUBISM_SEG_STATE(a1)
	move.w	(a3)+,CUBISM_SEG_WAIT(a1)
.notmovingout
	cmp.w	#CUBISM_ANIM_MOVEIN_R,d4
	bne.s	.notmovingin_r
	move.w	d4,CUBISM_SEG_STATE(a1)
	move.w	#$fe,CUBISM_SEG_XPOS(a1)		* start at rightmost
	move.w	(a3)+,CUBISM_SEG_WAIT(a1)
	move.l	a3,(a2,d5.w)					* save animation script pointer
	rts
.notmovingin_r
	cmp.w	#CUBISM_ANIM_MOVEOUT_R,d4
	bne.s	.notmovingout_r
	move.w	d4,CUBISM_SEG_STATE(a1)
	move.w	#$80,CUBISM_SEG_XPOS(a1)		* start at center for right-half move out
	move.w	(a3)+,CUBISM_SEG_WAIT(a1)
.notmovingout_r
	move.l	a3,(a2,d5.w)					* save animation script pointer
	rts

cubism_clearscreen:
		move.l	cubism_vars,a5
		move.l	cubism_backbuffer(a5),a1		* get ptr to clear-ready screen
*		move.l	DRAWSCR(a0),a1					* move the address of the screen to be cleared to a1
				*bsr cubism_cpu_clearscreen
		bsr		cubism_blitter_clearscreen
		rts


cubism_blitter_clearscreen:
		lea.l	custom,a6						; a6 - custom base
		move.l	cubism_vars,a5
		move.l	cubism_backbuffer(a5),a0
		move.w	#CUBISM_DRAWWIDTH/16,d4			; d4 - screen width in words
		move.w	#CUBISM_BPLHEIGHT*CUBISM_BPLDEPTH,d5 ; d5 - screen height (effective times BPLDEPTH)
.bltwait:
		btst.b	#14,dmaconr(a6)					; wait for blitter ready
		bne.b	.bltwait

		move.l	a0,bltdpt(a6)
		moveq.l	#CUBISM_DRAWSKIP/8,d0
		move.w	d0,bltdmod(a6)
		move.l	#%100000000,d0
		swap	d0
		move.l	d0,bltcon0(a6)

		move.w	d5,d0
		lsl.w	#6,d0
		or.w	d4,d0
		move.w	d0,bltsize(a6)
		rts

cubism_preparenoise:
		move.l	cubism_vars,a5
		move.l	cubism_noiseptr(a5),a0
		move.w	#(2*CUBISM_SEGBPLSIZE/4)-1,d7
.makenoise
		jsr		Random32
		move.l	d0,(a0)+
		dbf		d7,.makenoise
		rts

cubism_precalc_chesslines:
		move.l	cubism_vars,a5
		ALLOC_PUBLIC CHESS_TOTAL_SIZE,cubism_chesslines(a5)
		move.l	cubism_chesslines(a5),a0		* base write ptr

		moveq	#0,d7							* frame index
.frame_loop
		move.l	a0,a1							* frame start
		addq.l	#2,a0							* reserve space for count
		move.w	#0,(a1)							* line count

		lea.l	RotatedCubePoints3d,a2
		move.w	d7,d0
		mulu	#48,d0							* 8 vertices * 3 words * 2 bytes
		adda.l	d0,a2							* a2 = 3d points for frame

		lea.l	FrontBackColor,a3
		move.w	d7,d0
		mulu	#8,d0
		adda.l	d0,a3							* a3 = visibility for frame

		moveq	#0,d5							* face index
.face_loop
		btst	d5,1(a3)
		beq		.next_face

		lea.l	CubeFaces,a4
		move.w	d5,d0
		mulu	#18,d0							* 9 words per face
		adda.l	d0,a4

		* v1 coords
		move.w	2(a4),d0						* v1
		mulu	#6,d0
		lea.l	(a2,d0.w),a6
		move.w	(a6),d0							* v1x
		move.w	2(a6),d1						* v1y
		move.w	4(a6),d2						* v1z

		* v2 coords
		move.w	4(a4),d3						* v2
		mulu	#6,d3
		lea.l	(a2,d3.w),a6
		move.w	(a6),d3							* v2x
		move.w	2(a6),d4						* v2y
		move.w	4(a6),d5						* v2z

		* du = v2 - v1
		sub.w	d0,d3							* dux
		sub.w	d1,d4							* duy
		sub.w	d2,d5							* duz

		* store v1 and du on stack (6 words)
		suba.l	#18,sp
		move.w	d0,0(sp)						* v1x
		move.w	d1,2(sp)						* v1y
		move.w	d2,4(sp)						* v1z
		move.w	d3,6(sp)						* dux
		move.w	d4,8(sp)						* duy
		move.w	d5,10(sp)						* duz

		* v4 coords
		move.w	12(a4),d6						* v4
		mulu	#6,d6
		lea.l	(a2,d6.w),a6
		move.w	(a6),d6							* v4x
		move.w	2(a6),d4						* v4y
		move.w	4(a6),d5						* v4z (reuse d5)

		* dv = v4 - v1
		sub.w	d0,d6							* dvx
		sub.w	d1,d4							* dvy
		sub.w	d2,d5							* dvz
		move.w	d6,12(sp)						* dvx
		move.w	d4,14(sp)						* dvy
		move.w	d5,16(sp)						* dvz

		* u-lines (5)
		moveq	#0,d3							* i = 0..4
.uline_loop
		move.w	6(sp),d0						* dux
		ext.l	d0
		muls	d3,d0
		asr.l	#2,d0
		add.w	0(sp),d0						* x0

		move.w	8(sp),d1						* duy
		ext.l	d1
		muls	d3,d1
		asr.l	#2,d1
		add.w	2(sp),d1						* y0

		move.w	10(sp),d2						* duz
		ext.l	d2
		muls	d3,d2
		asr.l	#2,d2
		add.w	4(sp),d2						* z0

		move.w	d0,d4
		add.w	12(sp),d4						* x1
		move.w	d1,d5
		add.w	14(sp),d5						* y1
		move.w	d2,d6
		add.w	16(sp),d6						* z1

		move.w	d4,-(sp)						* save x1
		move.w	d5,-(sp)						* save y1
		move.w	d6,-(sp)						* save z1
		bsr		chess_project_point
		move.w	(sp)+,d6						* restore z1
		move.w	(sp)+,d5						* restore y1
		move.w	(sp)+,d4						* restore x1
		move.w	d0,-(sp)						* save x0
		move.w	d1,-(sp)						* save y0
		move.w	d4,d0
		move.w	d5,d1
		move.w	d6,d2
		bsr		chess_project_point
		move.w	(sp)+,d2						* y0
		move.w	(sp)+,d3						* x0
		move.w	d0,d4							* x1
		move.w	d1,d5							* y1

		move.w	d3,d0
		move.w	d4,d1
		tst.w	d0
		bpl.s	.xu_notneg
		tst.w	d1
		bmi.s	.u_skip
.xu_notneg
		cmp.w	#CHESS_MAXXY,d0
		ble.s	.xu_ok
		cmp.w	#CHESS_MAXXY,d1
		bgt.s	.u_skip
.xu_ok
		move.w	d2,d0
		move.w	d5,d1
		tst.w	d0
		bpl.s	.yu_notneg
		tst.w	d1
		bmi.s	.u_skip
.yu_notneg
		cmp.w	#CHESS_MAXXY,d0
		ble.s	.yu_ok
		cmp.w	#CHESS_MAXXY,d1
		bgt.s	.u_skip
.yu_ok
		move.w	d3,(a0)+						* x0
		move.w	d2,(a0)+						* y0
		move.w	d4,(a0)+						* x1
		move.w	d5,(a0)+						* y1
		addq.w	#1,(a1)
.u_skip
		addq.w	#1,d3
		cmp.w	#5,d3
		blt	.uline_loop

		* v-lines (5)
		moveq	#0,d3							* i = 0..4
.vline_loop
		move.w	12(sp),d0						* dvx
		ext.l	d0
		muls	d3,d0
		asr.l	#2,d0
		add.w	0(sp),d0						* x0

		move.w	14(sp),d1						* dvy
		ext.l	d1
		muls	d3,d1
		asr.l	#2,d1
		add.w	2(sp),d1						* y0

		move.w	16(sp),d2						* dvz
		ext.l	d2
		muls	d3,d2
		asr.l	#2,d2
		add.w	4(sp),d2						* z0

		move.w	d0,d4
		add.w	6(sp),d4						* x1
		move.w	d1,d5
		add.w	8(sp),d5						* y1
		move.w	d2,d6
		add.w	10(sp),d6						* z1

		move.w	d4,-(sp)						* save x1
		move.w	d5,-(sp)						* save y1
		move.w	d6,-(sp)						* save z1
		bsr		chess_project_point
		move.w	(sp)+,d6						* restore z1
		move.w	(sp)+,d5						* restore y1
		move.w	(sp)+,d4						* restore x1
		move.w	d0,-(sp)						* save x0
		move.w	d1,-(sp)						* save y0
		move.w	d4,d0
		move.w	d5,d1
		move.w	d6,d2
		bsr		chess_project_point
		move.w	(sp)+,d2						* y0
		move.w	(sp)+,d3						* x0
		move.w	d0,d4							* x1
		move.w	d1,d5							* y1

		move.w	d3,d0
		move.w	d4,d1
		tst.w	d0
		bpl.s	.xv_notneg
		tst.w	d1
		bmi.s	.v_skip
.xv_notneg
		cmp.w	#CHESS_MAXXY,d0
		ble.s	.xv_ok
		cmp.w	#CHESS_MAXXY,d1
		bgt.s	.v_skip
.xv_ok
		move.w	d2,d0
		move.w	d5,d1
		tst.w	d0
		bpl.s	.yv_notneg
		tst.w	d1
		bmi.s	.v_skip
.yv_notneg
		cmp.w	#CHESS_MAXXY,d0
		ble.s	.yv_ok
		cmp.w	#CHESS_MAXXY,d1
		bgt.s	.v_skip
.yv_ok
		move.w	d3,(a0)+						* x0
		move.w	d2,(a0)+						* y0
		move.w	d4,(a0)+						* x1
		move.w	d5,(a0)+						* y1
		addq.w	#1,(a1)
.v_skip
		addq.w	#1,d3
		cmp.w	#5,d3
		blt		.vline_loop

		adda.l	#18,sp
.next_face
		addq.w	#1,d5
		cmp.w	#6,d5
		blt		.face_loop

		add.l	#CHESS_FRAME_SIZE,a1
		move.l	a1,a0

		addq.w	#1,d7
		cmp.w	#CUBE_FRAMES,d7
		blt		.frame_loop
		rts

cubism_precalc_spacecut:
		move.l	cubism_vars,a5
		ALLOC_PUBLIC SPACECUT_TOTAL_SIZE,cubism_spacecutpoly(a5)
		move.l	cubism_spacecutpoly(a5),a0		* base write ptr

		moveq	#0,d7							* frame index
.frame_loop
		move.l	a0,a1							* frame start
		addq.l	#2,a0							* reserve space for count
		move.w	#0,(a1)							* point count

		lea.l	RotatedCubePoints3d,a2
		move.w	d7,d0
		mulu	#48,d0							* 8 vertices * 3 words * 2 bytes
		adda.l	d0,a2							* a2 = 3d points for frame

		* temp buffer on stack: count + points (x,y)
		suba.l	#40,sp
		move.l	sp,a3							* a3 = base
		move.w	d7,(a3)							* save frame index
		lea.l	2(a3),a3						* a3 = count
		clr.w	(a3)							* count = 0
		lea.l	2(a3),a4						* a4 = write ptr

		lea.l	SpacecutEdges,a6
		moveq	#12-1,d6
.edge_loop
		move.w	(a6)+,d0						* v0 index
		move.w	(a6)+,d3						* v1 index

		move.w	d0,d2
		mulu	#6,d2
		lea.l	(a2,d2.w),a5
		move.w	(a5),d0							* x0
		move.w	2(a5),d1						* y0
		move.w	4(a5),d2						* z0
		move.w	d0,SPACECUT_TMP_X0(a3)			* save x0
		move.w	d1,SPACECUT_TMP_Y0(a3)			* save y0

		move.w	d3,d4
		mulu	#6,d4
		lea.l	(a2,d4.w),a5
		move.w	(a5),d3							* x1
		move.w	2(a5),d4						* y1
		move.w	4(a5),d5						* z1

		* if z0 == depth, add v0
		cmp.w	#SPACECUT_DEPTH,d2
		bne.s	.check_z1
		bsr		spacecut_add_point
.check_z1
		* if z1 == depth, add v1
		cmp.w	#SPACECUT_DEPTH,d5
		bne.s	.check_cross
		move.w	d3,d0							* x
		move.w	d4,d1							* y
		bsr		spacecut_add_point

.check_cross
		move.w	d2,d7
		sub.w	#SPACECUT_DEPTH,d7				* z0 - depth
		move.w	d5,d5
		sub.w	#SPACECUT_DEPTH,d5				* z1 - depth
		muls	d5,d7
		bpl.s	.edge_done						* same side or on plane

		* interpolate intersection point (8.8 fixed t)
		move.w	d5,d7
		add.w	#SPACECUT_DEPTH,d7				* z1
		sub.w	d2,d7							* dz = z1 - z0
		beq.s	.edge_done
		move.w	d2,d5
		sub.w	#SPACECUT_DEPTH,d5				* z0 - depth
		neg.w	d5								* depth - z0
		ext.l	d5
		asl.l	#8,d5							* 8.8 fixed
		divs	d7,d5							* t in d5.w

		move.w	SPACECUT_TMP_X0(a3),d0			* x0
		move.w	SPACECUT_TMP_Y0(a3),d1			* y0
		move.w	d3,d7
		sub.w	d0,d7							* dx = x1 - x0
		move.w	d4,d2
		sub.w	d1,d2							* dy = y1 - y0

		move.w	d7,d3
		muls	d5,d3
		asr.l	#8,d3
		add.w	d3,d0							* x = x0 + dx*t

		move.w	d2,d3
		muls	d5,d3
		asr.l	#8,d3
		add.w	d3,d1							* y = y0 + dy*t

		bsr		spacecut_add_point

.edge_done
		dbf		d6,.edge_loop

		* sort points around center in world x/y (z is constant)
		bsr		spacecut_sort_points

		* write projected polygon to output
		move.w	(a3),d6							* count
		cmp.w	#3,d6
		blt.s	.no_poly

		move.w	d6,(a1)
		lea.l	2(a3),a4
		subq.w	#1,d6
		move.w	d6,d7
.write_loop
		move.w	(a4)+,d0						* x
		move.w	(a4)+,d1						* y
		move.w	#SPACECUT_DEPTH,d2
		bsr		spacecut_project_point
		move.w	d0,(a0)+
		move.w	d1,(a0)+
		dbf		d7,.write_loop
		bra.s	.done_frame

.no_poly
		move.w	#0,(a1)

.done_frame
		move.w	-2(a3),d7						* restore frame index
		add.l	#40,sp
		add.l	#SPACECUT_FRAME_SIZE,a1
		move.l	a1,a0

		addq.w	#1,d7
		cmp.w	#CUBE_FRAMES,d7
		blt		.frame_loop
		rts

* Adds point (d0=x, d1=y) if unique and space available
spacecut_add_point:
		move.w	(a3),d2							* count
		cmp.w	#SPACECUT_MAX_POINTS,d2
		bge.s	.add_done

		move.w	d2,d3
		subq.w	#1,d3
		blt.s	.add_store
		move.l	a3,a5
		lea.l	2(a5),a5
.add_check
		move.w	(a5)+,d4
		move.w	(a5)+,d5
		cmp.w	d0,d4
		bne.s	.add_next
		cmp.w	d1,d5
		beq.s	.add_done
.add_next
		dbf		d3,.add_check

.add_store
		move.w	d0,(a4)+
		move.w	d1,(a4)+
		addq.w	#1,(a3)

.add_done
		rts

* Sort points in temp buffer by angle around center
spacecut_sort_points:
		move.w	(a3),d7
		cmp.w	#2,d7
		ble	.sort_done

		lea.l	2(a3),a4
		moveq	#0,d0
		moveq	#0,d1
		move.w	d7,d6
		subq.w	#1,d6
.sum_loop
		move.w	(a4)+,d2
		ext.l	d2
		add.l	d2,d0
		move.w	(a4)+,d2
		ext.l	d2
		add.l	d2,d1
		dbf		d6,.sum_loop

		move.l	d0,d2
		divs	d7,d2
		move.w	d2,d4							* cx
		move.l	d1,d2
		divs	d7,d2
		move.w	d2,d5							* cy

		move.w	d7,d6
		subq.w	#1,d6
.outer
		move.w	d6,d0
		lea.l	2(a3),a4
.inner
		move.w	d0,-(sp)

		move.w	(a4),d1						* px
		move.w	2(a4),d2					* py
		move.w	4(a4),d3					* qx
		move.w	6(a4),d7					* qy

		sub.w	d4,d1						* dx1
		sub.w	d5,d2						* dy1
		sub.w	d4,d3						* dx2
		sub.w	d5,d7						* dy2

		* p upper half?
		moveq	#0,d0
		tst.w	d2
		bgt.s	.p_upper
		bne.s	.p_done
		tst.w	d1
		blt.s	.p_done
.p_upper
		moveq	#1,d0
.p_done

		* q upper half?
		tst.w	d7
		bgt.s	.q_upper
		bne.s	.q_lower
		tst.w	d3
		blt.s	.q_lower
.q_upper
		moveq	#1,d7
		bra.s	.q_done
.q_lower
		moveq	#0,d7
.q_done

		cmp.w	d0,d7
		beq.s	.same_half
		bgt.s	.do_swap
		bra.s	.keep_order

.same_half
		move.w	6(a4),d7
		sub.w	d5,d7						* dy2
		move.w	d1,d0
		muls	d7,d0							* dx1*dy2
		move.w	d2,d7
		muls	d3,d7							* dy1*dx2
		sub.l	d7,d0
		bgt.s	.keep_order
		blt.s	.do_swap

.keep_order
		move.w	(sp)+,d0
		addq.l	#4,a4
		dbf		d0,.inner
		dbf		d6,.outer
		bra.s	.sort_done

.do_swap
		move.w	(a4),d1
		move.w	2(a4),d2
		move.w	4(a4),(a4)
		move.w	6(a4),2(a4)
		move.w	d1,4(a4)
		move.w	d2,6(a4)
		move.w	(sp)+,d0
		addq.l	#4,a4
		dbf		d0,.inner
		dbf		d6,.outer

.sort_done
		rts

spacecut_project_point:
		move.w	d2,d6
		add.w	#CHESS_DIST,d6

		move.l	d0,d3
		ext.l	d3
		move.w	#CHESS_FOCAL,d4
		muls	d4,d3
		divs.w	d6,d3
		move.w	#CHESS_CENTERX,d0
		add.w	d3,d0

		move.l	d1,d3
		ext.l	d3
		move.w	#CHESS_FOCAL,d4
		muls	d4,d3
		divs.w	d6,d3
		move.w	#CHESS_CENTERY,d1
		add.w	d3,d1
		rts

* Clip polygon in screen coords to Y window [d0..d1], inclusive.
* in: a0 = input poly (count, x/y pairs)
*     a1 = output poly buffer
*     d0.w = ymin
*     d1.w = ymax
* out: output poly in a1 (count, points)
spacecut_clip_ywindow:
		suba.l	#40,sp							* temp poly (count + points)
		move.l	sp,a2							* temp buffer

		move.l	a2,a1
		bsr		spacecut_clip_ymin

		move.l	a2,a0
		move.w	d1,d0							* ymax -> d0 for clip_ymax
		bsr		spacecut_clip_ymax

		add.l	#40,sp
		rts

* Clip polygon to y >= d0
* in: a3 = input poly (count + points)
*     a4 = output poly buffer
spacecut_clip_ymin:
		move.w	(a0)+,d7						* in count
		clr.w	(a1)							* out count
		lea.l	2(a1),a2						* out ptr
		tst.w	d7
		beq	.clip_ymin_done

		lea.l	0(a0),a3						* points start
		move.w	d7,d5
		subq.w	#1,d5
		mulu	#4,d5
		lea.l	(a3,d5.w),a4					* last point
		move.w	(a4),d1							* prevx
		move.w	2(a4),d2						* prevy

		move.w	d7,d5
		subq.w	#1,d5
.ymin_loop
		move.w	(a3)+,d3						* curx
		move.w	(a3)+,d4						* cury

		moveq	#0,d6							* prev_in
		cmp.w	d0,d2
		blt	.prev_out
		moveq	#1,d6
.prev_out
		moveq	#0,d7							* cur_in
		cmp.w	d0,d4
		blt	.cur_out
		moveq	#1,d7
.cur_out

		cmp.w	d6,d7
		beq	.ymin_same_side

		tst.w	d6								* prev_in?
		bne	.ymin_in_to_out

.ymin_out_to_in
		* compute intersection at y = ymin (d0)
		move.w	d4,d7
		sub.w	d2,d7							* dy
		beq	.ymin_advance
		move.w	d0,d6
		sub.w	d2,d6							* ymin - prevy
		ext.l	d6
		asl.l	#8,d6
		divs	d7,d6							* t in d6.w

		move.w	d3,d7
		sub.w	d1,d7							* dx
		muls	d6,d7
		asr.l	#8,d7
		add.w	d1,d7							* xint in d7

		move.w	d7,(a2)+
		move.w	d0,(a2)+
		addq.w	#1,(a1)
		move.w	d3,(a2)+
		move.w	d4,(a2)+
		addq.w	#1,(a1)
		bra	.ymin_advance

.ymin_in_to_out
		* compute intersection at y = ymin (d0)
		move.w	d4,d7
		sub.w	d2,d7							* dy
		beq	.ymin_advance
		move.w	d0,d6
		sub.w	d2,d6							* ymin - prevy
		ext.l	d6
		asl.l	#8,d6
		divs	d7,d6							* t in d6.w

		move.w	d3,d7
		sub.w	d1,d7							* dx
		muls	d6,d7
		asr.l	#8,d7
		add.w	d1,d7							* xint in d7

		move.w	d7,(a2)+
		move.w	d0,(a2)+
		addq.w	#1,(a1)
		bra	.ymin_advance

.ymin_same_side
		tst.w	d6								* prev_in?
		beq.s	.ymin_advance
		move.w	d3,(a2)+
		move.w	d4,(a2)+
		addq.w	#1,(a1)

.ymin_advance
		move.w	d3,d1							* prevx = curx
		move.w	d4,d2							* prevy = cury
		dbf		d5,.ymin_loop

.clip_ymin_done
		rts

* Clip polygon to y <= d0
* in: a0 = input poly (count + points)
*     a1 = output poly buffer
spacecut_clip_ymax:
		move.w	(a0)+,d7						* in count
		clr.w	(a1)							* out count
		lea.l	2(a1),a2						* out ptr
		tst.w	d7
		beq	.clip_ymax_done

		lea.l	0(a0),a3						* points start
		move.w	d7,d5
		subq.w	#1,d5
		mulu	#4,d5
		lea.l	(a3,d5.w),a4					* last point
		move.w	(a4),d1							* prevx
		move.w	2(a4),d2						* prevy

		move.w	d7,d5
		subq.w	#1,d5
.ymax_loop
		move.w	(a3)+,d3						* curx
		move.w	(a3)+,d4						* cury

		moveq	#0,d6							* prev_in
		cmp.w	d0,d2
		bgt.s	.prev_out2
		moveq	#1,d6
.prev_out2
		moveq	#0,d7							* cur_in
		cmp.w	d0,d4
		bgt.s	.cur_out2
		moveq	#1,d7
.cur_out2

		cmp.w	d6,d7
		beq.s	.ymax_same_side

		tst.w	d6								* prev_in?
		bne.s	.ymax_in_to_out

.ymax_out_to_in
		* compute intersection at y = ymax (d0)
		move.w	d4,d7
		sub.w	d2,d7							* dy
		beq.s	.ymax_advance
		move.w	d0,d6
		sub.w	d2,d6							* ymax - prevy
		ext.l	d6
		asl.l	#8,d6
		divs	d7,d6							* t in d6.w

		move.w	d3,d7
		sub.w	d1,d7							* dx
		muls	d6,d7
		asr.l	#8,d7
		add.w	d1,d7							* xint in d7

		move.w	d7,(a2)+
		move.w	d0,(a2)+
		addq.w	#1,(a1)
		move.w	d3,(a2)+
		move.w	d4,(a2)+
		addq.w	#1,(a1)
		bra.s	.ymax_advance

.ymax_in_to_out
		* compute intersection at y = ymax (d0)
		move.w	d4,d7
		sub.w	d2,d7							* dy
		beq.s	.ymax_advance
		move.w	d0,d6
		sub.w	d2,d6							* ymax - prevy
		ext.l	d6
		asl.l	#8,d6
		divs	d7,d6							* t in d6.w

		move.w	d3,d7
		sub.w	d1,d7							* dx
		muls	d6,d7
		asr.l	#8,d7
		add.w	d1,d7							* xint in d7

		move.w	d7,(a2)+
		move.w	d0,(a2)+
		addq.w	#1,(a1)
		bra.s	.ymax_advance

.ymax_same_side
		tst.w	d6								* prev_in?
		beq.s	.ymax_advance
		move.w	d3,(a2)+
		move.w	d4,(a2)+
		addq.w	#1,(a1)

.ymax_advance
		move.w	d3,d1							* prevx = curx
		move.w	d4,d2							* prevy = cury
		dbf		d5,.ymax_loop

.clip_ymax_done
		rts

* Draw filled polygon in screen coords into 1bpp buffer.
* in: a0 = poly (count + points)
*     a1 = buffer start
*     d4.w = bytes per row
*     d5.w = height (lines)
*     a6 = custom base
spacecut_draw_polygon:
		move.w	(a0)+,d7						* count
		cmp.w	#3,d7
		blt	.draw_done

		* draw edges
		lea.l	(a0),a2							* points start
		move.w	d7,d6
		subq.w	#1,d6
		mulu	#4,d6
		lea.l	(a2,d6.w),a3					* last point
		move.w	(a3),d0							* x0
		move.w	2(a3),d1						* y0

		move.w	d7,d6
		subq.w	#1,d6
.edge_loop
		move.w	(a2)+,d2						* x1
		move.w	(a2)+,d3						* y1
		movem.l	d0-d3/a0,-(sp)
		WAIT_BLIT
		move.l	a1,a0
		bsr		cubism_drawedgeline
		movem.l	(sp)+,d0-d3/a0
		move.w	d2,d0
		move.w	d3,d1
		dbf		d6,.edge_loop

		* fill in-place
		WAIT_BLIT
		move.l	#-1,bltafwm(a6)
		move.l	#$09f00012,bltcon0(a6)
		move.w	#0,bltamod(a6)
		move.w	#0,bltdmod(a6)
		move.w	d4,d0
		lsr.w	#1,d0							* width in words
		move.w	d5,d1
		lsl.w	#6,d1
		or.w	d0,d1							* bltsize
		move.l	a1,a0
		move.w	d5,d2
		mulu	d4,d2
		lea.l	-2(a0,d2.w),a0					* end ptr
		move.l	a0,bltapt(a6)
		move.l	a0,bltdpt(a6)
		move.w	d1,bltsize(a6)

.draw_done
		rts

SpacecutEdges:
		dc.w	0,1, 0,2, 0,4
		dc.w	1,3, 1,5
		dc.w	2,3, 2,6
		dc.w	3,7
		dc.w	4,5, 4,6
		dc.w	5,7
		dc.w	6,7

chess_project_point:
		move.w	d2,d6
		add.w	#CHESS_DIST,d6

		move.l	d0,d3
		ext.l	d3
		move.w	#CHESS_FOCAL,d4
		muls	d4,d3
		divs.w	d6,d3
		move.w	#CHESS_CENTERX,d0
		add.w	d3,d0

		move.l	d1,d3
		ext.l	d3
		move.w	#CHESS_FOCAL,d4
		muls	d4,d3
		divs.w	d6,d3
		move.w	#CHESS_CENTERY,d1
		add.w	d3,d1
		rts

;----------------------------------------------------------------------------------
; Draw blitter edge line for blitter area fill
;
; The routine assumes that the blitter is idle when called
; The routine will exit with the blitter active
;
; in	d0.w	x0
;	d1.w	y0
;	d2.w	x1
;	d3.w	y1
;	d4.w	bytes per row in bitplane
;	a0	bitplane
;	a6	$dff000

FILL_LINE_MINTERM = $4a							; xor
cubism_drawedgeline:
		move.w	d4,a1

		cmp.w	d1,d3
		bge.s	.downward
		exg		d0,d2
		exg		d1,d3
.downward

		sub.w	d0,d2
		sub.w	d1,d3

		move.w	d2,d4
		bpl.s	.positiveDX
		neg.w	d4
.positiveDX
		move.w	d3,d5
		bpl.s	.positiveDY
		neg.w	d5
.positiveDY
		move.w	d4,d6
		sub.w	d5,d6
		add.l	d6,d6
		move.w	d3,d6
		add.l	d6,d6
		move.w	d2,d6
		add.l	d6,d6
		swap	d6
		and.w	#7,d6
		lea		cubism_octant_lookup,a2
		move.b	(a2,d6.w),d6
		or.w	#BLTCON1F_SING|BLTCON1F_LINE,d6

		cmp.w	d4,d5
		bls.s	.absDyLessThanAbsDx
		exg		d4,d5
.absDyLessThanAbsDx

		move.w	d5,d7
		add.w	d7,d7
		sub.w	d4,d7
		add.w	d7,d7
		ext.l	d7
		move.l	d7,bltapt(a6)
		bpl.s	.positiveGradient
		or.w	#BLTCON1F_SIGN,d6
.positiveGradient

		add.w	d4,d4
		add.w	d4,d4
		add.w	d5,d5
		add.w	d5,d5
		move.w	d5,bltbmod(a6)
		sub.w	d4,d5
		move.w	d5,bltamod(a6)
		lsr.w	#2,d4

		move.w	#$8000,bltadat(a6)
		move.l	#$ffffffff,bltafwm(a6)

		move.w	d0,d2
		and.w	#$f,d2
		ror.w	#4,d2

		move.w	#$ffff,bltbdat(a6)

		move.w	a1,d7
		mulu.w	d1,d7
		add.l	d7,a0
		move.w	d0,d7
		lsr.w	#4,d7
		add.w	d7,d7
		add.w	d7,a0
		move.l	a0,bltcpt(a6)
		move.l	#blitter_temp_output_word,bltdpt(a6)

		move.w	a1,bltcmod(a6)
		move.w	a1,bltdmod(a6)

		or.w	#BLTCON0F_USEA|BLTCON0F_USEC|BLTCON0F_USED|FILL_LINE_MINTERM,d2
		move.w	d2,bltcon0(a6)
		move.w	d6,bltcon1(a6)

		addq.w	#1,d4
		lsl.w	#6,d4
		addq.w	#2,d4
		move.w	d4,bltsize(a6)
		rts

cubism_octant_lookup
		dc.b	BLTCON1F_SUD					; octant 7
		dc.b	BLTCON1F_SUD|BLTCON1F_AUL		; octant 4
		dc.b	BLTCON1F_SUD|BLTCON1F_SUL		; octant 0
		dc.b	BLTCON1F_SUD|BLTCON1F_SUL|BLTCON1F_AUL ; octant 3
		dc.b	0								; octant 6
		dc.b	BLTCON1F_SUL					; octant 5
		dc.b	BLTCON1F_AUL					; octant 1
		dc.b	BLTCON1F_SUL|BLTCON1F_AUL		; octant 2

blitter_temp_output_word dc.w 0

		section	"cubism_data",data

* Precalced cube data for 512 frames.
* Header contains number of vertices,number of faces,each face with
* number of edges,"color id",edge 0-3,edge 0 (for completion).
* Each frame:
* - 8 3d coordinates a 3 words
* - 8 screen coordinates a 2 words
* - 6 normal vectors + cosines + 2d vector product
* Offset for framedata: can be interpreted
*        for 2d coords in each frame: 48 bytes
*        for normal vectors+cosines in frame: 80

FrontBackThisFrame: dc.l 0
cubism_sine256: incbin "../assets/sintab256.dat"
		even

cubism_animframe: dc.w $0

		include	"src/cubism_animation_script.i"

cubism_animation_starts: 
		dc.l	cubism_animation_script1,cubism_animation_script2
		dc.l	cubism_animation_script3,cubism_animation_script4
		dc.l	cubism_animation_script5,cubism_animation_script6

cubism_segment_types: 
		*		dc.l cubism_gold_glenzsegment
		dc.l	cubism_codersegment
		dc.l	cubism_spiralsegment
		dc.l	cubism_emptysegment
		dc.l	cubism_noisesegment
		dc.l	cubism_granny_blenksegment
		dc.l	cubism_purple_glenzsegment
		dc.l	cubism_crayola_blenksegment
		dc.l	cubism_gold_blenksegment
		*		dc.l	cubism_spiralsegment
		dc.l	cubism_purple_glenzsegment
		dc.l	cubism_crayola_blenksegment

* Current animation state table
cubism_current_segments: blk.l CUBISM_SEGMENTS*4,0
* Calculated xpositions
cubism_moving_pattern: blk.w 128,0
* Current animation script pointer
cubism_animation_scripts: blk.l CUBISM_SEGMENTS,0
* Counters for where we are in the spiral buffer (downwards)
cubism_spiral_positions: dc.w 0,0,0,0,0,0		* x and y positions (in sine offsets)
cubism_spiral_pos: dc.w 0,0						* byteoffset and scroll register
cubism_spiralptr: dc.l cubism_spiral
*cubism_colorintensities: dc.w	$002,$0f0f,$004,$0f00			* up to 12 faces at the same time (color id and intensity cosine)
cubism_blenkpalette: dc.l cubism_pal_purple
cubism_noisepalette: dc.l cubism_pal_grey
cubism_spiralpalette: dc.l cubism_pal_green
cubism_glenzpalette: dc.l cubism_pal_gold
												* each palette is 16 colors
cubism_pal_purple: dc.w $000,$101,$202,$303,$404,$505,$606,$707,$808,$909,$a0a,$b0b,$c0c,$d0d,$e0e,$f0f
cubism_pal_white: dc.w $000,$111,$222,$333,$444,$555,$666,$777,$888,$999,$aaa,$bbb,$ccc,$ddd,$eee,$fff
cubism_pal_grey: dc.w $000,$111,$222,$333,$444,$555,$666,$777,$888,$999,$aaa,$bbb,$cbb,$cbc,$ccc,$ccc
cubism_pal_blue: dc.w $0,$1,$2,$3,$4,$5,$6,$7,$8,$9,$a,$b,$c,$d,$e,$f
cubism_pal_green: dc.w $00,$10,$20,$30,$40,$50,$60,$70,$80,$90,$a0,$b0,$c0,$d0,$e0,$f0
cubism_pal_red: dc.w $0,$100,$200,$300,$400,$500,$600,$700,$800,$900,$a00,$b00,$c00,$d00,$e00,$f00
cubism_pal_gold: dc.w $0,$210,$310,$410,$420,$520,$530,$630,$730,$840,$940,$a50,$b60,$c70,$d80,$e90
cubism_pal_allblack: dc.w 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
cubism_pal_granny: dc.w 0,$010,$121,$232,$242,$353,$464,$575,$686,$797,$898,$8a8,$9b9,$aca,$bdb,$bfb
cubism_pal_peach: dc.w 0,$100,$211,$311,$421,$531,$642,$753,$864,$975,$a86,$b97,$ca8,$db9,$ec9,$fca
cubism_pal_crayola: dc.w 0,$110,$221,$332,$442,$553,$654,$765,$876,$987,$a97,$ba8,$cb8,$dc8,$ed9,$fe9

COL_CRAYOLA = $fe9
COL_PEACH = $fca
COL_GRANNY = $bfb
COL_BLACK = $000
COL_GOLD = $e90
COL_WHITE = $fff
COL_GREY = $ccc
COL_BLUE = $00f
COL_RED = $f00
COL_GREEN = $0f0
COL_PURPLE = $f0f

Script:	dc.l	0,0

		section	"cubism_chipdata",data_c

cubism_spiral: incbin "./assets/spiralbuffer.raw"

cubism_maincopper:
		dc.l	$008e2cc0,$00902c80			;window start,window stop,
		dc.l	$00920058,$009400b8				;bitplane start,bitplane stop
		dc.l	$01060c00,$01fc0000				;fixes the aga modulo problem
		dc.l	$01080016,$010a0016				;modulo odd planes,modulo even planes
		dc.l	$01000200,$01800000+CUBISM_BACKCOL
		dc.w	$008a,$0000						* copjmp2
		dc.l	$fffffffe

cubism_vars: dc.l $deadcafe

						rsreset

cubism_spacecutpoly: 	rs.l 1
cubism_altbuffer: 		rs.l 1
cubism_drawbuffer: 		rs.l 1
cubism_frontbuffer: 	rs.l 1
cubism_frontcopper: 	rs.l 1
cubism_backbuffer: 		rs.l 1
cubism_backcopper: 		rs.l 1
cubism_noiseptr: 		rs.l 1
cubism_chesslines: 		rs.l 1
cubism_coppreamble: 	rs.l 1
cubism_copseglen:		rs.l 1
cubism_xpostable:		rs.l 1
cubism_vars_SIZEOF: 	so
