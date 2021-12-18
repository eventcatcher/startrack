anf:      movem.l   d0-d7/a0-a6,-(sp)
          movea.l   64(sp),a0 ; anf
          movea.l   68(sp),a1 ; ende
          movea.l   72(sp),a2 ; dest
          movea.l   76(sp),a3 ; grenzwert
anf2:     move.l    (a0)+,(a2)+
          cmp.l     a1,a0
          bge.s     weg
          cmp.l     a3,a2
          blt.s     anf2
weg:      movem.l   (sp)+,d0-d7/a0-a6
          rts       
