       .equiv Stars.COUNT, 256
       .equiv Stars.SCREEN, FB1

        MOV  $Stars.SCREEN,R5
        MOV  $8000>>2,R1
        100$:
           .rept 4
            CLR  (R5)+
           .endr
        SOB  R1,100$

        MOV  $screen_lines_table,R5
        MOV  $0x4000,R0
        MOV  $200>>1,R1
        200$:
           .rept 2
            BIS  R0,(R5)+
           .endr
        SOB  R1,200$

        MOV  $Stars.COUNT,R3 # loop counter
        MOV  $Stars.stars,R4 # R4  x, y and speed pointer
Stars.add:
Stars.x_pos:
        CALL  Core.random_word
        CLR   R1
        BISB  R0,R1
        SWAB  R0
        BIC   $0xFFC0,R0
        ADD   R0,R1
        MOV   R1,(R4)+
Stars.y_pos:
        CALL Core.random_word
        CMPB R0,$200
        BHIS Stars.y_pos

        CLR  R2
        BISB R0,R2
        MOV  R2,(R4)+
Stars.layer:
        CALL  Core.random_word
        BIC   $0xFFF8,R0 # 0xFFF8 8 layers, 0xFFFC 4 layers

        INC   R0       # make sure speed isn't 0
        MOV   R0,(R4)+ # store speed

        CALL Stars.plot

        SOB  R3,Stars.add

Stars.move:
        MOV  $Stars.COUNT,R3
        MOV  $Stars.stars,R4
Stars.main_loop:
        MOV  (R4)+,R1 # get x pos
        MOV  (R4)+,R2 # get y pos

        CALL Stars.plot

        SUB  (R4)+,R1
        CMP  R1,$320
        BLO  Stars.no_overflow

        BIC  $0xFEC0,R1
    Stars.no_overflow:
        MOV  R1,-6(R4)

        CALL Stars.plot

        SOB  R3,Stars.main_loop

       #WAIT
       #WAIT
        BR   Stars.move

Stars.plot: # R2 - Y pos, R1 - X pos
        MOV  R2,R5
        ASL  R5
        MOV  screen_lines_table(R5),R5

        MOV  R1,R0
        ASR  R0
        ASR  R0
        ADD  R0,R5

        MOV  R1,R0
        BIC  $0xFFF8,R0
        ASL  R0
        MOV  Stars.bits(R0),R0

        XOR  R0,(R5)
        RETURN

Stars.stars: .space Stars.COUNT * 3 * 2
Stars.bits:  .word 0x0101, 0x0202, 0x0404, 0x0808, 0x1010, 0x2020, 0x4040, 0x8080
