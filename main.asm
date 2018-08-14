#include "p12f510.inc"
 __config _OSC_IntRC & _WDT_ON & _CP_OFF & _MCLRE_OFF & _IOSCFS_ON
 
;----------------------------------------
;Constants

SER_DAT equ GP4
SER_CLK equ GP5
DIS_DIG1_ON equ GP0
DIS_DIG2_ON equ GP2
BUT1 equ GP1
BUT2 equ GP3
 
;----------------------------------------
 
;----------------------------------------
;Variables
udata
 
MAIN_COUNTER res 1
DELAY_COUNTER res 1
DELAY_TIME res 1
SERIAL_BYTE res 1
SERIAL_COUNTER res 1
DIG1 res 1
DIG2 res 1
SUB_DIG res 1
CUR_DIG res 1
PREV_BUT_STATE res 1
 
;---------------------------------------

res_vect  code    0x0000
    goto    setup_state

main_prog code

setup_state
	movlw b'00011111'
	option	
	bcf CM1CON0, 3	;turn off CM1
	clrf ADCON0	;turn off AD0
	clrf GPIO
	movlw b'00001010'
	tris GPIO
	movlw d'0'
	movwf DIG1
	movlw d'1'
	movwf DIG2
	clrf PREV_BUT_STATE
	
	call update_digits
	movlw d'100'
	movwf DELAY_TIME
	call delay
	
	goto config_state
	
config_state
	clrwdt
	
	call update_digits
	movlw d'10'
	movwf DELAY_TIME
	call delay
		
	btfss GPIO,BUT2
	goto counting_state
	
	btfsc GPIO,BUT1
	goto but1_down
	bsf PREV_BUT_STATE,0
	
	goto config_state

but1_down
	btfss PREV_BUT_STATE,0
	goto config_state
	bcf PREV_BUT_STATE,0
	decfsz DIG2
	goto config_state
	movlw d'9'
	movwf DIG2
	goto config_state
	
counting_state
	clrwdt
	call update_counter
	call update_digits
	movlw d'10'
	movwf DELAY_TIME
	call delay
	goto counting_state
	
;---------------------------update_counter: ---------------------------
update_counter
	decfsz SUB_DIG
	retlw b'0'
	movlw d'100'
	movwf SUB_DIG
	decf DIG1
	incfsz DIG1
	goto dig1_dec
	decf DIG2
	incfsz DIG2
	goto dig1_res
	goto $
	
dig1_res	decf DIG2
	movlw d'9'
	movwf DIG1
	retlw b'0'
	
dig1_dec	decf DIG1
	retlw b'0'
	
;---------------------------update_digits: ---------------------------
update_digits
	movlw b'1'
	xorwf CUR_DIG,F
	btfss CUR_DIG,0
	goto digit1
	goto digit2
	
digit1	bcf GPIO,DIS_DIG2_ON
	bsf GPIO,DIS_DIG1_ON
	movfw DIG1
	call sd_lookup
	movwf SERIAL_BYTE
	call serial_send
	retlw b'0'
	
digit2	bcf GPIO,DIS_DIG1_ON
	bsf GPIO,DIS_DIG2_ON
	movfw DIG2
	call sd_lookup
	movwf SERIAL_BYTE
	call serial_send
	retlw b'0'
	
;---------------------------sd_lookup: 7 digit display lookup table  ---------------------------
sd_lookup   addwf PCL
	retlw b'10000001'
	retlw b'11001111'
	retlw b'10010010'
	retlw b'10000110'
	retlw b'11001100'
	retlw b'10100100'
	retlw b'10100000'
	retlw b'10001111'
	retlw b'10000000'
	retlw b'10000100'
	
;---------------------------serial_send: Send serial ---------------------------
serial_send
	movlw d'9'
	movwf SERIAL_COUNTER
serial_loop	decfsz SERIAL_COUNTER
	goto serial_send_bit
	bcf GPIO,SER_CLK
	bcf GPIO,SER_DAT
	retlw b'0'
serial_send_bit
	bcf GPIO,SER_CLK
	rrf SERIAL_BYTE
	btfss STATUS,C
	goto serial_send_0
	goto serial_send_1
serial_send_1
	bsf GPIO,SER_DAT
	nop
	nop
	bsf GPIO, SER_CLK
	goto serial_loop
serial_send_0
	bcf GPIO,SER_DAT
	nop
	nop
	bsf GPIO,SER_CLK
	goto serial_loop
		
;--------------------------- Delay: x ms delay subroutine ---------------------------
; Paramater: DELAY_TIME = delay amount in ms - 1
delay
	clrwdt
	call delay1
	decfsz DELAY_TIME
	goto delay
	retlw b'0'

;--------------------------- Delay1: 1 ms delay subroutine ---------------------------
delay1
	movlw h'FF'
	movwf DELAY_COUNTER
delay1loop1
	decfsz DELAY_COUNTER
	goto delay1loop1
	movlw h'FF'
	movwf DELAY_COUNTER
delay1loop2
	decfsz DELAY_COUNTER
	goto delay1loop2
	movlw d'80'
	movwf DELAY_COUNTER
delay1loop3
	decfsz DELAY_COUNTER
	goto delay1loop3
	retlw b'0'
	end

