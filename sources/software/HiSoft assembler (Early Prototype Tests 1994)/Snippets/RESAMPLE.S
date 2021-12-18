          movem.l   d0-d7/a0-a6,-(sp)
          movea.l   64(sp),a0 ; sourceanf
          movea.l   68(sp),a1 ; sourceende
          movea.l   72(sp),a2 ; destanf
          movea.l   76(sp),a3 ; destende
          move.l    80(sp),d3 ; source-sample-rate (320,441,480)
          move.l    84(sp),d4 ; dest-sample-rate (320,441,480)
          move.l    88(sp),a4 ; destende-RETURN-Wert
          move.l    d3,d5
          sub.l     d4,d5
          moveq.l   #0,d1
          move.l    d3,d2
          divu      d4,d2
          cmpi.l    #1,d2
          beq.s     abzanf
          andi.l    #$ffff,d2
          cmpi.w    #0,d2
          beq.s     dazuanf
          cmpi.w    #2,d2
          blt.s     abzanf2
abzanf:   move.l    (a0),(a2)+
          add.l     d3,d1
          move.l    d1,d2
          divu      d4,d2
          andi.l    #$ffff,d2
          move.l    d2,d7
          mulu      #4,d7
          mulu      d4,d2
          sub.l     d2,d1
          adda.l    d7,a0
          cmpa.l    a1,a0
          blt.s     abzanf
          bra.s     ende
abzanf2:  move.l    d3,d5
          sub.l     d4,d5
abzanf3:  move.l    (a0)+,d0
          add.l     d5,d1
          move.l    d1,d2
          sub.l     d3,d2
          bmi.s     noabz2
          move.l    d2,d1
          bra.s     abztest2
noabz2:   move.l    d0,(a2)+
abztest2: cmpa.l    a1,a0
          blt.s     abzanf3
          bra.s     ende
dazuanf:  move.l    d4,d2
          divu      d3,d2
          cmpi.w    #2,d2
          bge.s     dazuanf4
          move.l    d4,d5
          sub.l     d3,d5
dazuanf2: move.l    (a0)+,d0
          add.l     d5,d1
          move.l    d1,d2
          sub.l     d3,d2
          bmi.s     dazuanf3
          move.l    d2,d1
          move.l    d0,(a2)+
dazuanf3: move.l    d0,(a2)+
          cmpa.l    a3,a2
          bge.s     ende
          cmpa.l    a1,a0
          blt.s     dazuanf2
          bra.s     ende
dazuanf4: move.l    (a0)+,d0
          add.l     d4,d1
          move.l    d1,d2
          divu      d3,d2
          andi.l    #$ffff,d2
          move.l    d2,d7
          mulu      d3,d2
          sub.l     d2,d1
          subq.l    #1,d7
dazuanf5: move.l    d0,(a2)+
          cmp.l     a3,a2
          bge.s     ende
          dbra      d7,dazuanf5
          cmpa.l    a1,a0
          blt.s     dazuanf4
ende:     move.l    a2,(a4)
          movem.l   (sp)+,d0-d7/a0-a6
          rts       
