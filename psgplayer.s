# vim: set tabstop=4 :

#---------------------------------------------------------------------------------
#   PLAYING MODULE FOR TWO PSG.PACKED FILES BY VLADIMIR "KUVO" KUTYAKOV / CSI, 02022
#   based on psg_player_v1.0 for Z80 by tmk & bfox
#
#   SPECIAL FOR AZBK BY MAXIM BAGAEV 
#
#   PLATFORM:   Electronika MS0511 + Aberrant Sound Module
#   COMPILER:   GNU Assembler
#
#   BK-0011M version adapted for Electronika MS0511 by aberrant_hacker
#---------------------------------------------------------------------------------

                #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                #!!!
                #!!!    This file is included in UNIP2PSG.mac by .INCLUDE directive
                #!!!
                #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

psgplayer.MUS_PLAY:
        MOV  SP, SP_CALL
        
        MOV  $MUS_1_PARAMS, R5  # AY1, FILE1 (see UNIP2PSG.mac)
        CALL PLAY_ONE_PSG

        MOV  $MUS_2_PARAMS, R5  # AY2, FILE2 (see UNIP2PSG.mac)
                                
PLAY_ONE_PSG:
        MOV  MUS_PAUSE(R5), R0
        BZE  10$

        DEC  R0
        MOV  R0, MUS_PAUSE(R5)
        RETURN

10$:    MOV  CUR_MUS_ADDR(R5), @$PBPADR
        MOV  MUS_DATA_REG(R5), R1
MUS_ADDR_NEXT:
        MOVB (R1), R0
        INC  @$PBPADR
        TSTB R0
        BPL  10$

        JMP  MUS_LINKS
10$:    BZE  MUS_PAUSE_N

        SUB  $0100, R0
        BPL  MUS_PSG2

        SUB  $0177740, R0    
        BPL  MUS_PSG2_INDEX

        ADD  $021, R0
        BNE  2$

       #CMP  @$MUS_PAGES, $036000
       #BEQ  1$

       #MOV  $036000, @$MUS_PAGES
       #MOV  @$MUS_PAGES, @$0177716
       #MOV  $040000, @$FILE_1_PARAMS
       #MOV  $065034, @$FILE_2_PARAMS
        CLR  MUS_STOP_NEED
        BR   MUS_LOOP

1$:     CLR  @$PLAY_NOW
        JMP  MUS_STOP

2$:     BMI  MUS_PSG1

MUS_PAUSE16:
        DEC  R0
        MOV  R0, MUS_PAUSE(R5)
        JMP  MUS_COM_END

MUS_PSG1:
        SUB  $0177762, R0
        MOV  AY_PORT(R5), R2
        MOV  R0, (R2)   # AY REGISTER
        MOVB (R1), (R2) # VALUE
        INC  @$PBPADR
        JMP  MUS_COM_END

MUS_PAUSE_N:
        MOVB (R1), MUS_PAUSE(R5)
        INC  @$PBPADR
        JMP  MUS_COM_END

MUS_LOOP:
       .equiv SP_CALL, .+2
        MOV  $0, SP
        JMP  psgplayer.MUS_INIT

MUS_PSG2:
        MOVB (R1), R2
        INC  @$PBPADR
        BR   MUS_PSG2_OUT

MUS_PSG2_INDEX:
        PUSH @$PBPADR

        MOV  MUS_DATA_ADDR(R5), R2
        ASL  R0
        ADD  R0, R2
        MOV  R2,@$PBPADR
        MOVB (R1), R0
        INC  @$PBPADR
        MOVB (R1), R2

        POP @$PBPADR

MUS_PSG2_OUT:
        CLR  R3
        MOV  AY_PORT(R5), R4
        ASR  R2
        BCC  10$

        MOV  R3, (R4)   # AY REGISTER
        MOVB (R1), (R4) # VALUE
        INC  @$PBPADR
10$:    INC  R3

       .rept 7
        ASR R2
        BCC .+10 # !

        MOV  R3, (R4)   # AY REGISTER
        MOVB (R1), (R4) # VALUE
        INC  @$PBPADR
        INC  R3
       .endr

       .rept 5
        ASR R0
        BCC .+10 # !

        MOV  R3, (R4)   # AY REGISTER
        MOVB (R1), (R4) # VALUE
        INC  @$PBPADR
        INC  R3
       .endr

        ASR R0
        BCC MUS_COM_END

        MOV  R3, (R4)   # AY REGISTER
        MOVB (R1), (R4) # VALUE
        INC  @$PBPADR

MUS_COM_END:
        MOV  @$PBPADR, CUR_MUS_ADDR(R5)

        MOV  BEGIN_MUS_STACK_ADDR(R5), R0
        MOV  CUR_MUS_STACK_ADDR(R5), @$PBPADR
        MOV  $MAX_INNER_CALL, R3
10$:    CMP  R0, @$PBPADR
        BEQ  1$

        DEC  (R0)+
        BZE  MUS_CALL_RET

        TST  (R0)+           #ADD $2, R0
        SOB  R3, 10$
1$:     RETURN

MUS_CALL_RET:
        MOV  (R0), R2
        TST  -(R0)           #SUB $2,R0
        MOV  R0, CUR_MUS_STACK_ADDR(R5)
        MOV  R2, CUR_MUS_ADDR(R5)
        RETURN

MUS_LINKS:
        CLR  R2
        BISB (R1), R2
        INC  @$PBPADR
        MOV  CUR_MUS_STACK_ADDR(R5), R3
        SUB  $0177700, R0
        BMI  MUS_CALL_ONE

        MOV  R0, R4  
MUS_CALL_N:
        CLR  R0
        BISB (R1), R0
        INC  @$PBPADR
        MOV  R0, (R3)+
        MOV  @$PBPADR, (R3)+
        MOV  R3, CUR_MUS_STACK_ADDR(R5)
        SWAB R4
        BISB R2, R4
        SUB  R4, @$PBPADR
        JMP  MUS_ADDR_NEXT

MUS_CALL_ONE:
        SUB  $0177700, R0
        MOV  $1, (R3)+
        MOV  @$PBPADR, (R3)+
        MOV  R3, CUR_MUS_STACK_ADDR(R5)
        SWAB R0
        BISB R2, R0
        SUB  R0, @$PBPADR
        JMP  MUS_ADDR_NEXT

psgplayer.MUS_INIT:
        MOV  $FILE_1_PARAMS, R5
        CALL SETUP_PSG_PARAM

       .equiv MUS_STOP_NEED, .+2
        TST  $-1
        BZE  10$ 

        CALL MUS_STOP
        
10$:    MOV  $FILE_2_PARAMS, R5
        CALL SETUP_PSG_PARAM

        TST  MUS_STOP_NEED
        BNE  MUS_STOP

        MOV  R5, MUS_STOP_NEED
        MOV  PC, R5
        ADD  $psgplayer.MUS_PLAY-., R5
        PUSH R5
        RETURN

 SETUP_PSG_PARAM:
        MOV  (R5)+, R0 # R0 = data register
        MOV  (R5)+, R1 # R1 = music address
        PUSH R5
        MOV  R0, (R5)+ # R0 -> MUS_DATA_REG
        MOV  R1, (R5)+ # R1 -> MUS_DATA_ADDR
        ADD  $INI_INDEXMASK_SIZE, R1 # R1 = music address + 64
        MOV  R1, (R5)+ # R1 -> MUS_LOOP_ADDR
        MOV  R1, (R5)+ # R1 -> CUR_MUS_ADDR
        MOV  R5, R0    # R0 = addr of MUS_STACK
        MOV  $MAX_INNER_CALL_SIZE_WORDS, R1
        10$:
            CLR  (R5)+ # clears mus_stack
        SOB  R1, 10$

        MOV  R0, (R5)+ # MUS_STACK -> BEGIN_MUS_STACK_ADDR
        MOV  R0, (R5)+ # MUS_STACK -> CUR_MUS_STACK_ADDR
        CLR  (R5)+     # -> MUS_PAUSE
        POP  R5
        RETURN
       
MUS_STOP:
      # SEND ZERO TO ALL REGISTERS AY
        MOV  AY_PORT(R5), R4
        MOV  $015, R1
        CLR  R2
10$:    MOV  R1, (R4) # AY REGISTER
        MOVB R2, (R4) # VALUE
        DEC  R1
        BPL  10$

        RETURN

psgplayer.MUTE:
        MOV  $MUS_1_PARAMS, R5
        CALL MUS_STOP
        MOV  $MUS_2_PARAMS, R5
        BR   MUS_STOP

       # MUS_PARAMS
        .equiv INI_INDEXMASK_SIZE, 64
        .equiv INI_MUS_LOOP, 0
        .equiv MAX_INNER_CALL, 7
        .equiv MAX_INNER_CALL_SIZE, MAX_INNER_CALL * 8
        .equiv MAX_INNER_CALL_SIZE_WORDS, MAX_INNER_CALL_SIZE >> 1

       # MUS_PARAMS_OFFSETS
        .equiv MUS_DATA_REG,                                0
        .equiv MUS_DATA_ADDR,        MUS_DATA_REG         + 2
        .equiv MUS_LOOP_ADDR,        MUS_DATA_ADDR        + 2
        .equiv CUR_MUS_ADDR,         MUS_LOOP_ADDR        + 2
        .equiv MUS_STACK,            CUR_MUS_ADDR         + 2
        .equiv BEGIN_MUS_STACK_ADDR, MUS_STACK            + MAX_INNER_CALL_SIZE
        .equiv CUR_MUS_STACK_ADDR,   BEGIN_MUS_STACK_ADDR + 2
        .equiv MUS_PAUSE,            CUR_MUS_STACK_ADDR   + 2
        .equiv AY_PORT,              MUS_PAUSE            + 2

        .equiv SIZE_OF_MUS_PARAMS, AY_PORT - MUS_DATA_REG

#PSG_1_PARAMS:
    AY_1_PARAMS:    .word 0b0100111100000000
                    .word 0
    FILE_1_PARAMS:  .word PBP1DT
                    .word 0100000
    MUS_1_PARAMS:   .space SIZE_OF_MUS_PARAMS
    psgplayer.PSG0: .word PSG0

#PSG_2_PARAMS:
    AY_2_PARAMS:    .word 0b1000111100000000
                    .word 1
    FILE_2_PARAMS:  .word PBP2DT
                    .word 0100000
    MUS_2_PARAMS:   .space SIZE_OF_MUS_PARAMS
    psgplayer.PSG1: .word PSG1
