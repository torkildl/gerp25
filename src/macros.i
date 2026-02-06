
WAIT_BLIT macro
        tst.w   dmaconr(a6)                     ;for compatibility with A1000
.\@:    btst    #DMAB_BLTDONE,dmaconr(a6)
        bne.s   .\@
        endm


BLIT_HOG macro
        move.w  #DMAF_SETCLR!DMAF_BLITHOG,dmacon(a6)
        endm

BLIT_UNHOG macro
        move.w  #DMAF_BLITHOG,dmacon(a6)
        endm



********************************************************************************
; Test macro -- lmb to continue
;-------------------------------------------------------------------------------
THLTEST macro
.\@:    move.w  #$f77,color00+custom
        btst    #6,$bfe001
        bne.s   .lmb
        endm


BLANKSPRITE macro 
        dc.w    $1905,$1a00                     ;1px high sprite in the top-leftmost valid position
        dc.w    0,0                             ;blank pixel data
        dc.w    0,0                             ;standard end of chain control word pair.
        endm
        
FOREVERWAIT macro 
        inline
.wait   btst    #6,$bfe001
        bne.s   .wait
        einline
        endm
        
FOREVERWAITCOL macro 
        inline
.wait   move.w  #\1,$dff180
        btst    #6,$bfe001
        bne.s   .wait
        einline
        endm
        
        
LEFTMOUSEWAIT macro 
.\@     btst.b  #6,$bfe001
        bne.s   .\@
        endm


LEFTCLICKWAIT macro 
.\@     btst.b  #6,$bfe001
        bne.s   .\@
.\@2    btst.b  #6,$bfe001
        beq.s   .\@2
        endm

********************************************************************************
; Fixed point to integer (15)
; \1 - Fixed point value (mutated)
;-------------------------------------------------------------------------------
FP2I    macro
        add.l   \1,\1
        swap    \1
        endm


********************************************************************************
FPMULS  macro
;-------------------------------------------------------------------------------
        muls.w  \1,\2
        FP2I    \2
        endm


********************************************************************************
FPMULU  macro
;-------------------------------------------------------------------------------
        mulu.w  \1,\2
        FP2I    \2
        endm


********************************************************************************
; Copper
********************************************************************************

COP_MOVE: macro
        dc.w    (\2)&$1fe,\1
        endm

COP_WAIT: macro
        dc.w    (((\1)&$ff)<<8)+((\2)&$fe)+1,$fffe
        endm

COP_WAITV: macro
        COP_WAIT \1&$ff,4
        endm

COP_WAITH: macro
        dc.w    ((\1&$80)<<8)+(\2&$fe)+1,$80fe
        endm

COP_WAITBLIT: macro
        dc.l    $10000
        endm

COP_SKIP: macro
        dc.w    (((\1)&$ff)<<8)+((\2)&$fe)+1,$ffff
        endm

COP_SKIPV: macro
        COP_SKIP \1,4
        endm

COP_SKIPH: macro
        dc.w    (((\1)&$80)<<8)+((\2)&$fe)+1,$80ff
        endm

COP_NOP: macro
        COP_MOVE 0,$1fe
        endm

COP_END: macro
        dc.l    $fffffffe
        endm

; Copper blitter queue:

COPQ_WAITBLIT macro
        move.l  #$10000,(a0)+
        endm

COPQ_END macro
        move.l  #-2,(a0)+
        endm

COPQ_MOVEI macro
        move.l  #(\2<<16)!\1,(a0)+
        endm

COPQ_MOVEW macro
        move.w  #\2,(a0)+
        move.w  \1,(a0)+
        endm

COPQ_NOP macro
        move.l  #$1fe<<16,(a0)+
        endm
