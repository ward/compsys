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

.STACK 1024

.DATA
message	db	"Please enter a number:","$"
; Buffer, size 100
buffer	db	100 dup (0)

oldvidmode	db	?

; for testing
ball1	db	18 dup (0)

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

.STARTUP
	;lea	dx,message
	;push	dx
	;call	prints
	;call	newline
	
	;mov	ax,offset buffer
	;push	ax
	;call	getline
	;call	newline
	
	; return value
	;sub	sp,2
	;mov	bx,offset buffer
	;add	bx,2
	;push	bx
	;call	stoi
	;pop	dx
	
	
	; Create a ball
	lea	ax,message
	push	ax
	mov	ax,160	; x
	push	ax
	mov	ax,100	; y
	push	ax
	mov	ax,10	; rico_x
	push	ax
	mov	ax,1	; rico_y
	push	ax
	mov	ax,33	;radius
	push	ax
	mov	ax,200	;colour
	push	ax
	call	ball_new
	; Try some drawing
	setvideomode	13h,oldvidmode
	
	lea	ax,message
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
