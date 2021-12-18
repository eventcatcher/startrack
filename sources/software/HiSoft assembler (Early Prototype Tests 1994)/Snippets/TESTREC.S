	  lea.l     $200000,a3  ; adr
          lea.l     fname,a6  ; fname
          move.l    #12920,d5 ; sectors
          move.l    #$2000,d4 ; len
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
          lea.l     rett(pc),a5
          move.l    32(a0),2(a5)
          lea.l     neuikbd(pc),a5
          move.l    a5,32(a0)
          movem.l   (sp)+,d0-d7/a0-a6
          movem.l   d0-d6/a0-a6,-(sp)
          move.w    #0,-(sp)  ; Fcreate
          move.l    a6,-(sp)
          move.w    #60,-(sp)
          trap      #1
          addq.l    #8,sp
          move.w    d0,d7
          movem.l   (sp)+,d0-d6/a0-a6
          lea.l     $df0441,a0          ; Flagstatus
          lea.l     $df04c0,a1          ; SDATA Word-Read (wegen PARITY)
          lea.l     merk(pc),a4
          move.l    a3,d1         ; MEMende
          add.l     d4,d1
          moveq.l   #1,d2
          moveq.l   #8,d3
          move.b    #2,(a0)   ; REC-FIFO lîschen, SWDIGOUT=0
          move.b    #0,(a0)
          moveq.l   #0,d6
anf:      addq.l    #1,d6
anf1:     movea.l   a3,a2
ctrl1:    move.b    (a0),d0   ; Daten gÅltig ?
          and.b     d2,d0
          beq.s     ctrl1
          move.w    (a1),d0   ; High-Byte,Rechter Kanal (Bit 8 geloescht ?)...
          btst      d3,d0
          bne.s     ctrl1      ; fehlerhafte Daten ?
          move.b    d0,(a2)+
ctrl2:    move.b    (a0),d0   ; Daten gÅltig ?
          and.b     d2,d0
          beq.s     ctrl2
          move.w    (a1),d0   ; Low-Byte,Rechter Kanal (Bit 8 geloescht ?)...
          btst      d3,d0
          bne.s     ctrl2      ; fehlerhafte Daten ?
          move.b    d0,(a2)+
ctrl3:    move.b    (a0),d0   ; Daten gÅltig ?
          and.b     d2,d0
          beq.s     ctrl3
          move.w    (a1),d0   ; High-Byte,Linker Kanal (Bit 8 gesetzt ?)...
          btst      d3,d0
          beq.s     ctrl3      ; fehlerhafte Daten ?
          move.b    d0,(a2)+
ctrl4:    move.b    (a0),d0   ; Daten gÅltig ?
          and.b     d2,d0
          beq.s     ctrl4
          move.w    (a1),d0   ; Low-Byte,Linker Kanal (Bit 8 gesetzt ?)...
          btst      d3,d0
          beq.s     ctrl4      ; fehlerhafte Daten ?
          move.b    d0,(a2)+
          cmpa.l    d1,a2
          bne.s     ctrl1
          movem.l   d1-d7/a0-a4,-(sp)
          move.l    a3,-(sp)  ; Fwrite
          move.l    d4,-(sp)
          move.w    d7,-(sp)
          move.w    #64,-(sp)
          trap      #1
          lea.l     $c(sp),sp
          movem.l   (sp)+,d1-d7/a0-a4
          bmi.s     weg
          cmp.l     d0,d4
          bne.s     weg
          move.w    (a4),d0
          bne.s     weg

          move.b    (a0),d0   ; Daten gÅltig ?
          andi.b    #2,d0
          bne.s     nocopy
          movea.l   a3,a2
          addq.l    #1,d6
copy:     move.w    #$0fff,d0
copy2:    move.b    1(a1),(a2)+   ; High-Byte,Rechter Kanal (Bit 8 geloescht ?)...
          dbra      d0,copy2
          bra.s     ctrl1

nocopy:   cmp.l     d5,d6
          bne.s     anf
weg:      move.w    d7,-(sp)  ; Fclose
          move.w    #62,-(sp)
          trap      #1
          addq.l    #4,sp
          lea.l     ptr2(pc),a5
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

          clr.w     -(sp)
          trap      #1
neuikbd:  move.w    #1,merk
rett:     jmp       rett
ptr:      DC.b $12
ptr2:     DC.b $8
merk:     DC.w 0
fname:    dc.b "H:\CAMEO.SMP",0
          end

