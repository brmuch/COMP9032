;
; Lab1_task2.asm
;
; Created: 2018/8/9 16:03:45
; Author : Ran Bai
; Function: 


; Replace with your application code

.def aH = r3            ; define a High 8 bits to r2
.def aL = r2            ; define a Low 8 bits to r3
.def n = r16            ; define n to r4
.def sumH = r25         ; define sum High 8 bits
.def sumL = r24         ; define sum Low 8 bits
.def tempH = r11        ; define temp High 8 bits
.def tempL = r10        ; define temp Low 8 bits
.equ num = 1            ; define the value of num to 1(un-redefinable)

.macro  calculate
    adiw sumL, num      ; words add with num
	mul sumL, aL        ; multiple the low 8bits of sum with the low 8bits of a
	mov tempH, r1       ; temporarily store the high 8bits of result 
	mov tempL, r0       ; temporarily store the low 8bits of result

	mul sumH, aL        ; multiple the high 8bits of sum with the low 8bits of a
	add tempH, r0       ; add the high 8bits of temp with r0
	mul sumL, aH        ; multiple the low 8bits of sum with the low 8bits of a
	add tempH, r0       ; add the high 8bits of temp with r0
	movw sumL, tempL    ; move word  sumH:sumL <- tempH:tempL

	ldi r30, 1          ; load 1 to r30
	sub n, r30          ; n - 1
.endmacro


	movw   sumL, aL     ; move word sumH:sumL <- aH:aL
main:
	cpi n, 1            ; compare n with 1
	breq end            ; if n==1, go to end

    calculate           ; calculating, go to macro running

	rjmp main           ; jump to main
end:
	rjmp end