anf:      movem.l   d0-d7/a0-a6,-(sp)
          movea.l   64(sp),a0 ; anf
          movea.l   68(sp),a1 ; ende
          move.l    72(sp),d0 ; grenz
          move.l    76(sp),d1 ; back%
anf2:     moveq.l   #0,d2
          move.b    #0,d3
          move.w    (a0),d2
          btst      #15,d2
          beq.s     noneg
          not.w     d2
          mulu.w    d0,d2
          divu.w    d1,d2
          not.w     d2
          move.w    d2,(a0)+
          cmp.l     a1,a0
          blt.s     anf2
          movem.l   (sp)+,d0-d7/a0-a6
          rts       
noneg:    mulu.w    d0,d2
          divu.w    d1,d2
          move.w    d2,(a0)+
          cmp.l     a1,a0
          blt.s     anf2
          movem.l   (sp)+,d0-d7/a0-a6
          rts       
