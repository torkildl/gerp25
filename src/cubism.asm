CUBISM_BPLWIDTH = (192*2)+16
CUBISM_BPLHEIGHT = 192
CUBISM_BPLSIZE = ((CUBISM_BPLWIDTH/8)*CUBISM_BPLHEIGHT)
CUBISM_BPLDEPTH = 4
CUBISM_SCREEN_SIZE = CUBISM_BPLSIZE*CUBISM_BPLDEPTH
CUBISM_DRAWBUFFER_SIZE = 192*CUBISM_BPLHEIGHT*2/8

CUBISM_COPPER_SIZE = 1024
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

CUBISM_SPIRAL_YSPD = 3

		incdir	"include"
		include	"hw.i
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

		* frontbuffer bplptrs to frontcopper
		swap	d2
		move.l	#$00e00000,d0
		move.w	d2,d0
		rept	4
		move.l	d0,(a0)+
		add.l	#$00040000,d0
		endr									4

		* backbuffer bplptrs to backcopper
		swap	d3
		move.l	#$00e00000,d0
		move.w	d3,d0
		rept	4
		move.l	d0,(a1)+
		add.l	#$00040000,d0
		endr									4

		move.l	a0,d0
		sub.l	a3,d0				* offset for segments in copperlist
		move.l	d0,cubism_coppreamble(a5)

y set CUBISM_START_Y

		rept	6
			move.l	a0,d0
			move.b	#y,(a0)+		* HRIGHT WAIT
			move.b	#y,(a1)+
			move.b	#$b5,(a0)+
			move.b	#$b5,(a1)+
			move.w	#$fffe,(a0)+
			move.w	#$fffe,(a1)+
			* set bplptrs for 4 bpls
			move.l	#$01002200,(a0)+
			move.l	#$01002200,(a1)+
			move.l	#$01020000,(a0)+
			move.l	#$01020000,(a1)+
			move.l	#$00e20000,(a0)+
			move.l	#$00e20000,(a1)+
			move.l	#$00e60000,(a0)+
			move.l	#$00e60000,(a1)+
			move.l	#$00ea0000,(a0)+
			move.l	#$00ea0000,(a1)+
			move.l	#$00ee0000,(a0)+
			move.l	#$00ee0000,(a1)+
			move.l	#$01800000+CUBISM_BACKCOL,(a0)+
			move.l	#$01800000+CUBISM_BACKCOL,(a1)+
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
			move.b	#$8f,(a0)+			* HLEFT wait
			move.b	#$8f,(a1)+
			move.w	#$fffe,(a0)+
			move.w	#$fffe,(a1)+

			rept	31
			move.b	#y,(a0)+		* HRIGHT WAIT
			move.b	#y,(a1)+
			move.b	#$b5,(a0)+
			move.b	#$b5,(a1)+
			move.w	#$fffe,(a0)+
			move.w	#$fffe,(a1)+
y set y+1
			move.b	#y,(a0)+		* HRIGHT WAIT
			move.b	#y,(a1)+
			move.b	#$8f,(a0)+			* HLEFT wait
			move.b	#$8f,(a1)+
			move.w	#$fffe,(a0)+
			move.w	#$fffe,(a1)+
			endr
			move.l 	a0,d1
		endr
		sub.l	d0,d1
		move.l	d1,cubism_copseglen(a5)
		* end copperlists
		move.l	#-2,(a0)
		move.l	#-2,(a1)


		ALLOC_CHIP CUBISM_DRAWBUFFER_SIZE,cubism_drawbuffer(a5)

		ALLOC_CHIP CUBISM_SEGBPLSIZE*2,cubism_noiseptr(a5)
	
		bsr		cubism_initanimation
		bsr		cubism_preparenoise
		rts

Cubism_Effect:
		jsr		SetBgTask
		jsr		MemFreeLast						* free memory reserved be previous effect (in the other mem direction)

		move.l	cubism_frontbuffer(a5),a0
		WAIT_BLIT
		move.l	#$01000000,bltcon0(a6)
		move.l	a0,bltdpt(a6)
		clr.w	bltdmod(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#(CUBISM_BPLHEIGHT*3*64)+(CUBISM_BPLWIDTH/16),bltsize(a6)

		move.l	cubism_backbuffer(a5),a0
		WAIT_BLIT
		move.l	#$01000000,bltcon0(a6)
		move.l	a0,bltdpt(a6)
		clr.w	bltdmod(a6)
		move.l	#-1,bltafwm(a6)
		move.w	#(CUBISM_BPLHEIGHT*3*64)+(CUBISM_BPLWIDTH/16),bltsize(a6)
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
		moveq	#0,d1							* lets start at the top of the bitplane
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




* produce noise segment: input d0 = current screen vpos,d1 = segment screen address,d2 = offsets for bplptr/bplcon1,a0 = copperlist,a1 = segment list
cubism_emptysegment:
		bra		cubism_blenksegment
		move.l	#$01000200,(a0)+				* set number of bitplanes from start
		move.l	#$01800000+CUBISM_BACKCOL,(a0)+	* set background color
		rts

cubism_glenzsegment:
		bra		cubism_blenksegment
		* d1 = current bplptr for first bitplane
		move.l	#$01002200,(a0)+				* set number of bitplanes from start
		move.w	#$0102,(a0)+					* set scroll register
		move.w	d2,(a0)+						* ... to value supplied in d2

		add.w	d1,d5							* add screen address to d5:  now d5 contains screen address _and_ byteoffset for segment
		move.w	#$00e2,(a0)+					* first bplptr code
		move.w	d5,(a0)+
		add.w	#CUBISM_BPLSIZE,d5
		move.w	#$00e6,(a0)+					* first bplptr code
		move.w	d5,(a0)+

		move.l	#$01800000+CUBISM_BACKCOL,(a0)+	* set background color
		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4
		move.l	cubism_blenkpalette,a5

		move.w	#$182,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+

		move.w	#$184,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+

		move.w	#$186,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+
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
* Segment structure: WAIT (4), BPLCON0, BPLCON1, BPLPTR1-4, COL0, COL1-5
* 4 bytes per instruction
cubism_blenksegment:
		* d1 = current bplptr for first bitplane
		* a0 = start of copper segment
		move.w	#$2200,6(a0)					* after wait and $0100
		move.w	d2,10(a0)						* bplcon1
		add.w	d1,d5							* add screen address to d5:  now d5 contains screen address _and_ byteoffset for segment
		move.w	d5,14(a0)
		add.w	#CUBISM_BPLSIZE,d5
		move.w	d5,18(a0)

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4
		move.l	cubism_blenkpalette,a5

		*move.w	#$182,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),34(a0)

		*move.w	#$184,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),38(a0)

		*move.w	#$186,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),42(a0)
		rts

cubism_codersegment:
		bra cubism_blenksegment
		* d1 = current bplptr for first bitplane
		move.l	#$01002200,(a0)+				* set number of bitplanes from start
		move.w	#$0102,(a0)+					* set scroll register
		move.w	d2,(a0)+						* ... to value supplied in d2

		add.w	d1,d5							* add screen address to d5:  now d5 contains screen address _and_ byteoffset for segment
		move.w	#$00e2,(a0)+					* first bplptr code
		move.w	d5,(a0)+
		add.w	#CUBISM_BPLSIZE,d5
		move.w	#$00e6,(a0)+					* first bplptr code
		move.w	d5,(a0)+

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4

		move.l	#$01800000+CUBISM_BACKCOL,(a0)+	* set background color
		move.l	#cubism_pal_red,a5
		move.w	#$182,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+

		move.l	#cubism_pal_green,a5
		move.w	#$184,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+

		move.l	#cubism_pal_blue,a5
		move.w	#$186,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+
		rts


cubism_spiralsegment:
		bra cubism_spiralsegment
		* d1 = current bplptr for first bitplane
		move.l	#$01003200,(a0)+				* set number of bitplanes from start
		move.w	#$0102,(a0)+					* set scroll register
		move.w	d2,(a0)+						* ... to value supplied in d2

		add.w	d1,d5							* add screen address to d5:  now d5 contains screen address _and_ byteoffset for segment
		move.w	#$00e2,(a0)+					* first bplptr code
		move.w	d5,(a0)+
		add.w	#CUBISM_BPLSIZE,d5
		move.w	#$00e6,(a0)+					* first bplptr code
		move.w	d5,(a0)+

		move.l	cubism_spiralptr,d4				* address to pattern-screen area (animated later)
		move.w	#$00e8,(a0)+					* set high word bplptr code for spiral
		swap	d4
		move.w	d4,(a0)+
		swap	d4
		move.w	#$00ea,(a0)+
		move.w	d4,(a0)+						* set lower word of bplptr for spiral

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4
		move.l	cubism_spiralpalette,a5

		move.l	#$01800000+CUBISM_BACKCOL,(a0)+	* set background color
		move.l	#$01880000+CUBISM_BACKCOL,(a0)+	* color always black if not noise on top

		move.l	#cubism_pal_peach,a5
		move.w	#$182,(a0)+
		move.w	(a4),d4							* color id 1
		move.w	(a5,d4.w),(a0)+
		move.w	#$184,(a0)+
		move.w	2(a4),d4						* color id 2
		move.w	(a5,d4.w),(a0)+
		move.w	#$186,(a0)+
		move.w	4(a4),d4						* color id 3
		move.w	(a5,d4.w),(a0)+

		move.l	#cubism_pal_granny,a5
		move.w	#$18a,(a0)+
		move.w	(a4),d4							* color id 1
		move.w	(a5,d4.w),(a0)+
		move.w	#$18c,(a0)+
		move.w	2(a4),d4						* color id 2
		move.w	(a5,d4.w),(a0)+
		move.w	#$18e,(a0)+
		move.w	4(a4),d4						* color id 3
		move.w	(a5,d4.w),(a0)+
		rts

cubism_noisesegment:
		bra cubism_blenksegment
		* d1 = current bplptr for first bitplane
		move.l	#$01003200,(a0)+				* set number of bitplanes from start
		move.w	#$0102,(a0)+					* set scroll register
		move.w	d2,(a0)+						* ... to value supplied in d2

		add.w	d1,d5							* add screen address to d5:  now d5 contains screen address _and_ byteoffset for segment
		move.w	#$00e2,(a0)+					* first bplptr code
		move.w	d5,(a0)+
		add.w	#CUBISM_BPLSIZE,d5
		move.w	#$00e6,(a0)+					* first bplptr code
		move.w	d5,(a0)+

		move.l	cubism_vars,a5
		move.l	d0,d6							* save as the Random32 
		jsr		Random32
		and.l	#$3ff,d0
		add.l	cubism_noiseptr(a5),d0			* switch noise buffers
		move.w	#$00ea,(a0)+
		move.w	d0,(a0)+
		swap	d0
		move.w	#$00e8,(a0)+
		move.w	d0,(a0)+
		move.l	d6,d0							* restore d0

		move.l	FrontBackThisFrame,a4
		lea.l	2(a4),a4
		move.l	cubism_noisepalette,a5

		move.l	#$01800000+CUBISM_BACKCOL,(a0)+	* set background color
		move.l	#$01820000,(a0)+				* color always black if not noise on top
		move.l	#$01840000,(a0)+				* color always black if not noise on top
		move.l	#$01860000,(a0)+				* color always black if not noise on top
		move.l	#$01880000+CUBISM_BACKCOL,(a0)+	* color always black if not noise on top

		move.w	#$18a,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+

		move.w	#$18c,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+

		move.w	#$18e,(a0)+
		move.w	(a4)+,d4						* color id
		move.w	(a5,d4.w),(a0)+

		rts



cubism_initanimation:
		* prepare table of xpositions,with byte offsets and scroll registers for moving in and moving out
		lea.l	cubism_moving_pattern,a1
		lea.l	cubism_sine256,a2
		move.w	#$40,d7							* $40 values
		moveq	#0,d0							* start with zero
		move.w	#$80,d3							* maximum is $80
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

		* convert current xpos to byteoffset and scroll
		lea.l	cubism_moving_pattern,a2
		move.w	CUBISM_SEG_XPOS(a1),d2
		and.w	#$7e,d2
		move.w	(a2,d2.w),d4					* xpos in pixels

		move.w	d4,d3							* save xpos for later

		lsr.w	#4,d4							*	get bytes from pixels
		add.w	d4,d4							* word align ** now offset to be added to bplptrs
		sub.w	#2,d4

		and.w	#$f,d3							* the scroll value
		move.w	#16,d2
		sub.w	d3,d2
		and.w	#$f,d2							* if no bits are set,we don't need to scroll
		tst.w	d2								* do we scroll?
		beq.s	.noscroll

		move.w	d2,d3							* copy scroll reg value
		lsl.l	#4,d3							* move 4 bits higher for next playfield
		or.w	d3,d2							* combine playfields scroll register input
		addq	#2,d4							* subtract two bytes (one word) from bplptrs,for scrolling right

.noscroll
		move.w	d4,CUBISM_SEG_BYTEOFFSET(a1)	* set byteoffset (word aligned) for bplptrs
		move.w	d2,CUBISM_SEG_SCROLLREG(a1)		* set value for scroll register

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
		dc.l	$008e2cc1,$00902c81				;window start,window stop,
		dc.l	$00920050,$009400a8				;bitplane start,bitplane stop
		dc.l	$01060c00,$01fc0000				;fixes the aga modulo problem
		dc.l	$0108001a,$010a001a				;modulo odd planes,modulo even planes
		dc.l	$01000200,$01800000+CUBISM_BACKCOL
		dc.w	$008a,$0000						* copjmp2
		dc.l	$fffffffe

cubism_vars: dc.l $deadcafe

		rsreset
cubism_drawbuffer: 	rs.l 1
cubism_frontbuffer: rs.l 1
cubism_frontcopper: rs.l 1
cubism_backbuffer: 	rs.l 1
cubism_backcopper: 	rs.l 1
cubism_noiseptr: 	rs.l 1
cubism_coppreamble: 	rs.l 1
cubism_copseglen:	rs.l 1
cubism_vars_SIZEOF: so

