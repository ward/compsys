.MODEL compact ;multiple data, one code segment, stack and data segment are grouped

;-------------------------------------------------------------------------
;macros
setvideomode macro NewMode,OldMode
    ;get current mode, set in al
    mov ah,0Fh
    int 10h
    mov OldMode,al
    ;set new mode
    mov ah,00h
    mov al,NewMode
    int 10h
endm

restorevideomode macro OldMode 
    mov ah,00h
    mov al,OldMode
    int 10h
endm

blankscreenmode13 macro
    local blankscreenmode13_wait1,blankscreenmode13_wait2
    ;store context
    push ax
    push cx
    push dx
    push es
    push di
    ;set target registers for stosb
    mov ax,0A000h
    mov es,ax
    xor di,di
    ;wait for vblank
    mov dx, 03dah ; VGA status port                 
blankscreenmode13_wait1: ;if in vblank, wait until vblank finishes
    in al, dx
    and al, 8
    jnz blankscreenmode13_wait1                 ; busy wait
blankscreenmode13_wait2:                        ;wait until begin of vblank
    in al, dx
    and al, 8
    jz blankscreenmode13_wait2             ; and again
    ;set fill color
    mov al,0
    mov cx,64000 ;size of video ram
    rep stosb ;blit
    pop di
    pop es
    pop dx
    pop cx
    pop ax
endm
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
;const defines
rectx = 100
recty =10
circleradius = 16
rectcolor =50
;-------------------------------------------------------------------------

;-------------------------------------------------------------------------
; stack and data segments
.STACK 1024 ;stack, 1024 bytes
.FARDATA ;for storing off-line buffer
    videobuffer db 64000 dup (0)
.DATA ;data segment, static variables
oldvideomode db ?
;rectangle db rectwidth dup (rectcolor),(rectheight-2) dup (rectcolor,(rectwidth-2) dup (0),rectcolor),rectwidth dup (rectcolor)
rectangle db (4*circleradius*circleradius) dup (3)

; Voor printint
powersoften dw 10000,1000,100,10,1
maxint db "-32768$"

.CODE ;code segment
.STARTUP ; start main, sets ds to beginning of data segment, updates ss to ds and adjusts sp acordingly
;	mov bx,offset rectangle
;	mov ax,1
;	add bx,ax
;	mov al,rectcolor
;	mov [bx],al
	call makecircle
	call vgamodeex1 
.EXIT ; end main/exit to dos
 ;procedures
 

; We're going to fill the memory in a way to draw a circle
; color if (x-r)^2 + (y-r)^2 <= r^2
makecircle proc near
	; Save dynamic link
	push bp
	; Update base pointer
	mov bp,sp
	; Save context
	; Note that we only need to save what we will use
	push ax
	push bx
	push cx
	push dx
	
	; Do our thing
	; Puts r^2 on stack
	mov ax,circleradius*circleradius
	push ax
	; y-value = 2r
	xor cx,cx
	mov cl,2*circleradius
makecircleloopy:
	push cx
	; x-value = 2r
	xor cx,cx
	mov cl,2*circleradius
makecircleloopx:
	; Do (r - x)^2, we use ?l because multiplying goes twice as big
	; eg al -> ax, ax -> dx:ax
	xor ax,ax
	mov al,circleradius
	sub al,cl
	imul al
	mov dx,ax;(r-x)^2 in dx
	; Do (r - y)^2
	mov al,circleradius
	mov bx,[bp-12]
	sub al,bl ; We had placed outer cx (y) on the stack
	imul al
	add ax,dx ; (r-x)^2 + (r-y)^2 in ax
	cmp ax,[bp-10] ; Compare with r^2
	jg makecircleskipcolor ; Jump if r^2 > (r-x)^2 + (r-y)^2

	; Calculate the offset of the point we just checked
	; and color it.
	mov bx,offset rectangle
	xor dx,dx
	mov dx,32
	mov ax,[bp-12]
	;dec ax ; anders zitten we te ver
	imul dl ; Toen hier dx stond, kwam het resultaat in dx:ax
	add bx,ax
	add bx,cx ; 32 * y + x
	; We have to use al instead of ax,
	; otherwise we write a colored pixel followed by a black one
	mov al,rectcolor
	mov [bx],al

makecircleskipcolor:
	; Op deze manier loopen ipv met "loop" omdat
	; dat slechts voor nabije labels werkt (~42 instructies?)
	dec cx
	jns makecircleloopx
	pop cx
	dec cx
	jns makecircleloopy
	
	; r^2 off again
	pop ax

	;restore context
	pop dx
	pop cx
	pop bx
	pop ax
	;restore bp
	pop bp
	;return, removing parameter
	ret
makecircle endp
 
vgamodeex1 proc near
  ;save dynamic link
  push bp
  ;update base pointer
  mov bp,sp
  ;save context
  push ax
  push cx
  push dx
  push si
  push di
  ;go to mode 13 and draw a stupid rectangle
  ;go to mode 13
  setvideomode 13h,oldvideomode     
  ;draw rectangle to backbuffer
  ;start with first line
  ;rep movsb source in ds:si, destination in es:di
  mov si,offset rectangle
  mov di,seg videobuffer
  mov es,di
  mov di,offset videobuffer
  ;adjust di to account for rectx,recty
  add di,rectx+320*recty
  ;init cx for loop (height of rectangle)
  mov cx,2*circleradius
vgamodeex1_vertical:
  push cx ;save cx on stack so it can be used for rep movsb
  mov cx,2*circleradius
  rep movsb
  ;update si and di to point to next line
  ;add si,rectwidth
  add di,320-2*circleradius
  pop cx ;restore cx for loop
  loop vgamodeex1_vertical
  ;change registers for rep movsb to video ram
  mov dx,seg videobuffer
  mov ds,dx
  mov si,offset videobuffer
  mov dx,0A000h
  mov es,dx
  xor di,di
  ;wait for vblank to write to video ram
  mov dx, 03dah ; VGA status port             
asciimodeex1_wait1: ;if in vblank, wait until vblank finishes
  in al, dx
  and al, 8
  jnz asciimodeex1_wait1                 ; busy wait
asciimodeex1_wait2:                        ;wait until begin of vblank
  in al, dx
  and al, 8
  jz asciimodeex1_wait2                  ; and again
  mov cx,64000
  rep movsb ;blit
  ;wait for key pressed
  xor ah,ah
  int 16h
  ;clear screen
  blankscreenmode13
  ;wait for key pressed
  xor ah,ah
  int 16h
  ;reset ds segment register
  mov ax,@data
  mov ds,ax
  ;restore old videomode
  restorevideomode oldvideomode
  ;restore context
  pop di
  pop si
  pop dx
  pop cx
  pop ax
  ;restore bp
  pop bp
  ;return, removing parameter
  ret
  vgamodeex1 endp
  
newline proc near
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
