anf:      movem.l   d0-d7/a0-a6,-(sp)
          move.l    64(sp),d7 ; treshold
          move.b    #2,$df0441      ; REC-FIFO loeschen
          move.b    #0,$df0441
          movem.l   d0-d7/a0-a6,-(sp)
clear:    move.w    #11,-(sp)
          trap      #1
          addq.l    #2,sp
          cmpi.l    #0,d0
          beq.s     weiter
          move.w    #1,-(sp)
          trap      #1
          addq.l    #2,sp
          bra.s     clear
weiter:   movem.l   (sp)+,d0-d7/a0-a6
anf2:     movem.l   d1-d7/a0-a6,-(sp)
          move.w    #11,-(sp)
          trap      #1
          addq.l    #2,sp
          movem.l   (sp)+,d1-d7/a0-a6
          cmpi.l    #0,d0
          bne       weg
          move.w    $df04c0,d1      ; auf 1 warten
          btst      #8,d1
          beq.s     anf2
          move.w    $df04c0,d1      ; wenn 0, weiter
          btst      #8,d1
          bne.s     anf2
          andi.w    #$ff,d1
          asl.w     #8,d1
          move.w    $df04c0,d2      ; wenn 0, weiter
          btst      #8,d2
          bne.s     anf2
          andi.w    #$ff,d2
          add.w     d2,d1
          move.w    $df04c0,d2      ; wenn 1, weiter
          btst      #8,d2
          beq.s     anf2
          andi.w    #$ff,d2
          asl.w     #8,d2
          move.w    $df04c0,d3      ; wenn 1, weiter
          btst      #8,d3
          beq.s     anf2
          andi.w    #$ff,d3
          add.w     d3,d2
          move.w    $df04c0,d3      ; wenn 0, weiter
          btst      #8,d3
          bne.s     anf2
          andi.w    #$ff,d3
          asl.w     #8,d3
          move.w    $df04c0,d4      ; wenn 0, weiter
          btst      #8,d4
          bne       anf2
          andi.w    #$ff,d4
          add.w     d4,d3
          move.w    $df04c0,d4      ; wenn 1, weiter
          btst      #8,d4
          beq       anf2
          andi.w    #$ff,d4
          asl.w     #8,d4
          move.w    $df04c0,d5      ; wenn 1, weiter
          btst      #8,d5
          beq       anf2
          andi.w    #$ff,d5
          add.w     d5,d4
          btst      #15,d1          ; Oberstes Bit da ?
          beq.s     weiter1         ; dann negieren
          not.w     d1
weiter1:  btst      #15,d2
          beq.s     weiter2
          not.w     d2
weiter2:  btst      #15,d3
          beq.s     weiter3
          not.w     d3
weiter3:  btst      #15,d4
          beq.s     weiter4
          not.w     d4
weiter4:  cmp.w     d7,d1           ; treshold vergleichen
          ble       anf2
          cmp.w     d7,d2
          ble       anf2
          cmp.w     d7,d3
          ble       anf2
          cmp.w     d7,d4
          ble       anf2
weg:      movem.l   (sp)+,d0-d7/a0-a6
          rts       
