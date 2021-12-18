anf:      movem.l   d0-d7/a0-a6,-(sp)
          movea.l   64(sp),a0 ; ende
          movea.l   68(sp),a1 ; anf
          movea.l   72(sp),a2 ; destende
anf2:     move.l    -(a0),-(a2)
          cmp.l     a1,a0
          bgt.s     anf2
weg:      movem.l   (sp)+,d0-d7/a0-a6
          rts       
