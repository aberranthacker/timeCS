       .list

       .title Loader

       .include "hwdefs.s"
       .include "macros.s"
       .include "defs.s"

       .global start


       .=LOADER_START

start:
        MTPS $PR0
        MOV  $0xE000,SP
      # clear screen
        MOV  $FB_SIZE,R1
        MOV  $FB0,R5
        100$:
           .rept 1
            CLR  (R5)+
           .endr
        SOB  R1,100$
      # display logo 128x48 (16 words wide)
       .set X_OFFSET, 64 >> 2 + 8
       .set Y_OFFSET, 104 * LINE_WIDTHB
        MOV  $FB0 + X_OFFSET + Y_OFFSET, R5
        MOV  $gfx_c2ay_toyhifi,R4
        MOV  $48,R1 # logo height
        200$:
           .rept 16
            MOV  (R4)+,(R5)+
           .endr
            ADD  $LINE_WIDTHB - (128 >> 2),R5
        SOB  R1,200$

       .ppudo $PPU.SetPalette, $title_palette

        MOV  $32,R2
        MOV  $9,R3
        ASL  R3

        CALL DIV_FUNC
        # R2 - 0
        # R3 - 9
        # R4 - 3
        # R5 - 5
        MOV R4, progress_bar_arg
        CALL DIV_FUNC + 2 # skip R5 clearing
        # R4 - 0107070 36408 0x8E38
        # R5 - 8
        MOV R4, progress_bar_arg + 4
        MOV R4, progress_bar_arg + 6

        MOV  $10,R1
    300$:
        MOV  $100,R2
    400$:
        WAIT
        SOB  R2,400$

        CALL PROGRESS_BAR_DISPLAY
        SOB  R1,300$

        BR  .

        # R2 - dividend
        # R3 - divisor
        # R4 - quotient
        # R5 - remainder
DIV_FUNC:
        CLR R5
        CLR R4
        TST R3
        BEQ 2$

        INC R4
  0$:   ASL R2
        ROL R5
        CMP R5, R3
        BLO 1$

        SUB R3, R5
        SEC
        ROL R4
        BCC 0$

        RETURN

  1$:   ASL R4
        BCC 0$

  2$:   RETURN

PROGRESS_BAR_DISPLAY:
        PUSH R0
        PUSH R1
        PUSH R2
        PUSH R3
        PUSH R4
        PUSH R5

# | 3 | x | 36408 | 36408 |
# | 3 | 4 | 36408 |  7280 |
        MOV  $progress_bar_arg, R4
        ADD  (R4)+, (R4)
        MOV  (R4)+, R1
        ADD  (R4)+, (R4)
        ADC  R1
        MOV  R1, -4(R4)

       .set X_OFFSET, 64 >> 2 + 8
       .set Y_OFFSET, 160 * LINE_WIDTHB
        MOV  $FB0 + X_OFFSET + Y_OFFSET, R0
        MOV  $4, R2
        MOV  $0x0007, R4
        0$: # lines loop
            PUSH R0
            MOV  $0b1010101010101010,R5
            MOV  R1, R3
            1$: 
                BCC  2$
                BIS  $0x0070,(R0)+
                ASL  R5
            SOB  R3, 1$
            BR  3$

                2$:
                BIS  $0x0007,(R0)
                ASL  R5
            SOB  R3, 1$

        3$:
            POP  R0
            ADD  $LINE_WIDTHB, R0
        SOB  R2, 0$

        POP  R5
        POP  R4
        POP  R3
        POP  R2
        POP  R1
        POP  R0

        RETURN

title_palette: #----------------------------------------------------------------
    .word      0, setCursorScalePalette, cursorGraphic, scale320 | rGB
    .word      1, setColors; .byte Black, brRed, brGreen, White
    .word 128+ 6, setCursorScalePalette, cursorGraphic, scale320 | RGB
    .word 128+10, setColors; .byte Black, Red, Green, Gray
    .word 128+19, setColors; .byte Black, brRed, Green, Gray
    .word untilEndOfScreen
#-------------------------------------------------------------------------------
progress_bar_arg: .space 4 * 2
gfx_c2ay_toyhifi: .incbin "build/c2ay_toyhifi.raw"

end:
