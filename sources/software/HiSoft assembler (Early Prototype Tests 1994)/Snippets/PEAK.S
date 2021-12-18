          movem.l   d0-d7/a0-a6,-(sp)
	  lea.l     wert(pc),a0
          move.l    64(sp),(a0)+ 
          move.l    68(sp),(a0)+ 
          move.l    72(sp),(a0)+ 
          move.l    76(sp),(a0)+ 
          move.l    80(sp),(a0)+ 
          move.l    84(sp),(a0)+ 
          move.l    88(sp),(a0)+ 
          move.l    92(sp),(a0)+ 
          move.l    96(sp),(a0)+ 
          move.l    100(sp),(a0)+ 
          move.l    104(sp),(a0)+ 
          move.l    108(sp),(a0)+ 
          move.l    112(sp),(a0)+ 
          move.l    116(sp),(a0)+ 
          move.l    120(sp),(a0)+ 
          move.l    124(sp),(a0)+ 
          move.l    128(sp),(a0)+ 
          move.l    132(sp),(a0)+ 
          move.l    136(sp),(a0)+ 
          move.l    140(sp),(a0)
          movem.l   d0-d7/a0-a6,-(sp)
          lea.l     ptr(pc),a5
          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp
clear:    move.w    #11,-(sp)
          trap      #1
          addq.l    #2,sp
          cmpi.l    #0,d0
          beq.s     weiter
          move.w    #1,-(sp)
          trap      #1
          addq.l    #2,sp
          bra.s     clear
weiter:   move.w    #34,-(sp)
          trap      #14
          addq.l    #2,sp
          movea.l   d0,a0
          lea.l     rett(pc),a1
          move.l    32(a0),2(a1)
          lea.l     neuikbd(pc),a1
          move.l    a1,32(a0)
          movem.l   (sp)+,d0-d7/a0-a6
	  lea.l     wert(pc),a0
	  lea.l     merk(pc),a4
          lea.l     $df0441,a6
          moveq.l   #1,d5
anf:      move.w    $df04c0,d0
          btst      #8,d0
          beq       anf
anf2:     move.b    (a6),d0   ; Daten gÅltig ?
          and.b     d5,d0
          beq       test
          move.w    $df04c0,d1
          btst      #8,d1
          bne       anf2
ctrl1:    move.b    (a6),d0   ; Daten gÅltig ?
          and.b     d5,d0
          beq       test
          move.w    $df04c0,d2
          btst      #8,d2
          bne       anf2
anf3:     move.b    (a6),d0   ; Daten gÅltig ?
          and.b     d5,d0
          beq       test
          move.w    $df04c0,d3
          btst      #8,d3
          beq       anf3
ctrl2:    move.b    (a6),d0   ; Daten gÅltig ?
          and.b     d5,d0
          beq       test
          move.w    $df04c0,d4
          btst      #8,d4
          beq       anf3
          and.w     #$ff,d1
          asl.w     #8,d1
          and.w     #$ff,d2
          add.w     d2,d1
          and.w     #$ff,d3
          asl.w     #8,d3
          and.w     #$ff,d4
          add.w     d4,d3
          btst      #15,d1
          beq.s     anf4
          not.w     d1
anf4:     btst      #15,d3
          beq.s     anf5
          not.w     d3
anf5:     mulu.w    #10,d1
          mulu.w    #10,d3
          divu.w    #32767,d1
          divu.w    #32767,d3
          moveq.l   #0,d6
          moveq.l   #0,d7
anfrs:    movea.l   0(a0,d6.w),a1
          cmp.b     d7,d1
          bgt.s     anfrs2
          move.w    #0,(a1)
          bra.s     anfrs3
anfrs2:   move.w    #1,(a1)
anfrs3:   addq.l    #4,d6
          addq.l    #1,d7
          cmp.b     #10,d7
          bne.s     anfrs
          moveq.l   #0,d7
anfls:    movea.l   0(a0,d6.w),a1
          cmp.b     d7,d3
          bgt.s     anfls2
          move.w    #0,(a1)
          bra.s     anfls3
anfls2:   move.w    #1,(a1)
anfls3:   addq.l    #4,d6
          addq.l    #1,d7
          cmp.b     #10,d7
          bne.s     anfls
          cmp.b     #10,d1
          beq.s     nixw1
          cmp.b     #10,d3
          beq.s     nixw1
          bra.s     test
nixw1:    bsr       pause
test:     move.w    (a4),d0
          bne.s     weg
          bra       anf2
weg:      lea.l     ptr2(pc),a5
          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp
          move.w    #34,-(sp)
          trap      #14
          addq.l    #2,sp
          movea.l   d0,a0
          lea.l     rett(pc),a1
          move.l    2(a1),32(a0)
          movem.l   (sp)+,d0-d7/a0-a6
          rts       

pause:    move.w    #-1,d6
pause2:   move.w    #-1,d7
pause3:   dbra      d7,pause3
          dbra      d6,pause2
          rts

neuikbd:  
          move.w    #1,merk
rett:     jmp       rett

ptr:      DC.b $12
ptr2:     DC.b $8
wert:     ds.l 20
merk:     DC.w 0

end
