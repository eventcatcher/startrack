;****************************************************************************
;       RING4.ASM    Rev.1.0
;
; for STARTRACK DSP56001-33
; 
; Ring-Buffer-Record 
; empfÑngt Daten per SSI und sendet sie via Host (Stereo)
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
HSR             equ     $FFE9   ;Host status
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
	jsr     host_comand2             ;Host Kommando default

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

	move    #0,r1
	move    r1,x:start              ; Initialize start
	move    r1,x:count              ; Initialize count
	move    #$4000,r5
	move    r5,x:RX_PTR             ; Initialize the rx pointer
	move    #$4000,r4
	move    r4,x:TX_PTR             ; Initialize the rx pointer
	move    #$1FFF,m4
	move    #$1FFF,m5
	move    #0,a
	move    a,x:half
	nop
	movep   #5,x:HCR                ; host interrupt enable
	andi    #$FC,mr         ; enable interrupts
	jmp     *

ssi_rx_isr
	move    r5,x:(r6)+              ; Save r5 to the stack.
	move    x1,x:(r6)+              ; Save r5 to the stack.
	move     a,x:(r6)+              ; Save r5 to the stack.
	move     b,x:(r6)+              ; Save r5 to the stack.
	movep   x:SSIDR,b               ; Read out received data to buffer.
	move    x:start,a
	move    #0,x1
	nop
	nop
	cmp     x1,a
	jeq     rx_bypass
rx_go2  move    x:RX_PTR,r5              ; receive pointer
	jset    #1,x:SSISR,rxleft        ; Rechts0/Links1-Erkennung
	nop
rxright move    b,y:(r5)+         ; Read out received data to buffer.
	move    r5,x:RX_PTR
	move    b,x:RX_R
rx_go   move    #$5000,x1
	move    r5,a
	cmp     x1,a
	jne     rloop1b
	move    #1,a
	jmp     rloop1c
rloop1b move    #$4000,x1
	move    r5,a
	cmp     x1,a
	jne     rx_ende
	move    #0,a
	nop
	nop
rloop1c move    a,x:half
	move    x:start,a
	movep   a,x:HRX                 ; Datenanforderung durch Write in HRX   
	move    #1,x1
	add     x1,a
	move    a,x:start
rx_ende move    x:-(r6),b               ; Restore r5.
	move    x:-(r6),a               ; Restore r5.
	move    x:-(r6),x1              ; Restore r5.
	move    x:-(r6),r5              ; Restore r5.
	rti
rxleft  move    b,x:(r5)           ; Read out received data to buffer.
rxleft2 move    b,x:RX_L
	jmp     rx_ende
rx_bypass
	jset    #1,x:SSISR,rxleft2       ; Rechts0/Links1-Erkennung
	move    b,x:RX_R
	jmp     rx_ende

host_rx_isr
	move    x1,x:(r6)+              ; Save r5 to the stack.
	move    r4,x:(r6)+              ; Save r5 to the stack.
	move    a,x:(r6)+               ; Save r5 to the stack.
	movep   x:HRX,a
	move    x:TX_PTR,r4              ; receive pointer
	nop
	move    x:count,a        
	move    #0,x1
	cmp     x1,a
	jne     hright
hleft   movep   x:(r4),x:HRX         ; Read out received data to buffer.
	move    #1,x1
	move    x1,x:count
	jmp     hsndgo
hright  movep   y:(r4)+,x:HRX         ; Read out received data to buffer.
	move    #0,x1
	move    x1,x:count
hsndgo  move    r4,x:TX_PTR              ; receive pointer
	move    x:-(r6),a               ; Restore r5.
	move    x:-(r6),r4              ; Restore r5.
	move    x:-(r6),x1              ; Restore r5.
	rti

ssi_tx_isr
	move    x1,x:(r6)+              ; Save r5 to the stack.
	jset    #1,x:SSISR,txleft        ; Rechts0/Links1-Erkennung
	nop
	move    x:RX_R,x1
	movep   x1,x:SSIDR               ; Read out and trash received data
txexit  move    x:-(r6),x1              ; Restore r5.
	rti
txleft  move    x:RX_L,x1
	movep   x1,x:SSIDR               ; Read out and trash received data
	jmp     txexit

host_tx_isr
	rti

host_comand
	move    r1,x:(r6)+              ; Save r5 to the stack.
	move    #$4000,r1
	move    r1,x:RX_PTR             ; Initialize the rx pointer
	move    r1,x:TX_PTR             ; Initialize the rx pointer
	move    #0,r1
	move    r1,x:start              ; Initialize start
	move    x:-(r6),r1              ; Restore r5.
	rti

host_comand2
	move    r1,x:(r6)+              ; Save r5 to the stack.
	move    #1,r1
	move    r1,x:start              ; Initialize start
	move    #0,r1
	move    r1,x:count              ; Initialize start
	move    x:-(r6),r1              ; Restore r5.
	rti

	org    x:$50   
RX_PTR          equ     *
		ds      1        ;ZÑhler fÅr RX ISR
TX_PTR          equ     *
		ds      1       ; Pointer for rx buffer
half            equ     *
		ds      1
start           equ     *
		ds      1
count           equ     *
		ds      1
RX_R            equ     *
		ds      1
RX_L            equ     *
		ds      1

	end
