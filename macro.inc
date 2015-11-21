$NOLIST

;--------------------------------------------------------------------------------------------------------
; 80188 Macros

; Macros useful asm86 operations on bits and a few others.

; CLR(reg)			- sets register to zero (assume not segment reg)     
; SETBIT(reg, bit)   	- sets bit #bit in register reg (assume not segment reg)
; CLRBIT(reg, bit)   	- clears bit #bit in register reg (assume not segment reg)
; TESTBIT(reg,bit)  	- sets ZF based on bit #bit in register reg (assume not segment reg) 
; COMBIT(reg, bit)    	- complements bit #bit in register reg (assume not segment reg)
; XLATW            		- translate 16-bit value in AX by table pointed to in BX
; READPCB(addr)       	- read PCB register at address addr and return in AX
; WRITEPCB(addr,val) 	- write 16-bit value val to PCB register at address addr
;----------------------------------------------------------------------------------------------------------

; Revision History: 
; 03/03/09 William Fan


; CLR
;
; Description:
; Sets register to zero.
;
; Operation: 
; XOR itself to bitwise clear each bit in the register.
;
; Arguments:					reg - register to clear
;
; Error Handling: 					None
;
; Registers Changed: 				[reg]
; Stack Depth: 					None
;
; Limitations:
; Assume [reg] is not a segment register.
;
; Revision History: 
; 03/03/09 William Fan

%*DEFINE(CLR(reg))   
(
	XOR 	%reg, %reg      ;bitwise clear
)


; SETBIT
;
; Description:
; Sets bit #bit in register reg.
;
; Operation: 
; Rotate to shift bit # around.
;
; Arguments:					reg - register to update
;							bit - bit # to set
;
; Error Handling: 					None
;
; Registers Changed: 				[reg]
; Stack Depth: 					None
;
; Limitations:
; Assume [reg] is not a segment register.
;
; Revision History: 
; 03/03/09 William Fan

%*DEFINE(SETBIT(reg, bit)) 
(
	ROR 	%reg, %bit		;rotate (bit) to low bit
    OR 		%reg, 1         ;set low bit
    ROL 	%reg, %bit      ;reverse rotate to original position
)


; CLRBIT
;
; Description:
; Clears bit #bit in register reg.
;
; Operation: 
; Rotate to shift bit # around.
;
; Arguments:					reg - register to update
;							bit - bit # to clear
;
; Error Handling: 					None
;
; Registers Changed: 				[reg]
; Stack Depth: 					None
;
; Limitations:
; Assume [reg] is not a segment register.
;
; Revision History: 
; 03/03/09 William Fan

%*DEFINE(CLRBIT(reg, bit)) 
(
    NOT %reg             	;complement each bit in the register
    %SETBIT(%reg, %bit) 	;set nominal bit
    NOT %reg            	;complement each bit again (nominal bit cleared)
)


; TESTBIT
;
; Description:
; Sets ZF based on bit #bit in register reg.
;
; Operation: 
; Rotate to shift bit # to lowest bit, then compare with zero.
;
; Arguments:					reg - register to test
;							bit - bit # to test
;
; Error Handling: 					None
;
; Registers Changed: 				[reg]
; Stack Depth: 					2 bytes
;
; Limitations:
; Assume [reg] is not a segment register.
;
; Revision History: 
; 03/03/09 William Fan

%*DEFINE(TESTBIT(reg, bit)) 
(
	PUSH 	%reg           	;save the register
    SHL 	%reg, %bit     	;shift nominal bit to lowest bit
    AND 	%reg, 1        	;clear other bits
    CMP 	%reg, 0        	;CMP will set zero flag if it's zero
    POP 	%reg           	;restore the register (flags not changed)
)


; COMBIT
;
; Description:
; Complements bit #bit in register reg.
;
; Operation: 
; For this macro, we will use our previously coded TESTBIT to decide if we should use
; SETBIT or CLRBIT to complement it.
;
; Arguments:					reg - register to update
;							bit - bit # to complement
;
; Error Handling: 					None
;
; Registers Changed: 				[reg]
; Stack Depth: 					None
;
; Limitations:
; Assume [reg] is not a segment register.
;
; Revision History: 
; 03/03/09 William Fan

%*DEFINE(COMBIT(reg, bit)) LOCAL ClrBit SetBit ComBitFin 
(
    %TESTBIT(%reg, %bit)	;test the nominal bit to find out how to complement
    JZ 		%SetBit			;ZF set means it's zero
	;JNZ 	%ClrBit			;otherwise it's not zero

%ClrBit:
    %CLRBIT	(%reg, %bit)	;which means we clear it like we did before
	JMP 	%ComBitFin
	
%SetBit:
    %SETBIT	(%reg, %bit)	;else we set it like we did before
    ;JMP 		%ComBitFin

%ComBitFin:
    NOP
)


; XLATW
;
; Description:
; Translates AX by value at DS:BX.
;
; Operation: 
; Replace 16-bit value in AX by the value in table pointed to in BX.
;
; Arguments:					None
;
; Error Handling: 					None
;
; Registers Changed: 				AX, BX, CX, DS
; Stack Depth: 					2 bytes
;
; Revision History: 
; 03/03/09 William Fan

%*DEFINE(XLATW) 
(
    PUSH 	BX          	;save registers (cannot POPA)
    PUSH 	CX
    MOV 	CL, 2			;number of bytes
	MUL 	CL          	;value is at [DS:(BX + 2*AX)]
    ADD 	BX, AX      	;complete the arithmetic for table address
	MOV 	AX, DS:[BX] 	;replace value in AX with value at the table address
    POP 	CX				;restore popped registers
    POP 	BX                 
)


; READPCB
;
; Description:
; Returns PCB register in AX.
;
; Operation: 
; Reads from the PCB register at addr and writes it to AX.
;
; Arguments:					addr - address of PCB register
;
; Error Handling: 					None
;
; Registers Changed: 				AX, DX
; Stack Depth: 					2 bytes
;
; Revision History: 
; 03/03/09 William Fan

%*DEFINE(READPCB(addr)) 
(
	PUSH 	DX				;save the register (no need to save AX)
    MOV 	DX, %addr    	;store address in DX (temporarily)
    IN 		AX, DX     	    ;read value from DX and write to AX
    POP 	DX				;restore the register (don't restore AX)
)


; WRITEPCB
;
; Description:
; Write 16-bit value val to PCB register at address addr.
;
; Operation: 
; Use OUT instruction.
;
; Arguments:					addr - address of PCB register
;
; Error Handling: 					None
;
; Registers Changed: 				AX, DX
; Stack Depth: 					2 bytes
;
; Revision History: 
; 03/03/09 William Fan

%*DEFINE(WRITEPCB(addr, val)) 
(
    PUSH 	AX				;save the registers we will use
	PUSH 	DX
    MOV 	DX, %addr    	;move address into DX
    MOV 	AX, %val		;move value to write into AX
    OUT 	DX, AX       	;output value in AX to address point by DX
    POP 	DX           	;restore registers we used
    POP 	AX 
)


$LIST