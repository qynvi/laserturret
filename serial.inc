; serial.inc
; Defines serial Rx/Tx status and the size of the Rx/Tx queue structures.
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 04/26/09 William Fan
;	-Added constants for fixed serial routines.
;	-Greatly reduced length of Rx/Tx queues, removed limitation of size must be 2^n.
; 03/08/09 William Fan

RX_SIZE         	EQU     20             	;length of our Rx/Tx queue strucs
TX_SIZE         	EQU     20

ACE_CLK_MSB  		EQU     0004H           ;BRG clock
ACE_CLK_LSB  		EQU     6500H


SERIAL_DFLT		    EQU     00000011B      	;8 words, no parity, one stop bit
SERIAL_IRQ	       	EQU     00000111B   	;turn on data available and receiver line status interrupts
											;ACE_IER_ERBF		EQU         00000001B               	;enable received data available interrupt
											;ACE_IER_ELSI     	EQU         00000100B               	;enable receiver line status interrupt

SERIAL_ERROR_NULL   EQU     0               ;serial error FALSE
SERIAL_ERROR_TRUE 	EQU     1               ;serial error TRUE
SERIAL_RX_BITDROP   EQU     00000001B       ;special bit to mask into SerialError if Rx integrity fails check
SERIAL_TX_MASK  	EQU     00011110B       ;special bits to isolate Tx error bits
SERIAL_BR_DEFAULT	EQU		9600			;define an initial baud rate with which to reset ACE when InitSerial firstrun or EXTRNcalled
SERIAL_BR_DFLTDVSR	EQU		60				;define the divisor to produce the default baud rate
											;18.432e6 / [(SERIAL_BR_DEFAULT / 2) * 4 * 16] = 60
SERIAL_MIN_BR		EQU		5				;lowest value of br divisor such that baud rate fits in 16 bits
