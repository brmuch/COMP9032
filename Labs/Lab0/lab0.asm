.include "m2560def.inc"
.def a =r16 ; define a to be register r16
.def b =r17 ; define b to be register r17
.def c =r10 ; define c to be register r10
.def d =r11 ; define d to be register r11
.def e =r12 ; define e to be register r12

main: ; main is a label
	ldi a, 10 ; load value 10 into a
	ldi b, -20
	mov c, a ; copy the value of a to c
	add c, b ; add c and b and store the result in c
	mov d, a
	sub d, b ; subtract b from d and store the result in d
	lsl c
	asr d
	mov e, c
	add e, d
halt:
	rjmp halt ; halt the processor execution
