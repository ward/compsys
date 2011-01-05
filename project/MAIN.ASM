.MODEL compact

; Macros

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

; Constants, these affect the settings of the compiled program.
AMT_BALLS_MIN = 1
AMT_BALLS_MAX = 5
RADIUS_MIN = 1
RADIUS_MAX = 30

; Don't change colour max and min
COLOUR_MIN = 0
COLOUR_MAX = 255

.STACK 1024

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
ary_balls	dw	AMT_BALLS_MAX dup (0)
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
; stoi
extern	stoi:proto
; ball
extern	ball_new:proto
extern	ball_draw:proto

; printint
extern	printint:proto

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
	; bx now holds the number of the ball we are handling
	; Firstly we print it out as info to the user
	mov	ax,offset msg_ball_n
	push	ax
	call	prints
	push	bx
	call	printint
	call	newline
	; Then we put it on the stack again, since we need it a bit further
	push	bx	; We will need it again
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
	; x
	mov	ax,160
	push	ax
	; y
	mov	ax,100
	push	ax
	; rico_x
	mov	ax,10
	push	ax
	; rico_y
	mov	ax,10
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
	
	; Note that the address of ball n is at: ary_balls[2n]
	mov	ax,ary_balls[0]
	push	ax
	call	ball_draw


; draw a dot in bottom left corner
	; Screen
	mov	dx,0A000h
	mov	es,dx
	
	xor	di,di
	mov	di,320
	mov	ax,199
	mul	di
	mov	di,ax

	  ;wait for vblank to write to video ram
  mov dx, 03dah ; VGA status port             
drawscreen_wait1: ;if in vblank, wait until vblank finishes
  in al, dx
  and al, 8
  jnz drawscreen_wait1                 ; busy wait
drawscreen_wait2:                      ;wait until begin of vblank
  in al, dx
  and al, 8
  jz drawscreen_wait2                  ; and again
	mov	al,50
	stosb ; stores al into es:di
	
	  ;wait for key pressed
  xor ah,ah
  int 16h
	
	restorevideomode	oldvidmode
.EXIT

end
