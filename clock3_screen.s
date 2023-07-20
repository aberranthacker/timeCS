#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' ('CLOCK SCREEN 3') 6-channel (2AY) music only!
#   BY VLADIMIR 'KUVO' KUTYAKOV/CSI
#
#   CONVERSION FOR Elektronika MS0511 (UKNC)
#   BY ABERRANTHACKER
#
#   SOUND DEVICE:   Aberrant Sound Module
#   PLATFORM:       Elektronika MS0511
#   COMPILER:       GNU Assembler
#-------------------------------------------------------------------------------
        DANGLING_WIDTH_ORIG = 24 >> 2
        DANGLING_WIDTH = DANGLING_WIDTH_ORIG + 2
        DANGLING_HEIGHT = 44
        DANGLING_ONE_PHASE_SIZE = DANGLING_WIDTH * DANGLING_HEIGHT
        DANGLING_GFX_BUFFER_SIZE = DANGLING_ONE_PHASE_SIZE * 8

        DANGLING_GFX_ALL_BUFFERS_SIZE = DANGLING_GFX_BUFFER_SIZE * 2

        DANGLING_GFX_BUFFER = DANGLING1_GFX

        DANGLING_GFX_BUFFER1 = DANGLING_GFX_BUFFER
        DANGLING_GFX_BUFFER2 = DANGLING_GFX_BUFFER1 + DANGLING_GFX_BUFFER_SIZE


        SCREEN_BUFFER_SIZE = 256 >> 2 * 184
        SCREEN_BUFFER = FB1 # DANGLING_GFX_BUFFER + DANGLING_GFX_ALL_BUFFERS_SIZE


        LINE_CENTER_X = 96
        LINE_CENTER_Y = 80

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

    PREP_SCREEN_BUFFER_DISPLAY:
        offset = (184*LINE_WIDTHB) - (LINE_WIDTHB - CLOCK_SCR_WIDTH_BYTES)
        MOV $FB0 + offset, R0
        MOV $SCREEN_BUFFER + offset, R4
        MOV $CLOCK_GFX_END, R1
        MOV $CLOCK_SCR_HEIGHT, R2
        10$:
            MOV $CLOCK_SCR_WIDTH_WORDS, R3
            1$:
                MOV -(R1), -(R0)
                MOV (R0), -(R4)
            SOB R3, 1$
            SUB $LINE_WIDTHB - CLOCK_SCR_WIDTH_BYTES, R0
            SUB $LINE_WIDTHB - CLOCK_SCR_WIDTH_BYTES, R4
        SOB R2, 10$

    PREP_DANGLING:
        MOV $DANGLING2_GFX, R1
        MOV $DANGLING_GFX_BUFFER2, R0
        MOV $DANGLING_HEIGHT, R2
        10$:
            MOV $DANGLING_WIDTH_ORIG>>1, R3
            1$:
                MOV (R1)+, (R0)+
            SOB R3, 1$
            CLR (R0)+
        SOB R2, 10$

        MOV $DANGLING_GFX_BUFFER + DANGLING_ONE_PHASE_SIZE, R0
        MOV $DANGLING1_GFX_END, R1
        MOV $DANGLING_HEIGHT, R2
        2$:
            MOV $DANGLING_WIDTH_ORIG >> 1, R3
            CLR -(R0)
            3$:
                MOV -(R1), -(R0)
            SOB R3, 3$
        SOB R2, 2$

        MOV $DANGLING_GFX_BUFFER, R1
        MOV $DANGLING_GFX_BUFFER + DANGLING_ONE_PHASE_SIZE, R3
        CALL SHIFT_DANGLING_GFX_BUFFER

        MOV $DANGLING_GFX_BUFFER2, R1
        MOV $DANGLING_GFX_BUFFER2 + DANGLING_ONE_PHASE_SIZE, R3
        CALL SHIFT_DANGLING_GFX_BUFFER

    CLOCK_OPER:
        WAIT

        MOV $SCREEN_BUFFER + 12 + (14*64), R0
        MOV $0100 - 030, R1
        MOV $-1, R4
        MOV $150, R2
        10$:
            MOV $014, R3
            1$:
                MOV R4, (R0)+
            SOB R3, 1$
            ADD R1, R0
        SOB R2, 10$

        CALL NEXT_CLOCKHAND_OPER

        MOV $SCREEN_BUFFER + 48>>2 + (14*64), R1
        MOV $FB0 + 48>>2 + (14*LINE_WIDTHB), R0
        MOV $64 - 96>>2, R4
        MOV $LINE_WIDTHB - 96>>2, R5
        MOV $150, R2
        2$:
            MOV $48>>2, R3
            3$:
                MOV (R1)+, (R0)+
            SOB R3, 3$
            ADD R4, R1
            ADD R5, R0
        SOB R2, 2$
        RETURN

SHIFT_DANGLING_GFX_BUFFER:
        MOV $7 * DANGLING_HEIGHT, R2
        6$:
            MOV R3, R0
            MOV $DANGLING_WIDTH >> 1, R4
            7$:
                MOV (R1)+, (R0)+
            SOB R4, 7$
            8$:
                MOV R3, R0
                MOV $DANGLING_WIDTH >> 1 - 1, R4
                ASLB (R0)+   # 0 -> 1  1 -> 2  0 -> 2
                INC R0       # 1 -> 2  2 -> 3
                9$:
                    ROLB (R0)+ # 2 -> 3  3 -> 4  2 -> 4
                    INC R0     # 3 -> 4  4 -> 5
                SOB R4, 9$
                INC R3
                INC PC # INC PC + BR repeat two times
            BR 8$
            DEC R0
            MOV R0, R3
        SOB R2, 6$
        RETURN

DISPLAY_DANGLING1:
        MOV $DANGLING_GFX_BUFFER1, R3
        BR DISPLAY_DANGLING

DISPLAY_DANGLING2:
        MOV $DANGLING_GFX_BUFFER2, R3

DISPLAY_DANGLING:
        CLR R1
        MOV X_FOR_DANGLING, R2
        BIC $0177770, R2
        BEQ 1$

        10$:
            ADD $0540, R1
        SOB R2, 10$
    1$: ADD R3, R1
        MOV SCREEN_ADDR_FOR_DANGLING, R0
        SUB $2, R0

        MOV $0100 - 010, R3
        MOV $DANGLING_HEIGHT, R2
        2$:
            BIC (R1)+, (R0)+
            BIC (R1)+, (R0)+
            BIC (R1)+, (R0)+
            BIC (R1)+, (R0)+
            ADD R3, R0
        SOB R2, 2$
        RETURN



NEXT_CLOCKHAND_OPER:
        MOV (PC)+, R5
    MIN_CLOCKHAND_IDX:  .word CLOCKHAND_DOTS-4
        MOV (PC)+, R4
    HOUR_CLOCKHAND_IDX: .word CLOCKHAND_DOTS

        ADD $4, R5
        CMP R5, $CLOCKHAND_DOTS_END
        BLO 10$

        MOV $CLOCKHAND_DOTS, R5
    10$:DEC $013
        BPL 1$

        MOV $013, .-4
        ADD $4, R4
        CMP R4, $CLOCKHAND_DOTS_END
        BLO 1$

        MOV $CLOCKHAND_DOTS, R4
    1$: MOV R4, HOUR_CLOCKHAND_IDX
        MOV R5, MIN_CLOCKHAND_IDX



DISPLAY_CLOCKHANDS:
        MOV R4, -(SP)
        CLR LINE_LENGTH
        CALL DISPLAY_CLOCKHAND
        CALL DISPLAY_DANGLING1
        MOV (SP)+, R5
        INC LINE_LENGTH
        CALL DISPLAY_CLOCKHAND
        CALL DISPLAY_DANGLING2
        RETURN

        #BR NEXT_CLOCK_OPER
DISPLAY_CLOCKHAND:
        MOV $LINE_CENTER_X, R0
        MOV $LINE_CENTER_Y, R1

        MOV (R5)+, R2
        MOV (R5)+, R3

        MOV (PC)+, R4       #'NOP' IN R4
        NOP
        SUB R0, R2
        BEQ 1$
        BMI 10$
        MOV (PC)+, R4       #'INC R0' IN R4
        INC R0
        BR 1$
    10$:    NEG R2
        MOV (PC)+, R4       #'DEC R0' IN R4
        DEC R0
    1$: MOV R4, CODE_MODIFY_INCR_X

        MOV (PC)+, R4       #'NOP' IN R4
        NOP
        SUB R1, R3
        BEQ 3$
        BMI 2$
        MOV (PC)+, R4       #'INC R1' IN R4
        INC R1
        BR 3$
    2$: NEG R3
        MOV (PC)+, R4       #'DEC R1' IN R4
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

       #MOV R2, R4
       #MOV R3, R2
       #MOV R4, R3
       #CALL DIV_FUNC
       #SWAB R4

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
       #CALL DIV_FUNC
       #SWAB R4

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
                MOV $030, COMP_DOTS_COUNT
                TST (PC)+
            LINE_LENGTH:    .word 0
                BEQ OFFSET_X
                MOV DOTS_COUNT, R4
                ASR R4
                ASR R4
                SUB R4, DOTS_COUNT
                MOV DOTS_COUNT, R4
                ASR R4
                MOV R4, COMP_DOTS_COUNT

    OFFSET_X:
                DEC R2
                BPL OFFSET_Y

                MOV (PC)+, R4
            FACTOR_X_ALIGN: .word 0
                BEQ FACTOR_X_INIT

                ADD R4, (PC)+
            FACTOR_X_FINE:  .word 0
                BCC OFFSET_Y

        FACTOR_X_INIT:

                MOV (PC)+, R2
            FACTOR_X:   .word 0

            CODE_MODIFY_INCR_X:
            .word 0                     #'NOP' or 'INC R0' or 'DEC R0'

    OFFSET_Y:

                DEC R3
                BPL CALC_SCREEN_ADDR

                MOV (PC)+, R4
            FACTOR_Y_ALIGN: .word 0
                BEQ FACTOR_Y_INIT

                ADD R4, (PC)+
            FACTOR_Y_FINE:  .word 0
                BCC CALC_SCREEN_ADDR

        FACTOR_Y_INIT:

                MOV (PC)+, R3
            FACTOR_Y:   .word 0

            CODE_MODIFY_INCR_Y:
                .word 0                     #'NOP' or 'INC R1' or 'DEC R1'

    CALC_SCREEN_ADDR:

                #COM $0
                #BEQ DOTS_COUNT - 2

                MOV R1, R4
                SWAB R4         #X400
                BIS R0, R4
                CLC
                ROR R4          #X200
                ASR R4          #X100
                ADD $SCREEN_BUFFER, R4

    CALC_DOT_ADDR:

                MOV R0, R5
                BIC $0177770, R5
                ASL R5

    DISPLAY_DOT:

                MOV DOTS(R5), R5
                BIC R5, (R4)
                BIC R5, -0100(R4)
                BIC R5, 0100(R4)

                DEC (PC)+
            DOTS_COUNT: .word 0
                BEQ LINE_END
                CMP @(PC)+, (PC)+
                        .word DOTS_COUNT
            COMP_DOTS_COUNT:    .word 0
                BNE OFFSET_X
                MOV R0, (PC)+
            X_FOR_DANGLING: .word 0
                MOV R4, (PC)+
            SCREEN_ADDR_FOR_DANGLING: .word 0
                BR OFFSET_X

    LINE_END:


RETURN

DOTS:         # 7654321076543210
        .word 0b0000001100000011 # 0b00_00_00_00_00_00_11_11
        .word 0b0000011000000110 # 0b00_00_00_00_00_11_11_00
        .word 0b0000110000001100 # 0b00_00_00_00_11_11_00_00
        .word 0b0001100000011000 # 0b00_00_00_11_11_00_00_00
        .word 0b0011000000110000 # 0b00_00_11_11_00_00_00_00
        .word 0b0110000001100000 # 0b00_11_11_00_00_00_00_00
        .word 0b1100000011000000 # 0b11_11_00_00_00_00_00_00
        .word 0b1000000010000000 # 0b11_00_00_00_00_00_00_00



# DIV_FUNC:
#             #R4 = R2/R3
# 
#             CLR R5
#             CLR R4
#             TST R3
#             BEQ 2$
#             INC R4
#       10$:  ASLB R2
#             ROL R5
#             CMP R5, R3
#             BLO 1$
#             SUB R3, R5
#             SEC
#             ROL R4
#             BCC 10$
# RETURN
#       1$:    ASL R4
#             BCC 10$
#       2$:   RETURN


CLOCKHAND_DOTS:
.word  96, 14
.word 103, 15
.word 109, 16
.word 114, 19
.word 120, 23
.word 125, 28
.word 129, 33
.word 133, 39
.word 136, 44
.word 138, 50
.word 139, 55
.word 141, 60
.word 142, 65
.word 143, 70
.word 143, 75
.word 143, 80


.word 143, LINE_CENTER_Y + (LINE_CENTER_Y - 75)
.word 143, LINE_CENTER_Y + (LINE_CENTER_Y - 70)
.word 142, LINE_CENTER_Y + (LINE_CENTER_Y - 65)
.word 141, LINE_CENTER_Y + (LINE_CENTER_Y - 60)
.word 139, LINE_CENTER_Y + (LINE_CENTER_Y - 55)
.word 138, LINE_CENTER_Y + (LINE_CENTER_Y - 50)
.word 136, LINE_CENTER_Y + (LINE_CENTER_Y - 44)
.word 133, LINE_CENTER_Y + (LINE_CENTER_Y - 39)
.word 129, LINE_CENTER_Y + (LINE_CENTER_Y - 33)
.word 125, LINE_CENTER_Y + (LINE_CENTER_Y - 28)
.word 120, LINE_CENTER_Y + (LINE_CENTER_Y - 23)
.word 114, LINE_CENTER_Y + (LINE_CENTER_Y - 19)
.word 109, LINE_CENTER_Y + (LINE_CENTER_Y - 16)
.word 103, LINE_CENTER_Y + (LINE_CENTER_Y - 15)
.word  96, LINE_CENTER_Y + (LINE_CENTER_Y - 14)

.word LINE_CENTER_X - (103 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 15)
.word LINE_CENTER_X - (109 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 16)
.word LINE_CENTER_X - (114 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 19)
.word LINE_CENTER_X - (120 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 23)
.word LINE_CENTER_X - (125 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 28)
.word LINE_CENTER_X - (129 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 33)
.word LINE_CENTER_X - (133 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 39)
.word LINE_CENTER_X - (136 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 44)
.word LINE_CENTER_X - (138 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 50)
.word LINE_CENTER_X - (139 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 55)
.word LINE_CENTER_X - (141 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 60)
.word LINE_CENTER_X - (142 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 65)
.word LINE_CENTER_X - (143 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 70)
.word LINE_CENTER_X - (143 - LINE_CENTER_X), LINE_CENTER_Y + (LINE_CENTER_Y - 75)


.word LINE_CENTER_X - (143 - LINE_CENTER_X), 80
.word LINE_CENTER_X - (143 - LINE_CENTER_X), 75
.word LINE_CENTER_X - (143 - LINE_CENTER_X), 70
.word LINE_CENTER_X - (142 - LINE_CENTER_X), 65
.word LINE_CENTER_X - (141 - LINE_CENTER_X), 60
.word LINE_CENTER_X - (139 - LINE_CENTER_X), 55
.word LINE_CENTER_X - (138 - LINE_CENTER_X), 50
.word LINE_CENTER_X - (136 - LINE_CENTER_X), 44
.word LINE_CENTER_X - (133 - LINE_CENTER_X), 39
.word LINE_CENTER_X - (129 - LINE_CENTER_X), 33
.word LINE_CENTER_X - (125 - LINE_CENTER_X), 28
.word LINE_CENTER_X - (120 - LINE_CENTER_X), 23
.word LINE_CENTER_X - (114 - LINE_CENTER_X), 19
.word LINE_CENTER_X - (109 - LINE_CENTER_X), 16
.word LINE_CENTER_X - (103 - LINE_CENTER_X), 15

CLOCKHAND_DOTS_END:

DANGLING1_GFX:
        .incbin "build/clock3/dangling1.raw"
DANGLING1_GFX_END:
DANGLING2_GFX:
        .incbin "build/clock3/dangling2.raw"

CLOCK_GFX:
        .incbin "build/clock3/clock3.raw"
CLOCK_GFX_END:
