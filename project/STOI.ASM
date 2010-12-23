.MODEL compact

; exports

.STACK 1024

.DATA

.CODE

; Parameter: string address, string ending in $
stoi	proc	near
	push	bp
	mov	bp,sp
	; 2 local vars
	sup	sp,2
	; sign = 1; access: [bp-2]
	mov	[bp-2],1
	; total = 0; access: [bp-4]
	mov	[bp-4],0
	
	; save context
	push	ax
	push	bx
	
	; Move the address of the beginning of the string into our base register
	; so we can use it.
	mov	bx,[bp+4]
	
	; 45 is -
	cmp	[bx],45
	jnz	notminus
	; If first character is a -, ignore it as being first and set sign
	add	bx,1
	mov	[bp-2],-1
	jmp	notplus
notminus:
	; 43 is +
	cmp	[bx],43
	jnz	notplus
	add	bx,1
notplus:
	; Now we have to start looping over our digits
	
	
	; Will finish in case of:
	;  * overflow
	;  * invalid character	
finish:
	
	pop	bx
	pop	ax
	pop	bp
	ret	2
stoi	endp

; Local procedure to check if CHARACTER in dl is element of
; { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
isdigit	proc	near	
	; numbers range from 48 to 57 in asciitable
	cmp	al,48
	jl	notvalid
	cmp	al,58
	jl	valid
	
	push	ax
	mov	ax,0
notvalid:
	; Until we find a better way, use cmp to set the zero flag to 1
	cmp	ax,0
	pop	ax
	ret
valid:
	; Use cmp to set zero flag to 0
	cmp	ax,1
	pop	ax
	ret
isdigit	endp

end
