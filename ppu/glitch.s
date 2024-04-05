Glitch.Add:
      # calculate FB1 SLTAB offset ---
        MOV  FB1_FirstRecAddr, R0
        SUB  FB0_FirstRecAddr, R0
        MOV  R0, FB1_SLTAB_OFFSET
      # ------------------------------

        CALL TRandW
      #         5432109876543210
        BIC  $0b1111111100000111, R0
        MOV  R0, R1                  # R1 = random lines count * 8

        CALL TRandW
      #         5432109876543210
        BIC  $0b1111100000000111, R0 # R0 = random line number * 8
       #MOV  $10 * 8, R0

        MOV  R0, R2
        ADD  R1, R2
        CMP  R2, $255 * 8 # line number + lines count > screen height
        BGE  1237$        # yes, skip glitch add section

      # check whether lines range intersects with existion "glitchy" lines
        MOV  $Glitch.Data, R5

Glitch.CompareWithNextGlitch:
        CMP  R5, $Glitch.Data.End  # are we reached end of present glitches table?
        BEQ  1237$                 # yes, exit the check

        TST  (R5)+
        BZE  Glitch.AddAnotherOne

        MOV  (R5)+, R3 # R3 = first existing glitch line
        MOV  R3, R4
        ADD  (R5)+, R4 # R4 = last existing glitch line
        CMP  R0, R4                       # is first glitch line below existing glitch?
        BGT  Glitch.CompareWithNextGlitch #   yes, check next existing glitch
        CMP  R2, R3                       # is last glitch line above existing glitch?
        BLE  Glitch.CompareWithNextGlitch #   yes, check next existing glitch
                                          #   no, proceed with removal then 
1237$:  RETURN
        
Glitch.AddAnotherOne: #------------------------------------------------------{{{
        MOV  FRAME_NUMBER, -2(R5) # store frame number when glitch was introduced
        MOV  R0, (R5)+            # store line where the glitch started
        MOV  R1, (R5)            # store number of lines affected by the glitch

        MOV  FB0_FirstRecAddr, R2 # first screen line SLTAB record
        ADD  R0, R2               # add offset to record to update
        ADD  $6, R2               # add offset of "next record" entry

        MOV  $PBPADR, R5 # R5 address register pointer
        MOV  $PBP0DT, R4 # R4 bitplane 0 data register pointer, PPU RAM

        MOV  R2, (R5)
      # read next SLTAB record address
        CLR  R3       # read line address
        BISB (R4), R3 # LSB -> R2
        INC  (R5)
        SWAB R3
        BISB (R4), R3 # MSB -> R2
        SWAB R3
      # ------------------------------
        CMP  R3, FB1_FirstRecAddr # is it points to FB1 SLTAB already?
        BGE  VblankInt_Finalize   # yes, do nothing

      # set link to FB1 SLTAB --------
       .equiv FB1_SLTAB_OFFSET, .+2
        ADD  $0, R3
      # ------------------------------
        SWAB R3
        MOV  R3, (R4) # MSB ->
        DEC  (R5)
        SWAB R3
        MOV  R3, (R4) # LSB ->
      # ------------------------------
        ADD  R1, R3
        MOV  R3, (R5)
      # ------------------------------
        CLR  R3       # read line address
        BISB (R4), R3 # LSB -> R2
        INC  (R5)
        SWAB R3
        BISB (R4), R3 # MSB -> R2
        SWAB R3
      # set link back to FB0 SLTAB ---
        SUB  FB1_SLTAB_OFFSET, R3
      # ------------------------------
        SWAB R3
        MOV  R3, (R4) # MSB ->
        DEC  (R5)
        SWAB R3
        MOV  R3, (R4) # LSB ->
#----------------------------------------------------------------------------}}}
        RETURN

Glitch.RemoveStale: #--------------------------------------------------------{{{
        MOV  $Glitch.Data, R1
        MOV  (R1)+, R0
        BZE  1237$             # no glitches to remove yet

        ADD  $2, R0            # add glitch retention frames count
        CMP  R0, FRAME_NUMBER  # is the oldest glitch retention time expired?
        BLO  Glitch.Remove     #   yes, remove the glitch
1237$:  RETURN                 #   no, do nothing

Glitch.Remove:
        MOV  FB0_FirstRecAddr, R2 # first screen line SLTAB record
        ADD  (R1)+, R2            # add offset to record to update
        ADD  $6, R2               # add offset of "next record" entry

        MOV  $PBPADR, R5 # R5 address register pointer
        MOV  $PBP0DT, R4 # R4 bitplane 0 data register pointer, PPU RAM

        MOV  R2, (R5)
      # read next SLTAB record address
        CLR  R2       # read line address
        BISB (R4), R2 # LSB -> R2
        INC  (R5)
        SWAB R2
        BISB (R4), R2 # MSB -> R2
        SWAB R2
        MOV  R2, R3
      # set link back to FB0 SLTAB --------
        SUB  FB1_SLTAB_OFFSET, R2

        SWAB R2
        MOV  R2, (R4) # MSB ->
        DEC  (R5)
        SWAB R2
        MOV  R2, (R4) # LSB ->
      # ------------------------------
        ADD  (R1), R3
        MOV  R3, (R5)
      # ------------------------------
        CLR  R3       # read line address
        BISB (R4), R3 # LSB -> R2
        INC  (R5)
        SWAB R3
        BISB (R4), R3 # MSB -> R2
        SWAB R3
      # set link back to FB1 SLTAB ---
        ADD  FB1_SLTAB_OFFSET, R3
      # ------------------------------
        SWAB R3
        MOV  R3, (R4) # MSB ->
        DEC  (R5)
        SWAB R3
        MOV  R3, (R4) # LSB ->
        
      # shift up removal queue
        MOV  $Glitch.Data, R5
        MOV  $Glitch.Data + 6, R4

Glitch.Data.ShiftNext:
        MOV  (R4)+, (R5)+
        MOV  (R4)+, (R5)+
        MOV  (R4)+, (R5)+
        CMP  R4, $Glitch.Data.End
        BNE  Glitch.Data.ShiftNext
        CLR  (R5)+
        CLR  (R5)+
        CLR  (R5)+
#----------------------------------------------------------------------------}}}
        RETURN
Glitch.Data:
   .rept 10
       .word 0 # frame number
       .word 0 # start line
       .word 0 # number of lines
   .endr
Glitch.Data.End:
