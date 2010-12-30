;;;;;;;;;;;;
; BALL ADT ;
;;;;;;;;;;;;
.MODEL compact

; exports

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
	mov	bx,[bp+14]
	
	; Moving things into the reserved space
	mov	[bx],[bp+12] ; curr_x
	mov	[bx+2],[bp+10] ; curr_y
	mov	[bx+4],[bp+12] ; start_x
	mov	[bx+6],[bp+10] ; start_y
	mov	ax,0
	mov	[bx+8],ax ; t, internal counter
	mov	[bx+10],[bp+8] ; rico_x
	mov	[bx+12],[bp+6] ; rico_y
	mov	[bx+14],[bp+4] ; radius
	mov	[bx+16],[bp+2] ; colour
	
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
