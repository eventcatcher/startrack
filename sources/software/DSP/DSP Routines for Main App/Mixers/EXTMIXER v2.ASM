;****************************************************************************
;       EXTMIXER.ASM    Rev.1.0
;
; for STARTRACK DSP56002-66
; 
; Mischer mit Volumecontrol & Route fÅr 8 Falconkompatible KanÑle
;
; Stereo-Bypass, empfÑngt 8 KanÑle im Network-Mode,asynchron, external Clk 
; von der SSI und sendet sie per SSI
; SC2=Framesync Transmitter, SCLK = Clock Transmitter
; SC1=Framesync Receiver   , SC0 = CLock Receiver
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
PCD             equ     $FFE5   ;Port C Data Register
PCDDR           equ     $FFE3   ;Port C Data Direction Register
PCC             equ     $FFE1   ;Port C Control Register
PBC             equ     $FFE0   ;Port B Control Register
HRX             equ     $FFEB   ;Host Data
HCR             equ     $FFE8   ;Host interrupt enable
HSR             equ     $FFE9   ;Host Status Register


START   equ     $100

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
        jsr     set_route                ;Host Kommando
        jsr     set_byp                  ;Host Kommando
        jsr     set_mode                 ;Host Kommando

;******************************************************************************

;---------------------------------------------------------------------------
;
;      DSP/codec initialization
;
;---------------------------------------------------------------------------
	org     p:START

        movep   #$0000,x:BCR            ; zero wait states in all ext. memory
        ori     #3,mr                   ; disable interrupts
	movep   #1,x:PBC                ; port b = host
        move    #2,omr
        movec   #0,sp                   ; clear hardware stack pointer
        move    #$400,r6                ; initialize stack pointer
	move    #-1,m6                  ; linear addressing

codec_init
	movep   #$0000,x:PCC    ; turn off ssi port 
	movep   #$0,x:PCDDR     ; setup pc0-pc8 as inputs
	movep   #$4700,x:CRA    ; 16bits,8 word/frame
	movep   #$F800,x:CRB    ; rcv,xmt & int ena,netwk,syn,sclk==inp,msb 1st
	movep   #$3800,x:IPR    ; set interrupt priority level
	movep   #$FFE8,x:PCC    ; Turn on ssi port
	move    #$2800,r5       ; Memorypointer Receive
	move    #$2000,r4       ; Memorypointer Transmit
	move    #$2FF8,x1       ; Rundungswert fÅr Speicher-Synchronisation
	move    r5,r3
        move    #-1,m0
        move    #-1,m1
        move    #-1,m2
	move    #$FFF,m3        ; Modulo mixpointer 4KB = $2000 - $2FFF
	move    #$FFF,m4        ; Modulo Transmit 4KB = $2000 - $2FFF
	move    #$FFF,m5        ; Modulo Receive 4KB = $2000 - $2FFF
        move    #-1,m7
        move    #receive,r0     ; receive start

yreadhx jclr    #0,x:HSR,noreadhx      ; HX-Receive full ?
        movep   x:HRX,a                ; Read out received data to buffer.
        nop
        nop
        jmp     yreadhx
noreadhx
        movep   #5,x:HCR        ; host interrupt enable
	andi    #$FC,mr         ; enable interrupts

main    move    r5,a
	and     x1,a    r3,y0
	cmp     y0,a
	jeq     main
        move    #level,r2                   ; leveltabelle
        move    #peaks,r1
        move    #bypass,r7

        move    x:mode,y1
        jclr    #2,y1,mixer8               ; 8 channels ?

        move    x:(r2)+,y0                  ; level ersten Kanal holen
        move    r3,x:(r6)+                  ; framestart merken
        jsr     mixer16                    ; mix channels 1..8
        move    x:-(r6),r3                  ; framestart holen
        nop
        move    x:(r3)+,y1                  ; goto Daten Kanal9
        jsr     mixer16                    ; mix channels 9..16
        move    x:-(r3),y1                  ; dummy goto frame_start_next
        move    r3,x:(r6)+
        move    #routbuf+16,r1
        do      #16,cpyblkx
        move    x:-(r3),y1
        move    y1,x:-(r1)
cpyblkx move    r3,y0
        move    #routes,r2
        jsr     xroute                 ; route ch1..8
        move    #routbuf+1,r1
        jsr     xroute                 ; route ch9..16
        move    x:-(r6),r3
	jmp     main

xroute  do      #8,dorut16
        move    x:(r2)+,a              ; get routechannel 
        move    x:(r1)+,x0             ; get routbuf1,goto routbuf9
        move    a,b
        move    #>$0008,y1
        and     y1,a
        jeq     low16
        sub     y1,b   
        lsl     b       #>$0001,y1
        add     y1,b    y0,a
        jmp     rout16
low16   lsl     b       y0,a 
rout16  add     b,a     x:(r1)+,y1      ; goto routbuf2
        move    a,r3
        nop
        move    x0,x:(r3)              ; copy data to destination
dorut16 rts

mixer16 do      #8,chnlx16
        jclr    #0,x:(r7)+,chnl_a           ; bypass channel ?
        jsr     xbypass
        jmp     chnl_xa
chnl_a  move    x:(r3),y1                   ; Daten Kanal1 holen
        move    x:(r1)+,x0                  ; peakwert1 holen,goto peakwert2
        mpyr    y0,y1,a       x:mlevel,y0   ; level1 anpassen,mlevel holen
        asl     a                   
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; an mlevel anpassen,level2 holen 
        asl     a                                       
        move    a,x:(r3)+                   ; Kanal1 retten,goto Kanal9
        cmp     x0,a            x:(r3)+,y1  ; goto Kanal2 
        jle     chnl_xa
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
chnl_xa nop
chnlx16 rts

mixer8  move    x:(r2)+,y0                  ; level ersten Kanal holen
        do      #8,mixex8 
        jclr    #0,x:(r7)+,mixr8a           ; bypass channel ?
        jsr     rbypass
        jmp     mixr8b 
mixr8a  move    x:(r3),y1                   ; Daten Kanal1 holen
        move    x:(r1)+,x0                  ; peakwert1 holen,goto peakwert2
        mpyr    y0,y1,a       x:mlevel,y0   ; level1 anpassen,mlevel holen
        asl     a
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; an mlevel anpassen,level2 holen
        asl     a
        move    a,x:(r3)+                   ; Kanal1 retten,goto Kanal2
        cmp     x0,a
        jle     mixr8b
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
mixr8b  nop
mixex8  move    r3,x:(r6)+
        move    #routbuf+8,r1
        do      #8,cpy_blk
        move    x:-(r3),y1
        nop
        move    y1,x:-(r1)
cpy_blk nop
        move    r3,y0
        move    #routes,r2
        do      #8,doroute
        move    x:(r1)+,x0             ; get sourcedata
        move    x:(r2)+,b              ; get routechannel 
        move    y0,a                   ; get bufstart
        nop
        add     b,a                    ; destdata
        nop
        move    a,r3
        nop
        move    x0,x:(r3)              ; copy data to destination
doroute nop
        move    x:-(r6),r3
	jmp     main

rbypass move    x:(r2)+,y0                  ; level ersten Kanal holen
        move    x:(r3)+,a                   ; Daten Kanal1 holen
        move    x:(r1)+,x0                  ; peakwert1 holen,goto peakwert2
        cmp     x0,a            
        jle     rbypex
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
rbypex  rts

xbypass move    x:(r2)+,y0                  ; level ersten Kanal holen
        move    x:(r3)+,a                   ; Daten Kanal1 holen,goto Kanal9
        move    x:(r1)+,x0                  ; peakwert1 holen,goto peakwert2
        cmp     x0,a            x:(r3)+,y1  ; goto Kanal2
        jle     xbypb
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
xbypb   rts

ssi_rx_isr
	jset    #3,x:SSISR,frame_rx      ; Frame-Erkennung
	movep   x:SSIDR,x:(r5)+          ; Read out received data to buffer
	rti
frame_rx 
	move    a,x:(r6)+              ; Save to the stack.
	move    r5,a
	and     x1,a                     ; 1.Slot->Speicher synchonisieren
	move    a,r5                   
	move    x:-(r6),a
	movep   x:SSIDR,x:(r5)+          ; Read out received data to buffer
	rti

ssi_tx_isr
	jset    #2,x:SSISR,frame_tx      ; Frame-Erkennung
	movep   x:(r4)+,x:SSIDR           ; read out buffer and transmit
	rti
frame_tx
	move    b,x:(r6)+              ; Save to the stack.
	move    r4,b
	and     x1,b                     ; 2.Slot->Speicher synchronisieren
	move    b,r4                     ; auf ersten Slot runden
	nop
	move    x:(r4)+,b                ; wir sind aber im zweiten Slot
	move    x:-(r6),b
	movep   x:(r4)+,x:SSIDR          ; read out buffer and transmit
	rti                         

host_rx_isr
        move    a,x:(r6)+               ; Save r5 to the stack.
        move    x:HRX,a
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
        nop
        move    x:(r0)+,b              ; level-number (field 0)
        nop
        move    x:(r0),x0              ; level (field 1)
        move    #level,a
        nop
        add     b,a
        nop
        move    a,r0
        nop
        move    x0,x:(r0)
        nop
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

set_route                               ; set route
        move    a,x:(r6)+
        move    b,x:(r6)+
        move    x0,x:(r6)+
        move    #receive,r0
        nop
        move    x:(r0)+,b              ; level-number (field 0)
        nop
        move    x:(r0),x0              ; level (field 1)
        move    #routes,a
        nop
        add     b,a
        nop
        move    a,r0
        nop
        move    x0,x:(r0)
        nop
        move    #receive,r0
        move    x:-(r6),x0
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
        move    #mode,r0
        nop
        move    x0,x:(r0)
        move    #receive,r0
	move    #$2800,r5       ; Memorypointer Receive
	move    #$2000,r4       ; Memorypointer Transmit
        jset    #2,x0,mode16    ; 16 channels ?
	move    #$2FF8,x1       ; Rundungswert fÅr Speicher-Synchronisation
        jset    #1,x0,bit24     ; 24bit ?
        movep   #$4700,x:CRA    ; 16bits,8 word/frame
        jmp     modend
bit24   movep   #$6700,x:CRA    ; 24bits,8 word/frame
modend  move    x:-(r6),x0
        rti
mode16  move    #$2FF0,x1       ; Rundungswert fÅr Speicher-Synchronisation
	move    #$2800,r5       ; Memorypointer Receive
	move    #$2000,r4       ; Memorypointer Transmit
        jset    #1,x0,bit24b    ; 24bit ?
        movep   #$4F00,x:CRA    ; 16bits,16 word/frame
        jmp     modend
bit24b  movep   #$6F00,x:CRA    ; 24bits,16 word/frame
        jmp     modend


	org     x:$50

mode    dc      $0

bypass  dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0

level   dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
        dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
mlevel  dc      $1FFF00
	dc      $1FFF00

peaks   dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0

routes  dc      $0
        dc      $1
        dc      $2
        dc      $3
        dc      $4
        dc      $5
        dc      $6
        dc      $7
        dc      $8
        dc      $9
        dc      $a
        dc      $b
        dc      $c
        dc      $d
        dc      $e
        dc      $f

routbuf dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0
        dc      $0


receive 


	end
