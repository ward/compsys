.MODEL compact

.STACK 1024

.DATA

.CODE

; Parameter: string address, string ending in $
stoi	proc	near

stoi	endp

; Local procedure to check if character in dl is element of
; { +, -, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
validch	proc	near
	push	bp
	mov	bp,sp
	
	; Is it a +
	cmp	[bp+4],43 ; 43 is + in ascii
	; do something to indicate it is false
valid:
	; do something to indicate it is true
	; Set a flag? -> HOW?
	ret
validch	endp

end
