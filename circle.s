#------------------------------------------------------------
#
#   FAST CIRCLE DRAW BY KUVO, CSI, 02020
#
#   COMPILER:   PDPy11
#   PLATFORM:   BK-00011(010)
#
#-------------------------------------------------------------

#       MOV  $01330, @$0177664 
#       MOV  $017400, @$0177716

#       MOV  $040000, R0
#       MOV  R0, R1
#   10$:CLR  (R0)+
#       SOB  R1, 10$

CIRCLE.MAIN_LOOP:
        CALL CIRCLE.GET_RND_VALUE
        BIC  $0177740, R0
        ADD  $010, R0
        MOV  R0, CIRCLE.RADIUS
        CALL CIRCLE.DRAW_CIRCLE

        #BR.

        CALL CIRCLE.GET_CENTER_COORD
        MOV  R0, CIRCLE.CENTER_Y
        CALL CIRCLE.GET_CENTER_COORD
        MOV  R0, CIRCLE.CENTER_X

        CALL CIRCLE.GET_RND_VALUE
        BIC  $0177774, R0
        CMP  R0, $3
        BNE  10$

        DEC  R0
    10$:ASL  R0
        ASL  R0
        ASL  R0
        ASL  R0
        ADD  $CIRCLE.DOTS, R0
        MOV  R0, CIRCLE.DOTS_BASE+2

        BR   CIRCLE.MAIN_LOOP

CIRCLE.GET_RND_VALUE:
       .equiv CIRCLE.RND_ACCUM, .+2
        MOV  $012345, R0
        ASL  R0
        BCS  10$
        MOV  $645, R1
        XOR  R1, R0
    10$:MOV  R0, CIRCLE.RND_ACCUM
        
        RETURN

CIRCLE.GET_CENTER_COORD:       
        CALL CIRCLE.GET_RND_VALUE
        BIC  $0177400, R0
        CMP  R0, $0324
        BLE  10$

        MOV  $0324, R0
    10$:CMP  R0, $054
        BGE  1$

        MOV  $054, R0
    1$: RETURN

CIRCLE.DRAW_CIRCLE:
       .equiv CIRCLE.RADIUS, .+2
        MOV  $0, R1
        MOV  R1, R3
        MOV  R1, R5
        ASL  R5
        CLR  R4
        CLR  R0          #Y

    CIRCLE.CIRCLE_LOOP:
        PUSH R0
        PUSH R1
        CALL CIRCLE.DRAW_DOTS
        MOV  R0, R2
        MOV  R1, R0
        MOV  R2, R1
        CALL CIRCLE.DRAW_DOTS
        POP  R1
        POP  R0

        SUB  $2, R4
        ADD  R4, R3
        BCS  10$

        TST  -(R5)
        ADD  R5, R3
        DEC  R1          #NEXT X

    10$:INC  R0          #NEXT Y
        
        CMP  R0, R1
        BLO  CIRCLE.CIRCLE_LOOP

CIRCLE.DRAW_DOTS:
        PUSH R3
        CALL CIRCLE.DRAW_DOT
        NEG  R1
        CALL CIRCLE.DRAW_DOT
        NEG  R0
        CALL CIRCLE.DRAW_DOT
        NEG  R1
        CALL CIRCLE.DRAW_DOT
        POP  R3

        RETURN

CIRCLE.DRAW_DOT:
       .equiv CIRCLE.CENTER_Y, .+2
        MOV  $0200, R2
        ADD  R1, R2
        SWAB R2
       .equiv CIRCLE.CENTER_X, .+2
        MOV  $0200, R3
        ADD  R0, R3
        BIS  R3, R2
        CLC
        ROR  R2
        ASR  R2
        ADD  $FB0, R2 # ADD  $040000, R2
        BIC  $0177770, R3
        ASL  R3
        BIC  CIRCLE.DOTS+040(R3), (R2)
    DOTS_BASE:
        BIS  CIRCLE.DOTS(R3), (R2)

        RETURN

CIRCLE.DOTS:
       .word 0b0000000000000001 # .word 0b0000000000000001
       .word 0b0000000000000010 # .word 0b0000000000000100
       .word 0b0000000000000100 # .word 0b0000000000010000
       .word 0b0000000000001000 # .word 0b0000000001000000
       .word 0b0000000000010000 # .word 0b0000000100000000
       .word 0b0000000000100000 # .word 0b0000010000000000
       .word 0b0000000001000000 # .word 0b0001000000000000
       .word 0b0000000010000000 # .word 0b0100000000000000

       .word 0b0000000100000000 # .word 0b0000000000000010
       .word 0b0000001000000000 # .word 0b0000000000001000
       .word 0b0000010000000000 # .word 0b0000000000100000
       .word 0b0000100000000000 # .word 0b0000000010000000
       .word 0b0001000000000000 # .word 0b0000001000000000
       .word 0b0010000000000000 # .word 0b0000100000000000
       .word 0b0100000000000000 # .word 0b0010000000000000
       .word 0b1000000000000000 # .word 0b1000000000000000

       .word 0b0000000100000001 # .word 0b0000000000000011
       .word 0b0000001000000010 # .word 0b0000000000001100
       .word 0b0000010000000100 # .word 0b0000000000110000
       .word 0b0000100000001000 # .word 0b0000000011000000
       .word 0b0001000000010000 # .word 0b0000001100000000
       .word 0b0010000000100000 # .word 0b0000110000000000
       .word 0b0100000001000000 # .word 0b0011000000000000
       .word 0b1000000010000000 # .word 0b1100000000000000
