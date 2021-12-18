          movem.l   d0-d7/a0-a6,-(sp)
	  movea.l   64(sp),a3  ; adr
          movea.l   68(sp),a6  ; fname
          move.l    72(sp),d2 ; sectors
          move.l    76(sp),d5 ; len
          move.l    80(sp),d7 ; handle
          move.l    84(sp),a5 ; subber
          move.l    88(sp),a4 ; Returnwert
          lea.l     $df0441,a0          ; Flagstatus
          lea.l     $df04c0,a1          ; SDATA Word-Read (wegen PARITY)
          move.l    a3,d1     ; MEManf
          moveq.l   #0,d6
          moveq.l   #4,d4
          moveq.l   #8,d3
anf:      addq.l    #1,d6
          movea.l   a3,a2
          add.l     d5,a2     ; auf MEMende setzen
          movem.l   d0-d7/a0-a5,-(sp)
          move.w    #1,-(sp)  ; Fseek
          move.w    d7,-(sp)
          move.l    d5,d0
          add.l     d0,d0
          neg.l     d0
          move.l    d0,-(sp)
          move.w    #66,-(sp)
          trap      #1
          lea.l     $a(sp),sp
          move.l    a3,-(sp)  ; Fread
          move.l    d5,-(sp)
          move.w    d7,-(sp)
          move.w    #63,-(sp)
          trap      #1
          lea.l     $c(sp),sp
          movem.l   (sp)+,d0-d7/a0-a5
          move.b    (a0),d0   ; FIFO halbleer ?
          andi.b    #8,d0
          beq.s     anf2
          move.l    d1,-(sp)
          move.w    #$3ff,d0     ; ...dann FIFO halb-fuellen (FIFO-LEN/2/4-1)!
copy:     suba.l    #4,a2
          move.b    (a2)+,d1
          bclr      d3,d1     ; Rechter Kanal (Bit 8 geloescht)
          move.w    d1,(a1)   ; High-Byte senden
          move.b    (a2)+,d1
          bclr      d3,d1     ; Rechter Kanal (Bit 8 geloescht)
          move.w    d1,(a1)   ; Low-Byte senden
          move.b    (a2)+,d1
          bset      d3,d1     ; Linker Kanal (Bit 8 gesetzt)
          move.w    d1,(a1)   ; High-Byte senden
          move.b    (a2)+,d1
          bset      d3,d1     ; Linker Kanal (Bit 8 gesetzt)
          move.w    d1,(a1)   ; Low-Byte senden
          suba.l    #4,a2
          dbra      d0,copy
          move.l    (sp)+,d1
anf2:     suba.l    #4,a2
anf2b:    move.b    (a0),d0
          and.b     d4,d0
          beq.s     anf2b
          move.b    (a2)+,d0
          bclr      d3,d0     ; Rechter Kanal (Bit 8 geloescht)
          move.w    d0,(a1)   ; High-Byte senden
anf3:     move.b    (a0),d0
          and.b     d4,d0
          beq.s     anf3
          move.b    (a2)+,d0
          bclr      d3,d0     ; Rechter Kanal (Bit 8 geloescht)
          move.w    d0,(a1)   ; Low-Byte senden
anf4:     move.b    (a0),d0
          and.b     d4,d0
          beq.s     anf4
          move.b    (a2)+,d0
          bset      d3,d0     ; Linker Kanal (Bit 8 gesetzt)
          move.w    d0,(a1)   ; High-Byte senden
anf5:     move.b    (a0),d0
          and.b     d4,d0
          beq.s     anf5
          move.b    (a2)+,d0
          bset      d3,d0     ; Linker Kanal (Bit 8 gesetzt)
          move.w    d0,(a1)   ; Low-Byte senden
          suba.l    #4,a2
          movem.l   d1-d7/a0-a6,-(sp)
          move.w    #2,-(sp)
          move.w    #1,-(sp)
          trap      #13
          addq.l    #4,sp
          movem.l   (sp)+,d1-d7/a0-a6
          cmp.w     #0,d0
          bne.s     weg
          sub.l     a5,a2
          cmpa.l    d1,a2
          bne.s     anf2
          cmp.l     d2,d6
          bne       anf
weg:      move.l    d6,(a4)
          movem.l   (sp)+,d0-d7/a0-a6
          rts
          END 
