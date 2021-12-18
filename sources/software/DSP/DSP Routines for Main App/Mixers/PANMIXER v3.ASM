;****************************************************************************
;       PANMIXER.ASM    Rev.1.0
;
; for STARTRACK DSP56002-66
; 
; Mischer mit Volumecontrol,Pan & Route
;
; support: 8ch x 16bit (normal,sum24)
;          8ch x 24bit
;         16ch x 16bit (normal,sum24)
;         16ch x 24bit
;
; mischt die KanÑle zu Stereosumme zusammen und gibt sie auf den 
; Master-Route-KanÑlen aus
;
; empfÑngt KanÑle im Network-Mode,asynchron, external Clk 
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


START   equ     $80

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
        move    #0,x0
        move    #-1,m7
        move    #receive,r0     ; receive start
        move    x0,x:mode

yreadhx jclr    #0,x:HSR,noreadhx      ; HX-Receive full ?
        movep   x:HRX,a                ; Read out received data to buffer.
        jmp     yreadhx
noreadhx
        movep   #5,x:HCR        ; host interrupt enable
	andi    #$FC,mr         ; enable interrupts

rstseq  move    #$2800,r5       ; Memorypointer Receive
	move    #$2000,r4       ; Memorypointer Transmit
	move    r5,r3
        bclr    #8,x:mode       ; restart-sequenz ausfuehren

main    move    r5,a
	and     x1,a    r3,y0
	cmp     y0,a
	jeq     main
        clr     a       #level,r2           ; liste lautstÑrke
        clr     b       #peaks,r1           ; liste peakmeter-maximalwerte
        move    x:(r2)+,y0                  ; level1 holen
        move    x:mode,y1
        nop
        jset    #8,y1,rstseq                ; restart-sequenz ausfuehren
        jset    #2,y1,mixal16               ; 16 channels ?
        nop
        jmp     mixall8

mixal16 move    r3,x:(r6)+                  ; framestart retten
        jsr     mixit16                     ; mix channels 1..8
        move    r3,y1                       ; next framepos merken
        move    x:-(r6),r3                  ; framestart holen
        move    y1,x:(r6)+                  ; next framepos retten
        move    y1,x:(r6)+                  ; next framepos retten
        move    x:(r3)+,y1                  ; goto Daten Kanal9
        jsr     mixit16                     ; mix channels 1..8
        move    x:-(r6),r3                  ; next framepos holen
        move    x:(r1)+,x0                  ; masterpeak1 holen
        jset    #0,x:(r7),nxbypm1           ; bypass masterchannels ?
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; masterlev1 anpassen,masterlev2 holen
        asl     a               b,y1
nxbypm1 cmp     x0,a
        jle     lowmx1
        move    a,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lowmx1  move    x:(r1)+,x0                  ; master2-peakwert holen
        jclr    #0,x:(r7),nxbypm2           ; bypass masterchannels ?
        jmp     nxbypm3
nxbypm2 mpyr    y0,y1,b                     ; masterlev2 anpassen
        asl     b                    
nxbypm3 cmp     x0,b            #0,y1
        jle     lowmx2
        move    b,x:-(r1)                   ; peakwert speichern
lowmx2  move    x:mode,y0
        nop
        jset    #1,y0,xput24       ; 24bit ?
        do      #16,clsxblk
        move    y1,x:-(r3)                  ; Frameout lîschen
clsxblk jset    #0,y0,xsumme       ; 24bit-summe ?
        move    r3,y0
        move    #routes+16,r1
        move    a,y1
        move    x:(r1)+,a
        add     y0,a
        nop
        move    a,r3
        nop
        move    y1,x:(r3)+                  ; mix 1+3+5+7->Slot 1,goto Slot9
        nop
        move    x:(r3)+,y1                  ; dummy goto Slot2
        nop
        move    b,x:(r3)                    ; mix 2+4+6+8 in Slot 2 speichern
        jmp     xainend
xsumme  move    a,x:(r3)+                   ; mix in Slot 1 (MSB16) speichern
        move    a,y1
        move    #$8000,y0
        mpy     y0,y1,a
        move    a0,x:(r3)+                  ; mix in Slot 2 (LSB8) speichern
        move    #0,y0
        move    y0,x:(r3)+                  ; Slot 3 nullen
        move    y0,x:(r3)+                  ; Slot 4 nullen
        move    y0,x:(r3)+                  ; Slot 5 nullen
        move    y0,x:(r3)+                  ; Slot 6 nullen
        move    y0,x:(r3)+                  ; Slot 7 nullen
        move    y0,x:(r3)+                  ; Slot 8 nullen
        move    b,x:(r3)+                   ; mix in Slot 9 (MSB16) speichern
        move    b,y1
        move    #$8000,y0
        mpy     y0,y1,a
        move    a0,x:(r3)+                  ; mix in Slot 10 (LSB8) speichern
        jmp     xainend
xput24  move    y1,x:-(r3)                  ; Frameout1 lîschen
        move    y1,x:-(r3)                  ; Frameout2 lîschen
        move    y1,x:-(r3)                  ; Frameout3 lîschen
        move    y1,x:-(r3)                  ; Frameout4 lîschen
        move    y1,x:-(r3)                  ; Frameout5 lîschen
        move    y1,x:-(r3)                  ; Frameout6 lîschen
        move    y1,x:-(r3)                  ; Frameout7 lîschen
        move    b,x:-(r3)                   ; Frame8 is left output
        move    y1,x:-(r3)                  ; Frameout9 lîschen
        move    y1,x:-(r3)                  ; Frameout10 lîschen
        move    y1,x:-(r3)                  ; Frameout11 lîschen
        move    y1,x:-(r3)                  ; Frameout12 lîschen
        move    y1,x:-(r3)                  ; Frameout13 lîschen
        move    y1,x:-(r3)                  ; Frameout14 lîschen
        move    y1,x:-(r3)                  ; Frameout15 lîschen
        move    a,x:-(r3)                   ; Frame16 is right output
xainend move    x:-(r6),r3                  ; next framepos holen
xum_blk jmp     main

mixit16 do      #8,chnl16b
        move    x:(r1)+,x0                  ; peakwert1 holen
        move    x:(r3),y1                   ; Daten Kanal1 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; level1 anpassen,nc1 holen
        asl     a               x:(r2)+,y0  ; lpan1 holen
        cmp     x0,a            x:(r3),y1   ; test peak1,get Daten Kanal1
        jle     lowr3lx
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto peakwert2
lowr3lx mpy     y0,y1,a         x:(r2)+,y0  ; lpan1 anpassen,rpan1 holen
        asl     a                                        
        move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan1+mastr1,get Data1,goto Dat9
        rnd     a                           ; ergebnis runden,peakwert2 holen
        move    b,x:(r6)+                   ; ergebnis master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan1 anpassen,level2 holen
        asl     b               x:(r3)+,y1  ; get Data9,goto Daten Kanal2 
        move    x:-(r6),x0                  ; master2 holen
        add     x0,b                        ; rpan1+master2
        rnd     b                           ; ergebnis runden               
chnl16b rts

mixall8 do      #8,chnlx8a
        move    x:(r1)+,x0                  ; peakwert1 holen
        move    x:(r3),y1                   ; Daten Kanal1 holen
        move    a,x:(r6)+                   ; ergebnis master1 retten
        mpy     y0,y1,a         x:(r2)+,y0  ; level1 anpassen,nc1 holen
        asl     a               x:(r2)+,y0  ; lpan1 holen
        cmp     x0,a            x:(r3),y1   ; test peak1,get Daten Kanal1
        jle     lower3l
        move    a,x:-(r1)                   ; peakwert1 speichern
        move    x:(r1)+,x0                  ; dummy goto peakwert2
lower3l mpy     y0,y1,a         x:(r2)+,y0  ; lpan1 anpassen,rpan1 holen
        asl     a                                        
        move    x:-(r6),x0                  ; master1 holen
        add     x0,a            x:(r3)+,y1  ; lpan1+master1,Daten Kanal1 holen
        rnd     a                           ; ergebnis runden                
        move    b,x:(r6)+                   ; ergebnis master2 retten
        mpy     y0,y1,b         x:(r2)+,y0  ; rpan1 anpassen,level2 holen
        asl     b
        move    x:-(r6),x0                  ; master2 holen
        add     x0,b                        ; rpan1+master2             
        rnd     b                           ; ergebnis runden                
chnlx8a move    #level+64,r2                ; liste masterlautstÑrke
        move    #peaks+16,r1                ; liste master peak-maximalwerte
        move    #bypass+16,r7               ; liste master-bypass
        move    x:(r1)+,x0                  ; peakwert holen
        move    x:(r2)+,y0                  ; masterlevel1 holen
        jset    #0,x:(r7),nobypm1           ; bypass masterchannels ?
        move    a,y1
        mpyr    y0,y1,a         x:(r2)+,y0  ; masterlev1 anpassen,masterlev2 holen
        asl     a               b,y1
nobypm1 cmp     x0,a
        jle     lowm1
        move    a,x:-(r1)                   ; peakwert speichern
        move    x:(r1)+,x0                  ; dummy goto next peakwert
lowm1   move    x:(r1)+,x0                  ; master2-peakwert holen
        jclr    #0,x:(r7),nobypm2           ; bypass masterchannels ?
        move    r3,x:(r6)+
        jmp     nobypm3
nobypm2 mpyr    y0,y1,b         r3,x:(r6)+  ; masterlev2 anpassen
        asl     b                    
nobypm3 cmp     x0,b            #0,y1
        jle     lowm2
        move    b,x:-(r1)                   ; peakwert speichern
lowm2   move    x:mode,y0
        nop
        jset    #1,y0,put24       ; 24bit ?
        do      #8,cls_blk
        move    y1,x:-(r3)                  ; Frameout lîschen
cls_blk jset    #0,y0,summe       ; 24bit-summe ?
        move    r3,y0
        move    #routes+16,r1
        move    a,y1
        move    x:(r1)+,a
        add     y0,a
        nop
        move    a,r3
        nop
        move    y1,x:(r3)                    ; mix 1+3+5+7 in Slot 5 speichern
        move    x:(r1),a
        add     y0,a
        move    a,r3
        nop
        move    b,x:(r3)                    ; mix 2+4+6+8 in Slot 6 speichern
        jmp     mainend
summe   move    a,x:(r3)+                   ; mix in Slot 1 (MSB16) speichern
        move    a,y1
        move    #$8000,y0
        mpy     y0,y1,a
        move    a0,x:(r3)+                  ; mix in Slot 2 (LSB8) speichern
        move    #0,y0
        move    y0,x:(r3)+                  ; Slot 3 nullen
        move    y0,x:(r3)+                  ; Slot 4 nullen
        move    b,x:(r3)+                   ; mix in Slot 5 (MSB16) speichern
        move    b,y1
        move    #$8000,y0
        mpy     y0,y1,a
        move    a0,x:(r3)+                  ; mix in Slot 6 (LSB8) speichern
        jmp     mainend
put24   move    y1,x:-(r3)                  ; Frameout1 lîschen
        move    y1,x:-(r3)                  ; Frameout2 lîschen
        move    y1,x:-(r3)                  ; Frameout3 lîschen
        move    b,x:-(r3)                   ; Frame4 is left channel
        move    y1,x:-(r3)                  ; Frameout5 lîschen
        move    y1,x:-(r3)                  ; Frameout6 lîschen
        move    y1,x:-(r3)                  ; Frameout7 lîschen
        move    a,x:-(r3)                   ; Frame8 is right channel
mainend move    x:-(r6),r3
dum_blk jmp     main

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

set_route                               ; set route
        move    a,x:(r6)+
        move    b,x:(r6)+
        move    x0,x:(r6)+
        move    #receive,r0
        move    #routes,a
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
        ori     #3,mr                   ; disable interrupts
        move    x0,x:(r6)+
        move    #receive,r0
        nop
        move    x:(r0),x0          ; mode-word
        nop
        bset    #8,x0              ; cookie fuer restart-sequence
        move    #mode,r0
        nop
        move    x0,x:(r0)
        move    #receive,r0
	move    #$2800,r5       ; Memorypointer Receive
	move    #$2000,r4       ; Memorypointer Transmit
	move    r5,r3
        jset    #2,x0,mode16    ; 16 channels ?
	move    #$2FF8,x1       ; Rundungswert fÅr Speicher-Synchronisation
        jset    #1,x0,bit24     ; 24bit ?
        movep   #$4700,x:CRA    ; 16bits,8 word/frame
        jmp     modend
bit24   movep   #$6700,x:CRA    ; 24bits,8 word/frame
modend  move    x:-(r6),x0
	andi    #$FC,mr         ; enable interrupts
        nop
        rti
mode16  move    #$2FF0,x1       ; Rundungswert fÅr Speicher-Synchronisation
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
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
	dc      $1FFF00
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
        dc      $0
        dc      $1

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
