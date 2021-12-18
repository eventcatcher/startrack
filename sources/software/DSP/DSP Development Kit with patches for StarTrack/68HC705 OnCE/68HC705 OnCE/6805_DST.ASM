.header "68HC705 OnCE Interface"        ;depends on assembler
.pagewidth 80t                         ;ditto

*************************************************************************
*       Program Name: 6805_DST.ASM                                      *
*       Revision: 1.1                                                   *
*                                                                       *
*       OnCE interface section:                                         *
*       Date April 25, 1994                                             *
*       Written by:  David Horton, Motorola Digital Signal              *
*               Processing Division, 24/32-bit Applications             *
*                                                                       *
*       SCI interface section:                                          *
*       Date August 27, 1992                                            *
*       Written by: Craig Haller, P&E Microcomputer Systems             *
*       Modified by: Dan Bernard, Motorola CSIC Applications            *
*       Modified by: Roman Robles, Motorola Digital Signal              *
*                Processing Division, 24/32-bit Applications            *
*                                                                       *
*       Semi-Final code - June 3, 1994                                  *
*       Final code - July 30, 1994                                      *
*       Fix transmitted parity bit width - Oct. 24, 1994                *
*************************************************************************
*************************************************************************
*       This is code for the 68HC705K1 to act as a simple interface     *
*       between the OnCE port and an RS232 serial port on any computer  *
*                                                                       *
*       This interface is intended to be extremely inexpensive. The     *
*       68HC705K1 was chosen for its low cost and small package size    *
*       (16 pin SOIC and DIP).                                          *
*                                                                       *
*       The following code is primarily hardware port bit               *
*       manipulation to operate the DSP OnCE port.                      *
*       Other GPIO lines accomplish a simple serial port entirely       *
*               in software.                                            *
*                                                                       *
*       The 68705 connections are:                                      *
*                1) Reset  -  tied to a simple RC reset circuit.        *
*                2) PB1 - curently unused. Previous versions            *
*                       used this pin as a CTS or DCD pin               *
*                3) PB0 - This is the data output for serial data to    *
*                       the host.                                       *
*                4) IRQ/Vpp - This is the received data from the RS232  *
*                       converter. Am just sensing this bit and         *
*                       branching on the state, this function could be  *
*                       placed on a GPIO line instead.                  *
*                5) PA0 - This bit is the DSI/OS0 bit, it is used as    *
*                       an input to read one of the DSP status pins     *
*                       when not in debug, and as the data output to    *
*                       the OnCE port when in debug mode.               *
*                6) PA1 - This bit is the DSCK/OS1 bit, it is used as   *
*                       an input to read one of the DSP status pins     *
*                       when not in debug, and as the clock output to   *
*                       the OnCE port when in debug mode.               *
*                7) PA2 - This bit senses the output state of the ACK   *
*                       latch, a hardware SR flip-flop constructed of   *
*                       two NAND gates. The 68HC705 is not fast enough  *
*                       to read the ACK pulse, which is produced on     *
*                       the DSO line, so it is latched.                 *
*                8) PA3 - This bit is the DSO bit, reads the data       *
*                       from the OnCE data output pin.                  *
*                9) PA4 - This bit, when cleared and then set, resets   *
*                       the ACK latch.                                  *
*               10) PA5 - This bit controls the DSP OnCE /DR (debug     *
*                       request) line. On initialization, it is         *
*                       configured as an output to control the DSP /DR  *
*                       pin. Since this pin is driven by an 8 mA output *
*                       driver, it has no problem controlling /DR.      *
*               11) PA6 - This bit controls the DSP /RST (reset) line.  *
*               12) PA7 - This bit controls the DEBUG LED. It is set    *
*                       by the 68705 when the DSP is not in debug, and  *
*                       cleared to illuminate the LED when in debug     *
*                       mode. The 68HC705K1 can sink 8 ma, but can      *
*                       only source 0.8 ma.                             *
*               13) Vcc - +5 volts DC.                                  *
*               14) Gnd -                                               *
*               15) OSC2 - nc                                           *
*               16) OSC1 - Connected to 4.0 MHz clock.                  *
*                                                                       *
*       In this application, the 68HC705 also acts as a reset           *
*       controller for the DSP, holding it in reset until the 68HC705   *
*       has completed its initialization. Resetting the 68HC705 will    *
*       automatically reset the DSP as well, since this line becomes    *
*       a 68705 high-impedance input, with a (rather weak) pulldown     *
*       resistor attached.                                              *
*                                                                       *
*       The 68705 interfaces to the DSP OnCE port by controlling the    *
*       /DR line and by shifting data in and out of registers in the    *
*       DSP's OnCE section. Data is shifted into the OnCE by setting    *
*       one port A GPIO line to the desired bit state and raising       *
*       and lowering another GPIO line to act as a clock, shifting      *
*       the bit in. Reading is the inverse of this.                     *
*                                                                       *
*       The user is invited to spend much time with the DSP56K Family   *
*       Manual, Section 10 for more information about the subtleties    *
*       of the OnCE port.                                               *
*                                                                       *
*************************************************************************
*************************************************************************
*       Revision History:                                               *
*       0.1 - OnCE interface code written for the PC printer port,      *
*               bit-banging working, learned about subtleties of the    *
*               OnCE port.                                              *
*       0.2 - Ported to the 68HC705 microcontroller. Obtained RS232     *
*               bit-banger code from Motorola CSIC group. First OnCE    *
*               code written - 4/13/94.                                 *
*       0.3 - OnCE code revised and optimized and main control section  *
*               added (4/18/94). Moved code around to reduce lengths    *
*               of jumps/branches.                                      *
*       0.4 - OnCE and main control sections operational and tested.    *
*               Adding in additional features and finding further ways  *
*               to compact the code (4/25/94). No RS232 section yet.    *
*       0.5 - First merger of all three sections of the code. Added in  *
*               get_char and put_char from the echo complement test     *
*               code.                                                   *
*       0.6 - Parity checking fixed. One-byte commands seeem to be      *
*               working.                                                *
*       0.7 - Alpha version believed correct (6/30/94)                  *
*       1.0 - Everything working, debugged, working with host code,     *
*               error catching installed (7/30/94)                      *
*       1.1 - Transmitted parity bit was too short, caused framing      *
*               errors on some machines, fixed to have proper length.   *
*               Also changed to 19,200 baud                             *
*                                                                       *
*************************************************************************
*************************************************************************
*                                                                       *
*       The memory map of the 68HC705K1 is:                             *
*                                                                       *
*               $0000 - $001F   I/O registers                           *
*               $0020 - $00DF   unused                                  *
*               $00E0 - $00FF   RAM - 32 bytes - variables and stack    *
*               $0100 - $01FF   unused                                  *
*               $0200 - 03EF    EPROM - system code                     *
*               $03F0           COP register                            *
*               $03F1 - $03F7   unused                                  *
*               $03F8 - $03FD   Timer, Ext IRQ, SWI vectors             *
*               $03FE - $03FF   Reset vector                            *
*                                                                       *
*       The Mask Option Register at $0017 is programmed to $00,         *
*       indicating:                                                     *
*              pulldowns resistors enabled on both port A and port B,   *
*                    unless overridden by software (and I don't)        *
*              oscillator configured as a two-pin oscillator, i.e.      *
*                    PB1 is available for use as a GPIO pin             *
*              oscillator is configured to accept external clock input  *
*              STOP instruction is not converted to WAIT instruction    *
*              PA0-PA3 pins not configured for external interrupt       *
*              the low-voltage reset is disabled                         *
*              interrupt pins are edge-triggerred rather than edge-     *
*                    and-level-triggered                                *
*              COP watchdog is disabled                                 *
*                                                                       *
*        The 64-bit personality EPROM is not used                       *
*                                                                       *
*************************************************************************


********************************** Equates ******************************

porta           equ     $00             ;port "A"
portb           equ     $01             ;port "B"
ddra            equ     $04             ;port A data direction register
ddrb            equ     $05             ;port B data direction register
TSCR            EQU     $08
TCNTR           EQU     $09
ISCR            EQU     $0A
PEBSR           EQU     $0E
PESCR           EQU     $0F
PDRA            EQU     $10
PBRB            EQU     $11
MOR             EQU     $17             ;mask option register - $08
EPROG           EQU     $18
TESTRE          EQU     $1F
COPR            EQU     $03F0           ;COP watchdog register - not used



;       PORT A BITS
DATA_To_OnCE    EQU     0               ;outputs data to the DSP DSI line
STAT0_BIT       EQU     0               ;reads the DSI line as a status pin
CLK_BIT         EQU     1               ;connects to the DSP DSCK line
STAT1_BIT       EQU     1               ;reads the DSCK line as a status pin
ACK_BIT         EQU     2               ;reads the output of the ACK latch
DATA_From_OnCE  EQU     3               ;read the data from the DSP DSO line
ACK_RST_BIT     EQU     4               ;resets the ACK latch
DR_BIT          EQU     5               ;connected to the DSP /DR pin
OPT_BIT         EQU     5
DSP_RST_BIT     EQU     6               ;connected to the DSP /RESET pin
DEBUG_LED_BIT   EQU     7               ;also used as an 'in debug' flag
;
;       PORT B BITS
TXD_BIT         EQU     0               ;RS232 data is transmitted via this pin
BUSY_BIT        EQU     1               ;operates as a CTS pin
;
;       OnCE COMMAND REGISTER BITS
EX_BIT          EQU     5               ;the OnCE CR EXit bit, here read to
                                        ;see if the DSP will exit debug state
;
;

******************************* Memory Equates **************************

ram             equ     $00E0           ;beginning of ram
rom             equ     $0200           ;beginning of rom
reset           equ     $03FE           ;reset vector location
vectors         equ     $03F8           ;other vectors

******************************** Other Equates **************************

Half_Bit_time    equ     $06             ;19200 baud at 2 Mhz bus
Full_Bit_time    equ     $0B             ;19200 baud
Parity_Bit_time  equ     $0F             ;19200 baud

ACK_TIME        equ      $60             ;just a random time for acknowledge
CUR_REV_LVL     equ      $11             ;current revision level
;
;
**************************** Command Language ***************************
* This is the definition of the simple 'command language' used          *
* to communicate between the host computer and the 68705K1              *
*                                                                       *
*       Host commands to 68705:                                         *
* RD_CMD            execute a read from the OnCE register specified in  *
*                   the following CR byte and send it back to the host  *
*                   [2 byte packet/4 byte return]                       *
* WR_ONE_BYTE_CMD   write the following byte to the OnCE CR register    *
*                   [2 byte packet/1 byte ack packet]                   *
* WR_FOUR_BYTE_CMD  write the first following byte to the OnCE CR       *
*                   register, selecting a OnCE register to write to,    *
*                   then write the next three following bytes to it     *
*                   [5 byte packet/1 byte ack packet]                   *
* RST_OnCE_CMD      reset the OnCE port, reply with success or failure  *
*                   [1 byte packet/1 byte ack packet]                   *
* RST_DSP_CMD       reset the DSP                                       *
*                   [1 byte packet/No ack]                              *
* REQ_OnCE_CMD      request the OnCE port, putting the DSP into debug,  *
*                   reply with success or failure                       *
*                   [1 byte packet/1 byte return packet]                *
* REL_OnCE_CMD      release the OnCE port                               *
*                   [1 byte packet/1 byte ack packet]                   *
* RD_STAT_CMD       read the current DSP status (by reading all of      *
*                   porta), report it back to the host                  *
*                   [1 byte packet/[2 byte return packet]               *
* RST_68705_CMD     restart and reinitialize the 68705                  *
*                   [1 byte packet/No ack]                              *
* ARE_YOU_AWAKE     68705 replies if it is awake and accepting commands *
*                   [1 byte packet/1 byte return packet]                *
* WHAT_REV_LVL      68705 replies with its revision level               *
*                   [1 byte packet/1 byte return packet]                *
*                                                                       *
*       68705 replies to host [1 byte]:                                 *
* HUH_REPLY            didn't understand that last packet               *
* ACK_GOOD             received acknowledge from DSP                    *
* ACK_BAD              did not receive ack from DSP                     *
* NO_DSP_AWAKE         no DSP attached, or it is not responding         *
* OUT_OF_DEBUG         not in debug state                               *
* IN_DEBUG             in debug state                                   *
* INIT_192             68HC705 set for 19200 baud                       *
* HERES_SOME_DATA      1 to 384 bytes to follow                         *
* PAR_ERR_RPLY         saw a parity error with that last packet,        *
*                      resend it                                        *
*                                                                       *
*************************************************************************


;       Host commands to 68705:
RD_CMD                  equ     $A0
WR_ONE_BYTE_CMD         equ     $A1
WR_FOUR_BYTE_CMD        equ     $A2
RST_OnCE_CMD            equ     $A3
RST_DSP_CMD             equ     $A4
REQ_OnCE_CMD            equ     $A5
REL_OnCE_CMD            equ     $A6
RD_STAT_CMD             equ     $A7
RST_IN_DEBUG_CMD        equ     $A8
RST_68705_CMD           equ     $A9
CHG_OnCE_CLK_CMD        equ     $AA     ;not implemented
CHG_BAUD_CMD            equ     $AB     ;not implemented
ARE_YOU_AWAKE           equ     $AC
WHAT_REV_LVL            equ     $AD
EXEC_RAM_CMD            equ     $AE     ;not implemented
STORE_PARAMS_CMD        equ     $AF     ;not implemented

;       68705 replies to host:
HUH_REPLY               equ     $D0     ;didn't understand that last packet
ACK_GOOD                equ     $D1     ;received acknowledge from DSP
ACK_BAD                 equ     $D2     ;did not receive ack from DSP
NO_DSP_AWAKE            equ     $D3     ;no DSP attached, or it is not responding
OUT_OF_DEBUG            equ     $D4     ;not in debug state
IN_DEBUG                equ     $D5     ;in debug state
IM_AWAKE                equ     $D6     ;68HC705 awake and listening
HERES_SOME_DATA         equ     $D7     ;1 to 384 bytes to follow
PAR_ERR_RPLY            equ     $DF     ;saw a parity error with that last packet


****************************** Memory Allocation ************************


         org MOR                        ;setup MOR register
MOR_reg         rmb  $00

         org ram                        ;reserve memory variables

count           DS      1               ;bit counter used in put_char and get_char,
                                        ;also used to count OnCE reset attempts
parCnt          DS      1               ;0 = even number of ones, $FF = odd number
flagWd          DS      1				;holds several flags:
resBit              EQU     0           ;result bit, set if waitForAck times out
parityErr           EQU     1           ;set if a parity error was detected
;
;
FIRST_BYTE      DS      1
SECOND_BYTE     DS      1
THIRD_BYTE      DS      1
FOURTH_BYTE     DS      1
;
;
;       7 bytes are used above, and only a maximum of four interrupt levels
;       (2 bytes each) are needed, so 17 bytes of user RAM are unused
;

******************************* Initialization **************************
*                                                                       *
*   Initial porta data = 10110000 = $B0                                 *
*   Initial porta data direction = 11110000 = $F0                       *
*   Porta data direction w/ comm w/ OnCE enabled = 11110011 = $F3       *
*   Initial portb data = xxxxxx01 = $01                                 *
*   portb data direction = xxxxxx01 = $01                               *
*                                                                       *
*************************************************************************

        org     rom                      ;start of program area
;
;
start
        rsp                              ;reset the stack pointer
       ;clr     ISCR                     ;disable external interrupts
        clr     flagWd
;
        lda     #$B0                    ;init port a
        sta     porta
        lda     #$F0                    ;OS0 and OS1 are still inputs from the DSP
        sta     ddra                    ;DSP reset pulled low
        lda     #$01                    ;Only PB0 is an output
        sta     portb                   ;set it high initially
        sta     ddrb
        bsr     resetDSP                ;let the DSP come out of reset
                                        ;after a good long wait

******************************  main loop  ******************************

main    bclr    parityErr,flagWd
        jsr     get_char
        bsr     decodeCommand
        bra     main


****************************** OnCE Code ********************************

readByte
        ldx     #8
readBit                                         ;shifts another bit into a
        bset    CLK_BIT,PORTA                   ;raise clock line
        brset   DATA_From_OnCE,porta,$+3         ;set or clr carry
        rola                                    ;rotate into a
        bclr    CLK_BIT,PORTA                   ;lower clock line again
        decx
        bne     readBit
        rts                                     ;and the received byte is in a


resetDSP
        bclr    DSP_RST_BIT,porta               ;pull reset line low
        bset    DEBUG_LED_BIT,porta             ;turn off the LED
        bsr     resetAckLatch                   ;
        bsr     waitForAck                      ;just a dummy wait cycle - should time out
        bsr     waitForAck                      ;do it again,
                                                ;note that we do nothing with result
        bset    DSP_RST_BIT,porta               ;pull DSP reset line back high
        rts



rstIntoDebug
        bclr    DR_BIT,porta                   ;hold /DR low while resetting DSP
        bsr     resetDSP
        bsr     waitForAck
        bset    DR_BIT,porta
        jsr     rptAck                         ;drop through to resetOnCE, turning
                                               ;the LED back on, whether or not the
                                               ;DSP responded or not
                                               ;tells the DSP about it,though

resetOnCE
        bsr     resetAckLatch                   ;reset the acknowldge latch
        bclr    DR_BIT,porta
        bsr     waitForAck
        bset    DR_BIT,porta
        brset   resBit,flagWd,abortRST          ;
        bset    DATA_To_OnCE,DDRA               ;make these two 68705 inputs into outputs
        bset    CLK_BIT,DDRA
        bclr    DEBUG_LED_BIT,porta             ;turn on debug LED
abortRST:
        rts



readWord                                        ;read three words from the OnCE port
        bsr     readByte
        sta     SECOND_BYTE
        bsr     readByte
        sta     THIRD_BYTE
        bsr     readByte
        sta     FOURTH_BYTE
        rts



writeByte                          ;write a byte to the OnCE port
        ldx     #8
writeBit
        rola                                    ;rotates MSB into carry
        bset    CLK_BIT,porta                   ;raise clock line
        bcs     writeBit1
        bclr    DATA_To_OnCE,porta              ;clear the DSI line
        bra     writeBit2
writeBit1:
        bset    DATA_To_OnCE,porta              ;set the DSI line
writeBit2:
        ;nop     ;mebbe?
        decx                                    ;loop if more bits
        bclr    CLK_BIT,porta                   ;lower clock line again
        bne     writeBit                        ;the bclr doesn't affect the condition codes
        rts                                     ;set by the decx - gives extra DSI setup time



writeWord                                       ;write three bytes to the OnCE port
        lda     SECOND_BYTE
        bsr     writeByte
        lda     THIRD_BYTE
        bsr     writeByte
        lda     FOURTH_BYTE
        bsr     writeByte
        rts



resetAckLatch                                  ;reset the hardware acknowledge latch
        bclr    ACK_RST_BIT,porta
        bset    ACK_RST_BIT,porta
        rts



waitForAck
        bclr    resBit,flagWd                   ;clear acknowledge bit
        ldx     #Ack_Time
ackLoop:
        brset   ACK_BIT,porta,endAck            ;end looping if we get an acknowledge
        decx                                    ;otherwise, keep counting down
        bne     ackloop
        bset    resBit,flagWd                   ;set bit if port times out without ack
endAck:
        rts


******************************************************************

decodeCommand                                   ;decode the command from the host, and
                                                ;branch to the appropriate part of the code
        jsr     chkParity                       ;check the parity on the command byte
        bcs     collector                       ;if carry set, i.e. parity error, abort operation
        cmp     #RD_CMD
        beq     doReadCmd                       ;write one byte to OnCE port, read three back
        cmp     #WR_ONE_BYTE_CMD
        bne     notOneByte
        jmp     doOneByte                       ;write one byte to the OnCE port
notOneByte:
        cmp     #WR_FOUR_BYTE_CMD
        bne     notFourByte
        jmp     doFourBytes                     ;write four bytes to the OnCE port
notFourByte:
        cmp     #RST_OnCE_CMD
        beq     resetOnCE                       ;reset the OnCE port
        cmp     #RST_DSP_CMD
        bne     notRstDSP
        jmp     resetDSP
notRstDSP:
        cmp     #REQ_OnCE_CMD
        beq     req_OnCE                        ;request the OnCE port
        cmp     #REL_OnCE_CMD
        bne     next2
        jmp     releaseOnCE                     ;release the OnCE port, turn off the LED
next2:  cmp     #RD_STAT_CMD
        beq     readDSPStatus                   ;read the DSP status, acknowledge, and some 68705 pins
        cmp     #RST_68705_CMD
        bne     notStart
        jmp     start                           ;jump back to the start of it all
notStart:
        cmp     #RST_IN_DEBUG_CMD
        bne     notRstDebug
        jmp     rstIntoDebug                    ;reset the DSP, holding it in debug state
notRstDebug:
        cmp     #WHAT_REV_LVL
        beq     sendRevLvl                      ;tell the host what rev we are
        cmp     #ARE_YOU_AWAKE
        bne     unknownCmd
sndImAwake
        lda     #IM_AWAKE                       ;reply that the 68705 is awake
        bra     exPutChar                       ;and don't come back to here
unknownCmd:
        lda     #HUH_REPLY                      ;character is not recognized
        bra     exPutChar                       ;take no further action



req_OnCE                 ;request the OnCE port, do not bypass if already in debug
        lda     #25t                            ;try 25 times to reset the OnCE port
        sta     count                           ;use this byte for the reset count
req_once1:
        jsr     resetOnCE
        brclr   resBit,flagWd,endReqOnCE        ;end looping if we got an acknowledge
        dec     count                           ;with that request
        bne     req_once1                       ;has it timed out yet?
        lda     #NO_DSP_AWAKE
        bra     exPutChar                       ;tell the host that no DSP is awake
endReqOnCE:
        lda     #IN_DEBUG
        bra     exPutChar


collector                                       ;a stub routine to conditionally
        rts                                     ;return using a bcs instruction


readDSPStatus            ;read DSP status, ack latch state, debug state, etc
        lda     #HERES_SOME_DATA                ;ack byte
        bsr     exPutChar
        lda     porta                           ;read all of port a
        bra     exPutChar                       ;store it to be sent to host
sendRevLvl
        lda      #CUR_REV_LVL
        bra      exPutChar


doReadCmd               ;read from a OnCE register
        jsr     get_char                        ;get the OnCE CR byte
        sta     FIRST_BYTE
        jsr     resetAckLatch                   ;reset the acknowledge latch
        jsr     writeByte                       ;send byte to OnCE CR
        jsr     waitForAck
        brclr   resBit,flagWd,contRead
        bra     rptAck                          ;if no Ack, abort the command
exPutChar
        bra     put_char
contRead:
        jsr     readWord                        ;if an Ack, read the data
        lda     #HERES_SOME_DATA                ;ack byte
        bsr     put_char
        lda     SECOND_BYTE                     ;and send to the host
        bsr     put_char
        lda     THIRD_BYTE
        bsr     put_char
        lda     FOURTH_BYTE
        bra     put_char



doOneByte                ;write one byte to OnCE port command register
        jsr     get_char                        ;get the OnCE CR byte
        sta     FIRST_BYTE
        bsr     chkParity                       ;check parity over the data byte
        bcs     collector
        jsr     resetAckLatch                   ;reset the acknowldge latch
        jsr     writeByte
        bra     commonCode
doFourBytes                   ;write one byte to OnCE port command register,
                              ;then three bytes to the selected OnCE register
        bsr     get_char                        ;get the OnCE CR byte
        sta     FIRST_BYTE
        bsr     get_char                        ;get the 1st data byte
        sta     SECOND_BYTE
        bsr     get_char                        ;get the 2nd data byte
        sta     THIRD_BYTE
        bsr     get_char                        ;get the 3rd data byte
        sta     FOURTH_BYTE
        bsr     chkParity                       ;check parity over entire packet
        bcs     collector
        lda     FIRST_BYTE
        jsr     resetAckLatch                   ;reset the acknowledge latch
        jsr     writeByte                       ;write to the OnCE command register
        jsr     waitForAck
        brset   resBit,flagWd,rptAck            ;report and abort only if ack bad
        jsr     resetAckLatch                   ;reset the acknowldge latch again
        jsr     writeWord
commonCode:
        bsr     chkForExit
        bcs     collector                       ;exit if this is an exit command
        jsr     waitForAck                      ;else wait for the DSP to come back
        bra     rptAck                          ;and tell the host about it


chkParity
        brclr   parityErr,flagWd,endChkParity
                                      ;which sets/clears the carry bit as well !!
parErrRply
        lda     #PAR_ERR_RPLY
        bsr     put_char
        sec                                    ;set the carry bit again
endChkParity:
        rts



chkForExit                 ;check if the exit bit is set
        brclr   EX_BIT,FIRST_BYTE,endChkForExit
                               ;which sets/clears the carry bit as well  !!
releaseOnCE                                    ;make this routine do double duty
        bclr    STAT0_BIT,DDRA                 ;make these two outputs into inputs
        bclr    STAT1_BIT,DDRA
        bset    DEBUG_LED_BIT,porta            ;turn off debug LED
        lda     #OUT_OF_DEBUG
        bsr     put_char
        sec                                    ;set the carry bit again
endChkForExit:
        rts



rptAck                     ;examine the ack bit and report its state to the host
        brset   resBit,flagWd,ackMissing
        lda     #ACK_GOOD
        bra     ackPresent
ackMissing:
        lda     #ACK_BAD
ackPresent:
        bsr     put_char
endRptAck:
        rts



*************************************************************************
*                                                                       *
*       Program Description - RS232 section:                            *
*                                                                       *
*       Code for 68HC705K1 to send and receive asynchronous data with   *
*       non-return to zero (NRZ) format. The original code was tested   *
*       at 9600 baud.                                                   *
*                                                                       *
*                            _______                                    *
*                            |     |                                    *
*               TXD     <-- 3|B0   |                                    *
*               RXD     --> 4|/IRQ |                                    *
*                            |_____|                                    *
*                                                                       *
*               Pin out for 68HC705K1  SCI section                      *
*                                                                       *
*       Operation:                                                      *
*                                                                       *
*   put_char:  sends a byte out the serial TX pin. Includes the START   *
*              and STOP bits.  Generates and sends the PARITY bit.      *
*              The format is one start, 8 data, even parity, one stop.  *
*              Port B bit 0 is used as the transmit data pin.The input  *
*              byte is received from the main program in the            *
*              accumulator.  It is sent LSB first by right shifting     *
*              the acc. Parity is generated by inverting the contents   *
*              of the memory location labled ParCnt every time the bit  *
*              sent out is a "one".  After the 8 data bits have been    *
*              sent, the LSB ParCnt contains the proper value for EVEN  *
*              parity and is sent next. The parity bit requires a       *
*              slightly longer delay which is accomplished using the    *
*              Parity_Bit_time constant and jumping to delay_bit1.      *
*                                                                       *
*   get_char:  The external interrupt/programming voltage pin (Vpp/IRQ) *
*              is used as the receive data pin. It waits for a START    *
*              bit to be received on the IRQ pin, polling rather than   *
*              using interrupts to detect the bit. When a high-to-low   *
*              transition is detected, the routine waits for 1.5 cells  *
*              to elapse and then starts to sample the IRQ pin,         *
*              shifting the received bits into the accumulator. Parity  *
*              is checked based on a technique similar to the technique *
*              in put_char. The parity errors are flagged as a "sticky" *
*              bit in the flag word.                                    *
*                                                                       *
*************************************************************************

put_char:
        ldx     #9t                             ;[2]load bit count in index
        stx     count
        clr     parCnt
        clc                                     ;[2]clear carry for start bit
        rola                                    ;[3]position start bit for first out...

put_loop:                                       ;---main put loop (29 cycles + delay) ---
        sta     portb                           ;[4]send the bit
        rora                                    ;[3]shift bit into carry
        bcc     put_0                           ;[3]
        com     parCnt                          ;[5].......and invert the parity track
put_1:
        bsr     delay_bit                       ;[6]wait for start of next bit cell
        dec     count                           ;[5]decrement the bit count until zero...
        bne     put_loop                        ;[3]continue until all data bits sent

        lda     parCnt                          ;[3]get the parity track word and
        sta     portb                           ;[4]send the parity bit...
        ldx     #Parity_Bit_time                ;   correction for parity bit
        bsr     delay_bit1                      ;[6]wait for the parity bit cell time
        bset    TXD_BIT,portb                   ;[5]set the stop bit(s)
        ldx     #Parity_Bit_time                ;[2]make parity bit length correct
        bsr     delay_bit1                      ;[6]wait for the stop bit cell time
        rts                                     ;[6]and get out

put_0:                                          ;---send a zero
        nop                                     ;[2]make zero send time = one send time
        bra     put_1                           ;[3]and return



get_char:
        clr     parCnt                  ;[5]initialize the parity tracking
        lda     #$FF                    ;[2]init acc for bit count
get_start:
        bih     $                       ;[3]wait for start bit to go low
        ldx     #half_bit_time          ;[2] load delay 1/2 bit time
        bsr     delay_bit1              ;[6]   wait for 1/2 bit time
                                        ;we are now in middle of start bit
        bih     get_start               ;[3] false start if we branch   <<!>>
                                        ;all ACC bits are set for subsequent clear
get_loop:                               ;--- main get loop (29 cycles + delay)
        bil     c_car                   ;[3]if IRQ low...leave it clear
        com     parCnt                  ;[5]...else invert parity track
carol:                                  ; this also sets carry bit..
        rora                            ;[3]...rotate carry bit into msb
        bcc     g_char_end              ;[3] clear carry bit means complete
        bsr     delay_bit               ;[6] wait until in the next bit cell
        rola                            ;[3]makes code delay for get equal
        rora                            ;[3]
        bra     get_loop                ;[3]
g_char_end
        bsr     delay_bit               ;[6]wait for parity bit...
        bil     par1                    ;[3]branch if parity set...
        com     parCnt                  ;[5]invert parCnt
par1
        brclr   0,parCnt,par_good       ;[5]branch if EVEN parity checks OK
        bset    parityErr,flagWd        ;[5]...else, set sticky parity flag
par_good:
        bsr     delay_bit
        rts                             ;[6]
c_car:
        clc                             ;[2]clear the carry bit
        bra     carol                   ;[3]...and continue



****************************************************************************
*   at 9600 Baud, each cell consumes 104.16 us.                            *
*   delay is:                       2     LDX                              *
*                  + (3+3) * 27 = 162     DELAY LOOP with count $1B        *
*                             +     6     RTS                              *
*                                -----                                     *
*                                 170     Total cycles in delay loop       *
*                             +    29     cycles in main loop              *
*                                -----                                     *
*                                 199     Total cycles per loop = 99.5 us  *
*      ---this is 4.66 us short or 4.5%                                    *
* ------------------------------------------------------------------------ *
*   at 19200 Baud, each cell consumes 52.0833 us.                          *
*   delay is:                       2     LDX                              *
*                  + (3+3) * 11 =  66     DELAY LOOP with count $0B        *
*                             +     6     RTS                              *
*                                -----                                     *
*                                  74     Total cycles in delay loop       *
*                             +    29     cycles in main loop              *
*                                -----                                     *
*                                 103     Total cycles per loop = 51.5 us  *
*      ---this is 0.5833 us short or 1.12%                                 *
* ------------------------------------------------------------------------ *
*  delay_bit  is a legal entry point for the standard, full-bit-time delay *
*  delay_bit1 is an entry point for alternate delay periods (e.g.,         *
*             half-bit) It is entered with the alternate delay in the      *
*             x-register. BOTH routines corrupt the x-register             *
****************************************************************************




delay_bit:
        ldx     #full_bit_time          ;[2]
delay_bit1:
        decx                            ;[3]
        bne     delay_bit1              ;[3]
        rts                             ;[6]


******************************Setup reset vector*************************

        org     vectors
        bra     $                       ;Timer vector
        bra     $                       ;External IRQ vector
        bra     $                       ;SWI vector

        org     reset
        dw      start


* By the way, I'll mention that this code will probably be a nightmare
* to maintain and extend. Good luck!  ;-)

