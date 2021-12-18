          movem.l   d0-d7/a0-a6,-(sp)
	  movea.l   64(sp),a3  ; adr
          movea.l   68(sp),a6  ; fname
          move.l    72(sp),a4 ; sectors
          move.l    76(sp),d5 ; len
          move.l    80(sp),d7 ; handle
          move.l    84(sp),a5 ; adder
          move.l    88(sp),a0 ; Returnwert
          move.l    92(sp),d2 ; midi
          move.l    a0,-(sp)
          movem.l   d0-d7/a0-a6,-(sp)
          lea.l     ptr(pc),a5
          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp
          movem.l   (sp)+,d0-d7/a0-a6
          lea.l     $df0441,a0          ; Flagstatus
          lea.l     $df04c0,a1          ; SDATA Word-Read (wegen PARITY)
          move.l    a3,d1     ; MEMende
          add.l     d5,d1
          moveq.l   #0,d6
          moveq.l   #4,d4
          moveq.l   #8,d3
anf:      addq.l    #1,d6
          movea.l   a3,a2
          movem.l   d0-d7/a0-a5,-(sp)
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
copy:     move.b    (a2)+,d1
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
          dbra      d0,copy
          move.l    (sp)+,d1
anf2:     move.b    (a0),d0
          and.b     d4,d0
          beq.s     anf2
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
          movem.l   d1-a6,-(sp)
          move.w    #3,-(sp)  ; MIDI
          move.w    #1,-(sp)  ; Bconstat
          trap      #13
          addq.l    #4,sp
          cmp.w     #0,d0
          beq.s     nomidi
          move.w    #3,-(sp)
          move.w    #2,-(sp)  ; Bconin
          trap      #13
          addq.l    #4,sp
          movem.l   (sp)+,d1-a6
          movem.l   d1-a6,-(sp)
          lea.l     midiw(pc),a5
          btst      #7,d0
          beq.s     midi2     ; Daten oder Befehl ?
          asr.w     #8,d2     ; Channel im oberen Byte des Wortes
          sub.b     d2,d0     ; Channel vom Befehl abziehen
          move.b    d0,(a5)   ; Befehl schreiben
          bra.s     nomidi
midi2:    cmp.b     d2,d0       ; Noten-DATA ?
          beq.s     midi4
          cmp.b     1(a5),d2    ; Noten-data schon gewesen und korrekt ?
          bne.s     nomidi
midi3:    move.b    d0,2(a5)    ; Velocitywert schreiben
          cmp.b     #$80,(a5)   ; NOTE OFF ? 
          beq.s     midi5
          cmp.b     #$90,(a5)   ; NOTE ON ?
          beq.s     midi6
midi3b:   move.l    #0,(a5)     ; Datenwort l”schen
          bra.s     nomidi
midi4:    cmp.b     1(a5),d2  ; Noten-DATA schon gewesen ?
          beq.s     midi3     ; dann ist es nicht Note sondern Velocity
          move.b    d0,1(a5)  ; Notenwert schreiben
          bra.s     nomidi
midi5:    cmp.b     1(a5),d2  ; NOTE OFF und Note OK ?        
          bne.s     midi3b    ; wenn nein, Datenwort l”schen
          bra.s     weg2      ; Abbruch, da NOTE OFF ! 
midi6:    cmp.b     1(a5),d2  ; NOTE ON und Note OK ?        
          bne.s     midi3b    ; wenn nein, Datenwort l”schen
          cmp.b     #0,2(a5)  ; Velocity ist Null ?
          bne.s     midi3b    ; wenn nein, Datenwort l”schen
          bra.s     weg2      ; Abbruch, da NOTE ON und Velo=Null ! 
nomidi:   movem.l   (sp)+,d1-a6
          add.l     a5,a2
          cmpa.l    d1,a2
          bne       anf2
          cmp.l     a4,d6
          bne       anf
          bra       weg
weg2:     movem.l   (sp)+,d1-a6
weg:      move.l    (sp)+,a0
          move.l    d6,(a0)
          lea.l     ptr2(pc),a5
          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp
          movem.l   (sp)+,d0-d7/a0-a6
          rts
ptr:      dc.b $12
ptr2:     Dc.b $8
midiw:    dc.l 0
          END 
