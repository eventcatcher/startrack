anf:      movem.l   d0-d7/a0-a6,-(sp)
          movea.l   64(sp),a0 ; anf
          movea.l   68(sp),a1 ; ende
          moveq.l   #0,d0
anf2:     move.l    d0,(a0)+
          cmp.l     a1,a0
          blt.s     anf2
weg:      movem.l   (sp)+,d0-d7/a0-a6
          rts       
