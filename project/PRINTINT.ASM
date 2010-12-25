.MODEL compact ;one data, one code segment, stack and data segment are grouped

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This works, but maybe we first need to make this "ours" ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

public	printint

.STACK 1024 ;stack, 1024 bytes
.DATA ;data segment, static variables
powersoften dw 10000,1000,100,10,1
maxint db "-32768$"
.CODE ;code segment

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
