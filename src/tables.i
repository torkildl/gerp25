		ifnd	_TABLES_I
_TABLES_I set	1

		xdef	Tables_Precalc
		xdef	Sin
		xdef	Cos
		xdef	Sin2048
		xdef	ScreenMuls
		xdef	Init

		xdef	Cubeframe
		xdef	CubeCorners
		xdef	CubeFaces
		xdef	FrontBackColor
		xdef	RotatedUnitVectors
		xdef	RotatedCubePoints3d
		xdef	RotatedCubePoints2d

CUBE_FRAMES = 512
CUBE_VERTICES = 8

XANGLE = 0
YANGLE = 2
ZANGLE = 4

FRAMIAN = 2048/CUBE_FRAMES						* for 256 frames,8 notches per frame is full rotation

XROT = 1*FRAMIAN								* takes 1024/2 frames to go full circle
YROT = -FRAMIAN									* takes 1024/3 frames to go full circle
ZROT = 1*FRAMIAN


		endc
