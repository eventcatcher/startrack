;****************************************************************************
;       TSTMEMHI.ASM    Rev.1.0
;
; Speichertest fuer RAM (128Kx24Bit)
; 
; Testet P-mem des 128Kx24Bit RAMs auf korrekte Funktionsweise
; 
;******************************************************************************

	org     y:$1000
	dc      $1000
	dc      $111111

	org     y:$7F00
	dc      $7F00
	dc      $222222

	org     x:$1000
	dc      $9000
	dc      $333333
	
	org     x:$7F00
	dc      $FF00
	dc      $444444

    end
