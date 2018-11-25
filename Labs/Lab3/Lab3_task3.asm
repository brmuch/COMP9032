;
; lab3_task1.asm
;
; Created: 2018/9/3 22:37:18
; Author : Ran Bai
; Function £ºImplement a LED control system to repeatedly display a sequence of three patterns.
;            The display will be halted when the user presses a button. 
; Version number: 1.0
; Replace with your application code
.include "m2560def.inc"
.def iH = r26
.def iM = r25
.def iL = r24
.def countH = r18
.def countM = r17
.def countL = r16
.macro oneSecondDelay      ; macro for creating a second delay
     ldi r19, 0
	 ldi r20, 1
     ldi countL, 0xD0
	 ldi countM, 0x31
	 ldi countH, 0x16
	 clr iH
	 clr iM
	 clr iL                ; 8 instructions, every instructions above costs 1 clock cycle
loop:
     cp iL, countL         //1 clock cycle
	 cpc iM, countM        //1 clock cycle
	 cpc iH, countH        //1 clock cycle
	 brsh done             // if branch, cost 2, if not , cost 1
	 add iL, r20           // 1 clock cycle
	 adc iM, r19           // 1 clock cycle
	 adc iH, r19           // 1 clock cycle
	 nop                   // 1 clock cycle
	 jmp loop              ; jmp cost 3 clock cycle, and the loop totally cost 5 + 11 * 1454544 clock cycles
done:
     nop                   ; use 3 nop in order to waster 3 clock cycle
	 nop                   // 1 clock cycle
	 nop                   // 1 clock cycle
.endmacro

.macro displayed           ; display corresponding mode into lab board and judge if end or not
waiting1:
	  sbis PIND, 0         ; if PIND pin0 = 1, skip
	  rjmp waiting1

      ldi r16, @0          ; load data into r16
	  out PORTC, r16       ; output the data to port c

waiting:
	  sbis PIND, 0         ; if PIND pin0 = 1, skip 
	  rjmp waiting
.endmacro

      ser r16
	  out DDRC, r16        ; set port C into ouput mode
	  cbi DDRD, 0          ; set pin 0 of port D into input mode
	  sbi PORTD, 0         ; activate the pull up
display:
      displayed 0x49       ; display 0b01001001 in lab bar
      oneSecondDelay       ; delay 1s
	  displayed 0x24       ; display 0b00100100 in lab bar
	  oneSecondDelay       ; delay 1s
	  displayed 0x92       ; display 0b10010010 in lab bar
	  oneSecondDelay       ; delay 1s
	  rjmp display         ; rjmp to display
end:
      //displayed 0x00       ; end   
      rjmp end