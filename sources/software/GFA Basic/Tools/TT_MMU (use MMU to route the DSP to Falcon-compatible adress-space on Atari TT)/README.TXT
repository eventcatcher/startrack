This Program is only for the Atari TT with 68030 CPU and TOS
(MagiC is not supported at this time).

Copy it in the Autofolder, direct below
the Audiodriver SOUND.PRG (notice the Boot sequence).
This Program use the MMU of the TT and mirrors the Registers of the DSP in the
Falcon-compatible adress space $FFFA200. With this trick, the Audiocard is compatible
to bad Falcon-Programs that program directly the DSP-Registers.

Notice that it only works with Original Single-TOS !
Multitasking-OS MagiC,NAES,MultiTOS etc. use and programs the MMU for own things.
For use with Multitasking-OS don't load this Autofolder-Program (rename the file) 
DSP_ROUT.PRG !

Future versions of this Multitasking-Systems integrates the
DSP-Mirroring,so that you than can use this Feature.
