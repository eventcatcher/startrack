;       HI-Lader fuer den DSP56001.
;       patched (mit PLL-Initialisierung 4MHZ-Quarz x10 = 40MHz Takt)
;
;       Dieser Lader initialisiert das host interface (HI)
;       des DSP56001 und laedt dann LOD-Dateien 
;       in den internen Speicher.  Der Lader nutzt die oberen
;       128 Bytes des P-Speichers und laedt den unteren Speicher von
;       $0000-(LDRMEM-1) mit dem LOD-Programm .  Die folgenden Labels werden
;       erkannt:
;           _DATA X ADDR
;           _DATA Y ADDR
;           _DATA P ADDR
;           _END ADDR
;       Wenn das END-Label erkannt wurde, springt der Lader zu der Adresse
;       im END-Label.  Nehme zur Kenntnis das eine Adresse im END-Label 
;       enthalten sein muss ! (Das Programm muss wenigstens ein P-Segment
;       enthalten 
;
;       Der Lader laedt die folgenden Speicherraeume:
;           X - 0 bis FF
;           Y - 0 bis FF
;           P - 0 bis LDRMEM-1
;

HSR     equ     $FFE9           ;Host status register
HRX     equ     $FFEB           ;Host receive register
PBC     equ     $FFE0           ;port B control
PBDDR   equ     $FFE2           ;port B data direction
PBD     equ     $FFE4           ;port B data
PLL     equ     $FFFD           ;PLL Control Register
BCR     equ     $FFFE           ;port a bus control reg
LDRMEM  EQU     $1A9            ;START OF LOADER IN P MEMORY

	ORG     P:$0000         ;RESET VECTOR FOR BOOTING
RVEC
	JMP     <LOAD           ;GO EXECUTE LOADER

	ORG     P:LDRMEM
LOAD
	movep   #$261009,x:PLL  ;set PLL for MPY of 10 x
	movep   #1,x:PBC        ;port B: Host interface 
	movep   #1,x:PBC        ;port B: Host interface 
	movep   #$2222,x:BCR    ;no wait states: 0 for RAM, 0 for ROM and I/O
WTUS
	JSR     <GETCH          ;INPUT CHARACTER
	MOVE    #'_',X0         ;GET UNDERSCORE CHARACTER
	CMP     X0,A            ;SEE IF "_" YET
	JNE     <WTUS           ;NO
GOTUS
	JSR     <GETCH          ;GET A CHARACTER
	MOVE    #'D',X0         ;GET A D FOR DATA
	CMP     X0,A    #'E',X0 ;COMPARE TO D, GET E
	JEQ     <DATAREC        ;IF "D", THEN DATA RECORD
	CMP     X0,A            ;SEE IF END RECORD
	JNE     <WTUS           ;NO, GO WAIT FOR ANOTHER UNDERSCORE
_WTSPC
	JSR     <GETCH          ;GET CHARACTER
	MOVE    #$20,X0         ;GET SPACE
	CMP     X0,A            ;WAIT FOR SPACE AFTER "END"
	JNE     <_WTSPC         ;WAIT FOR SPACE
	JSR     <IN4            ;GET TRANSFER ADDRESS
	MOVE    B1,R0           ;MOVE TRANSFER ADDRESS
	NOP                     ;CLEAR ADDRESS PIPE
	JMP     (R0)            ;GO EXECUTE USER CODE
DATAREC
	JSR     <GETCH          ;GET CHARACTER
	MOVE    #$20,X0         ;GET SPACE
	CMP     X0,A            ;SEE IF SPACE
	JNE     <DATAREC        ;NO
	JSR     <GETCH          ;GET [P,X,Y]
	MOVE    A1,Y0           ;SAVE CHARACTER
	JSR     <IN4            ;GET ADDRESS OF DATA RECORD
	MOVE    B1,R0           ;SAVE ADDRESS
	MOVE            #'X',A  ;GET X
	CMP     Y0,A    #'Y',A  ;SEE IF X, GET Y
	JEQ     <_LDX           ;LOAD DATA INTO X MEMORY
	CMP     Y0,A            ;SEE IF Y
	JEQ     <_LDY           ;LOAD DATA INTO Y MEMORY
_LDP
	JSR     <IN6            ;GET DATA
	MOVEM   B1,P:(R0)+      ;LOAD P MEMORY
	JMP     <_LDP
_LDX
	JSR     <IN6            ;GET DATA
	MOVE    B1,X:(R0)+      ;LOAD X MEMORY
	JMP     <_LDX
_LDY
	JSR     <IN6            ;GET DATA
	MOVE    B1,Y:(R0)+      ;LOAD Y MEMORY
	JMP     <_LDY

GETCH
	JCLR    #0,X:HSR,*      ;wait for data from HI
	nop
	nop
	MOVEP   X:HRX,A         ;GET HI DATA BYTE
	nop
	nop
	LSL     A               ;SHIFT OUT PARITY
	LSR     A               ;clear parity bit
	MOVE    A1,A            ;SIGN EXTEND AND ZERO
	RTS
IN4
	CLR     B       #>4,X0  ;CLEAR VALUE, GET 4
	JMP     <READHEX        ;READ 4 HEX CHARACTERS
IN6
	CLR     B       #>6,X0  ;CLEAR VALUE, GET 6
READHEX
	DO      X0,_READHEX     ;READ ASCII HEX AND CONVERT TO BINARY
_GET
	JSR     <GETCH          ;GET A CHARACTER
	MOVE    #'_',X0         ;GET UNDERSCORE
	CMP     X0,A    #'F',X0 ;SEE IF UNDERSCORE
	JNE     <_NOTUS         ;NO
	ENDDO                   ;EXIT LOOP
	MOVEC   SSH,X0          ;POP RETURN ADDRESS
	JMP     <GOTUS          ;GO PROCESS NEW INPUT RECORD
_NOTUS
	CMP     X0,A    #'0',X0 ;SEE IF GREATER THAN F
	JGT     <_GET           ;YES, IGNORE
	CMP     X0,A            ;SEE IF LESS THAN 0
	JLT     <_GET           ;YES, IGNORE
	SUB     X0,A    #10,X0  ;ADJUST FOR ASCII TO BINARY
	CMP     X0,A    #7,X0   ;SEE IF A-F
	JLT     <_NOTALPHA      ;NO
	SUB     X0,A            ;ADJUST FOR 1-F
_NOTALPHA
	REP     #4              ;SHIFT OLD VALUE LEFT 1 NIBBLE
	LSL     B
	REP     #16             ;SHIFT NEW NIBBLE DOWN TO LSB
	LSR     A
	ADD     A,B             ;ADD NEW NIBBLE IN
_READHEX
	RTS
	END

