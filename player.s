#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' (PART 2 'PLAYER') 6-channel (2AY) music only!
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
           .global ClockScreenStart
           .global clock1_screen.bin.lzsa3
           .global clock2_screen.bin.lzsa3
           .global clock3_screen.bin.lzsa3
           .global clock4_screen.bin.lzsa3
           .global song01.pt3.lzsa3
           .global song02.pt3.lzsa3
           .global song03.pt3.lzsa3
           .global song04.pt3.lzsa3
           .global song05.pt3.lzsa3
           .global song06.pt3.lzsa3
           .global song07.pt3.lzsa3
           .global song08.pt3.lzsa3
           .global song09.pt3.lzsa3
           .global song10.pt3.lzsa3
           .global song11.pt3.lzsa3
           .global song12.pt3.lzsa3
           .global song13.pt3.lzsa3
           .global song14.pt3.lzsa3
           .global song15.pt3.lzsa3
           .global song16.pt3.lzsa3
           .global song17.pt3.lzsa3
           .global song18.pt3.lzsa3
           .global mainscr_palette

           .=PLAYER_START

start:

SCREEN_PREP: #---------------------------------------------------------------{{{
            MOV  $MAINSCR_GFX, R2
            MOV  $CBPADR,R4
            MOV  $0100000,(R4) # upper 32K
            MOV  $CBP2DT,R1    # bank 2
           .set count, (MAINSCR_GFX_END - MAINSCR_GFX) >> 1
            MOV  $count, R0
            100$:
                MOVB (R2)+,(R1)
                INC  (R4)
                MOVB (R2)+,(R1)
                INC  (R4)
            SOB  R0, 100$

            MOV  $0100000,(R4)
            MOV  $FB1-8, R2
            CLR  (R2)+
            CLR  (R2)+
            CLR  (R2)+
            CLR  (R2)+
            CALL UnpackFromBP

            MTPS $PR0
            MOV  $FB0, R4
            MOV  $LINE_WIDTHB, R1
            MOV  $32, R2
            1$:
                MOV  R4, R0
                MOV  $256, R3
                WAIT
                2$:
                    MOV  FB1_OFFSET(R0), (R0)
                    ADD  R1, R0
                SOB  R3, 2$

                CMP  R2, $10
                BNE  3$
               .ppudo $PPU.SetPalette, $mainscr_palette
                3$:
                TST  (R4)+
            SOB  R2, 1$
#----------------------------------------------------------------------------}}}
            CLR  ClockScreenStart
MAIN_LOOP_PREP:
            CALL SONG_PREP
            CALL DISPLAY_PLAYING_SONG_NAME
            MOV $TIKTAK, @$0100
           .equiv song_loaded_flag, .+2
            TST $0
            BZE MAIN_LOOP

           .ppudo $PPU.PT3Play.Start
MAIN_LOOP:
            TST  ClockScreenStart
            BZE  skip_clock_screen_call

            CALL ClockScreenStart # clock screen call
    skip_clock_screen_call:
            TST PT3Params.END_OF_PT3FILE
            BZE pt3_eof_not_reached

            CALL AUTONEXT_SONG
    pt3_eof_not_reached:
            MOV @$KeyboardScanner, R0
            BNZ key_pressed
            CLR previous_keyboard_state

    key_pressed:
           .equiv previous_keyboard_state, .+2
            MOV $0, R1
            CMP R0, R1
            BNE KEY_REPEAT_OPER

            TST DISPLAY_PLAYING_SONG_NAME_DELAY_COUNTER
            BPL MAIN_LOOP

            CALL GET_PLAYING_SONG
            CMP R5, TRACK_LIST_SONG_DISPLAYED
            BEQ MAIN_LOOP

            CALL DISPLAY_PLAYING_SONG_NAME
            BR MAIN_LOOP

    KEY_REPEAT_OPER:
            MOV R0, previous_keyboard_state
            CLR DISPLAY_PLAYING_SONG_NAME_DELAY_COUNTER

            TST SCROLL_OPER
            BNZ MAIN_LOOP

            ASLB R0    # key 'UP'
            BCC 1$

            MOV $TRACK_LIST.RECORD_SIZE, R0
            NEG R0
            BR 2$

        1$: ASLB R0    # key 'DOWN'
            BCC 3$

            MOV $TRACK_LIST.RECORD_SIZE, R0
        2$: CALL TRACK_LIST_SCROLL
            BR MAIN_LOOP

        3$: ASLB R0    # key 'SPACE'
            BCC 4$

            CALL DISPLAY_PLAYING_SONG_NAME
            BR MAIN_LOOP

        4$: ASLB R0    # key 'Enter'
            BCC MAIN_LOOP
    LOAD_SONG:
            CALL LOAD_SELECTED_SONG
            BR MAIN_LOOP_PREP

AUTONEXT_SONG:
           .equiv AUTONEXT_SONG.delay_conter_in_progress_flag, .+2
            TST $0
            BZE 1$

            TST AUTONEXT_SONG_DELAY_COUNTER
            BMI 2$
            RETURN
        1$:
            CLR AUTONEXT_SONG_DELAY_COUNTER
            MOV PC, AUTONEXT_SONG.delay_conter_in_progress_flag
            RETURN

        2$:
            CLR AUTONEXT_SONG.delay_conter_in_progress_flag
            CALL GET_PLAYING_SONG
            CLR TRACK_LIST.SONG_STATUS(R5)
            ADD $TRACK_LIST.RECORD_SIZE, R5
            MOV R5, TRACK_LIST_SONG_DISPLAYED
            CMP R5, $TRACK_LIST_END
            BLO 3$

            MOV $TRACK_LIST, R5
            MOV R5, TRACK_LIST_SONG_DISPLAYED
        3$:
            INC TRACK_LIST.SONG_STATUS(R5)
            BR LOAD_SONG

LOAD_SELECTED_SONG:
            CALL GET_PLAYING_SONG

            CMP R5, TRACK_LIST_SONG_DISPLAYED
            BEQ 1237$

            CLR TRACK_LIST.SONG_STATUS(R5)
            MOV TRACK_LIST_SONG_DISPLAYED, R5
            INC TRACK_LIST.SONG_STATUS(R5)

1237$:      RETURN

TRACK_LIST_SCROLL:
           .equiv TRACK_LIST_SONG_DISPLAYED, .+2
            MOV $TRACK_LIST, R5

            ADD  R0, R5

            CMP  R5, $TRACK_LIST
            BLO  TRACK_LIST_SCROLL_EXIT

            CMP  R5, $TRACK_LIST_END
            BGE  TRACK_LIST_SCROLL_EXIT

            MOV  $16, R2
            MOV  $SONG_NAME_BUFFER1, R1
            TST  R0
            BPL  1$

            NEG  R2
            MOV  $SONG_NAME_BUFFER2, R1

       1$:  PUSH R1
            PUSH R2
            PUSH R5

            CMP  R5, TRACK_LIST_SONG_DISPLAYED
            BLO  2$

            MOV  $SONG_NAME_BUFFER2, R0
            CALL PREP_SONG_NAME2
            MOV  $SONG_NAME_BUFFER1, R0
            CALL PREP_SONG_NAME
            BR   3$

        2$: MOV $SONG_NAME_BUFFER1, R0
            CALL PREP_SONG_NAME2
            MOV $SONG_NAME_BUFFER2, R0
            CALL PREP_SONG_NAME

        3$: POP TRACK_LIST_SONG_DISPLAYED
            POP SCROLL_ARG2
            POP SCROLL_ARG1

            MOV $7, SCROLL_OPER
    TRACK_LIST_SCROLL_EXIT:
            RETURN


DISPLAY_PLAYING_SONG_NAME:
            CALL GET_PLAYING_SONG
            MOV  R5, TRACK_LIST_SONG_DISPLAYED
            MOV  $SONG_NAME_BUFFER1, R0
            CALL PREP_SONG_NAME

DISPLAY_SONG_NAME:
           .set offsetX, 96 >> 2
           .set offsetY, 187 * LINE_WIDTHB
            MOV $FB0 + offsetX + offsetY, R1
            MOV $6, R2
            10$:
               .rept 8
                    MOV (R0)+, (R1)+
               .endr
                ADD $LINE_WIDTHB - 16, R1
            SOB R2, 10$

            RETURN

PREP_SONG_NAME:
            MOV TRACK_LIST_SONG_DISPLAYED, R5
PREP_SONG_NAME2:
            MOV TRACK_LIST.GFX_NAME_ADDR(R5), R1

PREP_SONG_NAME_BUFFER:
            MOV $COLOR_OPER2, R4
            TST TRACK_LIST.SONG_STATUS(R5) # playing the song?
            BZE MONO_TO_COLOR_SONG_NAME    # no, black text color

            MOV $COLOR_OPER1, R4           # yes, white text color

    MONO_TO_COLOR_SONG_NAME: # 64x6 px
            PUSH R0
            MOV  $6, R2
            10$:
                MOV  $8, R3
                1$:
                    CLR  R5
                    BISB (R1)+, R5
                    CALL (R4)
                SOB  R3, 1$
            SOB  R2, 10$
            POP  R0

            RETURN

COLOR_OPER1:
            SWAB R5
            COM  R5
            MOV  R5, (R0)+
            RETURN

COLOR_OPER2:
            MOV  R5, (R0)+
            RETURN

GET_PLAYING_SONG:
            MOV  $TRACK_LIST, R5
        10$:TST  TRACK_LIST.SONG_STATUS(R5)
            BNZ  1$

            ADD  $TRACK_LIST.RECORD_SIZE, R5
            BR   10$

        1$: RETURN

SONG_PREP: # prepare a song and a clockscreen -------------------------------{{{
           .ppudo $PPU.PT3Play.Stop
            WAIT
            CLR song_loaded_flag

           .equiv LAST_LOADING_ERROR, .+2
            TST  $0
            BZE  20$

            CALL DISPLAY_ERROR
            CLR  LAST_LOADING_ERROR
            BR   100$

        20$:CALL RESTORE_SCREEN
            CALL DISPLAY_LOADING

       100$:CALL GET_PLAYING_SONG

            MOV  (R5), R1
            MUL  $6, R1
            ADD  $Songs, R1 # calculete song file parameters address
            MOV  R1, R0
            CALL DiskRead_Start
            CALL DiskIO_WaitForFinish
            BCC  load_song_success

            MOV  PC, LAST_LOADING_ERROR
            CALL DISPLAY_ERROR
            RETURN

        load_song_success:
            MOV  (R1), R1 # DiskRead leaves R1 uncorrupted
            MOV  $CBP1DT, R2
            MOV  $CBPADR, R4
            MOV  $SONG_START, (R4)
            CALL Unpack2BP

            MOV  $SONG_START, PT3Params.PT3FILE_MODULE1_ADDR
            MOV  (R4), PT3Params.PT3FILE_END_ADDR
            MOV PC, song_loaded_flag
           .ppudo $PPU.PT3Play.Init

          # prepare clockscreen
            CLR ClockScreenStart

            MOV CURRENT_CLOCK, R5
            BPL 1$ # we have loaded clockscreen, switch to next one

            CLR R5 # load very first clockscreen
            BR 10$
        1$:
            INC R5     # increase clockscreen idx
            CMP R5, $4 # clockscreen with next idx exists?
            BLO 10$ # yes, get next one
            CLR R5  # no, get the first one

        10$:
            MOV R5, CURRENT_CLOCK # store the clockscreen idx as current one
            MUL $6, R5
            ADD $CLOCKS, R5
            TST 2(R5) # already loaded?
            BNZ 20$ # yes, unpack the clockscreen

        11$:
            MOV 4(R5),R0
            CALL DiskRead_Start
            CALL DiskIO_WaitForFinish
            BCC  load_clockscreen_success

            CLR ClockScreenStart
            MOV  PC, LAST_LOADING_ERROR
            CALL DISPLAY_ERROR
            RETURN

        load_clockscreen_success:
            MOV  (R5), (R4)
            MOV  (R4), (R2)
            MOV  4(R5), R1
            MOV  (R1)+,R2 # loaded file start addr
            MOV  (R1),R0  # loaded file size, words
            MOV  $CBP2DT, R1

            copy_clockscreen_to_RAM2_loop:
                MOVB (R2)+, (R1)
                INC  (R4)
                MOVB (R2)+, (R1)
                INC  (R4)
            SOB  R0, copy_clockscreen_to_RAM2_loop
            MOV $1, 2(R5) # set clockscreen loaded flag
            MOV (R4), 6(R5) # store address where to store next clockscreen

        20$:
            MOV  $CBP2DT, R1
           .equiv current_clockscreen_address, .+2
            MOV  (R5), (R4)
            MOV  $ClockScreenStart, R2

            CALL UnpackFromBP

            CALL DISPLAY_LOADING

1237$:      RETURN

CURRENT_CLOCK: .word -1
CLOCKS:
CLOCK1: .word 0100000, 0, clock1_screen.bin.lzsa3
CLOCK2: .word       0, 0, clock2_screen.bin.lzsa3
CLOCK3: .word       0, 0, clock3_screen.bin.lzsa3
CLOCK4: .word       0, 0, clock4_screen.bin.lzsa3
next_clockscreen_addr_placeholder: .word 0
#----------------------------------------------------------------------------}}}

RESTORE_SCREEN:
        MOV $FB0, R0
        MOV $LINE_WIDTHB - CLOCK_SCR_WIDTH >> 2, R4
        MOV $CLOCK_SCR_HEIGHT - 43, R2
        1$:
            MOV $CLOCK_SCR_WIDTH_WORDS, R3
            2$:
                CLR (R0)+
            SOB R3, 2$
            ADD R4, R0
        SOB R2, 1$

        MOV $MAINSCR_PIECE, R1
        MOV $43, R2
        10$:
            MOV $(192-16)>>3,R3
            11$:
                CLR (R0)+
            SOB R3, 11$

            MOV $16>>3, R3
            12$:
                MOV (R1)+, (R0)+
            SOB R3, 12$
            ADD R4, R0
        SOB R2, 10$

        RETURN

DISPLAY_ERROR:
           .set offsetX, (CLOCK_SCR_WIDTH >> 3 - 48 >> 3) + LINE_WIDTHB * 12
           .set offsetY, ((CLOCK_SCR_HEIGHT >> 1) * LINE_WIDTHB) - LINE_WIDTHB * 2
            MOV $FB0 + offsetX + offsetY, R0
            MOV $ERROR_GFX, R1
            BR DISPLAY_LOADING_GFX

DISPLAY_LOADING:
           .set offsetX, (CLOCK_SCR_WIDTH >> 3 - 48 >> 3) - LINE_WIDTHB * 5
           .set offsetY, ((CLOCK_SCR_HEIGHT >> 1) * LINE_WIDTHB) - LINE_WIDTHB * 2
            MOV $FB0 + offsetX + offsetY, R0
            MOV $LOADING_GFX, R1

DISPLAY_LOADING_GFX:
            MOV $5, R2 # 5 lines
            10$:
                MOV $48 >> 3, R3 # 48px wide
                1$:
                    MOV (R1)+, R4
                    XOR R4, (R0)+
                SOB R3, 1$

                ADD $LINE_WIDTHB * 3 - 48 >> 2, R0
            SOB R2, 10$

            RETURN

LOADING_GFX:
           .incbin "build/loading.raw"
ERROR_GFX:
           .incbin "build/error.raw"
MAINSCR_PIECE:
           .incbin "build/mainscr_piece.raw"

TIKTAK:
            PUSH R0
            PUSH R1
            PUSH R2
            PUSH R3
            PUSH R4
            PUSH R5

           .equiv DISPLAY_PLAYING_SONG_NAME_DELAY_COUNTER, .+2
            TST $-1
            BMI 1$

            ADD $0x00A0, DISPLAY_PLAYING_SONG_NAME_DELAY_COUNTER
        1$:
           .equiv AUTONEXT_SONG_DELAY_COUNTER, .+2
            TST $-1
            BMI 2$
            ADD $0x0100, AUTONEXT_SONG_DELAY_COUNTER
        2$:
           .equiv SCROLL_OPER, .+2
            TST $0
            BZE TIKTAK_EXIT

           .equiv SCROLL_ARG1, .+2
            MOV $0, R0
            CALL DISPLAY_SONG_NAME

           .equiv SCROLL_ARG2, .+2
            ADD $0, SCROLL_ARG1
            DEC SCROLL_OPER

    TIKTAK_EXIT:
            POP  R5
            POP  R4
            POP  R3
            POP  R2
            POP  R1
            POP  R0
            RTI

TRACK_LIST:
           .equiv TRACK_LIST.RECORD_SIZE, 3 * 2
          # +0 - SONG NUMBER
          # +2 - SONG STATUS: NOT ZERO - PLAYING
           .equiv TRACK_LIST.SONG_STATUS, 2
          # +4 - GFX NAME ADDRESS
           .equiv TRACK_LIST.GFX_NAME_ADDR, 4
          # +6 - NEXT SONG

          # +0  - SMK PAGE
          # +2  - SONG NUMBER IN SMK OR 7 PAGE
          # +4  - SONG STATUS: NOT ZERO - PLAYING
          # +6  - GFX NAME ADDRESS
          # +8  - SONG PACK NUMBER
          # +10 - NEXT SONG

           .word  0, 1, GFX_TRACK_NAMES + 48 *  0
           .word  1, 0, GFX_TRACK_NAMES + 48 *  1
           .word  2, 0, GFX_TRACK_NAMES + 48 *  2
           .word  3, 0, GFX_TRACK_NAMES + 48 *  3
           .word  4, 0, GFX_TRACK_NAMES + 48 *  4
           .word  5, 0, GFX_TRACK_NAMES + 48 *  5
           .word  6, 0, GFX_TRACK_NAMES + 48 *  6
           .word  7, 0, GFX_TRACK_NAMES + 48 *  7
           .word  8, 0, GFX_TRACK_NAMES + 48 *  8
           .word  9, 0, GFX_TRACK_NAMES + 48 *  9
           .word 10, 0, GFX_TRACK_NAMES + 48 * 10
           .word 11, 0, GFX_TRACK_NAMES + 48 * 11
           .word 12, 0, GFX_TRACK_NAMES + 48 * 12
           .word 13, 0, GFX_TRACK_NAMES + 48 * 13
           .word 14, 0, GFX_TRACK_NAMES + 48 * 14
           .word 15, 0, GFX_TRACK_NAMES + 48 * 15
           .word 16, 0, GFX_TRACK_NAMES + 48 * 16
           .word 17, 0, GFX_TRACK_NAMES + 48 * 17
TRACK_LIST_END:

           .include "unlzsa3_to_bp.s"
           .include "unlzsa3_from_bp.s"

GFX_TRACK_NAMES:
           .incbin "build/song_names.raw"
           .even

SONG_NAME_BUFFER1: .space 6 * 16
SONG_NAME_BUFFER2: .space 6 * 16

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

       .ppudo $PPU.LoadDiskFile,$ParamsStruct
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
# files data ----------------------------------------------------------------{{{
# each record is 3 words:
#   .word address for the data from a disk
#   .word size in words
#   .word starting block of a file
Songs:
song01.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song02.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song03.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song04.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song05.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song06.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song07.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song08.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song09.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song10.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song11.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song12.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song13.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song14.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song15.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song16.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song17.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
song18.pt3.lzsa3:
    .word SongBuffer
    .word 0
    .word 0
clock1_screen.bin.lzsa3:
    .word ClockScreenStart
    .word 0
    .word 0
clock2_screen.bin.lzsa3:
    .word ClockScreenStart
    .word 0
    .word 0
clock3_screen.bin.lzsa3:
    .word ClockScreenStart
    .word 0
    .word 0
clock4_screen.bin.lzsa3:
    .word ClockScreenStart
    .word 0
    .word 0
#----------------------------------------------------------------------------}}}
mainscr_palette: #--------------------------------------------------------------
    .word      0, setCursorScalePalette, cursorGraphic, scale320 | RGB
    .word      1, setColors; .byte Black, brRed, brGreen, brCyan
    .word    184, setColors; .byte Black, brRed, brGreen, White
    .word    185, setCursorScalePalette, cursorGraphic, scale320 | RGB
    .word    198, setCursorScalePalette, cursorGraphic, scale320 | rGb
    .word untilEndOfScreen
#-------------------------------------------------------------------------------

.equiv mainscr_gfx_size, MAINSCR_GFX_END - MAINSCR_GFX
.equiv max_clock_size, 13000

ClockScreenStart: .word 0
SongBuffer:

MAINSCR_GFX:
           .incbin "build/mainscr.raw.lzsa"
           .even
MAINSCR_GFX_END:

        .ifdef DEBUG
    .space max_clock_size - mainscr_gfx_size
        .endif
.space 2
end:
