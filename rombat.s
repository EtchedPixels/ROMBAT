;
;	Minimal RAMless monitor
;
;	0-F	add digits to the 24bit shifting value
;	X	jump to the low 16bits of the value
;	R	read the memory at the low 16bits of the value, inc value.16
;		by one
;	W	write the low 8bits of the 24bit value to the address in the
;		upper 16, move it right 8bits and increment
;	I	read the I/O at the low 16bits of value
;	O	write the low 8bits of the 24bit value to the I/O in the
;		upper 16, move it right 8bits
;	space	just echoed for convenience
;	newline	force a newline and prompt for convenience
;
;	The practical effect of this is
;
;	0800 R			reads 0800
;	R			reads 0801
;	0800 02 W		write 02 to 0800
;	02 W			write 02 to 0801
;	0800 X			execute from 0800
;	F8 I			read port xxF8
;	FFF8 O			write to port FFF8
;
;	A	Scratch
;	BC	Scratch
;	D	Character input as is
;	EHL	24bit working value
;	IX/IY	unused
;	Alt	unused
;	SP	effectively a threadcode program counter driven by ret	
;
ACIA_S	.equ	0xA0
ACIA_D	.equ	0xA1

init:
	; init serial here
	ld	a,0x96			; Initialize the ACIA settings
	out	(ACIA_S),a

	; If space is tight you can cut from here -----8<-----
	ld	hl,rombat
start:
	; and go
	ld	sp,start_sp
	xor	a
	ld	d,(hl)
	cp	d
	jr	z, newline_init
	inc	hl
	ret
rombat:
	.ascii	'ROMBAT 0.1a'
	.byte 0

start_sp:
	.word	outc
	.word	start		; effectively a loop calling outc
;
;	----------8<----------- to here
;
newline_init:
	ld	h,a		; clear the initial working addr
	ld	l,a		; for some kind of consistent start
newline:
	ld	sp,nl_sp
	ld	d,13
	ret
out10:	ld	d,10
	jr	outc
warm:	
	ld	d,'*'
	ld	sp,echo_sp
	ret
monret:
	ld	sp,mon_sp
	ret
waitk:
	in	a,(ACIA_S)
	rra
	jr	nc,waitk
	in	a,(ACIA_D)
	ld	d,a
	cp	10
	jr	z,newline
	cp	13
	jr	z,newline
	; If space is tight you can cut from here -----8<-----
	cp	127
	jr	nz, notdel
	srl	e
	rr	h
	rr	l
	srl	e
	rr	h
	rr	l
	srl	e
	rr	h
	rr	l
	srl	e
	rr	h
	rr	l
	ld	d,8
	ret
	;	----------8<----------- to here
notdel:
	cp	32
	ret	z		; echo space and wait for key
	cp	'X'
	jr	nz,notx
	jp	(hl)
notx:	cp	'I'
	jr	nz,noti
	ld	b,h
	ld	c,l
	in	c,(c)
	jr	hexout
noti:	cp	'R'
	jr	nz,notr
	ld	c,(hl)
	inc	hl
hexout:	ld	sp,horet
	ld	d,' '
	ret
notr:	cp	'O'
	jr	nz,noto
	ld	b,e
	ld	c,h
	out	(c),l
	ld	l,h
	ld	h,e
	jr	newline
noto:	cp	'W'
	jr	nz,not_w
	ld	a,l
	ld	l,h
	ld	h,e
	ld	(hl),a
	inc	hl
	jr	newline
not_w:
	sub	48			; '0'
	jr	c, waitk
	cp	10
	jr	c, digit
	cp	'A'-48
	jr	c, waitk
	cp	'F'-48+1
	jr	nc,waitk
	sub	7
digit:	rla
	rla
	rla
	rla
	rla
	adc	hl,hl
	rl	e
	rla
	adc	hl,hl
	rl	e
	rla
	adc	hl,hl
	rl	e
	rla
	adc	hl,hl
	rl	e
	ret			; and echo char in D
hexdo1:
	; Print hex char in C
	ld	a,c
	rra
	rra
	rra
	rra
hexdo2:
	or	0xF0
	daa
	add	a,0xA0
	adc	a,0x40
	ld	d,a
outc:	in	a,(ACIA_S)
	and	2
	jr	z,outc
	ld	a,d
	out	(ACIA_D),a
	ld	a,c		; for hexdo2
	ret

; Stack for hex printing
horet:	.word	outc		; echo char
	.word	hexdo1		; return from hexdo into hexdo1 (after outc)
	.word	hexdo2		; after first ch print second
	.word	monret		; and from hexdo2 into newline
; Main monitor stack
echo_sp:.word	outc		; first print char
mon_sp:	.word	waitk		; then back to the keyloop
	.word	outc		; echo char
	.word	monret		; then back to warm on cmd done
; Newline stack
nl_sp:  .word	outc		; first print char
	.word	out10		; then print second char
	.word	warm		; then warm start
