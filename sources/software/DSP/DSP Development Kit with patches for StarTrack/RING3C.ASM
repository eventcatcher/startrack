;****************************************************************************
;       RING3C.ASM    Rev.1.2
;
; for STARTRACK DSP56001-33
; 
; Ring-Buffer 
; empf„ngt 4 Kan„le via Host, mischt sie zu einem Stereo-Signal zusammen 
; und sendet sie per SSI
;
; Timingoptimierte Version, nutzt schnelle HostInt-Routine und Work-Buffer
; Berechnung der Daten nicht im Interrupt, sondern im Hauptprogramm !!!
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
	move    #1,a
	move    a,x:convert
	move    #$4000,r5              ; Init receive-pointer
	move    #$3FF,m5               ; receive-pointer counter-reset
	move    #$4000,r4              ; Init transmit-pointer
	move    #$3FF,m4               ; transmit-pointer counter-reset
	move    #$5000,r1              ; Init work-pointer
	move    #$7FF,m1               ; work-pointer counter-reset
	move    #$7FF,y1
	movep   #5,x:HCR                ; host interrupt enable
	andi    #$FC,mr                 ; enable interrupts
	
	
anf     move    x:convert,a
	tst     a       
	jne     anf
	do      #$200,anf2
	move    x:(r1)+,a            
	move    x:(r1)+,b            
	move    x:(r1)+,x1         
	add     x1,a    x:(r1)+,x1       
	add     x1,b    a,x:(r5)    
	move    b,y:(r5)+
anf2    move    x:start,a
	move    #1,x1
	add     x1,a    x1,x:convert    
	cmp     x1,a    a,x:start   
	jne     anf 
	movep   a,x:HRX                 ; Datenanforderung durch Write in HRX   
free    jmp     anf

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
loop1a  jset    #1,x:SSISR,ssileft        ; Rechts0/Links1-Erkennung
	movep   y:(r4)+,x:SSIDR         ; Read out received data to buffer.
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
	move    a,x:(r6)+              ; Save r5 to the stack.
	movep   x:HRX,x:(r1)+          ; Read out received data to buffer.
	move    r1,a        
	and     y1,a    
	move    a,x:convert
host_ex move    x:-(r6),a               ; Restore r5.
	rti

host_tx_isr
	rti

host_comand
	move    a,x:(r6)+              ; Save r5 to the stack.
	clr     a    
	move    a,x:start              ; Initialize start
	move    #1,a 
	move    a,x:convert
	move    #$4000,r5              ; Initialize the rx pointer
	move    #$4000,r4              ; Initialize the rx pointer
	move    #$5000,r1              ; Init work-pointer
	movep   a,x:HRX                ; Datenanforderung durch Write in HRX   
	move    x:-(r6),a              ; Restore r5.
	rti

	org    x:$50   
start           equ     *
		ds      1
convert         equ     *
		ds      1

	end
