;****************************************************************************
;       DONOT.ASM    Rev.1.0
;
; for STARTRACK DSP56001-33
; 
; Dummy-Ring-Buffer 
; empf„ngt 8 Kan„le via Host, und macht nix 
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
HRX             equ     $FFEB   ;Host Data
HCR             equ     $FFE8   ;Host interrupt enable
PCD             equ     $FFE5   ;Port C Data Register
PCDDR           equ     $FFE3   ;Port C Data Direction Register
PCC             equ     $FFE1   ;Port C Control Register
PBC             equ     $FFE0   ;Port B Control Register

START           equ     $40

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
	jsr     host_comand              ;Host Kommando default

;---------------------------------------------------------------------------
;      DSP/codec initialization
;---------------------------------------------------------------------------
	org     p:START

	movep   #$0000,x:BCR            ;zero wait states in all ext. memory
	ori     #3,mr                   ;disable interrupts
	movep   #1,x:PBC                ; port b = host
	movec   #0,sp                   ;clear hardware stack pointer
	move    #$40,r6                 ; initialize stack pointer
	move    #-1,m6                  ; linear addressing
	move    #2,omr
	movep   #$0000,x:PCC    ; turn off ssi port 
	movep   #$0,x:PCDDR     ; setup pc0-pc8 as inputs
	movep   #$4000,x:CRA    ; 16bits,1 word/frame, /2/4/2=2.5 MHz
	movep   #$F200,x:CRB    ; rcv,xmt & int ena,netwk,syn,sclk==inp,msb 1st
	movep   #$3800,x:IPR    ; set interrupt priority level
	movep   #$FFE8,x:PCC    ; Turn on ssi port

	clr     a
	move    a,x:start              ; Initialize start
	move    #0,r4                  ; Init transmit-pointer
	move    #$3FF,m4               ; transmit-pointer counter-reset
	movep   #5,x:HCR                ; host interrupt enable
	andi    #$FC,mr                 ; enable interrupts
	jmp     *

ssi_rx_isr
	movep   x:SSIDR,y0              ; Read out received data to buffer.
	rti

ssi_tx_isr
	move    a,x:(r6)+              ; Save r5 to the stack.
	move    x:start,a
	tst     a    
	jne     loop1a
	movep   a,x:SSIDR         ; Read out received data to buffer.
	move    x:-(r6),a               ; Restore r5.
	rti
loop1a  movep   y:(r4)+,x:SSIDR         ; Read out received data to buffer.
	move    r4,a     
	tst     a
	jne     loop1c
	movep   a,x:HRX                 ; Datenanforderung durch Write in HRX   
loop1c  move    x:-(r6),a               ; Restore r5.
	rti

host_rx_isr
	movep   x:HRX,y0                ; Read out received data to buffer.
	rti

host_tx_isr
	rti

host_comand
	move    a,x:(r6)+              ; Save r5 to the stack.
	clr     a
	move    a,x:start              ; Initialize start
	move    #$0,r4                 ; Initialize the rx pointer
	move    #1,a
	move    a,x:start              ; Initialize start
	move    x:-(r6),a              ; Restore r5.
	rti

	org    x:$50   
start           equ     *
		ds      1

	end
