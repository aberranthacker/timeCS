               .nolist

               .title Chibi Akumas PPU module

               .global start # make the entry point available to a linker
               .global PPU_ModuleSize
               .global PPU_ModuleSizeWords

               .include "macros.s"
               .include "hwdefs.s"
               .include "core_defs.s"

               .equiv  PPU_ModuleSize, (end - start)
               .equiv  PPU_ModuleSizeWords, PPU_ModuleSize >> 1

               .=PPU_UserRamStart

start:
        MTPS $PR7
      # bit 0 if clear, disables ROM chip in range 0100000..0117777
      #       which allows to enable RW access to RAM in that range
      #       when bit 4 is set as well
      # bits 1-3 used to select ROM cartridge banks
      # bit 4 replaces ROM in range 0100000..0117777 with RAM, see bit 0
      # bit 5 replaces ROM in range 0120000..0137777 with write only RAM
      # bit 6 replaces ROM in range 0140000..0157777 with write only RAM
      # bit 7 replaces ROM in range 0160000..0176777 with write only RAM
      # bit 8 enables PPU Vblank interrupt when clear, disables when set
      # bit 9 enables CPU Vblank interrupt when clear, disables when set
      #
      # WARNING: since there is no way to disable ROM chips in range
      # 0120000..0176777, we can only write to the RAM in that range.
      # **But** UKNCBL emulator allows to read from the RAM as well!
      # **Beware** this is **not** how the real hardware behaves!
        MOV  $0x0F0,@$PASWCR
#-------------------------------------------------------------------------------
        CALL ClearOffscreenArea

# initialize our scanlines parameters table (SLTAB): ------------------------{{{
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
312 (1..312) lines is SECAM half-frame
309 (1..309) SLTAB records in total (lines 4..312 of SECAM's half-frame)
  scanlines   1..19  are not visible due to the vertical blanking interval
  scanlines  20..307 are visible (lines 23-310 of SECAM's half-frame)
  scanlines 308..309 are not visible due to the vertical blanking interval

| 2-word records | 4-word records |
| 0 address      | 0 data         | data - words that will be loaded into
| 2 next record  | 2 data         |        control registers
|                | 4 address      | address - address of the line to display
|                | 6 next record  | next record - address of the next record of
                                                  the SLTAB

Very first record of the table is 2-word and has fixed address 0270
--------------------------------------------------------------------------------
"next record" word description: ---------------------------------------------{{{

+--+--+--+--+--+--+--+--+--+--+--+--+--+-----+-----+------+
|15|14|13|12|11|10| 9| 8| 7| 6| 5| 4| 3|   2 |   1 |    0 |
+--+--+--+--+--+--+--+--+--+--+--+--+--+-----+-----+------+
|     address of the next record       | sel |2W/4W|cursor|
+--+--+--+--+--+--+--+--+--+--+--+--+--+-----+-----+------+

bit 0: cursor switching control
       1 - switch cursor state (on/off)
       0 - save cursor state
       Hardware draws cursor in a range of sequential lines.
       The cursor has to be switched "on" on the first line of the sequence,
       saved in between, and turned "off" on the last line of the sequence.

bit 1: size of the next record
       1 - next is a 4-word record
       0 - next is a 2-word record

bit 2: 1) for 2-word record - bit 2 of address of the next element of the table
       2) for 4-word record - selects register to which data will be loaded:
          0 - cursor, pallete, and horizontal scale control register
          1 - colors control register
-----------------------------------------------------------------------------}}}
cursor, pallete and horizontal scale control registers desription: ----------{{{

1st word
+----+----+----+----+----+----+----+----+----+----+----+----+---+---+---+---+
| 15 | 14 | 13 | 12 | 11 | 10 |  9 |  8 |  7 |  6 |  5 |  4 | 3 | 2 | 1 | 0 |
+----+----+----+----+----+----+----+----+----+----+----+----+---+---+---+---+
| X  | cursor position within a line    |graph curs pos|type| Y | R | G | B |
+----+----+----+----+----+----+----+----+----+----+----+----+---+---+---+---+

bits 0-3:  cursor color and brightness
bit 4:     cursor type
           1 - graphic cursor
           0 - character cursor
bits 5-7:  graphic cursor position within pixels octet
           0 - least significant bit (on the left side of the octet)
           7 - most significant bit (on the right side of the octet)
bits 8-14: cursor position within a text line
           from 0 to 79

2nd word
+----+----+----+----+----+----+---+---+---+---+---+---+---+----+----+----+
| 15 | 14 | 13 | 12 | 11 | 10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 |  2 |  1 |  0 |
+----+----+----+----+----+----+---+---+---+---+---+---+---+----+----+----+
|                     unused                  | scale | X | PB | PG | PR |
+----+----+----+----+----+----+---+---+---+---+---+---+---+----+----+----+

bits 0-2:  brightness of RGB components on the whole line
           1 - full brightness
           0 - 50% of the full brightness
bit 3:     unused
bits 4,5:  horizontal scale
           | 5 | 4 | width px | width chars | last char pos |
           +---+---+----------+-------------+---------------+
           | 0 | 0 |   640    |     80      |     0117      |
           | 0 | 1 |   320    |     40      |      047      |
           | 1 | 0 |   160    |     20      |      023      |
           | 1 | 1 |    80    |     10      |      011      |
bits 6-15: unused
-----------------------------------------------------------------------------}}}
colors control registers description:----------------------------------------{{{

1st word
           +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
           |15 |14 |13 |12 |11 |10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
           +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
           | Y | R | G | B | Y | R | G | B | Y | R | G | B | Y | R | G | B |
           +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
bitplanes  |      011      |      010      |      001      |      000      |
bit 2,1,0

2nd word
           +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
           |15 |14 |13 |12 |11 |10 | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
           +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
           | Y | R | G | B | Y | R | G | B | Y | R | G | B | Y | R | G | B |
           +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
bitplanes  |      111      |      110      |      101      |      100      |
bits 2,1,0
-----------------------------------------------------------------------------}}}
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
SLTABInit:
        MOV  $SLTAB,R0       # set R0 to beginning of SLTAB
        MOV  R0,R1           # R0 address of current record (2)

        MOV  $15,R2          #  records 2..16 are same
        1$:
            CLR  (R0)+       #--addresses of lines 2..16
            ADD  $4,R1       #  calc address of next record of SLTAB
            MOV  R1,(R0)+    #--address of records 3..17
        SOB  R2,1$

      # we are switching from 2-word records to 4-word records
      # so we have to align at 4 words (8 bytes)
        CLR  (R0)+           #--address of line 17
        ADD  $0b1000,R1      #  align

        BIS  $0b0010,R1      #  next record is 4-word
        BIC  $0b0100,R1      #  set cursor/scale/palette
        MOV  R1,(R0)+        #--address of the record 18
        ADD  $0b100,R0       #  correct R0 due to alignment
        BIC  $0b100,R0

        MOV  $0b10000,(R0)+  #--cursor settings, graphical cursor
        MOV  $0b10111,(R0)+  #  320 dots per line, palette 7
        CLR  (R0)+           #  address of line 18
        BIS  $0b110,R1       #  next record is 4-word, color settings
        ADD  $8,R1           #  calculate address to next record
        MOV  R1,(R0)+        #--pointer to record 19

        MOV  R0,@$TopAreaColors # store the address for future use
        MOV  $0xBA90,(R0)+   # colors  011  010  001  000 (YRGB)
        MOV  $0xFEDC,(R0)+   # colors  111  110  101  100 (YRGB)
        CLR  (R0)+           #--address of line 19
        BIC  $0b110,R1       #  next record is 2-word
        ADD  $8,R1           #  calculate pointer to next record
        MOV  R1,(R0)+        #--pointer to the record 20
#------------------------------------- top region, header
        MOV  $OffscreenAreaAddr,R2 # scanlines 20..307 are visible
        MOV  $43,R3          #
        2$:
            MOV  R2,(R0)+    #--address of screenline
            ADD  $4,R1       #  calc address of next record of SLTAB
            MOV  R1,(R0)+    #--set address of next record of SLTAB
            ADD  $40,R2      #  calculate address of next screenline
        SOB  R3,2$           #

      # we are switching from 2-word records to 4-word records
      # so we have to align at 8 bytes
        MOV  R2,(R0)+        #--address of a screenline
        BIS  $0b0010,R1      #  next record is 4-word
        BIC  $0b0100,R1      #  display settings
        ADD  $0b1000,R1      #  calc address of next record of SLTAB
                             #  taking alignment into account
        MOV  R1,(R0)+        #--pointer to record 63
        ADD  $0b100,R0       #  correct R0
        BIC  $0b100,R0       #  due to alignment
        ADD  $40,R2          #  calculate address of next screenline

        MOV  R0,@$FBSLTAB   #
        SUB  $2,@$FBSLTAB   #

        MOV  $0b10000,(R0)+  #--cursor settings: graphical cursor
        MOV  $0b10111,(R0)+  #  320 dots per line, pallete 7
        MOV  R2,(R0)+        #--address of a screenline
        ADD  $8,R1           #  calc address of next record of SLTAB
        BIS  $0b110,R1       #  next record is 4-word, color settings
        MOV  R1,(R0)+        #--pointer to record 64

        MOV  R0,@$FirstMainScreenLinePointer
        ADD  $4,@$FirstMainScreenLinePointer
#----------------------------- main screen area
        MOV  $FB1 >> 1,R2    # address of second frame-buffer
        MOV  $200,R3         # number of lines on main screen area
        3$:                  #
            MOV  $0x0000,(R0)+ #  colors  011  010  001  000 (YRGB)
            MOV  $0x0000,(R0)+ #  colors  111  110  101  100 (YRGB)
            MOV  R2,(R0)+      #--main RAM address of a scanline
            ADD  $8,R1         #  calc address of next record of SLTAB
            MOV  R1,(R0)+      #--pointer to the next record of SLTAB
            ADD  $40,R2        #  calculate address of next screenline
        SOB  R3,3$           #
#------------------------------------- bottom region, footer
        MOV  R0,@$BottomAreaColors # store the address for future use
        MOV  $0xBA90,(R0)+   # colors  011  010  001  000 (YRGB)
        MOV  $0xFEDC,(R0)+   # colors  111  110  101  100 (YRGB)
        MOV  $OffscreenAreaAddr+03340+40,R2  #
        MOV  R2,(R0)+        #
        ADD  $40,R2          # calculate address of next screenline
        ADD  $8,R1           # calculate pointer to next record
        BIC  $0b110,R1       # next record consists of 2 words
        MOV  R1,(R0)+        #--set address of record 265

        MOV  $42,R3          #
        4$:
            MOV  R2,(R0)+    #--address of a screenline
            ADD  $4,R1       #  calc address of next record of SLTAB
            MOV  R1,(R0)+    #--pointer to the next record of SLTAB
            ADD  $40,R2      # calculate address of next screenline
        SOB  R3,4$           #
                             #
        CLR  (R0)+           #--address of line 308
        MOV  R1,(R0)         #--pointer back to record 308
#----------------------------------------------------------------------------}}}
        MOV  $0x001,@$PASWCR
#-------------------------------------------------------------------------------
        MOV  $SLTAB, @$0272   # use our SLTAB

        MOV  $KeyboardIntHadler,@$KBINT
        MOV  $Channel0In_IntHandler,@$PCH0II
      # read from the channel, just in case
        TST  @$PCH0ID

        MOV  $Channel1In_IntHandler,@$PCH1II
        BIS  $Ch1StateInInt,@$PCHSIS
      # read from the channel, just in case
        TST  @$PCH1ID

       .equiv ScanRangeWords, 3
      # Aberrant Sound Module detection
        MOV  $PSG0+ScanRangeWords * 2,R1
        MOV  $PSG1,R2
        MOV  $Trap4,@$4
      # Aberrant Sound Module uses addresses range 0177360-0177377
      # 16 addresses in total
        MOV  $ScanRangeWords,R0
        TestNextSoundBoardAddress:
            TST  -(R1)
        SOB  R0,TestNextSoundBoardAddress
      # R1 now contains 0177360, address of PSG0

        TST  @$Trap4Detected
        BZE  AberrantSoundModulePresent

        MOV  $DummyPSG,R1
        MOV  R1,R2

AberrantSoundModulePresent:
        CLR  @$Trap4Detected
        MOV  R1,@$PLY_AKG_PSGAddress
        MOV  R2,@$PLY_SE_PSGAddress
        MOV  $0173362,@$4 # restore back Trap 4 handler

       #MOV  $SoundEffects,R5
       #CALL PLY_SE_InitSoundEffects # initialize sound effects player

        MOV  $VblankIntHandler,@$0100
      # inform loader that PPU is ready to receive commands
        MOV  $CPU_PPUCommandArg,@$PBPADR
        CLR  @$PBP12D

        MOV  $CommandsQueue_CurrentPosition,R4
        MTPS $PR0
#-------------------------------------------------------------------------------
Queue_Loop:
        MOV  (R4),R5
        CMP  R5,$CommandsQueue_Bottom
        BEQ  Queue_Loop

        #MTPS $PR7
        MOV  (R5)+,R1
        MOV  (R5)+,R0
        MOV  R5,(R4)
        #MTPS $PR0
    .ifdef DebugMode
        CMP  R1,$PPU_LastJMPTableIndex
        BHI  .
    .endif
        CALL @CommandVectors(R1)
        MOV  $CommandsQueue_CurrentPosition,R4
        BR   Queue_Loop
#-------------------------------------------------------------------------------
CommandVectors:
       .word LoadDiskFile
       .word SetPalette            # PPU_SetPalette
#-------------------------------------------------------------------------------
SetPalette: #----------------------------------------------------------------{{{
        PUSH @$PASWCR
        MOV  $0x040,@$PASWCR
        MOV  $PBPADR,R4

        CLC
        ROR  R0
        MOV  R0,(R4) # palette address
      # R0 - first parameter word
      # R1 - second parameter word
      # R2 - display/color parameters flag
      # R3 - current line
      # R4 - next line where parameters change
      # R5 - pointer to a word that we'll modify
        MOVB @$PBP1DT,@$NextLineNum  # get line number
        PUSH (R4)
SetPalette_NextRecord:
        MOV  @$NextLineNum,R3 # R3 = previous iteration's next line
        MOV  R3,R5            # prepare to calculate address of SLTAB section to modify
        ASH  $3,R5            # calculate offset by multiplying by 8 (by shifting R5 left by 3 bits)
       .equiv FBSLTAB, .+2
        ADD  $0,R5        # and add address of SLTAB section we modify

        POP  (R4)
        MOVB @$PBP2DT,R2         # get display/color parameters flag
        BMI  SetPalette_Finalize # negative value - terminator

        INC  (R4)
        MOV  @$PBP12D,R0     # get first data word
        INC  (R4)
        MOV  @$PBP12D,R1     # get second data word
        INC  (R4)
        MOVB @$PBP1DT,@$NextLineNum # get next line idx
        PUSH (R4)

        CMP  R2,$2
        BEQ  SetPalette_OffscreenColors
    set_params$:
        TSTB R2
        BNZ  SetPalette_SetColorRegisters # 1 - set colors

#SetPalette_SetControlRegisters:
       #BIC  $0b100,(R5)+    # 0 - set data
        MOV  R5,(R4)
        BICB $0b100,@$PBP0DT    # 0 - set data
        INC  R5
        INC  R5

        BR   set_data$

SetPalette_SetColorRegisters:
       #BIS  $0b100,(R5)+
        MOV  R5,(R4)
        BISB $0b100,@$PBP0DT    # 0 - set data
        INC  R5
        INC  R5

    set_data$:
        MOV  R0,(R5)+
        MOV  R1,(R5)+
        INC  R5
        INC  R5           # skip third word (screen line address)

        INC  R3           # increase current line idx
       .equiv NextLineNum, .+2
        CMP  R3,$0        # compare current line idx with next line idx
        BLO  set_params$  # branch if lower

        CMP  @$NextLineNum,$201
        BNE  SetPalette_NextRecord
        BR   SetPalette_Finalize_POP_R4

SetPalette_OffscreenColors:
       .equiv TopAreaColors, .+2
        MOV  $0,R2
        MOV  R0,(R2)+
        MOV  R1,(R2)
       .equiv BottomAreaColors, .+2
        MOV  $0,R2
        MOV  R0,(R2)+
        MOV  R1,(R2)
        BR   SetPalette_NextRecord

SetPalette_Finalize_POP_R4:
        POP  R4 # remove a value from the stack
SetPalette_Finalize:
        POP  @$PASWCR

        RETURN
#----------------------------------------------------------------------------}}}
SetOffscreenAreaColors: # ---------------------------------------------------{{{
        PUSH @$PASWCR
        MOV  $0x010,@$PASWCR

       #CLC
       #ROR  R0
       #MOV  R0,@$PBPADR # palette address
       #MOV  $PBPADR,R5
       #MOV  $PBP12D,R4
       #MOV  R0,(R5)

       #MOV  (R4),R1
       #INC  (R5)
       #MOV  (R4),R2
       #equiv TopAreaColors, .+2
       #MOV  $0,R3
       #MOV  R1,(R3)+
       #MOV  R2,(R3)
       #equiv BottomAreaColors, .+2
       #MOV  $0,R3
       #MOV  R1,(R3)+
       #MOV  R2,(R3)

        POP  @$PASWCR
        RETURN
#----------------------------------------------------------------------------}}}
ClearOffscreenArea: # -------------------------------------------------------{{{
        MOV  $88*4,R1
        MOV  $DTSOCT,R4
        MOV  $PBPADR,R5
        MOV  $OffscreenAreaAddr,(R5)
        CLR  @$PBPMSK # write to all bit-planes
        CLR  @$BP01BC # background color, pixels 0-3
        CLR  @$BP12BC # background color, pixels 4-7

        100$:
           .rept 10
            CLR  (R4)
            INC  (R5)
           .endr
        SOB  R1,100$

        RETURN
#----------------------------------------------------------------------------}}}
LoadDiskFile: # -------------------------------------------------------------{{{
        MOV  $1,@$VblankInt_SkipMusic
        MOV  R0,@$023200 # set ParamsStruct address for firmware proc to use
        CALL @$0125030   # firmware proc that handles channel 2
       #CALL @07132      # stop floppy drive spindle
        CALL @$0134454   # stop floppy drive spindle
        CLR  @$VblankInt_SkipMusic
        RETURN
#----------------------------------------------------------------------------}}}

       .include "ppu/interrupts_handlers.s"
       .include "akg_player.s"
       .include "player_sound_effects.s"

CGAFontBitmap: .incbin "resources/cga8x8b.raw"

CharLinesTable:
    .word 0x0000, 0x0140, 0x0280, 0x03C0, 0x0500, 0x0640, 0x0780, 0x08C0, 0x0A00, 0x0B40
    .word 0x0C80, 0x0DC0, 0x0F00, 0x1040, 0x1180, 0x12C0, 0x1400, 0x1540, 0x1680, 0x17C0
    .word 0x1900, 0x1A40, 0x1B80, 0x1CC0, 0x1E00

DummyPSG: .word 0

CommandsQueue_Top:
       .space 2*2*16
CommandsQueue_Bottom:

StrBuffer:
       .even
end:
       .nolist
