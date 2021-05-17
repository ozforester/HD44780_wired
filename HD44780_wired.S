; somewhere in strlen hides an error

; Copyright (c) 2021 ozforester. All rights reserved.
; Use of this source code is goverened by a MIT license
; that can be found in the LICENSE file.

; ATmega8 @4MHz internal osc. (H:D9, L:23)
; HD44780_wired.S "Hello world"
; prints greeting in 4bit mode

; atmega8
;
; LED PD7
; E - PB2
; R/W - PB1
; R/S - PB0
; D7-D4 - PC3-PC0
; SPI programmer - upgraded USB-ISP

#undef __SFR_OFFSET
#define __SFR_OFFSET 0
#include <avr/io.h>

#define CTRD DDRB
#define CTRP PORTB
#define CTR_RS PB0
#define CTR_RW PB1
#define CTR_E  PB2
#define DATD DDRC
#define DATP PORTC
#define DATI PINC
#define DATA4 PC0
#define DATA5 PC1
#define DATA6 PC2
#define DATA7 PC3

accum = 0			; r0
temp  = 16			; good worker (.set)
char  = 17			; msg char
tcntr = 18			; time counter

.data

.text

.global main			;
.global TIMER0_OVF_vect		;

main:				;
        rcall led_init          ;
        rcall timer_init        ;
        rcall delay_20ms        ;
	rcall ports_init	;
	rcall lcd_init		;
	rcall lcd_string	;
        ;rcall led_on            ; j-tag (:
	loop:			;
	rjmp loop 		;
ret				;

msg1: .asciz "Hello world"       ;
msg2: .asciz "Hello world"       ;

ret				;

lcd_string:			;
        ldi zh, hi8(msg1) 	; z *-> msg
        ldi zl,	lo8(msg1)	;
	rcall strlen		; length in temp register
	ls1:			;
	lpm			; read msg word into r0
	mov char, accum		; copy word into char register
	rcall lcd_char		; write one 4bit mode char
        inc zl                  ; next 16 bit world of msg
	dec temp		; one less msg left
	brne ls1		; if not Z go next
ret				; or exit

strlen:				; count length of msg
        ;ldi temp, 7             ; debugging
	;ret			; debugging
	push zh			; save msg pointer
	push zl			; to stack
	clr temp		; clear counter
	sl1:			;
	lpm			; read msg byte into r0
	mov char, accum		; copy r0 into char
	cpi char, 0		; end of string? (seems it always non zero)
	breq sl2		; yes,  '\0' terminator
	inc temp		; increment length counter
	inc zl			; increment Z
	rjmp sl1		; and continue read flash
	sl2:			;
	pop zl			; restore flash pointer
	pop zh			; from stack
	;ldi temp, 7		; debugging
ret				;

lcd_char:			; write one character
        rcall rs_out_high       ;
        rcall rw_out_low        ;
        ; low nibble, w/o mask, bit by bit
        rcall all_data_out      ; 0000
	sbrc char, 7		;
	rcall d7_out_high	;
        sbrc char, 6            ;
        rcall d6_out_high       ;
        sbrc char, 5            ;
        rcall d5_out_high       ;
        sbrc char, 4            ;
        rcall d4_out_high       ;
        rcall e_pulse           ; HIGH TETRADE
	; high nibble
        rcall all_data_out      ; 0000
        sbrc char, 3            ;
        rcall d7_out_high       ;
        sbrc char, 2            ;
        rcall d6_out_high       ;
        sbrc char, 1            ;
        rcall d5_out_high       ;
        sbrc char, 0            ;
        rcall d4_out_high       ;
        rcall e_pulse 		; LOW TETRADE
        rcall all_data_in 	;
        rcall wait_bf           ;
ret				;

wait_bf:                        ; wait until busy flag cleared
;        rcall delay_1ms	; debugging
	rcall rs_out_low	;
        rcall rw_out_high       ;
	rcall all_data_in	;
        rcall e_out_high	;
        wb1:                    ;
        sbic DATI, DATA7        ; wait BF cleared
        rjmp wb1                ;
	rcall e_out_low		;
        nop                     ;
        nop                     ;
        nop                     ;
	nop			;
	rcall e_pulse           ;
ret                             ;

e_pulse:                        ;
        rcall e_out_high        ;
        nop			;
        nop			;
        nop			; about us
        nop			;
        rcall e_out_low         ;
ret                             ;

lcd_init:				;
        rcall delay_20ms                ; >= 40 ms
        rcall delay_20ms                ;
	rcall rs_out_low		;
	rcall rw_out_low		;
			; 8-bit mode
        rcall all_data_out              ; def. low
	rcall d4_out_high		;
	rcall d5_out_high		; 0011 - init1
	rcall e_pulse			; 1
        rcall delay_1ms                 ;
        rcall delay_1ms                 ;
        rcall delay_1ms                 ;
        rcall delay_1ms                 ;
        rcall e_pulse                   ; 2
        rcall delay_100us                ;
	rcall e_pulse			; 3
        rcall delay_100us                ;
        rcall d4_out_low                ; 0010 - pre function
        rcall e_pulse                   ; 4
        rcall delay_100us                ;
			; 4-bit mode
        rcall all_data_out              ;
        rcall d5_out_high               ; 0010 - function set, 4 bit mode
	rcall e_pulse			; 5
	rcall all_data_out		;
        rcall d7_out_high               ; 1000 - function set cont. 2 lines, 5x8 font, - -
        rcall e_pulse                   ; 6
        rcall all_data_in               ;
        rcall rw_out_high               ;
        rcall wait_bf                   ;
        rcall rw_out_low               ;
        rcall all_data_out              ; 0000 - display
        rcall e_pulse                   ; 7
        rcall d7_out_high               ; 1000 - off
        rcall e_pulse                   ; 8
        rcall all_data_in               ;
        rcall rw_out_high               ;
        rcall wait_bf                   ;
        rcall rw_out_low               ;
        rcall all_data_out              ; 0000 - display
        rcall e_pulse                   ; 9
        rcall d4_out_high               ; 0001 - clear
        rcall e_pulse                   ; 10
        rcall all_data_in               ;
        rcall rw_out_high               ;
        rcall wait_bf                   ;
        rcall rw_out_low               ;
        rcall all_data_out              ; 0000 - entry
        rcall e_pulse                   ; 11
        rcall d6_out_high               ; 0100 - mode
        rcall d5_out_high               ; 0110
        rcall e_pulse                   ; 12
        rcall all_data_in               ;
        rcall rw_out_high               ;
        rcall wait_bf                   ;
        rcall rw_out_low               ;
        rcall all_data_out              ; 0000 - display
        rcall e_pulse                   ; 13
        rcall d7_out_high               ; 1000
        rcall d6_out_high               ; 1100 - on
        rcall d5_out_high               ; 1110 - w/ cursor
        rcall d4_out_high               ; 1111 - w/ blinking
        rcall e_pulse                   ; 14
        rcall all_data_in               ;
        rcall rw_out_high               ;
        rcall wait_bf                   ;
        rcall rw_out_low               ;
        rcall delay_20ms                ; voila
ret					;

ports_init:			;
	rcall rs_out_low	;
	rcall rw_out_low	;
	rcall e_out_low		;
	rcall d4_out_low	;
	rcall d5_out_low	;
	rcall d6_out_low	;
	rcall d7_out_low	;
ret				;

all_data_in:			;
        rcall d4_in_low         ;
        rcall d5_in_low         ;
        rcall d6_in_low         ;
	rcall d7_in_low		;
ret				;

all_data_out:                   ;
        rcall d4_out_low        ;
        rcall d5_out_low        ;
        rcall d6_out_low        ;
        rcall d7_out_low        ;
ret		                ;

d4_in_low:                      ;
        cbi DATD, DATA4         ;
        cbi DATP, DATA4         ;
ret		                ;

d4_in_high:                     ;
        cbi DATD, DATA4         ;
        sbi DATP, DATA4         ;
ret                             ;

d4_out_low:                     ;
        sbi DATD, DATA4         ;
        cbi DATP, DATA4         ;
ret	                        ;

d4_out_high:                    ;
        sbi DATD, DATA4         ;
        sbi DATP, DATA4         ;
ret 	                        ;

d5_in_low:                      ;
        cbi DATD, DATA5         ;
        cbi DATP, DATA5         ;
ret 	                        ;

d5_in_high:                     ;
        cbi DATD, DATA5         ;
        sbi DATP, DATA5         ;
ret                             ;

d5_out_low:                     ;
        sbi DATD, DATA5         ;
        cbi DATP, DATA5         ;
ret 	                        ;

d5_out_high:                    ;
        sbi DATD, DATA5         ;
        sbi DATP, DATA5         ;
ret 	                        ;

d6_in_low:                      ;
        cbi DATD, DATA6         ;
        cbi DATP, DATA6         ;
ret	                        ;

d6_in_high:                     ;
        cbi DATD, DATA6         ;
        sbi DATP, DATA6         ;
ret                             ;

d6_out_low:                     ;
        sbi DATD, DATA6         ;
        cbi DATP, DATA6         ;
ret 	                        ;

d6_out_high:                    ;
        sbi DATD, DATA6         ;
        sbi DATP, DATA6         ;
ret 	                        ;

d7_in_low:                      ;
        cbi DATD, DATA7         ;
    	cbi DATP, DATA7         ;
ret		                ;

d7_in_high:                     ;
        cbi DATD, DATA7         ;
        sbi DATP, DATA7         ;
ret                             ;

d7_out_low:                     ;
        sbi DATD, DATA7         ;
        cbi DATP, DATA7         ;
ret	                        ;

d7_out_high:                    ;
        sbi DATD, DATA7         ;
        sbi DATP, DATA7         ;
ret 	                        ;

rs_out_low:			;
        sbi CTRD, CTR_RS        ;
        cbi CTRP, CTR_RS        ;
ret				;

rs_out_high:	                ;
        sbi CTRD, CTR_RS        ;
        sbi CTRP, CTR_RS        ;
ret				;

rw_out_low:                     ;
        sbi CTRD, CTR_RW        ;
        cbi CTRP, CTR_RW        ;
ret				;

rw_out_high:                    ;
        sbi CTRD, CTR_RW        ;
        sbi CTRP, CTR_RW        ;
ret				;

e_out_low:                      ;
        sbi CTRD, CTR_E         ;
        cbi CTRP, CTR_E         ;
ret				;

e_out_high:                     ;
        sbi CTRD, CTR_E         ;
        sbi CTRP, CTR_E         ;
ret				;

delay_20ms:                     ;
        ldi temp, 20            ;
	d20:			;
	rcall delay_1ms		;
	subi temp, 1		;
	brne d20		;
ret 		                ;

delay_100us:                    ;
        ldi tcntr, 4            ;
        du1:                    ;
        cpi tcntr, 0            ;
        brne du1                ;
ret		                ;

delay_1ms:                      ;
        ldi tcntr, 40           ;
        d1:                     ;
	cpi tcntr, 0		;
        brne d1                 ;
ret 		                ;

TIMER0_OVF_vect:                ;
	cli			;
        push temp               ; save
        in temp, SREG           ; save
	push temp
        ldi temp, 155           ; next 25 us
        out TCNT0, temp         ;
        subi tcntr, 1           ; delay counter--
	pop temp
        out SREG, temp          ; restore
        pop temp                ; restore
	sei			;
reti 		                ;

timer_init:				;
        ldi temp, (1<<CS00)		; prescaler 1, 0.25 us
	out TCCR0, temp			;
	ldi temp, 155			; 25 us
	out TCNT0, temp			;
	ldi temp, (1<<TOIE0)    	;
	out TIMSK, temp         	;
	sei				; go
ret					;

led_init:			;
        sbi DDRD, PD7           ; D7 output
        cbi PORTD, PD7          ; D7 low
ret				;

led_on:				;
	rcall led_init		;
        sbi PORTD, PD7          ; D7 high
ret				;

.end
