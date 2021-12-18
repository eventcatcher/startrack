;****************************************************************************
;       EXTMIXER.ASM    Rev.1.0
;
; for STARTRACK DSP56002-66
; 
; Mischer mit Volumecontrol & Route fr 8 Falconkompatible Kan„le
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
        jsr     set_route                ;Host Kommando

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
        move    #level,r2                   ; leveltabelle
        move    #level+8,r7                 ; masterlevel-tabelle
        move    #peaks,r1
        move    x:(r3),y1                   ; Daten Kanal1 holen
        move    x:(r2)+,y0                  ; level ersten Kanal holen
        move    x:(r1)+,x0                  ; peakwert1 holen,goto peakwert2
        mpyr    y0,y1,a         x:(r7),y0   ; level1 anpassen,mlevel holen
        asl     a
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; an mlevel anpassen,level2 holen
        asl     a
        move    a,x:(r3)+                   ; Kanal1 retten,goto Kanal2
        cmp     x0,a
        jle     lower1
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower1  move    x:(r3),y1                   ; Daten Kanal2 holen,goto Kanal3
        move    x:(r1)+,x0                  ; peakwert2 holen,goto peakwert3
        mpyr    y0,y1,b         x:(r7),y0   ; level2 anpassen,mlevel holen
        asl     b
        move    b,y1
        mpyr    y0,y1,b         x:(r2)+,y0  ; an mlevel anpassen,level3 holen
        asl     b
        move    b,x:(r3)+                   ; Kanal2 retten,goto Kanal3 
        cmp     x0,b
        jle     lower2
        move    b,x:-(r1)                   ; peakwert2 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower2  move    x:(r3),y1                   ; Daten Kanal3 holen
        move    x:(r1)+,x0                  ; peakwert3 holen,goto peakwert4
        mpyr    y0,y1,a         x:(r7),y0   ; level3 anpassen,mlevel holen
        asl     a
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; an mlevel anpassen,level4 holen
        asl     a
        move    a,x:(r3)+                   ; Kanal3 retten,goto Kanal4 
        cmp     x0,a
        jle     lower3
        move    a,x:-(r1)                   ; peakwert3 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower3  move    x:(r3),y1                   ; Daten Kanal4 holen
        move    x:(r1)+,x0                  ; peakwert4 holen,goto peakwert5
        mpyr    y0,y1,b         x:(r7),y0   ; level4 anpassen,mlevel holen
        asl     b
        move    b,y1
        mpyr    y0,y1,b         x:(r2)+,y0  ; an mlevel anpassen,level5 holen
        asl     b
        move    b,x:(r3)+                   ; Kanal4 retten,goto Kanal5 
        cmp     x0,b
        jle     lower4
        move    b,x:-(r1)                   ; peakwert4 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower4  move    x:(r3),y1                   ; Daten Kanal5 holen
        move    x:(r1)+,x0                  ; peakwert5 holen,goto peakwert6
        mpyr    y0,y1,a         x:(r7),y0   ; level5 anpassen,mlevel holen
        asl     a
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; an mlevel anpassen,level6 holen
        asl     a
        move    a,x:(r3)+                   ; Kanal5 retten,goto Kanal6 
        cmp     x0,a
        jle     lower5
        move    a,x:-(r1)                   ; peakwert5 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower5  move    x:(r3),y1                   ; Daten Kanal6 holen
        move    x:(r1)+,x0                  ; peakwert6 holen,goto peakwert7
        mpyr    y0,y1,b         x:(r7),y0   ; level6 anpassen,mlevel holen
        asl     b
        move    b,y1
        mpyr    y0,y1,b         x:(r2)+,y0  ; an mlevel anpassen,level7 holen
        asl     b
        move    b,x:(r3)+                   ; Kanal6 retten,goto Kanal7 
        cmp     x0,b
        jle     lower6
        move    b,x:-(r1)                   ; peakwert6 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower6  move    x:(r3),y1                   ; Daten Kanal7 holen
        move    x:(r1)+,x0                  ; peakwert7 holen,goto peakwert8
        mpyr    y0,y1,a         x:(r7),y0   ; level7 anpassen,mlevel holen
        asl     a
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; an mlevel anpassen,level8 holen
        asl     a
        move    a,x:(r3)+                   ; Kanal7 retten,goto Kanal8 
        cmp     x0,a
        jle     lower7
        move    a,x:-(r1)                   ; peakwert5 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lower7  move    x:(r3),y1                   ; Daten Kanal8 holen
        move    x:(r1),x0                   ; peakwert8 holen
        mpyr    y0,y1,b         x:(r7),y0   ; level8 anpassen,mlevel holen
        asl     b
        move    b,y1
        mpyr    y0,y1,b                     ; an mlevel anpassen
        asl     b
        move    b,x:(r3)+                   ; Kanal8 retten,goto next Frame 
        cmp     x0,b
        jle     lower8
        move    b,x:(r1)                    ; peakwert8 speichern
lower8  move    r3,x:(r6)+
        move    #routbuf+8,r1
        do      #8,cpy_blk
        move    x:-(r3),y1
        nop
        nop
        move    y1,x:-(r1)
cpy_blk nop
        nop
        move    r3,y0
        move    #routes,r2
        do      #8,doroute
        move    x:(r1)+,x0             ; get sourcedata
        move    x:(r2)+,b              ; get routechannel 
        move    y0,a                   ; get bufstart
        nop
        nop
        add     b,a                    ; destdata
        nop
        nop
        move    a,r3
        nop
        nop
        move    x0,x:(r3)              ; copy data to destination
doroute nop
        nop
        move    x:-(r6),r3
	jmp     main

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

	org     x:$50
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
