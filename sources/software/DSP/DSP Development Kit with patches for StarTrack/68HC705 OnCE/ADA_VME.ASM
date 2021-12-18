	page    132,60
;****************************************************************************
;       ADA_INIT.ASM
;       Initialization program for the Crystal Semi. CS4215 A/D &
;          D/A Converters
;
; patched for VME-Card STARTRACK
; Initialize the SSI and the Buffers for A/D CS5339 and D/A CS4328
; Normal Mode,16Bits,Word-Sync,synchron
;
;       NOTES:
;          1-  The DSP5002EVM analog inputs are connected to "MIC"
;                input pins only.  The "LINE" input pins are connected
;                to analog GROUND.  Line level inputs are supported
;                by disabling the 20 dB Microphone Pre-Amplifier.
;          2-  As shipped, the DSP56002EVM has a 24.576 MHz crystal
;                connected to the XTAL2 inputs of the CD4215.  Do
;                not select any other clock source unless the board
;                has been modified to support the alternate clock
;                source(s).
;
;
;       Copyright (c) MOTOROLA 1995
;                     Semiconductor Products Sector 
;                     Digital Signal Processing Division
;
;****************************************************************************
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


;----------------------------------------------------------------------------
; The two buffers which are defined below are the source and
; destination storage for the codec Input/Output ISRs
;----------------------------------------------------------------------------
       org    x:$50   ; war 0
TX_BUFF_BASE    equ     *
		ds      16       ;Buffer or Ringbuffer RX ISR

RX_BUFF_BASE    equ     *
		ds      2        ;Buffer for TX ISR

TX_PTR          ds      1       ; Pointer for rx buffer
RX_PTR          ds      1       ; Pointer for tx buffer

;***************************************************************************
;*****                  initialize the CS4215 codec                    *****
;***************************************************************************
;   1.  Configure the SSI port and the GPIO lines used (D/C~ & Reset)
;   2.  Program SSI to receive Frame Sync and Clock
;   3.  Enable SSI port
;***************************************************************************
;
;
	org     p:
codec_init
	move    #RX_BUFF_BASE,x0
	move         x0,x:RX_PTR             ; Initialize the rx pointer
	move    #RX_BUFF_BASE+16,x0
	move         x0,x:TX_PTR             ; Initialize the tx pointer


;----- initialize SSI -----
; Assuming the DSP56002 is running at 40 MHz,  this section selects a
;   2.5 MHz SSI clock to be sent from the 56002's SSI clock circuit 
;   to the codec.  It also sets up 64-bit frame length (4 words per
;   frame x 16-bits per word), enables SSI TX & RX, enables TX & RX
;   interrupts and synchronous operation with bit-length frame sync.
;----------------------------------------------------------------------------
	movep   #$0000,x:PCC    ; turn off ssi port 
	movep   #$0,x:PCDDR     ; setup pc0-pc8 as inputs
	movep   #$4000,x:CRA    ; 16bits,1 word/frame, /2/4/2=2.5 MHz
	movep   #$F200,x:CRB    ; rcv,xmt & int ena,netwk,syn,sclk==inp,msb 1st
	movep   #$3000,x:IPR    ; set interrupt priority level
	movep   #$FFE8,x:PCC    ; Turn on ssi port
	andi    #$FC,mr         ; enable interrupts
