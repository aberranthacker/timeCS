# vim: set tabstop=4 :


#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' ('CLOCK SCREEN 1') 6-channel (2AY) music only!  
#   BY VLADIMIR 'KUVO' KUTYAKOV/CSI
#   
#   PLATFORM:       BK-0011M
#   COMPILER:       PDPy11
#-------------------------------------------------------------------------------
        MAKE_RAW 'CLOCK1_SCREEN.RAW'

        .org 020000

        ACTUAL_PAGES = 01014  #SEE PLAYER.MAC

START_CLOCK:

        MOV @$ACTUAL_PAGES, ACTUAL_PAGES_STORE

        TRAP 0; .word 04400
        MOV $CLOCK_GFX, R5

        TST $0
        BNE 2$
        MOV PC, .-4

        MOV $0100000, R0
        MOV R5, R1
        ADD (R5), R1
        MOV $184, R2
    10$:MOV $192 >> 3, R3
    1$: MOV (R1)+, (R0)+
        SOB R3, 1$
        ADD $0100 - 192 >> 2, R0
        SOB R2, 10$

    2$:
        CALL NEXT_CLOCK_OPER
        MOV (PC)+, R0
    ACTUAL_PAGES_STORE: .word 0     
        MOV R0, @$ACTUAL_PAGES
        MOV R0, @$0177716
RETURN

NEXT_CLOCK_OPER:

    NUMBERS_OPERS:
        ADD $040, $0
        BCC DIGITS2_OPERS

        MOV (PC)+, R1
    NUMBERS_IDX:    .word 0
        ADD $0140, R1
        CMP R1, $0140 * 4
        BLO 10$
        CLR R1
    10$:    MOV R1, NUMBERS_IDX
        ADD 6(R5), R1
        ADD R5, R1
        MOV $016, R2
        MOV $6, R3
        MOV $0100000 + (96 >> 2) + (124*64), R0
        CALL DISPLAY_GFX

    DIGITS2_OPERS:

        ADD $020000, $0
        BCS 10$
RETURN

    10$:    MOV $0100000 + (96 >> 2) + (96*64), R0
        MOV $DIGITS2_1_IDX, R1
        CALL DIGITS2_CALC
        TST (R1)
        BNE 1$
        CALL DISPLAY_DIGITS2
        MOV $0100000 + (84 >> 2) + (99*64), R0
        MOV $DIGITS2_2_IDX, R1
        CALL DIGITS2_CALC
    1$: CALL DISPLAY_DIGITS2


    DIGITS1_OPERS:

        TST DIGITS2_1_IDX
        BNE LEFT_INDICATOR_OPERS
        TST DIGITS2_2_IDX
        BNE LEFT_INDICATOR_OPERS

        MOV $0100000 + (136 >> 2) + (42*64), R0
        MOV $DIGITS1_1_IDX, R1
        CALL DIGITS1_9_CALC
        TST (R1)
        BNE 1$
        CALL DISPLAY_DIGITS1
        MOV $0100000 + (100 >> 2) + (52*64), R0
        MOV $DIGITS1_2_IDX, R1
        CALL DIGITS1_5_CALC
        TST (R1)
        BNE 1$
        CALL DISPLAY_DIGITS1
        MOV $0100000 + (64 >> 2) + (62*64), R0
        MOV $DIGITS1_3_IDX, R1
        CALL DIGITS1_3_CALC
        TST (R1)
        BNE 1$
        CALL DISPLAY_DIGITS1
        MOV $0100000 + (28 >> 2) + (73*64), R0
        MOV $DIGITS1_4_IDX, R1
        CALL DIGITS1_2_CALC
        
    1$: CALL DISPLAY_DIGITS1

    LEFT_INDICATOR_OPERS:

        ADD $040000, $0
        BCS 10$
RETURN

    10$:    COM $0
        BNE RIGHT_INDICATOR_OPERS

        MOV $LEFT_INDICATOR_BUFFER, R1
        CALL FILL_INDICATOR_BUFFER

        MOV $LEFT_INDICATOR_BUFFER, R3
        MOV $LEFT_INDICATOR_BAR_LOCATION, INDICATOR_BAR_LOCATION
        MOV $030, GFX_ON_INDICATOR_OFFSET
        CALL DISPLAY_INDICATOR
RETURN

    RIGHT_INDICATOR_OPERS:

        MOV $RIGHT_INDICATOR_BUFFER, R1
        CALL FILL_INDICATOR_BUFFER

        MOV $RIGHT_INDICATOR_BUFFER, R3
        MOV $RIGHT_INDICATOR_BAR_LOCATION, INDICATOR_BAR_LOCATION
        MOV $070, GFX_ON_INDICATOR_OFFSET
        CALL DISPLAY_INDICATOR
RETURN

DISPLAY_INDICATOR:
        CLR R2
        MOV $010, R4

    10$:    MOV R4, -(SP)
        MOV R2, R0
        ASL R0
        MOV R0, R1
        ASL R0
        ADD R1, R0
        ADD INDICATOR_BAR_LOCATION, R0
        MOV R2, R1
        ASL R1
        ADD GFX_ON_INDICATOR_OFFSET, R1
        TSTB (R3)+
        BEQ 1$
        SUB $020, R1
    1$: MOV CLOCK_GFX(R1), R1
        ADD R5, R1
        
        MOV R2, -(SP)
        MOV R3, -(SP)

        MOV (R0)+, R2
        MOV (R0)+, R3
        MOV (R0)+, R0

    3$: MOV R0, -(SP)
        MOV R2, R4
    4$: MOVB (R1)+, (R0)+
        SOB R4, 4$
        MOV (SP)+, R0
        ADD $0100, R0
        SOB R3, 3$

        MOV (SP)+, R3
        MOV (SP)+, R2
        MOV (SP)+, R4

        INC R2
        SOB R4, 10$

RETURN

FILL_INDICATOR_BUFFER:
        MOV (PC)+, R0
    RND:    .word 0150000
        MOVB (R0)+, R2
        BIC $020000, R0
        BIS $010000, R0
        MOV R0, RND
        ADD R0, R2
        BIC $0177770, R2
        INC R2
        MOV $010, R3
        SUB R3, R2
        NEG R2
        BEQ 1$
        SUB R2, R3
    10$:CLRB (R1)+
        SOB R2, 10$
    1$: INCB (R1)+
        SOB R3, 1$
RETURN


INDICATOR_BAR_LOCATION:             .word 0
GFX_ON_INDICATOR_OFFSET:            .word 0
GFX_OFF_INDICATOR_OFFSET_FROM_ON:   .word 0

LEFT_INDICATOR_BUFFER:  .BLKB 8
LEFT_INDICATOR_BAR_LOCATION:
        .word  8 >> 2, 10, 0100000 + (28 >> 2) + (LINE_WIDTHB * 44) + (28 >> 2) + (LINE_WIDTHB * 112)
        .word 12 >> 2, 12, 0100000 + (32 >> 2) + (LINE_WIDTHB * 33) + (28 >> 2) + (LINE_WIDTHB * 112)
        .word 12 >> 2, 13, 0100000 + (32 >> 2) + (LINE_WIDTHB * 19) + (28 >> 2) + (LINE_WIDTHB * 112)
        .word 12 >> 2, 13, 0100000 + (28 >> 2) + (LINE_WIDTHB *  7) + (28 >> 2) + (LINE_WIDTHB * 112)
        .word 12 >> 2, 12, 0100000 + (20 >> 2) + (LINE_WIDTHB *  0) + (28 >> 2) + (LINE_WIDTHB * 112)
        .word  8 >> 2,  8, 0100000 + (12 >> 2) + (LINE_WIDTHB *  1) + (28 >> 2) + (LINE_WIDTHB * 112)
        .word  8 >> 2, 10, 0100000 + ( 4 >> 2) + (LINE_WIDTHB *  4) + (28 >> 2) + (LINE_WIDTHB * 112)
        .word  4 >> 2, 12, 0100000 + ( 0 >> 2) + (LINE_WIDTHB * 12) + (28 >> 2) + (LINE_WIDTHB * 112)

RIGHT_INDICATOR_BUFFER: .BLKB 8
RIGHT_INDICATOR_BAR_LOCATION:
        .word  8 >> 2,  9, 0100000 + (16 >> 2) + (LINE_WIDTHB * 48) + (128 >> 2) + (LINE_WIDTHB * 84)
        .word 12 >> 2, 12, 0100000 + ( 4 >> 2) + (LINE_WIDTHB * 40) + (128 >> 2) + (LINE_WIDTHB * 84)
        .word 12 >> 2, 12, 0100000 + ( 0 >> 2) + (LINE_WIDTHB * 28) + (128 >> 2) + (LINE_WIDTHB * 84)
        .word 12 >> 2, 12, 0100000 + ( 0 >> 2) + (LINE_WIDTHB * 16) + (128 >> 2) + (LINE_WIDTHB * 84)
        .word 12 >> 2, 12, 0100000 + ( 4 >> 2) + (LINE_WIDTHB *  4) + (128 >> 2) + (LINE_WIDTHB * 84)
        .word  8 >> 2,  7, 0100000 + (16 >> 2) + (LINE_WIDTHB *  1) + (128 >> 2) + (LINE_WIDTHB * 84)
        .word  8 >> 2,  7, 0100000 + (24 >> 2) + (LINE_WIDTHB *  3) + (128 >> 2) + (LINE_WIDTHB * 84)
        .word  8 >> 2,  6, 0100000 + (32 >> 2) + (LINE_WIDTHB *  8) + (128 >> 2) + (LINE_WIDTHB * 84)

DIGITS2_1_IDX: .word 0
DIGITS2_2_IDX: .word 0

DIGITS1_1_IDX: .word 3 * 150
DIGITS1_2_IDX: .word 0
DIGITS1_3_IDX: .word 2 * 150
DIGITS1_4_IDX: .word 1 * 150

DIGITS1_9_CALC:
        MOV $150*10, R2
        BR DIGITS1_CALC
DIGITS1_5_CALC:
        MOV $150*6, R2
        BR DIGITS1_CALC
DIGITS1_3_CALC:
        MOV $150*4, R2
        BR DIGITS1_CALC
DIGITS1_2_CALC:
        MOV $150*3, R2
DIGITS1_CALC:
        ADD $150, (R1)
        CMP (R1), R2
        BLO 10$
        CLR (R1)
    10$:RETURN

DIGITS2_CALC:
        ADD $24, (R1)
        CMP (R1), $240
        BLO 10$
        CLR (R1)
    10$:RETURN

DISPLAY_DIGITS1:
        MOV (R1), R1
        ADD 2(R5), R1
        ADD R5, R1
        MOV $30, R2
        MOV $5, R3
        BR DISPLAY_GFX

DISPLAY_DIGITS2:
        MOV (R1), R1
        ADD 4(R5), R1
        ADD R5, R1
        MOV $12, R2
        MOV $2, R3

DISPLAY_GFX:
            MOV R4, -(SP)
        10$:    MOV R0, -(SP)
            MOV R3, R4
        1$: MOVB (R1)+, (R0)+
            SOB R4, 1$
            MOV (SP)+, R0
            ADD $0100, R0
            SOB R2, 10$
            MOV (SP)+, R4
RETURN

CLOCK_GFX:
        .incbin "raw/clock1/CLOCK1_gfx.raw"
        .even

