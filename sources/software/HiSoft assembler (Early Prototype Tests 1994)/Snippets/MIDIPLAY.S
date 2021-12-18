begin:    movem.l   d0-d7/a0-a6,-(sp)
	  movea.l   64(sp),a3  ; von
          move.l    68(sp),d1  ; bis
          move.l    72(sp),d3 ; loop
          move.l    76(sp),d2 ; midi
          movem.l   d0-d7/a0-a6,-(sp)
          lea.l     ptr(pc),a5
          move.l    a5,-(sp)
          move.w    #0,-(sp)
          move.w    #25,-(sp)
          trap      #14
          addq.l    #8,sp
          movem.l   (sp)+,d0-d7/a0-a6
          lea.l     $df0441,a0
          lea.l     $df04c0,a1          ; Wordmode
          move.b    #4,(a0)
          moveq.l   #8,d4               ; Anzahl der Backstep
          moveq.l   #8,d5
          moveq.l   #4,d6
anf0:     movea.l   a3,a2
anf1:     move.b    (a0),d0
          and.b     d6,d0
          beq.s     anf1
          move.b    (a2)+,d7
          bclr      d5,d7     ; Parity loeschen (Kennung fÅr Rechter Kanal)
          move.w    d7,(a1)   ; High-Byte senden
anf2:     move.b    (a0),d0
          and.b     d6,d0
          beq.s     anf2
          move.b    (a2)+,d7
          bclr      d5,d7     ; Parity loeschen (Kennung fÅr Rechter Kanal)
          move.w    d7,(a1)   ; Low-Byte senden
anf3:     move.b    (a0),d0
          and.b     d6,d0
          beq.s     anf3
          move.b    (a2)+,d7
          bset      d5,d7     ; Parity einfÅgen (Kennung fÅr Linker Kanal)
          move.w    d7,(a1)   ; High-Byte senden
anf4:     move.b    (a0),d0
          and.b     d6,d0
          beq.s     anf4
          move.b    (a2)+,d7
          bset      d5,d7     ; Parity einfÅgen (Kennung fÅr Linker Kanal)
          move.w    d7,(a1)   ; Low-Byte senden
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
midi3b:   move.l    #0,(a5)     ; Datenwort lîschen
          bra.s     nomidi
midi4:    cmp.b     1(a5),d2  ; Noten-DATA schon gewesen ?
          beq.s     midi3     ; dann ist es nicht Note sondern Velocity
          move.b    d0,1(a5)  ; Notenwert schreiben
          bra.s     nomidi
midi5:    cmp.b     1(a5),d2  ; NOTE OFF und Note OK ?        
          bne.s     midi3b    ; wenn nein, Datenwort lîschen
          bra.s     weg2      ; Abbruch, da NOTE OFF ! 
midi6:    cmp.b     1(a5),d2  ; NOTE ON und Note OK ?        
          bne.s     midi3b    ; wenn nein, Datenwort lîschen
          cmp.b     #0,2(a5)  ; Velocity ist Null ?
          bne.s     midi3b    ; wenn nein, Datenwort lîschen
          bra.s     weg2      ; Abbruch, da NOTE ON und Velo=Null ! 
nomidi:   movem.l   (sp)+,d1-a6
          suba.l    d4,a2
          cmpa.l    d1,a2
          bne       anf1
          tst.l     d3
          beq.s     weg
          bra       anf0
weg2:     movem.l   (sp)+,d1-a6
weg:      lea.l     ptr2(pc),a5
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

