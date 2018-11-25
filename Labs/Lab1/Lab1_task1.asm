;
; lab1_mini.asm
;
; Created: 2018/8/2 16:24:04
; Author : lenovo
;


; Replace with your application code
.def a=r16
.def b=r17
.def c=r18
main:
    cp a,b
	breq end
	brge choice
	mov c,a	
	mov a,b
	mov b,c
choice:
    sub a,b
	rjmp main
end:

