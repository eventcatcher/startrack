Programm READREGS.PRG

Es werden 2 Register der Startrack ausgelesen.
Hierbei sollte es keinen Absturz geben,wenn die Register im Milan erkannt werden.
Das Programm gibt die Registeradresse und deren Inhalt aus,
und wartet auf einen Mausklick zum Beenden des Programms:

FEFF0401	BC
FEFF0421	7F




Programm DSPREGS.PRG :

Mit diesem Programm werden die Register des DSP ausgelesen.
Die Bildschirmausgabe sollte in etwa so aussehen:

FEFF0600	0
FEFF0601	18
FEFF0602	6
FEFF0603	15
FEFF0604	0
FEFF0605	255
FEFF0606	255
FEFF0607	255

St�rzt das Programm ab,werden diese Register NICHT erkannt.
Das sollte nicht passieren. Zum Beenden des Programms die Maustaste dr�cken.




XBIOSTST.PRG :

Mit diesem Programm werden einige Funktionen der StarTrack XBIOS-Erweiterung
getestet. Wenn das SOUND.PRG richtig installiert (im AUTO-Ordner) und richtig geladen
wurde,sollten hiermit einige ausgelesene Daten auf dem Bildschirm ausgegeben werden.
Zum Beenden des Programms die Maustaste dr�cken.




SPEEDTST.PRG

Testet die Geschwindigkeit der Audiokarte beim Datentransfer einiger Register.
Zum Beenden des Programms die Maustaste dr�cken.


