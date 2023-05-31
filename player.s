# vim: set tabstop=4 :

#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' (PART 2 'PLAYER') 6-channel (2AY) music only!
#   BY VLADIMIR 'KUVO' KUTYAKOV/CSI
#   
#   CONVERSION FOR Elektronika MS0511 (UKNC)
#   BY ABERRANTHACKER
#
#   2AY DEVICES:    Aberrant Sound Module
#   PLATFORM:       Elektronika MS0511
#   COMPILER:       GNU Assembler
#-------------------------------------------------------------------------------
           .nolist

           .include "hwdefs.s"
           .include "macros.s"
           .include "defs.s"

           .global start

            BK11_PALETTE = 014

            SMK_PRESENT = 0400
            SONG_PACKS_PHISICAL_LOCATION = 0402
            CLOCK_SCREENS_CATALOGUE_PHISICAL_LOCATION = SONG_PACKS_PHISICAL_LOCATION + (6 * 4)
            DRIVER_WORK_AREA = 0440

           .=PLAYER_START
start:
            JMP START_PART

CUR_SONG_PACK_NUMBER:   .word -1

PT3_PLAY:
            RETURN
            RETURN
            RETURN

START_PART:

    SCREEN_PREP:
            MOV $MAINSCR_GFX, R1
            MOV $FB0, R2
            CLR  (R2)+
            CLR  (R2)+
            CLR  (R2)+
            CLR  (R2)+
            CALL UNPACK
           .ppudo $PPU.SetPalette, $mainscr_palette
            BR  .

            TRAP 0; .word 017400 #5-6

            MOV $040000, R4
            MOV $0100, R1
            MOV $040, R2
        1$: MOV R4, R0
            MOV $0400, R3
            WAIT
        2$: MOV 040000(R0), (R0)
            ADD R1, R0
            SOB R3, 2$
            TST (R4)+
            SOB R2, 1$

            CLR @$020000

MAIN_LOOP_PREP:

            CALL SONG_PREP
            CALL DISPLAY_PLAYING_SONG_NAME
            MOV $TIKTAK, @$0100
            MTPS $0
            INC PLAY_NOW

MAIN_LOOP:
            TST @$020000
            BEQ 10$

            CALL @$020000  #CLOCK SCREEN CALL

        10$:TST PT3_PLAY + 032  # CODA (END_OF_PT3FILE)
            BEQ 1$

            CALL AUTONEXT_SONG

        1$: BIT $0100, @$0177716
            BEQ KEY_REPEAT_OPER

            CLR KEY_PRESSED

            ADD (PC)+, (PC)+
                .word 010
        RETURN_TO_DISPLAY_PLAYING_SONG_NAME_DELAY:
                .word 0
            BCC MAIN_LOOP

            CALL GET_PLAYING_SONG
            CMP R5, TRACK_LIST_SONG_DISPLAYED
            BEQ MAIN_LOOP

            CALL DISPLAY_PLAYING_SONG_NAME
            BR MAIN_LOOP

    KEY_REPEAT_OPER:
            TST (PC)+
        KEY_PRESSED:    .word 0
            BNE MAIN_LOOP
        GET_KEY_CODE:
            MOV PC, KEY_PRESSED
            CLR RETURN_TO_DISPLAY_PLAYING_SONG_NAME_DELAY

            MOV @$0177662, R0

            CMP R0, $3      #KT
            BNE 10$
            HALT

        10$:    TST SCROLL_OPER + 2
            BNE MAIN_LOOP

            CMP R0, $032    #KEY 'UP'
            BNE 1$
            MOV $-012, R0
            BR 2$
        1$: CMP R0, $033    #KEY 'DOWN'
            BNE 3$
            MOV $012, R0
        2$: CALL TRACK_LIST_SCROLL
            BR MAIN_LOOP

        3$: CMP R0, $040    #KEY 'SPACE'
            BNE 4$
            CALL DISPLAY_PLAYING_SONG_NAME
            BR MAIN_LOOP

        4$: CMP R0, $012
            BEQ LOAD_SONG
        5$: CMP R0, $031
            BNE MAIN_LOOP
    LOAD_SONG:
            CALL LOAD_SELECTED_SONG
            BR MAIN_LOOP_PREP


AUTONEXT_SONG:

            DEC $040
            BMI 10$
            RETURN

        10$:CALL GET_PLAYING_SONG
            CLR 4(R5)
            ADD $012, R5
            MOV R5, TRACK_LIST_SONG_DISPLAYED
            CMP R5, $TRACK_LIST_END
            BLO 1$
            MOV $TRACK_LIST, R5
            MOV R5, TRACK_LIST_SONG_DISPLAYED
        1$: INC 4(R5)
            BR LOAD_SONG

LOAD_SELECTED_SONG:

            CALL GET_PLAYING_SONG
            CMP R5, TRACK_LIST_SONG_DISPLAYED
            BEQ LOAD_SELECTED_SONG_EXIT

            CLR 4(R5)
            MOV TRACK_LIST_SONG_DISPLAYED, R5
            INC 4(R5)

        LOAD_SELECTED_SONG_EXIT:
            RETURN

TRACK_LIST_SCROLL:

            MOV (PC)+, R5
        TRACK_LIST_SONG_DISPLAYED:  .word TRACK_LIST

            ADD R0, R5

            CMP R5, $TRACK_LIST
            BLO TRACK_LIST_SCROLL_EXIT
            CMP R5, $TRACK_LIST_END
            BGE TRACK_LIST_SCROLL_EXIT

            MOV $16, R2
            MOV $SONG_NAME_BUFFER1, R1
            TST R0
            BPL 100$
            NEG R2
            MOV $SONG_NAME_BUFFER2, R1

       100$:MOV R1, -(SP)
            MOV R2, -(SP)
            MOV R5, -(SP)

            CMP R5, TRACK_LIST_SONG_DISPLAYED
            BLO 10$
            MOV $SONG_NAME_BUFFER2, R0
            CALL PREP_SONG_NAME2
            MOV $SONG_NAME_BUFFER1, R0
            CALL PREP_SONG_NAME
            BR 1$

        10$:    MOV $SONG_NAME_BUFFER1, R0
            CALL PREP_SONG_NAME2
            MOV $SONG_NAME_BUFFER2, R0
            CALL PREP_SONG_NAME

        1$: MOV (SP)+, TRACK_LIST_SONG_DISPLAYED
            MOV (SP)+, SCROLL_ARG2
            MOV (SP)+, SCROLL_ARG1

            MOV $7, SCROLL_OPER + 2
    TRACK_LIST_SCROLL_EXIT:
            RETURN


DISPLAY_PLAYING_SONG_NAME:

            CALL GET_PLAYING_SONG
            MOV R5, TRACK_LIST_SONG_DISPLAYED
            MOV $SONG_NAME_BUFFER1, R0
            CALL PREP_SONG_NAME

DISPLAY_SONG_NAME:

            TRAP 0; .word 017400

DISPLAY_SONG_NAME2:
            MOV $040000 + (96 >> 2) + (187*64), R1
            MOV $6, R2
        10$:
            .rept 8
                MOV (R0)+, (R1)+
            .endr
            ADD $0100 - 16, R1
            SOB R2, 10$
            RETURN

PREP_SONG_NAME:
            MOV TRACK_LIST_SONG_DISPLAYED, R5
PREP_SONG_NAME2:
            MOV 6(R5), R1

PREP_SONG_NAME_BUFFER:

            MOV $COLOR_OPER2, MONO_TO_COLOR_OPER
            TST 4(R5)
            BEQ MONO_TO_COLOR_SONG_NAME
            MOV $COLOR_OPER1, MONO_TO_COLOR_OPER

    MONO_TO_COLOR_SONG_NAME:
            MOV R0, -(SP)
            MOV $6, R2
        10$:MOV R2, -(SP)
            MOV $8, R2
        1$: MOVB (R1)+, R3
            MOV $010, R4
        2$: ASR R3
            ROR R5
            ASR R5
            SOB R4, 2$
            CALL @MONO_TO_COLOR_OPER
            SOB R2, 1$
            MOV (SP)+, R2
            SOB R2, 10$
            MOV (SP)+, R0
            RETURN

MONO_TO_COLOR_OPER:     .word COLOR_OPER1

COLOR_OPER1:
            MOV R5, R4
            BIC $0125252, R4
            MOV R4, (R0)
            COM R5
            BIS R5, (R0)+
            RETURN

COLOR_OPER2:
            BIC $0125252, R5
            MOV R5, (R0)+
            RETURN


GET_PLAYING_SONG:
            MOV $TRACK_LIST, R5
        10$:TST 4(R5)
            BNE 1$
            ADD $012, R5
            BR 10$
        1$: RETURN

SONG_PREP:
            WAIT
            CLR PLAY_NOW

            TST PT3_PLAY + 6 #FRAME_NUMBER
            BEQ 10$
            #IF THE MUSIC WAS PLAYING THEN TURN IT OFF
            CALL @PT3_PLAY + 4 #MUTE

        10$:TST (PC)+
        LAST_LOADING_ERROR: .word 0
            BEQ 20$

            CALL DISPLAY_ERROR
            CLR LAST_LOADING_ERROR
            BR 100$

        20$:CALL RESTORE_SCREEN
            CALL DISPLAY_LOADING

        100$:   CALL GET_PLAYING_SONG

            TRAP 0; .word 046400 #4-7

            CMP CUR_SONG_PACK_NUMBER, 010(R5)
            BEQ 1$
            TST SMK_PRESENT
            BNE 1$

            CALL LOAD_FROM_DISK
            BCC 1$

            MOV PC, LAST_LOADING_ERROR
            CALL DISPLAY_ERROR

            RETURN

        1$: MOV 010(R5), CUR_SONG_PACK_NUMBER

            MOV $6, @$0177130
            MOV (R5)+, @$0177130

            MOV (R5)+, R5
            ASL R5
            ASL R5
            MOV $0100000, R1
            ADD R1, R5
            MOV (R5)+, R0
            MOV (R5)+, R2
            ADD R2, R0
        2$: MOVB -(R0), -(R1)
            SOB R2, 2$

            MOV $6, @$0177130
            MOV $0140, @$0177130
            MOV $0,  @$0177130

            MOV $040000, R2
            ADD R2, R1

            TRAP 0; .word 036000 #3-4

            CALL UNPACK

            MOV R2, PT3_PLAY + 030 #PT3FILE_END_ADDR

            CALL @PT3_PLAY #SONG INIT

PREP_CLOCKSCREEN:

            TST @$020000
            BNE 2$

            TRAP 0; .word 025000

            TST SMK_PRESENT
            BNE 10$

            MOV CLOCK_SCREENS_CATALOGUE_PHISICAL_LOCATION, R1
            MOV CLOCK_SCREENS_CATALOGUE_PHISICAL_LOCATION + 2, R0

            CALL LOAD_FROM_DISK2
            BCC 2$
            RETURN

        10$:    MOV $6, @$0177130
            MOV $0121, @$0177130 #STORED IN LOADER

            MOV $040000, R0
            MOV $0100000, R1
            MOV $020000, R2
        1$: MOV (R1)+, (R0)+
            SOB R2, 1$

            MOV $6, @$0177130
            MOV $0140, @$0177130
            MOV $0, @$0177130

        2$: TRAP 0; .word 05000
            MOV (PC)+, R0
        CLOCK_SCREEN_IDX:   .word 0100000
        10$:MOV (R0)+, R1
            BNE 1$
            MOV $0100000, R0
            BR 10$
        1$: MOV R0, CLOCK_SCREEN_IDX

            MOV $020000, R2
            CALL UNPACK

            CALL DISPLAY_LOADING

            RETURN

LOAD_FROM_DISK:
            MOV 010(R5), R0         #GET SONG PACK NUMBER
            ASL R0
            ASL R0
            MOV SONG_PACKS_PHISICAL_LOCATION(R0), R1    # file size in WORDS
            MOV SONG_PACKS_PHISICAL_LOCATION+2(R0), R0  # block number
LOAD_FROM_DISK2:
            MOV R5, -(SP)
            MOV $0100000, R2        # address where to load
            MOV $DRIVER_WORK_AREA, R3           # address of HDD parameters block
            CALL @$0160004
            MOV (SP)+, R5
            RETURN

RESTORE_SCREEN:
            TRAP 0; .word 017400

            MOV $040000, R0
            MOV $0100000, R1
            MOV $0100 - 192 >> 2, R5
            MOV $184, R2
        10$:MOV $192 >> 3, R3
        1$: MOV (R1)+, (R0)+
            SOB R3, 1$
            ADD R5, R1
            ADD R5, R0
            SOB R2, 10$
            RETURN

DISPLAY_ERROR:

            MOV $040000 + ((184 >> 1) * 0100) - 0200 + (192 >> 3 - 48 >> 3) + 01400, R0
            MOV $LOADING_GFX + (5 * 48 >> 2), R1
            BR DISPLAY_LOADING_GFX

DISPLAY_LOADING:

            MOV $040000 + ((184 >> 1) * 0100) - 0200 + (192 >> 3 - 48 >> 3) - 0500, R0
            MOV $LOADING_GFX, R1

DISPLAY_LOADING_GFX:

            TRAP 0; .word 017400

            MOV $5, R2
        10$:MOV $48 >> 3, R3
        1$: MOV (R1)+, R4
            XOR R4, (R0)+
            SOB R3, 1$
            ADD $0300 - 48 >> 2, R0
            SOB R2, 10$
            RETURN

LOADING_GFX:
            .incbin "build/loading.raw"

TIKTAK:
            MOV R0, -(SP)
            MOV R1, -(SP)
            MOV R2, -(SP)
            MOV R3, -(SP)
            MOV R4, -(SP)
            MOV R5, -(SP)

            TST (PC)+
    PLAY_NOW:   .word 0
            BEQ SCROLL_OPER

            MOV $036000, @$0177716

            CALL @PT3_PLAY + 2

    SCROLL_OPER:
            TST $0
            BEQ TIKTAK_EXIT

            MOV $017400, @$0177716

            MOV (PC)+, R0
        SCROLL_ARG1:    .word 0
            CALL DISPLAY_SONG_NAME2
            ADD (PC)+, @(PC)+
        SCROLL_ARG2:    .word 0
                        .word SCROLL_ARG1
            DEC SCROLL_OPER + 2

    TIKTAK_EXIT:
            MOV (SP)+, R5
            MOV (SP)+, R4
            MOV (SP)+, R3
            MOV (SP)+, R2
            MOV (SP)+, R1
            MOV (SP)+, R0
            RTI

TRACK_LIST:
           #+0  - SMK PAGE
           #+2  - SONG NUMBER IN SMK OR 7 PAGE
           #+4  - SONG STATUS: NOT ZERO - PLAYING
           #+6  - GFX NAME ADDRESS
           #+010 - SONG PACK NUMBER
           #+012 - NEXT SONG

           .word  0124, 0, 1, GFX_TRACK_NAMES          ; .word 0 #SONGS1.OVL
           .word  0124, 1, 0, GFX_TRACK_NAMES + 48     ; .word 0
           .word  0124, 2, 0, GFX_TRACK_NAMES + 48 *  2; .word 0
           .word  0124, 3, 0, GFX_TRACK_NAMES + 48 *  3; .word 0
           .word  0124, 4, 0, GFX_TRACK_NAMES + 48 *  4; .word 0

           .word 02124, 0, 0, GFX_TRACK_NAMES + 48 *  5; .word 1 #SONGS2.OVL
           .word 02124, 1, 0, GFX_TRACK_NAMES + 48 *  6; .word 1
           .word 02124, 2, 0, GFX_TRACK_NAMES + 48 *  7; .word 1
           .word 02124, 3, 0, GFX_TRACK_NAMES + 48 *  8; .word 1

           .word  0130, 0, 0, GFX_TRACK_NAMES + 48 *  9; .word 2 #SONGS3.OVL
           .word  0130, 1, 0, GFX_TRACK_NAMES + 48 * 10; .word 2
           .word  0130, 2, 0, GFX_TRACK_NAMES + 48 * 11; .word 2

           .word 02130, 0, 0, GFX_TRACK_NAMES + 48 * 12; .word 3 #SONGS4.OVL
           .word 02130, 1, 0, GFX_TRACK_NAMES + 48 * 13; .word 3

           .word  0134, 0, 0, GFX_TRACK_NAMES + 48 * 14; .word 4 #SONGS5.OVL
           .word  0134, 1, 0, GFX_TRACK_NAMES + 48 * 15; .word 4

           .word 02134, 0, 0, GFX_TRACK_NAMES + 48 * 16; .word 5 #SONGS6.OVL
           .word 02134, 1, 0, GFX_TRACK_NAMES + 48 * 17; .word 5

TRACK_LIST_END:

UNPACK:
           .include "unlzsa3.s"
GFX_TRACK_NAMES:
           .incbin "build/song_names.raw"
MAINSCR_GFX:
           .incbin "build/mainscr.raw.lzsa"
           .even

SONG_NAME_BUFFER1: .space 6 * 16
SONG_NAME_BUFFER2: .space 6 * 16

mainscr_palette: #--------------------------------------------------------------
    .word      0, setCursorScalePalette, cursorGraphic, scale320 | RGB
    .word      1, setColors; .byte Black, brRed, brGreen, White
    .word    236, setCursorScalePalette, cursorGraphic, scale320 | rGb
    .word untilEndOfScreen
#-------------------------------------------------------------------------------
end:
