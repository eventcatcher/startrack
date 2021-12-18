begin:    movem.l   d0-d7/a0-a6,-(sp)
	  movea.l   64(sp),a3  ; von
          move.l    68(sp),d1  ; bis
          move.l    72(sp),d3 ; loop
          move.l    76(sp),a4 ; Returnwert
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
anf0:     movem.l   (sp)+,d0-d7/a0-a6
          movem.l   d0-d7/a0-a6,-(sp)
          lea.l     $df0441,a0
          lea.l     $df04c0,a1          ; Wordmode
          move.b    #4,(a0)
          lea.l     merk(pc),a4
          moveq.l   #8,d5
          moveq.l   #4,d6
          movea.l   a3,a2
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
          bne       weg
          cmpa.l    d1,a2
          bne.s     anf1
          movem.l   (sp)+,d0-d7/a0-a6
          movem.l   d0-d7/a0-a6,-(sp)
          lea.l     $df0441,a0
          lea.l     $df04c0,a1          ; Wordmode
          move.l    d1,d2
          move.l    a3,d1
          add.l     #4,d1 
          movea.l   d2,a3
          suba.l    #4,a3
          moveq.l   #4,d4
          lea.l     merk(pc),a4
          moveq.l   #8,d5
          moveq.l   #4,d6
          movea.l   a3,a2
anfb1:    move.b    (a0),d0
          and.b     d6,d0
          beq.s     anfb1
          move.b    (a2)+,d7
          bclr      d5,d7     ; Parity loeschen (Kennung fÅr Rechter Kanal)
          move.w    d7,(a1)   ; High-Byte senden
anfb2:    move.b    (a0),d0
          and.b     d6,d0
          beq.s     anfb2
          move.b    (a2)+,d7
          bclr      d5,d7     ; Parity loeschen (Kennung fÅr Rechter Kanal)
          move.w    d7,(a1)   ; Low-Byte senden
anfb3:    move.b    (a0),d0
          and.b     d6,d0
          beq.s     anfb3
          move.b    (a2)+,d7
          bset      d5,d7     ; Parity einfÅgen (Kennung fÅr Linker Kanal)
          move.w    d7,(a1)   ; High-Byte senden
anfb4:    move.b    (a0),d0
          and.b     d6,d0
          beq.s     anfb4
          move.b    (a2)+,d7
          bset      d5,d7     ; Parity einfÅgen (Kennung fÅr Linker Kanal)
          move.w    d7,(a1)   ; Low-Byte senden
          move.w    (a4),d0
          bne.s     weg2
          suba.l    d4,a2
          cmpa.l    d1,a2
          bne.s     anfb1
          tst.l     d3
          beq.s     weg
          bra       anf0
weg2:     movem.l   (sp)+,d0-d7/a0-a6
          move.l    #1,(a4)
          bra.s     weg3
weg:      movem.l   (sp)+,d0-d7/a0-a6
weg3:     lea.l     ptr2(pc),a5
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
neuikbd:  move.w    #1,merk
rett:     jmp       rett
merk:     Dc.w 0
          END
