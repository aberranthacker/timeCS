
#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' ('CLOCK SCREEN 2') 6-channel (2AY) music only!
#   BY VLADIMIR 'KUVO' KUTYAKOV/CSI
#
#   PLATFORM:       BK-0011M
#   COMPILER:       PDPy11
#-------------------------------------------------------------------------------
           .list

           .include "hwdefs.s"
           .include "macros.s"
           .include "defs.s"
           .include "clock_defs.s"

           .global start

           .org ClockScreenStart

start:
START_CLOCK:
        TST $0
        BNE 2$

        MOV PC, .-4

        MOV $FB0, R0
        MOV $CLOCK_GFX, R1
        MOV $CLOCK_SCR_HEIGHT, R2
        10$:
            MOV $CLOCK_SCR_WIDTH_WORDS, R3
            1$:
                MOV (R1)+, (R0)+
            SOB R3, 1$
            ADD $LINE_WIDTHB - CLOCK_SCR_WIDTH_BYTES, R0
        SOB R2, 10$
    2$:
        CALL NEXT_CLOCK_OPER

        RETURN

NEXT_CLOCK_OPER:
      # WAIT

        COM $0
        BNE 1$

        MOV $1, R0
        XOR R0, ADDER_Y2
       .equiv RIGHT_RAY_IDX, .+2
    1$: MOV $RIGHT_RAY - 4, R5
       .equiv LEFT_RAY_IDX, .+2
        MOV $LEFT_RAY, R4

        DEC $0
        BPL DISPLAY_RAYS
        MOV $017, .-4

        ADD $4, R5
        CMP R5, $RIGHT_RAY + (4 * 11)
        BLO 2$

        MOV $RIGHT_RAY, R5
        ADD $4, R4
        CMP R4, $LEFT_RAY + (4 * 12)
        BLO 2$

        MOV $LEFT_RAY, R4
    2$: MOV R5, RIGHT_RAY_IDX
        MOV R4, LEFT_RAY_IDX

DISPLAY_RAYS:
        PUSH R4
        CALL DISPLAY_RAY
        POP  R5
DISPLAY_RAY:
        MOVB (R5)+, R0
        BIC $0177400, R0
        MOVB (R5)+, R1
        BIC $0177400, R1

        MOVB (R5)+, R2
        BIC $0177400, R2
        MOVB (R5)+, R3
       .equiv ADDER_Y2, .+2
        ADD $0, R3
        BIC $0177400, R3

        MOV (PC)+, R4 # 'NOP' IN R4
        NOP
        SUB R0, R2
        BEQ 1$
        BMI 10$

        MOV (PC)+, R4 # 'INC R0' IN R4
        INC R0
        BR 1$

    10$:NEG R2
        MOV (PC)+, R4 # 'DEC R0' IN R4
        DEC R0
    1$: MOV R4, CODE_MODIFY_INCR_X

        MOV (PC)+, R4 # 'NOP' IN R4
        NOP
        SUB R1, R3
        BEQ 3$
        BMI 2$

        MOV (PC)+, R4 # 'INC R1' IN R4
        INC R1
        BR 3$

    2$: NEG R3
        MOV (PC)+, R4 # 'DEC R1' IN R4
        DEC R1
    3$: MOV R4, CODE_MODIFY_INCR_Y

        CLR FACTOR_X
        CLR FACTOR_Y
        CLR FACTOR_X_ALIGN
        CLR FACTOR_Y_ALIGN

        MOV R2, DOTS_COUNT

        CMP R2, R3
        BNE 4$

        CLR R2
        CLR R3
        BR LINE_DRAW

    4$: BLO 5$

      # R3 * 256 / R2 * 256
        MOV R2,R4
        CLR R2
        SWAB R3
        DIV R4,R2
        SWAB R2

        MOV R2, FACTOR_Y_ALIGN
        MOV R2, FACTOR_Y_FINE
        MOV FACTOR_Y, R3
        CLR R2
        BR LINE_DRAW

    5$: MOV R3, DOTS_COUNT

      # R2 * 256 / R3 * 256
        MOV R2,R5
        CLR R4
        SWAB R5
        DIV R3,R4
        SWAB R4

        MOV R4, FACTOR_X_ALIGN
        MOV R4, FACTOR_X_FINE
        MOV FACTOR_X, R2
        CLR R3

LINE_DRAW:
        COM $0
        BNE LINE_DRAW
        SUB $4, DOTS_COUNT

    OFFSET_X:
                DEC R2
                BPL OFFSET_Y

               .equiv FACTOR_X_ALIGN, .+2
                MOV $0, R4
                BEQ FACTOR_X_INIT

               .equiv FACTOR_X_FINE, .+2
                ADD R4, $0
                BCC OFFSET_Y

        FACTOR_X_INIT:
               .equiv FACTOR_X, .+2
                MOV $0, R2

            CODE_MODIFY_INCR_X:
                NOP # or 'INC R0' or 'DEC R0'

    OFFSET_Y:
                DEC R3
                BPL CALC_SCREEN_ADDR
               .equiv FACTOR_Y_ALIGN, .+2
                MOV $0, R4
                BEQ FACTOR_Y_INIT

               .equiv FACTOR_Y_FINE, .+2
                ADD R4, $0
                BCC CALC_SCREEN_ADDR

        FACTOR_Y_INIT:
               .equiv FACTOR_Y, .+2
                MOV $0, R3

            CODE_MODIFY_INCR_Y:
                NOP # or 'INC R1' or 'DEC R1'

    CALC_SCREEN_ADDR: # R0: X, R1: Y
                MOV R1, R5
                MUL $288,R5 #SWAB R4         # X400
                ADD R0, R5  #BIS R0, R4
                CLC
                ROR R5          # X200
                ASR R5          # X100
                ADD $FB0, R5

    CALC_DOT_ADDR:
                MOV R0, R4
                BIC $0177770, R4
                ASL R4

    DISPLAY_DOT:
                MOV DOTS(R4), R4
                XOR R4, (R5)

                DEC (PC)+
            DOTS_COUNT: .word 0
                BNE OFFSET_X

    LINE_END:


RETURN

DOTS:
               #7654321076543210      7  6  5  4  3  2  1  0
        .word 0b0000000100000000 # 0b00_00_00_00_00_00_00_10
        .word 0b0000001000000010 # 0b00_00_00_00_00_00_11_00
        .word 0b0000010000000000 # 0b00_00_00_00_00_10_00_00
        .word 0b0000100000001000 # 0b00_00_00_00_11_00_00_00
        .word 0b0001000000000000 # 0b00_00_00_10_00_00_00_00
        .word 0b0010000000100000 # 0b00_00_11_00_00_00_00_00
        .word 0b0100000000000000 # 0b00_10_00_00_00_00_00_00
        .word 0b1000000010000000 # 0b11_00_00_00_00_00_00_00

LEFT_RAY:

.byte 32, 4 + (16 * 0)
.byte 74 + 010, 59

.byte 32, 4 + (16 * 1)
.byte 72 + 010, 62

.byte 32, 4 + (16 * 2)
.byte 68 + 010, 66

.byte 32, 4 + (16 * 3)
.byte 67 + 010, 72

.byte 32, 4 + (16 * 4)
.byte 66 + 010, 79

.byte 32, 4 + (16 * 5)
.byte 63 + 010, 86

.byte 32, 4 + (16 * 6)
.byte 64 + 010, 94

.byte 32, 4 + (16 * 7)
.byte 64 + 010, 102

.byte 32, 4 + (16 * 8)
.byte 67 + 010, 108

.byte 32, 4 + (16 * 9)
.byte 69 + 010, 114

.byte 32, 4 + (16 * 10)
.byte 70 + 010, 119

.byte 32, 4 + (16 * 11)
.byte 73 + 010, 121

RIGHT_RAY:

.byte 160, 12
.byte 115 - 4, 66

.byte 160, 28
.byte 116 - 4, 69

.byte 160, 44
.byte 119 - 4, 72

.byte 160, 61
.byte 121 - 4, 77

.byte 160, 76
.byte 122 - 4, 83

.byte 160, 92
.byte 122 - 4, 90

.byte 160, 108
.byte 122 - 4, 96

.byte 160, 124
.byte 121 - 4, 102

.byte 160, 140
.byte 120 - 4, 108

.byte 160, 156
.byte 118 - 4, 111

.byte 160, 172
.byte 116 - 4, 114

CLOCK_GFX:
        .incbin "build/clock2/clock2.raw"
        .even
