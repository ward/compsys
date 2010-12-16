.MODEL compact

.STACK 1024

.DATA
message	db	"Welcome to this world.","$"

.CODE
;===============
;=== Imports ===
;===============

extern print:proto
extern prints:proto
extern newline:proto

.STARTUP
	lea	dx,message
	push	dx
	call	prints
	mov	dl,'!'
	call	print
	call	newline
	call	print
	call	newline
	call	print
	call	newline
	call	print
.EXIT

end
