.MODEL compact

;===============
;=== exports ===
;===============
public	prints
public	print
public	printint
public	newline
public	getline


.STACK 1024

.DATA

; Needed for printint
powersoften dw 10000,1000,100,10,1
maxint db "-32768$"

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

; printint from the examples given in class
;print an integer to stdout
;value on tos (16-bit 2's compl)
printint proc near ;near procedure
	;save dynamic link
	push bp
	;update bp
	mov bp,sp
	;save context
	push ax
	push bx
	push dx
	push si
	;load param in bx
	; Note: +4 because:
	;	a) works in steps of two
	;	b) stack grows down
	;	c) sp = bp atm holds previous bp (because of PUSH bp)
	;	d) bp + 2 is return address (because of CALL)
	;	e) bp + 4 is the number we want (because of PUSH ax)
	mov bx,[bp+4] ;near proc, one word return address
	;handle special case of zero
	test bx,0FFFFh
	jnz printint_nonzero
	mov ah,02h
	mov dl,'0'
	int 21h
	jmp printint_done
printint_nonzero:
	;handle special case of -32768
	cmp bx,-32768
	jnz printint_notintmin
	mov ah,09h
	mov dx,offset maxint
	int 21h
	jmp printint_done
printint_notintmin:
	;print sign
	test bx,8000h
	jz printint_positive
	;if negative,print sign and invert
	;print sign (int 21h, function 02h)
	mov ah,02
	mov dl,'-'
	int 21h
	;invert sign of bx
	neg bx
printint_positive:
	;from now on bx is positive
	;determine largest power of ten smaller than bx
	;init si to point to first element of powersoften array
	mov si,offset powersoften
	; while bx<[si] increment si C: while(bx<powersoften[si]) si++
printint_nextpoweroften:
	cmp bx,[si]
	jge printint_powerfound
	add si,2    
	jmp printint_nextpoweroften
printint_powerfound:
	;ok now print digits
	mov ax,bx
	cwd ;sign extend to DX:AX (32-bit)
	idiv word ptr [si]  ;divide DX:AX by current power of ten, result in AX, remainder in DX
	mov bx,dx  ;move remainder to bx
	mov ah,02h ;print al
	mov dl,al
	;add 48 to convert to ascii
	add dl,48
	int 21h
	;was this the last digit? i.e. [si]==1
	cmp word ptr [si],1
	je printint_done
	add si,2   ;increment si
	jmp printint_powerfound ;repeat for next digit
printint_done:
	;restore context
	pop si
	pop dx
	pop bx
	pop ax
	;restore bp
	pop bp
	;return freeing param from stack (2 bytes)
	ret 2
printint endp

end
