;--------------------------------------------------------------------------------------------------------
; Texas Instruments TL16C450 Asynchronous Communications Element

; Include file for the TL16C450 ACE which defines the locations and values of
; all control registers.
;----------------------------------------------------------------------------------------------------------
;
; Revision History:
; 05/01/09 William Fan
;	-Repackage for final release.
; 03/07/09 William Fan


;REGISTER ADDRESSES

;ACE register base address
ACE_BASE_LOC        EQU         100h                    	;base address of 16C450

;ACE register relative addreses
ACE_DLL_LOC         EQU         ACE_BASE_LOC + 0            ;divisor latch (LSB) location
ACE_DLM_LOC         EQU         ACE_BASE_LOC + 1         	;divisor latch (MSB)

ACE_RBR_LOC         EQU         ACE_BASE_LOC + 0           	;receiver buffer register location
ACE_THR_LOC			EQU         ACE_BASE_LOC + 0            ;transmitter holding register
ACE_IER_LOC         EQU         ACE_BASE_LOC + 1         	;interrupt enable register
ACE_IIR_LOC         EQU         ACE_BASE_LOC + 2         	;interrupt identification register
ACE_LCR_LOC         EQU         ACE_BASE_LOC + 3         	;line control register
ACE_MCR_LOC         EQU         ACE_BASE_LOC + 4         	;modem control register
ACE_LSR_LOC         EQU         ACE_BASE_LOC + 5         	;line status register
ACE_MSR_LOC         EQU         ACE_BASE_LOC + 6         	;modem status register

ACE_SCR_LOC         EQU         ACE_BASE_LOC + 7         	;scratch register location

ACE_BRG_DIV      	EQU         ACE_BASE_LOC + 0            ;baud rate generator divisor


;REGISTER CONTROL VALUES

;IER - interrupt enable register
ACE_IER_ERBF		EQU         00000001B               	;enable received data available interrupt
ACE_IER_ETBE		EQU         00000101B               	;disable ETBE interrupt
ACE_IER_ELSI     	EQU         00000100B               	;enable receiver line status interrupt
ACE_IER_EDSSI    	EQU         00001000B               	;enable modem status interrupt
;ACE_IER_NULL4		EQU			00010000B						;UNUSED
;ACE_IER_NULL5		EQU			00100000B						;UNUSED
;ACE_IER_NULL6		EQU			01000000B						;UNUSED
;ACE_IER_NULL7		EQU			10000000B						;UNUSED

;IIR - interrupt identification register
ACE_IIR_PEND 		EQU         00000001B               	;clear for interrupt pending
ACE_IIR_MASK     	EQU         00000110B               	;identify highest priority pending IRQ
;ACE_IIR_NULL3		EQU			00001000B						;UNUSED
;ACE_IIR_NULL4		EQU			00010000B						;UNUSED
;ACE_IIR_NULL5		EQU			00100000B						;UNUSED
;ACE_IIR_NULL6		EQU			01000000B						;UNUSED
;ACE_IIR_NULL7		EQU			10000000B						;UNUSED
ACE_IIR_IRQ_RLS     EQU         00000110B               	;receiver line status IRQ 		(PRIORITY 1 - HIGHEST)
ACE_IIR_IRQ_RDA	    EQU         00000100B               	;received data available IRQ 		(PRIORITY 2)
ACE_IIR_IRQ_THRE    EQU         00000010B               	;transmitter holding register is empty (PRIORITY 3)
ACE_IIR_IRQ_MS      EQU         00000000B               	;modem status IRQ 			(PRIORITY 4 - LOWEST)

;LCR - line control register
ACE_LCR_WL_MASK 	EQU         00000011B					;bit 0 and 1 identify word length
ACE_LCR_STB		    EQU         00000100B               	;number of stop bits (by word length in bit 0 and 1)
															;BIT 2	WL(bits)	#STOP BITS
															;0		ANY		1
															;1		5		1.5
															;1		6		2
															;1		7		2
															;1		8		2
ACE_LCR_PAR_MASK    EQU         00111000B					;bit 3 and 4 and 5 enable and set parity
ACE_LCR_BREAK   	EQU         01000000B               	;set break
ACE_LCR_DLAB	  	EQU         10000000B               	;divisor latch access bit of baud generator
ACE_LCR_WL_MAX 		EQU         00000011B               	;serial character word length MAX of 8 bits
ACE_LCR_WL_5   		EQU         00000000B               	;serial character word length of 5 bits
ACE_LCR_WL_6   		EQU         00000001B					;serial character word length of 6 bits
ACE_LCR_WL_7   		EQU         00000010B					;serial character word length of 7 bits
ACE_LCR_WL_8   		EQU         00000011B					;serial character word length of 8 bits
ACE_LCR_PAR_ON   	EQU         00001000B               	;parity enable
ACE_LCR_PAR_OFF  	EQU         00000000B					;parity disable
ACE_LCR_EPS     	EQU         00010000B              	 	;even parity select
ACE_LCR_OPS     	EQU         00000000B               	;odd parity select
ACE_LCR_SPS   		EQU         00100000B              		;stick parity select
ACE_LCR_PAR_CLR    	EQU         ACE_LCR_SPS OR ACE_LCR_EPS	;parity bit t/c as cleared (assume parity enabled)
ACE_LCR_PAR_SET	    EQU         ACE_LCR_SPS OR ACE_LCR_OPS	;parity bit t/c as set (assume parity enabled)

;LSR - line status register
ACE_LSR_DR       	EQU         00000001B               	;data ready
ACE_LSR_IRQ   		EQU         00011110B               	;all LSR registers which cause IRQ
ACE_LSR_OE       	EQU         00000010B               	;overrun error
ACE_LSR_PE       	EQU         00000100B               	;parity error
ACE_LSR_FE       	EQU         00001000B               	;framing error
ACE_LSR_BI       	EQU         00010000B               	;break interrupt indicator
ACE_LSR_THRE     	EQU         00100000B               	;transmit holding register empty indicator
ACE_LSR_TEMT     	EQU         01000000B               	;transmitter empty indicator
;ACE_LSR_NULL8	 	EQU	     		10000000B						;UNUSED

;MCR - modem control register
ACE_MCR_DTR      	EQU         00000001B               	;data terminal output low/high
ACE_MCR_RTS      	EQU         00000010B               	;request to send output low/high
ACE_MCR_OUT1     	EQU         00000100B               	;user controlled output 1 signal low/high
ACE_MCR_OUT2     	EQU         00001000B               	;user controlled output 2 signal low/high
ACE_MCR_LOOP     	EQU         00010000B               	;local loopback for diagnostic testing of the ACE
															;1. SOUT asserted high
															;2. SIN is disconnected
															;3. output of the transmitter shift register is feedbacked into RSR
															;4. CTS, DSR, DCD, RI are all disconnected
															;5. DTR, RTS, OUT1, OUT2 are internally connected to MCIs
															;6. MCO terminals are forced to inactive states.
ACE_MCR_NULL5		EQU			00100000B					;UNUSED
ACE_MCR_NULL6		EQU			01000000B					;UNUSED
ACE_MCR_NULL7		EQU			10000000B					;UNUSED

;MSR - modem status register
ACE_MSR_DCTS     	EQU         00000001B               	;delta clear to send indicator
ACE_MSR_DDSR     	EQU         00000010B               	;delta data set ready indicator
ACE_MSR_TERI     	EQU         00000100B               	;trailing edge of ring indicator detector
ACE_MSR_DDCD     	EQU         00001000B               	;delta carrier detect indicator
ACE_MSR_CTS      	EQU         00010000B               	;complement of the clear to send (CTS) input
															;when MCRb4 set, should EQU MCRb1 (RTS)
ACE_MSR_DSR      	EQU         00100000B               	;complement of the data set ready (DSR) input
															;when MCRb4 set, should EQU MCRb0 (DTR)
ACE_MSR_RI       	EQU         01000000B               	;complement of the ring indicator (RI) input
															;when MCRb4 set, should EQU MCRb2 (OUT1)
ACE_MSR_DCD      	EQU         10000000B               	;complement of the data carrier detect (DCD) input
															;when MCRb4 set, should EQU MCRb3 (OUT2)
