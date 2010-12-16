include mylib.a


InpSeg segment para public 'input'

newline proc far
	push bp
	mov bp,sp
	push ax
	push dx
	
	mov ah,02h
	mov dl,10 ; newline ASCII code
	int 21h
	
	pop dx
	pop ax
	pop bp
	ret
newline endp

InpSeg ends

end
