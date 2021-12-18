; pink noise (1/f) generator
; based on noise generator from Dr. Bubb but extended to 24 bits
; uses simple one-tap recursive filter
;
; written by: Quinn Jensen (jensenq@npd.novell.com)
;
; patched for STARTRACK

	org     x:$10

NSTATE  dc      1               ;STATE OF NOISE GENERATOR (SHIFT REG)

	org     y:$0
	org     x:$0
in_l    dc      0                               ;input queue
in_r    dc      0
in_ls   dc      0                               ;saved left
in_rs   dc      0                               ;and right
out_l   dc      0                               ;output queue
out_r   dc      0

savea10 dc      0                               ;places to save regs
savea2  dc      0                               ;N.B. uses YMEM also!
saveb10 dc      0
saveb2  dc      0
savex   dc      0
savey   dc      0

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

hf_init
	MOVE    #$FEEDEE,X0         ;INITIAL STATE OF NOISE GENERATOR
	MOVE    X0,X:<NSTATE

;
; global register assignments
;
; r5,m5         Stereo input queue pointer (alternating L/R)
; r4,m4         Stereo output queue pointer (alternating L/R)

init_stereo
	move            #>in_l,r5               ;base of stereo input queue
	move            #>out_l,r4              ;base of stereo output queue
	movec           #2-1,m5                 ;modulus of stereo input queue
	movec           #2-1,m4                 ;modulus of stereo output queue

;
; fs = 32.552083 kHz
;

	include 'ada_vme.asm'
; ! Achtung !  x-locator auf $50 setzen !


loop        
	jset    #1,x:SSISR,*            ; warten auf Wechsel Links1->Rechts0
	jclr    #1,x:SSISR,*            ; warten auf Wechsel Rechts0->Links1
	jset    #6,x:SSISR,*            ; wait transmitter empty
	
	move   x:out_r,a
	move   x:out_l,b
	move   a,x:TX_BUFF_BASE+1        ;and output L or R
	move   b,x:TX_BUFF_BASE          ;and output L or R

	jsr hf_comp

	jmp loop

saveregs
	move            a2,x:<savea2
	move            a1,x:<savea10
	move            a0,y:<savea10
	move            x,l:<savex
	move            b2,x:<saveb2
	move            b1,x:<saveb10
	move            b0,y:<saveb10
	move            y,l:<savey
	rts

restregs
	move            l:<savea10,a
	move            x:<savea2,a2
	move            l:<savex,x
	move            l:<saveb10,b
	move            x:<saveb2,b2
	move            l:<savey,y
	rts

hf_comp

	jsr     <saveregs
	jsr     NOISE
	move            #.005,x1
	move            #.990,y1
	move            a,x0
	mpyr    x0,x1,a x:<out_l,x0
	macr    x0,y1,a
	move            a,x:<out_l
	jsr     NOISE
	move            a,x0
	mpyr    x0,x1,a x:<out_r,x0
	macr    x0,y1,a
	move            a,x:<out_r
	jsr     <restregs
	rts
	
	include 'txrx_vme.asm'


;       NOISE GENERATION ROUTINE.  THIS ROUTINE USES A 15 BIT SHIFT
;       REGISTER LEFT JUSTIFIED IN THE VARIABLE "NSTATE".  AFTER THE STATE
;       IS LOADED, IT IS CHECKED TO SEE IF IT IS NORMALIZED.  IF IT IS
;       NORMALIZED (TOP TWO BITS ARE DIFFERENT), A 1 IS SET AS THE INPUT
;       TO THE SHIFT REGISTER AND THE REGISTER IS SHIFTED AND SAVED.
;
;         B23     B22                            B9      B8
;        ______________________________________________
;       | S14   | S13 |                        | S0   |
;       |       |     |      . . .             |      |<----------
;       |_______|_____|________________________|_______          |
;           |      |                                             |
;            \    /                                              |
;              XOR                                               |
;               \_________________________________________________
;
;
;       ASSUMES SCALING MODE IS OFF
;
NOISE                                   ;DO NOISE GENERATION LOOP
	CLR     B       X:<NSTATE,A     ;GET A ZERO IN B
	TST     A   #>$000001,X0        ;CHECK A, GET A 1 IN LSB POSITION
	TNR     X0,B                    ;IF NORMALIZED, THEN XOR=1
	ADD     B,A                     ;SET LSB
	ASL     A                       ;SHIFT BITS
	MOVE    A1,X:<NSTATE            ;SAVE STATE
	RTS                             ;RETURN WITH STATE

	END
