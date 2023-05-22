       .list

       .title My First Demo Core Module

       .include "hwdefs.s"
       .include "macros.s"
       .include "core_defs.s"

       .global start


       .=CORE_START

start:
        MTPS $PR0
        MOV  $0xE000,SP
       .ppudo $PPU_SetPalette, $core_palette

       .include "stars.s"

#InfiniteLoop:
#        MOV  $FB0,R5
#        MOV  $8000,R2
#    FillFB0Loop:
#        CALL RandomWord
#        MOV  R0,(R5)+
#        SOB  R2,FillFB0Loop
#
#        MOV  $PPU_SET_FB0_VISIBLE,@$CCH1OD
#
#        MOV  $FB1,R5
#        MOV  $8000,R2
#    FillFB1Loop:
#        CALL RandomWord
#        MOV  R0,(R5)+
#        SOB  R2,FillFB1Loop
#
#        MOV  $PPU_SET_FB1_VISIBLE,@$CCH1OD
#
#        BR   InfiniteLoop
#

Core.random_word:
       .equiv Core.rseed1, .+2
        MOV $0xB7D9, R0
        ADD R0, R0
        BHI 1$
        ADD $39, R0
    1$:
        MOV R0, @$Core.rseed1
       .equiv Core.rseed2, .+2
        ADD $0xF61F, R0
        MOV R0, @$Core.rseed2
        RETURN

screen_lines_table: .screen_lines_table

core_palette: #-----------------------------------------------------------------
    .word   0, cursorGraphic, scale320 | RGB
    .byte   1, setColors, Black, Magenta, brCyan, brCyan
    .word untilEndOfScreen
#-------------------------------------------------------------------------------
end:
