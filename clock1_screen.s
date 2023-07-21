#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' ('CLOCK SCREEN 1') 6-channel (2AY) music only!
#   BY VLADIMIR 'KUVO' KUTYAKOV/CSI
#   
#   CONVERSION FOR Elektronika MS0511 (UKNC)
#   BY ABERRANTHACKER
#
#   SOUND DEVICE:   Aberrant Sound Module
#   PLATFORM:       Elektronika MS0511
#   COMPILER:       GNU Assembler
#-------------------------------------------------------------------------------
           .nolist

           .include "hwdefs.s"
           .include "macros.s"
           .include "defs.s"
           .include "clock_defs.s"

           .global start

           .org ClockScreenStart

           .equiv NUMBERS_COUNTER_INCREMENT, 0x0004 # 0x0020
           .equiv DIGITS2_COUNTER_INCREMENT, 0x0480 # 0x2000
           .equiv INDICATORS_COUNTER_INCREMENT, 0x4000 # 0x4000

start:
START_CLOCK:
        MOV  $CLOCK_GFX, R5

       .equiv first_run, .+2
        TST  $0 # first run?
        BNZ  2$ # no, skip initialization

        MOV  PC, first_run # yes, skip initialization next time

        MOV  $FB0, R0
        MOV  R5, R1
        ADD  (R5), R1
        MOV  $CLOCK_SCR_HEIGHT, R2
        10$:
            MOV  $CLOCK_SCR_WIDTH_WORDS, R3
            1$:
                MOV  (R1)+, (R0)+
            SOB  R3, 1$
            ADD  $LINE_WIDTHB - CLOCK_SCR_WIDTH_BYTES, R0
        SOB  R2, 10$

    2$:
        CALL NEXT_CLOCK_OPER
        RETURN

NEXT_CLOCK_OPER:
    NUMBERS_OPERS:
        ADD  $NUMBERS_COUNTER_INCREMENT, $0
        BCC  DIGITS2_OPERS

       .equiv NUMBERS_IDX, .+2
        MOV  $0, R1
        ADD  $0140, R1
        CMP  R1, $0140 * 4
        BLO  10$

        CLR  R1
    10$:MOV  R1, NUMBERS_IDX
        ADD  6(R5), R1
        ADD  R5, R1
        MOV  $016, R2
        MOV  $3, R3   # MOV  $6, R3
        MOV  $FB0 + (96 >> 2) + (124*LINE_WIDTHB), R0
        CALL DISPLAY_GFX

    DIGITS2_OPERS:
        ADD  $DIGITS2_COUNTER_INCREMENT, $0
        BCS  10$
        RETURN

    10$:MOV  $FB0 + (96 >> 2) + (96*LINE_WIDTHB), R0
        MOV  $DIGITS2_1_IDX, R1
        CALL DIGITS2_CALC
        TST  (R1)
        BNE  1$

        CALL DISPLAY_DIGITS2
        MOV  $FB0 + (84 >> 2) + (99*LINE_WIDTHB), R0
        MOV  $DIGITS2_2_IDX, R1
        CALL DIGITS2_CALC
        BR   2$

    1$: CALL DISPLAY_DIGITS2
        BR DIGITS1_OPERS

    2$: CALL DISPLAY_DIGITS2_SHIFTED

    DIGITS1_OPERS:
        TST  DIGITS2_1_IDX
        BNZ  LEFT_INDICATOR_OPERS

        TST  DIGITS2_2_IDX
        BNZ  LEFT_INDICATOR_OPERS

        MOV  $FB0 + (136 >> 2) + (42*LINE_WIDTHB), R0
        MOV  $DIGITS1_1_IDX, R1
        CALL DIGITS1_9_CALC
        TST  (R1)
        BNZ  1$

        CALL DISPLAY_DIGITS1
        MOV  $FB0 + (100 >> 2) + (52*LINE_WIDTHB), R0
        MOV  $DIGITS1_2_IDX, R1
        CALL  DIGITS1_5_CALC
        TST  (R1)
        BNZ  2$

        CALL DISPLAY_DIGITS1_SHIFTED
        MOV  $FB0 + (64 >> 2) + (62*LINE_WIDTHB), R0
        MOV  $DIGITS1_3_IDX, R1
        CALL DIGITS1_3_CALC
        TST  (R1)
        BNZ  1$

        CALL DISPLAY_DIGITS1
        MOV  $FB0 + (28 >> 2) + (73*LINE_WIDTHB), R0
        MOV  $DIGITS1_4_IDX, R1
        CALL DIGITS1_2_CALC
        BR   2$

    1$: CALL DISPLAY_DIGITS1
        BR   LEFT_INDICATOR_OPERS

    2$: CALL DISPLAY_DIGITS1_SHIFTED

    LEFT_INDICATOR_OPERS:
        ADD  $INDICATORS_COUNTER_INCREMENT, $0
        BCS  10$
        RETURN

    10$:COM  $0
        BNZ  RIGHT_INDICATOR_OPERS

        MOV  $LEFT_INDICATOR_BUFFER, R1
        CALL FILL_INDICATOR_BUFFER # defines how many segments to on/off

        MOV  $LEFT_INDICATOR_BUFFER, R3
        MOV  $LEFT_INDICATOR_BAR_LOCATION, INDICATOR_BAR_LOCATION
        MOV  $030, GFX_ON_INDICATOR_OFFSET
        CALL DISPLAY_INDICATOR
1234$:  RETURN

    RIGHT_INDICATOR_OPERS:

        MOV  $RIGHT_INDICATOR_BUFFER, R1
        CALL FILL_INDICATOR_BUFFER

        MOV  $RIGHT_INDICATOR_BUFFER, R3
        MOV  $RIGHT_INDICATOR_BAR_LOCATION, INDICATOR_BAR_LOCATION
        MOV  $070, GFX_ON_INDICATOR_OFFSET
        CALL DISPLAY_INDICATOR
        RETURN

DISPLAY_INDICATOR:
        CLR  R2
        MOV  $010, R4

        10$:PUSH R4

            MOV  R2, R1
            ASL R1
            ASL R1
            ASL R1 # segment number * 8
            ADD  INDICATOR_BAR_LOCATION, R1 # calc segment number params address
            MOV  R2, R0
            ASL  R0
            ADD  GFX_ON_INDICATOR_OFFSET, R0
            TSTB (R3)+
            BZE  1$

            SUB  $16, R0
        1$: MOV  CLOCK_GFX(R0), R0
            ADD  R5, R0

            PUSH R2
            PUSH R3
            PUSH R5

            MOV  (R1)+, R2 # element width bytes
            MOV  (R1)+, R3 # element height
            MOV  (R1)+, R5 # mask address
            MOV  (R1)+, R1 # dst address

            3$:
                PUSH R1
                PUSH R5
                MOV  R2, R4
                4$:
                    BIC (R5)+, (R1)
                    BIS (R0)+, (R1)+
                SOB  R4, 4$
                POP  R5
                POP  R1
                ADD  $LINE_WIDTHB, R1
            SOB  R3, 3$

            POP  R5
            POP  R3
            POP  R2

            INC  R2
            POP  R4
        SOB  R4, 10$

        RETURN

FILL_INDICATOR_BUFFER:
       # IN: R1 = [LEFT|RIGHT]_INDICATOR_BUFFER
       .equiv RND, .+2
        MOV  $0150000, R0
        MOVB (R0)+, R2
        BIC  $020000, R0
        BIS  $010000, R0
        MOV  R0, RND
        ADD  R0, R2
        BIC  $0177770, R2
        INC  R2
        MOV  $010, R3
        SUB  R3, R2
        NEG  R2
        BEQ  1$

        SUB  R2, R3
        10$:
            CLRB (R1)+
        SOB  R2, 10$

        1$:
            INCB (R1)+
        SOB  R3, 1$
        RETURN

INDICATOR_BAR_LOCATION:             .word 0
GFX_ON_INDICATOR_OFFSET:            .word 0
GFX_OFF_INDICATOR_OFFSET_FROM_ON:   .word 0

center_8_16: .word 0xF0F0, 0x0F0F # 0   8->16 center
west_12_16:  .word 0xFFFF, 0x0F0F # 2  12->16 east
east_12_16:  .word 0xF0F0, 0xFFFF # 4  12->16 west
east_4_8:    .word 0xF0F0         # 6   4-> 8 west
center_8_8:  .word 0xFFFF
LEFT_INDICATOR_BUFFER: .space 8 # .BLKB 8

.set line, LINE_WIDTHB * 112
LEFT_INDICATOR_BAR_LOCATION:
  .word 1, 10, center_8_8,  FB0 + line + (28 >> 2) + (LINE_WIDTHB * 44) + (28 >> 2) #  8
  .word 2, 12, east_12_16,  FB0 + line + (32 >> 2) + (LINE_WIDTHB * 33) + (28 >> 2) # 12 sh
  .word 2, 13, east_12_16,  FB0 + line + (32 >> 2) + (LINE_WIDTHB * 19) + (28 >> 2) # 12 sh
  .word 2, 13, west_12_16,  FB0 + line + (28 >> 2) + (LINE_WIDTHB *  7) + (28 >> 2) # 12
  .word 2, 12, west_12_16,  FB0 + line + (20 >> 2) + (LINE_WIDTHB *  0) + (28 >> 2) # 12
  .word 1,  8, center_8_8,  FB0 + line + (12 >> 2) + (LINE_WIDTHB *  1) + (28 >> 2) #  8
  .word 1, 10, center_8_8,  FB0 + line + ( 4 >> 2) + (LINE_WIDTHB *  4) + (28 >> 2) #  8
  .word 1, 12, east_4_8,    FB0 + line + ( 0 >> 2) + (LINE_WIDTHB * 12) + (28 >> 2) #  4 sh

RIGHT_INDICATOR_BUFFER: .space 8 # .BLKB 8

.set line, LINE_WIDTHB * 84
RIGHT_INDICATOR_BAR_LOCATION:
  .word  1,  9, center_8_8, FB0 + line + (16 >> 2) + (LINE_WIDTHB * 48) + (128 >> 2) #  8
  .word  2, 12, east_12_16, FB0 + line + ( 4 >> 2) + (LINE_WIDTHB * 40) + (128 >> 2) # 12 sh
  .word  2, 12, west_12_16, FB0 + line + ( 0 >> 2) + (LINE_WIDTHB * 28) + (128 >> 2) # 12
  .word  2, 12, west_12_16, FB0 + line + ( 0 >> 2) + (LINE_WIDTHB * 16) + (128 >> 2) # 12
  .word  2, 12, east_12_16, FB0 + line + ( 4 >> 2) + (LINE_WIDTHB *  4) + (128 >> 2) # 12 sh
  .word  1,  7, center_8_8, FB0 + line + (16 >> 2) + (LINE_WIDTHB *  1) + (128 >> 2) #  8
  .word  1,  7, center_8_8, FB0 + line + (24 >> 2) + (LINE_WIDTHB *  3) + (128 >> 2) #  8
  .word  1,  6, center_8_8, FB0 + line + (32 >> 2) + (LINE_WIDTHB *  8) + (128 >> 2) #  8

DIGITS2_1_IDX: .word 0
DIGITS2_2_IDX: .word 0

.equiv DIGIT1_WIDTH,  24
.equiv DIGIT1_HEIGHT, 30
.equiv DIGIT1_SIZE, DIGIT1_WIDTH >> 2 * DIGIT1_HEIGHT

DIGITS1_1_IDX: .word 3 * DIGIT1_SIZE # 150
DIGITS1_2_IDX: .word 0
DIGITS1_3_IDX: .word 2 * DIGIT1_SIZE # 150
DIGITS1_4_IDX: .word 1 * DIGIT1_SIZE # 150

DIGITS1_9_CALC:
        MOV $DIGIT1_SIZE *10, R2 # MOV $150*10, R2
        BR DIGITS1_CALC

DIGITS1_5_CALC:
        MOV $DIGIT1_SIZE * 6, R2 # MOV $150*6, R2
        BR DIGITS1_CALC

DIGITS1_3_CALC:
        MOV $DIGIT1_SIZE * 4, R2 # MOV $150*4, R2
        BR DIGITS1_CALC

DIGITS1_2_CALC:
        MOV $DIGIT1_SIZE * 3, R2 # MOV $150*3, R2
DIGITS1_CALC:
        ADD  $DIGIT1_SIZE, (R1)  # ADD  $150, (R1)
        CMP  (R1), R2
        BLO  1237$

        CLR  (R1)
1237$:  RETURN

DIGITS2_CALC:
        ADD  $24, (R1)
        CMP  (R1), $240
        BLO  1237$

        CLR  (R1)
1237$:  RETURN

DISPLAY_DIGITS1:
        MOV  (R1), R1
        ADD  2(R5), R1
        ADD  R5, R1
        MOV  $DIGIT1_HEIGHT, R2
        MOV  $DIGIT1_WIDTH>>3, R3 # MOV  $5, R3
        BR   DISPLAY_DIGIT1_GFX

DISPLAY_DIGITS1_SHIFTED:
        MOV  (R1), R1
        ADD  0110(R5), R1
        ADD  R5, R1
        MOV  $DIGIT1_HEIGHT, R2
        MOV  $DIGIT1_WIDTH>>3, R3 # MOV  $5, R3
        BR   DISPLAY_DIGIT1_GFX_SHIFTED

DISPLAY_DIGITS2:
        MOV  (R1), R1
        ADD  4(R5), R1
        ADD  R5, R1
        MOV  $12, R2
        MOV  $1, R3      # MOV $2, R3

DISPLAY_GFX:
        PUSH R4
        10$:
            PUSH R0
            MOV  R3, R4
            1$:
                MOV (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            SOB  R4, 1$
            POP  R0
            ADD $LINE_WIDTHB, R0
        SOB R2, 10$
        POP  R4

        RETURN

DISPLAY_DIGITS2_SHIFTED:
        MOV  (R1), R1
        ASL  R1
        ADD  0112(R5), R1
        ADD  R5, R1
        MOV  $12, R2
        PUSH R4
        MOV  $0xF0F0,R3
        MOV  $0x0F0F,R4

        10$:
            PUSH R0
            BIC R3,(R0)
            BIS (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            BIC R4,(R0)
            BIS (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            POP  R0
            ADD $LINE_WIDTHB, R0
        SOB R2, 10$
        POP  R4

        RETURN

DISPLAY_DIGIT1_GFX:
        PUSH R4
        MOV $0xFFFF,R3
        MOV $0x0F0F,R4
        10$:
            PUSH R0
            BIC R3,(R0)
            BIS (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            BIC R3,(R0)
            BIS (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            BIC R4,(R0)
            BIS (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            POP  R0
            ADD $LINE_WIDTHB, R0
        SOB R2, 10$
        POP R4

        RETURN

DISPLAY_DIGIT1_GFX_SHIFTED:
        PUSH R4
        MOV $0xF0F0,R3
        MOV $0xFFFF,R4
        10$:
            PUSH R0
            BIC R3,(R0)
            BIS (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            BIC R4,(R0)
            BIS (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            BIC R4,(R0)
            BIS (R1)+, (R0)+ # MOVB (R1)+, (R0)+ #
            POP  R0
            ADD $LINE_WIDTHB, R0
        SOB R2, 10$
        POP R4

        RETURN

CLOCK_GFX:
        .incbin "build/clock1_gfx.bin"
        .even
