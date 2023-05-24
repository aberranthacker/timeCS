               .nolist

               .TITLE Demo Bootsector

               .include "../aku/uknc/hwdefs.s"
               .include "../aku/uknc/macros.s"
               .include "./core_defs.s"

               .global main.bin

       .=0
        NOP  # Bootable disk marker
        BR   68$

       .=040
        RTI                 # dummy interrupt handler
       .=0104
68$:
      # R0 - contains a drive number
      # R1 - contains CSR
        MOVB R0,@$PS.DeviceNumber
        MOV  $040,@$0100    # set dummy Vblank int handler
        MOV  $0160000,SP

        CALL @$PrintTitleStr

      #-------------------------------------------------------------------------
      # load PPU module
        CALL Channel2Send
      # ждём окончание загрузки модуля PPU с дискеты
        30$:
            MOVB @$PS.Status,R0
        BMI  30$
      #-------------------------------------------------------------------------
      # PPU will clear the value when finishes initialization
        MOV  $-1,@$PPUCommandArg
      # execute the PPU module
        MOV  $PPUModule_PS,@$ParamsAddr+4
        CALL PPEXEC

        WaitForPPUInit:
            TST  @$PPUCommandArg
        BNZ  WaitForPPUInit
      #-------------------------------------------------------------------------
        MOV  $main.bin,R0
        CALL LoadDiskFile.Start
        CALL LoadDiskFile.WaitForFinish
      #-------------------------------------------------------------------------
        JMP  @$CORE_START
      #-------------------------------------------------------------------------

LoadDiskFile.Start: # ----------------------------------------------------------
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
       .ppudo_ensure $PPU_LoadDiskFile,$ParamsStruct
        RETURN
LoadDiskFile.WaitForFinish: #---------------------------------------------------
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
TitleStr: #---------------------------------------------------------------------
       .asciz "My First Demo"
       .even
#-------------------------------------------------------------------------------
PPEXEC: #-----------------------------------------------------------------------
        MOV  $PPUModule_PS,@$ParamsAddr+4
        CALL Channel2Send                 # => Send request to PPU
                                          # PS.A1 contains address of allocated area
        MOV  $FB1,@$PPUModule_PS.A2       # Arg 2 - addr of mem block in CPUs RAM
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
    PS.CPU_RAM_Address: .word  FB1
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
    PPUModule_PS.A2:      .word  PPU_UserRamSizeWords   # Argument 2
    PPUModule_PS.A3:      .word  0   # Argument 3
#-------------------------------------------------------------------------------
main.bin:
    .word CORE_START
    .word 0
    .word 0
#-------------------------------------------------------------------------------
