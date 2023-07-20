# vim: set tabstop=4 :

# optimized LZSA3 decompressor for PDP-011 by Manwe and Ivanq
# Thanks to Ivan Gorodetsky
# Usage:
# MOV $CPB1DT,R1
# MOV $dst_adr,R2
# MOV $CBPADR,R4
# MOV $src_adr,(R4)
# CALL Unpack

#.global Unpack

UnpackFromBP:
        CLR  R5             # no nibbles sign
UnpackFromBP.Token:
        MOVB (R1),R3        # read token
        INC  (R4)

UnpackFromBP.Liter:
        MOV  R3,R0
        BIC  $0177774,R0     # get 2 bits
        BEQ  UnpackFromBP.Decode

        CMP  R0,$3           # literals length
        BNE  UnpackFromBP.Copy

        CALL UnpackFromBP.Extend
UnpackFromBP.Copy:
            MOVB (R1),(R2)+ # literals length in R0
            INC (R4)
        SOB R0,UnpackFromBP.Copy

UnpackFromBP.Decode:
        PUSH R3
        ROLB R3             # get 2 bits
        ROL  R0
        ROLB R3
        ROL  R0
        ASL  R0
        ADD  R0,PC          # run subroutine
        BR UnpackFromBP.oOther
        BR UnpackFromBP.o9bit
        BR UnpackFromBP.o13bit

UnpackFromBP.o5bit:
        CALL UnpackFromBP.Nibble         # get nibble in R0
        ROLB R3
        ROL  R0
        INC  R0

UnpackFromBP.Save:
        MOV R0,UnpackFromBP.offset # save offset for future

UnpackFromBP.Match:
        POP  R0
        ASR  R0
        ASR  R0
        BIC  $0177770,R0    # get 3 bits
        CMP  R0,$7
        BNE  UnpackFromBP.Clone

        CALL UnpackFromBP.Extend
        TSTB R0        # match length
        BEQ UnpackFromBP.Exit

UnpackFromBP.Clone:
        MOV  R2,R3
       .equiv UnpackFromBP.offset, .+2
        SUB  $0,R3
        MOVB (R3)+,(R2)+
        INC  R0
        1$:
            MOVB (R3)+,(R2)+
        SOB  R0,1$
        BR   UnpackFromBP.Token

UnpackFromBP.o9bit:
        CLR  R0
        BISB (R1),R0
        INC  (R4)
        ROLB R3
        ROL  R0
        INC  R0
        BR   UnpackFromBP.Save

UnpackFromBP.o13bit:
        CALL UnpackFromBP.Nibble         # get nibble in R0
        ROLB R3
        ROL  R0
        SWAB R0
        BISB (R1),R0       # 8 bits
        INC  (R4)
        ADD  $513,R0
        BR   UnpackFromBP.Save

UnpackFromBP.oOther:
        ROLB R3
        BCS  UnpackFromBP.Match
        BISB (R1),R0       # read 016 bits
        INC  (R4)
        SWAB R0
        BISB (R1),R0
        INC  (R4)
        BR   UnpackFromBP.Save

UnpackFromBP.Nibble:
        COM  R5
        BMI  1$

        MOV  R5,R0
        CLR  R5
        BR   2$

1$:     BICB (R1),R5       # read 2 nibbles
        INC  (R4)
        MOV  R5,R0
        ASR  R0
        ASR  R0
        ASR  R0
        ASR  R0
2$:     BIC  $0177760,R0   # leave 4 low bits
        RETURN

UnpackFromBP.Extend:
        PUSH R0             # save original value
        CALL UnpackFromBP.Nibble # get nibble in R0
        BNE  UnpackFromBP.Ext2

        BISB (R1),R0
        INC  (R4)
        TST R0
        BNZ  UnpackFromBP.Ext1

        # unnecessary for short files
        BISB (R1),R0   # read high byte
        INC  (R4)
        SWAB R0
        BISB (R1),R0   # read low byte
        INC  (R4)
        TST  (SP)+     # skip saved R0
        RETURN

UnpackFromBP.Ext1:
        ADD  $15,R0
UnpackFromBP.Ext2:
        DEC  R0
        ADD  (SP)+,R0  # add original value
UnpackFromBP.Exit:
        RETURN
