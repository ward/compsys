.MODEL compact

;===============
;=== exports ===
;===============
public prints
public print
public newline
public getline


.STACK 1024

.DATA

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
; Input: Begin address of string, note that string has to end in $
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

; Gets line (70 characters max)
; Parameter: address of buffer
; Result: buffer has:
;	first byte: number indicating max characters that were allowed
;	second byte: n amount of characters read in
getline	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	dx

	mov	dx,[bp+4]
	
	; Set max characters to get in first byte of buffer
	mov	al,71
	mov	bx,dx ; Need base register to use like this:
	mov	[bx],al
	
	; Call the software interrupt
	; String in buffer mentioned at bp+4
	mov	ah,0ah
	int	21h
	
	; Todo: set first byte after last character to 0 (or $)
	
	pop	dx
	pop	bx
	pop	ax
	pop	bp
	ret	2
getline	endp

end
