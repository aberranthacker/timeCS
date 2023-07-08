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
#   PLATFORM:       BK-0011M (maybe BK-00010)
#   SOUND DEVICES:  LEGACY AY/YM, GryphonSound, TurboSound, AZBK
#
#   COMPILER:       PDPy11
#---------------------------------------------------------------------

#PLAYER BEGIN -------------------------------------------------------------

                        .global PARAM_SIZE

PLAYER_ENTRY_POINTS:
                        .word pt3play2.INIT     #+0  First call before playback
                        .word pt3play2.PLAY     #+2  Main play call for the next position in PT3 file (one quark, one tick)
                        .word pt3play2.MUTE     #+4  Mute the sound

INTEGRATION_POINTS:
    FRAME_NUMBER:         .word 0                             #  +6 Incremented by one each time the PLAY entry point is accessed
    TS_PRESENT:           .word 0                             #+010 TS sign
    SEL_DEVICE:           .word 0                             #+012 Auto selected device: 0 - legacy AY/YM or TurboSound or GryphonSound, 1 - AZBK 
    PARAMETERS_AY1_ADDR:  .word PARAMETERS_AY1                #+014 Address of the operating parameters of AY1
    PARAMETERS_AY2_ADDR:  .word PARAMETERS_AY2                #+016 Address of the operating parameters of AY2
    AYREGS_AY1:           .word PARAMETERS_AY1 + PARAM_AYREGS #+020 Address of last sent AY1 register values
    AYREGS_AY2:           .word PARAMETERS_AY2 + PARAM_AYREGS #+022 Address of last sent AY2 register values
    PT3FILE_MODULE1_ADDR: .word 0100000                       #+024 PT3 file address
    PT3FILE_MODULE2_ADDR: .word 0                             #+026 Address of module 2 (TS) in PT3 file
    PT3FILE_END_ADDR:     .word 0                             #+030 Address of end PT3 file
    END_OF_PT3FILE:       .word 0                             #+032 CODA. End of PT3 file reached (incremented by one each time)
    NO_REPEAT_MODE:       .word 1                             #+034 Play without repeat. Set (not zero) before INIT call.
    REPETITION_NUMBER:    .word 0                             #+036 Number of elapsed repetitions after end of PT3 file

    CUR_PARAMS_ADDR:      .word 0                             #+040


TS_ID:
        .ascii "PT3!PT3!02TS"
TS_ID_END:

TS_ID_CHECK:
            MOV $4, R4
            10$:
                DEC  (R4) # @$PBPADR
                CMPB (R0), -(R2)
                BNE 1237$
            SOB R4, 10$

1237$:      RETURN

pt3play2.INIT:
           #CLR TS_PRESENT
           #CLR SEL_DEVICE
            CLR FRAME_NUMBER
            CLR END_OF_PT3FILE
            CLR PT3FILE_MODULE2_ADDR
            CLR REPETITION_NUMBER
            #;MOV $PT3FILE_END, PT3FILE_END_ADDR
            MOV $PBPADR,R4
            MOV $PBP12D,R0
            MOV $PPT3.PT3FILE_MODULE1_ADDR, (R4)
            MOV (R0), PT3FILE_MODULE1_ADDR
            INC (R4)
            MOV (R0), PT3FILE_END_ADDR

            MOV $PARAM_DEVICES_AY1, R3
            CLR (R3)+
            MOV $0100000, (R3)+
            MOV $PSG0, (R3)+
            #;MOV $PARAMETERS_AY1, R3
            MOV PT3FILE_MODULE1_ADDR, R1

    TS_DETECT:
            MOV PT3FILE_END_ADDR, (R4)
            MOV $PBP1DT,R0
            MOV $TS_ID_END, R2

            CALL TS_ID_CHECK
            BNE INIT_NEXT

            SUB $2, (R4) # @$PBPADR # SKIP LENGTH OF SECOND MODULE

            CALL TS_ID_CHECK
            BNE INIT_NEXT

            CLR R5       # GET OFFSET TO SECOND MODULE
            DEC  (R4) # @$PBPADR
            BISB (R0), R5
            SWAB R5
            DEC  (R4) # @$PBPADR
            BISB (R0), R5
            ADD PT3FILE_MODULE1_ADDR, R5 # GET ADDRESS OF SECOND MODULE

            CALL TS_ID_CHECK
            BNE INIT_NEXT

            INC TS_PRESENT

            INC SEL_DEVICE

            PUSH R5

            CALL INIT_NEXT

            POP  R1

            MOV R1, PT3FILE_MODULE2_ADDR

            MOV $PARAM_DEVICES_AY2, R3
            MOV $1, (R3)+
            MOV $040000, (R3)+
            MOV $PSG1, (R3)+
           #;MOV $PARAMETERS_AY2, R3

INIT_NEXT:
          # R4 = PBPADR
          # R0 = PBP1DT
          # R1 = PT3FILE_MODULE1_ADDR
          # R3 = PARAMETERS_AY1
            MOV R3, CUR_PARAMS_ADDR

            MOV  R1, PARAM_MODULE_ADDRESS(R3)
            MOV  R1, R5  
            MOV  R5,(R4)
            ADD  $100,(R4) # MOVB 100(R5), PARAM_DELAY(R3)
            MOVB (R0), PARAM_DELAY(R3)
            ADD  $200, R1   
            MOV  R1, PARAM_CURRENTPOSITION(R3)
            ADD  $2,(R4)   # MOVB 102(R5), R2 
            MOVB (R0), R2
            ADD  R2, R1
            INC  R1
            MOV  R1, PARAM_LOOPPOSITION(R3)
            CLR  R1
            ADD  $2,(R4)   # BISB 104(R5), R1 
            BISB (R0), R1
            SWAB R1
            DEC  (R4)      # BISB 103(R5), R1
            BISB (R0), R1
            ADD  R5, R1  
            MOV  R1, PARAM_PATTERNSPOINTER(R3) 
            MOV  $169, R1
            ADD  R5, R1  
            MOV  R1, PARAM_ORNAMENTSPOINTERS(R3)  
            MOV  $105, R1
            ADD  R5, R1  
            MOV  R1, PARAM_SAMPLESPOINTERS(R3)

            PUSH R5
#-----------------!!!!!
            MOV  $TABLES_PACK, R4 
            MOV  $PARAM_TAB_WORK + 98, R5
            ADD  R3, R5

            MOV  $4, R3
            MOV  $12, R2
            10$:    
                MOV (R4)+, R0   
                ASL  R0  
                BR   2$  

                1$:
                    CLR  R1
                    BISB (R4)+, R1   
                    ADD R1, R0  
                    ADD R1, R0
                2$: MOV R0, -(R5)   
                SOB R2, 1$  

                MOVB (R4)+, R2   
                INC R4
                BIC $1, R4  
            SOB R3, 10$  

            MOV CUR_PARAMS_ADDR, R5
 
            MOV $PARAM_VAR0START, R1
            ADD R5, R1
            MOV $PARAM_VAR0END - PARAM_VAR0START, R3
            3$:
                CLRB (R1)+
            SOB R3, 3$

            MOVB $1, PARAM_DELAYCOUNTER(R5)
            MOV $0xF001, R0 
            MOV $EMPTY_SAM_ORN, R2
            MOV $PARAM_CHANNEL_A, R4
            ADD R5, R4

            MOV (PC)+, R3
            .byte   AY_TONA, AY_AMPLITUDEA
            CALL FILL
            
            MOV (PC)+, R3
            .byte   AY_TONB, AY_AMPLITUDEB
            CALL FILL
            
            MOV (PC)+, R3
            .byte   AY_TONC, AY_AMPLITUDEC
            CALL FILL

            POP  R5

            MOVB 13(R5), R0  
            SUB $060, R0  
            BCS 4$  

            CMPB R0, $10
            BLO 5$  

    4$:     MOV  $6, R0   
    5$:     MOV  CUR_PARAMS_ADDR, R2
            MOVB R0, PARAM_VERSION(R2) 
            PUSH R0
            CMPB R0, $4   
            MOVB 99(R5), R0  
            ROLB R0   
            BICB $0177770, R0  

NOTE_TABLE_MAKER:
            PUSH R1
            MOV  $NT_DATA, R1
            ADD  R0, R1
            ADD  R0, R1
            ADD  R0, R1  
            CLR  R2
            BISB (R1)+, R2   
            MOV  (PC)+, R0
            NOP
            TSTB (R1)+   
            BEQ  10$
            MOV  (PC)+, R0   
            CLC
    10$:    MOV  R0, MULTY_SUBR

            CLR  R3
            BISB (R1), R3
            ADD  $TABLES ,R3

            ADD  (SP)+, R2   

            PUSH R3
            MOV  $PARAM_NOTE_TAB, R1 
            ADD  CUR_PARAMS_ADDR, R1
            PUSH R1

            MOV  $12, R4 
            1$:
                MOV  (R2)+, R3   
                PUSH R1
                MOV  $8, R5  
                2$:
                    CLC
                    ROR  R3
                    CALL MULTY_SUBR   
                    MOV  R3, R0
                    ADC  R0
                    MOV  R0, (R1)
                    ADD  $24, R1
                SOB  R5, 2$
                POP  R1
                TST  (R1)+   
            SOB  R4, 1$

            POP  R2   
            POP  R1   

            CMP R1, $TAB_C_OLD_1
            BNE 3$
            MOV CUR_PARAMS_ADDR, R0
            MOVB $0xFD, PARAM_NOTE_TAB + 056(R0)

    3$:     CLR  R0
            BISB (R1)+, R0
            BEQ  5$

            CLR  R5
            RORB R0  
            ROL  R5  
            ASLB R0  
            ADD  R0, R2  
            TST  R5  
            BEQ  4$

            SUB  $2, (R2)
    4$:     INC  (R2)
            SUB  R0, R2 
            BR   3$

    5$:     POP  R0   


VOL_TABLE_MAKER:
            MOV $021, R3 
            CLR R1  
            CMPB R0, $5  
            MOV (PC)+, R0
            ASLB R0  
            BHIS 10$

            DEC R3  
            MOV R3, R1  
            MOV (PC)+, R0
            NOP  

    10$:    MOV R0, MULTY_SUBR

            MOV $PARAM_VOL_TAB, R4 
            ADD CUR_PARAMS_ADDR, R4
            MOV R4, R5
            MOV $16, R2 
            ADD R2, R5
            MOV $256 >> 1, R0
    1$:     CLR (R4)+   
            SOB R0, 1$

    2$:     PUSH R3

            ADD R3, R1  
            MOV $0, R3  
            SBC R3  

    3$:     MOVB R3, R0  
            MOV  R3, R4  
            CLRB R4
            SWAB R4  
            CALL MULTY_SUBR
            ADCB R4
            MOVB R4, (R5)+
            ADD  R1, R3
            INC  R2  
            MOV  R2, R0
            BIC  $0177760, R0
            BNE  3$

            POP   R3
            CMP  R1, $119
            BNE  4$

            INC R1
    4$:     TSTB R2  
            BNE 2$

            JMP REG_OUT

MULTY_SUBR:
            NOP
            RETURN

pt3play2.PLAY:       
            INC FRAME_NUMBER

            MOV $PARAMETERS_AY1, R4

            CALL PLAY_NEXT

            MOV $PARAMETERS_AY2, R4
PLAY_NEXT:

            MOV R4, CUR_PARAMS_ADDR

            CLR PARAM_ADDTOENVELOPE(R4)
           .set offset, PARAM_AYREGS + AY_MIXER
            CLRB offset(R4)
           .set offset, PARAM_AYREGS + AY_ENVELOPETYPE
            MOVB $-1, offset(R4)
            DECB PARAM_DELAYCOUNTER(R4)
            BHI 5$ 
            MOV $PARAM_CHANNEL_A, R5
            ADD R4, R5
            DECB CHP_NOTE_SKIP_COUNTER(R5)
            BNE 2$
            MOV CHP_ADDRESS_IN_PATTERN(R5), R3
            TSTB (R3)
            BNE 1$
            CLRB PARAM_NOISE_BASE(R4)
            MOV PARAM_CURRENTPOSITION(R4), R0
            INC R0
            MOVB (R0), R1

            CMPB $0377, R1
            BNE 10$

            INC END_OF_PT3FILE

            TST NO_REPEAT_MODE
            BEQ 100$

                INCB PARAM_DELAYCOUNTER(R4)
               .set offset, PARAM_CHANNEL_A + CHP_NOTE_SKIP_COUNTER
                INCB offset(R4)
                JMP pt3play2.MUTE

    100$:   MOV PARAM_LOOPPOSITION(R4), R0
            MOVB (R0), R1

            INC REPETITION_NUMBER               #Next repeat

    10$:    MOV R0, PARAM_CURRENTPOSITION(R4)
            BIC $0177400, R1
            ASL R1
            ADD PARAM_PATTERNSPOINTER(R4), R1 
            MOV PARAM_MODULE_ADDRESS(R4), R2

            CLR R3
            BISB (R1)+, R3   
            SWAB R3
            BISB (R1)+, R3   
            SWAB R3   
            ADD R2, R3

            CLR R0
            BISB (R1)+, R0
            SWAB R0
            BISB (R1)+, R0
            SWAB R0
            ADD R2, R0
           .set offset, PARAM_CHANNEL_B + CHP_ADDRESS_IN_PATTERN
            MOV R0, offset(R4)

            CLR R0
            BISB (R1)+, R0
            SWAB R0
            BISB (R1)+, R0
            SWAB R0
            ADD R2, R0
           .set offset, PARAM_CHANNEL_C + CHP_ADDRESS_IN_PATTERN
            MOV R0, offset(R4)

    1$:     CALL PATTERN_INTERPR
            MOV R3, CHP_ADDRESS_IN_PATTERN(R5)

    2$:     ADD $CHP, R5
            DECB CHP_NOTE_SKIP_COUNTER(R5)
            BNE 3$
            MOV CHP_ADDRESS_IN_PATTERN(R5), R3
            CALL PATTERN_INTERPR
            MOV R3, CHP_ADDRESS_IN_PATTERN(R5)

    3$:     ADD $CHP, R5
            DECB CHP_NOTE_SKIP_COUNTER(R5)
            BNE 4$
            MOV CHP_ADDRESS_IN_PATTERN(R5), R3
            CALL PATTERN_INTERPR
            MOV R3, CHP_ADDRESS_IN_PATTERN(R5)

    4$:     MOVB PARAM_DELAY(R4), PARAM_DELAYCOUNTER(R4)

    5$:     MOV $PARAM_CHANNEL_A, R5
            ADD R4, R5
            CALL CHANGE_REGS
            CALL CHANGE_REGS
            CALL CHANGE_REGS

            MOVB PARAM_NOISE_BASE(R2), R0  
            ADD PARAM_ADDTONOISE(R2), R0
           .set offset, PARAM_AYREGS + AY_NOISE
            MOVB R0, offset(R2)

            MOV PARAM_ENVELOPE_BASE(R2), R0
            ADD PARAM_ADDTOENVELOPE(R2), R0
            ADD PARAM_CUR_ENV_SLIDE(R2), R0
           .set offset, PARAM_AYREGS + AY_ENVELOPE
            MOVB R0, offset(R2)
            SWAB R0
           .set offset, PARAM_AYREGS + AY_ENVELOPE + 1
            MOVB R0, offset(R2)

            MOV $PARAM_CUR_ENV_DELAY, R0
            ADD R2, R0
            TSTB (R0)
            BEQ REG_OUT
            DECB (R0)
            BNE REG_OUT
            MOVB PARAM_ENV_DELAY(R2), (R0)
            ADD PARAM_ENV_SLIDE_ADD(R2), PARAM_CUR_ENV_SLIDE(R2)

REG_OUT:    MOV CUR_PARAMS_ADDR, R0
            MOV R0, R4

            MOV -(R0), pt3play2.AY_PORT

            ADD $PARAM_AYREGS + AY_ENVELOPETYPE, R4

    REG_OUT_DEVICE_MANAGE:
           .equiv pt3play2.AY_PORT, .+2
            MOV  $0177360,R5
            MOV  $015, R1
            MOVB (R4), R0
            BMI  10$

            MOV  R1, (R5)
            MOVB R0, (R5)
    10$:    DEC  R1
            BMI  1237$

            MOV  R1, (R5)
            MOVB -(R4), (R5)
            BR   10$

1237$:      RETURN

pt3play2.MUTE:
            MOV $PARAMETERS_AY1, R4
            CALL pt3play2.MUTE_NEXT
            MOV $PARAMETERS_AY2, R4
pt3play2.MUTE_NEXT:
            MOV R4, CUR_PARAMS_ADDR
           .set offset, PARAM_AYREGS + AY_AMPLITUDEA
            CLR offset(R4)
           .set offset, PARAM_AYREGS + AY_AMPLITUDEC
            CLRB offset(R4)
           .set offset, PARAM_AYREGS + AY_MIXER
            MOVB $077, offset(R4)
            BR REG_OUT


PD_ORSM:    CLRB CHP_ENVELOPE_ENABLED(R5)
            CALL SET_ORNAMENT
            MOVB (R3)+, R0
            BR  PD_SAM_

PD_SAM:     SUB $0xD0, R0
            ASL R0
PD_SAM_:    ADD PARAM_SAMPLESPOINTERS(R4), R0
            CLR R1
            BISB (R0)+, R1
            SWAB R1
            BISB (R0), R1
            SWAB R1
            TST R1
            BEQ 10$  
            ADD PARAM_MODULE_ADDRESS(R4), R1
            MOV R1, CHP_SAMPLEPOINTER(R5)
        10$:    BR  PD_LOOP

PD_VOL:     BIC $0xFFF0, R0
            ASL R0
            ASL R0
            ASL R0
            ASL R0
            MOVB R0, CHP_VOLUME(R5)
            BR  PD_LOOP

PD_EOFF:    CLRB CHP_ENVELOPE_ENABLED(R5)
            CLRB CHP_POSITION_IN_ORNAMENT(R5)
            BR  PD_LOOP

PD_SORE:    BIC $0xFFF0, R0
            DECB R0
            BNE PD_ENV
            MOVB (R3)+, CHP_NUMBER_OF_NOTES_TO_SKIP(R5)
            BR  PD_LOOP

PD_ENV:     CALL SET_ENVELOPE
            CLRB CHP_POSITION_IN_ORNAMENT(R5)
            BR  PD_LOOP

PD_ORN:     CALL SET_ORNAMENT
            BR  PD_LOOP

PD_ESAM:    CLRB CHP_ENVELOPE_ENABLED(R5)
            BIC $0xFFF0, R0
            BEQ 10$
            CALL SET_ENVELOPE
        10$:CLRB CHP_POSITION_IN_ORNAMENT(R5)
            MOVB (R3)+, R0
            BR  PD_SAM_

PATTERN_INTERPR:
            MOV CHP_NOTE(R5), PARAM_PRNOTE(R4)
            MOV CHP_CURRENT_TON_SLIDING(R5), PARAM_PRSLIDING(R4)

PD_LOOP:    CLR R0
            BISB (R3)+, R0
            CMPB R0, $0xF0
            BHIS PD_ORSM  
            CMPB R0, $0xD0
            BEQ PD_FIN  
            BHI PD_SAM  
            CMPB R0, $0xC0
            BEQ PD_REL  
            BHI PD_VOL
            CMPB R0, $0xB0
            BEQ PD_EOFF  
            BHI PD_SORE  
  
            CMPB R0, $0x50
            BHIS PD_NOTE  
            CMPB R0, $0x40
            BHIS PD_ORN  
            CMPB R0, $0x20
            BHIS PD_NOIS 
            CMPB R0, $0x10
            BHIS PD_ESAM 
  
            ASL R0
            MOV SPEC_SUBR(R0), -(SP)  
            BR  PD_LOOP

PD_NOIS:    BIC $0xFFE0, R0
            MOVB R0, PARAM_NOISE_BASE(R4)
            BR  PD_LOOP

PD_REL:     CLRB CHP_ENABLED(R5)
            BR  PD_RES

PD_NOTE:    SUB $0x50, R0
            MOV R0, CHP_NOTE(R5)
            MOVB $-1, CHP_ENABLED(R5)

PD_RES:     MOV R5, R0
            CLR (R0)+   
            CLR (R0)+   
            CLR (R0)+   
            CLR (R0)+   
            CLR (R0)+   
            CLR (R0) 

PD_FIN:     MOVB CHP_NUMBER_OF_NOTES_TO_SKIP(R5), CHP_NOTE_SKIP_COUNTER(R5)
            RETURN

SUBR_PORTM:
            CLRB CHP_SIMPLEGLISS(R5)
            MOVB (R3)+, R0

            INC R3
            INC R3
            MOVB R0, CHP_TON_SLIDE_DELAY(R5)
            MOVB R0, CHP_TON_SLIDE_COUNT(R5)
            MOV CHP_NOTE(R5), R2
            MOV R2, CHP_SLIDE_TO_NOTE(R5)
            ASL R2
            ADD R4, R2
            MOV PARAM_NOTE_TAB(R2), R2
            MOV PARAM_PRNOTE(R4), R1
            MOV R1, CHP_NOTE(R5)
            ASL R1
            ADD R4, R1
            MOV PARAM_NOTE_TAB(R1), R1
            SUB R1, R2
            MOV R2, CHP_TON_DELTA(R5)   
            MOV CHP_CURRENT_TON_SLIDING(R5), R1
            CMPB PARAM_VERSION(R4), $6
            BLO OLDPRTM  
            MOV PARAM_PRSLIDING(R4), R1
            MOV R1, CHP_CURRENT_TON_SLIDING(R5)
OLDPRTM:    CLR R0
            BISB (R3)+, R0   
            SWAB R0
            BISB (R3)+, R0   
            SWAB R0
            TST R0   
            BPL 10$
            NEG R0
        10$:SUB R1, R2  
            BPL 1$   
            NEG R0
        1$: MOV R0, CHP_TON_SLIDE_STEP(R5)
            CLRB CHP_CURRENT_ONOFF(R5)
            RETURN

SUBR_GLISS:
            MOVB (PC), CHP_SIMPLEGLISS(R5)
            MOVB (R3)+, R0
            MOVB R0, CHP_TON_SLIDE_DELAY(R5)
            BNE GL36
 
            CMPB PARAM_VERSION(R4), $7 
            BLO GL36
            INCB R0  
GL36:       MOVB R0, CHP_TON_SLIDE_COUNT(R5)
            MOVB (R3)+, CHP_TON_SLIDE_STEP(R5) 
            MOVB (R3)+, CHP_TON_SLIDE_STEP + 1(R5) 
            CLRB CHP_CURRENT_ONOFF(R5)
            RETURN

SUBR_SMPOS:
            MOVB (R3)+, CHP_POSITION_IN_SAMPLE(R5)
            RETURN

SUBR_ORPOS:
            MOVB (R3)+, CHP_POSITION_IN_ORNAMENT(R5)
            RETURN

SUBR_VIBRT:
            MOVB (R3), CHP_ONOFF_DELAY(R5)
            MOVB (R3)+, CHP_CURRENT_ONOFF(R5)
            MOVB (R3)+, CHP_OFFON_DELAY(R5)
            CLRB CHP_TON_SLIDE_COUNT(R5)
            CLR CHP_CURRENT_TON_SLIDING(R5)
            RETURN

SUBR_ENGLS:
            MOVB (R3), PARAM_ENV_DELAY(R4)
            MOVB (R3)+, PARAM_CUR_ENV_DELAY(R4)
            MOVB (R3)+, PARAM_ENV_SLIDE_ADD(R4)
            MOVB (R3)+, PARAM_ENV_SLIDE_ADD + 1(R4)
            RETURN

SUBR_DELAY:
            MOVB (R3)+, PARAM_DELAY(R4)
            RETURN

SET_ENVELOPE:
            MOVB $0x10, CHP_ENVELOPE_ENABLED(R5)
           .set offset, PARAM_AYREGS + AY_ENVELOPETYPE
            MOVB R0, offset(R4)
            MOVB (R3)+, PARAM_ENVELOPE_BASE + 1(R4)
            MOVB (R3)+, PARAM_ENVELOPE_BASE(R4) 
            CLRB PARAM_CUR_ENV_DELAY(R4)
            CLR PARAM_CUR_ENV_SLIDE(R4)
SUBR_NOP:
            RETURN

SET_ORNAMENT:
            BIC $0xFFF0, R0
            ASL R0
            ADD PARAM_ORNAMENTSPOINTERS(R4), R0
            CLR R1
            BISB (R0)+, R1
            SWAB R1
            BISB (R0), R1
            SWAB R1
            TST R1
            BNE 10$
            MOV $EMPTY_SAM_ORN, R1
            BR 1$
        10$:ADD PARAM_MODULE_ADDRESS(R4), R1
        1$: MOV R1, CHP_ORNAMENTPOINTER(R5)
            CLRB CHP_POSITION_IN_ORNAMENT(R5)
            RETURN

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
            CLR R1  
            TSTB CHP_ENABLED(R5)
            BNE CHANGE_REGS_NEXT

    CHANGE_REGS_EXIT:
            MOVB CHP_AMPL_REG(R5), R0
            MOV CUR_PARAMS_ADDR, R2
            ADD R2, R0
            MOVB R1, PARAM_AYREGS(R0)
           .set offset, PARAM_AYREGS + AY_MIXER
            ASRB offset(R2)
            TSTB CHP_CURRENT_ONOFF(R5)
            BEQ 1$
            DECB CHP_CURRENT_ONOFF(R5)
            BNE 1$
            MOVB CHP_ONOFF_DELAY(R5), R0
            COMB CHP_ENABLED(R5)
            BNE 10$
            MOVB CHP_OFFON_DELAY(R5), R0
        10$:MOVB R0, CHP_CURRENT_ONOFF(R5)
        1$: ADD $CHP, R5
            RETURN

    CHANGE_REGS_NEXT:

            MOV CHP_ORNAMENTPOINTER(R5), R1 
            MOVB (R1)+, R4   
            MOVB (R1)+, R3   
            MOVB CHP_POSITION_IN_ORNAMENT(R5), R0 
            ADD R0, R1
            INCB R0
            CMPB R0, R3
            BLO 100$

            MOVB R4, R0
    100$:   MOVB R0, CHP_POSITION_IN_ORNAMENT(R5)
            MOV CHP_NOTE(R5), R0 
            MOVB (R1), R1 
            ADD R1, R0
            BPL 1$
            CLR R0
    1$:     CMP R0, $96
            BLO 2$
            MOV $95, R0
    2$:     ASL R0
            MOV R0, -(SP)   
            MOV CHP_SAMPLEPOINTER(R5), R1   
            MOVB (R1)+, R4   
            MOVB (R1)+, R3   
            MOVB CHP_POSITION_IN_SAMPLE(R5), R0  
            ADD R0, R1
            ADD R0, R1
            ADD R0, R1
            ADD R0, R1
            INCB R0
            CMPB R0, R3
            BLO 3$
            MOVB R4, R0
    3$:     MOVB R0, CHP_POSITION_IN_SAMPLE(R5)
            MOVB (R1)+, R3   
            MOVB (R1)+, R4   
            CLR R2
            BISB (R1)+, R2   
            SWAB R2
            BISB (R1), R2
            SWAB R2
            ADD CHP_TON_ACCUMULATOR(R5), R2
            BIT $0x40, R4   
            BEQ 4$
            MOV R2, CHP_TON_ACCUMULATOR(R5)
    4$:     MOV (SP)+, R1   
            ADD CUR_PARAMS_ADDR, R1
            ADD PARAM_NOTE_TAB(R1), R2 
            MOV CHP_CURRENT_TON_SLIDING(R5), R1 
            ADD R1, R2  
            BIC $0xF000, R2
            MOVB CHP_TONE_REG(R5), R0
            ADD CUR_PARAMS_ADDR, R0
            MOV R2, PARAM_AYREGS(R0)  

            TSTB CHP_TON_SLIDE_COUNT(R5)
            BEQ 7$

            DECB CHP_TON_SLIDE_COUNT(R5)
            BNE 7$

            MOVB CHP_TON_SLIDE_DELAY(R5), CHP_TON_SLIDE_COUNT(R5)
            MOV CHP_TON_SLIDE_STEP(R5), R2
            ADD R2, R1  
            MOV R1, CHP_CURRENT_TON_SLIDING(R5)
            TSTB CHP_SIMPLEGLISS(R5) 
            BNE 7$

            MOV CHP_TON_DELTA(R5), R0
            TST R2  
            BPL 5$

            CMP R1, R0
            BLE 6$
            BR  7$

    5$:     CMP R1, R0
            BLT 7$

    6$:     MOV CHP_SLIDE_TO_NOTE(R5), CHP_NOTE(R5)
            CLRB CHP_TON_SLIDE_COUNT(R5)
            CLR CHP_CURRENT_TON_SLIDING(R5)

    7$:     MOVB CHP_CURRENT_AMPLITUDE_SLIDING(R5), R0   
            BIT $0x80, R3   
            BEQ 10$

            BIT $0x40, R3   
            BEQ 8$

            CMPB R0, $15 
            BEQ 10$

            INCB R0   
            BR  9$
 
    8$:     CMPB R0, $-15   
            BEQ 10$

            DECB R0   
    9$:     MOVB R0, CHP_CURRENT_AMPLITUDE_SLIDING(R5)
    10$:    MOV R4, R1  
            BIC $0xFFF0, R1 
            ADD R1, R0  
            BPL 11$

            CLR R0
    11$:    CMP R0, $16
            BLO 12$

            MOV $15, R0 
    12$:    BISB CHP_VOLUME(R5), R0  
            ADD CUR_PARAMS_ADDR, R0
            MOVB PARAM_VOL_TAB(R0), R1 
            BIT $1, R3  
            BNE 13$

            BISB CHP_ENVELOPE_ENABLED(R5), R1 
    13$:    MOV R3, R0
            ASR R0
            BIC $0xFFE0, R0 
            BIT $0x80, R4   
            BEQ 16$

            BIT $0x10, R0   
            BEQ 14$   

            BIS $0xFFE0, R0 
    14$:    ADD CHP_CURRENT_ENVELOPE_SLIDING(R5), R0
            BIT $0x20, R4   
            BEQ 15$

            MOV R0, CHP_CURRENT_ENVELOPE_SLIDING(R5)
    15$:    MOV CUR_PARAMS_ADDR, R2
            ADD R0, PARAM_ADDTOENVELOPE(R2)
            BR 17$

    16$:    MOVB CHP_CURRENT_NOISE_SLIDING(R5), R3   
            ADD R3, R0
            MOV CUR_PARAMS_ADDR, R2
            MOV R0, PARAM_ADDTONOISE(R2)
            BIT $0x20, R4   
            BEQ 17$

            MOVB R0, CHP_CURRENT_NOISE_SLIDING(R5)

    17$:    ASR R4  
            BIC $0177667, R4 
           .set offset, PARAM_AYREGS + AY_MIXER
            BISB R4, offset(R2)
            JMP CHANGE_REGS_EXIT

FILL:       MOV R0, CHP_NOTE_SKIP_COUNTER(R4)
            MOV R2, CHP_ADDRESS_IN_PATTERN(R4)  
            MOV R2, CHP_ORNAMENTPOINTER(R4) 
            MOV R2, CHP_SAMPLEPOINTER(R4)   
            MOV R3, CHP_TONE_REG(R4)
            ADD $CHP, R4
            RETURN


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

EMPTY_SAM_ORN: 
            .byte 0, 1, 0, 0x90, 0, 0 
            .even

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


            PARAM_TAB_WORK = PARAM_VOL_TAB + 16 
            PARAM_TAB_WORK_OLD_1 = PARAM_TAB_WORK
            PARAM_TAB_WORK_OLD_2 = PARAM_TAB_WORK_OLD_1 + 24
            PARAM_TAB_WORK_OLD_3 = PARAM_TAB_WORK_OLD_2 + 24
            PARAM_TAB_WORK_OLD_0 = PARAM_TAB_WORK_OLD_3 + 2

            PARAM_TAB_WORK_NEW_0 = PARAM_TAB_WORK_OLD_0
            PARAM_TAB_WORK_NEW_1 = PARAM_TAB_WORK_OLD_1
            PARAM_TAB_WORK_NEW_2 = PARAM_TAB_WORK_NEW_0 + 24
            PARAM_TAB_WORK_NEW_3 = PARAM_TAB_WORK_OLD_3


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
            PARAM_NOTE_TAB =          PARAM_VOL_TAB + 256

            PARAM_SIZE =              PARAM_NOTE_TAB + (96 * 2)

            PARAM_ENVELOPE_BASE =     PARAM_AYREGS + 14
            
            PARAM_VAR0END =           PARAM_TAB_WORK

PARAM_DEVICES_AY1:
    .word 0
    .word 0100000 # PSG0 pt3 start
    .word PSG0
PARAMETERS_AY1:    .space PARAM_SIZE

PARAM_DEVICES_AY2: .space 6
PARAMETERS_AY2:    .space PARAM_SIZE
