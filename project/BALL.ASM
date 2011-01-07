;;;;;;;;;;;;
; BALL ADT ;
;;;;;;;;;;;;
.MODEL compact

; exports
public	ball_new
public	ball_draw
public  ball_move
public	ball_bounce

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


; Interaction!
; eg: ball_get_x, ball_get_y, ball_get_r, ...
; Make them behave like this:
; Parameter (ball's address) in ax
; Call function
; Result in ax
; These are more for public users of the Ball
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
	mov	bx,[bp+4]	; Ball
	mov	ax,[bx+14]	; Radius
	; Radius is positive and we'll keep it below 128 so al is the same.
	mul	al
	push	ax

	; Get 2*radius (Note that this may need 2*r+1 instead), we'll see.
	; This is the y to loop through
	; We are assuming constraints on the radius size such that 2*r < 127
	mov	ax,[bx+14]
	mov	cx,ax
	add	cx,cx
iterdraw_y:
	push	cx
	; Get the beginvalue again, this represents our x to loop through
	mov	bx,[bp+4]	; Ball
	mov	ax,[bx+14]	; r
	mov	cx,ax
	add	cx,cx
iterdraw_x:
	; Do (r - x)^2
	mov	bx,[bp+4]
	mov	ax,[bx+14]
	sub	al,cl
	imul	al	; Result in ax !
	mov	dx,ax
	; Now (r - y)^2
	mov	ax,[bx+14]	; Still r
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
	mov	bx,[bp+4]
	mov	ax,[bx+2]	; y_m
	add	dx,ax	; y + y_m
	mov	ax,[bx+14]
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
	mov	bx,[bp+4]	; Ball
	mov	ax,[bx]	; x_m
	add	dx,ax	; x + x_m
	mov	ax,[bx+14]
	sub	dx,ax	; x + x_m - r in dx
	; If negative, skip
	js	draw_continue
	; or >= 320
	cmp	dx,320
	jns	draw_continue
	add	di,dx

	; Now to colour the dot. Notice that the colour is only 8 bit (unsigned)
	mov	bx,[bp+4]	; Ball
	mov	ax,[bx+16]	; Colour
	; This is the segment of the buffer parameter
	mov	dx,[bp+8]
	mov	es,dx
	; And the offset
	mov	dx,[bp+6]
	add	di,dx
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
	ret	6
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
	; Now to check and handle collisions with other balls
	; The address in bx is the ball we are at, not the index!
	; Keep the address of the ball in dx, we'll need it in a bit
	mov	dx,bx
	; Get the index from tos (and put back because we still need it)
	pop	bx
	push	bx
	; Now loop till we reach 0000
bounce_ball_loop:
	add	bx,2
	mov	ax,[bx]
	cmp	ax,0
	jz	bounce_ball_end
	; ax and dx are the two address of the balls
	; We'll push them on the stack and call function to check
	; if they're too close
	push	dx
	push	ax
	call	ball_bounce_checkballs
	jnc	nobounce
	; Now handle the bouncing of the two balls
	push	dx
	push	ax
	call	balls_bounced
	
nobounce:
	; Back to beginning of the loop
	jmp	bounce_ball_loop

bounce_ball_end:
	
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

; Gets two arguments via the stack
; Address of first and second ball
; If two balls collide, carry flag is set
; Otherwise, carryflag is clear
ball_bounce_checkballs	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	cx
	push	dx

	; Get data for the first ball
	mov	bx,[bp+6]	; ball 1
	mov	ax,[bx]	; x_1
	mov	dx,[bx+2]	; y_1
	mov	cx,[bx+14]	; r_1
	; And the second
	mov	bx,[bp+4]	; ball 2
	; We'll immediately take the absolute value
	sub	ax,[bx]	; x_1 - x_2
	jns	xdiff_pos
	neg	ax
xdiff_pos:
	sub	dx,[bx+2]	; y_1 - y_2
	jns	ydiff_pos
	neg	dx
ydiff_pos:
	add	cx,[bx+14]	; r_1 + r_2
	; To avoid multiplying too big numbers, we check
	; | x_1 - x_2 | > r_1 + r_2
	cmp	ax,cx
	jg	balls_dont_collide
	; | y_1 - y_2 | > r_1 + r_2
	cmp	dx,cx
	jg	balls_dont_collide

	; Now both sides are in a "normal" range
	mul	ax	; (|x_1 - x_2|)^2
	; swap ax and dx to square the y's
	push	ax
	mov	ax,dx
	pop	dx
	mul	ax	; (|y_1 - y_2|)^2
	add	dx,ax	; (|x_1 - x_2|)^2 + (|y_1 - y_2|)^2
	; Now finally the r's
	mov	ax,cx
	mul	ax
	; (r_1 + r_2)^2 ??? (|x_1 - x_2|)^2 + (|y_1 - y_2|)^2
	cmp	ax,dx
	; <
	js	balls_dont_collide
	; >=
	; or in other words, they collide. Set carry flag
	stc
	jmp	ball_bounce_checkballs_end

balls_dont_collide:
	; Clear carry flag
	clc

ball_bounce_checkballs_end:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret	4	; 2 parameters
ball_bounce_checkballs	endp

; Gives new route to the two balls
; Gets two parameters from the stack: addresses of two balls
balls_bounced	proc	near
	push	bp
	mov	bp,sp
	push	ax
	push	bx
	push	cx
	push	dx

	; Temporarily just send back in opposite direction
	mov	bx, [bp+4]
	; rico_x_1
	mov	cx, [bx+10]
	neg	cx
	mov	[bx+10], cx
	; rico_y_1
	mov	cx, [bx+12]
	neg	cx
	mov	[bx+12], cx
	call	ball_reset
	mov	bx, [bp+6]
	; rico_x_2
	mov	cx, [bx+10]
	neg	cx
	mov	[bx+10], cx
	; rico_y_2
	mov	cx, [bx+12]
	neg	cx
	mov	[bx+12], cx
	call	ball_reset

	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	bp
	ret	4	; 2 parameters
balls_bounced	endp
end
