;****************************************************************************
;       ECHO.ASM    Rev.1.2
;       Example program to move audio through CS4215
;               This program uses 4k samples of delay
;               to add a noticeable echo to the audio.
;
;       Copyright (c) MOTOROLA 1995
;                     Semiconductor Products Sector 
;                     Digital Signal Processing Division
;
; patched for STARTRACK DSP56001-33
; 
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

	include 'ada_vme.asm'


;******************************************************************************

	move    #$4000,r4
	move    #$3FFF,m4
loop_1
	jset    #1,x:SSISR,*            ; warten auf Wechsel Links1->Rechts0
	jclr    #1,x:SSISR,*            ; warten auf Wechsel Rechts0->Links1
	jset    #6,x:SSISR,*            ; wait transmitter empty

	move    x:RX_BUFF_BASE+1,a      ;receive left
	move    x:RX_BUFF_BASE,b        ;receive right
		
	move    x:(r4),x0       ;divide them by 2 and get oldest
	move    y:(r4),y0       ;samples from buffer
	add     x0,a                    ;add the new samples and the old
	add     y0,b
	asr     a
	asr     b
	move    a,x:(r4)                ;save the altered samples
	move    b,y:(r4)+               ;and bump the pointer

	move    a,x:TX_BUFF_BASE+1        ;transmit left
	move    b,x:TX_BUFF_BASE          ;transmit right

	jmp     loop_1                  ; Loop back.

	include 'txrx_vme.asm'

    end
