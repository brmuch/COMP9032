;
; lab4_task1.asm
;
; Created: 2018/9/27 17:02:12
; Author : Ran Bai
; version number: 1.0
; Function:  displays characters inputted from the keypad on the LCD. When the first line is full, the display 
;            goes to the second line. When the two lines are all full, the display is cleared and ready to display
;    		 a new set of characters.
; 
; Board settings: 1. Connect LCD data pins D0-D7 to PORTF0-7.
;                 2. Connect the four LCD control pins BE-RS to PORTA4-7.
;                 3. Connect the portc 7-4 to C3-C0, portc 3-0 to R3-R0.
.include "m2560def.inc"

.equ	PORTCDIR = 0xF0			; PC[7:4] output, PC[3:0], input
.equ	INITCOLMASK = 0xEF		; scan from the leftmost column
.equ	INITROWMASK = 0x01		; scan from top row
.equ	ROWMASK = 0x0F			; for obtaining input from Port F

.def	row = r17               ; define row to r17
.def	col = r18               ; define col to r18
.def	rmask = r19			    ; mask for current row during scan
.def	cmask = r20				; mask for current column during scan
.def	kb_input = r21			; define keyBoard input to r21 
.def    tmp2 = r22              ; define temp2 to r22
.def	tmp3 = r23              ; define temp3 to r23
.def    count = r24             ; define to judge whether changline
.def    temp = r25              ; define temp to r25
.def    flag_pressing = r26     ; judge whether key which is pressed is release

.macro read_kb					; read input and store it at kb_input
	clr 	flag_pressing       ; clear flag_pressing to 0

button_released:
	cpi 	flag_pressing, 0xFF ; if flag is set, and we scan
	breq 	got_result			; all column without getting anything,
								; it means button is released
								; At this moment, kb_input carrys what we want.
								; else: we haven't got anything, so keep reading.

read:
	; flag: 1/0
	ldi		cmask, INITCOLMASK  ; init column mask reg
	clr		col					; init col

colloop:
	cpi		col, 4 				; compare col with 4
	breq	button_released		; if all keys are scanned, repeat
	out		PORTC, cmask		; otherwise, scan a column

	ldi		tmp3, 0xFF		    ; slow down the scan operation
delay:
	dec		tmp3                ; tmp3 = tmp3 - 1
	brne	delay               ; if tmp3 != 0 , branch to delay

	in		tmp3, PINC			; read PORTC
	andi	tmp3, ROWMASK		; get the keypad output value
	

	cpi		tmp3, 0xF			; check if any row is low

	breq	nextcol             ; branch to nextcol
								; if any, find which row is low
	ldi		rmask, INITROWMASK  ; initialize for row check
	clr		row					; init row

rowloop:
	cpi		row, 4				; end loop condition
	breq	nextcol				; branch to nextcol

	mov		tmp2, tmp3          ; move data from tmp3 to tmp2
	and		tmp2, rmask 		; and operation

	breq	convert				; if (bit is clear): the key is pressed
	inc		row					; else: move to next row
	lsl		rmask               ; rmask = rmask * 2
	jmp		rowloop             ; jump to rowloop

nextcol:						; if row scan is over
	lsl		cmask               ; cmask = cmask * 2
	inc		col					; increase column value
	jmp		colloop             ; jump to colloop

convert:
	cpi		col, 3				; if (col == 3): letter
	breq	letters				; branch to letters

	cpi		row, 3				; elif (row == 3): a symbol or 0
	breq	symbols				; branch to symbols
one_to_nine:					; else: number 1-9
	mov		kb_input, row
	lsl		kb_input
	add		kb_input, row		; kb_input = row * 3
	add		kb_input, col		; kb_input += col
	subi	kb_input, -1		; add value of character '1'
	ldi     temp, '0'           ; load ascii code of '0' to temp
	add     kb_input, temp      ; kb_input = kb_input + '0'
	jmp		convert_end         ; jump to convert_end

zero:
	ldi		kb_input, '0'		; set to zero
	jmp		convert_end         ; jump to convert_end

letters:
	ldi		kb_input, 'A'		; kb_input = row + 0x0A
	add		kb_input, row       ; get the correct character from letters
	jmp		convert_end         ; jump to convert_end

symbols:
	cpi		col, 0				; if symble == '*'
	breq	star                ; branch to star
	cpi		col, 1				; if symble == '0'
	breq	zero                ; branch to zero
	ldi		kb_input, '#'		; if symble == "#"
	jmp		convert_end         ; jump convert_end

star:
	ldi		kb_input, '*'       ; load ascii code of '*' to kb_input
	jmp		convert_end         ; jump to convert_end

convert_end:
	ser 	flag_pressing 		; set flag
	jmp 	read                ; jump to read

got_result:
.endmacro

.macro do_lcd_command           ; transfer command to LCD
	ldi r16, @0                 ; load data @0 to r16
	rcall lcd_command           ; rcall lcd_command
	rcall lcd_wait              ; rcall lcd_wait
.endmacro
.macro do_lcd_data              ; transfer data to LCD
	mov r16, @0                 ; move data @0 to r16
	rcall lcd_data              ; rcall lcd_data
	rcall lcd_wait              ; rcall lcd_wait
.endmacro


RESET:
                                 ; keypad initalization
    ldi tmp3, PORTCDIR           ; load tmp3 to PORTDIR, PC[7:4] output, PC[3:0], input
	out DDRC, tmp3               ; out tmp3 to DDRC
	clr count                    ; clear count

	ldi r16, low(RAMEND)         ; RAMEND : 0x21FF       
	out SPL, r16                 ; initial stack pointer Low 8 bits
	ldi r16, high(RAMEND)        ; RAMEND: 0x21FF
	out SPH, r16                 ; initial High 8 bits of stack pointer

	                             ; LCD initalization
	ser r16                      ; set r16 to 0xFF
	out DDRF, r16                ; set PORT F to input mode
	out DDRA, r16                ; set PORT A to input mode
	clr r16                      ; clear r16
	out PORTF, r16               ; out 0x00 to PORT F
	out PORTA, r16               ; out 0x00 to PORT A

	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_5ms
	do_lcd_command 0b00111000 ; 2x5x7
	rcall sleep_1ms
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00111000 ; 2x5x7
	do_lcd_command 0b00001001 ; display off
	do_lcd_command 0b00000001 ; clear display
	do_lcd_command 0b00000110 ; increment, no display shift
	do_lcd_command 0b00001111 ; Cursor on, bar, no blink

main:

read_character:
	read_kb                         ; read data from key_board

    do_lcd_data kb_input            ; display kb_input to LCD screen
	inc count                       ; count = count + 1
	cpi count, 16                   ; if count == 16, means should change to another line
	brne no_change_line             ; if not equal, can display in the following
change_line:
	do_lcd_command 0b11000000       ; use lcd command to change to another line
no_change_line:

    cpi count, 32                   ; compare count with 32
	brne no_clear                   ; if not equal, branch to no_clear
	clr count                       ; clear count to 0
	do_lcd_command 0b00000001       ; use lcd
no_clear:

	jmp main                        ; jump to main


halt:                               ; halt
	rjmp halt

.equ LCD_RS = 7                     ; LCD_RS equal to 7        
.equ LCD_E = 6                      ; LCD_E equal to 6
.equ LCD_RW = 5                     ; LCD_RW equal to 5
.equ LCD_BE = 4                     ; LCD_BE equal to 4

.macro lcd_set
	sbi PORTA, @0                   ; set pin @0 of port A to 1
.endmacro
.macro lcd_clr
	cbi PORTA, @0                   ; clear pin @0 of port A to 0
.endmacro

;
; Send a command to the LCD (r16)
;

lcd_command:                        ; send a command to LCD IR
	out PORTF, r16
	nop
	lcd_set LCD_E                   ; use macro lcd_set to set pin 7 of port A to 1
	nop
	nop
	nop
	lcd_clr LCD_E                   ; use macro lcd_clr to clear pin 7 of port A to 0
	nop
	nop
	nop
	ret

lcd_data:                           ; send a data to LCD DR
	out PORTF, r16                  ; output r16 to port F
	lcd_set LCD_RS                  ; use macro lcd_set to set pin 7 of port A to 1
	nop
	nop
	nop
	lcd_set LCD_E                   ; use macro lcd_set to set pin 6 of port A to 1
	nop
	nop
	nop
	lcd_clr LCD_E                   ; use macro lcd_clr to clear pin 6 of port A to 0
	nop
	nop
	nop
	lcd_clr LCD_RS                  ; use macro lcd_clr to clear pin 7 of port A to 0
	ret

lcd_wait:                            ; LCD busy wait
	push r16                         ; push r16 into stack
	clr r16                          ; clear r16
	out DDRF, r16                    ; set port F to output mode
	out PORTF, r16                   ; output 0x00 in port F 
	lcd_set LCD_RW
lcd_wait_loop:
	nop
	lcd_set LCD_E                    ; use macro lcd_set to set pin 6 of port A to 1
	nop
	nop
    nop
	in r16, PINF                     ; read data from port F to r16
	lcd_clr LCD_E                    ; use macro lcd_clr to clear pin 6 of port A to 0
	sbrc r16, 7                      ; Skip if Bit 7 in R16 is Cleared
	rjmp lcd_wait_loop               ; rjmp to lcd_wait_loop
	lcd_clr LCD_RW                   ; use macro lcd_clr to clear pin 7 of port A to 0
	ser r16                          ; set r16 to 0xFF
	out DDRF, r16                    ; set port F to input mode
	pop r16                          ; pop r16 from stack
	ret

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

