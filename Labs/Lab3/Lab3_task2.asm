;
; lab3_task2.asm
;
; Created: 2018/9/4 15:45:16
; Author : Ran Bai
; Function :Based  Task 1, using an external interrupt to start and stop LEDs¡¯ display
; version number: 1.0
; Replace with your application code
.include "m2560def.inc"
.equ Pattern1 = 0x49      ; define pattern1 0b01001001
.equ Pattern2 = 0x24      ; define pattern2 0b00100100
.equ Pattern3 = 0x92      ; define pattern3 0b10010010
.def input = r21          ; define r21 as input
.def temp = r22           ; define r22 as temp
.def iH = r26             ; define r26:r25:r24 to 24 bits number iH:iM:iL
.def iM = r25             
.def iL = r24
.def countH = r18         ; define r18:r17:r16 to 24 bits number countH:countM:countL
.def countM = r17
.def countL = r16

.macro oneSecondDelay      ; macro for creating a second delay
     ldi r19, 0            ; 1 clock cycle
	 ldi r20, 1            ; 1 clock cycle
     ldi countL, 0xD0      ; 1 clock cycle
	 ldi countM, 0x31      ; 1 clock cycle
	 ldi countH, 0x16      ; 1 clock cycle
	 clr iH                ; 1 clock cycle
	 clr iM                ; 1 clock cycle
	 clr iL                ; 8 instructions, every instructions costs 1 clock cycle
loop:
     cp iL, countL         ; 1 clock cycle
	 cpc iM, countM        ; 1 clock cycle
	 cpc iH, countH        ; 1 clock cycle
	 brsh done             ; if branch, cost 2 clock cycle, else, cost 1
	 add iL, r20           ; 1 clock cycle
	 adc iM, r19           ; 1 clock cycle
	 adc iH, r19           ; 1 clock cycle
	 nop                   ; 1 clock cycle
	 jmp loop              ; jmp cost 3 clock cycle, and the loop totally cost 5 + 11 * 1454544 clock cycles
done:
     nop                   ; in order to waster 3 clock cycle
	 nop                   ; 1 clock cycle
	 nop                   ; 1 clock cycle
.endmacro

.macro displayed           ; display corresponding mode into lab board
      ldi r16, @0          ; load data to r16
	  out PORTC, r16       ; output the data from r16 to portc
.endmacro
                           
						   ; set up interrupt vectors
      rjmp RESET           ; jump to interrupt Reset
.org  INT0addr             ; defined in m2560def.inc
      jmp EXT_INT0         ; jump to interrupt EXT_INT0

RESET:
      ser input            ; set all bit in input to 1
	  out DDRC, input      ; set port C into ouput mode
	  cbi DDRD, 0          ; set pin 0 of port D into input mode
	  sbi PORTD, 0         ; activate the pull up
	  sbi PIND, 0          ; set pin0 in port D to 1
	  cbi DDRD, 1          ; set port 1 of port D into input mode
	  sbi PORTD, 1         ; activate the pull up
	  sbi PIND, 1          ; set pin1 in port D to 1

	  ldi temp, (1 << ISC00)  ; set INT0 as any edge triggered interrupt
	  sts EICRA, temp         ; store temp into EICRA
      in temp, EIMSK          ; input EIMSK into temp 
      ori temp, (1<<INT0)     ; logic or immediately, set INTO to 1
      out EIMSK, temp         ; output temp to EIMSK, enable INT0
	  sei                     ; enable global interrupt
	  jmp main                ; jump to main

EXT_INT0:
waiting:
      sbic PIND, 1            ; if pin1 of portD is clear, skip
      rjmp waiting            ; jump to waiting
	  reti                    ; end interrupt and return
main:
      displayed Pattern1      ; display pattern 1
	  oneSecondDelay          ; 1 second delay
	  displayed Pattern2      ; display pattern 2
	  oneSecondDelay          ; 1 second delay
	  displayed Pattern3      ; display pattern 3
	  oneSecondDelay          ; 1 second delay
	  rjmp main               ; rjmp to main
end:
      rjmp end                ; end
