anf:      movem.l   d0-d7/a0-a6,-(sp)
          movea.l   64(sp),a0 ; anf
          movea.l   68(sp),a1 ; ende
anf2:     moveq.l   #0,d1
          move.l    d1,d2
          move.w    (a0),d1
          move.w    2(a0),d2
          btst      #15,d1
          bne.s     anf5
anf3:     btst      #15,d2
          bne.s     anf6
anf4:     add.l     d2,d1    ; plus und plus = plus
          bra.s     ende
anf5:     btst      #15,d2
          bne.s     anf7     ; minus und minus = minus
          not.w     d1
          sub.l     d1,d2    ; minus und plus = ?
          move.l    d2,d1
          bra.s     ende
anf6:     not.w     d2       ; plus und minus = ?
          sub.l     d2,d1
          bra.s     ende
anf7:     add.l     d2,d1    ; add + wech
ende:     asr.l     #1,d1
          move.w    d1,(a0)+
          move.w    d1,(a0)+
          cmp.l     a1,a0
          blt.s     anf2
weg:      movem.l   (sp)+,d0-d7/a0-a6
          rts       
