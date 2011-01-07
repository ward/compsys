.stack 1024
.data
    randomnumber dw 1254
    powersoften dw 10000,1000,100,10,1
.code
.startup
	call random2
.exit

;generate random number using linear feedback shift register 
;random number is put in ax
random proc near
    push bp
    mov bp,sp
    push bx
    push cx
    push dx
    ;maximum period, put taps at [1,2,4,15]
    ;random number in ax
    mov ax,randomnumber
    mov dx,ax
    ;first tap (mask = 2h)
    and dx,0002h
    ;shift to first position
    mov cl,14
    shl dx,cl ;move to MSB
    ;init bit
    mov bx,dx
    ;second tap at 2 (mask=4h)
    mov dx,ax
    and dx,0004h
    mov cl,13 
    shl dx,cl ;move to MSB
    xor bx,dx
    ;third tap at 4 (mask=10h)
    mov dx,ax
    and dx,0010h
    mov cl,11 ;move to MSB
    shl dx,cl
    xor bx,dx ;xor
    ;fourth tap at 15 (mask=8000h), no shifting required already MSB
    mov dx,ax
    and dx,8000h
    xor bx,dx ;xor
    ;ok bit bound shift in msb
    shr ax,1
    or ax,bx
    ;save for next iteration
    mov randomnumber,ax
    ;done
    pop dx
    pop cx
    pop bx
    pop bp
    ret
random endp

;generate a random number using Oakenfull congruential generator
;x(n+1)=(a*x(n)+b) mod m + straal, a=16333, b=25887, m=2^8, range between straal and 256 + straal, for x
;                                                    m=2^7, range between straal and 128 + straal, for y
;                                                    laagste getal moet de lengte van de straal zijn want anders ligt ons bal buiten de grenzen
random2 proc near
a=16333
b=25887
    push bp
    mov bp,sp
    push bx
    push dx
    mov ax,randomnumber
    mov bx, [bp+...] ;aanpassen
    ;times a
    mov dx,a
    mul dx
    ;add b
    add ax,b ;no need for adc, bits will be lost anyway
    ;mask 8 first bits to perform mod 2^8
    and ax,00FFh
    mov dx, [bx+14]
    add ax, dx
    mov randomnumber,ax
    ;done
    pop dx
    pop bx
    pop bp
    ret
random2 endp
end
