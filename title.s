#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' (PART 1 'TITLE') 6-channel (2AY) music only!
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

           .global start
           .global f7001.lzsa
           .global f7002.lzsa
           .global f7003.lzsa
           .global f7004.lzsa
           .global w3.raw.lzsa
           .global Title.PLAY_NOW

           .=TITLE_START
start:
# INIT ----------------------------------------------------------------------{{{
        MTPS $PR0

        CALL PROGRESS_BAR_DISPLAY

        MOV  $f7001.lzsa,R0
        MOV  $0100000,@$CBPADR
        CALL LoadPSGP

        MOV  $f7002.lzsa,R0
        CALL LoadPSGP

        MOV  $f7003.lzsa,R0
        MOV  $0100000,@$CBPADR
        MOV  $CBP2DT,@$LoadPSGP.DataReg
        CALL LoadPSGP

        MOV  $f7004.lzsa,R0
        CALL LoadPSGP

        MOV  $w3.raw.lzsa,R0
        CALL DiskRead_Start
        CALL DiskIO_WaitForFinish
        CALL PROGRESS_BAR_DISPLAY

        MOV  $GFX_W3, R1
        MOV  $FB1, R2
        CALL LZSA_UNPACK
        CALL PROGRESS_BAR_DISPLAY

        CALL CLOCKHANDS_GFX_PREP

        CALL GFX_timeCS_PREP

        MOV  $TIKTAK, @$0100
        CALL PROGRESS_BAR_DISPLAY

        MOV  $(FB_SIZE_WORDS + 4) >> 2,R1
        MOV  $FB0-8,R5
        100$:
           .rept 4
            CLR  (R5)+
           .endr
        SOB  R1,100$
       .ppudo_ensure $PPU.SetPalette, $title_palette

        CALL MOSAIC

        MOV $PIC_OFFSET_SCRIPT, R5
    3$: MOV (R5)+, R0
        BZE PREP_MAIN_LOOP

        MOV (R5)+, R1
        MOV (R5)+, R2
        4$:
            MOV R0, R3
            MOV R1, R4
            5$:
                MOV (R3)+, -4(R3)
            SOB R4, 5$

            ADD $64+8, R0
        SOB R2, 4$

        BR 3$

PIC_OFFSET_SCRIPT:
       # src, inner loop count, outer loop count
        .word FB1 + ( 32 >> 2) + (216 * LINE_WIDTHB), 72 >> 3, 40
        .word FB1 + ( 32 >> 2) + (200 * LINE_WIDTHB), 40 >> 3, 16
        .word FB1 + ( 32 >> 2) + (184 * LINE_WIDTHB), 24 >> 3, 16
        .word FB1 + (  8 >> 2) + (  0 * LINE_WIDTHB), 24 >> 3, 48
        .word FB1 + (200 >> 2) + (  0 * LINE_WIDTHB), 40 >> 3, 40
        .word FB1 + (200 >> 2) + (205 * LINE_WIDTHB), 32 >> 3, 47
        .word 0

PREP_MAIN_LOOP:
        WAIT
       .ppudo_ensure $PPU.PSGP_Player.Init
        WAIT
       .ppudo_ensure $PPU.PSGP_Player.Play
        WAIT
# INIT ----------------------------------------------------------------------}}}

MAIN_LOOP:
        TST Title.PLAY_NOW
        BNZ 10$

   100$:JMP END_OF_PART

    10$:CMP FRAME_NUMBER, $9858
        BGE 100$

        TST @$KeyboardScanner # is a key was pressed?
        BZE 1$                # no, continue
        CLR Title.PLAY_NOW    # yes, stop playing

    1$: CALL DISPLAY_timeCS
        CALL DISPLAY_CLOCK

        CMP  FRAME_NUMBER, $768
        BLO  2$

        MOV  $2, DUMMY1       # increment
        MOV  $044, DUMMY1 + 4 # max value
        MOV  $2, DUMMY2       # replace end of table marker with increment

       .equiv DOTS_OFFSET, .+2
    2$: MOV  $0, R0
        ADD  $020, R0
       .equiv DOTS_SIZE, DOTS_END - DOTS
        CMP  R0, $DOTS_SIZE # at the end of the DOTS?
        BLO  3$             # no, continue
        CLR  R0             # yes, reset the offset

    3$: MOV  R0, DOTS_OFFSET

        ADD  $DOTS, R0
        MOV  R0, DOTS_ADDR_PLUS_OFFSET

DISPLAY_CIRCLES:
        MOV  $TUNNEL, R4

   100$:MOV  (R4)+, R0  # increment -> R0
        BZE  MAIN_LOOP

        ADD  R0, (R4)   # current_value += increment
        MOV  (R4)+, R1  # current_value -> R1

        CMP  R1, (R4)+  # current_value reached max_value?
        BLO  1$         # no, continue
        MOV  (R4), R1   # yes, max_value -> R1

    1$: TST  (R4)+      # advance pointer to FB offset
        MOV  R1, -6(R4) # store update current_value
        MOV  (R4)+, CIRCLE_FORMER # FB offset -> CIRCLE_FORMER
        CALL DRAW_CIRCLE_OPER
        BR 100$

TUNNEL:
    DUMMY1:# increment, current_value, max_value, value_reset, FB offset
       .word         3,           026,       040,         026, LINE_WIDTHB * 40
    DUMMY2:
       .word         0,           032,       040,         032, LINE_WIDTHB * 36
       .word         3,           040,       052,         040, LINE_WIDTHB * 32
       .word         5,           046,       062,         046, LINE_WIDTHB * 32
TUNNEL_END:
        .word 0 # end of data marker

DRAW_CIRCLE_OPER: #----------------------------------------------------------{{{
            MOV  $PPU.SET_FB0_VISIBLE,@$CCH1OD
            PUSH R4
            PUSH R5
            CALL DRAW_CIRCLE
            POP  R5
            POP  R4

            CLR  R0
            BISB @BK11_PALETTE_IDX, R0
            BZE  1237$

            ASLB R0
            BCC  1237$

            MOV  $PPU.SET_FB1_VISIBLE,@$CCH1OD
1237$:
            RETURN

DRAW_CIRCLE:
            CLR  R0
            CLR  R4
            MOV  R1, R3
            ASL  R3
            MOV  R3, R5
    CIRCLE_LOOP:
           .equiv CIRCLE_FORMER, .+2
            SUB  $LINE_WIDTHB * 36, R4 # 04400
            ADD  R4, R3
            BCS  10$

            TST  -(R5)
            ADD  R5, R3
            DEC  R1
        10$:PUSH R0
            PUSH R1
            COM  $0
            BZE  1$

            CALL DRAW_DOTS
            BR   2$

        1$: MOV  R0, R2
            MOV  R1, R0
            MOV  R2, R1
            CALL DRAW_DOTS
        2$: POP  R1
            POP  R0
            INC  R0
            MOV  R0, R2
            INC  R2
            CMP  R2, R1
            BLE CIRCLE_LOOP

DRAW_DOTS:
            CALL DRAW_DOT
            NEG  R1
            CALL DRAW_DOT
            NEG  R0
            CALL DRAW_DOT
            NEG  R1
DRAW_DOT:
            PUSH R3
            MOV  $64, R2 # X
            MOV  R2, R3  # Y
            ADD  R1, R3
            MUL  $LINE_WIDTHW * 8, R3

            ADD  R0, R2
            ADD  R2, R3
            ASR  R3

            ADD  $FB0 + LINE_WIDTHB * 8, R3 # 041000
    SCREEN_ADDER:
            BR   1$ # will be replaced with NOP by END_OF_PART

            MOV  FB_SIZE + FIRST_LINE_OFFSET(R3), (R3)
           .set offset, LINE_WIDTHB * 2
            MOV  FB_SIZE + FIRST_LINE_OFFSET + offset(R3), offset(R3)
            MOV  FB_SIZE + FIRST_LINE_OFFSET - offset(R3), -offset(R3)
            MOV  FB_SIZE + FIRST_LINE_OFFSET + 2(R3), 2(R3)
            BR   DRAW_DOT_EXIT

        1$: BIC  $0177770, R2
            ASL  R2

           .equiv DOTS_ADDR_PLUS_OFFSET, .+2
            MOV  DOTS(R2), R2
            XOR  R2, (R3)
            XOR  R2, 2(R3)

    DRAW_DOT_EXIT:
            POP  R3
            RETURN
DOTS:
       .word 0b0000000000000001
       .word 0b0000000000000010
       .word 0b0000000000000100
       .word 0b0000000000001000
       .word 0b0000000000010000
       .word 0b0000000000100000
       .word 0b0000000001000000
       .word 0b0000000010000000

       .word 0b0000000100000000
       .word 0b0000001000000000
       .word 0b0000010000000000
       .word 0b0000100000000000
       .word 0b0001000000000000
       .word 0b0010000000000000
       .word 0b0100000000000000
       .word 0b1000000000000000

       .word 0b0000000100000001
       .word 0b0000001000000010
       .word 0b0000010000000100
       .word 0b0000100000001000
       .word 0b0001000000010000
       .word 0b0010000000100000
       .word 0b0100000001000000
       .word 0b1000000010000000
DOTS_END: #------------------------------------------------------------------}}}

MOSAIC: #--------------------------------------------------------------------{{{
        MOV  $FB0-8,R5
        MOV  $GFX_W3, R4
        MOV  $BLOCKS_SCRIPT, R3
        MOV  $64,R2
    10$:MOV  (R3)+, R0
        BZE  4$

        1$:
            WAIT
            ADD  (R3), R5
            PUSH R5

            MOV  $32,R1
            3$:
                .rept 4
                 MOV FB1_OFFSET(R5),(R5)+
                .endr
                 ADD R2,R5
            SOB  R1,3$

            POP  R5
        SOB  R0,1$

        INC  R3
        INC  R3
        BR   10$

    4$: RETURN

BLOCKS_SCRIPT:
       .word   8,     8
       .word   7,  2048 + 32 * 8
       .word   7,    -8
       .word   6, -2048 - 32 * 8
       .word   6,     8
       .word   5,  2048 + 32 * 8
       .word   5,    -8
       .word   4, -2048 - 32 * 8
       .word   4,     8
       .word   3,  2048 + 32 * 8
       .word   3,    -8
       .word   2, -2048 - 32 * 8
       .word   2,     8
       .word   1,  2048 + 32 * 8
       .word   1,    -8
       .word   0
# MOSAIC --------------------------------------------------------------------}}}

DISPLAY_timeCS: #------------------------------------------------------------{{{
       .equiv NEXT_FRAME_NUMBER_A, .+4
        CMP  FRAME_NUMBER, $384 >> 1
        BLT  1237$

        CMP  FRAME_NUMBER, $9792
        BGE  1237$

       .equiv SCREEN_LOCATION_timeCS_IDX, .+2
        MOV  $SCREEN_LOCATION_timeCS, R5

       .equiv NEXT_FRAME_NUMBER_B, .+4
        CMP  FRAME_NUMBER, $384 >> 1
        BLT  1237$

        ADD  $12, NEXT_FRAME_NUMBER_B

        MOV  (R5)+, R0
        BNZ  1$

        ADD $192, NEXT_FRAME_NUMBER_A
        MOV $SCREEN_LOCATION_timeCS, SCREEN_LOCATION_timeCS_IDX
1237$:  RETURN

    1$: MOV (R5)+, R2
        MOV (R5)+, R3
        MOV R5, SCREEN_LOCATION_timeCS_IDX

       .equiv COLOR_timeCS_ADDR, .+2
        MOV  $BLUE_timeCS, R1
        CMP  R1, $BLUE_timeCS + GFX_timeCS_SIZE
        BLO  2$

        MOV  $RED_timeCS, R1

       .equiv COLOR_timeCS_MASK_ADDR, .+2
    2$: MOV  $GFX_timeCS_MASK, R4
        CMP  R4, $GFX_timeCS_MASK + GFX_timeCS_SIZE
        BLO  3$

        MOV  $GFX_timeCS_MASK, R4

        3$:
            PUSH R0
            MOV  R2, R5
            4$:
                BIC  (R4)+, (R0)
                BIS  (R1)+, (R0)+
            SOB  R5, 4$
            POP  R0
            ADD  $LINE_WIDTHB, R0
        SOB  R3, 3$

        CMP FRAME_NUMBER, $768-192
        BGE 5$

        CMP R1, $BLUE_timeCS + GFX_timeCS_SIZE
        BLO 5$
        MOV $BLUE_timeCS, R1

    5$: MOV R4, COLOR_timeCS_MASK_ADDR
        MOV R1, COLOR_timeCS_ADDR

        RETURN

SCREEN_LOCATION_timeCS:
       .word FB0 + 0 + (LINE_WIDTHB * 109), 32 >> 3, 16
       .word FB0 + 0 + (LINE_WIDTHB *  99), 32 >> 3, 18
       .word FB0 + 2 + (LINE_WIDTHB *  81), 32 >> 3, 27
       .word FB0 + 4 + (LINE_WIDTHB *  66), 24 >> 3, 19
       .word FB0 + 2 + (LINE_WIDTHB *  32), 48 >> 3, 43
       .word FB0 + 6 + (LINE_WIDTHB *   8), 40 >> 3, 46
       .word 0
# DISPLAY_timeCS ------------------------------------------------------------}}}

DISPLAY_CLOCK: #-------------------------------------------------------------{{{
       .equiv DISPLAY_CLOCK.next_frame_number, .+4
        CMP  FRAME_NUMBER, $6
        BLO  1237$

        ADD  $6, DISPLAY_CLOCK.next_frame_number

        MOV  $CLOCKHANDS_DATA, R5
    10$:MOV  (R5)+, R1
        BZE  3$

    1$: ADD  $64, R1
        CMP  R1, (R5)+
        BLO  2$

        MOV  (R5)+, -6(R5)
        BR   10$

    2$: MOV  R1, -4(R5)

    3$: MOV  $FB1 + (224 >> 2) + (LINE_WIDTHB * 210), R1
        MOV  $CLOCKHAND_BUFFER, R0
        MOV  $020, R2
        MOV  $LINE_WIDTHB - 4, R3
        4$:
            MOV  (R1)+, (R0)+
            MOV  (R1)+, (R0)+
            ADD  R3, R1
        SOB  R2, 4$

        MOV  $CLOCKHANDS_DATA, R5
    5$: MOV  (R5), R1
        BEQ  7$

        MOV  $CLOCKHAND_BUFFER, R0
        MOV  $040, R2
        6$:
            BIC  (R1)+, (R0)+
        SOB  R2, 6$

        ADD  $6, R5
        BR   5$

    7$: MOV  $FB0 + (224 >> 2) + (LINE_WIDTHB * 210), R0
        MOV  $CLOCKHAND_BUFFER, R1
        MOV  $020, R2
        8$:
            MOV  (R1)+, (R0)+
            MOV  (R1)+, (R0)+
            ADD  R3, R0
        SOB  R2, 8$

1237$:  RETURN

CLOCKHANDS_DATA:
       .word CLOCKHAND_SEC + 0500,         CLOCKHAND_SEC  + CLOCKHAND_SIZE, CLOCKHAND_SEC
       .word CLOCKHAND_MIN + 01400 - 0500, CLOCKHAND_MIN  + CLOCKHAND_SIZE, CLOCKHAND_MIN
       .word CLOCKHAND_HOUR,               CLOCKHAND_HOUR + CLOCKHAND_SIZE, CLOCKHAND_HOUR
       .word 0
# DISPLAY_CLOCK -------------------------------------------------------------}}}

END_OF_PART: #---------------------------------------------------------------{{{
        TST Title.PLAY_NOW
        BNZ 100$

       .ppudo_ensure $PPU.PT3Play.Stop

   100$:
        MOV $NOP_OPCODE, SCREEN_ADDER
        MOV $061, R5
        MOV $LINE_WIDTHB * 36, R4 # 04400
        TST DUMMY2
        BNE 10$

        MOV $042, R5
    10$:MOV R5, R1
        MOV R4, CIRCLE_FORMER
        CALL DRAW_CIRCLE_OPER
        SUB $020, R4
        DEC R5
        DEC R5
        BMI 1$
        BNE 10$

    1$:
        MOV $FB1, R0
        MOV $FB_SIZE, R1
        2$:
            ASLB (R0)
            CLRB (R0)+
        SOB R1, 2$

        CALL MOSAIC

    3$: TST Title.PLAY_NOW
        BNZ 3$

        MOV $DUMMY_INTERRUPT_HANDLER, @$0100
       .ppudo_ensure $PPU.PT3Play.Stop
        RETURN
# END_OF_PART ---------------------------------------------------------------}}}

TIKTAK: #--------------------------------------------------------------------{{{
        MOV  R0, -(SP)
        MOV  R1, -(SP)
        MOV  R2, -(SP)
        MOV  R3, -(SP)
        MOV  R4, -(SP)
        MOV  R5, -(SP)

       .equiv Title.PLAY_NOW, .+2
        TST  $0 # updated by PPU, at least supposed to
        BZE  TIKTAK_EXIT

       .equiv FRAME_NUMBER, .+2
        INC  $-1

      .equiv PALETTE_CHANGE_NEXT_FRAME_NUMBER, .+4
        CMP  FRAME_NUMBER, $68
        BLO  TIKTAK_EXIT

        CMP  FRAME_NUMBER, $9840
        BGE  TIKTAK_EXIT

        ADD  $96-18, PALETTE_CHANGE_NEXT_FRAME_NUMBER
       .equiv BK11_PALETTE_IDX, .+2
        MOV  $PALETTES_FOR_CHANGE, R1
    1$: CLR  R0
        BISB (R1)+, R0
        BNZ  2$

        MOV  $PALETTES_FOR_CHANGE, R1
        BR   1$

    2$: MOV  R1, BK11_PALETTE_IDX

        CALL SetBKPaletteFromR0

    TIKTAK_EXIT:
        MOV  (SP)+, R5
        MOV  (SP)+, R4
        MOV  (SP)+, R3
        MOV  (SP)+, R2
        MOV  (SP)+, R1
        MOV  (SP)+, R0

        RTI

SetBKPaletteFromR0:
        ASLB R0
        BCS  SwithToFB1

        MOV  $PPU.SET_FB0_VISIBLE,@$CCH1OD
        BR   1237$

    SwithToFB1:
        MOV  $PPU.SET_FB1_VISIBLE,@$CCH1OD
        MOV  palettes_table(R0),@$PPUCommandArg
       .ppudo_ensure $PPU.SetPaletteFB1
       #MOVB R0, @$0177663
1237$:
        RETURN

PALETTES_FOR_CHANGE:
    .byte  014,  014,  014, 0215,  014,  014, 0216, 014
    .byte 0203,  014, 0201,  014 , 014,  014, 0202, 014
    .byte  014,  014, 0204,  014, 0203, 0203,  014, 014
    .byte 0216,  014, 0205,  014,  014, 0206, 0207, 014
    .byte  014, 0205, 0205,    0
    .even
# TIKTAK --------------------------------------------------------------------}}}
palettes_table:
    .word palette_014 # palette_00
    .word palette_01
    .word palette_02
    .word palette_03
    .word palette_04
    .word palette_05
    .word palette_06
    .word palette_07
    .word palette_014 # palette_010
    .word palette_014 # palette_011
    .word palette_014 # palette_012
    .word palette_014 # palette_013
    .word palette_014
    .word palette_015
    .word palette_016

palette_01:
    .word      1, setColors; .byte Black, brBlue, brGreen, brRed
    .word untilEndOfScreen
palette_02:
    .word      1, setColors; .byte Black, brCyan, brBlue, brMagenta
    .word untilEndOfScreen
palette_03:
    .word      1, setColors; .byte Black, brGreen, brCyan, brYellow
    .word untilEndOfScreen
palette_04:
    .word      1, setColors; .byte Black, brMagenta, brCyan, White
    .word untilEndOfScreen
palette_05:
    .word      1, setColors; .byte Black, White, White, White
    .word untilEndOfScreen
palette_06:
    .word      1, setColors; .byte Black, brRed, brRed, brRed
    .word untilEndOfScreen
palette_07:
    .word      1, setColors; .byte Black, brGreen, brGreen, brGreen
    .word untilEndOfScreen
palette_014:
    .word      1, setColors; .byte Black, brRed, brGreen, brCyan
    .word untilEndOfScreen
palette_015:
    .word      1, setColors; .byte Black, brCyan, brYellow, White
    .word untilEndOfScreen
palette_016:
    .word      1, setColors; .byte Black, brYellow, brGreen, White
    .word untilEndOfScreen

# Creates three sets of 2-bit sprites from a set of 1-bit sprites
GFX_timeCS_PREP: #-----------------------------------------------------------{{{
        MOV $RED_timeCS, R3
        MOV $GREEN_timeCS, R4
        MOV $BLUE_timeCS, R5
        MOV $GFX_timeCS,R2
        MOV $GFX_timeCS_SIZE_WORDS, R1
        100$:
           CLR  R0
           BISB (R2),R0
           MOV  R0,(R5)+ # color number 1
           SWAB R0
           MOV  R0,(R4)+ # color number 2
           BISB (R2)+,R0
           MOV  R0,(R3)+ # color number 3
        SOB  R1,100$

        RETURN #-------------------------------------------------------------}}}

CLOCKHANDS_GFX_PREP: #-------------------------------------------------------{{{
        MOV  $CLOCKHAND_GFX_END, R1
        MOV  $CLOCKHANDS + CLOCKHAND_SIZE, R0
        MOV  $CLOCKHAND_SIZE_WORDS, R2
        1$:
            MOVB -(R1),R3
            MOVB R3,-(R0)
            MOVB R3,-(R0)
        SOB  R2, 1$

        MOV $CLOCKHAND_SIZE_WORDS, R2
        MOV $CLOCKHAND_MIN, R3
        MOV $CLOCKHAND_HOUR, R4
        10$:
            MOV (R0), (R3)+
            MOV (R0)+, (R4)+
        SOB R2, 10$

        MOV  $0x0303, R4 # 0b0000_0011_0000_0011
        MOV  $0x8080, R5 # 0b1000_0000_1000_0000
        CALL CLOCKHAND_REDUCE

        INC  @$count_a
        INC  @$count_b

        MOV  $0x0707, R4 # 0b0000_0111_0000_0111
        MOV  $0xC0C0, R5 # 0b1100_0000_1100_0000

   CLOCKHAND_REDUCE:
        MOV $16, R1
        SUB @$count_a, R1
        SUB @$count_b, R1

        MOV $12, R3 # CLOCKHAND_COUNT

   NEXT_CLOCKHAND_PHASE:
       .equiv count_a, .+2
        MOV $2, R2
        10$:
            CLR (R0)+
            CLR (R0)+
        SOB R2, 10$

        MOV R1, R2
        1$:
            BIC  R4, (R0)+
            BIC  R5, (R0)+
        SOB R2, 1$

       .equiv count_b, .+2
        MOV $3, R2
        2$:
            CLR (R0)+
            CLR (R0)+
        SOB R2, 2$

        DEC  R3 # CLOCKHAND_COUNT
        BNE  NEXT_CLOCKHAND_PHASE
        RETURN #-------------------------------------------------------------}}}

PROGRESS_BAR_DISPLAY:
        PUSH R0
        PUSH R1
        PUSH R2
        PUSH R3
        PUSH R4
        PUSH R5

# | 3 | x | 36408 | 36408 |
# | 3 | 4 | 36408 |  7280 |
       #MOV  $progress_bar_arg, R4
       #ADD  (R4)+, (R4)
       #MOV  (R4)+, R1
       #ADD  (R4)+, (R4)
       #ADC  R1
       #MOV  R1, -4(R4)

        MOV  @$pb_arg0, R1
        MUL  $2,R1
        INC  @$pb_arg0

       .set X_OFFSET, 64 >> 2
       .set Y_OFFSET, 160 * LINE_WIDTHB
        MOV  $FB0 + X_OFFSET + Y_OFFSET, R0
        MOV  $4, R2 # height of progress bar elements

        0$: # lines loop
            PUSH R0
            MOV  R1, R3 # R1 - number of elements to draw
            CLR  R5
            1$:
               #TST  R5
                BPL  2$
                BIS  $0x0070,(R0)+
                COM  R5
            SOB  R3, 1$
            BR  3$
            2$:
                BIS  $0x0007,(R0)
                COM  R5
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

progress_bar_arg:
        pb_arg0: .word 1
        pb_arg1: .word 0
        pb_arg2: .word 0
        pb_arg3: .word 0

DiskRead_Start: #--------------------------------------------------{{{
        MOVB $010,@$PS.Command # read from disk

DiskIO_Start:
        MOV  (R0)+,@$PS.CPU_RAM_Address
        MOV  (R0)+,@$PS.WordsCount
        MOV  (R0),R0 # starting block number
      # calculate location of a file on a disk from the starting block number
        CLR  R2      # R2 - most significant word
        MOV  R0,R3   # R3 - least significant word
        DIV  $20,R2  # quotient -> R2, remainder -> R3
        MOVB R2,@$PS.AddressOnDevice     # track number (0-79)

        CLR  R2
        DIV  $10,R2
        INC  R3
        MOVB R3,@$PS.AddressOnDevice + 1 # sector (1-10)

        ASH  $7,R2
        BICB $0x80,@$PS.DeviceNumber     # BICB/BISB to preserve drive number
        BISB R2,@$PS.DeviceNumber        # head (0, 1)

        MOVB $-1,@$PS.Status

       .ppudo_ensure $PPU.LoadDiskFile,$ParamsStruct
        RETURN
# DiskRead_Start #-------------------------------------------------}}}
DiskIO_WaitForFinish: #--------------------------------------------{{{
        CLC
        MOVB @$PS.Status,R0
        BMI  DiskIO_WaitForFinish
        BZE  1237$
      # +------------------------------------------------------+
      # | Код ответа |  Значение                               |
      # +------------+-----------------------------------------+
      # |     00     | Операция завершилась нормально          |
      # |     01     | Ошибка контрольной суммы зоны данных    |
      # |     02     | Ошибка контрольной суммы зоны заголовка |
      # |     03     | Не найден адресный маркер               |
      # |    100     | Дискета не отформатированна             |
      # |    101     | Не обнаружен межсекторный промежуток    |
      # |    102     | Не найден сектор с заданным номером     |
      # |     04     | Не найден маркер данных                 |
      # |     05     | Сектор на найден                        |
      # |     06     | Защита от записи                        |
      # |     07     | Нулевая дорожка не обнаружена           |
      # |     10     | Дорожка не обнаружена                   |
      # |     11     | Неверный массив параметров              |
      # |     12     | Резерв                                  |
      # |     13     | Неверный формат сектора                 |
      # |     14     | Не найден индекс (ошибка линии ИНДЕКС)  |
      # +------------------------------------------------------+
        SEC  # set carry flag to indicate that there was an error

1237$:  RETURN
# DiskIO_WaitForFinish #-------------------------------------------}}}
ParamsStruct:
    PS.Status:          .byte -1  # operation status code
    PS.Command:         .byte 010 # read data from disk
    PS.DeviceType:      .byte 02       # double sided disk
    PS.DeviceNumber:    .byte 0x00 | 0 # bit 7: head(0-bottom, 1-top) ∨ drive number 0(0-3)
    PS.AddressOnDevice: .byte 0, 1     # track 0(0-79), sector 1(1-10)
    PS.CPU_RAM_Address: .word 0
    PS.WordsCount:      .word 0        # number of words to transfer
# files related data --------------------------------------------------------{{{
# each record is 3 words:
#   .word address for the data from a disk
#   .word size in words
#   .word starting block of a file
f7001.lzsa:
    .word GFX_W3
    .word 0
    .word 0
f7002.lzsa:
    .word GFX_W3
    .word 0
    .word 0
f7003.lzsa:
    .word GFX_W3
    .word 0
    .word 0
f7004.lzsa:
    .word GFX_W3
    .word 0
    .word 0
w3.raw.lzsa:
    .word GFX_W3
    .word 0
    .word 0
#----------------------------------------------------------------------------}}}
title_palette: #----------------------------------------------------------------
    .word      0, setCursorScalePalette, cursorGraphic, scale320 | RGB
    .word      1, setColors; .byte Black, brRed, brGreen, White
    .word untilEndOfScreen
#-------------------------------------------------------------------------------
GFX_timeCS_MASK:
        .incbin "build/timecs_t_mask.raw"
        .incbin "build/timecs_i_mask.raw"
        .incbin "build/timecs_m_mask.raw"
        .incbin "build/timecs_e_mask.raw"
        .incbin "build/timecs_C_mask.raw"
        .incbin "build/timecs_S_mask.raw"
GFX_timeCS:
        .incbin "build/timecs_t.raw"
        .incbin "build/timecs_i.raw"
        .incbin "build/timecs_m.raw"
        .incbin "build/timecs_e.raw"
        .incbin "build/timecs_C.raw"
        .incbin "build/timecs_S.raw"
        .even
RED_timeCS:
        .equiv GFX_timeCS_SIZE, GFX_timeCS - GFX_timeCS_MASK
        .equiv GFX_timeCS_SIZE_WORDS, GFX_timeCS_SIZE >> 1

        .equiv GREEN_timeCS, RED_timeCS + GFX_timeCS_SIZE
        .equiv BLUE_timeCS, GREEN_timeCS + GFX_timeCS_SIZE

CLOCKHAND_GFX:
        .incbin "build/clockhand.raw"
CLOCKHAND_GFX_END:

        .equiv CLOCKHANDS, BLUE_timeCS + GFX_timeCS_SIZE
        .equiv CLOCKHAND_SIZE, (CLOCKHAND_GFX_END - CLOCKHAND_GFX) * 2
        .equiv CLOCKHAND_SIZE_WORDS, CLOCKHAND_SIZE >> 1

        .equiv CLOCKHAND_SEC,  CLOCKHANDS
        .equiv CLOCKHAND_MIN,  CLOCKHAND_SEC + CLOCKHAND_SIZE
        .equiv CLOCKHAND_HOUR, CLOCKHAND_MIN + CLOCKHAND_SIZE

        .equiv CLOCKHAND_BUFFER, CLOCKHAND_HOUR + CLOCKHAND_SIZE

LoadPSGP:
        CALL DiskRead_Start
        CALL DiskIO_WaitForFinish
        CALL PROGRESS_BAR_DISPLAY
        MOV  $GFX_W3,R1
        MOV  $FB1,R2
        CALL LZSA_UNPACK
        CALL PROGRESS_BAR_DISPLAY
        MOV  $CBPADR,R5
       .equiv LoadPSGP.DataReg, .+2
        MOV  $CBP1DT,R4
        MOV  $FB1,R3
        SUB  R3,R2
        ASR  R2
        100$:
            MOVB (R3)+,(R4)
            INC  (R5)
            MOVB (R3)+,(R4)
            INC  (R5)
        SOB  R2,100$
        CALL PROGRESS_BAR_DISPLAY
        RETURN

LZSA_UNPACK: .include "unlzsa3.s"

GFX_W3:
        .ifdef DEBUG
    .skip 10870+128
        .endif
   # f7001.lzsa  7 880 -> 16384
   # f7002.lzsa  2 894 ->  3862
   # f7003.lzsa 10 870 -> 16384
   # f7004.lzsa  7 642 -> 14928
end:
