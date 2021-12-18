;****************************************************************************
;       PANMIXER.ASM    Rev.1.0
;
; for STARTRACK DSP56002-66
; 
; Mischer mit Volumecontrol,Pan & Route fr 8 x 24Bit-Kan„le
;
; mischt zus„tzlich die 8 Kan„le zu 2 zusammen und gibt sie auf den 
; Master-Route-Kan„len aus
;
; Stereo-Bypass, empf„ngt 8 x 24bit-Kan„le im Network-Mode,asynchron, external Clk 
; von der SSI und sendet sie per SSI
; SC2=Framesync Transmitter, SCLK = Clock Transmitter
; SC1=Framesync Receiver   , SC0 = CLock Receiver
;
;******************************************************************************

;---DSP56002 on-chip peripheral addresses
IPR             equ     $FFFF   ;Interrupt Priority Register
BCR             equ     $FFFE   ;Bus Control Register
PLL             equ     $FFFD   ;PLL Control Register
SSIDR           equ     $FFEF   ;SSI Data Register
SSISR           equ     $FFEE   ;SSI Status Register
CRB             equ     $FFED   ;SSI Control Register B
CRA             equ     $FFEC   ;SSI Control Register A
PCD             equ     $FFE5   ;Port C Data Register
PCDDR           equ     $FFE3   ;Port C Data Direction Register
PCC             equ     $FFE1   ;Port C Control Register
PBC             equ     $FFE0   ;Port B Control Register
HRX             equ     $FFEB   ;Host Data
HCR             equ     $FFE8   ;Host interrupt enable
HSR             equ     $FFE9   ;Host Status Register


START   equ     $100

	org     p:0                     ;RESET Vector
	jmp     START
 
	org     p:$000C
	jsr     ssi_rx_isr              ;SSI RX
	jsr     ssi_rx_isr              ;SSI RX w/Exception
	jsr     ssi_tx_isr              ;SSI TX
	jsr     ssi_tx_isr              ;SSI TX w/Exception

	org     p:$0020
	jsr     host_rx_isr              ;SSI RX w/Exception
	jsr     host_tx_isr              ;SSI TX
        jsr     clr_count                ;Host Kommando default
        jsr     set_level                ;Host Kommando 
        jsr     rd_peaks                 ;Host Kommando 
        org     p:$0040
        jsr     set_route                ;Host Kommando
        jsr     set_byp                  ;Host Kommando

;******************************************************************************

;---------------------------------------------------------------------------
;
;      DSP/codec initialization
;
;---------------------------------------------------------------------------
	org     p:START

        movep   #$0000,x:BCR            ; zero wait states in all ext. memory
        ori     #3,mr                   ; disable interrupts
	movep   #1,x:PBC                ; port b = host
        move    #2,omr
        movec   #0,sp                   ; clear hardware stack pointer
        move    #$400,r6                ; initialize stack pointer
	move    #-1,m6                  ; linear addressing

codec_init
	movep   #$0000,x:PCC    ; turn off ssi port 
	movep   #$0,x:PCDDR     ; setup pc0-pc8 as inputs
        movep   #$6700,x:CRA    ; 24bits,8 word/frame
	movep   #$F800,x:CRB    ; rcv,xmt & int ena,netwk,syn,sclk==inp,msb 1st
	movep   #$3800,x:IPR    ; set interrupt priority level
	movep   #$FFE8,x:PCC    ; Turn on ssi port
	move    #$2800,r5       ; Memorypointer Receive
	move    #$FFF,m5        ; Modulo Receive 4KB = $2000 - $2FFF
	move    #$2000,r4       ; Memorypointer Transmit
	move    #$FFF,m4        ; Modulo Transmit 4KB = $2000 - $2FFF
	move    #$2FF8,x1       ; Rundungswert fr Speicher-Synchronisation
	move    r5,r3
	move    #$FFF,m3        ; Modulo mixpointer 4KB = $2000 - $2FFF
        move    #$FFF,m0
        move    #$FFFF,m7
        move    #receive,r0     ; receive start

yreadhx jclr    #0,x:HSR,noreadhx      ; HX-Receive full ?
        movep   x:HRX,a                ; Read out received data to buffer.
        jmp     yreadhx
noreadhx
        movep   #5,x:HCR        ; host interrupt enable
	andi    #$FC,mr         ; enable interrupts

main    move    r5,a
	and     x1,a    r3,y0
	cmp     y0,a
	jeq     main
        clr     a       #level,r2           ; liste lautst„rke
        clr     b       #peaks,r1           ; liste peakmeter-maximalwerte
        move    #bypass,r7                  ; liste bypass
        move    x:(r1)+,x0                  ; peakwert1 holen
        move    x:(r2)+,y0                  ; lpan1 ersten Kanal holen
        jclr    #0,x:(r7)+,nobyp1           ; bypass channel 1/2 ?
        jsr     rbypass
        jmp     gobyp1
nobyp1  move    x:(r3),y1                   ; Daten Kanal 1 holen
        mpy     y0,y1,a         x:(r2)+,y0  ; lpan1 anpassen,rpan1 holen
        asl     a
        cmp     x0,a
        jle     lower1l
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower1l move    x:(r3)+,y1                  ; Daten Kanal1 holen,goto Kanal2
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan1 anpassen,lpan2 holen
        asl     b               x:(r1),x0   ; peakwert2 holen
        cmp     x0,b
        jle     lower1r
        move    b,x:(r1)                    ; peakwert2 speichern
lower1r move    x:-(r1),x0                  ; dummy goto peakwert1
        move    x:(r3),y1                   ; Daten Kanal2 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; lpan2 anpassen,rpan2 holen
        asl     a               x:(r1)+,x0  ; peakwert1 holen
        cmp     x0,a
        jle     lower2l
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower2l move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan2+master1,Daten Kanal2 holen
        rnd     a               x:(r1)+,x0  ; ergebnis runden,peakwert2 holen
        move    b,x:(r6)+                   ; ergebnis master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan2 anpassen,lpan3 holen
        asl     b
        cmp     x0,b                        
        jle     lower2r
        move    b,x:-(r1)                   ; peakwert2 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower2r move    x:-(r6),x0                  ; master2 holen
        add     x0,b                        ; rpan2+master2
        rnd     b               x:(r1)+,x0  ; ergebnis runden,peakwert3 holen
gobyp1  jclr    #0,x:(r7)+,nobyp2           ; bypass channel 3/4 ?
        jsr     rbypass
        jmp     gobyp2
nobyp2  move    x:(r3),y1                   ; Daten Kanal3 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; lpan3 anpassen,rpan3 holen
        asl     a
        cmp     x0,a
        jle     lower3l
        move    a,x:-(r1)                   ; peakwert3 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower3l move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan3+master1,Daten Kanal3 holen
        rnd     a               x:(r1),x0   ; ergebnis runden,peakwert4 holen
        move    b,x:(r6)+                   ; ergebnis master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan3 anpassen,lpan4 holen
        asl     b
        cmp     x0,b
        jle     lower3r
        move    b,x:(r1)                    ; peakwert4 speichern
lower3r move    x:-(r1),x0                  ; dummy goto peakwert3
        move    x:-(r6),x0                  ; master2 holen
        add     x0,b            x:(r3),y1   ; rpan3+master2,Daten Kanal4 holen
        rnd     b               x:(r1)+,x0  ; ergebnis runden,peakwert3 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; lpan4 anpassen,rpan4 holen
        asl     a
        cmp     x0,a
        jle     lower4l
        move    a,x:-(r1)                   ; peakwert3 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower4l move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan4+master1,Daten Kanal4 holen
        rnd     a               x:(r1)+,x0  ; ergebnis runden,peakwert4 holen
        move    b,x:(r6)+                   ; master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan4 anpassen,lpan5 holen
        asl     b
        cmp     x0,b
        jle     lower4r
        move    b,x:-(r1)                   ; peakwert4 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower4r move    x:-(r6),x0                  ; master2 holen
        add     x0,b                        ; rpan4+master2
        rnd     b               x:(r1)+,x0  ; ergebnis runden,peakwert5 holen
gobyp2  jclr    #0,x:(r7)+,nobyp3           ; bypass channel 5/6 ?
        jsr     rbypass
        jmp     gobyp3
nobyp3  move    x:(r3),y1                   ; Daten Kanal5 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; lpan5 anpassen,rpan5 holen
        asl     a
        cmp     x0,a
        jle     lower5l
        move    a,x:-(r1)                   ; peakwert5 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower5l move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan5+master1,Daten Kanal5 holen
        rnd     a               x:(r1),x0   ; ergebnis runden,peakwert6 holen
        move    b,x:(r6)+                   ; ergebnis master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan5 anpassen,lpan6 holen
        asl     b
        cmp     x0,b
        jle     lower5r
        move    b,x:(r1)                    ; peakwert6 speichern
lower5r move    x:-(r1),x0                  ; dummy goto peakwert5
        move    x:-(r6),x0                  ; master2 holen
        add     x0,b            x:(r3),y1   ; rpan5+master2,Daten Kanal6 holen
        rnd     b               x:(r1)+,x0  ; ergebnis runden,peakwert5 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; lpan6 anpassen,rpan6 holen
        asl     a
        cmp     x0,a
        jle     lower6l
        move    a,x:-(r1)                   ; peakwert5 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower6l move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan6+master1,Daten Kanal6 holen
        rnd     a               x:(r1)+,x0  ; ergebnis runden,peakwert6 holen
        move    b,x:(r6)+                   ; master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan6 anpassen,lpan7 holen
        asl     b
        cmp     x0,b
        jle     lower6r
        move    b,x:-(r1)                   ; peakwert6 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower6r move    x:-(r6),x0                  ; master2 holen
        add     x0,b                        ; rpan6+master2
        rnd     b               x:(r1)+,x0  ; ergebnis runden,peakwert7 holen
gobyp3  jclr    #0,x:(r7)+,nobyp4           ; bypass channel 7/8 ?
        jsr     rbypass
        jmp     gobyp4
nobyp4  move    x:(r3),y1                   ; Daten Kanal7 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; lpan7 anpassen,rpan7 holen
        asl     a
        cmp     x0,a
        jle     lower7l
        move    a,x:-(r1)                   ; peakwert7 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower7l move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan7+master1,Daten Kanal7 holen
        rnd     a               x:(r1),x0   ; ergebnis runden,peakwert8 holen
        move    b,x:(r6)+                   ; ergebnis master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan7 anpassen,lpan8 holen
        asl     b
        cmp     x0,b
        jle     lower7r
        move    b,x:(r1)                    ; peakwert8 speichern
lower7r move    x:-(r1),x0                  ; dummy goto peakwert7
        move    x:-(r6),x0                  ; master2 holen
        add     x0,b            x:(r3),y1   ; rpan7+master2,Daten Kanal8 holen
        rnd     b               x:(r1)+,x0  ; ergebnis runden,peakwert7 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; lpan8 anpassen,rpan8 holen
        asl     a
        cmp     x0,a
        jle     lower8l
        move    a,x:-(r1)                   ; peakwert7 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower8l move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan8+master1,Daten Kanal8 holen
        rnd     a               x:(r1)+,x0  ; ergebnis runden,peakwert8 holen
        move    b,x:(r6)+                   ; master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan8 anpassen,masterlev1 holen
        asl     b
        cmp     x0,b
        jle     lower8r
        move    b,x:-(r1)                   ; peakwert8 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower8r move    x:-(r6),x0                  ; master2 holen
        add     x0,b                        ; rpan8+master2
        rnd     b               x:(r1)+,x0  ; ergebnis runden,hole masterpeak1
gobyp4  jset    #0,x:(r7),nobypm1            ; bypass masterchannels ?
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; masterlev1 anpassen,masterlev2 holen
        asl     a               b,y1
nobypm1 cmp     x0,a
        jle     lowm1
        move    a,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lowm1   move    x:(r1)+,x0                  ; master2-peakwert holen
        jclr    #0,x:(r7),nobypm2           ; bypass masterchannels ?
        move    r3,x:(r6)+
        jmp     nobypm3
nobypm2 mpyr    y0,y1,b         r3,x:(r6)+  ; masterlev2 anpassen
        asl     b                    
nobypm3 cmp     x0,b            #0,y1
        jle     lowm2
        move    b,x:-(r1)                   ; peakwert speichern
lowm2
        move    y1,x:-(r3)                  ; Frameout l”schen
        move    y1,x:-(r3)                  ; Frameout l”schen
        move    y1,x:-(r3)                  ; Frameout l”schen
        move    b,x:-(r3)                   ; Frameout l”schen
        move    y1,x:-(r3)                  ; Frameout l”schen
        move    y1,x:-(r3)                  ; Frameout l”schen
        move    y1,x:-(r3)                  ; Frameout l”schen
        move    a,x:-(r3)                   ; Frameout l”schen
        move    x:-(r6),r3
dum_blk jmp     main

rbypass move    x:(r2)+,y0                  ; lpan1 ersten Kanal holen
        move    x:(r2)+,y0                  ; rpan1 ersten Kanal holen
        move    x:(r2)+,y0                  ; lpan2 ersten Kanal holen
rbypa2  move    x:(r2)+,y0                  ; rpan2 ersten Kanal holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        move    x:(r3)+,a                   ; Daten Kanal1 holen,goto Kanal2
        cmp     x0,a
        jle     byp1
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
byp1    move    x:-(r6),x0                  ; master1 holen
        add     x0,a            b,x:(r6)+   ; channel+master1,erg master2 save
        move    x:(r1)+,x0                  ; ergebnis
        move    x:(r3)+,b                   ; Daten Kanal2 holen,goto Kanal3
        cmp     x0,b
        jle     byp2
        move    b,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
byp2    move    x:-(r6),x0                  ; master2 holen
        add     x0,b                        ; channel+master2
        move    x:(r1)+,x0                  ; peakwert1 holen
        rts

ssi_rx_isr
	jset    #3,x:SSISR,frame_rx      ; Frame-Erkennung
	movep   x:SSIDR,x:(r5)+          ; Read out received data to buffer
	rti
frame_rx 
	move    a,x:(r6)+              ; Save to the stack.
	move    r5,a
	and     x1,a                     ; 1.Slot->Speicher synchonisieren
	move    a,r5                   
	move    x:-(r6),a
	movep   x:SSIDR,x:(r5)+          ; Read out received data to buffer
	rti

ssi_tx_isr
	jset    #2,x:SSISR,frame_tx      ; Frame-Erkennung
	movep   x:(r4)+,x:SSIDR           ; read out buffer and transmit
	rti
frame_tx
	move    b,x:(r6)+              ; Save to the stack.
	move    r4,b
	and     x1,b                     ; 2.Slot->Speicher synchronisieren
	move    b,r4                     ; auf ersten Slot runden
        nop
	move    x:(r4)+,b                ; wir sind aber im zweiten Slot
	move    x:-(r6),b
	movep   x:(r4)+,x:SSIDR          ; read out buffer and transmit
	rti                         


host_rx_isr
        move    a,x:(r6)+               ; Save r5 to the stack.
        move    x:HRX,a
        nop
        move    a,x:(r0)+
        move    x:-(r6),a
	rti


host_tx_isr
        rti

clr_count                               ; clear counter
        move    #receive,r0             ; receive start
	rti

set_level                               ; set level
        move    a,x:(r6)+
        move    b,x:(r6)+
        move    x0,x:(r6)+
        move    #receive,r0
        move    #level,a
        move    x:(r0)+,b              ; level-number (field 0)
        move    x:(r0),x0              ; level (field 1)
        add     b,a
        nop
        move    a,r0
        nop
        move    x0,x:(r0)
        move    #receive,r0
        move    x:-(r6),x0
        move    x:-(r6),b
        move    x:-(r6),a
        rti

rd_peaks
        move    a,x:(r6)+
        move    b,x:(r6)+
        move    #peaks,a
        move    x:receive,b
        nop
        add     b,a
        nop
        move    a,r0
        nop
        move    x:(r0),a
        movep   a,x:HRX
        move    #0,a
        move    a,x:(r0)
        move    #receive,r0
        move    x:-(r6),b
        move    x:-(r6),a
        rti

set_route                               ; set route
        move    a,x:(r6)+
        move    b,x:(r6)+
        move    x0,x:(r6)+
        move    #receive,r0
        move    #routes,a
        move    x:(r0)+,b              ; level-number (field 0)
        move    x:(r0),x0              ; level (field 1)
        add     b,a
        nop
        move    a,r0
        nop
        move    x0,x:(r0)
        move    #receive,r0
        move    x:-(r6),x0
        move    x:-(r6),b
        move    x:-(r6),a
        rti

set_byp move    a,x:(r6)+
        move    b,x:(r6)+
        move    x0,x:(r6)+
        move    #receive,r0
        move    #bypass,a
        move    x:(r0)+,b              ; channel-number (field 0)
        move    x:(r0),x0              ; bypass (field 1)
        add     b,a
        nop
        move    a,r0
        nop
        move    x0,x:(r0)
        move    #receive,r0
        move    x:-(r6),x0
        move    x:-(r6),b
        move    x:-(r6),a
        rti

	org     x:$50

bypass  dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0

level   dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00

peaks   dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0

routes  dc      $0
        dc      $1
        dc      $2
        dc      $3
        dc      $4
        dc      $5
        dc      $6
        dc      $7
        dc      $0
        dc      $1

routbuf dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0

receive 


	end
