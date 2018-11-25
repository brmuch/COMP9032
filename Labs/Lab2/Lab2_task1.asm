;
; Lab2_task1.asm
;
; Created: 2018/8/14 14:57:07
; Author : Ran Bai
; Function : change type from string to int
; Replace with your application code
.include "m2560def.inc"

.def n = r16                   ; define n to r16
.def c = r17                   ; define c to r17
.equ zero = 0x30               ; define 0x30(ASCII) to zero
.equ ten = 0x40                ; define 0x40(ASCII) to ten
.def maxH = r19                ; define high 8bits of max to r19
.def maxL = r18                ; define low 8bits of max to r18
.def nH = r21                  ; define high 8bits of n to r21
.def nL = r20                  ; define low 8bits of n to r20
.def temp = r22                ; define temp to r22
.def multiple = r23            ; define multiple to r23
.def temp1 = r25               ; define temp1 to r25

.dseg
number: .byte 2                ; define number 2bytes in data memory(variable)
.cseg
s: .db "12345", 0              ; define s in program memory(constants)

main:
    rcall atoi                 ; call the function atoi
	ldi ZH, high(number)        ;update the value of number
	ldi ZL, low(number)
	st Z+, nL
	st Z, nH
end:
    rjmp end

atoi:
    ;prologue     
	push YL                    ; push the return address into stack
	push YH
	in YL, SPL                 ; initialize the stack frame pointer value
	in YH, SPH
	sbiw Y, 10                 ; reserve space for local variables and parameters
	out SPH,YH                 ; update the stack pointer to point to the new stack top
	out SPL,YL
    ;end of prologue

	;function body
	ldi maxH, 128              ; initial local variables and parameters
	clr maxL
	ldi n, 0
	ldi temp1, 0
	ldi multiple, 0x0A
	ldi ZH, high(s<<1)
	ldi ZL, low(s<<1)
    clr nL
	clr nH
loop:		
    lpm c, Z+                   ; get the value stored in s(pass reference)
    cpi c, zero                 ; compare c with 0  (ASCII)0x30
	brlo endloop                ; if c < 0x30 goto endloop
	cpi c, ten                  ; compare c with 10 (ASCII)0x40
	brsh endloop                ; if c >= 0x40 goto endloop
	cp nL, maxL                 ; compare n with max(65536)
	cpc nH, maxH                
	brsh endloop                ; if n >= max goto endloop

	ldi temp, zero              ; c = c - '0'
	sub c, temp
    
	mul nL, multiple            ; n = n * 10
	mov r24, nH
	mov nH, r1
	mov nL, r0
	mul multiple, r24
	add nH, r0
	add nL, c
	adc nH, temp1

    rjmp loop                   ; jump to loop
endloop:
   
	;end of function

	;epilogue 
	adiw Y, 10                  ; De-allocate the reserved space

	out SPH, YH                 ; update the stack pointer
	out SPL, YL

	pop YH                      ; pop 
	pop YL
	ret                         ; return to main()
	;end of epilogue
