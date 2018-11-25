;
; Lab2_task2.asm
;
; Created: 2018/8/23 22:19:08
; Author : Ran Bai
; version number:1.0
; Function: calculate the result of two 16bits number division
; Replace with your application code
.include "m2560def.inc"
//.def     quotient = r6
.def     bit_positionL = r17               ; define low 8bits of bit_position
.def     bit_positionH = r18               ; define high 8bits of bit_position
.def     zeroL = r19                       ; define low 8bits of zero
.def     zeroH = r20                       ; define high 8bits of zero
.dseg 
quotient: .byte 2                          ; define quotient in data space
.cseg
divisor:  .dw 0x085a                       ; define divisor and divident in program memory
dividend: .dw 0x1ea6

main:
    ldi ZL, low(divisor<<1)                ; initial Z to divisor address
	ldi ZH, high(divisor<<1)
	lpm r2, Z+                             ; load divisor to r3:r2 by Z
	lpm r3, Z
	ldi ZL, low(dividend<<1)               ; initial Z ro dividend address    
	ldi ZH, high(dividend<<1)
	lpm r4, Z+                             ; load dividend to r5:r4 by Z
	lpm r5, Z

    rcall posdiv                           ; call function, and jump to function posdiv
	;return value
	ldi ZL, low(quotient)                  ; initial Z to quotient address
	ldi ZH, high(quotient)
	st Z+, r6                              ; store r7:r6 to quotient in program memory
	st Z, r7
end:
    rjmp end

posdiv:
;prologue
    push YL               ; push return address into stack
	push YH
	push r2               ; push conflict register into stack
	push r3
	push r4
	push r5
	push zeroH
	push zeroL
	in YL, SPL            ; Y <- SP
	in YH, SPH
	sbiw Y, 4             ; allocate 4 bytes in stack
	out SPL, YL           ; SP <- Y, update the stack pointer to correct address
	out SPL, YH

	;pass value to function
	std Y+1, r2          ; pass divisor (r3:r2)
	std Y+2, r3
	std Y+3, r4          ; pass dividend (r5:r4)
	std Y+4, r5
;end of prologue

;function body
    clr r6               ; r7:r6 quotient, and initial to 0
	clr r7
	clr bit_positionH
	ldi bit_positionL, 1
	clr zeroH
	clr zeroL

	ldd r2, Y+1          ; load divisor to register 
	ldd r3, Y+2
	ldd r4, Y+3          ; load dividend to register
	ldd r5, Y+4
loop1:
    cp r4, r2            ; while compare section
	cpc r5, r3           ; dividend > divisor
	breq loop2
	brlo loop2 
	mov r16, r3          ; !(divisor & 0x8000)
	andi r16, 0x80
	cpi r16, 0x00
	brne next

	lsl r2                ; divisor = divisor << 1
	rol r3
	lsl bit_positionL     ; bit_position = bit_position << 1
	rol bit_positionH
	rjmp loop1
loop2:
    cp bit_positionL, zeroL     ; compare bit_positon with 0
	cpc bit_positionH, zeroH
	breq endfuc
	brlo endfuc

	cp  r4, r2
	cpc r5, r3
	brlo next 
	sub r4, r2                 ; dividend = dividend - divisor
	sbc r5, r3
	add r6, bit_positionL      ; quotient = quotient + bit_position
	adc r7, bit_positionH
next:
    lsr r3                     ; divisor = divisor >> 1
	ror r2
	lsr bit_positionH          ; bit_position = bit_position >> 1
	ror bit_positionL
	rjmp loop2
endfuc:
;end of function body
    
;epilogue
    adiw Y, 4                   ; de-allocate 4bytes from stack
	out SPH, YH
	out SPL, YL
	pop zeroL
	pop zeroH
	pop r5                      ; pop r5-r2 from stack
	pop r4
	pop r3
	pop r2
	pop YH                      ; pop return address
	pop YL
	ret                         ; return
;end of epilogue