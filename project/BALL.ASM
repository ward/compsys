;;;;;;;;;;;;
; BALL ADT ;
;;;;;;;;;;;;
.MODEL compact

; exports
public	ball_new
public	ball_draw

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
	; TODO: Is there a need to wait for that vblank stuff? See examples.
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

end
