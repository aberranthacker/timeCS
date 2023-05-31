# vim: set tabstop=4 :

#-------------------------------------------------------------------------------
#   MUSIC RELEASE 'timeCS' (PART 1 'TITLE') 6-channel (2AY) music only!  
#   BY VLADIMIR 'KUVO' KUTYAKOV/CSI
#   
#   2AY DEVICES:    AZBK, GryphonSound, TurboSound
#   PLATFORM:       BK-0011M
#   COMPILER:       PDPy11
#   
#-------------------------------------------------------------------------------
           .list

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
            MOV  $(FB_SIZE_WORDS + 4) >> 2,R1
            MOV  $FB0-8,R5
            100$:
               .rept 4
                CLR  (R5)+
               .endr
            SOB  R1,100$

            MTPS $PR0

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
            CALL Bootstrap.DiskRead_Start
            CALL Bootstrap.DiskIO_WaitForFinish

           .ppudo $PPU.SetPalette, $title_palette

            MOV $GFX_W3, R1
            MOV $FB1, R2
            CALL LZSA_UNPACK
           #CALL REMOVE_PROGRESS

           #CALL CLOCKHANDS_GFX_PREP
           #CALL REMOVE_PROGRESS

           #CALL GFX_timeCS_PREP
           #CALL REMOVE_PROGRESS

            MOV $TIKTAK, @$0100
           #CALL REMOVE_PROGRESS

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
            .word FB1 + ( 32 >> 2) + (216 * 72), 72 >> 3, 40
            .word FB1 + ( 32 >> 2) + (200 * 72), 40 >> 3, 16
            .word FB1 + ( 32 >> 2) + (184 * 72), 24 >> 3, 16
            .word FB1 + (  8 >> 2) + (  0 * 72), 24 >> 3, 48
            .word FB1 + (200 >> 2) + (  0 * 72), 40 >> 3, 40
            .word FB1 + (200 >> 2) + (205 * 72), 32 >> 3, 47
            .word 0

PREP_MAIN_LOOP:
        WAIT

       .ppudo $PPU.PSGP_Player.Init
        MOV $020, R0
    1$: WAIT
        SOB R0, 1$
       .ppudo $PPU.PSGP_Player.Play
        WAIT
        br .

MAIN_LOOP:
            TST Title.PLAY_NOW
            BNE 10$

       100$:JMP END_OF_PART

        10$:CMP FRAME_NUMBER, $9858
            BGE 100$

           #BIT $0100, @$0177716 # check if a key was pressed
           #BNE 1$

           #CLR PLAY_NOW # stop playing if a key was pressed

        1$: CALL DISPLAY_timeCS
## 
##             CALL DISPLAY_CLOCK
## 
##             CMP FRAME_NUMBER, $768
##             BLO 2$
## 
##             MOV $2, DUMMY1
##             MOV $044, DUMMY1 + 4
##             MOV $2, DUMMY2
## 
##         2$: MOV (PC)+, R0
##         DOTS_OFFSET:    .word 0
##             ADD $020, R0
##             CMP R0, $020 * 3
##             BLO 10$
##             CLR R0
##         10$:MOV R0, DOTS_OFFSET
## 
##             ADD $DOTS, R0
##             MOV R0, CODE_MODIFY + 2
## 
##     DISPLAY_CIRCLES:
##             MOV $TUNNEL, R4
## 
##         10$:MOV (R4)+, R0
##             BEQ MAIN_LOOP
##             
##             ADD R0, (R4)
##             MOV (R4)+, R1
##             CMP R1, (R4)+
##             BLO 1$
## 
##             MOV (R4), R1
##         1$: TST (R4)+
##             MOV R1, -6(R4)
##             MOV (R4)+, CIRCLE_FORMER
##             CALL DRAW_CIRCLE_OPER
##             BR 10$
               br MAIN_LOOP

DISPLAY_timeCS:
        CMP  FRAME_NUMBER, $384 >> 1
        BLT  1237$

        CMP  FRAME_NUMBER, $9792
        BGE  1237$

       .equiv SCREEN_LOCATION_timeCS_IDX, .+2
        MOV  $SCREEN_LOCATION_timeCS, R5

        CMP  FRAME_NUMBER, $384 >> 1
        BLT  1237$

        ADD  $12, .-6

        MOV  (R5)+, R0
        BNZ  1$

        ADD $192, DISPLAY_timeCS + 4
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
            ADD  $0100, R0
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
       .word FB0 + 0 + (72*109), 32 >> 3, 16
       .word FB0 + 0 + (72* 99), 32 >> 3, 18
       .word FB0 + 2 + (72* 81), 32 >> 3, 27
       .word FB0 + 4 + (72* 66), 24 >> 3, 19
       .word FB0 + 2 + (72* 32), 48 >> 3, 43
       .word FB0 + 6 + (72*  8), 40 >> 3, 46
       .word 0

## DISPLAY_CLOCK:
##             CMP FRAME_NUMBER, $6
##             BLO 9$
##             ADD $6, .-4
##             
##             MOV $CLOCKHANDS_DATA, R5
##         10$:MOV (R5)+, R1
##             BEQ 3$
##         1$: ADD $0100, R1
##             CMP R1, (R5)+
##             BLO 2$
##             MOV (R5)+, -6(R5)
##             BR 10$
##         2$: MOV R1, -4(R5)
## 
##         3$: MOV $0100000 + (224 >> 2) + (64*210), R1
##             MOV $CLOCKHAND_BUFFER, R0
##             MOV $020, R2
##             MOV $0100 - 4, R3
##         4$: MOV (R1)+, (R0)+
##             MOV (R1)+, (R0)+
##             ADD R3, R1
##             SOB R2, 4$
## 
##             MOV $CLOCKHANDS_DATA, R5
##         5$: MOV (R5), R1
##             BEQ 7$
##             MOV $CLOCKHAND_BUFFER, R0
##             MOV $040, R2
##         6$: BIC (R1)+, (R0)+
##             SOB R2, 6$
##             ADD $6, R5
##             BR 5$
## 
##         7$: MOV $040000 + (224 >> 2) + (64*210), R0
##             MOV $CLOCKHAND_BUFFER, R1
##             MOV $020, R2
##         8$: MOV (R1)+, (R0)+
##             MOV (R1)+, (R0)+
##             ADD R3, R0
##             SOB R2, 8$
##         9$:
##             RETURN
##             
## CLOCKHANDS_DATA:
##             .word CLOCKHAND_SEC + 0500, CLOCKHAND_SEC + CLOCKHAND_SIZE, CLOCKHAND_SEC
##             .word CLOCKHAND_MIN + 01400 - 0500, CLOCKHAND_MIN + CLOCKHAND_SIZE, CLOCKHAND_MIN
##             .word CLOCKHAND_HOUR, CLOCKHAND_HOUR + CLOCKHAND_SIZE, CLOCKHAND_HOUR
##             .word 0
## 
MOSAIC:
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

 
END_OF_PART:
    br .            
##             MOV $PALETTES_FOR_CHANGE, BK11_PALETTE_IDX
## 
##             TST PLAY_NOW
##             BNE 100$
## 
##             CALL PSGP_PLAYER + 4 #MUTE
## 
##        100$:MOV $0240, SCREEN_ADDER + 2
##             MOV $061, R5
##             MOV $04400, R4
##             TST DUMMY2
##             BNE 10$
##             MOV $042, R5
##         10$:MOV R5, R1
##             MOV R4, CIRCLE_FORMER       
##             CALL DRAW_CIRCLE_OPER
##             SUB $020, R4
##             DEC R5
##             DEC R5
##             BMI 1$
##             BNE 10$
## 
##         1$: MOV $0100000, R0
##             MOV $040000, R1
##         2$: ASLB (R0)
##             CLRB (R0)+
##             SOB R1, 2$
## 
##             CALL MOSAIC
## 
##         3$: TST PLAY_NOW
##             BNE 3$
## 
##             CALL PSGP_PLAYER + 4 #MUTE
## 
##             MTPS $0340
##            #MOVB $0100 + BK11_PALETTE, @$0177663
##             MOV $2, @$0102
##             MOV $0102, @$0100
## 
##             TRAP 0; .word 06400 #1-7
##             JMP @$0100000
## 
TIKTAK:
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

            CMP  FRAME_NUMBER, $68
            BLO  TIKTAK_EXIT
            CMP  FRAME_NUMBER, $9840
            BGE  TIKTAK_EXIT

##             ADD $96-18, .-014
##             MOV (PC)+, R0
##         BK11_PALETTE_IDX:   .word PALETTES_FOR_CHANGE
##         10$:MOVB (R0)+, R1
##             BNE 1$
##             MOV $PALETTES_FOR_CHANGE, R0
##             BR 10$
##         1$: MOV R0, BK11_PALETTE_IDX
##             MOVB R1, @$0177663

    TIKTAK_EXIT:
            MOV  (SP)+, R5       
            MOV  (SP)+, R4
            MOV  (SP)+, R3       
            MOV  (SP)+, R2       
            MOV  (SP)+, R1       
            MOV  (SP)+, R0       

            RTI

## PALETTES_FOR_CHANGE:
##     .byte  014,  014,  014, 0215,  014,  014, 0216, 014
##     .byte 0203,  014, 0201,  014 , 014,  014, 0202, 014
##     .byte  014,  014, 0204,  014, 0203, 0203,  014, 014
##     .byte 0216,  014, 0205,  014,  014, 0206, 0207, 014
##     .byte  014, 0205, 0205,    0
##     .even
## 
## TUNNEL:
##         DUMMY1:
##             .word 3, 026, 040, 026, 05000
##         DUMMY2:
##             .word 0, 032, 040, 032, 04400
##             .word 3, 040, 052, 040, 04000
##             .word 5, 046, 062, 046, 04000
## TUNNEL_END:
##             .word 0
## 
## 
## DRAW_CIRCLE_OPER:
##             MOVB $014, @$0177663
##             MOV R4, -(SP)
##             MOV R5, -(SP)
##             CALL DRAW_CIRCLE
##             MOV (SP)+, R5
##             MOV (SP)+, R4
##             MOVB @BK11_PALETTE_IDX, R0
##             BEQ 10$
##             MOVB R0, @$0177663
##         10$:RETURN
## DRAW_CIRCLE:
##             CLR R0
##             MOV R1, R3
##             ASL R3
##             MOV R0, R4
##             MOV R1, R5
##             ASL R5
##     CIRCLE_LOOP:
##             SUB (PC)+, R4
##         CIRCLE_FORMER:  .word 04400
##             ADD R4, R3
##             BCS 10$
##             TST -(R5)
##             ADD R5, R3
##             DEC R1
##         10$:MOV R0, -(SP)
##             MOV R1, -(SP)
##             COM $0
##             BEQ 1$
##             CALL DRAW_DOTS
##             BR 2$
##         1$: MOV R0, R2
##             MOV R1, R0
##             MOV R2, R1
##             CALL DRAW_DOTS
##         2$: MOV (SP)+, R1
##             MOV (SP)+, R0
##             INC R0
##             MOV R0, R2
##             INC R2
##             CMP R2, R1
##             BLE CIRCLE_LOOP
## DRAW_DOTS:
##             CALL DRAW_DOT
##             NEG R1
##             CALL DRAW_DOT
##             NEG R0
##             CALL DRAW_DOT
##             NEG R1
## DRAW_DOT:
##             MOV R3, -(SP)
##             MOV $0100, R2
##             MOV R2, R3
##             ADD R1, R3
##             SWAB R3
##             ADD R0, R2
##             BIS R2, R3
##             ASR R3
##             ADD (PC)+, R3
##         SCREEN_ADDER:   .word 041000
##             BR 10$
##             MOV 040000(R3), (R3)
##             MOV 040200(R3), 0200(R3)
##             MOV 040000-0200(R3), -0200(R3)
##             MOV 040002(R3), 2(R3)
##             BR DRAW_DOT_EXIT
## 
##         10$:BIC $0177770, R2
##             ASL R2
##         CODE_MODIFY:
##             MOV DOTS(R2), R2
##             XOR R2, (R3)
##             XOR R2, 2(R3)
##     DRAW_DOT_EXIT:
##             MOV (SP)+, R3
##             RETURN
## DOTS:
##             .word 0b0000000000000011
##             .word 0b0000000000001100
##             .word 0b0000000000110000
##             .word 0b0000000011000000
##             .word 0b0000001100000000
##             .word 0b0000110000000000
##             .word 0b0011000000000000
##             .word 0b1100000000000000
## 
##             .word 0b0000000000000001
##             .word 0b0000000000000100
##             .word 0b0000000000010000
##             .word 0b0000000001000000
##             .word 0b0000000100000000
##             .word 0b0000010000000000
##             .word 0b0001000000000000
##             .word 0b0100000000000000
## 
##             .word 0b0000000000000010
##             .word 0b0000000000001000
##             .word 0b0000000000100000
##             .word 0b0000000010000000
##             .word 0b0000001000000000
##             .word 0b0000100000000000
##             .word 0b0010000000000000
##             .word 0b1000000000000000
## DOTS_END:
## 
## CUR_PSGP_PLAYER:
##                 .word 0, 0
##                #.word GSPLAY, (GSPLAY_END - GSPLAY) / 2
## 
## PSGP_PLAYER:
##     AZBKPLAY:
##            #.include "AZBKPLAY.mac"
##             .even
##     AZBKPLAY_END:
## 
## GFX_timeCS_PREP:
##             MOV $RED_timeCS, R1
##             MOV $RED_timeCS + GFX_timeCS_SIZE, R0
##             CALL MONO_TO_COLOR
## 
##             MOV $RED_timeCS, R1
##             MOV $GREEN_timeCS, R0
##             MOV $GFX_timeCS_SIZE_WORDS, R2
##         10$:MOV (R1)+, (R0)
##             BIC $0125252, (R0)
##             MOV (R0), GFX_timeCS_SIZE(R0)
##             ASL (R0)+
##             SOB R2, 10$
## 
##             MOV $GFX_timeCS, R1
##             MOV $RED_timeCS, R0
##             CALL MONO_TO_COLOR
##             RETURN
## 
MONO_TO_COLOR:
            MOV $GFX_timeCS_SIZE_WORDS, R2
            MONO_TO_COLOR_LOOP:
                MOVB -(R1), R3
                MOV $010, R4
                1$:
                    ASR R3
                    ROR R5
                    ASR R5
                SOB R4, 1$
                MOV R5, -(R0)
            SOB R2, MONO_TO_COLOR_LOOP
            RETURN

CLOCKHANDS_GFX_PREP:
            MOV  $CLOCKHAND_GFX_END, R1
            MOV  $CLOCKHANDS + CLOCKHAND_SIZE, R0
            MOV  $CLOCKHAND_SIZE_WORDS, R2
            CLR  R5
            CALL MONO_TO_COLOR_LOOP

            MOV $CLOCKHAND_SIZE_WORDS, R2
            MOV $CLOCKHAND_MIN, R3
            MOV $CLOCKHAND_HOUR, R4
            10$:
                MOV (R0), (R3)+
                MOV (R0)+, (R4)+
            SOB R2, 10$

            MOV $2, R3
            MOV $3, R4
            MOV $0b1100000000001111, R5
            CALL CLOCKHAND_REDUCE

            INC R3
            INC R4
            MOV $0b1111000000111111, R5

    CLOCKHAND_REDUCE:
            MOV $020, R1
            SUB R3, R1
            SUB R4, R1

            MOV $12, CLOCKHAND_COUNT

    NEXT_CLOCKHAND_PHASE:
            MOV R3, R2
            10$:
                CLR (R0)+
                CLR (R0)+
            SOB R2, 10$

            MOV R1, R2
            1$:
                BICB R5, (R0)+
                INC R0
                INC R0
                SWAB R5
                BICB R5, (R0)+
                SWAB R5
            SOB R2, 1$

            MOV R4, R2
            2$:
                CLR (R0)+
                CLR (R0)+
            SOB R2, 2$

           .equiv CLOCKHAND_COUNT, .+2
            DEC $0
            BNE NEXT_CLOCKHAND_PHASE
            RETURN

## REMOVE_PROGRESS:
##            #MOV ACTUAL_PAGES, -(SP)
##             TRAP 0; .word 017400
## 
##             MOV R0, -(SP)
##             MOV R1, -(SP)
##             MOV $064020, R0
##             ADD $4, .-2
##             MOV $4, R1
##         10$:CLR (R0)+
##             CLR (R0)+
##             ADD $074, R0
##             SOB R1, 10$
##             MOV (SP)+, R1
##             MOV (SP)+, R0
##            #MOV (SP), ACTUAL_PAGES
##             MOV (SP)+, @$0177716
##             RETURN
## 
GFX_timeCS_MASK:
        .incbin "build/timecs1m.raw"
        .incbin "build/timecs2m.raw"
        .incbin "build/timecs3m.raw"
        .incbin "build/timecs4m.raw"
        .incbin "build/timecs5m.raw"
        .incbin "build/timecs6m.raw"
GFX_timeCS:
RED_timeCS:
        .incbin "build/timecs1.raw"
        .incbin "build/timecs2.raw"
        .incbin "build/timecs3.raw"
        .incbin "build/timecs4.raw"
        .incbin "build/timecs5.raw"
        .incbin "build/timecs6.raw"
GREEN_timeCS:
BLUE_timeCS:

CLOCKHAND_GFX_START:
        .incbin "build/clockhand.raw"
CLOCKHAND_GFX_END:
        
        .equiv GFX_timeCS_SIZE, (GFX_timeCS - GFX_timeCS_MASK) * 2
        .equiv GFX_timeCS_SIZE_WORDS, GFX_timeCS_SIZE >> 1

       #.equiv GREEN_timeCS, RED_timeCS + GFX_timeCS_SIZE
       #.equiv BLUE_timeCS, GREEN_timeCS + GFX_timeCS_SIZE

       #.equiv CLOCKHANDS, BLUE_timeCS + GFX_timeCS_SIZE
        .equiv CLOCKHANDS, CLOCKHAND_GFX_START
        .equiv CLOCKHAND_SIZE, (CLOCKHAND_GFX_END - CLOCKHAND_GFX_START) * 2
        .equiv CLOCKHAND_SIZE_WORDS, CLOCKHAND_SIZE >> 1

        .equiv CLOCKHAND_SEC, CLOCKHANDS
        .equiv CLOCKHAND_MIN, CLOCKHAND_SEC + CLOCKHAND_SIZE
        .equiv CLOCKHAND_HOUR, CLOCKHAND_MIN + CLOCKHAND_SIZE

        .equiv CLOCKHAND_BUFFER, CLOCKHAND_HOUR + CLOCKHAND_SIZE

LoadPSGP:
        CALL Bootstrap.DiskRead_Start
        CALL Bootstrap.DiskIO_WaitForFinish
        MOV  $GFX_W3,R1
        MOV  $FB1,R2
        CALL LZSA_UNPACK
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
        RETURN
            
LZSA_UNPACK:
           .include "unlzsa3.s"

Bootstrap.DiskRead_Start: #-------------------------------------------------
        MOVB $010,@$PS.Command # read from disk

Bootstrap.DiskIO_Start:
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
# Bootstrap.DiskRead_Start #------------------------------------------------
ParamsStruct:
    PS.Status:          .byte -1  # operation status code
    PS.Command:         .byte 010 # read data from disk
    PS.DeviceType:      .byte 02       # double sided disk
    PS.DeviceNumber:    .byte 0x00 | 0 # bit 7: head(0-bottom, 1-top) ∨ drive number 0(0-3)
    PS.AddressOnDevice: .byte 0, 1     # track 0(0-79), sector 1(1-10)
    PS.CPU_RAM_Address: .word 0
    PS.WordsCount:      .word 0        # number of words to transfer
Bootstrap.DiskIO_WaitForFinish: #--------------------------------------------{{{
        CLC
        MOVB @$PS.Status,R0
        BMI  Bootstrap.DiskIO_WaitForFinish
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
# Bootstrap.DiskIO_WaitForFinish #-------------------------------------------}}}
title_palette: #----------------------------------------------------------------
    .word      1, setOffscreenColors
    .word         BLACK | BLUE  << 4 | BLACK << 8 | BLACK << 12
    .word         BLACK | BLACK << 4 | BLACK << 8 | BLACK << 12
    .word      0, setCursorScalePalette, cursorGraphic, scale320 | RGb
    .word      1, setColors; .byte Black, brRed, brGreen, White
    .word untilEndOfScreen
#-------------------------------------------------------------------------------
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
GFX_W3:
           .even

          #.incbin "songs/7004.lzsa" # 7642 -> 14928
          #.incbin "songs/7003.lzsa" # 10870 -> 16384
          #.incbin "songs/7002.lzsa" # 2894 -> 3862
          #.incbin "songs/7001.lzsa" # 7880 -> 16384
end:
