;**************************************
; HC-SR04 Ultrasonic Sensor Interface
; ATmega32 Assembly Code
;**************************************
.INCLUDE "m32def.inc" ; Include ATmega32 definitions
.ORG 0x00 ; Start at memory location 0x00
;**************************************
; Interrupt Vectors
;**************************************
RJMP MAIN ; Reset vector
.ORG INT0addr ; External Interrupt 0 Vector
RJMP INT0_ISR ; Jump to ISR
;**************************************
; Variable Definitions
;**************************************
.DEF PULSE = R16 ; Stores pulse width
.DEF TEMP = R17 ; Temporary register
.DEF DISTANCE = R18 ; Stores calculated distance
.DEF LCD_POS = R19 ; LCD position counter
;**************************************
PAGE 14
; MAIN Program
;**************************************
MAIN:
 LDI R16, 0xFF ; Set PORTD as output except PD2 (Echo
input)
 OUT DDRD, R16
 CBI DDRD, PD2 ; Set PD2 as input (Echo)

 LDI R16, (1<<INT0) ; Enable External Interrupt 0
 OUT GICR, R16
 LDI R16, (1<<ISC00) ; Set INT0 to trigger on any edge
 OUT MCUCR, R16
 SEI ; Enable global interrupts
 LDI R16, 0x00 ; Clear Timer1
 OUT TCNT1H, R16
 OUT TCNT1L, R16
LOOP:
 SBI PORTD, PD0 ; Trigger HIGH
 CALL DELAY_15US ; Delay for 15 microseconds
 CBI PORTD, PD0 ; Trigger LOW

 CALL DISPLAY ; Call LCD display function
 RJMP LOOP ; Repeat continuously
;**************************************
; ISR for INT0 (Echo Signal Processing)
;**************************************
PAGE 15
INT0_ISR:
 SBIC TCCR1B, CS10 ; Check if Timer1 is running
 RJMP CAPTURE_FALL ; If running, capture falling edge
 ; Capture Rising Edge
 LDI R16, (1<<CS10) ; Start Timer1 (No Prescaler)
 OUT TCCR1B, R16
 RJMP EXIT_ISR
CAPTURE_FALL:
 CLR R16 ; Stop Timer1
 OUT TCCR1B, R16
 IN R16, TCNT1L ; Read Timer1 low byte
 MOV PULSE, R16
 IN R16, TCNT1H ; Read Timer1 high byte
 LSL R16 ; Shift left to combine 16-bit value
 OR PULSE, R16
 LDI R16, 58 ; Conversion factor (1 pulse = 58 µs/cm)
 CALL DIVISION ; Calculate distance (PULSE / 58)
 MOV DISTANCE, R16 ; Store result
 LDI R16, 0x00 ; Reset Timer1
 OUT TCNT1H, R16
 OUT TCNT1L, R16
EXIT_ISR:
 RETI ; Return from interrupt
PAGE 16
;**************************************
; LCD Display Function
;**************************************
DISPLAY:
 CALL LCD_CLEAR
 LDI LCD_POS, 0x80 ; Set cursor position (First row)
 CALL LCD_CMD
 LDI R16, 'D' ; Display "Distance="
 CALL LCD_DATA
 LDI R16, 'i'
 CALL LCD_DATA
 LDI R16, 's'
 CALL LCD_DATA
 LDI R16, 't'
 CALL LCD_DATA
 LDI R16, 'a'
 CALL LCD_DATA
 LDI R16, 'n'
 CALL LCD_DATA
 LDI R16, 'c'
 CALL LCD_DATA
 LDI R16, 'e'
 CALL LCD_DATA
 LDI R16, '='
 CALL LCD_DATA
 MOV R16, DISTANCE ; Display distance value
 CALL LCD_NUMBER
PAGE 17
 LDI R16, 'c' ; Display "cm"
 CALL LCD_DATA
 LDI R16, 'm'
 CALL LCD_DATA
 RET
;**************************************
; Delay Functions
;**************************************
DELAY_15US:
 LDI R16, 12 ; Approximate 15µs delay
D_LOOP:
 DEC R16
 BRNE D_LOOP
 RET
;**************************************
; LCD Functions
;**************************************
LCD_CMD:
 OUT PORTB, R16 ; Send command to LCD
 SBI PORTC, 0 ; RS = 0 (Command)
 SBI PORTC, 1 ; Enable pulse
 CBI PORTC, 1
 CALL DELAY_15US
 RET
LCD_DATA:
 OUT PORTB, R16 ; Send data to LCD
 SBI PORTC, 0 ; RS = 1 (Data)
PAGE 18
 SBI PORTC, 1 ; Enable pulse
 CBI PORTC, 1
 CALL DELAY_15US
 RET
LCD_CLEAR:
 LDI R16, 0x01 ; LCD clear command
 CALL LCD_CMD
 CALL DELAY_15US
 RET
LCD_NUMBER:
 LDI R17, 10 ; Divide by 10 to extract digits
 CLR R19 ; Counter
DIV_LOOP:
 CP R16, R17
 BRLO PRINT_DIGIT ; If number < 10, print it directly
 SUB R16, R17
 INC R19
 RJMP DIV_LOOP
PRINT_DIGIT:
 ADD R16, '0' ; Convert to ASCII
 CALL LCD_DATA
 MOV R16, R19 ; Print remaining digit
 ADD R16, '0'
 CALL LCD_DATA
 RET
