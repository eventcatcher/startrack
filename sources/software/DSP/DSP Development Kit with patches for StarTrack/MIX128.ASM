;****************************************************************************
;       MIX128.ASM    Rev.1.0
;
; for STARTRACK DSP56001-33
; 
; Ring-Buffer fr 8 Falconkompatible Kan„le
;
; mischt zus„tzlich die 8 Kan„le zu 2 zusammen und gibt sie in den 
; letzten beiden Slots aus
;
; Stereo-Bypass, empf„ngt 8 Kan„le im Network-Mode,asynchron, external Clk 
; von der SSI und sendet sie unver„ndert per SSI
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


START   equ     $40

	org     p:0                     ;RESET Vector
	jmp     START
 
	org     p:$000C
	jsr     ssi_rx_isr              ;SSI RX
	jsr     ssi_rx_isr              ;SSI RX w/Exception
	jsr     ssi_tx_isr              ;SSI TX
	jsr     ssi_tx_isr              ;SSI TX w/Exception
;******************************************************************************

;---------------------------------------------------------------------------
;
;      DSP/codec initialization
;
;---------------------------------------------------------------------------
	org     p:START

	movep   #$0000,x:BCR            ;zero wait states in all ext. memory
	ori     #3,mr                   ;disable interrupts
	movec   #0,sp                   ;clear hardware stack pointer
	move    #0,omr                  ;mode 0: enable int. P:RAM, rst=0000
	move    #$40,r6                 ; initialize stack pointer
	move    #-1,m6                  ; linear addressing

codec_init
	movep   #$0000,x:PCC    ; turn off ssi port 
	movep   #$0,x:PCDDR     ; setup pc0-pc8 as inputs
	movep   #$4700,x:CRA    ; 16bits,8 word/frame
	movep   #$F800,x:CRB    ; rcv,xmt & int ena,netwk,syn,sclk==inp,msb 1st
	movep   #$3000,x:IPR    ; set interrupt priority level
	movep   #$FFF8,x:PCC    ; Turn on ssi port
	move    #$2800,r5       ; Memorypointer Receive
	move    #$FFF,m5        ; Modulo Receive 4KB = $2000 - $2FFF
	move    #$2000,r4       ; Memorypointer Transmit
	move    #$FFF,m4        ; Modulo Transmit 4KB = $2000 - $2FFF
	move    #$2FF8,x1       ; Rundungswert fr Speicher-Synchronisation
	move    r5,r3
	move    #$FFF,m3        ; Modulo mixpointer 4KB = $2000 - $2FFF
	andi    #$FC,mr         ; enable interrupts

	
	
main    move    r5,a
	and     x1,a    r3,y0
	cmp     y0,a
	jeq     main
	move    #level,r2
	nop
	move    x:(r2)+,y0                  ; level ersten Kanal holen       
	move    x:(r3)+,y1                  ; Daten erster Kanal holen
	mpy     y0,y1,a         x:(r2)+,y0  ; level1 anpassen, level2 holen
	move    x:(r3)+,y1                  ; Daten zweiter Kanal holen 
	mpy     y0,y1,b         x:(r2)+,y0  ; level2 anpassen, level3 holen
	move    x:(r3)+,y1                  ; Daten dritter Kanal holen
	macr    y0,y1,a         x:(r2)+,y0  ; level3 anpassen,add level1,hol level4
	move    x:(r3)+,y1                  ; Daten vierter Kanal holen
	macr    y0,y1,b         x:(r2)+,y0  ; level4 anpassen,add level2,hol level5
	move    x:(r3)+,y1                  ; Daten fnfter Kanal holen
	macr    y0,y1,a         x:(r2)+,y0  ; level5 anpassen,add level1+3,hol level6
	move    x:(r3)+,y1                  ; Daten sechter Kanal holen
	macr    y0,y1,b         x:(r2)+,y0  ; level6 anpassen,add level2+4,hol level7
	move    x:(r3)+,y1                  ; Daten siebter Kanal holen
	macr    y0,y1,a         x:(r2)+,y0  ; level7 anpassen,add level1+3+5,hol level8
	move    x:(r3),y1                   ; Daten achter Kanal holen
	macr    y0,y1,b                     ; level8 anpassen,add level2+4+6
	move    a,x:-(r3)                   ; mix 1+3+5+7 in Slot 7 speichern
	move    x:(r3)+,a                   ; dummy um zum Slot 8 zu kommen
	move    b,x:(r3)+                   ; mix 2+4+6+8 in Slot 8 speichern
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


	org     x:$50
level   dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00

	end
