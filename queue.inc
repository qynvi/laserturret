;--------------------------------------------------------------------------------------------------------
; RoboTrike Queue Routines
;
; Include file defining the queue structure.
;
; Used in:
;
; QueueInit - Initializes queue of size s at address a.
; QueueEmpty - Checks if the queue is empty.
; QeueFull - Checks if the queue is full.
; Dequeue - Removes a value from the head of the queue. Blocking function.
; Enqueue - Adds a value b to queue at address a. Blocking function.
;----------------------------------------------------------------------------------------------------------

; Revision History:
; 05/01/09 William Fan
;	- Repackage for final release.
; 04/28/09 William Fan
;	- Revised for compliance with new serial routines.
; 02/08/09	William Fan

; Queue constants
Q_MAX_LEN  		EQU     100          ;maximum length of the queue

; Test constants
Q_DFLT_LEN 		EQU     10			 ;default length of the queue

; Structure to represent a queue
QSTRUC     STRUC           			;queue structure declaration

    qlen    	DW      ?           ;nominal length of the queue
    qtail       DW      ?           ;address of the tail pointer
    qhead       DW      ?           ;address of the head pointer
    queue_data  DB      101 dup (?) ;storage space for queue contents

QSTRUC     ENDS
