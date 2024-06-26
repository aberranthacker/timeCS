#-------------------------------------------------------------------------------
# Note that the PRESENCE of those variables is tested, NOT their values. -------
#.equiv DEBUG, 1
.equiv WORD_LINE_NUMBERS, 1
#-------------------------------------------------------------------------------
.equiv CPU_PPUCommandArg, PPUCommandArg >> 1

.equiv PPU.LoadDiskFile,      0 << 1
.equiv PPU.SetPalette,        1 << 1
.equiv PPU.SetPaletteFB1,     2 << 1
.equiv PPU.PSGP_Player.Init,  3 << 1
.equiv PPU.PSGP_Player.Play,  4 << 1
.equiv PPU.PSGP_Player.Stop,  5 << 1
.equiv PPU.PT3Play.Init,      6 << 1
.equiv PPU.PT3Play.Mute,      7 << 1
.equiv PPU.PT3Play.Start,     8 << 1
.equiv PPU.PT3Play.Stop,      9 << 1

.equiv PPU.LastJMPTableIndex, 9 << 1

.equiv PPU.SET_FB0_VISIBLE, 0
.equiv PPU.SET_FB1_VISIBLE, 1
#-------------------------------------------------------------------------------
.equiv ExtMemSizeBytes, 7168
#-------------------------------------------------------------------------------
.equiv MAIN_SCREEN_LINES_COUNT, 256
.equiv AUX_SCREEN_LINES_COUNT, 288 - MAIN_SCREEN_LINES_COUNT
.equiv LINE_WIDTHB, 72
.equiv LINE_WIDTHW, LINE_WIDTHB >> 1

.equiv CLOCK_SCR_WIDTH, 192
.equiv CLOCK_SCR_WIDTH_BYTES, CLOCK_SCR_WIDTH >> 2
.equiv CLOCK_SCR_WIDTH_WORDS, CLOCK_SCR_WIDTH >> 3
.equiv CLOCK_SCR_HEIGHT, 184
# CPU memory map ---------------------------------------------------------------
.equiv DUMMY_INTERRUPT_HANDLER, 040 # 32 0x20 loads from bootsector
.equiv PPUCommandArg, 046 # 38 0x26 command for PPU argument

.equiv PT3Params.FRAME_NUMBER,         050 # Incremented by one each time the PLAY entry point is accessed
.equiv PT3Params.PT3FILE_MODULE1_ADDR, 052 # PT3 file address
.equiv PT3Params.PT3FILE_END_ADDR,     054 # Address of end PT3 file
.equiv PT3Params.END_OF_PT3FILE,       056 # CODA. End of PT3 file reached (incremented by one each time)
.equiv PT3Params.NO_REPEAT_MODE,       060 # Play without repeat. Set (not zero) before INIT call.
.equiv PT3Params.REPETITION_NUMBER,    062 # Number of elapsed repetitions after end of PT3 file
.equiv KeyboardScanner,                064

.equiv PPT3.FRAME_NUMBER, PT3Params.FRAME_NUMBER >> 1
.equiv PPT3.PT3FILE_MODULE1_ADDR, PT3Params.PT3FILE_MODULE1_ADDR >> 1
.equiv PPT3.PT3FILE_END_ADDR, PT3Params.PT3FILE_END_ADDR >> 1
.equiv PPT3.END_OF_PT3FILE, PT3Params.END_OF_PT3FILE >> 1
.equiv PPT3.NO_REPEAT_MODE, PT3Params.NO_REPEAT_MODE >> 1
.equiv PPT3.REPETITION_NUMBER, PT3Params.REPETITION_NUMBER >> 1
.equiv PPU_KeyboardScanner, KeyboardScanner >> 1

.equiv FB_SIZE, MAIN_SCREEN_LINES_COUNT * LINE_WIDTHB
.equiv FB_SIZE_WORDS, FB_SIZE >> 1
.equiv FIRST_LINE_OFFSET, 8
.equiv FB0, 0600 + FIRST_LINE_OFFSET # 0384 0x0180
.equiv FB1_OFFSET, FB_SIZE + FIRST_LINE_OFFSET
.equiv FB1, FB0 + FB1_OFFSET
.equiv DEFAULT_FB, FB1 - FIRST_LINE_OFFSET

.equiv INITIAL_SP, 0160000
.equiv LOADER_START, FB1 + (288 * 164) >> 2 # 044610 18824 0x4988
.equiv PLAYER_START, FB1 + FB_SIZE
.equiv TITLE_START,  FB1 + FB_SIZE
# 0160000 57344 0xE000 end of RAM ----------------------------------------------
.equiv SONG_START, 0100000 # we are (not) using HALT mode RAM as well 😎
#-------------------------------------------------------------------------------
.equiv PPU_UserRamSize,  0054104 # 22596 0x5844
.equiv PPU_UserRamSizeWords, PPU_UserRamSize >> 1 # 0026042 11298 0x2C22
#-------------------------------------------------------------------------------
# PPU memory map ---------------------------------------------------------------
.equiv PPU_UserRamStart, 0023666 # 10166 0x27B6
.equiv PPU_UserRamEnd,   0077772 # 32762 0x7FFA
.equiv PPU_UserProcessMetadataAddr, PPU_UserRamSize
#-end of PPU memory map---------------------------------------------------------
#-------------------------------------------------------------------------------
# VRAM memory map --------------------------------------------------------------
.equiv SLTAB, 0140000 # 32768 0x8000 # bank 0
.equiv AUX_SCREEN_ADDR, 0160000 # 49152 0xC000 # banks 0, 1 and 2
#-end of VRAM memory map--------------------------------------------------------
#-------------------------------------------------------------------------------
.equiv setCursorScalePalette, 0
.equiv cursorGraphic, 0x10 # 020 dummy parameter
.equiv scale640, 0x00
.equiv scale320, 0x10
.equiv scale160, 0x20
.equiv scale80,  0x30
    .ifdef RGBpalette
.equiv rgb, 0b000
.equiv rgB, 0b001
.equiv rGb, 0b010
.equiv rGB, 0b011
.equiv Rgb, 0b100
.equiv RgB, 0b101
.equiv RGb, 0b110
.equiv RGB, 0b111
    .else
.equiv rgb, 0b000
.equiv rgB, 0b001
.equiv rGb, 0b100
.equiv rGB, 0b101
.equiv Rgb, 0b010
.equiv RgB, 0b011
.equiv RGb, 0b110
.equiv RGB, 0b111
    .endif
#-------------------------------------------------------------------------------
.equiv setColors, 1
    .ifdef RGBpalette
.equiv BLACK,   0b000 # 0x0
.equiv BLUE,    0b001 # 0x1
.equiv GREEN,   0b010 # 0x2
.equiv CYAN,    0b011 # 0x3
.equiv RED,     0b100 # 0x4
.equiv MAGENTA, 0b101 # 0x5
.equiv YELLOW,  0b110 # 0x6
.equiv GRAY,    0b111 # 0x7
    .else
.equiv BLACK,   0b000 # 0x0
.equiv BLUE,    0b001 # 0x1
.equiv RED,     0b010 # 0x2
.equiv MAGENTA, 0b011 # 0x3
.equiv GREEN,   0b100 # 0x4
.equiv CYAN,    0b101 # 0x5
.equiv YELLOW,  0b110 # 0x6
.equiv GRAY,    0b111 # 0x7
    .endif
.equiv BR_BLUE,    010 | BLUE    # 0x9
.equiv BR_RED,     010 | RED     # 0xC
.equiv BR_MAGENTA, 010 | MAGENTA # 0xD
.equiv BR_GREEN,   010 | GREEN   # 0xA
.equiv BR_CYAN,    010 | CYAN    # 0xB
.equiv BR_YELLOW,  010 | YELLOW  # 0xE
.equiv WHITE,      010 | GRAY    # 0xF

.equiv Black,     BLACK      << 4 | BLACK
.equiv Blue,      BLUE       << 4 | BLUE
.equiv Green,     GREEN      << 4 | GREEN
.equiv Cyan,      CYAN       << 4 | CYAN
.equiv Red,       RED        << 4 | RED
.equiv Magenta,   MAGENTA    << 4 | MAGENTA
.equiv Yellow,    YELLOW     << 4 | YELLOW
.equiv Gray,      GRAY       << 4 | GRAY
.equiv brBlue,    BR_BLUE    << 4 | BR_BLUE
.equiv brGreen,   BR_GREEN   << 4 | BR_GREEN
.equiv brCyan,    BR_CYAN    << 4 | BR_CYAN
.equiv brRed,     BR_RED     << 4 | BR_RED
.equiv brMagenta, BR_MAGENTA << 4 | BR_MAGENTA
.equiv brYellow,  BR_YELLOW  << 4 | BR_YELLOW
.equiv White,     WHITE      << 4 | WHITE

.equiv setOffscreenColors, 2

.equiv untilLine, -1
.equiv untilEndOfScreen, MAIN_SCREEN_LINES_COUNT + 1
.equiv endOfScreen, MAIN_SCREEN_LINES_COUNT + 1
#-------------------------------------------------------------------------------
.equiv NOP_OPCODE, 000240
.equiv INC_R0_OPCODE, 0005200
.equiv DECB_R3_OPCODE, 0105303
.equiv MOVB_R3_R3_OPCODE, 0110303

.equiv KEYMAP_UP,    0b10000000
.equiv KEYMAP_DOWN,  0b01000000
.equiv KEYMAP_SPACE, 0b00100000
.equiv KEYMAP_ENTER, 0b00010000
