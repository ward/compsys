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

.STARTUP
	lea	dx,message
	push	dx
	call	prints
	call	newline
	
	mov	ax,offset buffer
	push	ax
	call	getline
	call	newline
	
	; print 3rd character
	mov	bx,offset buffer
	mov	dl,[bx+4]
	call	print
.EXIT

end
