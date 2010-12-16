include mylib.a
.MODEL compact ;multiple data, one code segment, stack and data segment are grouped

;-------------------------------------------------------------------------
; stack and data segments
.STACK 1024 ;stack, 1024 bytes
.DATA ;data segment, static variables
maxint db "-32768$"

.CODE ;code segment
.STARTUP ; start main, sets ds to beginning of data segment, updates ss to ds and adjusts sp acordingly
	call newline
	call newline
	call newline
.EXIT ; end main/exit to dos
end
