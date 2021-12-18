;***************************************************************
; 
; A stereo reverb for the DSP56001 signal processor.
; Developed by Quinn Jensen (jensenq@npd.novell.com) using
; Dr. Vercoe and company's csound code as a reference for the 
; configuration and gain values.
; 
; This program fragment implements a stereo reberb effect
; on a DSP56001 processor.  The "depth" and wet/dry mix are
; adjustable.  The following filter configuration is employed:
;
;
;  Left in ------+------- "dry" gain -----------> sum -----> Left out
;                |                                 ^
;                v                                 |
;               sum --> reverb --> "wet" gain -----+
;                ^                                 |
;                |                                 v -
;  Right in -----+------- "dry" gain -----------> sum -----> Right out
;
;
; Note that the reverb path output is negated before summing with the
; right input signal.  This throws in 180 degrees of phase shift
; making for interesting results even with mono inputs 
; (i.e. Left in == Right in).
; 
; The reverb element looks like this:
;
;
; Input ----+-----> comb1 ------+
;           |                   |
;           +-----> comb2 ---\  v
;           |                  sum -----> allpass1 --> allpass2 ---> output
;           +-----> comb3 ---/  ^
;           |                   |
;           +-----> comb4 ------+
;
; Each comb stage looks like this:
;
;                        +---- gain <-----+
;                        |                |
;                        v                |
; Input ---> gain ----> sum ---> delay ---+--> out
;
;
; The allpass stages look like:
;
;                         +--------- gain <---------+
;                         |                         |
;                         v                         |
; Input ---> gain --+--> sum ---> delay ---> sum ---+----> out
;                   |                         ^
;                   |                         |
;                   +--------> gain ----------+
;
; or,
;
;                             +-------> gain ----+
;                             |                  |
;                             |                  v
; Input ---> gain ----> sum --+--> delay --+--> sum -----> out
;                        ^                 |
;                        |                 |
;                        +----- gain <-----+
;
;
; I've seen both configurations in the literature, so I plotted the
; Z-transform and they are equivalent in the steady state.  They are indeed
; all-pass in the steady state but are supposed to have a subtle, discernable
; effect in "transient" audio signals.
;
; I think it could really use a couple more comb stages to fill in some of the 
; graininess.  The best possible "diffusion" is desired.  By the way, 
; I'd enjoy seeing any optimizations to the code.
;
; Quinn Jensen (jensenq@npd.novell.com or jensenq@qcj.icon.com)
;

START   equ     $40

dot                             ;remember where we were in P-space
	org     x:$10           ;put runtime variables in on-chip X-space

in_atten equ                      0.3409091
comb_atten equ                    0.0416667
dry_init equ                      0.4000000     ; initial "dry" gain
reverb_init equ                   0.9900000     ; initial "wet" gain

; comb 1 data and parameters

c1d equ $1000        ; war $4000
c1r dc c1d
c1m equ 966          ; war 966
c1c equ 0.9500031

; comb 2 data and parameters

c2d equ c1d+2048
c2r dc c2d
c2m equ 1207         ; war 1207
c2c equ 0.9379399

; comb 3 data and parameters

c3d equ c2d+2048
c3r dc c3d
c3m equ 1337         ; war 1337
c3c equ 0.9314831

; comb 4 data and parameters

c4d equ c3d+2048
c4r dc c4d
c4m equ 1422         ; war 1422
c4c equ 0.9273101

; allpass 1 data and parameters

a1d equ c4d+2048
a1r dc a1d
a1m equ 162          ; war 162
a1c equ 0.9914025

; allpass 2 data and parameters

a2d equ a1d+2048
a2r dc a2d
a2m equ 54           ; war 54
a2c equ 0.9970685
 
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
	
	movec   #$0300,sr                       ;go to IPL 3

	movep   #$0000,x:BCR            ;zero wait states in all ext. memory
	ori     #3,mr                   ;disable interrupts
	movec   #0,sp                   ;clear hardware stack pointer
	move    #0,omr                  ;mode 0: enable int. P:RAM, rst=0000
	move    #$40,r6                 ; initialize stack pointer
	move    #-1,m6                  ; linear addressing

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
	
	jsr eff1_on

	include 'ada_vme.asm'
;  Achtung !     x:Location is $800 for ada_vme.asm        

	movec   #0,sr                       ;go to IPL 1

;******************************************************************************

loop_1
	jset    #1,x:SSISR,*            ; warten auf Wechsel Links1->Rechts0
	jclr    #1,x:SSISR,*            ; warten auf Wechsel Rechts0->Links1
	jset    #7,x:SSISR,*            ; wait transmitter empty

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

;*****************************************************
;
; run-time controls
;
;*****************************************************

eff1_on         ;enable reverb
	move                    #reverb_on,y0
	move                    y0,y:<reverb_gain
	rts

eff1_off        ;bypass reverb
	move                    #reverb_off,y0
	move                    y0,y:<reverb_gain
	rts

;*****************************************************
;
; interrupt time calculations
;
;*****************************************************

;
; fs = 32.552083 kHz
;

hf_comp
	jsr     <saveregs
;
;       L/R mix
;
	clr     a       #in_atten,x1            ;clr a, get scale for mix
	move            x:<in_l,x0              ;get left in
	move            x0,x:<in_ls             ;save
	macr    x0,x1,a x:<in_r,x0              ;a = scale * left, get right
	macr    x0,x1,a x0,x:<in_rs             ;a += scale * right, save right
	clr     b               a,y0            ;y0 goes to the combs, b is sum
;
;       comb 1 
;
	move            x:<c1r,r0
	movec           #c1m,m0
	move                    y0,a
	move            x:(r0),x1
	add     x1,b    #c1c,x0
	macr    x0,x1,a
	move            a,x:(r0)+
	move            r0,x:<c1r
;
;       comb 2
;
	move            x:<c2r,r0
	movec           #c2m,m0
	move                    y0,a
	move            x:(r0),x1
	add     x1,b    #c2c,x0
	macr    x0,x1,a
	move            a,x:(r0)+
	move            r0,x:<c2r
;
;       comb 3
;
	move            x:<c3r,r0
	movec           #c3m,m0
	move                    y0,a
	move            x:(r0),x1
	add     x1,b    #c3c,x0
	macr    x0,x1,a
	move            a,x:(r0)+
	move            r0,x:<c3r
;
;       comb 4
;
	move            x:<c4r,r0
	movec           #c4m,m0
	move                    y0,a
	move            x:(r0),x1
	add     x1,b    #c4c,x0
	macr    x0,x1,a
	move            a,x:(r0)+
	move            r0,x:<c4r
;
;       scale
;
	move            #comb_atten,x0  b,y0
	mpyr    x0,y0,b

;
;       allpass 1
;
	move            x:<a1r,r0
	movec           #a1m,m0
	move            #a1c,x0
	move            x:(r0),x1
	macr    x0,x1,b x1,a
	move                    b,y0
	macr    -x0,y0,a b,x:(r0)+
	move            r0,x:<a1r
;
;       allpass 2
;
	move            x:<a2r,r0
	movec           #a2m,m0
	move            #a2c,x0
	move            x:(r0),x1
	macr    x0,x1,a x1,b
	move                    a,y0
	macr    -x0,y0,b a,x:(r0)+
	move            r0,x:<a2r
;
;       output mix
;
	move            b,x0
	move                    y:<reverb_gain,y0
	mpyr    x0,y0,b         y:<dry_gain,y0
	move            x:<in_ls,x0
	move            b,a
	macr    x0,y0,a x:<in_rs,x0
	macr    x0,y0,b a,x:<out_l
	move            b,x:<out_r

	jsr     <restregs
	rts

	org     y:$0

reverb_on equ   reverb_init
reverb_off equ  0

reverb_gain
	dc      reverb_on
dry_gain
	dc      dry_init

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
