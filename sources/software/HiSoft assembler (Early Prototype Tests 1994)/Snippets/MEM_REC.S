begin:    movem.l   d0-d7/a0-a6,-(sp)
	  movea.l   64(sp),a3  ; von
          move.l    68(sp),d1  ; bis
          movea.l   72(sp),a5 ; adr
          movem.l   d0-d7/a0-a6,-(sp)

          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp

clear:    
          move.w    #11,-(sp)
          trap      #1
          addq.l    #2,sp
          cmpi.l    #0,d0
          beq.s     weiter
          move.w    #1,-(sp)
          trap      #1
          addq.l    #2,sp
          bra.s     clear
weiter:   

          move.w    #34,-(sp)
          trap      #14
          addq.l    #2,sp
          movea.l   d0,a0
          lea.l     rett,a1
          move.l    32(a0),2(a1)
          lea.l     neuikbd,a1
          move.l    a1,32(a0)
          movem.l   (sp)+,d0-d7/a0-a6

          lea.l     $df0441,a0
          lea.l     $df04c0,a1          ; Word-adressiert !!

          move.b    #2,(a0)   ; REC-FIFO loeschen, SWDIGOUT=0
          move.b    #0,(a0)


          add.l     #2,a5
          move.l    a5,a4
          sub.l     #2,a5
          moveq.l   #8,d2
          moveq.l   #1,d3

anf0:     movea.l   a3,a2

ctrl1:    
          move.b    (a0),d0   ; Daten gÅltig ?
          and.b     d3,d0
          beq.s     ctrl1
          move.w    (a1),d7   ; High-Byte,Rechter Kanal (Bit 8 geloescht ?)...
          btst      d2,d7
          bne.s     anf0      ; fehlerhafte Daten ?
ctrl2:    
          move.b    (a0),d0   ; Daten gÅltig ?
          and.b     d3,d0
          beq.s     ctrl2
          move.w    (a1),d6   ; Low-Byte,Rechter Kanal (Bit 8 geloescht ?)...
          btst      d2,d6
          bne.s     anf0      ; fehlerhafte Daten ?
ctrl3:    
          move.b    (a0),d0   ; Daten gÅltig ?
          and.b     d3,d0
          beq.s     ctrl3
          move.w    (a1),d5   ; High-Byte,Linker Kanal (Bit 8 gesetzt ?)...
          btst      d2,d5
          beq.s     anf0      ; fehlerhafte Daten ?
ctrl4:    
          move.b    (a0),d0   ; Daten gÅltig ?
          and.b     d3,d0
          beq.s     ctrl4
          move.w    (a1),d4   ; Low-Byte,Linker Kanal (Bit 8 gesetzt ?)...
          btst      d2,d4
          beq.s     anf0      ; fehlerhafte Daten ?

          move.b    d7,(a2)+
          move.b    d6,(a2)+
          move.b    d5,(a2)+
          move.b    d4,(a2)+

          move.w    (a4),d0
          bne.s     weg

          cmpa.l    d1,a2
          bne.s     ctrl1
weg:      
          add.l     #1,a5
          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp

          move.w    #34,-(sp)
          trap      #14
          addq.l    #2,sp
          movea.l   d0,a0
          lea.l     rett,a1
          move.l    2(a1),32(a0)

          movem.l   (sp)+,d0-d7/a0-a6
          rts

neuikbd:  
          move.w    #1,merk
rett:     jmp       rett

ptr:      DC.b $12
ptr2:     DC.b $8
merk:     DC.w 0
          END 

