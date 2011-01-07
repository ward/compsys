.MODEL compact

; Macros
; See examples 'Computersystemen'
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

clearvideobuffer macro
	;store context
	push ax
	push cx
	push dx
	push es
	push di
	;set target registers for stosb
	mov ax,seg videobuffer
	mov es,ax
	mov di,offset videobuffer
	;set fill color
	mov al,0
	mov cx,64000	;size of video ram
	rep stosb	;blit
	;restore context
	pop di
	pop es
	pop dx
	pop cx
	pop ax
endm

; Constants, these affect the settings of the compiled program.
; You are advised not to change them, stability cannot be assured.
AMT_BALLS_MIN = 1
AMT_BALLS_MAX = 5
RADIUS_MIN = 1
RADIUS_MAX = 20

; Don't change colour max and min
COLOUR_MIN = 0
COLOUR_MAX = 255

.STACK 1024

.FARDATA
videobuffer	db	64000 dup (0)

.DATA
; Messages for user interaction
msg_amt_balls	db	"Please enter the amount of balls to show:","$"
msg_ball_n	db	"-> Ball #","$"
msg_radius	db	"Please enter the ball's radius:","$"
msg_colour	db	"Please enter a colour number (0-255):","$"

; Buffer (for character input), size 100
input_buffer	db	100 dup (0)

; Needed to save
amt_balls	dw	(0)
; Will hold the addresses to the memory blocks
; Add +1 to have 0 signify the end of the array.
ary_balls	dw	(AMT_BALLS_MAX+1) dup (0)
ary_balls_data	db	AMT_BALLS_MAX dup (18 dup (0))

; Something to store the old video mode when switching to drawing
oldvidmode	db	?


.CODE
;===============
;=== Imports ===
;===============

; print
extern	print:proto
extern	prints:proto
extern	newline:proto
extern	getline:proto
extern	printint:proto
; stoi
extern	stoi:proto
; ball
extern	ball_new:proto
extern	ball_draw:proto
extern	ball_move:proto
extern	ball_bounce:proto


.STARTUP
	; Perhaps add something to clear the screen?

	; Ask for the amount of balls
get_amt_balls:
	lea	dx,msg_amt_balls
	push	dx
	call	prints
	call	newline
	; Get input
	mov	ax,offset input_buffer
	push	ax
	call	getline
	call	newline
	; Convert to int
	sub	sp,2
	mov	ax,offset input_buffer
	add	ax,2 ; First 2 bytes aren't part of the string!!
	push	ax
	call	stoi
	pop	ax
	; In the valid range?
	cmp	ax,AMT_BALLS_MIN
	js	get_amt_balls
	cmp	ax,AMT_BALLS_MAX
	jg	get_amt_balls
	mov	amt_balls,ax

	; Now we will ask for input on every ball.
	mov	cx,amt_balls
create_ball:
	; Idea: allocate memory depending on amount entered?
	; Issue: You get the start of a segment back, can this be used like
	;	our ADT is already doing?

	; For now, we have the maximum allocated.
	; How to go at setting up:
	;	find the offset in ary_balls_data
	;	add offset to beginaddress of ary_balls_data
	;	store at correct spot in ary_balls
	mov	bx,amt_balls
	sub	bx,cx
	; bx now holds the number of the ball we are handling (0 to n-1)
	; Firstly we print it out as info to the user
	mov	ax,offset msg_ball_n
	push	ax
	call	prints
	mov	ax,bx
	inc	ax
	push	ax
	call	printint
	call	newline
	; Then we put it on the stack again, since we need it a bit further
	push	bx
	mov	ax,18
	mul	bl
	add	ax,offset ary_balls_data
	pop	bx
	add	bx,bx	; offset times two since every block is 2 bytes!
	add	bx,offset ary_balls
	mov	[bx],ax

	; Now we have the address of that one, start asking the user for
	; the beginning defaults.
	; Push every item onto the stack in the correct order,
	; then call ball_new at the end of the iteration.

	; address
	push	ax
	; x NEEDS TO BE RANDOM BUT NOT INTERFERING WITH OTHERS? same for rest
	mov	ax,2*RADIUS_MAX
	mul	cx
	push	ax
	; y
	mov	ax,100
	push	ax
	; rico_x
	mov	ax,cx
	push	ax
	; rico_y
	mov	ax,cx
	push	ax

	; Radius?
get_radius:
	lea	ax,msg_radius
	push	ax
	call	prints
	call	newline
	; Get input
	mov	ax,offset input_buffer
	push	ax
	call	getline
	call	newline
	; to int
	sub	sp,2	; return value
	mov	ax,offset input_buffer
	add	ax,2	; First 2 bytes aren't part of string
	push	ax
	call	stoi
	pop	ax
	; Check if it fits in the valid range
	cmp	ax,RADIUS_MIN
	js	get_radius
	cmp	ax,RADIUS_MAX
	jg	get_radius
	push	ax

	; Colour? (0 to 255)
get_colour:
	lea	ax,msg_colour
	push	ax
	call	prints
	call	newline
	; Get input
	mov	ax,offset input_buffer
	push	ax
	call	getline
	call	newline
	; Convert to int
	sub	sp,2
	mov	ax,offset input_buffer
	add	ax,2 ; First 2 bytes aren't part of the string!!
	push	ax
	call	stoi
	pop	ax
	; In the valid range?
	cmp	ax,COLOUR_MIN
	js	get_colour
	cmp	ax,COLOUR_MAX
	jg	get_colour
	push	ax

	; And finally make the ball
	call	ball_new

	; Looping till cx = 0
	dec	cx
	jnz	create_ball

	; Try some drawing
	setvideomode	13h,oldvidmode


loop_draw:
	clearvideobuffer
	; Note that the address of ball n is at: ary_balls[2n] for n=0..amt-1
	mov	bx,amt_balls
	add	bx,amt_balls
	sub	bx,2	; Because indices start counting at 0
loop_draw_ball:
	; Parameters for ball_draw: bufferseg bufferadd ball
	mov	ax,seg videobuffer
	push	ax
	mov	ax,offset videobuffer
	push	ax
	; Now get current ball
	mov	ax,ary_balls[bx]
	push	ax
	call	ball_draw
	; Current ball again
	push	ax
	call	ball_move
	
	sub	bx,2
	cmp	bx,0
	jns	loop_draw_ball
	
	; Check collisions
	mov	ax,offset ary_balls
	push	ax
	call	ball_bounce
	
	; Throw buffer to the screen
	call	updatescreen

	; Get keystroke
	mov	ah,01h
	int	16h
	jz	loop_draw
	;cmp	al,'q'
	;jnz	loop_draw

	restorevideomode	oldvidmode
.EXIT

; Throws the videobuffer to the screen
updatescreen	proc	near
	push	ax
	push	cx
	push	dx
	push	ds
	push	es
	push	di
	push	si

	;change registers for rep movsb to video ram
	mov	dx,seg videobuffer
	mov	ds,dx
	mov	si,offset videobuffer
	mov	dx,0A000h
	mov	es,dx
	xor	di,di
	;wait for vblank to write to video ram
	mov	dx, 03dah	; VGA status port
updatescreen_wait1:	;if in vblank, wait until vblank finishes
	in	al,dx
	and	al,8
	jnz	updatescreen_wait1	; busy wait
updatescreen_wait2:	;wait until begin of vblank
	in	al,dx
	and	al,8
	jz	updatescreen_wait2	; and again
	mov	cx,64000
	rep	movsb ;blit

	pop	si
	pop	di
	pop	es
	pop	ds
	pop	dx
	pop	cx
	pop	ax
	ret
updatescreen	endp

end
