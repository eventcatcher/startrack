;****************************************************************************
;PASSTHRU : PASS-THRU FOR THE DSP56002EVM 
;WILL PASS AUDIO STRAIGHT THROUGH 
;patched for VME-Card STARTRACK
;ohne Ringbuffer
;***************************************************************************



START   EQU     $40

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
        move    a,x:TX_BUFF_BASE+1        ;transmit left
        move    b,x:TX_BUFF_BASE          ;transmit right
wait
        jmp     wait2                   ;go back to the beginning

        include 'txrx_vme.asm'   ; neuer Interrupt-Treiber

        end

