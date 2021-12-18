;****************************************************************************
;LOWPASS : LOW PASS FILTERING FOR THE DSP56002EVM 
;PASS IT THROUGH A LOW-PASS-FILTER  
;patched for VME-Card STARTRACK
;ohne Ringbuffer
;***************************************************************************



START   EQU     $40
LINEAR  EQU     $FFFF

        org     x:$20           ; !Wichtig! wegen RX/TX Buffer
coefs   dc      0.00370753      ;b10
        dc      0.5             ;scaling factor
        dc      0.00741518      ;b11
        dc      0.83384359      ;a11
        dc      0.00370753      ;b12
        dc      -0.34867418     ;a22
     

        dc      0.00485158      ;b20
        dc      0.5             ;scaling factor
        dc      0.00970316      ;b21
        dc      0.86615109      ;a21
        dc      0.00485158      ;b22
        dc      -0.38555753     ;a22
        
        org     y:$10
rtdelay bsc     4,$0            ;used to store information for filter
ltdelay bsc     4,$0
tempstore
        ds      1


        org     p:$0
        jmp     START

        org     p:$000c
        jsr     ssi_rx_isr      ;SSI receive data
        jsr     ssi_rx_isr      ;SSI receive data with exception
        jsr     ssi_tx_isr      ;SSI transmit data
        jsr     ssi_tx_isr      ;SSI transmit with exception

        org     p:START

        movep   #0000,x:BCR     ;ada_init.asm program
        ori     #3,mr           ;mask interrupts
        movec   #0,sp           ;clear hardware stack pointer
        move    #0,omr          ;operating mode 0
        move    #$40,r6         ; initialise stack pointer
        move    #-1,m6          ; linear addressing

        include 'ada_vme.asm'       ; neuer SSI-Initializer 
        
wait2
        jset    #1,x:SSISR,*            ; warten auf Wechsel Links1->Rechts0
        jclr    #1,x:SSISR,*            ; warten auf Wechsel Rechts0->Links1
        jset    #6,x:SSISR,*            ; wait transceiver empty

        move    x:RX_BUFF_BASE+1,a        ;receive left
        move    x:RX_BUFF_BASE,b          ;receive right
        jsr     process_stereo
        move    a,x:TX_BUFF_BASE+1        ;transmit left
        move    b,x:TX_BUFF_BASE          ;transmit right
wait
        jmp     wait2                   ;go back to the beginning


process_stereo
        move    #ltdelay,r0             ;set up pointer
        jsr     filter                  ;filter the left sample
        move    a,y:tempstore           ;save filtered left sample
        move    b,a                     ;move right sample
        move    #rtdelay,r0             ;set up pointer
        jsr     filter                  ;filter the right sample
        move    a,b                     ;filtered right into b
        move    y:tempstore,a           ;filtered left into a
        rts

filter
        move    #LINEAR,m0              ;linear addressing
        move    m0,m4
        ori     #$08,mr                 ;set scaling mode  
        asr     a       #coefs,r4       ;r4=pointer to coefficients
        move    a,x0    y:(r0)+,a
        asr     a       x:(r4)+,x1
        macr    x1,x0,a x:(r4)+,x1      y:(r0)-,y0
        mpy     y0,x1,a a,y1            x:(r4)+,x1
        mac     x0,x1,a x:(r4)+,x1
        macr    y1,x1,a x:(r4)+,x1
        mpy     x1,x0,a x:(r4)+,x1      a,y:(r0)+
        macr    y1,x1,a 
        tfr     y1,a    x:(r4)+,x0      a,y:(r0)+
        andi    #$f3,mr
        rts

        include 'txrx_vme.asm'   ; neuer Interrupt-Treiber

        end

