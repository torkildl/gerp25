        incdir  include
        include hw.i
        include src/_main.i
        include src/endpart.i
        include common-timings.i

endpart_precalc:
        jsr     MemFlip
        ALLOC_CHIP 51200,titlepic_buf
        lea.l   titlepic_packed+4,a0
        move.l  titlepic_buf,a1
        jsr     lzodecrunch

        ALLOC_CHIP 8192,backcopper
        ALLOC_CHIP 8192,frontcopper
        move.l  backcopper,a0
        move.l  #-2,(a0)
        move.l  frontcopper,a0
        move.l  #-2,(a0)
        rts

endpart_effect:        
        jsr     SetBgTask
        jsr     MemFreeLast
        
        lea.l   Script,a0
        jsr     Commander_Init
        lea.l   custom,a6
        move.l  frontcopper,cop2lc(a6)
        lea.l   Maincop,a0
        move.l  a0,cop1lc(a6)

.mainloop
        jsr     UpdateFrame
        jsr     VSync
        jsr     PartOver
        blt     .mainloop
        rts


UpdateFrame:
        move.l  backcopper,a0
        move.l  frontcopper,d0
        move.w  #$0084,(a0)+
        swap    d0
        move.w  d0,(a0)+
        move.w  #$0086,(a0)+
        swap    d0
        move.w  d0,(a0)+

        move.l  current_palette,a1
        move.w  #31,d7
        move.w  #$0180,d0
.newcol
        move.w  d0,(a0)+
        move.w  (a1)+,(a0)+
        addq    #2,d0
        dbf     d7,.newcol

        move.w  #$00e0,d0
        move.l  titlepic_buf,d1
        rept    5
        move.w  d0,(a0)+
        addq.l  #2,d0
        swap    d1
        move.w  d1,(a0)+
        move.w  d0,(a0)+
        addq.l  #2,d0
        swap    d1
        move.w  d1,(a0)+
        add.l   #40,d1
        endr
        move.l  #$01005200,(a0)+
        move.l  #-2,(a0)+

        move.l  backcopper,d0
        move.l  frontcopper,backcopper
        move.l  d0,frontcopper
        rts

        include "decruncher.asm"

        section regular, data

backcopper: dc.l 0
frontcopper: dc.l 0

fadeout: dc.w   0
scrolltext:
        incbin  "assets/scrolltext.txt"
        even

titlepic_packed: incbin "assets/titlepic.raw.cr"
titlepic_palette: incbin "assets/titlepic.palette"

titlepic_buf: dc.l 0
current_palette: dc.l blackpalette
whitepalette: blk.w 32,$fff
blackpalette: blk.w 32,$000
twistpalette: blk.w 32,GFXTWIST_BACKCOL


Script: 
        dc.l    1,CmdLerpPal,32-1,6,twistpalette,titlepic_palette,current_palette
        dc.l    200,CmdLerpPal,32-1,7,titlepic_palette,blackpalette,current_palette
        dc.l    0,0

scrollermap:
font:   incbin  "assets/reorderedfont.raw"

        section chipdata,data_c

Maincop:
        dc.w    $008e,$2c71,$0090,$2cd1,$0092,$0038,$0094,$00d0
        dc.w    $0180,$0000,$0100,$5200,$0102,$0000
        dc.w    $010a,40*4,$0108,40*4
        dc.w    copjmp2,$0000
        dc.l    -2




