anf:      movem.l   d0-d7/a0-a6,-(sp)
          movea.l   64(sp),a0 ; anf
          movea.l   68(sp),a1 ; ende
          movea.l   72(sp),a2 ; Returnwert
          moveq.l   #0,d0
anf2:     move.w    (a0)+,d1
          btst      #15,d1
          beq.s     noneg
          not.w     d1
noneg:    cmp.w     d0,d1
          blt.s     noadd
          move.w    d1,d0
noadd:    cmp.l     a1,a0
          blt.s     anf2
          move.l    d0,(a2)
weg:      movem.l   (sp)+,d0-d7/a0-a6
          rts       
