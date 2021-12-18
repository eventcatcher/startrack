Have fun with the StarTrack Audiocard and the StarTrack Software V2.00 !                K”ln, 09/17/1998

Here a few explained words from me.
All rights to this program are from Stephan Wilhelm,Niehler Str.312,50735 K”ln, Germany
This program is not error-free and i don't responsible for damages from your hardware or software of your
computers through the use of this program (but this is really improbable).

Before you install the Startrack Audiocard in your Computer, please read absolute first the
Installation Guide in the Hypertext. Please, if you will mount the Audiocard into the Hades,
check especially the VME-cable of correct installation. The Hades VME-Connector on the board
has none existing protection against wrong connect .
First, install now the Software and the Hypertext and read the corresponded chapter
for Hardware installation in the Hypertext.

Without Audiocard, the software runs automatic as Demoversion.
In this case you can direct begin with the installation of the Software.


Software-Installation
---------------------
The installation is really easy: Unpack the Software (Disk1, STARTRAK.LZH) with
a LZH packer (LHARC 3.1 or higher) on any partition of your Harddisk-Drive.
The Software needs ca. 3 MB free space onto the media.
Thereafter unpack the Hypertext (Disk2, STARHELP.LZH) in the main directory
of the Startrack-Folder "STARTRAK" The Hypertext needs ca. 5 MB free space.

After the installation should the new folder "STARTRAK" shown how below:

/1STGUIDE     -  Hypertext-Software 1stGuide
/STARHELP     -  Hypertext-System for 1stGuide (in german, but i translate it in english later)
/ENGLISH      -  all texts translate to english
   HARDWARE.TXT  -  hardware-features
   README.TXT    -  installation-reference and last modifications (read it first !!!)
   SNDCHECK.TXT  -  soundcheck
   SOFT.TXT      -  software-description
   SOFTFEAT.TXT  -  software-features
   STARTRAK.UPL  -  upload-text for the publication in mailboxes
/HADES           -  Cookie-Patch for Betaversion of MagiC for Hades
/STARMODE        -  Accessory for select Modes of Matrix and Audiohardware
/STAR_CSB        -  Accessory for readout the digital Channel-Statusblock
/TT_MMU          -  Autofolder-Program for the Atari TT for Falcon compatible DSP-Registers 
HARDWARE.TXT  -  hardware-features (in german)
LANGUAGE.TXT  -  used Language-File
LANG_D.TXT    -  file for german language
LANG_E.TXT    -  file for english language
LANG_F.TXT    -  file for french language
LIESMICH.TXT  -  installation-reference and last modifications (in german)
NONSTOP.INF   -  Infofile for NONSTOP.S16
NONSTOP.PBF   -  Cachefile for NONSTOP.S16
NONSTOP.S16   -  Demosample for Info-Window
PAUSE.PRG     -  Keypress program for Auto-Folder
SOFT.TXT      -  software description (in german)
SOFTFEAT.TXT  -  software features (in german)
SOUND.PRG     -  Audio hardware and XBIOS-Driver
STARHIGH.RSC  -  window dialogs for high resolution (>= 1024x768)
STARLMON.RSC  -  monochrome window dialogs for small resolution in Smallmode
STARLOW.RSC   -  window-dialogs for small resolution (< 1024x768)
STARTRAK.PRG  -  sample-editor-programm
STARTRAK.UPL  -  upload-text for the publication in mailboxes (in german)
UPDATE.TXT    -  Update-History in german


Explanation of the Software-Utilitys
------------------------------------
In the folder named "STARMODE" you find a Accessory for select the different modes of
the Audiohardware. This runs also as program (change the file extension from ACC to PRG).
The Starmode-Accessory is useful for work with Falcon-software onto the Audiocard.
Here,you can select many features and controlling the hardware for use of not
clean programmed falcon-software (most Falcon-software writes direct in the
hardware-registers and don't use the OS-Calls for this).
For details please read the Textfiles (in folder "STARMODE").   

In the folder "STAR_CSB" you find another Accessory for detailed readout of the
digital Channel Status Block. This runs also as program (change extension ACC to PRG).
The CSB (Channel Status Block) is defined in the digital SP/DIF and AES/EBU-Signal
and is added to the clean Audiosignal for additional informations of the sample.
Here you find detailed Infos about record source, Samplerate, Error correction etc.
that's shown from the Accessory in intelligible manner.

In the folder "TT_MMU" you find a Program only for the Atari TT. Copy it in the
Autofolder, direct below the Audiodriver SOUND.PRG (notice the Boot sequence).
This Program use the MMU of the TT and mirrors the Registers of the DSP in the
Falcon-compatible adress space $FFFA200. With this trick, the Audiocard is compatible
to bad Falcon-Programs that program directly the DSP-Registers.
Notice that it only works with Original Single-TOS !
Multitasking-OS MagiC,NAES,MultiTOS etc. use and programs the MMU for own things.
For use with Multitasking-OS don't load this Autofolder-Program (rename the file) 
DSP_ROUT.PRG ! Future versions of this Multitasking-Systems integrates the
DSP-Mirroring,so that you than can use this Feature.

Important: The Accessory-Resourcefiles (extension .RSC) you must copy in the Bootpath.
The Audio driver "SOUND.PRG" should be installed before you can use the Accessorys.
The Accessorys needed the Audiodriver.

The Program and the Error messages you can localize to your language with the
language files - for german (LANG_D.TXT), english (LANG_E.TXT) and french (LANG_F.TXT).
For select one of these languages you must rename one of the LANG_X.TXT-files to
LANGUAGE.TXT. The Audiosoftware automatic loads this file by startup.

NONSTOP.S16 is a audio sample, played as identity melody and Demo,
when you open the Info-window.

PAUSE.PRG you can copy in the AUTO-folder and should be direct loaded after
the Audiodriver SOUND.PRG .
It waits only for a keypress. That is useful for read the status information of
the Audiodriver by load from the AUTO-folder (e.g. the Hades060 is too fast
without PAUSE for read the informations by loading).

The Fastload- and Fastmemflags of the Audiodriver (SOUND.PRG) should be set.
Important: Don't change The flags of the Mainprogram (STARTRAK.PRG) !


Install 1stGuide
----------------
1. Copy the file 1STGUIDE.ACC in your Boot-directory.
   If you will print with 1st Guide, you must install a GDOS.

2. Restart your computer

For use 1stGuide with the StarTrack program, you must
define the searchpath from STARTRAK.IDX (in folder STARHELP) in 1stGuide.
You come into the Setup-Dialog from 1stGuide, if you doubleclick the left
mousekey with pressed right mousekey onto the Accessory-entry "1stGuide".
In the Setup is a field named Indexdatei. Here you define the searchpath.
Have you done this, click thereafter the "Sichern"-Button, that's all.

For additional informations and explanations of the 1stGuide-Software,
click in the Desk-Menu of the Desktop the point "1st Guide" and
select in the Fileselector the file "1STGUIDE.HLP" in the 1STGUIDE-folder.
This Hypertext is surely only included in the Fullversion of 1stGuide.
For this, please procure the Fullversion of 1stGuide (e.g. in Mailboxes or
Shareware CDs).


Important by work with 1stGuide and StarTrack-Software
------------------------------------------------------
You can normally call up the Hypertext in StarTrack with the HELP-Key in the windows.
You can do this normally not in a dialogbox (Hypertext use 1stGuides windows).
Therefore you can do this, the program temorary close the dialogbox for
call up the 1stGuide-window. Have 1stGuide opened all needed windows (for
explained the program-features), the program shows the dialogbox again and you can
make farther your Inputs. You must first close the dialogbox, before you can switch
to the explained 1stGuide-Hypertext !.
That is a AES-Feature (in my opinion a little bug, ehh).
The decision for the benefit of 1stGuide is that 1stGuide is the first
Hypertext-Program that could shown colour-pictures in the Hypertext
before ST-Guide could do that.


Fitting the StarTrack Mastering-Software
----------------------------------------
The program runs with a minimal resolution from 640x400 in monochrome with 4MB RAM,
but for full power and successful use you should have a resolution from 1024x768 
(monochrome, better styling in colour) or more. Then, the program load another
resource-file for greater resolutions (STARHIGH.RSC for greater Editor and Tracker-window).

The Program works with all TOS-compatible Computers with VME-Bus (MegaSTE,TT,Medusa with
VME-Card,Hades) with TOS,MultiTOS and MagiC-OS. The Program is in big pieces developed
on a Hades060.

-> The Software works without Audiohardware automatic in Demo-Mode on the described computers
-> and all Ataris with 68000-CPU with 4MB, the TT and Falcon, and with Apple-Computers with MagiCMac.

The Program should run successful on all TOS compatible Systems.
We have it successfully tested with this Hardware:

Hades (32MB RAM)                            : ok, and with MagiC (Hades-Version)
Medusa (16MB RAM)                           : ok
Atari TT (4MB ST,8MB TT RAM)                : ok, and with MagiC
Elrad ST (4MB RAM)                          : ok
Falcon (4MB RAM)                            : ok
Apple Powerbook 520 (68K,20MB RAM)          : ok,requires MagiCMac
Power Mac 8200/120 (PowerPC601/120,48MB RAM): ok,requires MagiCMac
Gravis MT200 (PowerPC603/200,48MB RAM)      : ok,requires MagiCMac

With MagiCMac sometimes you can become problems with wrong Memory-Configurations.
For the Mac you should give a rest of ca. 2MB free Memory, the Sounddriver of the Mac
is loaded from the StarTrack-Software when you start the program.
This Configuration runs successful on a PowerMac 8200/120 with 48MB RAM:

Minimum ST-RAM:      0 KB
Minimum gesamt:   8192 KB
Maximum gesamt:  31000 KB
Minimum Mac frei: 2000 KB

If the program have start-problems or runs with problems with MagiCMac, change the 
memory-configuration of the system. I had problems with more than 32000 KB Maximum.
I can't say what's makes this problems with MagiCMac at this time.
With all other Systems we haven't problems with more Memory.

The Accessorys are specially written for the StarTrack Audiocard, and are not required for
run the Audiosoftware on Falcon or MagiCMac.

In the Demomode it's possible to play audio on Apple-computers with MagiCMac and play and recording audio
with Atari Falcon-Computers !
But, it works only with samples in RAM. HD-Recording and DSP functions are not supported on the Falcon
at this time. This piece of the software-driver is in development. At the end we have also a complete
Software-Version of the StarTrack Audiosoftware special for den Falcon.

Attention ! The programm works now on Computers with only 4MB RAM and needs minimal ca. 3.5 MB free RAM.
With less then 6MB free RAM,the program works automatic in the smallmode. In the Smallmode the
software supports only windows in monochrome with max. windowsize of 640x400 and the software use a smaller
display-cache. Only with more as 6MB free RAM runs the Software also with colour windows and with greater
windows. Recommended are 8MB free RAM for faster and correct work with all supported functions, especially
for work in the Tracker-Window. Important for TT-User: For RAM-Calculation you must have coherent
continuous RAM, recommended for TT are 6-8 MB Fast-RAM (ideal condition).
When you have more RAM, you can adjust it in the StarTrack Setup-Dialog. 
The Software runs without problems in Fast-RAM, and also with 68040 and 68060 CPUs (Hades,Medusa).

Now, after the correct installation of the software you can start the Audiosoftware STARTRAK.PRG.
The audio hardwaredriver "SOUND.PRG" were automatical load from the STARTRAK.PRG.
This file should are in the same folder as the program.
The Audiodriver "SOUND.PRG" is also loadable from the AUTO-folder on the Boot-Partition.
and display a few Status-informations about the driver and the Audiohardware. 
When the OS loads the programs from the AUTO-folder, should the Audiodriver load as one of
the latest programs that are in this folder. You can change the start-sequence e.g with XBOOT.

After the first start, the program shows not all display-options. Look first in the Setup.
You become this with the medical-bag symbol in the upper buttonrow from the edit-window.
Here you can select many options for your own, special work-environment and individual
requirements. When necessary, limit the from the program allocated memory in the setup
Important: The Tracker needs for successful work ca. 8 MB free RAM
(for 8MB : malloc=8192 and select the max-option). Save the setup with the SAVE-Button.
Important: The program saves also the windowpositions, and rebuild this windows after the next start.

Now you have a program-description as a Hypertext-System (in the folder /STARHELP). This runs with the
1stGuide-accessory, and you can it use in the Audiosoftware with the HELP-key.
If you have installed correctly 1stGuide, you become a Guide for all functions from the
Dialog or window in that you has pressed the Help-Key or Help-Button (function-sensitive).

A few Falcon-Programs runs now with the StarTrack Audiocard.
For this you must first load the XBIOS-Driver SOUND.PRG (e.g. copy it in the AUTO-folder).
But, you can also starts the Driver manually from the Desktop.


Requirements for Harddisk-Recording
-----------------------------------
Harddiskrecording is a very fastidious job for a Computer system and requires high power
from the system. You should have a fast Computer,a fast harddisk and enough RAM.
With the Hades060 you can play 16 Tracks at this time. With a faster,optimized
Driver perhaps you can 24 Tracks playback in the future.
I'm sorry to say, but the slow SCSI-Transfers of TOS-Computers limits the power.
With a PCI Ultrawide-SCSI-Card for Hades, i think we can playback 24-32 Tracks.
The use of the Audiocard in the MegaSTE is not a technical problem, it works.
But, HD-Recording with MegaSTE is possible only under best conditions,
RAM-Sampling is no problem.


Important for Software-Updates:
-------------------------------
The old version V1.09 had two bad bugs that maked many problems,
especially on the TT in the Demo-Mode. This Bugs are deleted in the new version.

1. Important: If the Software starts not correctly, delete the old Setup-File (SMP16.SET),
              newer versions have eventually another format !!!

2. The Audiodriver SOUND.PRG can you now start from the AUTO-folder and should stay at the end of the
   program load-sequence.
   
3. The Accessorys use the Audiodriver and presumed a loaded driver. That is correct with a driver that
   starts from the Auto-folder. Is the driver not in the auto-folder, you must start the driver manual (SOUND.PRG) !
   
4. The Masteringsoftware STARTRAK.PRG loads a notloaded driver automatic and start it,if the driver is in
   the same folder as STARTRAK.PRG.

5. The Masteringsoftware starts at the begin in a very small configuration. You should change the
   Samplememory-value in the Setup (malloc) to ca. 8 MB after the first start. You become problems
   with the tracker if you have a too small samplememory.

6. Please,copy ALL files in den programfolder, the languagefiles
   (LANG_X.TXT und LANGUAGE.TXT) and the Resource-Files (*.RSC) are eventually changed and the programs
   don't work with the old versions.


The new Version includes Effect-Plugins from Winrec which are now a piece of
StarTrack with friendly permission of A.Binner.

Future Windows for Mixer and Crossfader (without functionality at this time):

In the Dropdown-Menu - entry Functions/Partition-Mode:

CTRL-Key pressed + click on Dropdown entry : XFADE-Dialog
ALT-Key pressed + click on Dropdown entry  : Mixer-Window


If you have questions to me about the program, you can write me a email:

Internet: stepwil@aol.com

The newest version of the Software is in the Internet: ftp://members.aol.com/swenet/edownld.html 

My Homepage is http://members.aol.com/swenet 

Mail: SWE,Stephan Wilhelm Development, Niehler Str. 312, 50735 K”ln,
      Tel.: +49 221-7127380, Fax: +49 221-685184

Best regards, Stephan
