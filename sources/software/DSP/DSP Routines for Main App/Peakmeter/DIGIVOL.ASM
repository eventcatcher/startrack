;****************************************************************************
;       DSPREC.ASM    Rev.1.0
;
; for STARTRACK DSP56001-33
; 
; Ring-Buffer-Record 
; empfÑngt und sendet Daten per SSI
;
; fÅr digital record mit volume,pan,bypass und mute
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

START           equ     $80

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
        jsr     dummy                    ;Host Kommando
        jsr     set_byp                  ;Host Kommando
        jsr     set_mode                 ;Host Kommando


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

	move    #$4000,r5
	move    r5,x:RX_PTR             ; Initialize the rx pointer
	move    #$4000,r4
	move    r4,x:TX_PTR             ; Initialize the rx pointer
	move    #$3FF,m4
	move    #$3FF,m5
        move    #bypass,r7              ; liste master-bypass
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
        jset    #1,x:SSISR,rxleft       ; Rechts0/Links1-Erkennung
        jset    #0,x:(r7),nobypm0           ; bypass masterchannels ?
        move    #level+1,r2
        move    b,y1
        move    x:(r2),y0                  ; level anpassen
        mpy     y0,y1,b
        asl     b
nobypm0 move    #peaks+1,r2
        nop
        nop
        move    x:(r2),x0                   ; peakwert-rechts holen
        cmp     x0,b
        jle     rnbypr2
        move    b,x:(r2)                    ; peakwert-rechts speichern
rnbypr2 move    b,x:RX_R
rx_ende move    x:-(r6),b               ; Restore r5.
	move    x:-(r6),a               ; Restore r5.
	move    x:-(r6),x1              ; Restore r5.
	move    x:-(r6),r5              ; Restore r5.
	rti

rxleft  jset    #0,x:(r7),nobypm2           ; bypass masterchannels ?
        move    #level,r2
        move    b,y1
        move    x:(r2),y0                  ; level anpassen
        mpy     y0,y1,b
        asl     b
nobypm2 move    b,x:(r5)           ; Read out received data to buffer.
        move    #peaks,r2
        nop
        nop
        move    x:(r2),x0                   ; peakwert-links holen
        cmp     x0,b
        jle     lnhigh
        move    b,x:(r2)                    ; peakwert-links speichern
lnhigh  move    b,x:RX_L
	jmp     rx_ende

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

set_mode
        move    x0,x:(r6)+
        move    #receive,r0
        nop
        move    x:(r0),x0          ; mode-word
        nop
        jset    #0,x0,bit24     ; 24bit ?
        movep   #$4000,x:CRA    ; 16bits,2 word/frame
        move    x:-(r6),x0
        rti
bit24   movep   #$6000,x:CRA    ; 24bits,2 word/frame
        move    x:-(r6),x0
dummy   rti

	org    x:$50   

peaks   dc      0
        dc      0

bypass  dc      0

level   dc      $3FFF00
        dc      $3FFF00

RX_PTR          equ     *
		ds      1        ;ZÑhler fÅr RX ISR
TX_PTR          equ     *
		ds      1       ; Pointer for rx buffer
RX_R            equ     *
		ds      1
RX_L            equ     *
		ds      1

receive 

	end
