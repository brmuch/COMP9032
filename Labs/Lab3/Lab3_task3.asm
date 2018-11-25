.include "m2560def.inc"
	
.def row    = r16		; current row number
.def col    = r17		; current column number
.def rmask  = r18		; mask for current row
.def cmask	= r19		; mask for current column
.def temp1	= r20		; define r20 as temp1 
.def temp2  = r21       ; define r21 as temp2
.def a_or_b = r22       ; a_or_b for store current number in a or b
.def number1 = r23      ; number1 for storing low 8bits of a 2bytes number
.def number2 = r24      ; number2 for storing high 8bits of a 2 bytes number
.def number3 = r26
.def temp = r25         ; define r25 as temp

.def a = r3             ; the first multiple number a
.def b = r4             ; the second multiple number b
.def count1 = r5
.def count2 = r6
.def count3 = r7

.equ PORTFDIR =0xF0			; use PortD for input/output from keypad: PF7-4, output, PF3-0, input
.equ INITCOLMASK = 0xEF		; scan from the leftmost column, the value to mask output
.equ INITROWMASK = 0x01		; scan from the bottom row
.equ ROWMASK  =0x0F			; low four bits are output from the keypad. This value mask the high 4 bits.

;rjmp	RESET
.macro aSecondDelay         ; a few ms delay
    ldi number1, 0xff       ; load 0xD0 into number1
	ldi number2, 0xff       ; load 0x31 into number2
	ldi number3, 0x01       ; load 0x16 into number3
	clr count1              ; clear count1
	clr count2              ; clear count2
	clr count3              ; clear count3
start:
    cp number1, count1           ; compare number1 with count1
	cpc number2, count2          ; compare number2 with count2
	cpc number3, count3          ; compare number3 with count3
	breq finish                  ; if number3:number2:number1 = count3:count2:count1, end Delay
	ldi temp, 1                  ; load 1 into temp
	add count1, temp             ; number3:number2:number1 = number3:number2:number1 + 1
	ldi temp, 0                  ; load 0 into temp
	adc count2, temp             ; count2 = count2 + 0 + c
	adc count3, temp             ; count3 = count3 + 0 + c
	rjmp start                   ; rjump to start, continue add operation
finish:
.endmacro

.macro load                        ; load number to correct place, a or b
    ldi temp, 0x0A                 ; load 10 to temp
	mul temp, @0                   ; origin number multiple 10, that is a * 10 or b * 10
	add r0, @1                     ; add the new press number
	mov @0, r0                     ; save result into correct place, a or b
	out PORTC, @0                  ; output current number in a or b
	jmp load_judge                 ; jmp to load_judge, judge the new number whether overflow
	//aSecondDelay
.endmacro

.macro overflow                    ; flash 3 times
    ldi temp, 0x00                 ; first time flash
	out PORTC, temp                ; output 0xFF
	aSecondDelay                   ; one second delay

    ldi temp, 0xFF                 ; first time flash
	out PORTC, temp                ; output 0xFF
	aSecondDelay                   ; one second delay
	ldi temp, 0x00                 ; load 0x00 to temp
	out PORTC, temp                ; output 0x00
	aSecondDelay                   ; one second delay

	ldi temp, 0xFF                 ; second time flash
	out PORTC, temp                ; output 0xFF
	aSecondDelay                   ; one second delay 
	ldi temp, 0x00                 ; load 0x00 to temp
	out PORTC, temp                ; output 0x00
	aSecondDelay                   ; one second delay

	ldi temp, 0xFF                 ; third time flash
	out PORTC, temp                ; output 0xFF
	aSecondDelay                   ; one second delay
	ldi temp, 0x00                 ; load 0x00 to temp
	out PORTC, temp                ; output 0x00
	aSecondDelay                   ; one second delay
	jmp convert_end                ; jmp to convert_end
.endmacro

RESET:
    clr a                       ; clear a
	clr b                       ; clear b
	clr a_or_b                  ; clear a_or_b
	ldi temp1, PORTFDIR			; columns are outputs, rows are inputs
	out	DDRF, temp1             ; set PF7-4, output, PF3-0, input 
	ser temp1					; set temp1 to 0xFF
	out DDRC, temp1				; PORTC is outputs 
	out PORTC, temp1            ; out 0xFF to PORTC, LED2-9 light means ready

main:
    //aSecondDelay
	//aSecondDelay
	aSecondDelay                ; 3 second Delay
	ldi cmask, INITCOLMASK		; initial column mask
	clr	col						; initial column
colloop:
	cpi col, 4                  ; compare col with 4
	breq main                   ; branch to main
	out	PORTF, cmask			; set column to mask value (one column off)

	ldi temp1, 0xFF             ; load 0xff to temp1
delay:
	dec temp1                   ; decrease temp1, temp1 = temp1 - 1
	brne delay                  ; if temp1 is not 0x00, branch to delay, else continue


	in	temp1, PINF				; read PORTD
	andi temp1, ROWMASK         ; and immediately
	cpi temp1, 0xF				; check if any rows are on
	breq nextcol
								; if yes, find which row is on
	ldi rmask, INITROWMASK		; initialise row check
	clr	row						; initial row
rowloop:
	cpi row, 4                  ; compare row with 4
	breq nextcol                ; if row = 4, branch to nextcol
	mov temp2, temp1            ; mov temp1 to temp2
	and temp2, rmask			; check masked bit
	breq convert 				; if bit is clear, convert the bitcode
	inc row						; else move to the next row
	lsl rmask					; shift the mask to the next bit
	jmp rowloop

nextcol:
	lsl cmask					; else get new mask by shifting and 
	inc col						; increment column value
	jmp colloop					; and check the next column

convert:
	cpi col, 3					; if column is 3 we have a letter
	breq letters				; branch to letters
	cpi row, 3					; if row is 3 we have a symbol or 0
	breq symbols                ; branch to symbols

	mov temp1, row				; otherwise we have a number in 1-9
	lsl temp1                   ; logical shift left temp1, temp1 = temp1 * 2
	add temp1, row				; temp1 = row * 3
	add temp1, col				; add the column address to get the value
	//out PORTC, temp1
	inc temp1                   ; increase temp1, temp1 = temp1 + 1

	cpi a_or_b, 0               ; compare a_or_b with 0, judge the input number should add into a or b
	brne loadb                  ; if a_or_b = 0, store to a, else store to b
	load a, temp1               ; load number to a 
loadb:
	load b, temp1               ; load number to b

letters:        				
	jmp main                    ; if press letter jmp to letter immediately

symbols:
	cpi col, 0					; check if we have a star
	breq star                   ; branch to star
	cpi col, 1					; or if we have zero
	breq zero					; branch to zero
	                            ; if not star or zero, we have hash'#'
	mul a, b                    ; mul a with b
	jmp result_judge            ; jmp to result_judge
	out PORTC, r0               ; output the result of multiple
	jmp convert_end             ; jmp to end

star:
	com a_or_b                  ; a_or_b's complement
	//aSecondDelay
	jmp main                    ; jumpt to main

zero:
	ldi temp1, 0				; set to zero
	cpi a_or_b, 0               ; compare a_or_b with 0
	brne loadb                  ; if a_or_b not equal to 0
	load a, temp1               ; load temp1 to a

load_judge:                     ; load judge, whether overflow
    ldi temp, 0                 ; load 0 to temp
	cp temp, r1                 ; compare temp with r1
	brne load_flash             ; if r1 is not 0, means overflow
	jmp main                    ; jump to main
load_flash:                     
    overflow                    ; use macro overflow

result_judge:
    ldi temp, 0                 ; load 0 to temp
	cp temp, r1                 ; compare temp with r1
	brne result_flash           ; if temp not equal to r1, branch to result_flash
	out PORTC, r0               ; it is not overflow, output the correct result in r0
	jmp convert_end             ; jump to convert_end
result_flash:
    overflow                    ; use macro overflow

convert_end:
	jmp convert_end					; end program