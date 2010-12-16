.MODEL compact

;===============
;=== exports ===
;===============
public prints
public print
public newline


.STACK 1024

.DATA
message	db	"Welcome to this world.","$"

.CODE

; Prints character in dl to stdout
print	proc	near
	push	ax

	mov	ah,02h
	int	21h

	pop	ax
	ret
print	endp

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

newline	proc	near
	push	ax
	push	dx
	
	mov	ah,02h
	mov	dl,10 ; newline ASCII code
	int	21h
	
	pop	dx
	pop	ax
	ret
newline endp

end
