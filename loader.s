       .list

       .title Loader

       .include "hwdefs.s"
       .include "macros.s"
       .include "defs.s"

       .global start

       .=LOADER_START

start:
        MTPS $PR0
      # clear screen
        MOV  $FB_SIZE_WORDS + 4,R1
        MOV  $FB0 - 8,R5
        100$:
           .rept 1
            CLR  (R5)+
           .endr
        SOB  R1,100$
      # display logo 128x48 (16 words wide)
       .set X_OFFSET, 64 >> 2
       .set Y_OFFSET, 104 * LINE_WIDTHB
        MOV  $FB0 + X_OFFSET + Y_OFFSET, R5
        MOV  $gfx_c2ay_toyhifi,R4
        MOV  $48,R1 # logo height
       .ppudo $PPU.SetPalette, $loader_palette

        200$:
           .rept 16
            MOV  (R4)+,(R5)+
           .endr
            ADD  $LINE_WIDTHB - (128 >> 2),R5
        SOB  R1,200$

        RETURN

loader_palette: #---------------------------------------------------------------
    .word      0, setOffscreenColors
    .word         BLACK | BLUE  << 4 | BLACK << 8 | BLACK << 12
    .word         BLACK | BLACK << 4 | BLACK << 8 | BLACK << 12
    .word      0, setCursorScalePalette, cursorGraphic, scale320 | rGB
    .word      1, setColors; .byte Black, brRed, brGreen, White
    .word 128+ 6, setCursorScalePalette, cursorGraphic, scale320 | RGB
    .word 128+10, setColors; .byte Black, Red, Green, Gray
    .word 128+19, setColors; .byte Black, brRed, Green, Gray
    .word untilEndOfScreen
#-------------------------------------------------------------------------------
gfx_c2ay_toyhifi: .incbin "build/c2ay_toyhifi.raw"

end:
