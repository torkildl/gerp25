		include	src/_main.i
		include	src/tables.i

********************************************************************************
Tables_Precalc:
		bsr		InitSin
		bsr		InitScreenMuls
		bsr		Precalculate_Cube
		rts

********************************************************************************
; Populate sin table
;-------------------------------------------------------------------------------
; https://eab.abime.net/showpost.php?p=1471651&postcount=24
; maxError = 26.86567%
; averageError = 8.483626%
;-------------------------------------------------------------------------------
EXTRA_ACC = 1
InitSin:
		lea		Sin,a0
		moveq	#0,d0							; amp=16384,len=1024
		move.w	#511+2,a1
.l
		subq.l	#2,a1
		move.l	d0,d1

		ifne	EXTRA_ACC
		move.w	d1,d2
		neg.w	d2
		mulu.w	d1,d2
		divu.w	#74504/2,d2						; 74504=amp/scale
		lsr.w	#2+1,d2
		sub.w	d2,d1
		endc

		asr.l	#2,d1
		move.w	d1,(a0)+
		neg.w	d1
		move.w	d1,(1024-2,a0)
		add.l	a1,d0
		bne.b	.l

; Copy extra 90 deg for cosine
		lea		Sin,a0
		lea		Sin+1024*2,a1
		move.w	#256/2,d0
.copy
		move.l	(a0)+,(a1)+
		dbf		d0,.copy

		rts


********************************************************************************
* d0 is screen width in bytes
MAX_SCREEN_H = 288
InitScreenMuls:
		lea		ScreenMuls,a0
		moveq	#0,d1
		move.w	#MAX_SCREEN_H-1,d7
.l		move.w	d1,(a0)+
		add.w	d0,d1
		dbf		d7,.l
		rts


* fade routine / palette generator
; Input:
;   D0.W - Color A (start color,0xRGB format)
;   D1.W - Color B (end color,0xRGB format)
;   A0.L - Pointer to output memory (16 words)

FADE_COLORS_16:
		move.w	d0,d4							; Extract starting color (A)
		move.w	d1,d5							; Extract ending color (B)

; Extract and separate RGB components of Color A
		move.w	d4,d6							; Copy Color A into D6
		andi.w	#$f00,d6						; Extract Red (R_start)
		lsr.w	#8,d6							; Shift into lower nibble

		move.w	d4,d7							; Copy Color A into D7
		andi.w	#$0f0,d7						; Extract Green (G_start)
		lsr.w	#4,d7							; Shift into lower nibble

		andi.w	#$00f,d4						; Extract Blue (B_start) (D4 holds B_start)

; Extract and separate RGB components of Color B
		move.w	d5,d2							; Copy Color B into D2
		andi.w	#$f00,d2						; Extract Red (R_end)
		lsr.w	#8,d2							; Shift into lower nibble

		move.w	d5,d3							; Copy Color B into D3
		andi.w	#$0f0,d3						; Extract Green (G_end)
		lsr.w	#4,d3							; Shift into lower nibble

		andi.w	#$00f,d5						; Extract Blue (B_end) (D5 holds B_end)

; Compute step increments for each channel
		sub.w	d6,d2							; R_delta = R_end - R_start
		moveq	#15,d1							; 16 steps: step count - 1
		divs.w	d1,d2							; R_step = R_delta / 15

		sub.w	d7,d3							; G_delta = G_end - G_start
		divs.w	d1,d3							; G_step = G_delta / 15

		sub.w	d4,d5							; B_delta = B_end - B_start
		divs.w	d1,d5							; B_step = B_delta / 15

; Loop to generate fade steps
		moveq	#16,d1							; Number of steps
FADE_LOOP:
		move.w	d6,d0							; Start with current R
		lsl.w	#8,d0							; Shift Red into position
		or.w	d7,d0							; Add current G
		lsl.w	#4,d0							; Shift Green into position
		or.w	d4,d0							; Add current B
		move.w	d0,(a0)+						; Store color to memory

		add.w	d2,d6							; Increment R
		add.w	d3,d7							; Increment G
		add.w	d5,d4							; Increment B

		subq.w	#1,d1							; Decrement steps
		bne.s	FADE_LOOP						; Repeat if steps remain

		rts

***
*** Main Precalculation routine
*** Loops over frames,and generates
*** - rotated unit vectors
*** - rotated 3d points

* TODO:
* add perspective projection to 2d points,and centering on a 192x192 large screen
* add hidden face removal precalc
* add line lists for drawing
* add chessboard lines y-clipped

Precalculate_Cube:
.newframe
		bsr		RotateUnitVectors				
		bsr		GenerateRotatedCube

		lea.l	Angles,a0
		move.w	(a0),d0
		add.w	#XROT,d0
		move.w	d0,(a0)+

		move.w	(a0),d0
		add.w	#YROT,d0
		move.w	d0,(a0)+

		move.w	(a0),d0
		add.w	#ZROT,d0
		move.w	d0,(a0)+

		move.w	Cubeframe,d0
		addq	#1,d0
		move.w	d0,Cubeframe
		cmp.w	#CUBE_FRAMES,d0
		blt.s	.newframe

		bsr		ProjectPoints2d					* convert all rotated vertices to 2d
		bsr		CullFacesAllFrames				* determine visibility of faces over all faces, all frames			
		* lighting of faces here

		clr.w	Cubeframe
		rts


dist	equ		650
FocalLen equ	256								; F = 256 in 2^8 scale => 1.0 = 256
CenterX	equ		96								; screen center X
CenterY	equ		96								; screen center Y

ProjectPoints2d:
		lea.l	RotatedCubePoints3d,a0			; read 3D
		lea.l	RotatedCubePoints2d,a1			; write 2D
		move.w	#(CUBE_VERTICES*CUBE_FRAMES)-1,d7
.loopProj:
		; load one 3D vertex
		move.w	(a0)+,d0						; x
		move.w	(a0)+,d1						; y
		move.w	(a0)+,d2						; z

		; We'll compute:
		;   screenX = CenterX + (x * FocalLen) / (z + FocalLen)
		;   screenY = CenterY + (y * FocalLen) / (z + FocalLen)
		;
		; Everything is 16-bit 2's complement in registers,but
		; we do 32-bit multiply in d3/d4,then do a 16-bit integer divide.

		; 1) d6 = (z + FocalLen)
		move.w	d2,d6
		add.w	#dist,d6						; d6 = z + 256 (both in 2^8 scale)

		; ------------------
		; 2) screenX calculation
		; numerator = x * FocalLen => 2^8 * 2^8 = 2^16 scale => 32-bit product

		move.l	d0,d3							; sign-extend x into d3
		ext.l	d3
		move.w	#FocalLen,d4
		muls	d4,d3							; d3 = x * FocalLen in 2^16

		; Shift from 2^16 to 2^8 (so it matches denominator scale) before dividing
		*		asr.l	#8,d3

		; 16-bit signed divide by (z + FocalLen) in d6 (2^8 scale)
		divs.w	d6,d3							; result in d3.w => 2^0 (pixel integer)
    
		; screenX = CenterX + d3.w
		move.w	#CenterX,d0
		add.w	d3,d0

; ------------------
; 3) screenY calculation
		move.l	d1,d3
		ext.l	d3
		move.w	#FocalLen,d4
		muls	d4,d3
*		asr.l	#8,d3
		divs.w	d6,d3
		move.w	#CenterY,d1
		add.w	d3,d1

; store final 2D screen coords
		move.w	d0,(a1)+						; screenX
		move.w	d1,(a1)+						; screenY

		dbf		d7,.loopProj

		lea.l	RotatedCubePoints2d,a1			; write 2D
		move.w	#(CUBE_VERTICES*CUBE_FRAMES)-1,d7
		moveq	#0,d0
		moveq	#0,d1
		move	#192,d2							*minx
		move	#0,d3							*maxx
		move	#192,d4							*miny
		move	#0,d5							*maxy
.newv
		movem.w	(a1)+,d0-d1
		cmp.w	d0,d2
		blt.s	.notminx
		move.w	d0,d2
.notminx
		cmp.w	d0,d3
		bgt.s	.notmaxx
		move.w	d0,d3
.notmaxx
		cmp.w	d1,d4
		blt.s	.notminy
		move.w	d1,d4
.notminy
		cmp.w	d1,d5
		bgt.s	.notmaxy
		move.w	d1,d5
.notmaxy
		dbf		d7,.newv
		rts



RotateUnitVectors:
		lea.l	Angles,a0
		lea.l	Sin,a1
		lea.l	Cos,a2
		lea.l	UnitVectors,a3
		lea.l	RotatedUnitVectors,a4			; a2 -> rux_x,rux_y,rux_z
		move.w	Cubeframe,d0
		mulu	#9*2,d0							* size of unit vector table entry
		lea.l	(a4,d0.w),a4

		rept	3
		moveq	#0,d0
		moveq	#0,d1
		moveq	#0,d2
		move.w	(a3)+,d0						* x value
		move.w	(a3)+,d1						* y value
		move.w	(a3)+,d2						* z value

		* Rotate along X axis (pitch)
		move.w	XANGLE(a0),d7
		and.w	#$7fe,d7
		move.w	(a1,d7.w),d6					* sin(t)
		move.w	(a2,d7.w),d7					* cos(t)

		* x' = x
		* y' = y*cos0 - z*sin0
		* z' = y*sin0 + z*cos0

		move.w	d1,d3
		muls	d7,d3							* y*cos0
*		asr.l	#8,d3
		move.w	d2,d4
		muls	d6,d4							* z*sin0
*		asr.l	#8,d4
		sub.l	d4,d3							* y*cos0 - z*sin0
		asr.l	#8,d3
		asr.l	#6,d3
		
		move.w	d1,d5							* y
		muls	d6,d5							* y*sin0
*		asr.l	#8,d5
		move.w	d2,d4							* z
		muls	d7,d4							* z*cos0
*		asr.l	#8,d4
		add.l	d4,d5							* y*sin0 - z*cos0
		asr.l	#8,d5
		asr.l	#6,d5

		move.w	d3,d1
		move.w	d5,d2
		
		* Y rotation (yaw): 
		* x'' = x'*cos0 + z'*sin0
		* y'' = y'
		* z'' = -x'*sin0 + z'*cos0

		move.w	YANGLE(a0),d7
		and.w	#$7fe,d7
		move.w	(a1,d7.w),d6					* sin(t)
		move.w	(a2,d7.w),d7					* cos(t)

		move.w	d0,d3
		muls	d7,d3							* x*cos0
*		asr.l	#8,d3
		move.w	d2,d4
		muls	d6,d4							* z*sin0
*		asr.l	#8,d4
		add.l	d4,d3							* x'
		asr.l	#8,d3
		asr.l	#6,d3
		
		move.w	d0,d5							* x
		neg.w	d5								* -x
		muls	d6,d5							* -x*sin0
*		asr.l	#8,d5
		move.w	d2,d4							* z
		muls	d7,d4							* z*cos0
*		asr.l	#8,d4
		add.l	d4,d5							* z'
		asr.l	#8,d5
		asr.l	#6,d5

		move.w	d3,d0							* update x
		move.w	d5,d2							* update z

		* Z rotation (roll): 
		* x''' = x''*cos0 - y''*sin0
		* y''' = x''*sin0 + y''*cos0
		* z''' = z''

		move.w	ZANGLE(a0),d7
		and.w	#$7fe,d7
		move.w	(a1,d7.w),d6					* sin(t)
		move.w	(a2,d7.w),d7					* cos(t)

		move.w	d0,d3
		muls	d7,d3							* x*cos0
*		asr.l	#8,d3
		move.w	d1,d4
		muls	d6,d4							* y*sin0
*		asr.l	#8,d4
		sub.l	d4,d3							* x'
		asr.l	#8,d3
		asr.l	#6,d3
		
		move.w	d0,d5							* x
		muls	d6,d5							* x*sin0
*		asr.l	#8,d5
		move.w	d1,d4							* y
		muls	d7,d4							* y*cos0
*		asr.l	#8,d4
		add.l	d4,d5							* y'
		asr.l	#8,d5
		asr.l	#6,d5

		move.w	d3,d0							* update x
		move.w	d5,d1							* update z

		move.w	d0,(a4)+
		move.w	d1,(a4)+
		move.w	d2,(a4)+
		endr		
		
		rts

GenerateRotatedCube:
		lea.l	CubeCorners,a0					; a0 -> first corner (x,y,z)
		lea.l	RotatedCubePoints3d,a1			; a1 -> where we store results
		lea.l	RotatedUnitVectors,a2			; a2 -> rux_x,rux_y,rux_z

		move.w	Cubeframe,d0
		move.w	d0,d1
		mulu	#2*3*CUBE_VERTICES,d0			* frame * sizeof_cubepoints (2*3*8)
		lea.l	(a1,d0.w),a1
		mulu	#9*2,d1							* size of unit vector table entry * frame cnt
		lea.l	(a2,d1.w),a2					* a2 -> rux_x,rux_y,rux_z
		lea.l	6(a2),a3						; a3 -> ruy_x,ruy_y,ruy_z
		lea.l	6(a3),a4						; a4 -> ruz_x,ruz_y,ruz_z

		moveq	#CUBE_VERTICES-1,d7				; 8 corners to process -1 for counter

.newvertex:
; Load original corner (x,y,z) in 2^8 scale
		move.w	(a0)+,d0						; x
		move.w	(a0)+,d1						; y
		move.w	(a0)+,d2						; z

; ----------------------------------
; x' = x*rux_x + y*rux_y + z*rux_z
; We'll accumulate in a long register (d3).
; Each multiply is 16-bit * 16-bit => 32-bit in d3 or d4.

		move.w	(a2),d3							; rux_x
		muls	d0,d3							; x*rux_x
*		asr.l	#8,d3							; partial shift from 2^16 => 2^8

		move.w	(a3),d4							; rux_y
		muls	d1,d4							; y*rux_y
*		asr.l	#8,d4
		add.l	d4,d3

		move.w	(a4),d4							; rux_z
		muls	d2,d4							; z*rux_z
*		asr.l	#8,d4
		add.l	d4,d3
		asr.l	#8,d3

; d3 now holds x' in 2^8 scale => store in corner
		move.w	d3,(a1)+

; ----------------------------------
; y' = x*ruy_x + y*ruy_y + z*ruy_z
		move.w	2(a2),d3
		muls	d0,d3
*		asr.l	#8,d3

		move.w	2(a3),d4
		muls	d1,d4
*		asr.l	#8,d4
		add.l	d4,d3

		move.w	2(a4),d4
		muls	d2,d4
*		asr.l	#8,d4
		add.l	d4,d3
		asr.l	#8,d3

		move.w	d3,(a1)+

; ----------------------------------
; z' = x*ruz_x + y*ruz_y + z*ruz_z
		move.w	4(a2),d3
		muls	d0,d3
		asr.l	#8,d3

		move.w	4(a3),d4
		muls	d1,d4
		asr.l	#8,d4
		add.l	d4,d3

		move.w	4(a4),d4
		muls	d2,d4
		asr.l	#8,d4
		add.l	d4,d3

		move.w	d3,(a1)+

; ----------------------------------
; Decrement corner count and loop
		dbf		d7,.newvertex

		rts


*** Predict linelist for visible faces -- to be read by wallcube and cubism

; ---------------------------------------------------------
; Constants / definitions
; ---------------------------------------------------------
FACE_COUNT equ	6								; We have 6 faces total
; Each face has 9 words:
;   [0] = color
;   [1] = v1,[2] = v2,
;   [3] = v2,[4] = v3,
;   [5] = v3,[6] = v4,
;   [7] = v4,[8] = v1
; We only need words 1,2,4 => (v1,v2,v3) for the culling test.

; We'll assume:
;   Faces:   label or pointer to the 6 faces data
;   RotatedCubePoints2d: holds 2D coords for each vertex,
;                        as 16-bit x,16-bit y repeated.

; Face i starts at: Faces + i*(9*2) bytes = i*18 bytes

; We'll produce our result in a word "FaceVisibilityBits":
;   bit i = 1 => face i is visible

; ---------------------------------------------------------
; BackfaceCullCube:
;   Output: d0 => bits for faces 0..5
;   Also store in FaceVisibilityBits if you want.
; ---------------------------------------------------------


CullFacesAllFrames:

		lea.l	RotatedCubePoints2d,a1
		lea.l	FrontBackColor,a4
		clr.w	Cubeframe

.frame
		bsr		BackfaceCullCube				* Cull all six faces
		add.w	#1,Cubeframe
		adda.l	#CUBE_VERTICES*2*2,a1
		adda.l	#8,a4
		cmp.w	#CUBE_FRAMES,Cubeframe
		bne.s	.frame
		rts

BackfaceCullCube:
		move.l	#CubeFaces,a0
		clr.w	(a4)
		move.w	#FACE_COUNT-1,d7				; we do 6 faces => from 5 down to 0

.bf_loop:

		move.w	2(a0),d0						; v1 index
		move.w	4(a0),d2						; v2 index
		move.w	8(a0),d4						; v3 index
    
; v1 

		move.w	d0,d1
		lsl.w	#2,d1
		move.w	(a1,d1.w),d0					; x1
		move.w	2(a1,d1.w),d1					; y1
    
; v2 => offset
		move.w	d2,d3
		lsl.w	#2,d3
		move.w	(a1,d3.w),d2					; x2
		move.w	2(a1,d3.w),d3					; y2
  
; v3 => offset
		move.w	d4,d5
		lsl.w	#2,d5
		move.w	(a1,d5.w),a2					; x3
		move.w	2(a1,d5.w),a3					; y3
    
; *** 4) compute cross = (x2 - x1)*(y3 - y1) - (y2 - y1)*(x3 - x1)
; We'll do 16-bit arithmetic,so be mindful of sign extension
; We stored x3 in a2.w,y3 in a3.w

		move.w	d2,d5
		sub.w	d0,d5							* x2-x1
		move.w	a3,d4
		sub.w	d1,d4							* y3-y1
		muls	d5,d4							* (x2-x1*)*(y3-y1)

		move.w	d3,d6
		sub.w	d1,d6							* (y2-y1)
		move.w	a2,d2
		sub.w	d0,d2							* (x3-x1)
		muls	d2,d6							* (y2-y1)*(x3-x1)

		sub.l	d6,d4							* final cross

; *** 5) check sign => if cross < 0 => visible
; We'll look at d4.l sign bit. If negative => set bit in 1(a4)
		add.l	#80,d4
		tst.l	d4
		bge.s	.bf_not_visible

		bset	d7,1(a4)						*keep word alignment
		asr.l	#8,d4
		neg.w	d4
		lsr.w	#2,d4
		cmp.w	#15,d4
		blt.s	.okcol
		move.w	#15,d4
.okcol
		move.w	(a0),d0
		add.w	d0,d0
		add.w	d4,d4
		move.w	d4,(a4,d0.w)					* register intensity for this color.


.bf_not_visible:
; *** 6) Next face
		adda.l	#18,a0
		dbf		d7,.bf_loop
    
; 		* this is used for debugging:
; 		move.w	(a4),d0

; 		move.w	d0,d1
; 		and.w	#%1,d1
; 		move.w	d0,d2
; 		and.w	#%10,d2
; 		lsr.w	#1,d2
; 		move.w	d0,d3
; 		and.w	#%100,d3
; 		lsr.w	#2,d3
; 		move.w	d0,d4
; 		and.w	#%1000,d4
; 		lsr.w	#3,d4
; 		move.w	d0,d5
; 		and.w	#%10000,d5
; 		lsr.w	#4,d5
; 		move.w	d0,d6
; 		and.w	#%100000,d6
; 		lsr.w	#5,d6

; 		add.w	d6,d5
; 		add.w	d5,d4
; 		add.w	d4,d3
; 		add.w	d3,d2
; 		add.w	d2,d1
; 		cmp.w	#3,d1
; 		ble		.noerror

; 		move.w	Cubeframe,d2
; .noerror
		rts




		section	precalc,data

		even

Cubeframe dc.w	0								* frame counter,also used in effects

Angles:	dc.w	0,0,0							* x,y,z 2pi = 2048 * current angle buffer
UnitVectors										* Unit vectors
		dc.w	256,0,0							* unit x
		dc.w	0,256,0							* unit y
		dc.w	0,0,256							* unit z

; Cube corners (centered at origin,side length = 256 in real coords).
; Each corner is (±128,±128,±128) in 2^8 scale,i.e. ±0.5 in float terms.
CubeCorners:
		dc.w	$80, $80, $80					; (+128,+128,+128)
		dc.w	$80, $80,-$80					; (+128,+128,-128)
		dc.w	$80,-$80, $80					; (+128,-128,+128)
		dc.w	$80,-$80,-$80					; (+128,-128,-128)
		dc.w	-$80, $80, $80					; (-128,+128,+128)
		dc.w	-$80, $80,-$80					; (-128,+128,-128)
		dc.w	-$80,-$80, $80					; (-128,-128,+128)
		dc.w	-$80,-$80,-$80					; (-128,-128,-128)

		; Face data: color,(v1,v2),(v2,v3),(v3,v4),(v4,v1)
		; Opposite faces share same color.
CubeFaces:
		; FRONT (z=+128),color=0
		dc.w	1,4,6,6,2,2,0,0,4
		; BACK (z=-128),color=0
		dc.w	1,5,1,1,3,3,7,7,5
		; LEFT (x=-128),color=1
		dc.w	2,4,5,5,7,7,6,6,4
		; RIGHT (x=+128),color=1
		dc.w	2,0,2,2,3,3,1,1,0
		; TOP (y=+128),color=2
		dc.w	3,4,0,0,1,1,5,5,4
		; BOTTOM (y=-128),color=2
		dc.w	3,6,7,7,3,3,2,2,6

RotatedUnitVectors: blk.w 3*3*CUBE_FRAMES		* 3 words,3 unit vectors,256 frames
RotatedCubePoints3d: blk.w 3*CUBE_VERTICES*CUBE_FRAMES * 3 words,8 vertices,256 frames
		dc.b	"DEADCAFE"
RotatedCubePoints2d: blk.w 2*CUBE_VERTICES*CUBE_FRAMES * 2 words,8 vertices,256 frames
		dc.b	"CAFEDEAD"
FrontBackColor: ds.w 4*CUBE_FRAMES				* binary code for indicating whether the face is front 0 or back 1

	printt "PRECALC SIZE:"
	printv Sin2048-Cubeframe

Sin2048: incbin	"assets/sintab.dat"

*******************************************************************************
		bss
*******************************************************************************
		section	precalcdata,bss


; FP 2/14
; +-16384
; ($c000-$4000) over 1024 ($400) steps
Sin:	ds.w	256
Cos:	ds.w	1024

ScreenMuls: ds.w MAX_SCREEN_H

