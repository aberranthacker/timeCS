#---------------------------------------------------------------------
#   PT3 PLAYER with TS support by KUVO, 02022 CSI
#
#       !!! This is a test sample under development !!!
#       !!!    Some tracks may not play correctly   !!!
#
#       !!! PT2 format is not supported !!!
#
#   BASED ON Universal PT3 player for ZX Spectrum and MSX by S.V.Bulba
#
#   BK-0011M version ported for Electronika MS0511 by aberrant_hacker
#
#   PLATFORM:     Elektronika MS 0511
#   SOUND DEVICE: Aberrant Sound Module
#
#   COMPILER:     GNU Assembler
#---------------------------------------------------------------------
PLAYER_ENTRY_POINTS:
                        .word pt3play2.INIT     #+0  First call before playback
                        .word pt3play2.PLAY     #+2  Main play call for the next position in PT3 file (one quark, one tick)
                        .word pt3play2.MUTE     #+4  Mute the sound

INTEGRATION_POINTS:
    NO_REPEAT_MODE:       .word 1 #+034 Play without repeat. Set (not zero) before INIT call.
    REPETITION_NUMBER:    .word 0 #+036 Number of elapsed repetitions after end of PT3 file

# INIT ----------------------------------------------------------------------{{{
TS_ID:
        .ascii "PT3!PT3!02TS"
TS_ID_END:

TS_ID_CHECK:
        MOV $4, R5                  # MOV #4, R4
        10$:                        # 0:
            DEC  (R4) # @$PBPADR
            CMPB (R0), -(R2)        #     CMPB -(R0), -(R2)
            BNE 1237$               #     BNE 1
        SOB R5, 10$                 # SOB R4, 0

1237$:  RETURN                      # 1: RET

CStateTable:

pt3play2.INIT:
        CLR TS_PRESENT                       # CLR TS_PRESENT
                                             # CLR SEL_DEVICE
        MOV $PBPADR,R4
        MOV $PBP12D,R0
        MOV $PPT3.FRAME_NUMBER,(R4)          # CLR FRAME_NUMBER
        CLR (R0)
        MOV $PPT3.END_OF_PT3FILE,(R4)        # CLR END_OF_PT3FILE
        CLR (R0)
                                             # CLR PT3FILE_MODULE2_ADDR
        MOV $PPT3.REPETITION_NUMBER,(R4)     # CLR REPETITION_NUMBER
        CLR (R0)

        MOV $PPT3.PT3FILE_MODULE1_ADDR, (R4) # MOV PT3FILE_MODULE1_ADDR, R1
        MOV (R0), R1 # R1 will be used later by INIT_NEXT
        MOV R1, PT3FILE_MODULE1_ADDR
        MOV $PPT3.PT3FILE_END_ADDR, (R4)
        MOV (R0), (R4)                       # MOV PT3FILE_END_ADDR, R0

        MOV $PARAM_DEVICES_AY1, R3           # MOV #PARAM_DEVICES_AY1, R3
                                             # CLR (R3)+
                                             # MOV #100000, (R3)+
        MOV $PSG0, (R3)+                     # MOV #AY_1_PORT_AZBK, (R3)+

      # TS detect
        MOV $TS_ID_END, R2                   # MOV #TS_ID_END, R2

        CALL TS_ID_CHECK                     # CALL TS_ID_CHECK
        BNE INIT_NEXT                        # BNE INIT_NEXT
      # Skip length of second module
        SUB $2, (R4)                         # SUB #2, R0

        CALL TS_ID_CHECK                     # CALL TS_ID_CHECK
        BNE INIT_NEXT                        # BNE INIT_NEXT
      # Get offset to second module
        CLR  R5                              # CLR R5 ;GET OFFSET TO SECOND MODULE
        DEC  (R4)
        BISB (R0), R5                        # BISB -(R0), R5
        SWAB R5                              # SWAB R5
        DEC  (R4)
        BISB (R0), R5                        # BISB -(R0), R5
       .equiv PT3FILE_MODULE1_ADDR, .+2
        ADD  $0, R5                          # ADD PT3FILE_MODULE1_ADDR, R5 ;GET ADDRESS OF SECOND MODULE
        MOV  R5,PT3FILE_MODULE2_ADDR

        CALL TS_ID_CHECK                     # CALL TS_ID_CHECK
        BNE INIT_NEXT                        # BNE INIT_NEXT

        INC TS_PRESENT                       # INC TS_PRESENT
                                             # MOV R5, -(SP) ; store PT3FILE_MODULE2_ADDR for now

        CALL INIT_NEXT                       # CALL INIT_NEXT

       .equiv PT3FILE_MODULE2_ADDR, .+2
        MOV $0, R1                           # MOV (SP)+, R1 # restore the PT3FILE_MODULE2_ADDR
        MOV $PARAM_DEVICES_AY2, R3           # MOV #PARAM_DEVICES_AY2, R3
                                             # MOV #1, (R3)+
                                             # MOV #40000, (R3)+
        MOV $PSG1, (R3)+                     # MOV #AY_2_PORT_AZBK, (R3)+

INIT_NEXT:
      # R4 = PBPADR
      # R0 = PBP1DT
      # R1 = PT3FILE_MODULEn_ADDR
      # R3 = PARAMETERS_AY[1|2]
        MOV  R3, CUR_PARAMS_ADDR                 # MOV R3, CUR_PARAMS_ADDR

        MOV  R1, PARAM_MODULE_ADDRESS(R3)        # MOV R1, PARAM_MODULE_ADDRESS(R3)
        MOV  R1, R5                              # MOV R1, R5
        MOV  R5,(R4)
      # +100 (1 byte) значение темпа
        ADD  $100,(R4)
        MOVB (R0), PARAM_DELAY(R3)               # MOVB 100.(R5), PARAM_DELAY(R3)
      # +201 (?) список позиций  (ордер)
      # Содержит номера паттернов (0...84), умноженные  на 3
        ADD  $200, R1                            # ADD #200., R1
        MOV  R1, PARAM_CURRENTPOSITION(R3)       # MOV R1, PARAM_CURRENTPOSITION(R3)
     # +102 (1 byte) song loop (0=зацикливание на начало)
        ADD  $2,(R4)                             # MOVB 102.(R5), R2
        MOVB (R0), R2

        ADD  R2, R1                              # ADD R2, R1
        INC  R1                                  # INC R1
        MOV  R1, PARAM_LOOPPOSITION(R3)          # MOV R1, PARAM_LOOPPOSITION(R3)

      # +103 (2 bytes) Psa_chn=смещение от начала модуля до таблицы паттернов.
        CLR  R1                                  # CLR R1
        ADD  $2,(R4)                             # BISB 104(R5), R1
        BISB (R0), R1
        SWAB R1                                  # SWAB R1
        DEC  (R4)                                # BISB 103(R5), R1
        BISB (R0), R1                            # R1: patterns offset

        ADD  R5, R1                              # ADD R5, R1
        MOV  R1, PARAM_PATTERNSPOINTER(R3)       # MOV R1, PARAM_PATTERNSPOINTER(R3)
      # +169 (16*2) смещения от начала модуля до орнаментов, начиная с нулевого.
      # По два байта на орнамент.
        MOV  $169, R1  # R1: ornaments offset    # MOV #169., R1
        ADD  R5, R1                              # ADD R5, R1
        MOV  R1, PARAM_ORNAMENTSPOINTERS(R3)     # MOV R1, PARAM_ORNAMENTSPOINTERS(R3)
      # +105 (32*2) смещения от начала модуля до сэмплов, начиная с нулевого  сэмпла.
      # По два байта  на сэмпл.
        MOV  $105, R1  # R1: samples offset      # MOV #105., R1
        ADD  R5, R1                              # ADD R5, R1
        MOV  R1, PARAM_SAMPLESPOINTERS(R3)       # MOV R1, PARAM_SAMPLESPOINTERS(R3)
#---
        MOV $EMPTY_SAM_ORN_TEMPLATE_END,R2
       .equiv EMPTY_SAM_ORN_TEMPLATE_SIZE, EMPTY_SAM_ORN_TEMPLATE_END - EMPTY_SAM_ORN_TEMPLATE
        MOV $EMPTY_SAM_ORN_TEMPLATE_SIZE, R1
        CLR (R4)
        create_empty_sam_orn_loop:
            DEC (R4)
            MOVB -(R2),(R0)
        SOB R1,create_empty_sam_orn_loop
        MOV (R4),EMPTY_SAM_ORN
#---
        PUSH R5 # store PT3FILE_MODULEn_ADDR     # MOV R5, -(SP)
#---
        MOV  $TABLES_PACK, R4                    # MOV #TABLES_PACK, R4
        MOV  $PARAM_TAB_WORK + 98, R5            # MOV #PARAM_TAB_WORK + 98., R5
        ADD  R3, R5                              # ADD R3, R5

        MOV  $4, R3                              # MOV #4, R3
        MOV  $12, R2                             # MOV #12., R2
        10$:
            MOV (R4)+, R0                        # MOV (R4)+, R0
            ASL  R0                              # ASL R0
            BR   2$                              # BR  2

            1$:
                CLR  R1                          # CLR R1
                BISB (R4)+, R1                   # BISB (R4)+, R1
                ADD R1, R0                       # ADD R1, R0
                ADD R1, R0                       # ADD R1, R0
            2$: MOV R0, -(R5)                    # MOV R0, -(R5)
            SOB R2, 1$                           # SOB R2, 1

            MOVB (R4)+, R2                       # MOVB (R4)+, R2
            INC R4                               # INC R4
            BIC $1, R4                           # BIC #1, R4
        SOB R3, 10$                              # SOB R3, 10

        MOV CUR_PARAMS_ADDR, R5                  # MOV CUR_PARAMS_ADDR, R5

        MOV $PARAM_VAR0START, R1                 # MOV #PARAM_VAR0START, R1
        ADD R5, R1                               # ADD R5, R1
        MOV $PARAM_VAR0END - PARAM_VAR0START, R3 # MOV #PARAM_VAR0END - PARAM_VAR0START, R3
        3$:
            CLRB (R1)+                           # CLRB (R1)+
        SOB R3, 3$                               # SOB R3, 3

        MOVB $1, PARAM_DELAYCOUNTER(R5)          # MOVB #1, PARAM_DELAYCOUNTER(R5)
        MOV $0xF001, R0                          # MOV #0XF001, R0
       .equiv EMPTY_SAM_ORN, .+2
        MOV $0, R2                               # MOV #EMPTY_SAM_ORN, R2
        MOV $PARAM_CHANNEL_A, R4                 # MOV #PARAM_CHANNEL_A, R4
        ADD R5, R4                               # ADD R5, R4
                                                 # MOV (PC)+, R3
        MOV $AY_AMPLITUDEA_TONEA, R3             # .BYTE   AY_TONA, AY_AMPLITUDEA
        CALL FILL
                                                 # MOV (PC)+, R3
        MOV $AY_AMPLITUDEB_TONEB, R3             # .BYTE   AY_TONB, AY_AMPLITUDEB
        CALL FILL
                                                 # MOV (PC)+, R3
        MOV $AY_AMPLITUDEC_TONEC, R3             # .BYTE   AY_TONC, AY_AMPLITUDEC
        CALL FILL

        MOV  $PBPADR,R4
        MOV  $PBP1DT,R3
        POP  (R4) # restore PT3FILE_MODULEn_ADDR # MOV (SP)+, R5

      # +13 (1) "7" (или "6","5","4", или даже "3" ) - номер подверсии.
        ADD $13,(R4)
        MOVB (R3), R0                            # MOVB 13.(R5), R0
        SUB $060, R0                             # SUB #60, R0
        BLO 4$                                   # BCS 4

        CMPB R0, $10                             # CMPB R0, #10.
        BLO 5$                                   # BLO 5

4$:     MOV  $6, R0                              # MOV #6, R0
5$:     MOV  CUR_PARAMS_ADDR, R2                 # MOV CUR_PARAMS_ADDR, R2
        MOVB R0, PARAM_VERSION(R2)               # MOVB R0, PARAM_VERSION(R2)
        PUSH R0                                  # MOV R0, -(SP)
        CMPB R0, $4                              # CMPB R0, #4
      # +99 (1) номер частотной таблицы:
      # 0=Pro Tracker (она же 1625000),
      # 1=Sound Tracker,
      # 2=1750000 (другое название, не соответствующее содержанию - ASM or PSC),
      # 3=RealSound (она же  1625000+, плохая попытка передвинуть табл. 0 под 1.75MHz).
      # Табличка занимает 192 байта и содержит значения делителей частоты для 96 нот, начиная
      # с C-1 (ДО первой октавы).
      # Делитель частоты - значение, помещаемое в соотвующие регистры AY.
      # Младшие байты (здесь  и  ниже, за одним исключением, которое  будет  указано)
      # хранятся  первыми.
      # Компилятор  PT3 (текущие версии PT3 собираются без компилятора) сохраняет таблицу,
      # соответствующую модулю, в  тело  плейера  по относительному адресу 512.
      # Таблицу громкости он сохраняет в том же теле плейера по относительному адресу 256.
        ADD $86,(R4)
        MOVB (R3), R0                            # MOVB 99.(R5), R0
        ROLB R0                                  # ROLB R0
        BIC  $0177770, R0                        # BICB #177770, R0

NOTE_TABLE_MAKER:
        PUSH R1                                  # MOV R1, -(SP)
        MOV  $NT_DATA, R1                        # MOV #NT_DATA, R1
        ADD  R0, R1                              # ADD R0, R1
        ADD  R0, R1                              # ADD R0, R1
        ADD  R0, R1                              # ADD R0, R1
        CLR  R2                                  # CLR R2
        BISB (R1)+, R2                           # BISB (R1)+, R2
        MOV  (PC)+, R0                           # MOV (PC)+, R0
        NOP                                      # NOP
        TSTB (R1)+                               # TSTB (R1)+
        BZE  10$                                 # BEQ 0

        MOV (PC)+, R0                            # MOV (PC)+, R0
        CLC                                      # CLC
10$:    MOV  R0, MULTY_SUBR                      # MOV R0, MULTY_SUBR

        CLR  R3                                  # CLR R3
        BISB (R1), R3                            # BISB (R1), R3
        ADD  $TABLES ,R3                         # ADD #TABLES ,R3
        ADD  (SP)+, R2 # pops stored R1          # ADD  (SP)+, R2

        PUSH R3                                  # MOV R3, -(SP)
        MOV  $PARAM_NOTE_TAB, R1                 # MOV #PARAM_NOTE_TAB, R1
        ADD  CUR_PARAMS_ADDR, R1                 # ADD CUR_PARAMS_ADDR, R1
        PUSH R1                                  # MOV R1, -(SP)

        MOV  $12, R4                             # MOV #12., R4
        1$:
            MOV  (R2)+, R3                       # MOV (R2)+, R3
            PUSH R1                              # MOV R1, -(SP)
            MOV  $8, R5                          # MOV #8., R5
            2$:
                CLC                              # CLC
                ROR  R3                          # ROR R3
                CALL MULTY_SUBR                  # CALL MULTY_SUBR
                MOV  R3, R0                      # MOV R3, R0
                ADC  R0                          # ADC R0
                MOV  R0, (R1)                    # MOV R0, (R1)
                ADD  $24, R1                     # ADD #24., R1
            SOB  R5, 2$                          # SOB R5, 2
            POP  R1                              # MOV (SP)+, R1
            TST  (R1)+                           # TST (R1)+
        SOB  R4, 1$                              # SOB R4, 1

        POP  R2                                  # MOV (SP)+, R2
        POP  R1                                  # MOV (SP)+, R1

        CMP R1, $TAB_C_OLD_1                     # CMP R1, #TAB_C_OLD_1
        BNE 3$                                   # BNE 3

        MOV CUR_PARAMS_ADDR, R0                  # MOV CUR_PARAMS_ADDR, R0
        MOVB $0xFD, PARAM_NOTE_TAB + 056(R0)     # MOVB #0XFD, PARAM_NOTE_TAB + 56(R0)

3$:     CLR  R0                                  # CLR R0
        BISB (R1)+, R0                           # BISB (R1)+, R0
        BZE  5$                                  # BEQ 5

        CLR  R5                                  # CLR R5
        RORB R0                                  # RORB R0
        ROL  R5                                  # ROL R5
        ASLB R0                                  # ASLB R0
        ADD  R0, R2                              # ADD R0, R2
        TST  R5                                  # TST R5
        BZE  4$                                  # BEQ 4

        SUB  $2, (R2)                            # SUB #2, (R2)
4$:     INC  (R2)                                # INC (R2)
        SUB  R0, R2                              # SUB R0, R2
        BR   3$                                  # BR  3

5$:     POP  R0                                  # MOV (SP)+, R0

VOL_TABLE_MAKER:
        MOV $021, R3                             # MOV #21, R3
        CLR R1                                   # CLR R1
        CMPB R0, $5                              # CMPB R0, #5
        MOV (PC)+, R0                            # MOV (PC)+, R0
        ASLB R0                                  # ASLB R0
        BCC 10$                                  # BHIS 0

        DEC R3                                   # DEC R3
        MOV R3, R1                               # MOV R3, R1
        MOV (PC)+, R0                            # MOV (PC)+, R0
        NOP                                      # NOP

10$:    MOV R0, MULTY_SUBR                       # MOV R0, MULTY_SUBR

        MOV $PARAM_VOL_TAB, R4                   # MOV #PARAM_VOL_TAB, R4
        ADD CUR_PARAMS_ADDR, R4                  # ADD CUR_PARAMS_ADDR, R4
        MOV R4, R5                               # MOV R4, R5
        MOV $16, R2                              # MOV #16., R2
        ADD R2, R5                               # ADD R2, R5
        MOV $256 >> 1, R0                        # MOV #256./2, R0
        1$:
            CLR (R4)+                            #     CLR (R4)+
        SOB R0, 1$                               # SOB R0, 1

2$:     PUSH R3                                  # MOV R3, -(SP)

        ADD R3, R1                               # ADD R3, R1
        MOV $0, R3                               # MOV #0, R3
        SBC R3                                   # SBC R3

3$:     MOVB R3, R0                              # MOVB R3, R0
        MOV  R3, R4                              # MOV R3, R4
        CLRB R4                                  # CLRB R4
        SWAB R4                                  # SWAB R4
        CALL MULTY_SUBR                          # CALL MULTY_SUBR
        ADCB R4                                  # ADCB R4
        MOVB R4, (R5)+                           # MOVB R4, (R5)+
        ADD  R1, R3                              # ADD R1, R3
        INC  R2                                  # INC R2
        MOV  R2, R0                              # MOV R2, R0
        BIC  $0177760, R0                        # BIC #177760, R0
        BNZ  3$                                  # BNE 3

        POP  R3                                  # MOV (SP)+, R3
        CMP  R1, $119                            # CMP R1, #119.
        BNE  4$                                  # BNE 4

        INC R1                                   # INC R1
4$:     TSTB R2                                  # TSTB R2
        BNZ 2$                                   # BNE 2

        JMP REG_OUT                              # JMP REG_OUT

MULTY_SUBR:
        NOP                                      # NOP
        RETURN                                   # RET

FILL:
        MOV R0, CHP_NOTE_SKIP_COUNTER(R4)        # MOV R0, CHP_NOTE_SKIP_COUNTER(R4)
        MOV R2, CHP_ADDRESS_IN_PATTERN(R4)       # MOV R2, CHP_ADDRESS_IN_PATTERN(R4)
        MOV R2, CHP_ORNAMENTPOINTER(R4)          # MOV R2, CHP_ORNAMENTPOINTER(R4)
        MOV R2, CHP_SAMPLEPOINTER(R4)            # MOV R2, CHP_SAMPLEPOINTER(R4)
        MOV R3, CHP_TONE_REG(R4)                 # MOV R3, CHP_TONE_REG(R4)
        ADD $CHP, R4                             # ADD #CHP, R4
        RETURN                                   # RET
# INIT ----------------------------------------------------------------------}}}

pt3play2.PLAY:
        MOV $PBPADR,R2
        MOV $PBP1DT,R3

        MOV $PPT3.FRAME_NUMBER,(R2)              # INC FRAME_NUMBER
        INC (R3)

        MOV $PARAMETERS_AY1, R4                  # MOV #PARAMETERS_AY1, R4

       .equiv TS_PRESENT, .+2 # TS sign present
        TST $0                                   # TST TS_PRESENT
        BZE PLAY_NEXT                            # BEQ PLAY_NEXT

        CALL PLAY_NEXT                           # CALL PLAY_NEXT

        MOV $PARAMETERS_AY2, R4                  # MOV #PARAMETERS_AY2, R4
PLAY_NEXT:
      # R4: PARAMETERS_AY[1|2]
        MOV R4, CUR_PARAMS_ADDR                    # MOV R4, CUR_PARAMS_ADDR

        CLR PARAM_ADDTOENVELOPE(R4)                # CLR PARAM_ADDTOENVELOPE(R4)
        CLRB PARAM_AYREGS.AY_MIXER(R4)             # CLRB PARAM_AYREGS + AY_MIXER(R4)
        MOVB $-1, PARAM_AYREGS.AY_ENVELOPETYPE(R4) # MOVB #-1, PARAM_AYREGS + AY_ENVELOPETYPE(R4)
        DECB PARAM_DELAYCOUNTER(R4)                # DECB PARAM_DELAYCOUNTER(R4)
        BNZ 5$ #                                   # BHI 5

        MOV $PARAM_CHANNEL_A, R5                   # MOV #PARAM_CHANNEL_A, R5
        ADD R4, R5                                 # ADD R4, R5

        DECB CHP_NOTE_SKIP_COUNTER(R5)             # DECB CHP_NOTE_SKIP_COUNTER(R5)
        BNZ 2$                                     # BNE 2

        MOV CHP_ADDRESS_IN_PATTERN(R5), (R2)       # MOV CHP_ADDRESS_IN_PATTERN(R5), R3
        TSTB (R3)                                  # TSTB (R3)
        BNZ 1$                                     # BNE 1

        CLRB PARAM_NOISE_BASE(R4)                  # CLRB PARAM_NOISE_BASE(R4)
        MOV  PARAM_CURRENTPOSITION(R4), (R2)       # MOV PARAM_CURRENTPOSITION(R4), R0
        INC  (R2)                                  # INC R0
        MOVB (R3), R1                              # MOVB (R0), R1

        CMPB $0377, R1                             # CMPB #377, R1
        BNE 10$                                    # BNE 0

        MOV $PPT3.END_OF_PT3FILE,(R2)              # INC END_OF_PT3FILE
        INC @$PBP12D

        TST NO_REPEAT_MODE                         # TST NO_REPEAT_MODE
        BZE 20$                                    # BEQ 00

        INCB PARAM_DELAYCOUNTER(R4)                # INCB PARAM_DELAYCOUNTER(R4)
        INCB PARAM_CHANNEL_A.CHP_NOTE_SKIP_COUNTER(R4) # INCB PARAM_CHANNEL_A + CHP_NOTE_SKIP_COUNTER(R4)
        JMP pt3play2.MUTE                          # JMP MUTE

20$:    MOV PARAM_LOOPPOSITION(R4), (R2)           # MOV PARAM_LOOPPOSITION(R4), R0
        MOVB (R3), R1                              # MOVB (R0), R1

        INC REPETITION_NUMBER                      # INC REPETITION_NUMBER ;Next repeat

10$:    MOV (R2), PARAM_CURRENTPOSITION(R4)        # MOV R0, PARAM_CURRENTPOSITION(R4)
        BIC $0xFF00, R1                            # BIC #177400, R1
        ASL R1                                     # ASL R1
        ADD PARAM_PATTERNSPOINTER(R4), R1          # ADD PARAM_PATTERNSPOINTER(R4), R1
        MOV R1,(R2)
        MOV PARAM_MODULE_ADDRESS(R4), R1           # MOV PARAM_MODULE_ADDRESS(R4), R2

        CLR R0                                     # CLR R3
        BISB (R3), R0                              # BISB (R1)+, R3
        INC (R2)
        SWAB R0                                    # SWAB R3
        BISB (R3), R0                              # BISB (R1)+, R3
        INC (R2)
        SWAB R0                                    # SWAB R3
        ADD R1, R0                                 # ADD R2, R3
        MOV R0, PARAM_CHANNEL_A.CHP_ADDRESS_IN_PATTERN(R4)

        CLR R0                                     # CLR R0
        BISB (R3), R0                              # BISB (R1)+, R0
        INC  (R2)
        SWAB R0                                    # SWAB R0
        BISB (R3), R0                              # BISB (R1)+, R0
        INC  (R2)
        SWAB R0                                    # SWAB R0
        ADD R1, R0                                 # ADD R2, R0
        MOV R0, PARAM_CHANNEL_B.CHP_ADDRESS_IN_PATTERN(R4) # MOV R0, PARAM_CHANNEL_B + CHP_ADDRESS_IN_PATTERN(R4)

        CLR R0                                     # CLR R0
        BISB (R3), R0                              # BISB (R1)+, R0
        INC  (R2)
        SWAB R0                                    # SWAB R0
        BISB (R3), R0                              # BISB (R1)+, R0
        INC  (R2)
        SWAB R0                                    # SWAB R0
        ADD R1, R0                                 # ADD R2, R0
        MOV R0, PARAM_CHANNEL_C.CHP_ADDRESS_IN_PATTERN(R4) # MOV R0, PARAM_CHANNEL_C + CHP_ADDRESS_IN_PATTERN(R4)
#-------------------------------------------------------------------------------
        MOV PARAM_CHANNEL_A.CHP_ADDRESS_IN_PATTERN(R4),(R2)

1$:     CALL PATTERN_INTERPR                       # CALL PATTERN_INTERPR
      # R5: PARAM_CHANNEL_A
        MOV (R2), CHP_ADDRESS_IN_PATTERN(R5)       # MOV R3, CHP_ADDRESS_IN_PATTERN(R5)

2$:     ADD $CHP, R5                               # ADD #CHP, R5
      # R5: PARAM_CHANNEL_B
        DECB CHP_NOTE_SKIP_COUNTER(R5)             # DECB CHP_NOTE_SKIP_COUNTER(R5)
        BNZ 3$                                     # BNE 3

        MOV CHP_ADDRESS_IN_PATTERN(R5), (R2)       # MOV CHP_ADDRESS_IN_PATTERN(R5), R3
        CALL PATTERN_INTERPR                       # CALL PATTERN_INTERPR
        MOV (R2), CHP_ADDRESS_IN_PATTERN(R5)       # MOV R3, CHP_ADDRESS_IN_PATTERN(R5)

3$:     ADD $CHP, R5                               # ADD #CHP, R5
      # R5: PARAM_CHANNEL_C
        DECB CHP_NOTE_SKIP_COUNTER(R5)             # DECB CHP_NOTE_SKIP_COUNTER(R5)
        BNZ 4$                                     # BNE 4

        MOV CHP_ADDRESS_IN_PATTERN(R5), (R2)       # MOV CHP_ADDRESS_IN_PATTERN(R5), R3
        CALL PATTERN_INTERPR                       # CALL PATTERN_INTERPR
        MOV (R2), CHP_ADDRESS_IN_PATTERN(R5)       # MOV R3, CHP_ADDRESS_IN_PATTERN(R5)

4$:     MOVB PARAM_DELAY(R4), PARAM_DELAYCOUNTER(R4) # MOVB PARAM_DELAY(R4), PARAM_DELAYCOUNTER(R4)

5$:     MOV $PARAM_CHANNEL_A, R5                   # MOV #PARAM_CHANNEL_A, R5
        ADD R4, R5                                 # ADD R4, R5

        CALL CHANGE_REGS                           # CALL CHANGE_REGS
        CALL CHANGE_REGS                           # CALL CHANGE_REGS
        CALL CHANGE_REGS                           # CALL CHANGE_REGS
      # R1: CUR_PARAMS_ADDR
        MOVB PARAM_NOISE_BASE(R1), R0              # MOVB PARAM_NOISE_BASE(R2), R0
        ADD PARAM_ADDTONOISE(R1), R0               # ADD PARAM_ADDTONOISE(R2), R0
        MOVB R0, PARAM_AYREGS.AY_NOISE(R1)         # MOVB R0, PARAM_AYREGS + AY_NOISE(R2)

        MOV PARAM_ENVELOPE_BASE(R1), R0            # MOV PARAM_ENVELOPE_BASE(R2), R0
        ADD PARAM_ADDTOENVELOPE(R1), R0            # ADD PARAM_ADDTOENVELOPE(R2), R0
        ADD PARAM_CUR_ENV_SLIDE(R1), R0            # ADD PARAM_CUR_ENV_SLIDE(R2), R0
        MOVB R0, PARAM_AYREGS.AY_ENVELOPE_LSB(R1)  # MOVB R0, PARAM_AYREGS + AY_ENVELOPE(R2)
        SWAB R0                                    # SWAB R0
        MOVB R0, PARAM_AYREGS.AY_ENVELOPE_MSB(R1)  # MOVB R0, PARAM_AYREGS + AY_ENVELOPE + 1(R2)

        MOV $PARAM_CUR_ENV_DELAY, R0               # MOV #PARAM_CUR_ENV_DELAY, R0
        ADD R1, R0                                 # ADD R2, R0
        TSTB (R0)                                  # TSTB (R0)
        BZE REG_OUT                                # BEQ REG_OUT

        DECB (R0)                                  # DECB (R0)
        BNZ REG_OUT                                # BNE REG_OUT

        MOVB PARAM_ENV_DELAY(R1), (R0)             # MOVB PARAM_ENV_DELAY(R2), (R0)
        ADD PARAM_ENV_SLIDE_ADD(R1), PARAM_CUR_ENV_SLIDE(R1) # ADD PARAM_ENV_SLIDE_ADD(R2), PARAM_CUR_ENV_SLIDE(R2)

REG_OUT:
       .equiv CUR_PARAMS_ADDR, .+2
        MOV $0, R0                                 # MOV CUR_PARAMS_ADDR, R0
        MOV R0, R4                                 # MOV R0, R4

        MOV -(R0), pt3play2.AY_PORT                # MOV -(R0), AY_PORT_AZBK
                                                   # MOV -(R0), GS_SELECTOR
                                                   # MOV -(R0), TS_SELECTOR

        ADD $PARAM_AYREGS.AY_ENVELOPETYPE, R4      # ADD #PARAM_AYREGS + AY_ENVELOPETYPE, R4

       .equiv pt3play2.AY_PORT, .+2                # MOV (PC)+, R5
        MOV  $DummyPSG,R5                          # AY_PORT_AZBK: .WORD 0
        MOV  $015, R1                              # MOV #15, R1
        MOVB (R4), R0                              # MOVB (R4), R0
        BMI  10$                                   # BMI 0

        MOV  R1, (R5)                              # MOVB R1, (R5)
        MOVB R0, (R5)                              # MOVB R0, 1(R5)
10$:    DEC  R1                                    # DEC R1
        BMI  1237$                                 # BMI 1

        MOV  R1, (R5)                              # MOVB R1, (R5)
        MOVB -(R4), (R5)                           # MOVB -(R4), 1(R5)
        BR   10$                                   # BR 0

1237$:  RETURN                                     # RET

pt3play2.MUTE: #-------------------------------------------------------------{{{
        MOV $PARAMETERS_AY1, R4                    # MOV #PARAMETERS_AY1, R4
        CALL pt3play2.MUTE_NEXT                    # CALL MUTE_NEXT
        MOV $PARAMETERS_AY2, R4                    # R4 MOV #PARAMETERS_AY2, R4
pt3play2.MUTE_NEXT:
        MOV R4, CUR_PARAMS_ADDR                    # MOV R4, CUR_PARAMS_ADDR
        CLR  PARAM_AYREGS.AY_AMPLITUDEA(R4)        # CLR PARAM_AYREGS + AY_AMPLITUDEA(R4)
        CLRB PARAM_AYREGS.AY_AMPLITUDEC(R4)        # CLRB PARAM_AYREGS + AY_AMPLITUDEC(R4)
        MOVB $077, PARAM_AYREGS.AY_MIXER(R4)       # MOVB #77, PARAM_AYREGS + AY_MIXER(R4)
        BR REG_OUT                                 # BR REG_OUT
#----------------------------------------------------------------------------}}}

PD_ORSM:
        CLRB CHP_ENVELOPE_ENABLED(R5)              # CLRB CHP_ENVELOPE_ENABLED(R5)
        CALL SET_ORNAMENT                          # CALL SET_ORNAMENT
        MOVB (R3), R0                              # MOVB (R3)+, R0
        INC  (R2)
        BR  PD_SAM_                                # BR  PD_SAM_

PD_SAM:
        SUB $0xD0, R0                              # SUB #0XD0, R0
        ASL R0                                     # ASL R0
PD_SAM_:
        MOV (R2), R1 # store current (R2)

        ADD PARAM_SAMPLESPOINTERS(R4), R0          # ADD PARAM_SAMPLESPOINTERS(R4), R0
        MOV R0, (R2)

        CLR R0                                     # CLR R1
        BISB (R3), R0                              # BISB (R0)+, R1
        INC  (R2)
        SWAB R0                                    # SWAB R1
        BISB (R3), R0                              # BISB (R0), R1
        SWAB R0                                    # SWAB R1

        MOV R1,(R2)  # restore (R2)

        TST R0                                     # TST R1
        BZE 1$                                     # BEQ 0

        ADD PARAM_MODULE_ADDRESS(R4), R0          # ADD PARAM_MODULE_ADDRESS(R4), R1
        MOV R0, CHP_SAMPLEPOINTER(R5)             # MOV R1, CHP_SAMPLEPOINTER(R5)
    1$: BR  PD_LOOP                               # BR  PD_LOOP

PD_VOL:
        BIC $0xFFF0, R0                           # BIC #0XFFF0, R0
        ASL R0                                    # ASL R0
        ASL R0                                    # ASL R0
        ASL R0                                    # ASL R0
        ASL R0                                    # ASL R0
        MOVB R0, CHP_VOLUME(R5)                   # MOVB R0, CHP_VOLUME(R5)
        BR  PD_LOOP                               # BR  PD_LOOP

PD_EOFF:
        CLRB CHP_ENVELOPE_ENABLED(R5)             # CLRB CHP_ENVELOPE_ENABLED(R5)
        CLRB CHP_POSITION_IN_ORNAMENT(R5)         # CLRB CHP_POSITION_IN_ORNAMENT(R5)
        BR  PD_LOOP                               # BR  PD_LOOP

PD_SORE:
        BIC $0xFFF0, R0                           # BIC #0XFFF0, R0
        DECB R0                                   # DECB R0
        BNZ PD_ENV                                # BNE PD_ENV
        MOVB (R3), CHP_NUMBER_OF_NOTES_TO_SKIP(R5) # MOVB (R3)+, CHP_NUMBER_OF_NOTES_TO_SKIP(R5)
        INC  (R2)
        BR  PD_LOOP                               # BR  PD_LOOP

PD_ENV:
        CALL SET_ENVELOPE                         # CALL SET_ENVELOPE
        CLRB CHP_POSITION_IN_ORNAMENT(R5)         # CLRB CHP_POSITION_IN_ORNAMENT(R5)
        BR  PD_LOOP                               # BR  PD_LOOP

PD_ORN:
        CALL SET_ORNAMENT                         # CALL SET_ORNAMENT
        BR  PD_LOOP                               # BR  PD_LOOP

PD_ESAM:
        CLRB CHP_ENVELOPE_ENABLED(R5)             # CLRB CHP_ENVELOPE_ENABLED(R5)
        BIC $0xFFF0, R0                           # BIC #0XFFF0, R0
        BZE 1$                                    # BEQ 0

        CALL SET_ENVELOPE                         # CALL SET_ENVELOPE
    1$: CLRB CHP_POSITION_IN_ORNAMENT(R5)         # CLRB CHP_POSITION_IN_ORNAMENT(R5)
        MOVB (R3), R0                             # MOVB (R3)+, R0
        INC  (R2)
        BR  PD_SAM_                               # BR  PD_SAM_

PATTERN_INTERPR:
      # was 
      # IN:  R3: PARAM_CHANNEL_[A|B|C].CHP_ADDRESS_IN_PATTERN
      # now:
      # IN: 
      #     R2: PBPADR
      #     (R2): PARAM_CHANNEL_[A|B|C].CHP_ADDRESS_IN_PATTERN
      #     R3: PBP1DT
      #
      # R4: CUR_PARAMS_ADDR
      # R5: CUR_PARAMS_ADDR.PARAM_CHANNEL_A
        MOV CHP_NOTE(R5), PARAM_PRNOTE(R4)        # MOV CHP_NOTE(R5), PARAM_PRNOTE(R4)
        MOV CHP_CURRENT_TON_SLIDING(R5), PARAM_PRSLIDING(R4) # MOV CHP_CURRENT_TON_SLIDING(R5), PARAM_PRSLIDING(R4)

PD_LOOP:
        CLR R0                                    # CLR R0
        BISB (R3), R0                             # BISB (R3)+, R0
        INC  (R2)
        CMPB R0, $0xF0                            # CMPB R0, #0XF0
        BHIS PD_ORSM                              # BHIS PD_ORSM

        CMPB R0, $0xD0                            # CMPB R0, #0XD0
        BEQ PD_FIN                                # BEQ PD_FIN
        BHI PD_SAM                                # BHI PD_SAM

        CMPB R0, $0xC0                            # CMPB R0, #0XC0
        BEQ PD_REL                                # BEQ PD_REL
        BHI PD_VOL                                # BHI PD_VOL

        CMPB R0, $0xB0                            # CMPB R0, #0XB0
        BEQ PD_EOFF                               # BEQ PD_EOFF
        BHI PD_SORE                               # BHI PD_SORE

        CMPB R0, $0x50                            # CMPB R0, #0X50
        BHIS PD_NOTE                              # BHIS PD_NOTE

        CMPB R0, $0x40                            # CMPB R0, #0X40
        BHIS PD_ORN                               # BHIS PD_ORN

        CMPB R0, $0x20                            # CMPB R0, #0X20
        BHIS PD_NOIS                              # BHIS PD_NOIS

        CMPB R0, $0x10                            # CMPB R0, #0X10
        BHIS PD_ESAM                              # BHIS PD_ESAM

        ASL R0                                    # ASL R0
        PUSH SPEC_SUBR(R0) # push RETURN address  # MOV SPEC_SUBR(R0), -(SP)
        BR  PD_LOOP                               # BR  PD_LOOP

PD_NOIS:
        BIC $0xFFE0, R0                           # BIC #0XFFE0, R0
        MOVB R0, PARAM_NOISE_BASE(R4)             # MOVB R0, PARAM_NOISE_BASE(R4)
        BR  PD_LOOP                               # BR  PD_LOOP

PD_REL:
        CLRB CHP_ENABLED(R5)                      # CLRB CHP_ENABLED(R5)
        BR  PD_RES                                # BR  PD_RES

PD_NOTE:
        SUB $0x50, R0                             # SUB #0X50, R0
        MOV R0, CHP_NOTE(R5)                      # MOV R0, CHP_NOTE(R5)
        MOVB $-1, CHP_ENABLED(R5)                 # MOVB #-1, CHP_ENABLED(R5)
PD_RES:
        MOV R5, R0                                # MOV R5, R0
        CLR (R0)+                                 # CLR (R0)+
        CLR (R0)+                                 # CLR (R0)+
        CLR (R0)+                                 # CLR (R0)+
        CLR (R0)+                                 # CLR (R0)+
        CLR (R0)+                                 # CLR (R0)+
        CLR (R0)                                  # CLR (R0)
PD_FIN:
        MOVB CHP_NUMBER_OF_NOTES_TO_SKIP(R5), CHP_NOTE_SKIP_COUNTER(R5) # MOVB CHP_NUMBER_OF_NOTES_TO_SKIP(R5), CHP_NOTE_SKIP_COUNTER(R5)
        RETURN

SUBR_PORTM:
        CLRB CHP_SIMPLEGLISS(R5)                  # CLRB CHP_SIMPLEGLISS(R5)
        MOVB (R3), R0                             # MOVB (R3)+, R0
        INC  (R2)

        INC  (R2)                                 # INC R3
        INC  (R2)                                 # INC R3
        MOVB R0, CHP_TON_SLIDE_DELAY(R5)          # MOVB R0, CHP_TON_SLIDE_DELAY(R5)
        MOVB R0, CHP_TON_SLIDE_COUNT(R5)          # MOVB R0, CHP_TON_SLIDE_COUNT(R5)

        MOV CHP_NOTE(R5), R0                      # MOV CHP_NOTE(R5), R2
        MOV R0, CHP_SLIDE_TO_NOTE(R5)             # MOV R2, CHP_SLIDE_TO_NOTE(R5)
        ASL R0                                    # ASL R2
        ADD R4, R0                                # ADD R4, R2
        MOV PARAM_NOTE_TAB(R0), R0                # MOV PARAM_NOTE_TAB(R2), R2

        MOV PARAM_PRNOTE(R4), R1                  # MOV PARAM_PRNOTE(R4), R1
        MOV R1, CHP_NOTE(R5)                      # MOV R1, CHP_NOTE(R5)
        ASL R1                                    # ASL R1
        ADD R4, R1                                # ADD R4, R1
        MOV PARAM_NOTE_TAB(R1), R1                # MOV PARAM_NOTE_TAB(R1), R1

        SUB R1, R0                                # SUB R1, R2
        MOV R0, CHP_TON_DELTA(R5)                 # MOV R2, CHP_TON_DELTA(R5)

        MOV CHP_CURRENT_TON_SLIDING(R5), R1       # MOV CHP_CURRENT_TON_SLIDING(R5), R1
        CMPB PARAM_VERSION(R4), $6                # CMPB PARAM_VERSION(R4), #6
        BLO OLDPRTM                               # BLO OLDPRTM

        MOV PARAM_PRSLIDING(R4), R1               # MOV PARAM_PRSLIDING(R4), R1
        MOV R1, CHP_CURRENT_TON_SLIDING(R5)       # MOV R1, CHP_CURRENT_TON_SLIDING(R5)

OLDPRTM:
        CLR R0                                   # CLR R0
        BISB (R3), R0                            # BISB (R3)+, R0
        INC  (R2)
        SWAB R0                                  # SWAB R0
        BISB (R3), R0                            # BISB (R3)+, R0
        INC  (R2)
        SWAB R0                                  # SWAB R0

        TST R0                                   # TST R0
        BPL 1$                                   # BPL 0

        NEG R0                                   # NEG R0
    1$: CMP CHP_TON_DELTA(R5), R1                # 0: SUB R1, R2
        BPL 2$                                   # BPL 1
        NEG R0                                   # NEG R0

    2$: MOV R0, CHP_TON_SLIDE_STEP(R5)           # 1: MOV R0, CHP_TON_SLIDE_STEP(R5)
        CLRB CHP_CURRENT_ONOFF(R5)               # CLRB CHP_CURRENT_ONOFF(R5)
        RETURN                                   # RET

SUBR_GLISS:
        MOVB (PC), CHP_SIMPLEGLISS(R5)           # MOVB (PC), CHP_SIMPLEGLISS(R5)
        MOVB (R3), R0                            # MOVB (R3)+, R0
        INC  (R2)
        MOVB R0, CHP_TON_SLIDE_DELAY(R5)         # MOVB R0, CHP_TON_SLIDE_DELAY(R5)
        BNZ GL36                                 # BNE GL36

        CMPB PARAM_VERSION(R4), $7               # CMPB PARAM_VERSION(R4), #7
        BLO GL36                                 # BLO GL36

        INCB R0                                  # INCB R0
GL36:   MOVB R0, CHP_TON_SLIDE_COUNT(R5)         # MOVB R0, CHP_TON_SLIDE_COUNT(R5)
        MOVB (R3), CHP_TON_SLIDE_STEP(R5)        # MOVB (R3)+, CHP_TON_SLIDE_STEP(R5)
        INC  (R2)
        MOVB (R3), CHP_TON_SLIDE_STEP + 1(R5)    # MOVB (R3)+, CHP_TON_SLIDE_STEP + 1(R5)
        INC  (R2)
        CLRB CHP_CURRENT_ONOFF(R5)               # CLRB CHP_CURRENT_ONOFF(R5)
        RETURN                                   # RET

SUBR_SMPOS:
        MOVB (R3), CHP_POSITION_IN_SAMPLE(R5)    # MOVB (R3)+, CHP_POSITION_IN_SAMPLE(R5)
        INC  (R2)
        RETURN                                   # RET

SUBR_ORPOS:
        MOVB (R3), CHP_POSITION_IN_ORNAMENT(R5)  # MOVB (R3)+, CHP_POSITION_IN_ORNAMENT(R5)
        INC  (R2)
        RETURN                                   # RET

SUBR_VIBRT:
        MOVB (R3), CHP_ONOFF_DELAY(R5)           # MOVB (R3), CHP_ONOFF_DELAY(R5)
        MOVB (R3), CHP_CURRENT_ONOFF(R5)         # MOVB (R3)+, CHP_CURRENT_ONOFF(R5)
        INC  (R2)
        MOVB (R3), CHP_OFFON_DELAY(R5)           # MOVB (R3)+, CHP_OFFON_DELAY(R5)
        INC  (R2)
        CLRB CHP_TON_SLIDE_COUNT(R5)             # CLRB CHP_TON_SLIDE_COUNT(R5)
        CLR CHP_CURRENT_TON_SLIDING(R5)          # CLR CHP_CURRENT_TON_SLIDING(R5)
        RETURN                                   # RET

SUBR_ENGLS:
        MOVB (R3), PARAM_ENV_DELAY(R4)           # MOVB (R3), PARAM_ENV_DELAY(R4)
        MOVB (R3), PARAM_CUR_ENV_DELAY(R4)       # MOVB (R3)+, PARAM_CUR_ENV_DELAY(R4)
        INC  (R2)
        MOVB (R3), PARAM_ENV_SLIDE_ADD_LSB(R4)   # MOVB (R3)+, PARAM_ENV_SLIDE_ADD(R4)
        INC  (R2)
        MOVB (R3), PARAM_ENV_SLIDE_ADD_MSB(R4)   # MOVB (R3)+, PARAM_ENV_SLIDE_ADD + 1(R4)
        INC  (R2)
        RETURN

SUBR_DELAY:
        MOVB (R3), PARAM_DELAY(R4)               # MOVB (R3)+, PARAM_DELAY(R4)
        INC  (R2)
        RETURN                                   # RET

SET_ENVELOPE:
        MOVB $0x10, CHP_ENVELOPE_ENABLED(R5)      # MOVB #0X10, CHP_ENVELOPE_ENABLED(R5)
        MOVB R0, PARAM_AYREGS.AY_ENVELOPETYPE(R4) # MOVB R0, PARAM_AYREGS + AY_ENVELOPETYPE(R4)
        MOVB (R3), PARAM_ENVELOPE_BASE + 1(R4)    # MOVB (R3)+, PARAM_ENVELOPE_BASE + 1(R4)
        INC (R2)
        MOVB (R3), PARAM_ENVELOPE_BASE(R4)        # MOVB (R3)+, PARAM_ENVELOPE_BASE(R4)
        INC (R2)
        CLRB PARAM_CUR_ENV_DELAY(R4)              # CLRB PARAM_CUR_ENV_DELAY(R4)
        CLR PARAM_CUR_ENV_SLIDE(R4)               # CLR PARAM_CUR_ENV_SLIDE(R4)
SUBR_NOP:
        RETURN

SET_ORNAMENT:
        MOV (R2), R1 # store (R2)

        BIC $0xFFF0, R0                           # BIC #0XFFF0, R0
        ASL R0                                    # ASL R0
        ADD PARAM_ORNAMENTSPOINTERS(R4), R0       # ADD PARAM_ORNAMENTSPOINTERS(R4), R0
        MOV R0, (R2)

        CLR R0                                    # CLR R1
        BISB (R3), R0                             # BISB (R0)+, R1
        INC  (R2)
        SWAB R0                                   # SWAB R1
        BISB (R3), R0                             # BISB (R0), R1
        SWAB R0                                   # SWAB R1

        TST R0                                    # TST R1
        BNZ 1$                                    # BNE 0

        MOV EMPTY_SAM_ORN, R0                     # MOV #EMPTY_SAM_ORN, R1
        BR 2$                                     # BR 1
    1$: ADD PARAM_MODULE_ADDRESS(R4), R0          # ADD PARAM_MODULE_ADDRESS(R4), R1

    2$: MOV R0, CHP_ORNAMENTPOINTER(R5)           # MOV R1, CHP_ORNAMENTPOINTER(R5)
        CLRB CHP_POSITION_IN_ORNAMENT(R5)         # CLRB CHP_POSITION_IN_ORNAMENT(R5)

        MOV R1, (R2) # restore (R2)
        RETURN                                    # RET

SPEC_SUBR:  .word   SUBR_NOP
            .word   SUBR_GLISS
            .word   SUBR_PORTM
            .word   SUBR_SMPOS
            .word   SUBR_ORPOS
            .word   SUBR_VIBRT
            .word   SUBR_NOP
            .word   SUBR_NOP
            .word   SUBR_ENGLS
            .word   SUBR_DELAY
            .word   SUBR_NOP
            .word   SUBR_NOP
            .word   SUBR_NOP
            .word   SUBR_NOP
            .word   SUBR_NOP
            .word   SUBR_NOP

CHANGE_REGS:
       # IN:  R2: PBPADR
       #      R3: PBP1DT
       #      R5: CUR_PARAMS_ADDR.PARAM_CHANNEL_[A|B|C]
       #
       # OUT: R1: CUR_PARAMS_ADDR
       #      R5: CUR_PARAMS_ADDR.PARAM_CHANNEL_[B|C|x]
       # CORRUPTS: R0, R3, R4
        CLR ampl_reg                             # CLR R1
        TSTB CHP_ENABLED(R5)                     # TSTB CHP_ENABLED(R5)
        BNZ CHANGE_REGS_NEXT                     # BNE CHANGE_REGS_NEXT

CHANGE_REGS_EXIT:
        MOVB CHP_AMPL_REG(R5), R0                # MOVB CHP_AMPL_REG(R5), R0
        MOV CUR_PARAMS_ADDR, R1                  # MOV CUR_PARAMS_ADDR, R2
        ADD R1, R0                               # ADD R2, R0
       .equiv ampl_reg, .+2
        MOVB $0, PARAM_AYREGS(R0)                # MOVB R1, PARAM_AYREGS(R0)
        ASRB PARAM_AYREGS.AY_MIXER(R1)           # ASRB PARAM_AYREGS + AY_MIXER(R2)
        TSTB CHP_CURRENT_ONOFF(R5)               # TSTB CHP_CURRENT_ONOFF(R5)
        BZE 2$                                   # BEQ 1

        DECB CHP_CURRENT_ONOFF(R5)               # DECB CHP_CURRENT_ONOFF(R5)
        BNZ 2$                                   # BNE 1

        MOVB CHP_ONOFF_DELAY(R5), R0             # MOVB CHP_ONOFF_DELAY(R5), R0
        COMB CHP_ENABLED(R5)                     # COMB CHP_ENABLED(R5)
        BNZ 1$                                   # BNE 0

        MOVB CHP_OFFON_DELAY(R5), R0             # MOVB CHP_OFFON_DELAY(R5), R0
    1$: MOVB R0, CHP_CURRENT_ONOFF(R5)           # 0: MOVB R0, CHP_CURRENT_ONOFF(R5)
    2$: ADD $CHP, R5                             # 1: ADD #CHP, R5

        RETURN                                   # RET

CHANGE_REGS_NEXT:
        MOV CHP_ORNAMENTPOINTER(R5), (R2)        # MOV CHP_ORNAMENTPOINTER(R5), R1
        MOVB (R3), R4                            # MOVB (R1)+, R4
        INC (R2)
      # R3 <-> R1
        MOVB (R3), R1                            # MOVB (R1)+, R3
        INC (R2)
        MOVB CHP_POSITION_IN_ORNAMENT(R5), R0    # MOVB CHP_POSITION_IN_ORNAMENT(R5), R0
        ADD R0, (R2)                             # ADD R0, R1
        INCB R0                                  # INCB R0
        CMPB R0, R1                              # CMPB R0, R3
        BLO 100$                                 # BLO 0

        MOVB R4, R0                              # MOVB R4, R0
100$:   MOVB R0, CHP_POSITION_IN_ORNAMENT(R5)    # 0: MOVB R0, CHP_POSITION_IN_ORNAMENT(R5)

        MOV CHP_NOTE(R5), R0                     # MOV CHP_NOTE(R5), R0
        MOVB (R3), R1                            # MOVB (R1), R1
        ADD R1, R0                               # ADD R1, R0
        BPL 1$                                   # BPL 1

        CLR R0                                   # CLR R0
1$:     CMP R0, $96                              # 1: CMP R0, #96.
        BLO 2$                                   # BLO 2

        MOV $95, R0                              # MOV #95., R0
2$:     ASL R0                                   # 2: ASL R0
        PUSH R0 # note table offset              # MOV R0, -(SP)

        MOV CHP_SAMPLEPOINTER(R5), (R2)          # MOV CHP_SAMPLEPOINTER(R5), R1
        MOVB (R3), R4                            # MOVB (R1)+, R4
        INC (R2)
      # R3 <-> R1
        MOVB (R3), R1                            # MOVB (R1)+, R3
        INC (R2)
        MOVB CHP_POSITION_IN_SAMPLE(R5), R0      # MOV CHP_POSITION_IN_SAMPLE(R5), R1
        ADD R0, (R2)                             # ADD R0, R1
        ADD R0, (R2)                             # ADD R0, R1
        ADD R0, (R2)                             # ADD R0, R1
        ADD R0, (R2)                             # ADD R0, R1
        INCB R0                                  # INCB R0
        CMPB R0, R1                              # CMPB R0, R3
        BLO 3$                                   # BLO 3

        MOVB R4, R0                              # MOVB R4, R0
3$:     MOVB R0, CHP_POSITION_IN_SAMPLE(R5)      # 3: MOVB R0, CHP_POSITION_IN_SAMPLE(R5)

      # R3 <-> R1
        MOVB (R3), R1                            # MOVB (R1)+, R3
        INC (R2)
        MOVB (R3), R4                            # MOVB (R1)+, R4
        INC (R2)

        CLR R0                                   # CLR R2
        BISB (R3), R0                            # BISB (R1)+, R2
        INC (R2)
        SWAB R0                                  # SWAB R2
        BISB (R3), R0                            # BISB (R1)+, R2
        INC (R2)
        SWAB R0                                  # SWAB R2
        ADD CHP_TON_ACCUMULATOR(R5), R0          # ADD CHP_TON_ACCUMULATOR(R5), R2

        BIT $0x40, R4                            # BIT #0X40, R4
        BZE 4$                                   # BEQ 4

        MOV R0, CHP_TON_ACCUMULATOR(R5)          # MOV R2, CHP_TON_ACCUMULATOR(R5)
      # store R1 (former R3) to address register
4$:     MOV R1,(R2)                              # 4: MOV (SP)+, R1
        POP R1 # restore note table offset
        ADD CUR_PARAMS_ADDR, R1                  # ADD CUR_PARAMS_ADDR, R1
        ADD PARAM_NOTE_TAB(R1), R0               # ADD PARAM_NOTE_TAB(R1), R2
        MOV CHP_CURRENT_TON_SLIDING(R5), R1      # MOV CHP_CURRENT_TON_SLIDING(R5), R1
        ADD R1, R0                               # ADD R1, R2
        BIC $0xF000, R0                          # BIC $0xF000, R2

        PUSH R0  # PUSH 'R2' ↑
        MOVB CHP_TONE_REG(R5), R0                # MOVB CHP_TONE_REG(R5), R0
        ADD CUR_PARAMS_ADDR, R0                  # ADD CUR_PARAMS_ADDR, R0
        POP PARAM_AYREGS(R0)                     # MOV R2, PARAM_AYREGS(R0)

        TSTB CHP_TON_SLIDE_COUNT(R5)             # TSTB CHP_TON_SLIDE_COUNT(R5)
        BZE 7$                                   # BEQ 7

        DECB CHP_TON_SLIDE_COUNT(R5)             # DECB CHP_TON_SLIDE_COUNT(R5)
        BNZ 7$                                   # BNE 7

        MOVB CHP_TON_SLIDE_DELAY(R5), CHP_TON_SLIDE_COUNT(R5) # MOVB CHP_TON_SLIDE_DELAY(R5), CHP_TON_SLIDE_COUNT(R5)
        MOV CHP_TON_SLIDE_STEP(R5), R0           # MOV CHP_TON_SLIDE_STEP(R5), R2
        ADD R0, R1                               # ADD R2, R1
        MOV R1, CHP_CURRENT_TON_SLIDING(R5)      # MOV R1, CHP_CURRENT_TON_SLIDING(R5)
        TSTB CHP_SIMPLEGLISS(R5)                 # TSTB CHP_SIMPLEGLISS(R5)
        BNZ 7$                                   # BNE 7

                                                 # MOV CHP_TON_DELTA(R5), R0
        TST R0                                   # TST R2
        BPL 5$                                   # BPL 5

        CMP R1, CHP_TON_DELTA(R5)                # CMP R1, R0
        BLE 6$                                   # BLE 6
        BR  7$                                   # BR  7

5$:     CMP R1, CHP_TON_DELTA(R5)                # CMP R1, R0
        BLT 7$                                   # BLT 7

6$:     MOV CHP_SLIDE_TO_NOTE(R5), CHP_NOTE(R5)  # 6: MOV CHP_SLIDE_TO_NOTE(R5), CHP_NOTE(R5)
        CLRB CHP_TON_SLIDE_COUNT(R5)             # CLRB CHP_TON_SLIDE_COUNT(R5)
        CLR CHP_CURRENT_TON_SLIDING(R5)          # CLR CHP_CURRENT_TON_SLIDING(R5)

7$:     MOVB CHP_CURRENT_AMPLITUDE_SLIDING(R5), R0 # 7: MOVB CHP_CURRENT_AMPLITUDE_SLIDING(R5), R0
        BIT $0x80, (R2)                          # BIT $0x80, R3
        BZE 10$                                  # BEQ 10

        BIT $0x40, (R2)                          # BIT $0x40, R3
        BZE 8$                                   # BEQ 8

        CMPB R0, $15                             # CMPB R0, #15.
        BEQ 10$                                  # BEQ 10

        INCB R0                                  # INCB R0
        BR  9$                                   # BR  9

8$:     CMPB R0, $-15                            # 8: CMPB R0, #-15.
        BEQ 10$                                  # BEQ 10

        DECB R0                                  # DECB R0
9$:     MOVB R0, CHP_CURRENT_AMPLITUDE_SLIDING(R5) # 9: MOVB R0, CHP_CURRENT_AMPLITUDE_SLIDING(R5)
10$:    MOV R4, R1                               # 10: MOV R4, R1
        BIC $0xFFF0, R1                          # BIC #0XFFF0, R1
        ADD R1, R0                               # ADD R1, R0
        BPL 11$                                  # BPL 11

        CLR R0                                   # CLR R0
11$:    CMP R0, $16                              # 11: CMP R0, #16.
        BLO 12$                                  # BLO 12

        MOV $15, R0                              # MOV #15., R0
12$:    BISB CHP_VOLUME(R5), R0                  # 12: BISB CHP_VOLUME(R5), R0
        ADD CUR_PARAMS_ADDR, R0                  # ADD CUR_PARAMS_ADDR, R0
        MOVB PARAM_VOL_TAB(R0), R1               # MOVB PARAM_VOL_TAB(R0), R1
        BIT $1, (R2)                             # BIT $1, R3
        BNZ 13$                                  # BNE 13

        BISB CHP_ENVELOPE_ENABLED(R5), R1        # BISB CHP_ENVELOPE_ENABLED(R5), R1
13$:    MOV R1, ampl_reg
        MOV (R2), R0                             # 13: MOV R3, R0
        ASR R0                                   # ASR R0
        BIC $0xFFE0, R0                          # BIC #0XFFE0, R0
        BIT $0x80, R4                            # BIT #0X80, R4
        BZE 16$                                  # BEQ 16

        BIT $0x10, R0                            # BIT #0X10, R0
        BZE 14$                                  # BEQ 14

        BIS $0xFFE0, R0                          # BIS #0XFFE0, R0
14$:    ADD CHP_CURRENT_ENVELOPE_SLIDING(R5), R0 # 14: ADD CHP_CURRENT_ENVELOPE_SLIDING(R5), R0
        BIT $0x20, R4                            # BIT #0X20, R4
        BZE 15$                                  # BEQ 15

        MOV R0, CHP_CURRENT_ENVELOPE_SLIDING(R5) # MOV R0, CHP_CURRENT_ENVELOPE_SLIDING(R5)
15$:    MOV CUR_PARAMS_ADDR, R1                  # MOV CUR_PARAMS_ADDR, R2
        ADD R0, PARAM_ADDTOENVELOPE(R1)          # ADD R0, PARAM_ADDTOENVELOPE(R2)
        BR 17$                                   # BR 17

16$:    MOVB CHP_CURRENT_NOISE_SLIDING(R5), R1   # 16: MOVB CHP_CURRENT_NOISE_SLIDING(R5), R3
        ADD R1, R0                               # ADD R3, R0
        MOV CUR_PARAMS_ADDR, R1                  # MOV CUR_PARAMS_ADDR, R2
        MOV R0, PARAM_ADDTONOISE(R1)             # MOV R0, PARAM_ADDTONOISE(R2)
        BIT $0x20, R4                            # BIT #0X20, R4
        BZE 17$                                  # BEQ 17

        MOVB R0, CHP_CURRENT_NOISE_SLIDING(R5)   # MOVB R0, CHP_CURRENT_NOISE_SLIDING(R5)

17$:    ASR R4                                   # 17: ASR R4
        BIC $0177667, R4                         # BIC #177667, R4
        BISB R4, PARAM_AYREGS.AY_MIXER(R1)       # BISB R4, PARAM_AYREGS.AY_MIXER(R2)
        JMP CHANGE_REGS_EXIT                     # JMP CHANGE_REGS_EXIT

TABLES:

TAB_C_OLD_0:
            .byte 0x00 + 1, 0x04 + 1, 0x08 + 1, 0x0A + 1, 0x0C + 1, 0x0E + 1, 0x12 + 1, 0x14 + 1
            .byte 0x18 + 1, 0x24 + 1, 0x3C + 1, 0
TAB_C_NEW_1:
TAB_C_OLD_1:
            .byte 0x5C + 1, 0
TAB_C_OLD_2:
            .byte 0x30 + 1, 0x36 + 1, 0x4C + 1, 0x52 + 1, 0x5E + 1, 0x70 + 1, 0x82, 0x8C
            .byte 0x9C, 0x9E, 0xA0, 0xA6, 0xA8, 0xAA, 0xAC, 0xAE, 0xAE, 0

TAB_C_NEW_3:
            .byte 0x56 + 1
TAB_C_OLD_3:
            .byte 0x1E + 1, 0x22 + 1, 0x24 + 1, 0x28 + 1, 0x2C + 1, 0x2E + 1, 0x32 + 1, 0xBE + 1, 0

TAB_C_NEW_0:
            .byte 0x1C + 1, 0x20 + 1, 0x22 + 1, 0x26 + 1, 0x2A + 1, 0x2C + 1, 0x30 + 1, 0x54 + 1
            .byte 0xBC + 1, 0xBE + 1, 0

TAB_C_NEW_2:
            .byte 0x1A + 1, 0x20 + 1, 0x24 + 1, 0x28 + 1, 0x2A + 1, 0x3A + 1, 0x4C + 1, 0x5E + 1
            .byte 0xBA + 1, 0xBC + 1, 0xBE + 1, 0

EMPTY_SAM_ORN_TEMPLATE:
            .byte 0, 1, 0, 0x90, 0, 0
            .even
EMPTY_SAM_ORN_TEMPLATE_END:

TABLES_PACK:
            .word 0x06EC
            .byte 0x0755-0x06EC
            .byte 0x07C5-0x0755
            .byte 0x083B-0x07C5
            .byte 0x08B8-0x083B
            .byte 0x093D-0x08B8
            .byte 0x09CA-0x093D
            .byte 0x0A5F-0x09CA
            .byte 0x0AFC-0x0A5F
            .byte 0x0BA4-0x0AFC
            .byte 0x0C55-0x0BA4
            .byte 0x0D10-0x0C55
            .byte 13
            .even
            .word 0x066D
            .byte 0x06CF-0x066D
            .byte 0x0737-0x06CF
            .byte 0x07A4-0x0737
            .byte 0x0819-0x07A4
            .byte 0x0894-0x0819
            .byte 0x0917-0x0894
            .byte 0x09A1-0x0917
            .byte 0x0A33-0x09A1
            .byte 0x0ACF-0x0A33
            .byte 0x0B73-0x0ACF
            .byte 0x0C22-0x0B73
            .byte 0x0CDA-0x0C22
            .byte 12
            .even
            .word 0x0704
            .byte 0x076E-0x0704
            .byte 0x07E0-0x076E
            .byte 0x0858-0x07E0
            .byte 0x08D6-0x0858
            .byte 0x095C-0x08D6
            .byte 0x09EC-0x095C
            .byte 0x0A82-0x09EC
            .byte 0x0B22-0x0A82
            .byte 0x0BCC-0x0B22
            .byte 0x0C80-0x0BCC
            .byte 0x0D3E-0x0C80
            .byte 12
            .even
            .word 0x07E0
            .byte 0x0858-0x07E0
            .byte 0x08E0-0x0858
            .byte 0x0960-0x08E0
            .byte 0x09F0-0x0960
            .byte 0x0A88-0x09F0
            .byte 0x0B28-0x0A88
            .byte 0x0BD8-0x0B28
            .byte 0x0C80-0x0BD8
            .byte 0x0D60-0x0C80
            .byte 0x0E10-0x0D60
            .byte 0x0EF8-0x0E10
            .even

NT_DATA:
            .byte   PARAM_TAB_WORK_NEW_0 - PARAM_TAB_WORK, 0, TAB_C_NEW_0 - TABLES
            .byte   PARAM_TAB_WORK_OLD_0 - PARAM_TAB_WORK, 1, TAB_C_OLD_0 - TABLES
            .byte   PARAM_TAB_WORK_NEW_1 - PARAM_TAB_WORK, 1, TAB_C_NEW_1 - TABLES
            .byte   PARAM_TAB_WORK_OLD_1 - PARAM_TAB_WORK, 1, TAB_C_OLD_1 - TABLES
            .byte   PARAM_TAB_WORK_NEW_2 - PARAM_TAB_WORK, 0, TAB_C_NEW_2 - TABLES
            .byte   PARAM_TAB_WORK_OLD_2 - PARAM_TAB_WORK, 0, TAB_C_OLD_2 - TABLES
            .byte   PARAM_TAB_WORK_NEW_3 - PARAM_TAB_WORK, 0, TAB_C_NEW_3 - TABLES
            .byte   PARAM_TAB_WORK_OLD_3 - PARAM_TAB_WORK, 0, TAB_C_OLD_3 - TABLES
            .even

            AY_TONA = 0
            AY_TONB = 2
            AY_TONC = 4
            AY_NOISE = 6
            AY_MIXER = 7
            AY_AMPLITUDEA = 8
            AY_AMPLITUDEB = 9
            AY_AMPLITUDEC = 10
            AY_ENVELOPE = 11
            AY_ENVELOPETYPE = 13

            CHP_POSITION_IN_ORNAMENT = 0
            CHP_POSITION_IN_SAMPLE = 1
            CHP_CURRENT_AMPLITUDE_SLIDING= 2
            CHP_CURRENT_NOISE_SLIDING = 3
            CHP_CURRENT_ENVELOPE_SLIDING = 4
            CHP_CURRENT_TON_SLIDING = 6
            CHP_TON_ACCUMULATOR = 8
            CHP_TON_SLIDE_COUNT = 10
            CHP_CURRENT_ONOFF = 11
            CHP_ONOFF_DELAY = 12
            CHP_OFFON_DELAY = 13
            CHP_ENVELOPE_ENABLED = 14
            CHP_SIMPLEGLISS = 15
            CHP_ENABLED = 16
            CHP_ADDRESS_IN_PATTERN = 18
            CHP_ORNAMENTPOINTER = 20
            CHP_SAMPLEPOINTER = 22
            CHP_SLIDE_TO_NOTE = 24
            CHP_NOTE = 26
            CHP_TON_SLIDE_STEP = 28
            CHP_TON_DELTA = 30
            CHP_NUMBER_OF_NOTES_TO_SKIP = 32
            CHP_TON_SLIDE_DELAY = 33
            CHP_NOTE_SKIP_COUNTER = 34
            CHP_VOLUME = 35
            CHP_TONE_REG = 36
            CHP_AMPL_REG = 37
            CHP = 38

            PARAM_VERSION =             0
            PARAM_DELAY =               1
            PARAM_ENV_DELAY =           2

            PARAM_MODULE_ADDRESS =      4
            PARAM_SAMPLESPOINTERS =     6
            PARAM_ORNAMENTSPOINTERS = 010
            PARAM_PATTERNSPOINTER =   012
            PARAM_LOOPPOSITION =      014
            PARAM_CURRENTPOSITION =   016

            PARAM_VAR0START =         020

            PARAM_PRNOTE =            PARAM_VAR0START
            PARAM_PRSLIDING =         022
            PARAM_ADDTOENVELOPE =     024
            PARAM_ENV_SLIDE_ADD =     026
            PARAM_ENV_SLIDE_ADD_LSB = PARAM_ENV_SLIDE_ADD
            PARAM_ENV_SLIDE_ADD_MSB = 027
            PARAM_CUR_ENV_SLIDE =     030
            PARAM_ADDTONOISE =        032
            PARAM_DELAYCOUNTER =      034
            PARAM_CUR_ENV_DELAY =     035
            PARAM_NOISE_BASE =        036

            PARAM_CHANNEL_A =         040
            PARAM_CHANNEL_B =         PARAM_CHANNEL_A + CHP
            PARAM_CHANNEL_C =         PARAM_CHANNEL_B + CHP

            PARAM_AYREGS =            PARAM_CHANNEL_C + CHP

            PARAM_VOL_TAB =           PARAM_AYREGS
            PARAM_ENVELOPE_BASE =     PARAM_AYREGS + 14
            PARAM_TAB_WORK =          PARAM_VOL_TAB + 16

            PARAM_VAR0END =           PARAM_TAB_WORK

            PARAM_NOTE_TAB =          PARAM_VOL_TAB + 256

            PARAM_SIZE =              PARAM_NOTE_TAB + (96 * 2)

            PARAM_TAB_WORK_OLD_1 = PARAM_TAB_WORK
            PARAM_TAB_WORK_OLD_2 = PARAM_TAB_WORK_OLD_1 + 24
            PARAM_TAB_WORK_OLD_3 = PARAM_TAB_WORK_OLD_2 + 24
            PARAM_TAB_WORK_OLD_0 = PARAM_TAB_WORK_OLD_3 + 2

            PARAM_TAB_WORK_NEW_0 = PARAM_TAB_WORK_OLD_0
            PARAM_TAB_WORK_NEW_1 = PARAM_TAB_WORK_OLD_1
            PARAM_TAB_WORK_NEW_2 = PARAM_TAB_WORK_NEW_0 + 24
            PARAM_TAB_WORK_NEW_3 = PARAM_TAB_WORK_OLD_3

           .equiv PARAM_AYREGS.AY_AMPLITUDEA,   PARAM_AYREGS + AY_AMPLITUDEA
           .equiv PARAM_AYREGS.AY_AMPLITUDEC,   PARAM_AYREGS + AY_AMPLITUDEC
           .equiv PARAM_AYREGS.AY_MIXER,        PARAM_AYREGS + AY_MIXER
           .equiv PARAM_AYREGS.AY_ENVELOPETYPE, PARAM_AYREGS + AY_ENVELOPETYPE
           .equiv PARAM_AYREGS.AY_NOISE,        PARAM_AYREGS + AY_NOISE
           .equiv PARAM_AYREGS.AY_ENVELOPE_LSB, PARAM_AYREGS + AY_ENVELOPE
           .equiv PARAM_AYREGS.AY_ENVELOPE_MSB, PARAM_AYREGS + AY_ENVELOPE + 1

           .equiv PARAM_CHANNEL_A.CHP_NOTE_SKIP_COUNTER,  PARAM_CHANNEL_A + CHP_NOTE_SKIP_COUNTER

           .equiv PARAM_CHANNEL_A.CHP_ADDRESS_IN_PATTERN, PARAM_CHANNEL_A + CHP_ADDRESS_IN_PATTERN
           .equiv PARAM_CHANNEL_B.CHP_ADDRESS_IN_PATTERN, PARAM_CHANNEL_B + CHP_ADDRESS_IN_PATTERN
           .equiv PARAM_CHANNEL_C.CHP_ADDRESS_IN_PATTERN, PARAM_CHANNEL_C + CHP_ADDRESS_IN_PATTERN

           .equiv AY_AMPLITUDEA_TONEA, AY_AMPLITUDEA << 8 | AY_TONA
           .equiv AY_AMPLITUDEB_TONEB, AY_AMPLITUDEB << 8 | AY_TONB
           .equiv AY_AMPLITUDEC_TONEC, AY_AMPLITUDEC << 8 | AY_TONC

.macro ParamsStruct n
    PARAM_VERSION\n\():          .byte 0   #    0
    PARAM_DELAY\n\():            .byte 0   #    1
    PARAM_ENV_DELAY\n\():        .word 0   #    2

    PARAM_MODULE_ADDRESS\n\():   .word 0   #    4
    PARAM_SAMPLESPOINTERS\n\():  .word 0   #    6
    PARAM_ORNAMENTSPOINTERS\n\():.word 0   #  010
    PARAM_PATTERNSPOINTER\n\():  .word 0   #  012
    PARAM_LOOPPOSITION\n\():     .word 0   #  014
    PARAM_CURRENTPOSITION\n\():  .word 0   #  016

PARAM_VAR0START\n\():
    PARAM_PRNOTE\n\():        .word 0   #     020
    PARAM_PRSLIDING\n\():     .word 0   #     022
    PARAM_ADDTOENVELOPE\n\(): .word 0   #     024
    PARAM_ENV_SLIDE_ADD_LSB\n\():
    PARAM_ENV_SLIDE_ADD_MSB\n\() = PARAM_ENV_SLIDE_LSB + 1
    PARAM_ENV_SLIDE_ADD\n\(): .word 0   #     026
    PARAM_CUR_ENV_SLIDE\n\(): .word 0   #     030
    PARAM_ADDTONOISE\n\():    .word 0   #     032
    PARAM_DELAYCOUNTER\n\():  .byte 0   #     034
    PARAM_CUR_ENV_DELAY\n\(): .byte 0   #     035
    PARAM_NOISE_BASE\n\():    .word 0   #     036

    PARAM_CHANNEL_A\n\():     .space 38 #     040
    PARAM_CHANNEL_B\n\():     .space 38 #    0106
    PARAM_CHANNEL_C\n\():     .space 38 #    0154

    PARAM_VOL_TAB\n\():
    PARAM_AYREGS\n\():        .space 14 #    0222
    PARAM_ENVELOPE_BASE\n\(): .word 0   #    0240
PARAM_VAR0END\n\():

    PARAM_TAB_WORK\n\():      .space 240 #   0242
    PARAM_NOTE_TAB\n\():      .space 96 * 2 #0622
.endm

PARAM_DEVICES_AY1:
   #.word 0       # TS_SELECTOR  [0|1]
   #.word 0       # GS_SELECTOR  [0100000|040000]
    .word PSG0    # AY_PORT_AZBK [PSG0|PSG1]
PARAMETERS_AY1: .space PARAM_SIZE

PARAM_DEVICES_AY2:
    .word PSG1    # AY_PORT_AZBK [PSG0|PSG1]
PARAMETERS_AY2: .space PARAM_SIZE
