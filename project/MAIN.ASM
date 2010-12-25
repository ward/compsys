.MODEL compact

.STACK 1024

.DATA
message	db	"Please enter a number:","$"
; Buffer, size 100
buffer	db	100 dup (0)

.CODE
;===============
;=== Imports ===
;===============

extern	print:proto
extern	prints:proto
extern	newline:proto
extern	getline:proto
extern	stoi:proto

.STARTUP
	lea	dx,message
	push	dx
	call	prints
	call	newline
	
	mov	ax,offset buffer
	push	ax
	call	getline
	call	newline
	
	; return value
	sub	sp,2
	mov	bx,offset buffer
	add	bx,2
	push	bx
	call	stoi
	;pop	dx
.EXIT

end
