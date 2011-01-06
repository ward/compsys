.MODEL compact

; exports
public	stoi

.STACK 1024

.DATA

.CODE

; Converts string to an int: [+-]?\d*
; Also stops at overflow
; Parameter: return value, string begin address
; Return: return value on stack
stoi	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	dx
	; 1 local var
	sub	sp,2
	; sign = 1; access: [bp-8]
	mov	ax,1
	mov	[bp-8],ax
	; returnvalue = total = 0; access: [bp+6]
	mov	ax,0
	mov	[bp+6],ax
	
	; Move the address of the beginning of the string into our base register
	; so we can use it.
	mov	bx,[bp+4]

	; 45 is -
	mov	al,45
	cmp	[bx],al
	jnz	notminus
	; If first character is a -, ignore it as being first and set sign
	add	bx,1
	mov	ax,-1
	mov	[bp-8],ax
	jmp	notplus
notminus:
	; 43 is +
	mov	al,43
	cmp	[bx],al
	jnz	notplus
	add	bx,1
notplus:
	; Now we have to start looping over our characters
	; We will keep current in [bx] at all time
	mov	al,[bx]
	call	isdigit
	jc	dosign
	; It is a digit, so multiply current number by 10, then add it
	; (converting char to int before adding)
	mov	ax,[bp+6]
	mov	dx,10
	mul	dx ; QUESTION: Is this interpreted as 8 or 16 bit? -> Need 16
	; Overflow means we end
	jo	dosign
	; Add current
	mov	[bp+6],ax
	mov	al,[bx]	; We only want one character
	cbw		; Sign extend al to ax
	sub	ax,48
	add	[bp+6],ax
	jo	dosign
	; Nothing went wrong, repeat for next character
	add	bx,1
	jmp	notplus
	
	; Will finish in case of:
	;  * overflow
	;  * invalid character (non number)
dosign:
	mov	ax,1
	cmp	[bp-8],ax
	jz	finish
	; sign change in two's complement means inverting and then adding 1
	mov	ax,[bp+6]
	not	ax
	add	ax,1
	mov	[bp+6],ax
finish:	
	; remove local var
	add	sp,2
	pop	dx
	pop	bx
	pop	ax
	pop	bp
	ret	2
stoi	endp

; Local procedure to check if CHARACTER in al is element of
; { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
; Carry flag to 1 if notvalid
; Carry flag to 0 if valid
isdigit	proc	near
	pushf
	; numbers range from 48 to 57 in asciitable
	cmp	al,48
	jl	notvalid
	cmp	al,58
	jl	valid
notvalid:
	popf
	; carry flag to 1
	stc
	ret
valid:
	popf
	; carry flag to 0
	clc
	ret
isdigit	endp

end
