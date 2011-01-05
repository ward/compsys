;;;;;;;;;;;;
; BALL ADT ;
;;;;;;;;;;;;
.MODEL compact

; exports
public	ball_new
public	ball_draw
public  ball_move
public	ball_bounce
public  botsing

.STACK 1024

.DATA

.CODE

; ball_new address x y rico_x rico_y radius colour
; Address must be the beginning of XXX free bytes TODO
ball_new	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	cx
	push	dx

	; Begin address in bx
	mov	bx,[bp+16]

	; Moving things into the reserved space
	; curr_x
	mov	ax,[bp+14]
	mov	[bx],ax
	; curr_y
	mov	ax,[bp+12]
	mov	[bx+2],ax
	; start_x
	mov	ax,[bp+14]
	mov	[bx+4],ax
	; start_y
	mov	ax,[bp+12]
	mov	[bx+6],ax
	; t, internal counter
	mov	ax,0
	mov	[bx+8],ax
	; rico_x
	mov	ax,[bp+10]
	mov	[bx+10],ax
	; rico_y
	mov	ax,[bp+8]
	mov	[bx+12],ax
	; radius
	mov	ax,[bp+6]
	mov	[bx+14],ax
	; colour
	mov	ax,[bp+4]
	mov	[bx+16],ax

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp

	; ATTENTION:
	; As long as concept is not fully worked out, doublecheck
	; that the correct number of parameters is removed from the stack!
	ret	14 ; 7 parameters
ball_new	endp


; Something here to grab the curr x etc from "inside"
; Interaction!
; eg: ball_get_x, ball_get_y, ball_get_r, ...
; Make them behave like this:
; Parameter (ball's address) in ax
; Call function
; Result in ax

ball_get_x	proc	near
	mov	bx,ax
	mov	ax,[bx]
	ret
ball_get_x	endp
ball_get_y	proc	near
	mov	bx,ax
	mov	ax,[bx+2]
	ret
ball_get_y	endp
ball_get_r	proc	near
	mov	bx,ax
	mov	ax,[bx+14]
	ret
ball_get_r	endp
ball_get_c	proc	near
	mov	bx,ax
	mov	ax,[bx+16]
	ret
ball_get_c	endp



; We'll draw straight to the screen
; ball_draw(addressball)
ball_draw	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	cx
	push	dx
	push	es
	push	di

	; Address of the ball can be found on bp+4

	; Put radius^2 on the stack
	mov	ax,[bp+4]
	call	ball_get_r
	; Radius is positive and we'll keep it below 128 so al is the same.
	; Result in ax
	mul	al
	push	ax

	; Get 2*radius (Note that this may need 2*r+1 instead), we'll see.
	; This is the y to loop through
	; We are assuming constraints on the radius size such that 2*r < 127
	mov	ax,[bp+4]
	call	ball_get_r
	mov	cx,ax
	add	cx,cx
iterdraw_y:
	push	cx
	; Get the beginvalue again, this represents our x to loop through
	mov	ax,[bp+4]
	call	ball_get_r
	mov	cx,ax
	add	cx,cx
iterdraw_x:
	; Do (r - x)^2
	mov	ax,[bp+4]
	call	ball_get_r
	sub	al,cl
	imul	al	; Result in ax !
	mov	dx,ax
	; Now (r - y)^2
	mov	ax,[bp+4]
	call	ball_get_r
	mov	bx,sp
	mov	bx,[bx]	; y was pushed on the stack at the begining of iter y!
	sub	al,bl
	imul	al
	; Add those two together, it has to be smaller or equal to r^2
	add	ax,dx
	; r^2 was pushed on the stack and is at sp+2 now
	mov	bx,sp
	cmp	ax,[bx+2]
	jg	draw_continue	; This point wasn't part of the cirle

	; Now we colour the appropriate dot on the screen.
	; If (x_m, y_m) are the coordinates of middle of the circle,
	; and the screen is 320 wide and 200 high,
	; and x and y are the values we just checked
	; then we are working with the dot at memory
	; x_m + 320*y_m + x - r + (y - r) * 320
	; Notice we also should check that we are within the screen.
	; This due to the balls moving at a speed greater than 1.
	; Meaning: 0 <= x_m + x - r < 320
	; 	and 0 <= y_m + y - r < 200

	; First, let's get y_m + y - r
	mov	bx,sp
	mov	dx,[bx]	; y
	mov	ax,[bp+4]
	call	ball_get_y
	add	dx,ax	; y + y_m
	mov	ax,[bp+4]
	call	ball_get_r
	sub	dx,ax	; y + y_m - r in dx
	; If negative, dont draw dot
	js	draw_continue
	; If >= 200, don't draw either
	cmp	dx,200
	jns	draw_continue
	; Now to do (y + y_m - r) * 320
	mov	ax,320
	mul	dx
	; Result is now in dx:ax, but due to our restrictions, we know our
	; result is in ax (completely). Note di is unsigned.
	mov	di,ax

	; Now we do x_m + x - r
	mov	dx,cx	; x
	mov	ax,[bp+4]
	call	ball_get_x
	add	dx,ax	; x + x_m
	mov	ax,[bp+4]
	call	ball_get_r
	sub	dx,ax	; x + x_m - r in dx
	; If negative, skip
	js	draw_continue
	; or >= 320
	cmp	dx,320
	jns	draw_continue
	add	di,dx

	; Now to colour the dot. Notice that the colour is only 8 bit (unsigned)
	mov	ax,[bp+4]
	call	ball_get_c
	; This is the segment of the screen
	mov	dx,0A000h
	mov	es,dx
	; This moves the value in al to es:di
	; Now the dot is coloured
	stosb

draw_continue:
	; As long as x >= 0, we keep going
	dec	cx
	jns	iterdraw_x
	; Same for y
	pop	cx
	dec	cx
	jns	iterdraw_y

	; r^2 can go off the stack again
	pop	ax

	pop	di
	pop	es
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret	2
ball_draw	endp


; Moves the ball
ball_move	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	cx
	push	dx

	; Firstly, increase internal counter t
	; Then, recalculate x and y
	mov	bx,[bp+4]	; address of the ball
	mov	dx,[bx+8]	; t
	inc	dx
	mov	[bx+8],dx
	; Recalculate positions
	push	bx
	mov	ax,0	; for x
	call	ball_calc_coor
	push	bx
	mov	ax,2	; for y
	call	ball_calc_coor
	

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret	2
ball_move	endp

; Private function, recalculates the mentioned coordinate
; ax = 0 -> x
; ax = 2 -> y
; tos = balladdress
ball_calc_coor	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	cx
	push	dx

	mov	bx,[bp+4]
	mov	dx,[bx+8]	; t
	; the offset, further use of bx will differ between x and y
	; Note, this heavily depends on the order of the data!
	add	bx,ax
	; Get rico
	mov	ax,[bx+10]
	imul	dx
	; dx:ax now holds ax*cx = rico * t
	; but due to limitations on the screen width and height as well
	; as limitations on our rico, we only have to look at ax
	; So we add the start position and save everything
	mov	dx,[bx+4]
	add	ax,dx
	mov	[bx],ax

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret	2
ball_calc_coor	endp


; This will handle all the collisions.
; Parameter is the begin address of an array of addresses to balls.
ball_bounce	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	cx
	push	dx

	mov	bx,[bp+4]
	; We will just walk through the array till we reach an element that
	; is 000000.
bounce_loop:
	mov	ax,[bx]
	cmp	ax,0
	jz	done_all
	; Save the current position in the array
	push	bx
	; Now we have the address of the ball in bx
	mov	bx,ax

	; === WALLS
	; == Left: Collision if x <= r
bounce_left_wall:
	mov	ax,[bx]	; x
	mov	dx,[bx+14]	; r
	; x <= r iif r - x >= 0
	cmp	dx,ax
	js	bounce_top_wall
	; Negate rico_x
	mov	ax,[bx+10]
	neg	ax
	mov	[bx+10],ax
	call	ball_reset
	
	; == Top: Collision if y <= r
bounce_top_wall:
	mov	ax,[bx+2]	; y
	mov	dx,[bx+14]	; r
	; y <= r iif r - x >= 0
	cmp	dx,ax
	js	bounce_right_wall
	; Negate rico_y
	mov	ax,[bx+12]
	neg	ax
	mov	[bx+12],ax
	call	ball_reset

	; == Right: Collision if x + r >= 319
bounce_right_wall:
	mov	ax,[bx]	; x
	mov	dx,[bx+14]	; r
	add	ax,dx
	cmp	ax,319
	js	bounce_bottom_wall
	; Negate rico_x
	mov	ax,[bx+10]
	neg	ax
	mov	[bx+10],ax
	call	ball_reset

	; == Bottom: Collision if y + r >= 199
bounce_bottom_wall:
	mov	ax,[bx+2]	; y
	mov	dx,[bx+14]	; r
	add	ax,dx
	cmp	ax,199
	js	bounce_wall_end
	; Negate rico_y
	mov	ax,[bx+12]
	neg	ax
	mov	[bx+12],ax
	call	ball_reset

bounce_wall_end:
	; Later there will be checking here for collisions with other balls
	
	; Get current position in the array back and move it to the next
	; step of the iteration
	pop	bx
	add	bx,2
	jmp	bounce_loop
	

done_all:

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret	2
ball_bounce	endp

; This function sets
;	start_x = curr_x
;	start_y = curr_y
;	t = 0
; Parameter (ball address) is in bx
ball_reset	proc	near
	push	ax
	push	bx
	; x
	mov	ax,[bx]
	mov	[bx+4],ax
	; y
	mov	ax,[bx+2]
	mov	[bx+6],ax
	; t
	mov	ax,0
	mov	[bx+8],ax
	pop	bx
	pop	ax
	ret
ball_reset	endp

; This one simply crashes it all, rewrite
ball_move_n proc near
	push bp
	mov bp, sp
	push ax
        push bx
	push cx
	push dx
counter:
	mov bx, [bp+4]  ;neemt het adres van de bal
	mov ax, [bx+8]  ;neemt de counter t
	inc ax ;verhoogt de counter met 1
	mov [bx+8], ax
positie_x:
	mov dx, [bx+10] ;neemt rico x
	mul dx ;ax*dx zit in ax
        mov cx, [bx+4] ;neem start-x van de bal
        add ax, cx    ;in ax zit t*rico_x + x_0
        push ax
        push bx
	push dx
        call check_ball_x
	pop dx
        pop bx
        pop ax
positie_y:
	mov ax, [bx+8]  ;neemt de counter
	mov dx, [bx+12] ;neemt rico y
	mul dx          ;ax= t*rico_y
	mov cx, [bx+6]  ;cx bevat start-y van de bal
	add ax, cx      ;ax= t*rico_y + y_0
	push ax
	push bx 
	push dx
        call check_ball_y
	pop dx
	pop bx
	pop ax
ball_continue:
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
ball_move_n	endp

check_ball_x proc near
first:
	pop dx
	pop bx
	pop ax
	cmp ax, 0
	jae second ;als x > 0
        jb false   ;als x < 0
second:
	cmp ax, 320
	ja false ;als x > 320
	mov [bx], ax  ;verandert x met de nieuwe positie
        jmp endg
false:
	neg dx  ;rico van x negatief maken
	mov [bx+10], dx ;nieuwe rico veranderen
	mov ax, 0
	mov [bx+8], ax   ;t resetten op 0
	mov ax, [bx]
	mov [bx+4], ax  ;verandert de start-x met de waarde van de huidige x
	mov ax, [bx+2]
	mov [bx+6], ax  ;verandert de start-y met de waarde van de huidige y
endg:
	push ax
	push bx
	push dx
check_ball_x	endp

check_ball_y proc near
first:
	pop dx
	pop bx
	pop ax
	cmp ax, 0
	jae second   ;als y >= 0
	jb false     ;als y < 0
second:
	cmp ax, 200
	ja false  ;als y > 200
	mov [bx+2], ax  ;verandert y met de nieuwe positie
	jmp endg
false:
	neg dx          ;rico van y negatief maken
	mov [bx+12], dx ;nieuwe rico veranderen
	mov ax, 0
	mov [bx+8], ax   ;t resetten op 0
	mov ax, [bx]
	mov [bx+4], ax ;verandert de start-x met de waarde van de huidige x
	mov ax, [bx+2]
	mov [bx+6], ax ;verandert de start-y met de waarde van de huidige y
endg:
	push ax
	push bx
	push dx
check_ball_y	endp

botsing proc near
	push bp
	mov bp, sp
	push ax
	push bx
	push cx
	push dx
	mov bx, [bp+6]
	mov ax, [bx+2]  ;ax bevat de y-co van cirkel2
	mov bx, [bp+4]
	mov cx, [bx+2]  ;cx bevat de y-co van cirkel1
	sub ax, cx      ;ax bevat y2-y1
	mul ax          ;ax bevat (y2-y1)²
	mov bx, [bp+6]
	mov cx, [bx]    ;cx bevat de x-co van cirkel2
	mov bx, [bp+4]
	mov dx, [bx]    ;dx bevat de x-co van cirkel1
	sub cx, dx      ;cx bevat x2-x1
	mov dx, cx
	mov cx, ax
	mov ax, dx
	mul ax          ;ax bevat (x2-x1)²
	add cx, ax      ;cx bevat ((y2-y1)²+(x2-x1)²)
	mov bx, [bp+4]
	mov ax, [bx+14] ;ax bevat de straal van cirkel1
	mov bx, [bp+6]
	mov dx, [bx+14] ;dx bevat de straal van cirkel2
	add ax, dx      ;ax bevat straal1 + straal2
	mul ax          ;ax bevat (straal1 + straal2)²
	cmp cx, ax      
	jbe kleiner     ; ((y2-y1)²+(x2-x1)²) <= (r1 + r2)²
	ja  groter
kleiner:
	mov bx, [bp+4]
	mov cx, [bx+10]
	neg cx          ;rico x van cirkel1 negatief maken
	mov [bx+10], cx
	mov cx, [bx+12]
	neg cx          ;rico y van cirkel1 negatief maken
	mov [bx+12], cx
	mov cx, 0
	mov [bx+8], cx  ;counter t van cirkel1 op 0 zetten
	mov cx, [bx]
	mov [bx+4], cx  ;start-x van cirkel1 veranderen met de huidige x
	mov cx, [bx+2]
	mov [bx+6], cx  ;start-y van cirkel1 veranderen met de huidige y
	mov bx, [bp+6]
	mov cx, [bx+10]
	neg cx          ;rico x van cirkel2 negatief maken
	mov [bx+10], cx
	mov cx, [bx+12]
	neg cx          ;rico y van cirkel2 negatief maken
	mov [bx+12], cx
	mov cx, 0
	mov [bx+8], cx  ;counter t van cirkel2 op 0 zetten
	mov cx, [bx]
	mov [bx+4], cx  ;start-x van cirkel2 veranderen met de huidige x
	mov cx, [bx+2]
	mov [bx+6], cx  ;start-y van cirkel2 veranderen met de huidige y
groter:
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
botsing	endp
end
