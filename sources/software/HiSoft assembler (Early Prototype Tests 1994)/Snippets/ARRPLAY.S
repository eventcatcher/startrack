begin:    movem.l   d0-d7/a0-a6,-(sp)
	  movea.l   64(sp),a3  ; von
          move.l    68(sp),d1  ; bis
          move.l    72(sp),d3 ; loop
	  movea.l   76(sp),a6  ; Returnwert
          movem.l   d0-d7/a0-a6,-(sp)
          lea.l     ptr(pc),a5
          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp
clear:    move.w    #11,-(sp)
          trap      #1
          addq.l    #2,sp
          cmpi.l    #0,d0
          beq.s     weiter
          move.w    #1,-(sp)
          trap      #1
          addq.l    #2,sp
          bra.s     clear
weiter:   move.w    #34,-(sp)
          trap      #14
          addq.l    #2,sp
          movea.l   d0,a0
          lea.l     rett(pc),a1
          move.l    32(a0),2(a1)
          lea.l     neuikbd(pc),a1
          move.l    a1,32(a0)
          movem.l   (sp)+,d0-d7/a0-a6
          lea.l     $df0441,a0
          lea.l     $df04c0,a1          ; Wordmode
          move.b    #4,(a0)
          moveq.l   #8,d4               ; Anzahl der Backstep
          lea.l     merk(pc),a4
          moveq.l   #8,d5
          moveq.l   #4,d6
anf0:     movea.l   a3,a2
anf1:     move.b    (a0),d0
          and.b     d6,d0
          beq.s     anf1
          move.b    (a2)+,d7
          bclr      d5,d7     ; Parity loeschen (Kennung fÅr Rechter Kanal)
          move.w    d7,(a1)   ; High-Byte senden
anf2:     move.b    (a0),d0
          and.b     d6,d0
          beq.s     anf2
          move.b    (a2)+,d7
          bclr      d5,d7     ; Parity loeschen (Kennung fÅr Rechter Kanal)
          move.w    d7,(a1)   ; Low-Byte senden
anf3:     move.b    (a0),d0
          and.b     d6,d0
          beq.s     anf3
          move.b    (a2)+,d7
          bset      d5,d7     ; Parity einfÅgen (Kennung fÅr Linker Kanal)
          move.w    d7,(a1)   ; High-Byte senden
anf4:     move.b    (a0),d0
          and.b     d6,d0
          beq.s     anf4
          move.b    (a2)+,d7
          bset      d5,d7     ; Parity einfÅgen (Kennung fÅr Linker Kanal)
          move.w    d7,(a1)   ; Low-Byte senden
          move.w    (a4),d0
          bne.s     weg2
          suba.l    d4,a2
          cmpa.l    d1,a2
          bne.s     anf1
          tst.l     d3
          beq.s     weg
          bra.s     anf0
weg2:     move.l    #1,(a6)
weg:      lea.l     ptr2(pc),a5
          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp
          move.w    #34,-(sp)
          trap      #14
          addq.l    #2,sp
          movea.l   d0,a0
          lea.l     rett(pc),a1
          move.l    2(a1),32(a0)
          movem.l   (sp)+,d0-d7/a0-a6
          rts
ptr:      dc.b $12
ptr2:     Dc.b $8
merk:     Dc.w 0
neuikbd:  move.w    #1,merk
rett:     jmp       rett

