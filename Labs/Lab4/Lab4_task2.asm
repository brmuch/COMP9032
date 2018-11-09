;
; lab4_task2.asm
;
; Created: 2018/10/2 15:18:47
; Author : Ran Bai
; Version number : 1.0
; Function : control the motor operations. When a button is pressed, the motor spins at its full speed. 
;            When the button is pressed again, the motor stops. 
; conncet: motor mot - pin 7 of port c
;          Ope - any +5v
;          PB0 - INT0s
;          must deal with problem of switch debourcing
; Replace with your application code
.include "m2560def.inc"
.def temp = r16       ; define temp to r16
.def flag = r17       ; define flag to r17
.def control = r18    ; define control to r18

        rjmp RESET
.org INT0addr
        jmp EXT_INT0
		
RESET:
     ldi control, 1    ; set control to 1
     clr flag          ; clear flag
     sbi DDRC, 7       ; set pin 7 of PORT C to 1, as output mode
	 cbi DDRD, 0       ; clear pin 0 of port D, as input mode
	 sbi PORTD, 0      ; activate the pull up

	 ldi temp, (2<<ISC00)         ; set INT0 as falling edge triggered interrupt
	 sts EICRA, temp                ; store temp into EICRA
	 in temp, EIMSK                 ; input EIMSK into temp
	 ori temp, (1<<INT0)            ; logic or immediately, set INT0 to 1
	 out EIMSK, temp                ; output temp to EIMSK, enable INT0

	 sei                            ; enable global interrupt
	 jmp main                       ; jump to main
	 
EXT_INT0:

	 com flag                       ; flag complement, 0x00->0xFF
	 cpi flag, 0xFF                 ; compare flag with 0xFF
	 breq motor_run                 ; if flag==0xFF, goto motor_run
motor_stop:
     cbi PORTC, 7                   ; clear pin 7 of Port C.
	 rjmp end_interrupt             ; rjmp to end_interrupt
motor_run:
     sbi PORTC, 7                   ; set pin 7 of Port C to 1
end_interrupt:
     rcall sleep_30ms
	 rcall sleep_30ms
	 rcall sleep_30ms
	 rcall sleep_30ms
	 rcall sleep_30ms
	 reti                           ; end interrupt and return

main:

      rjmp main                     ; loop 





.equ F_CPU = 16000000
.equ DELAY_1MS = F_CPU / 4 / 1000 - 4
; 4 cycles per iteration - setup/call-return overhead

sleep_1ms:                                   ; sleep 1ms
	push r24                                 ; push r24 to stack
	push r25                                 ; push r25 to stack
	ldi r25, high(DELAY_1MS)                 ; load high 8 bits of DELAY_1MS to r25
	ldi r24, low(DELAY_1MS)                  ; load low 8 bits of DELAY_1MS to r25
delayloop_1ms:
	sbiw r25:r24, 1                          ; r25:r24 = r25:r24 - 1
	brne delayloop_1ms                       ; branch to delayloop_1ms
	pop r25                                  ; pop r25 from stack
	pop r24                                  ; pop r24 from stack
	ret

sleep_5ms:                                    ; sleep 5ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	rcall sleep_1ms                           ; 1ms
	ret

sleep_30ms:
    rcall sleep_5ms                           ; 5ms
	rcall sleep_5ms                           ; 5ms
	rcall sleep_5ms                           ; 5ms
	rcall sleep_5ms                           ; 5ms
	rcall sleep_5ms                           ; 5ms
	rcall sleep_5ms                           ; 5ms
	ret
