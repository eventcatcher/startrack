begin:    movem.l   d0-d7/a0-a6,-(sp)
          move.l    64(sp),d0 ; adr
          lea.l     $df04c0,a1          
loop:     move.w    (a1),d1 
          dbra      d0,loop     
          movem.l   (sp)+,d0-d7/a0-a6
          rts

