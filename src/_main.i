		incdir	"src"
		incdir	"include"

		include	"hw.i"
		include	"debug.i"

		; common
		include	"src/tables.i"
		include	"src/memory.i"
		include	"src/macros.i"
		include	"src/commander.i"
		include	"src/transitions.i"

		xdef	_start

		xdef	WaitEOF
		xdef	WaitBlitter
		xdef	WaitRaster
		xdef	BlankBg
		xdef	BlankCop
		xdef	MainUSP
		xdef	GlobalFrame
		xdef	LocalFrame

		xdef	PartOver

		xdef	VSync
		xdef	VSyncWithBgTask
		xdef	SetBgTask
		xdef	CmdSetBgTask
		xdef	EmptyBgTask
		xdef	Random32

		xdef	VBlankInterrupt
		xdef	BlitterInterrupt
		xdef	SoftInt

		xdef	BlankData
		xdef	FillData


BPM = 125
