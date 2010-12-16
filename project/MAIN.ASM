;include	lib.a

.MODEL compact

.STACK 1024

.DATA
message	db	"Welcome to this world.","$"

.CODE
extern prints:proto
.STARTUP
	lea	dx,message
	push	dx
	call	prints
.EXIT

end
