;****************************************************************************
;       RING128.ASM    Rev.1.0
;
; for STARTRACK DSP56001-33
; 
; Ring-Buffer fr 8 Falconkompatible Kan„le
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
	andi    #$FC,mr         ; enable interrupts

	
	jmp     *


ssi_rx_isr
	jset    #3,x:SSISR,frame_rx      ; Frame-Erkennung
	movep   x:SSIDR,x:(r5)+          ; Read out received data to buffer
	rti
frame_rx move    r5,a
	and     x1,a                     ; 1.Slot->Speicher synchonisieren
	move    a,r5                   
	nop
	movep   x:SSIDR,x:(r5)+          ; Read out received data to buffer
	rti

ssi_tx_isr
	jset    #2,x:SSISR,frame_tx      ; Frame-Erkennung
	movep   x:(r4)+,x:SSIDR           ; read out buffer and transmit
	rti
frame_tx
	move    r4,b
	and     x1,b                     ; 2.Slot->Speicher synchronisieren
	move    b,r4                     ; auf ersten Slot runden
	nop
	move    x:(r4)+,b                ; wir sind aber im zweiten Slot
	movep   x:(r4)+,x:SSIDR          ; read out buffer and transmit
	rti                         
	end
