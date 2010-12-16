;include lib.a

;InpSeg segment para public 'input'

.MODEL compact
public prints
.STACK 1024

.DATA
message	db	"Welcome to this world.","$"

.CODE

; Prints a string
; Input: Begin address of string
prints	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	dx
		
	mov	ah,09h ; Intruction to write string to stdout
	mov	dx,[bp+4] ; parameter is 4 higher (bp, ret address, param)
	int	21h
	
	pop	dx
	pop	ax
	pop	bp
	ret	2
prints	endp

;InpSeg ends

end
