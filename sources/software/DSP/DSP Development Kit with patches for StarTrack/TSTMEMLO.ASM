;****************************************************************************
;       TSTMEMLO.ASM    Rev.1.0
;
; Speichertest fuer Falcon-kompatibles RAM (32Kx24Bit)
; 
; Testet P-mem des 32Kx24Bit RAMs auf korrekte Funktionsweise
; 
;******************************************************************************

	org     y:$1000
	dc      $1000
	dc      $111111

	org     y:$3F00
	dc      $3F00
	dc      $222222

	org     x:$1000
	dc      $5000
	dc      $333333
	
	org     x:$3F00
	dc      $7F00
	dc      $444444

    end
