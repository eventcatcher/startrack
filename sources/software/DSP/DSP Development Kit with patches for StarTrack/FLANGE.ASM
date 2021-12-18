;***************************************************************
;
;       Stereo Flange for the DSP56001 processor
;       Developed by Quinn Jensen (jensenq@npd.novell.com)
;
; patched for STARTRACK DSP56001-33
; 
;******************************************************************************
START   equ     $40
doff_i equ                               -33
ddeltaf equ                     0.0026607539
dspeed_i equ                          146800
dregen equ                      0.8888888889
delay   equ     $2000
dmax    equ     4096            ;125 ms

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

hf_init
	move    #delay,r1                       ;delay line input
	movec   #dmax-1,m1                      ;
	move    #doff_i,n1                      ;distance to output

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
 
;******************************************************************************

loop_1
	jset    #1,x:SSISR,*            ; warten auf Wechsel Links1->Rechts0
	jclr    #1,x:SSISR,*            ; warten auf Wechsel Rechts0->Links1
	jset    #6,x:SSISR,*            ; wait transmitter empty

	move   x:RX_BUFF_BASE+1,a        ;bring in L or R
	move   x:RX_BUFF_BASE,b          ;bring in L or R
	move   a,x:(r5)+                 ;bring in L or R
	move   b,x:(r5)+                 ;bring in L or R
	
	move   x:(r4)+,a                 ;and output L or R
	move   x:(r4)+,b                 ;and output L or R
	move   a,x:TX_BUFF_BASE+1        ;and output L or R
	move   b,x:TX_BUFF_BASE          ;and output L or R
	
	jsr   hf_comp               ;

	jmp     loop_1                  ; Loop back.

	include 'txrx_vme.asm'

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


;
; fs = 32.552083 kHz
;
hf_comp
	jsr     <saveregs
;
;       output and input mix
;
	clr     a       #.4375,x1               ;clr a, get input scale
	clr     b       #.5,y1                  ;clr b, get output scaler

	move            x:<delayout,y0          ;get delay out

	move            #.70,x0                 ;do regen term
	macr    x0,y0,a
	macr    x0,y0,a

	move            #.75,x0

	macr    y0,x0,b x:<in_l,x0              ;b = .5 * delay, x0=in_l
	macr    x0,y1,b         b,y0            ;b += .5 * in_l, y0=b
	macr    x0,x1,a b,x:<out_l              ;a += x1 * in_l, L = b
	move                    y0,b            ;b = -y0
	neg     b       x:<in_r,x0              ;x0 = in_r
	macr    x0,y1,b                         ;b += .5 * in_r
	macr    x0,x1,a b,x:<out_r              ;R = b, a += x1 * in_r
;
;       delay line in
;
	move            a,x:(r1)+
;
;       delay line length modulation
;
	move            l:<doff,a               ;a = current offset
	move            l:<ddelta,x             ;x = current delta
	add     x,a
	move            a,l:<doff               ;new offset = a + x
	move            a1,n1

	move            x1,b                    ;save delta for later use

; smoothly transition between delay-line offsets by
; interpolating the current sample with the previous or next
; one depending on whether the delay is currently getting longer or
; shorter.  Otherwise, an obnoxious click results when the offset snaps
; to the next integral value.

	move    y:<doff,a       ;compute |frac(doff)|
	lsr     a       #$800000,x0
	or      x0,a    #.5,x1
	move            a1,x0
	mpy     -x0,x1,a
	tst     b               a,y0            ;y0 = 0.5 * |frac(doff)|
	jpl     shorter                         ;on positive delta, the
						;delay is shortening

	move            (r1)-                   ;get previous sample
	move            x:(r1+n1),x0
	mpy     y0,x0,a #.5,b                   ;scale
	sub     y0,b    (r1)+                   ;compute scale for cur sample
	move                    b,y0
	move            x:(r1+n1),x0            ;get cur sample
	mac     x0,y0,a                         ;scale and sum
	jmp     endpan

shorter
	move            x:(r1+n1),x0            ;get cur sample
	mpy     y0,x0,a #.5,b                   ;scale
	sub     y0,b    (r1)+                   ;compute scale for next sample
	move                    b,y0
	move            x:(r1+n1),x0            ;get next sample
	mac     x0,y0,a (r1)-                   ;scale and sum
endpan
	move            a,x:<delayout           ;store resulting output

; update the triangle wave modulation

	move            x:<dtoggle,a            ;decrement toggle count
	move            #>1,x0
	sub     x0,a
	move            a,x:<dtoggle
	jgt     notogg                          ;time to toggle?
	move            x:<dspeed,x0            ;yes, negate delta and reset
	move            l:<ddelta,a
	neg     a       x0,x:<dtoggle
	move            a,l:<ddelta
notogg
bypass
	jsr     <restregs
	rts

dot
	org     x:$20

; Sample rate              32.5500 kc         
; 
; Delay time (1-12)         6.0000 ms         
; Depth (1-10)             10.0000
; Speed (1-10)              1.0000
; Regen (1-10)              9.0000
; 
; max depth +/-             6.0000 ms         
; min delay                 1.0000 ms         
; max delay                12.0000 ms         
; 1/2 cycle period          4.5100 s          
; samples per 1/2 cyc  146800.5000
; time delta/samp           0.0817 us         
; offset samp/samp          0.0027
; 
doff    dc      doff_i          ;current delay distance
	org     y:doff
	dc      0

	org     x:doff+1
ddelta  dc      0               ;
	org     y:ddelta
	dc      ddeltaf

	org     x:ddelta+1

dspeed  dc      dspeed_i
dtoggle dc      0               ;
delayout
	dc      0

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

	end
