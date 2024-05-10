PPU.DummyInterruptHandler: #----------------------------------------------------
        RTI

Trap4: .equiv Trap4Detected, .+4
        MOV  $0xFFFF,$0
        RTI

VblankIntHandler: #----------------------------------------------------------{{{
        PUSH R5
        PUSH R4
        PUSH R3
        PUSH R2
        PUSH R1
        PUSH R0
        PUSH @$PBPADR

        CALL TRandW

       .equiv PlayMusicProc, .+2
        CALL @$NULL

        CMP  @$PlayMusicProc, $psgplayer.MUS_PLAY
        BNE  VblankInt_Finalize

       .equiv FRAME_NUMBER, .+2
        INC  $-1

        CMP  FRAME_NUMBER, $50 * 2 # is it time to introduce glitches?
        BLO  VblankInt_Finalize

        CALL Glitch.RemoveStale

        CLR  R0
        MOV  FRAME_NUMBER, R1
       .equiv GlitchDivider, .+2
        DIV  $1, R0
        TST  R1
        BNZ  VblankInt_Finalize

        CALL  Glitch.Add

        CALL TRandW
        BIC  $0xFF80, R0 # random number 0..127
        ADD  $2, R0      # to avoid division by 0, and to reduce min delay
        MOV  R0, GlitchDivider

VblankInt_Finalize:
        POP @$PBPADR
        POP R0
        POP R1
        POP R2
        POP R3
        POP R4
        POP R5

VblankIntHandler.Minimal:
      # we do not need firmware interrupt handler except for this small
      # procedure
        TST  @$07130 # is floppy drive spindle rotating?
        BZE  1271$   # no, exit
        DEC  @$07130 # decrease spindle rotation counter
        BNZ  1271$   # continue rotation unless the counter reached zero
        CALL @07132  # stop floppy drive spindle

1271$:  RTI
       .include "ppu/glitch.s"
#----------------------------------------------------------------------------}}}

KeyboardIntHadler: #---------------------------------------------------------{{{
# key codes #-----------------------------------------------------{{{
# | oct | hex|  key    | note     | oct | hex|  key  |  note     |
# |-----+----+---------+----------+-----+----+-------+-----------|
# |   5 | 05 | ,       | NumPad   | 106 | 46 | АЛФ   | Alphabet  |
# |   6 | 06 | АР2     | Esc      | 107 | 47 | ФИКС  | Lock      |
# |   7 | 07 | ; / +   |          | 110 | 48 | Ч / ^ |           |
# |  10 | 08 | К1 / К6 | F1 / F6  | 111 | 49 | С / S |           |
# |  11 | 09 | К2 / К7 | F2 / F7  | 112 | 4A | М / M |           |
# |  12 | 0A | КЗ / К8 | F3 / F8  | 113 | 4B | SPACE |           |
# |  13 | 0B | 4 / ¤   |          | 114 | 4C | Т / T |           |
# |  14 | 0C | К4 / К9 | F4 / F9  | 115 | 4D | Ь / X |           |
# |  15 | 0D | К5 / К10| F5 / F10 | 116 | 4E | ←     |           |
# |  16 | 0E | 7 / '   |          | 117 | 4F | , / < |           |
# |  17 | 0F | 8 / (   |          | 125 | 55 | 7     | NumPad    |
# |  25 | 15 | -       | NumPad   | 126 | 56 | 0     | NumPad    |
# |  26 | 16 | ТАБ     | Tab      | 127 | 57 | 1     | NumPad    |
# |  27 | 17 | Й / J   |          | 130 | 58 | 4     | NumPad    |
# |  30 | 18 | 1 / !   |          | 131 | 59 | +     | NumPad    |
# |  31 | 19 | 2 / "   |          | 132 | 5A | ЗБ    | Backspace |
# |  32 | 1A | 3 / #   |          | 133 | 5B | →     |           |
# |  33 | 1B | Е / E   |          | 134 | 5C | ↓     |           |
# |  34 | 1C | 5 / %   |          | 135 | 5D | . / > |           |
# |  35 | 1D | 6 / &   |          | 136 | 5E | Э / \ |           |
# |  36 | 1E | Ш / [   |          | 137 | 5F | Ж / V |           |
# |  37 | 1F | Щ / ]   |          | 145 | 65 | 8     | NumPad    |
# |  46 | 26 | УПР     | Ctrl     | 146 | 66 | .     | NumPad    |
# |  47 | 27 | Ф / F   |          | 147 | 67 | 2     | NumPad    |
# |  50 | 28 | Ц / C   |          | 150 | 68 | 5     | NumPad    |
# |  51 | 29 | У / U   |          | 151 | 69 | ИСП   | Execute   |
# |  52 | 2A | К / K   |          | 152 | 6A | УСТ   | Settings  |
# |  53 | 2B | П / P   |          | 153 | 6B | ВВОД  | Enter     |
# |  54 | 2C | H / N   |          | 154 | 6C | ↑     |           |
# |  55 | 2D | Г / G   |          | 155 | 6D | : / * |           |
# |  56 | 2E | Л / L   |          | 156 | 6E | Х / H |           |
# |  57 | 2F | Д / D   |          | 157 | 6F | З / Z |           |
# |  66 | 36 | ГРАФ    | Graph    | 165 | 75 | 9     | NumPad    |
# |  67 | 37 | Я / Q   |          | 166 | 76 | ВВОД  | NumPad    |
# |  70 | 38 | Ы / Y   |          | 167 | 77 | 3     | NumPad    |
# |  71 | 39 | В / W   |          | 170 | 78 | 7     | NumPad    |
# |  72 | 3A | А / A   |          | 171 | 79 | СБРОС | Reset     |
# |  73 | 3B | И / I   |          | 172 | 7A | ПОМ   | Help      |
# |  74 | 3C | Р / R   |          | 173 | 7B | / / ? |           |
# |  75 | 3D | О / O   |          | 174 | 7C | Ъ / } |           |
# |  76 | 3E | Б / B   |          | 175 | 7D | - / = |           |
# |  77 | 3F | Ю / @   |          | 176 | 7E | О / } |           |
# | 105 | 45 | HP      | Shift    | 177 | 7F | 9 / ) |           |
#-----------------------------------------------------------------}}}
        PUSH R0
        PUSH R1

        MOVB @$KBDATA, R0
        BMI  key_released

    # key pressed ------------------
        MOV  $key_presses_scan_codes,R1
       .rept 5 # number of keymaps
        CMPB R0,(R1)+
        BEQ  recognized_key
        INC  R1
       .endr
        BR 1237$

    key_presses_scan_codes:
       .byte 0153, KEYMAP_ENTER
       .byte 0166, KEYMAP_ENTER
       .byte 0113, KEYMAP_SPACE
       .byte 0134, KEYMAP_DOWN
       .byte 0154, KEYMAP_UP
       .even

    key_released:
        PUSH @$PBPADR
        MOV  $PPU_KeyboardScanner,@$PBPADR
        CLR  @$PBP12D
        POP  @$PBPADR
        BR 1237$

    recognized_key:
        PUSH @$PBPADR
        MOV  $PPU_KeyboardScanner, @$PBPADR
        BISB (R1), @$PBP12D
        POP  @$PBPADR

1237$:
        POP R1
        POP R0
        RTI
#----------------------------------------------------------------------------}}}
# Receives commands from CPU
Channel0In_IntHandler: #-----------------------------------------------------{{{
        PUSH R5

        MOV @$CommandsQueue_CurrentPosition, R5
   .ifdef DEBUG
        CMP R5, $CommandsQueue_Top
        BLOS CommandsQueue_Full
   .endif
        PUSH @$PBPADR
        MOV $CPU_PPUCommandArg, @$PBPADR
        MOV @$PBP12D, -(R5)
        POP  @$PBPADR
        MOV @$PCH0ID, -(R5)
       .equiv CommandsQueue_CurrentPosition, .+2
        MOV R5, $CommandsQueue_Bottom

        POP  R5

        RTI
CommandsQueue_Full:
        BR   .
#----------------------------------------------------------------------------}}}
# Sets framebuffer
Channel1In_IntHandler: #-----------------------------------------------------{{{
        PUSH R0

        TSTB @$PCH1ID
        BZE show_FB0

    show_FB1:
       .equiv FB1_FirstRecAddr, .+2
        MOV $0,R0
        BR set_FB_addr

    show_FB0:
       .equiv FB0_FirstRecAddr, .+2
        MOV  $0,R0

    set_FB_addr:
        PUSH @$PBPADR
       .equiv MainScreenFirstRecAddr, .+2
        MOV $0, @$PBPADR
        BIS $0b0110, R0
        MOVB R0, @$PBP0DT
        INC @$PBPADR
        SWAB R0
        MOVB R0, @$PBP0DT
        POP @$PBPADR

        POP  R0

        RTI
#----------------------------------------------------------------------------}}}
