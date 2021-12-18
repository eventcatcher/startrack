anf:      movem.l   d0-d7/a0-a6,-(sp)
          movea.l   64(sp),a0 ; anf
          movea.l   68(sp),a1 ; ende
          moveq.l   #0,d1     ; zaehler pos
          moveq.l   #0,d4     ; zaehler neg
          moveq.l   #0,d2     ; zugriffszaehler
          moveq.l   #0,d3
anf2:     move.w    (a0),d3
          adda.l    #4,a0
          btst      #15,d3
          beq.s     positiv
negativ:  neg.w     d3
          add.l     d3,d4
          bra.s     weiter
positiv:  add.l     d3,d1
weiter:   add.l     #1,d2
          cmp.l     a1,a0
          blt.s     anf2
          sub.l     d4,d1
          bpl.s     posgo
          neg.l     d1
          divu.w    d2,d1
          andi.l    #$ffff,d1
          move.l    d1,d2
          move.l    #$10000,d1
          sub.l     d2,d1
          bra.s     ready    
posgo:    divu.w    d2,d1
          andi.l    #$ffff,d1
ready:    lea.l     wert(pc),a2
          move.w    d1,(a2)
weg:      movem.l   (sp)+,d0-d7/a0-a6
          rts       
wert:     dc.l 0

