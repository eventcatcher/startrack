;****************************************************************************
;       BALMIXER.ASM    Rev.1.0
;
; for STARTRACK DSP56002-66
; 
; Mischer mit Volumecontrol und Balance fr 8 Falconkompatible Kan„le
;
; mischt zus„tzlich die 8 Kan„le zu 2 zusammen und gibt sie in den 
; letzten beiden Slots aus
;
; Stereo-Bypass, empf„ngt 8 Kan„le im Network-Mode,asynchron, external Clk 
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
        move    #$40,r6                 ; initialize stack pointer
	move    #-1,m6                  ; linear addressing

codec_init
	movep   #$0000,x:PCC    ; turn off ssi port 
	movep   #$0,x:PCDDR     ; setup pc0-pc8 as inputs
	movep   #$4700,x:CRA    ; 16bits,8 word/frame
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
        nop
        nop
        jmp     yreadhx
noreadhx
        movep   #5,x:HCR        ; host interrupt enable
	andi    #$FC,mr         ; enable interrupts

main    move    r5,a
	and     x1,a    r3,y0
	cmp     y0,a
	jeq     main
	move    #level,r2
        move    #peaks,r1
        move    #bypass,r7
        move    x:(r3)+,y1                  ; Daten erster Kanal holen
        move    x:(r1)+,x0                  ; ersten peakwert holen
        jclr    #0,x:(r7),nobyp1           ; bypass channel 1 ?
        move    y1,a
        jmp     byp1
nobyp1  move    x:(r2)+,y0                  ; level ersten Kanal holen
        mpy     y0,y1,a                     ; level1 anpassen              
        asl     a
byp1    cmp     x0,a            x:(r2)+,y0  ; level2 holen
        jle     lower1
        move    a,x:-(r1)
        move    x:(r1)+,x0
lower1  move    x:(r3)+,y1                  ; Daten zweiter Kanal holen
        jclr    #0,x:(r7)+,nobyp2           ; bypass channel 2 ?
        move    y1,b
        jmp     byp2
nobyp2  mpy     y0,y1,b                     ; level2 anpassen              
        asl     b
byp2    move    x:(r1)+,x0                  ; zweiten peakwert holen
        cmp     x0,b            x:(r2)+,y0  ; level3 holen
        jle     lower2
        move    b,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower2  move    x:(r3)+,y1                  ; Daten dritter Kanal holen
        move    a,x:(r6)+                   ; ergebnis lev1 retten
        jclr    #0,x:(r7),nobyp3           ; bypass channel 3 ?
        move    y1,a
        jmp     byp3
nobyp3  mpy     y0,y1,a                     ; level3 anpassen              
        asl     a
byp3    move    x:(r1)+,x0                  ; dritten peakwert holen
        cmp     x0,a            x:(r2)+,y0  ; level4 holen
        jle     lower3
        move    a,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower3  move    x:-(r6),x0
        add     x0,a
        rnd     a
	move    x:(r3)+,y1                  ; Daten vierter Kanal holen
        move    x:(r1)+,x0                  ; vierten peakwert holen
        move    b,x:(r6)+                   ; ergebnis lev2 retten
        jclr    #0,x:(r7)+,nobyp4           ; bypass channel 4 ?
        move    y1,b
        jmp     byp4
nobyp4  mpy     y0,y1,b                     ; level4 anpassen              
        asl     b
byp4    cmp     x0,b            x:(r2)+,y0  ; level5 holen
        jle     lower4
        move    b,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower4  move    x:-(r6),x0
        add     x0,b                        ; geretteten lev2 zu lev4 add
        rnd     b                           ; ergebnis runden
	move    x:(r3)+,y1                  ; Daten fnfter Kanal holen
        move    x:(r1)+,x0                  ; fnften peakwert holen
        move    a,x:(r6)+                   ; ergebnis lev1+3 retten
        jclr    #0,x:(r7),nobyp5           ; bypass channel 5 ?
        move    y1,a
        jmp     byp5
nobyp5  mpy     y0,y1,a                     ; level5 anpassen              
        asl     a
byp5    cmp     x0,a            x:(r2)+,y0  ; level6 holen
        jle     lower5
        move    a,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower5  move    x:-(r6),x0
        add     x0,a
        rnd     a
	move    x:(r3)+,y1                  ; Daten sechter Kanal holen
        move    x:(r1)+,x0                  ; sechsten peakwert holen
        move    b,x:(r6)+                   ; ergebnis lev2+4 retten
        jclr    #0,x:(r7)+,nobyp6           ; bypass channel 6 ?
        move    y1,b
        jmp     byp6
nobyp6  mpy     y0,y1,b                     ; level6 anpassen              
        asl     b
byp6    cmp     x0,b            x:(r2)+,y0  ; level7 holen
        jle     lower6
        move    b,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower6  move    x:-(r6),x0
        add     x0,b                        ; geretteten lev2+4 zu lev6 add
        rnd     b                           ; ergebnis runden
	move    x:(r3)+,y1                  ; Daten siebter Kanal holen
        move    x:(r1)+,x0                  ; siebten peakwert holen
        move    a,x:(r6)+                   ; ergebnis lev1+3+5 retten
        jclr    #0,x:(r7),nobyp7           ; bypass channel 7 ?
        move    y1,a
        jmp     byp7
nobyp7  mpy     y0,y1,a                     ; level7 anpassen              
        asl     a
byp7    cmp     x0,a            x:(r2)+,y0  ; level8 holen
        jle     lower7
        move    a,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower7  move    x:-(r6),x0
        add     x0,a
        rnd     a
        move    x:(r3)+,y1                  ; Daten achter Kanal holen
        move    x:(r1)+,x0                  ; achten peakwert holen
        move    b,x:(r6)+                   ; ergebnis lev2+4+6 retten
        jclr    #0,x:(r7)+,nobyp8           ; bypass channel 8 ?
        move    y1,b
        jmp     byp8
nobyp8  mpy     y0,y1,b                     ; level8 anpassen                 
        asl     b
byp8    cmp     x0,b            x:(r2)+,y0  ; masterlevel1 holen
        jle     lower8
        move    b,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower8  move    x:-(r6),x0
        add     x0,b                        ; geretteten lev2+4+6 zu lev8 add
        rnd     b                           ; ergebnis runden
        move    a,y1
        move    x:(r1)+,x0                  ; master1-peakwert holen
        jset    #0,x:(r7),bypm1             ; bypass masterchannel ?
        mpyr    y0,y1,a                     ; masterlev1 anpassen                  
        asl     a
bypm1   cmp     x0,a            x:(r2)+,y0  ; masterlevel2 holen
        jle     lowm1
        move    a,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lowm1   move    b,y1
        move    x:(r1)+,x0                  ; master2-peakwert holen
        jset    #0,x:(r7),bypm2             ; bypass masterchannel ?
        mpyr    y0,y1,b                     ; masterlev2 anpassen
        asl     b
bypm2   cmp     x0,b
        jle     lowm2
        move    b,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lowm2   move    r3,x:(r6)+
        move    #0,y1
        do      #8,cls_blk
        move    y1,x:-(r3)                  ; Frameout l”schen
cls_blk move    r3,y0
        move    a,y1
        move    #routes+8,r1
        nop
        nop
        move    x:(r1)+,a
        nop
        nop
        add     y0,a
        nop
        nop
        move    a,r3
        nop
        nop
        move    y1,x:(r3)                    ; mix 1+3+5+7 in Slot 5 speichern
        move    x:(r1),a
        nop
        nop
        add     y0,a
        nop
        nop
        move    a,r3
        nop
        nop
        move    b,x:(r3)                    ; mix 2+4+6+8 in Slot 6 speichern
        move    x:-(r6),r3
dum_blk jmp     main

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
        nop
        nop
        move    x:HRX,a
        nop
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
        nop
        nop
        move    #receive,r0
        nop
        nop
        move    x:(r0)+,b              ; level-number (field 0)
        nop
        nop
        move    x:(r0),x0              ; level (field 1)
        move    #level,a
        nop
        nop
        add     b,a
        nop
        nop
        move    a,r0
        nop
        nop
        move    x0,x:(r0)
        nop
        nop
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
        nop
        nop
        move    #receive,r0
        nop
        nop
        move    x:(r0)+,b              ; level-number (field 0)
        nop
        nop
        move    x:(r0),x0              ; level (field 1)
        move    #routes,a
        nop
        nop
        add     b,a
        nop
        nop
        move    a,r0
        nop
        nop
        move    x0,x:(r0)
        nop
        nop
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

receive 
	end
