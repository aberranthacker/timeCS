               .nolist

               .TITLE timeCS bootsector

               .include "hwdefs.s"
               .include "macros.s"
               .include "defs.s"

               .global loader.bin
               .global player.bin
               .global title.bin

               .global LoadDiskFile
               .global PS.Status
               .global PS.Command
               .global PS.DeviceType
               .global PS.DeviceNumber
               .global PS.AddressOnDevice
               .global PS.CPU_RAM_Address
               .global PS.WordsCount

               .equiv PPU_MODULE_LOADING_ADDR, 0100000

       .=0
        NOP  # Bootable disk marker
        BR 68$

       .=DUMMY_INTERRUPT_HANDLER
        RTI

       .=0100
       .word DUMMY_INTERRUPT_HANDLER # Vblank interrupt handler
       .word 0200 #

68$:
      # R0 - contains a drive number
      # R1 - contains CSR
        MOVB R0,@$PS.DeviceNumber
        MOV  $0160000,SP

        CALL PrintTitleStr
      #-------------------------------------------------------------------------
        CALL Channel2Send # load PPU module
        30$:
            TSTB PS.Status  # check loading status
        BMI  30$
      #-------------------------------------------------------------------------
      # PPU will clear the value after it finishes initialization
        MOV  $-1, @$PPUCommandArg
        MOV  $PPUModule_PS, @$ParamsAddr+4
        CALL PPEXEC # execute the PPU module

        WaitForPPUInit:
            TST  @$PPUCommandArg
        BNZ  WaitForPPUInit
      #-------------------------------------------------------------------------
        MOV  $loader.bin,R0
        CALL LoadDiskFile
        CALL @$LOADER_START
      #-------------------------------------------------------------------------
        MOV  $title.bin,R0
        CALL LoadDiskFile
        CALL @$TITLE_START
      #-------------------------------------------------------------------------
        MOV  $player.bin,R0
        CALL LoadDiskFile
        JMP  @$PLAYER_START

LoadDiskFile: # ----------------------------------------------------------------
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
       .ppudo_ensure $PPU.LoadDiskFile, $ParamsStruct

        10$:
            TSTB @$PS.Status
        BMI  10$
        RETURN

Channel2Send:
        MOV  $ParamsAddr,R0     # R0 - pointer to channel's init sequence array
        MOV  $8,R1              # R1 - size of the array, 8 bytes
        10$:
            MOVB (R0)+,@$CCH2OD # Send a byte to the channel 2
            20$:
                TSTB @$CCH2OS   #
            BPL  20$            # Wait until the channel is ready
        SOB  R1,10$             # Next byte

        RETURN

PrintTitleStr:
        MOV  $TitleStr,R0
        10$:
            MOVB (R0)+,R1
            BZE  1237$
            20$:
                TSTB @$TTY.Output.State
            BPL  20$
            MOV  R1, @$TTY.Output.Data
        BR   10$
1237$:  RETURN
#-------------------------------------------------------------------------------
PPEXEC: #-----------------------------------------------------------------------
        MOV  $PPUModule_PS, @$ParamsAddr+4
        CALL Channel2Send                 # => Send request to PPU
                                          # PS.A1 contains address of allocated area
        MOV  $PPU_MODULE_LOADING_ADDR,@$PPUModule_PS.A2   # Arg 2 - addr of mem block in CPUs RAM
        MOV  $PPU_ModuleSizeWords,@$PPUModule_PS.A3 # Arg 3 - size of mem block, words
        MOVB $020, @$PPUModule_PS.Request # 020 - CPU to PPU memory copy
        CALL Channel2Send                 # => Send request to PPU
        MOVB $030, @$PPUModule_PS.Request # 030 - Execute programm
        CALL Channel2Send                 # => Send request to PPU
        RETURN

ParamsAddr: .byte  0, 0, 0, 0xFF # init sequence (just in case)
            .word  ParamsStruct
            .byte  0xFF, 0xFF    # two termination bytes 0xff, 0xff

ParamsStruct:
    PS.Status:          .byte  -1   # operation status code
    PS.Command:         .byte  010  # read data from disk
    PS.DeviceType:      .byte  02        # double sided disk
    PS.DeviceNumber:    .byte  0x00 | 0  # bit 7: side(0-bottom, 1-top) ∨ drive number(0-3)
    PS.AddressOnDevice: .byte  0,2       # track 0(0-79), sector 2(1-10)
    PS.CPU_RAM_Address: .word  PPU_MODULE_LOADING_ADDR
    PS.WordsCount:      .word  PPU_ModuleSizeWords # number of words to transfer

PPUModule_PS:
    PPUModule_PS.Reply:   .byte  -1  # operation status code
    PPUModule_PS.Request: .byte  1   # 01 - allocate memory
                                     # 02 - free memory
                                     # 010 - mem copy PPU -> CPU
                                     # 020 - mem copy CPU -> PPU
                                     # 030 - execute
    PPUModule_PS.Type:    .byte  032 # device type - PPU RAM
    PPUModule_PS.No:      .byte  0   # device number
    PPUModule_PS.A1:      .word  0   # Argument 1
    PPUModule_PS.A2:      .word  PPU_UserRamSizeWords # Argument 2
    PPUModule_PS.A3:      .word  0   # Argument 3
#-------------------------------------------------------------------------------
loader.bin:
    .word LOADER_START
    .word 0
    .word 0
title.bin:
    .word TITLE_START
    .word 0
    .word 0
player.bin:
    .word PLAYER_START
    .word 0
    .word 0
#-------------------------------------------------------------------------------
TitleStr: .asciz "loading timeCS"
#-------------------------------------------------------------------------------
    .=0600
