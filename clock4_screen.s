
#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' ('CLOCK SCREEN 4') 6-channel (2AY) music only!  
#   BY VLADIMIR 'KUVO' KUTYAKOV/CSI
#   
#   PLATFORM:       BK-0011M
#   COMPILER:       PDPy11
#-------------------------------------------------------------------------------
           .nolist

           .include "hwdefs.s"
           .include "macros.s"
           .include "defs.s"
           .include "clock_defs.s"

           .global start

           .org ClockScreenStart

start:
START_CLOCK:
        TST $0
        BNE CLOCK_OPER
        INC .-4

        MOV $FB0, R0
        MOV $CLOCK_GFX, R1
        MOV $CLOCK_SCR_HEIGHT, R2
        3$:
            MOV $CLOCK_SCR_WIDTH_WORDS, R3
            4$:
                MOV (R1)+, (R0)+
            SOB R3, 4$
            ADD $LINE_WIDTHB - CLOCK_SCR_WIDTH_BYTES, R0
        SOB R2, 3$
 
    CLOCK_OPER:
        CALL NEXT_CLOCK_OPER
        RETURN

NEXT_CLOCK_OPER:
        WAIT
        ADD $040000, $0
        BCC 3$

        MOV $DIGITS_SET, R5
        MOV R5, R4
        INC (R5)
        CMP (R5), $10
        BLO 10$

        CLR (R5)+
        INC (R5)
        CMP (R5), $6
        BLO 10$

        CLR (R5)+
        INC (R5)

        CMP (R5), $4
        BLO 10$

        CMP 2(R5), $2
        BEQ 100$ 

        CMP (R5), $10
        BLO 10$

   100$:CLR (R5)+
        INC (R5)
        CMP (R5), $3
        BLO 10$

        CLR (R5)
    10$:MOV $DIGITS_LOCATION, R5
        MOV $4, R3
        1$:
            MOV (R4)+, R2
            SWAB R2
            ASR R2
            ASR R2
            MOV R2, R1
            ASR R2
            ADD R2, R1
            ADD $DIGITS_GFX, R1
            MOV (R5)+, R0
            MOV $24, R2
            2$:
                MOV (R1)+, (R0)+
                MOV (R1)+, (R0)+
                ADD $LINE_WIDTHB - 4, R0
            SOB R2, 2$
        SOB R3, 1$  
    3$: RETURN
        

DIGITS_SET:
        .word 0
        .word 5
        .word 2
        .word 1

DIGITS_LOCATION:
        .word FB0 + (128 >> 2) + (81*LINE_WIDTHB)
        .word FB0 + (104 >> 2) + (81*LINE_WIDTHB)
        .word FB0 + ( 72 >> 2) + (81*LINE_WIDTHB)
        .word FB0 + ( 48 >> 2) + (81*LINE_WIDTHB)

clock4_palette: #---------------------------------------------------------------
    .word      0, setCursorScalePalette, cursorGraphic, scale320 | RGb
    .word      1, setColors; .byte Black, brRed, brGreen, brCyan
    .word     83, setColors; .byte Black, brRed, brRed, brCyan
    .word    104, setColors; .byte Black, brRed, brGreen, brCyan
    .word    184, setCursorScalePalette, cursorGraphic, scale320 | RGB
    .word    236, setCursorScalePalette, cursorGraphic, scale320 | rGb
    .word untilEndOfScreen
#-------------------------------------------------------------------------------

DIGITS_GFX:
        .incbin "build/clock4/digits.raw"

CLOCK_GFX:
        .incbin "build/clock4/clock4.raw"
