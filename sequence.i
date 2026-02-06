		include	src/gfxtwist.i
		include	src/truchet.i
		include	src/gfxtwist.i
		include	src/wallcube.i
		include	src/endpart.i


TEST_PART = 4

Pos		set		0
PART	macro
		dc.l	\1								; precalc
		dc.l	\2								; effect
Pos		set		Pos+\3
		dc.w	Pos
		endm

		rsreset
Part_Pre rs.l	1
Part_Effect rs.l 1
Part_Length rs.w 1
Part_SIZEOF rs.b 0

********************************************************************************
		dc.l	0,0
Sequence:
		PART	Wallcube_Precalc,Wallcube_Effect,4
		PART	truchet_precalc,truchet_effect,5
		PART	FaceTwist_Precalc,FaceTwist_Effect,8
		PART	endpart_precalc,endpart_effect,4
		PART	Cubism_Precalc, Cubism_Effect,10
SequenceEnd
		dc.l	0,0								*if align is needed
