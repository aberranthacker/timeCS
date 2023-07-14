# vim: set tabstop=4 :

# optimized LZSA3 decompressor for PDP-011 by Manwe and Ivanq
# Thanks to Ivan Gorodetsky
# Usage:
# MOV $src_adr,R1
# MOV $PBP1DT,R2
# MOV $PBPADR,R4
# MOV $dst_adr,(R4)
# CALL Unpack

#.global Unpack

Unpack2BP:
        CLR  R5             # no nibbles sign
Unpack2BP.Token:
        MOVB (R1)+,R3       # read token

Unpack2BP.Liter:
        MOV  R3,R0
        BIC  $0177774,R0     # get 2 bits
        BEQ  Unpack2BP.Decode

        CMP  R0,$3           # literals length
        BNE  Unpack2BP.Copy

        CALL Unpack2BP.Extend
Unpack2BP.Copy:
            MOVB (R1)+,(R2)     # literals length in R0
            INC (R4)
        SOB R0,Unpack2BP.Copy

Unpack2BP.Decode:
        PUSH R3
        ROLB R3             # get 2 bits
        ROL  R0
        ROLB R3
        ROL  R0
        ASL  R0
        ADD  R0,PC          # run subroutine
        BR Unpack2BP.oOther
        BR Unpack2BP.o9bit
        BR Unpack2BP.o13bit

Unpack2BP.o5bit:
        CALL Unpack2BP.Nibble         # get nibble in R0
        ROLB R3
        ROL  R0
        INC  R0

Unpack2BP.Save:
        MOV R0,Unpack2BP.offset # save offset for future

Unpack2BP.Match:
        POP  R0
        ASR  R0
        ASR  R0
        BIC  $0177770,R0    # get 3 bits
        CMP  R0,$7
        BNE  Unpack2BP.Clone

        CALL Unpack2BP.Extend
        TSTB R0        # match length
        BEQ Unpack2BP.Exit

Unpack2BP.Clone:
        PUSH R1
        PUSH R5
        MOV  (R4),R3
        MOV  R3,R5
       .equiv Unpack2BP.offset, .+2
        SUB  $0,R3

      # MOVB (R3)+,(R2)+
        MOV  R3,(R4)
        INC  R3
        MOVB (R2), R1
        MOV  R5,(R4)
        INC  R5
        MOVB R1,(R2)

        INC  R0
        1$:
          # MOVB (R3)+,(R2)+
            MOV  R3,(R4)
            INC  R3
            MOVB (R2), R1
            MOV  R5,(R4)
            INC  R5
            MOVB R1,(R2)
        SOB  R0,1$

        MOV  R5,(R4)
        POP  R5
        POP  R1
        BR   Unpack2BP.Token

Unpack2BP.o9bit:
        CLR  R0
        BISB (R1)+,R0
        ROLB R3
        ROL  R0
        INC  R0
        BR   Unpack2BP.Save

Unpack2BP.o13bit:
        CALL Unpack2BP.Nibble         # get nibble in R0
        ROLB R3
        ROL  R0
        SWAB R0
        BISB (R1)+,R0       # 8 bits
        ADD  $513,R0
        BR   Unpack2BP.Save

Unpack2BP.oOther:
        ROLB R3
        BCS  Unpack2BP.Match
        BISB (R1)+,R0       # read 016 bits
        SWAB R0
        BISB (R1)+,R0
        BR   Unpack2BP.Save

Unpack2BP.Nibble:
        COM  R5
        BMI  1$

        MOV  R5,R0
        CLR  R5
        BR   2$

1$:     BICB (R1)+,R5       # read 2 nibbles
        MOV  R5,R0
        ASR  R0
        ASR  R0
        ASR  R0
        ASR  R0
2$:     BIC  $0177760,R0     # leave 4 low bits
        RETURN

Unpack2BP.Extend:
        PUSH R0             # save original value
        CALL Unpack2BP.Nibble         # get nibble in R0
        BNE  Unpack2BP.Ext2

        BISB (R1)+,R0
        BNE  Unpack2BP.Ext1

        # unnecessary for short files
        BISB (R1)+,R0   # read high byte
        SWAB R0
        BISB (R1)+,R0   # read low byte
        TST  (SP)+      # skip saved R0
        RETURN

Unpack2BP.Ext1:
        ADD  $15,R0
Unpack2BP.Ext2:
        DEC  R0
        ADD  (SP)+,R0        # add original value
Unpack2BP.Exit:
        RETURN
