;****************************************************************************
;       RING.ASM    Rev.1.0
;
; for STARTRACK DSP56001-33
; 
; Ring-Buffer 
; (Stereo-Bypass, empfÑgt Daten von der SSI und sendet sie per SSI)

;******************************************************************************
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

;******************************************************************************
;       ADA_VME.ASM
;
;      portc usage:
;       bit8: SSI TX (from DSP to Codec)
;       bit7: SSI RX (from Codec to DSP)
;       bit6: SSI Clock
;       bit5: SSI Frame Sync
;       bit4: codec reset (from DSP to Codec)
;       bit3:
;       bit2: data/control bar
;             0=control
;             1=data
;
;****************************************************************************

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


       org    x:$50   ; war 0
TX_BUFF_BASE    equ     *
		ds      16       ;Buffer or Ringbuffer RX ISR

RX_PTR          equ     *
		ds      1        ;ZÑhler fÅr RX ISR

TX_PTR          ds      1       ; Pointer for rx buffer

	org     p:
codec_init

	movep   #$0000,x:PCC    ; turn off ssi port 
	movep   #$0,x:PCDDR     ; setup pc0-pc8 as inputs
	movep   #$4000,x:CRA    ; 16bits,1 word/frame, /2/4/2=2.5 MHz
	movep   #$F200,x:CRB    ; rcv,xmt & int ena,netwk,syn,sclk==inp,msb 1st
	movep   #$3000,x:IPR    ; set interrupt priority level
	movep   #$FFE8,x:PCC    ; Turn on ssi port
	andi    #$FC,mr         ; enable interrupts

	move    #$5000,r5
	move    r5,x:RX_PTR             ; Initialize the rx pointer
	move    #$4000,r4
	move    r4,x:TX_PTR             ; Initialize the rx pointer
	move    #$1FFF,m4
	move    #$1FFF,m5
	move    #0,a
	nop
	nop
	move    a,x:half
	jmp     *

;*****************************************************************************
;   TXRX_ISR.ASM 

ssi_rx_isr
	move    r5,x:(r6)+              ; Save r5 to the stack.
	move    x:RX_PTR,r5              ; receive pointer
	jset    #1,x:SSISR,next_rx      ; Rechts0/Links1-Erkennung
	nop
	movep   x:SSIDR,y:(r5)+         ; Read out received data to buffer.
	move    r5,x:RX_PTR
	move    x:-(r6),r5              ; Restore r5.
	rti
next_rx
	movep   x:SSIDR,x:(r5)          ; Read out received data to buffer.
	move    x:-(r6),r5              ; Restore r5.
	rti

ssi_tx_isr
	move    r4,x:(r6)+              ; Save r5 to the stack.
	move    x1,x:(r6)+              ; Save r5 to the stack.
	move    a,x:(r6)+              ; Save r5 to the stack.
	move    x:TX_PTR,r4              ; receive pointer
	jset    #1,x:SSISR,next_tx      ; Rechts0/Links1-Erkennung
	nop
	movep   y:(r4)+,x:SSIDR         ; Read out received data to buffer.
	move    r4,x:TX_PTR
	move    #$5000,x1
	move    r4,a
	cmp     x1,a
	jne     loop1b
	move    #1,a
	nop
	nop
	move    a,x:half
loop1b  move    #$4000,x1
	move    r4,a
	cmp     x1,a
	jne     loop1c
	move    #0,a
	nop
	nop
	move    a,x:half
loop1c  move    x:-(r6),a               ; Restore r5.
	move    x:-(r6),x1              ; Restore r5.
	move    x:-(r6),r4              ; Restore r5.
	rti
next_tx
	movep   x:(r4),x:SSIDR         ; Read out received data to buffer.
	jmp     loop1c

	org     x:$50
half    equ     *
	ds      1

    end
