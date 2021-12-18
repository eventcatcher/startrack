;****************************************************************************
;       KURZECHO.ASM    Rev.1.0
;
; patched for STARTRACK DSP56002-66 with 32Kx24 Bit SRAM
; 
; nutzt fast die Falcon-kompatiblen 32Kx24 fr ein Echo (0.35 sec.)
; 
; Testet P-mem des 32Kx24Bit RAMs auf korrekte Funktionsweise
; P: ab $200, X: und Y: ab $300-$3FFF
; 
;******************************************************************************
START   equ     $200

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

	move    #$300,r4
	move    #$FFFF,m4

loop_1
	jset    #1,x:SSISR,*            ; warten auf Wechsel Links1->Rechts0
	jclr    #1,x:SSISR,*            ; warten auf Wechsel Rechts0->Links1
	jset    #6,x:SSISR,*            ; wait transmitter empty

	move    x:RX_BUFF_BASE+1,a      ;receive left
	move    x:RX_BUFF_BASE,b        ;receive right
		
	asr     a       x:(r4),x0       ;divide them by 2 and get oldest
	asr     b       y:(r4),y0       ;samples from buffer
	add     x0,a                    ;add the new samples and the old
	add     y0,b
	asr     a                       ;reduce magnitude of new data
	asr     a
	asr     b
	asr     b
	move    a,x:(r4)                ;save the altered samples
	move    b,y:(r4)+               ;and bump the pointer

	move    a,x:TX_BUFF_BASE+1        ;transmit left
	move    b,x:TX_BUFF_BASE          ;transmit right

	move    r4,a
	move    #$3FFF,x0
	cmp     x0,a
	jne     loop_1
	move    #$300,x1        
	move    x1,r4
	jmp     loop_1

	include 'txrx_vme.asm'

    end
