	NAME  MCRML


; local include files
$INCLUDE(macro.inc)
	
CGROUP	GROUP 			CODE	

CODE 	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, SS:STACK, DS:DATA
		
TESTMACROS:  

MacroTestInit:
        MOV     AX, STACK		;initialize the stack pointer
        MOV     SS, AX
        MOV     AX, DATA     	;initialize the data segment
        MOV     DS, AX

TestCLR:	
	MOV 	AX, 111
	%CLR(AX)

TestSETBIT:
	%SETBIT(AX, 0)

TestCLRBIT:
	MOV 	DX, 0FFFFH
	%CLRBIT(DX, 2)

TestTESTBIT:
	%TESTBIT(DX, 3)
	JZ 		TESTBITWin
	;JNZ 	TESTBITFail

TESTBITFail:	
	JMP 	EndTest

TESTBITWin:
	;JMP 		TestXLATW

TestXLATW:
	%XLATW

TestRdWrt:
	%WRITEPCB(0FFA4H, 0C038H)
	%READPCB(0FFA4H)

EndTest:
	NOP

	CODE 		ENDS


DATA 			SEGMENT WORD PUBLIC 'DATA'
	
DATA 			ENDS
	
;the stack

STACK           SEGMENT STACK  'STACK'

                DB      80 DUP ('Stack ')       ;240 words

TopOfStack      LABEL   WORD

STACK           ENDS


	END			TESTMACROS