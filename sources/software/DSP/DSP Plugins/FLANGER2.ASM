; gepatchter Flanger aus dem Winrec-Paket


IPR             equ     $FFFF   ;Interrupt Priority Register
BCR             equ     $FFFE   ;Bus Control Register
PLL             equ     $FFFD   ;PLL Control Register
SSIDR           equ     $FFEF   ;SSI Data Register
RX              equ     $FFEF
TX              equ     $FFEF
SSISR           equ     $FFEE   ;SSI Status Register
CRB             equ     $FFED   ;SSI Control Register B
CRA             equ     $FFEC   ;SSI Control Register A
HRX             equ     $FFEB
HSR             equ     $FFE9
PCD             equ     $FFE5   ;Port C Data Register
PCDDR           equ     $FFE3   ;Port C Data Direction Register
PCC             equ     $FFE1   ;Port C Control Register
PBC             equ     $FFE0   ;Port B Control Register

        org     p:$0
        jmp     start

        org     p:$0c
        jsr     datain

        org     p:$10
        jsr     dataout

	org     x:$0
wet_gain        dc      $666666                         ;input queue
fl_depth        dc      $000032
fl_rate         dc      $0000A8                               ;saved left
fl_centre       dc      $00012C                               ;and right
dry_gain        dc      $599999                               ;output queue
wavepos         dc      0
word_mask       dc      $FFFFFE                               ;input queue
in_l            dc      1
in_r            dc      1                               ;saved left
out_l           dc      1                               ;and right
out_r           dc      1                               ;output queue
temp            dc      1
sync            dc      0                               ;input queue

          org      p:$40
start:    movep   x:HRX,X0
          move    #0,sp
          movep   #>$004000,x:CRA
          movep   #>$00ffe8,x:PCC
          btst    #$04,x:SSISR
          movep   #>$00F200,x:CRB
          movep   #>$000000,x:BCR
          movep   #>$003000,x:IPR
          movep   #>$000001,x:PBC
          move    #$00,R3
          or      #$04,omr
          jsr     effinit
ints_on:  and     #$fc,mr
main:     jclr    #$00,x:HSR,Wait1
          movep   x:HRX,N3
Wait2:    jclr    #$00,x:HSR,Wait2
          movep   x:HRX,x:(R3+N3)
Wait1:    jclr    #$00,x:sync,main
          jsr     doeffect
          bclr    #$00,x:sync
          jmp     main
datain:   bset    #$00,x:sync
          move    X0,x:temp
          jclr    #$01,x:SSISR,do_leftin
do_rightin:
          movep   x:RX,X0
          move    X0,x:in_r
          move    x:temp,X0
          rti
do_leftin:
          movep   x:RX,X0
          move    X0,x:in_l
          move    x:temp,X0
          rti

dataout:  move    X0,x:temp
          jclr    #$01,x:SSISR,do_leftout
do_rightout:
          move    x:out_r,X0
          movep   X0,x:RX
          move    x:temp,X0
          rti
do_leftout:
          move    x:out_l,X0
          movep   X0,x:RX
          move    x:temp,X0
          rti

effinit:  move    #>$002000,R0
          move    #>$002000,R7
          move    #>$001fff,M0
          move    #>$001fff,M7
          move    #$ff,M2
          move    #>$000600,N7
          move    #>$001000,R2
          move    #>$000001,X0
          move    #>$002000,R6
          move    #>$002000,Y0
          move    #$00,A
          move    #>$00ffff,M2
          move    #>$00ffff,M6
          do      X0,clrx
          move    A,x:(R2)+
clrx:     nop
          nop
          nop
          do      Y0,clry
          move    A,Y:(r6)+
clry:     rts

doeffect: move    x:>wavepos,A
          move    X:fl_rate,X0
          add     X0,A
          move    #$01,A2
          move    A1,X:>wavepos
          rep     #<$0010
          asr     A
          move    A1,R2
          move    x:in_l,A
          move    x:out_l,X0
          move    x:wet_gain,X1
          macr    +X1,X0,A
          move    A,y:(R0)+
          move    y:(R2),X0
          move    x:fl_depth,X1
          mpyr    -X1,X0,A
          move    x:fl_centre,B
          sub     B,A x:>word_mask,X0
          and     X0,A
          move    A,N7
          nop
          move    y:(R7+N7),X0
          move    x:>dry_gain,X1
          mpyr    +X1,X0,A (R7)+
          move    A,x:out_l
          move    x:in_r,A
          move    x:out_r,X0
          move    x:wet_gain,X1
          macr    +X1,X0,A
          move    A,y:(R0)+
          move    y:(R7+N7),X0
          move    x:>dry_gain,X1
          mpyr    +X1,X0,A (R7)+
          move    A,x:out_r
endeff:   rts
