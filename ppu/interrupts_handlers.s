DummyInterruptHandler: #-------------------------------------------------------
        RTI

Trap4: .equiv Trap4Detected, .+4
        MOV  $0xFFFF,$0
        RTI

VblankIntHandler: #----------------------------------------------------------{{{
       .equiv VblankInt_SkipMusic, .+2
        TST  $1
        BNZ  VblankInt_MinimalHandler # skip while floppy disk IO in progress

        MOV  @$PBPADR,-(SP)
        MOV  R5,-(SP)
        MOV  R4,-(SP)
        MOV  R3,-(SP)
        MOV  R2,-(SP)
        MOV  R1,-(SP)
        MOV  R0,-(SP)

       .equiv PLAY_NOW, .+2
        TST  $0
        BZE  VblankInt_Finalize

       .equiv PlayMusicProc, .+2
        CALL @$NULL

VblankInt_Finalize:
        MOV  (SP)+,R0
        MOV  (SP)+,R1
        MOV  (SP)+,R2
        MOV  (SP)+,R3
        MOV  (SP)+,R4
        MOV  (SP)+,R5
        MOV  (SP)+,@$PBPADR

VblankInt_MinimalHandler:
      # we do not need firmware interrupt handler except for this small
      # procedure
        TST  @$07130 # is floppy drive spindle rotating?
        BZE  1237$   # no
        DEC  @$07130 # decrease spindle rotation counter
        BNZ  1237$   # continue rotation unless the counter reaches zero
        CALL @07132  # stop floppy drive spindle

1237$:  RTI
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
        MOV  R0,-(SP)
        MOV  R1,-(SP)
        MOV  @$PBPADR,-(SP)

1237$:
        MOV  (SP)+,@$PBPADR
        MOV  (SP)+,R1
        MOV  (SP)+,R0
        RTI
#----------------------------------------------------------------------------}}}

Channel0In_IntHandler: #-----------------------------------------------------{{{
        MOV  @$PBPADR,-(SP)
        MOV  R5,-(SP)

        MOV  @$CommandsQueue_CurrentPosition,R5
   .ifdef DebugMode
        CMP  R5,$CommandsQueue_Top
        BLOS CommandsQueue_Full
   .endif
        MOV  $CPU_PPUCommandArg,@$PBPADR
        MOV  @$PBP12D,-(R5)
        MTPS $PR7
        MOV  @$PCH0ID,-(R5)
       .equiv CommandsQueue_CurrentPosition, .+2
        MOV  R5,$CommandsQueue_Bottom
        MTPS $PR0

        MOV  (SP)+,R5
        MOV  (SP)+,@$PBPADR

        RTI
CommandsQueue_Full:
        BR   .
        NOP
#----------------------------------------------------------------------------}}}

Channel1In_IntHandler: #-----------------------------------------------------{{{
        MTPS $PR7
        PUSH R0
        PUSH R4
        PUSH R5
        PUSH @$PBPADR

        TSTB @$PCH1ID
        BZE  ShowFB0
        BR   ShowFB1
ShowFB0: #----------------------------------------------------------------------
       .equiv FB0_FirstRecAddr, .+2
        MOV  $0,R0
        BR   SetFBAddr
#-------------------------------------------------------------------------------
ShowFB1: #----------------------------------------------------------------------
       .equiv FB1_FirstRecAddr, .+2
        MOV  $0,R0
#-------------------------------------------------------------------------------
SetFBAddr:
        MOV  $PBP0DT,R4
        MOV  $PBPADR,R5

       .equiv MainScreenFirstRecAddr, .+2
        MOV  $0,(R5)
        BIS  $0b0110,R0
        MOVB R0,(R4)
        INC  (R5)
        SWAB R0
        MOVB R0,(R4)

        POP  @$PBPADR
        POP  R5
        POP  R4
        POP  R0
        MTPS $PR0

        RTI
#----------------------------------------------------------------------------}}}
