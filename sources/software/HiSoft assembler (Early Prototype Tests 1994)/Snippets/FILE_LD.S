anf:      movem.l   d0-d7/a0-a6,-(sp)
	  movea.l   64(sp),a0  ; von
          movea.l   68(sp),a1  ; nach
          move.l    72(sp),d0 ; Len
	  add.l     a0,d0
anf2:	  move.b    (a0)+,(a1)+
          cmp.l     d0,a0
          bne       anf2
          movem.l   (sp)+,d0-d7/a0-a6
          rts       
