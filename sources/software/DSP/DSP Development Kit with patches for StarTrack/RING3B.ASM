;****************************************************************************
;       RING3B.ASM    Rev.1.1
;
; for STARTRACK DSP56001-33
; 
; Ring-Buffer 
; empfÑngt 4 KanÑle via Host, mischt sie zu einem Stereo-Signal zusammen 
; und sendet sie per SSI
;
; Timingoptimierte Revision
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

	move    #0,r1
	move    r1,x:start              ; Initialize start
	move    r1,x:count              ; Initialize count
	move    #$4000,r5
	move    r5,x:RX_PTR             ; Initialize the rx pointer
	move    #$4000,r4
	move    r4,x:TX_PTR             ; Initialize the rx pointer
	move    #$3FF,m4
	move    #$3FF,m5       
	movep   #5,x:HCR                ; host interrupt enable
	andi    #$FC,mr                 ; enable interrupts
	move    #1,a
	movep   a,x:HRX                 ; Datenanforderung durch Write in HRX   
	jmp     *

ssi_rx_isr
	movep   x:SSIDR,y0              ; Read out received data to buffer.
	rti

ssi_tx_isr
	move    a,x:(r6)+              ; Save r5 to the stack.
	move    x:start,a
	move    #1,x0
	cmp     x0,a
	jgt     loop1a
	clr     a
	movep   a,x:SSIDR         ; Read out received data to buffer.
	jmp     loop1c
loop1a  move    x:TX_PTR,r4              ; receive pointer
	jset    #1,x:SSISR,ssileft        ; Rechts0/Links1-Erkennung
	movep   y:(r4)+,x:SSIDR         ; Read out received data to buffer.
	move    r4,x:TX_PTR
	move    r4,a     
	move    #$1FF,x0
	and     x0,a        
	tst     a
	jne     loop1c
	movep   a,x:HRX                 ; Datenanforderung durch Write in HRX   
loop1c  move    x:-(r6),a               ; Restore r5.
	rti
ssileft movep   x:(r4),x:SSIDR         ; Read out received data to buffer.
	jmp     loop1c


host_rx_isr
	move    x:count,a        
	move    #1,x1
	add     x1,a    x:RX_PTR,r5    
	cmp     x1,a    a,x:count
	jne     hright1
hleft1  movep   x:HRX,x:(r5)          ; Read out received data to buffer.
	jmp     free
hright1 move    #2,x1
	cmp     x1,a
	jne     hleft2
	movep   x:HRX,y:(r5)          ; Read out received data to buffer.
	jmp     free
hleft2  move    #3,x1
	cmp     x1,a
	jne     hright2
	move    x:(r5),a
	movep   x:HRX,x1               ; Read out received data to buffer.
	add     x1,a       
	move    a,x:(r5)
	jmp     free
hright2 clr     a       
	move    a,x:count       
	move    y:(r5),a
	movep   x:HRX,b               ; Read out received data to buffer.
	add     b,a          
	move    a,y:(r5)+       
	move    r5,x:RX_PTR              ; receive pointer
	move    #0,x1
	move    x1,x:count
	move    r5,a
	move    #$1FF,x1        
	and     x1,a    #0,x1
	cmp     x1,a
	jne     free
	move    x:start,a
	move    #1,x1
	add     x1,a    
	cmp     x1,a    a,x:start
	jne     free
	movep   a,x:HRX                 ; Datenanforderung durch Write in HRX   
free    rti

host_tx_isr
	rti

host_comand
	move    a,x:(r6)+              ; Save r5 to the stack.
	clr     a
	move    a,x:start              ; Initialize start
	move    a,x:count              ; Initialize start
	move    #$4000,a
	move    a,x:RX_PTR             ; Initialize the rx pointer
	move    a,x:TX_PTR             ; Initialize the rx pointer
	movep   a,x:HRX                 ; Datenanforderung durch Write in HRX   
	move    x:-(r6),a               ; Restore r5.
	rti

	org    x:$50   
RX_PTR          equ     *
		ds      1        ;ZÑhler fÅr RX ISR
TX_PTR          equ     *
		ds      1       ; Pointer for rx buffer
start           equ     *
		ds      1
count           equ     *
		ds      1

	end
