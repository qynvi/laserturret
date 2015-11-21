;--------------------------------------------------------------------------------------
; 80188 Event Handler

; Include files for the 80188 timer event handler. Defines various addresses
; and constants for timers, interrupts, relevant control register values, LED, keypad,
; and chip selects.
;--------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/27/09 William Fan
;	-Verified compatibility with fixed serial.
; 04/26/09 William Fan
;	-Moved all 8255 motor related
;	 defintions to motor.inc.
; 03/02/09 William Fan
;	-Added constants for motor.
; 02/25/09 William Fan
;	-Corrections to PACS, MPCS
; 02/20/09 William Fan
;	-Chip selects.
;	-Keypad address.
; 02/18/09 William Fan


;Peripheral Control Block Base
PCBLocBase	EQU		0FF00h				;PCB default

;Timer Addresses
Tmr0Ctrl	EQU		(PCBLocBase + 56h)	;timer 0 control register
Tmr0MCnt	EQU		(PCBLocBase + 52h)	;timer 0 maxcount A register
Tmr0CCnt	EQU		(PCBLocBase + 50h)	;timer 0 count register

Tmr1Ctrl	EQU	 	(PCBLocBase + 5Eh)	;timer 1 control register
Tmr1MCnt	EQU 	(PCBLocBase + 5Ah)	;timer 1 maxcount A register
Tmr1CCnt	EQU	 	(PCBLocBase + 58h)	;timer 1 count register

Tmr2Ctrl	EQU	 	(PCBLocBase + 66h)	;timer 2 control register
Tmr2MCnt	EQU		(PCBLocBase + 62h)	;timer 2 maxcount A register
Tmr2CCnt	EQU		(PCBLocBase + 60h)	;timer 2 count register

;Timer Control Register
Tmr0CtrlV	EQU		0E000h				;value on timer 0's control register for specific functions
										;1--------------- enable timer
										;-1-------------- write to control
										;--1------------- enable interrupts
										;---0------------ compare register A
										;----------0----- max count = 0
										;-----------0---- no retriggering
										;------------0--- no prescaling
										;-------------0-- no extern clocking
										;--------------0- max count single mode
										;---------------1 one-shot mode (only if first bit is set)
Tmr1CtrlV	EQU		0E001h				;value on timer 2's control register for specific functions
										;1--------------- enable timer
										;-1-------------- write to control
										;--1------------- enable interrupts
										;---0------------ compare register A
										;----------0----- max count = 0
										;-----------0---- no retriggering
										;------------0--- no prescaling
										;-------------0-- no extern clocking
										;--------------0- max count single mode
										;---------------1 continuous mode
Tmr2CtrlV	EQU		0E001h 				;value on timer 2's control register for specific functions
										;1---------------  enable timer
										;-1--------------  write to control
										;--1-------------  enable interrupts
										;---------------1  continuous mode

;INT2 Pin Addresses
Int2Ctrl	EQU		(PCBLocBase + 03Ch)	;int2 control register

;INT2 Control Register
Int2CtrlV   EQU     0000000000010001B    ;0000000000-----  reserved bits
                                        ;------------001  priority 1
										;-----------0---  unmasked
                                        ;----------1----  level triggered

;Interrupt Vectors

Tmr0Int	    EQU		8	                ;timer 0 interrupt vector label
Tmr1Int		EQU		18					;timer 1 interrupt vector label
Tmr2Int		EQU		19					;timer 2 interrupt vector label
Int2Int		EQU     14                  ;INT2 interrupt vector label

;Clocking
TmrCntValue	EQU		2304	 			;number of timer counts in 1 ms, to generate 1 KHz IRQ on timer 2
Tmr0CntV	EQU		540					;number of timer counts per interrupt on timer 0
Tmr1CntV	EQU		57600				;number of timer counts per interrupt on timer 1

;Interrupt Addresses
EOI			EQU	 	(PCBLocBase + 022h)	;the address of EOI register
IntIRQCtrl	EQU   	(PCBLocBase + 032h)	;the address of internal interrupt controller
IntIRQCtrlV	EQU		00001h     			;internal control value to enable timers with priority 1

;EOI
GenEOIVal	EQU		8000h 				;EOI command (general)
TmrEOIVal	EQU  	8h	  				;EOI command (timer)
Int2EOI     EQU     0000Eh      		;EOI command (INT2)

;Interrupt Constants
FirstResvIRV EQU 	1	  				;bracket a section of interrupt vectors we use for EvH (rest illegal)
FinalResvIRV EQU	3
TotalIRV	 EQU 	256	  				;total interrupts in the entire table

;Chip Select
PACSregLoc	EQU		(PCBLocBase + 0A4h)	;PACS register address
MPCSregLoc	EQU		(PCBLocBase + 0A8h)	;MPCS register address
PACSctrlV   EQU     00003h          	;PCS base at 0, 3 wait states
                                        ;0000000000------  starts at address 0
                                        ;----------000---  reserved
                                        ;-------------0--  wait for RDY inputs
                                        ;--------------11  3 wait states
MPCSctrlV   EQU     00183h          	;PCS in I/O space, use PCS5/6, 3 wait states
                                        ;0---------000---  reserved
                                        ;-0000001--------  MCS is 8KB
                                        ;--------1-------  output PCS5/PCS6
                                        ;---------0------  PCS in I/O space
                                        ;-------------0--  wait for RDY inputs
                                        ;--------------11  3 wait states

;Device Addresses
LEDLoc		EQU		0000h				;LED display's address location in I/O
KeypadLoc	EQU		0080h				;keypad's address location  in I/O
