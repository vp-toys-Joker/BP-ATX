;
; OnOffCtrl.asm
; version 0.31  
;����������� ���������� ������� ������:
; ���� ���������� �������� � ���������� _int0
; �������� ������ �������� ��� ������� �� ������, � �� ��� ����������.
; v0.1: 08.10.2019
; v0.2: 16.11.2019
; v0.31: 06.12.2019
; Author : vp
;
;====================================================================
;====================================================================
;                       DEFINITIONS
;====================================================================
;.set _DEBUG_ = 1
.def fdel = r0  ;1 - ���� ������� ���������� ��� �������� �������: 0 - ������ (������� �����); 1 - �������� (����)
;==============================================================================================
;                               ��������� � ������
;==============================================================================================
;====================================================================
; state |                       0 - ��������                        |
;====================================================================
; mode  | ���������� | �������� ��������� | ��������� ������������� |
;       |  ��������  | (��������� �������-| (�� �� ���������� ���   |
;       |  ������    |  ���)              | ��������������� ������. |
;       |============================================================
;       |     0      |         1          |          2              |
;====================================================================
; state |                       1 - �������                         |
;====================================================================
; mode  | ���������� | �������� ����������| ��������� ������������� |
;       | ��������   |(���������� �������-| (�� �� ����������)      |
;       | ������     | ���)               |                         |
;       |============================================================
;       |    0       |         1          |          2              |
;====================================================================
.def state = r1      ; ���������: 0 - ��������; 1 - �������
.def mode = r2       ; ����� ���������
.def button_event = r3    ; ������� ������� ������: 0 - ��� �������; 1 - ���� ������ ��� ������.
.def key_state = r4 ; ��������� ����������� ������� ������: 
                     ;     0 - ��������: ��������� �������� - ��������. ���������� key_process
                     ;     1 - ������� ����������� ���������� - ��������� ��������� ����� INT0 - ������ ��������� �������� ���������
                     ;     2 - ������� ����������� ���������� - ��������� �������� ��������� � ����������� ��������� ������
                     ;         ��������. ���������� key_process
.def pwr_ok_event = r5; ������� ��������� ��������� ������������ ������� PW_OK
                     ;     0 - ��������: ��� �������;
                     ;     1 - ������� - ��������� ����������
.def pwr_ok_state = r6; ��������� ����� ������������ ������� PW_OK
                     ;     0 - ��� ����������;
                     ;     1 - ���� ����������
.def const_0 = r7    ; ������� ������ ���� ����� 0
.def const_1 = r8    ; ������� ������ ���� ����� 1
.def const_2 = r9    ; ������� ������ ���� ����� 2
.def button_state = r10  ; ��������� ������: 0 - ������; 1 - ������.

.def temp1 = r16
.def temp2 = r17
.def temp3 = r18

.INCLUDE "macros.inc"
.INCLUDE "constants_time.inc"
.INCLUDE "var-offonctrl.inc"

.CSEG              
.ORG 0
;===========================================================================================
;                           ����� � ������� ����������
;===========================================================================================
	rjmp start
	rjmp _int0
	rjmp pcint
	rjmp tim_ovo
	rjmp ee_rdy
	rjmp ana_comp
	rjmp tim_compa
	rjmp tim_compb
	rjmp watch_dog
	rjmp ADConv


.INCLUDE "calls.asm"

;===========================================================================================
;                            ������������� ���������
;===========================================================================================
start:
	ldi temp1, low(RAMEND)
	out SPL, temp1
    ;=====================================================
	;           ��������� ������ �����/������
    ;=====================================================
	ldi temp1, 0x19   ; b00011001
    out ddrB, temp1	; B1,B2,B5 - �����, B0,B3,B4 - ������
	ldi temp1, 0x1A	; b00011010 B1 � ���������,B2,B5-���;B0=0,B3,B4==1
	out portB, temp1
    ;=====================================================
	;     ��������� ������������ ��������� ����������
    ;=====================================================
.ifdef _DEBUG_
	in  temp1, clkpr	; �������� �������� �� ��������
.endif
	ldi temp1, 0x80
	ldi temp2, 0x01   ; ���� ������������ ��������� ���������� = 2
	out clkpr, temp1
	out clkpr, temp2
.ifdef _DEBUG_
	in  temp1, clkpr  ; �������� �������� ����� ��������
.endif
    ;=====================================================
    ;               ��������� �������
    ;=====================================================
	clr temp1
	out timsk0, temp1	; ���������� �� ������� T0 ���������
	out tccr0a, temp1	; ����� T0 - normal, OCR0A � OCR0B ��������� �� ������� 
	ldi temp1, 0xff	;
	out ocr0a, temp1
	ldi temp1, 0x02   ; ���� ������������ T0 = 8
	out tccr0b, temp1	
    ;=====================================================
    ;               ������������� ������
    ;=====================================================
    clr fdel    ; ����� ������������ �������� ������� ���������� TCNT0
    clr state   ; ��������� �������� ��������� - �� ��������
    clr mode    ; ��������� ������ �������� ������� ������ ��� ��������� ��
    in button_state, pinB  ; ��������� ��������� ������� ������
    ldi temp1, 0x02
    and button_state, temp1
    lsr button_state
    clr button_event  ; ����� ��������� ����������� �������� ����������
    clr key_state  ; ����� ��������� ����������� ������� ������
    ;clr pwr_ok_state  ; ����� ��������� ����� �������� ����������
    in pwr_ok_state, pinB  ; ��������� ��������� ����� �������� ����������
    ldi temp1, 0x04
    and pwr_ok_state, temp1
    lsr pwr_ok_state
    lsr pwr_ok_state
    clr pwr_ok_event  ; ����� ��������� ����������� �������� ����������
    clr const_1;
    ldi temp3, 1
    mov const_1, temp3
    ldi temp3, 2
    mov const_2, temp3
.ifdef _DEBUG_
    clr shatter_count  ; �������. �������� �������� �������� ��������� �� ������ (��� �������)
    clr shatter2_count ; �������. �������� �������� �������� ��������� �� �������� ���������� (��� �������)
.endif
    ;=====================================================
    ;           ������������� ��������: ����������
    ;=====================================================
     clr temp3
     sts timer01, temp3
     sts timer02, temp3
     sts timer03, temp3
     sts timer0Z, temp3
    ;=====================================================
    ;       �������� ���������� ������������ TCNT0
    ;=====================================================
    ldi temp1, 0x02       ; 0x02 - ��� ���������� �� ������������ TCNT0
    in temp2, timsk0
    or temp2, temp1
    out timsk0, temp2     ; ��������������� ���������� ���������� �� ������������ TCNT0
    ;=====================================================
    ;   �������� ����� ���������� PCINT2
    ;=====================================================
    _SET_NUM_PCIE_ temp1, temp2, 0x04   ; 0x04 - �������� ����� ���������� PCINT2
    ;=====================================================
    ; �������� ����� �������� ���������� INT0 
    ; 0 - �� ������� ������
    ; 1 - ��� ����� ��������� 
    ; 2 - �� �����
    ; 3 - �� ������
    ;=====================================================
    _MODE_INT0_ temp1, temp2, 1   
    ;=========================================================
    ; �������� ���������� �� �������� ���������� INT0 � PCIE
    ;=========================================================
    _EN_EXTINT_ temp1, temp2, 0x60  ; 0x40 - ��� ���������� �� INT0 + 0x20 - ��� ���������� �� PCIE
    ;=====================================================
    ;       ����� ������ ���������� �� �������
    ;=====================================================
    clr temp1
    out tifr0, temp1
    sei
;===========================================================================================
;                            �������� ���������
;===========================================================================================
main_loop:
    ;=====================================================
    ;              ����������� ��������� �������
    ;=====================================================
    cp state, const_1
    breq main_loop_state1
    rcall main_state0
    rjmp main_loop_continue

main_loop_state1:
    rcall main_state1

main_loop_continue:    
    rcall main_loop_indication
    rjmp main_loop

;===========================================================================================
;                           ����������� ������������
;===========================================================================================
    ;=====================================================
    ;          ��   ��������� ��������� 0 - "��������"
    ;=====================================================
main_state0:
    cp mode, const_1
    breq main_loop_state0_mode1
    rcall main_state0_mode0
    rjmp main_state0_return

main_loop_state0_mode1:
    rcall main_state0_mode1

main_state0_return:
    ret

    ;=====================================================
    ;          ��   ��������� ��������� 0 - ����� 0
    ;=====================================================
main_state0_mode0:
    rcall  pwr_ctrl_process  ; ����� �� �������� ������� PW_OK
    cp pwr_ok_state, const_1
    breq main_state0_mode0_return  ; ���� 1 - ������������� ��
    rcall key_process   ; ����� ����������� ������� �� ������
    cp button_event, const_1
    brne main_state0_mode0_return  ; ���� 0
    clr button_event ; ����� ������� �� ������
    cp button_state, const_1  ; �������� ��������� ������
    breq main_state0_mode0_set_mode1  ; ���� 1 - ��������� ��
    ; ���� 0
    ;=====================================================
    ; ������ ���� ������. ������ ��������� �������
    ;=====================================================
    ldi temp3, 1    ; ��������� ������ ����� ����� �������������
    ; ������ ������� ����� - �������� ������������� ������� ������
    ldi XL, LOW(timer01)  
    ldi temp1, LOW(key_snd_time) 
    ldi temp2, HIGH(key_snd_time)
    rcall _set_timer_proc_
    _OCR0A_On_ temp1, temp2 ; �������� ���� - �������� ������������� ������� ������
    rjmp main_state0_mode0_return  ; 
main_state0_mode0_set_mode1:   
    ;��������� ��
    ;=====================================================
    ; ������ ���� ��������. ������� � ����� 1
    ;=====================================================
    in temp1, PinB
    ldi temp2, 0xf7
    and temp1, temp2
    out portB, temp1  ; ���������� � 0 ������ PS_ON ��
    ; ���������� ����� 1 ��������� 0
    inc mode
    ; ������ ������� �������� ���������/���������� ��
    ldi temp3, 1    ; ��������� ������ ����� ����� �������������
    ldi XL, LOW(timer03)  
    ldi temp1, LOW (time_wait) 
    ldi temp2, HIGH(time_wait)
    rcall _set_timer_proc_
main_state0_mode0_return:
    ret

    ;=====================================================
    ;          ��   ��������� ��������� 0 - ����� 1
    ;=====================================================
main_state0_mode1:
    rcall  pwr_ctrl_process  ; ����� �� �������� ������� PW_OK
    ; �������� ��������� ��
    cp pwr_ok_state, const_1                          ; 1 - ������ PW_OK ������������
    brne  main_state0_mode1_off         ; 0 - �����������
main_state0_mode1_on:
    ; �� ���������
    ; ��������� ������ 0 ��������� 1
    clr mode   ; ���������� ����� 0 ��������� 1
    inc state  ; ���������� ��������� 1
    ; ���������� ����������� ��������� ���������/���������� ��
    ldi temp1, 0xef
    in temp2, pinB
    and temp2, temp1
    out portB, temp2  ; �������� ���������
    ldi temp3, 0
    sts timer02, temp3 ; ��������� ������ ������� ���������� 
    sts timer03, temp3 ; ��������� ������ �������� ���������
    rjmp main_state0_mode1_return
main_state0_mode1_off:
    ; �������� ��������� ��
    lds temp1, timer03
    cpi temp1, 0
    brne main_state0_mode1_return
    ; �� �� ��������� - ���� ���������
    clr mode   ; ���������� ����� 0 ��������� 0
    in temp1, PinB
    ldi temp2, 0x08
    or temp1, temp2
    out portB, temp1  ; ���������� � 1 ������ PS_ON ��
    rcall set_power_error
main_state0_mode1_return:
    ret

;==============================================================================

    ;=====================================================
    ;          ��   ��������� ��������� 1 - "�������"
    ;=====================================================
main_state1:
    cp mode, const_1
    breq main_loop_state1_mode1
    rcall main_state1_mode0
    rjmp main_state1_return

main_loop_state1_mode1:
    rcall main_state1_mode1

main_state1_return:
    ret

    ;=====================================================
    ;          ��   ��������� ��������� 1 - ����� 0
    ;=====================================================
main_state1_mode0:
    rcall  pwr_ctrl_process  ; ����� �� �������� ������� PW_OK
    ; �������� ������ ��
    cp pwr_ok_state, const_1                          ; 1 - ������ PW_OK ������������
    brne  main_state1_mode0_off         ; 0 - �����������
    rcall key_process   ; ����� ����������� ������� �� ������
    cp button_event, const_1
    brne main_state1_mode0_return  ; ���� 0
    clr button_event ; ����� ������� �� ������
    cp button_state, const_1  ; �������� ��������� ������
    breq main_state1_mode0_set_mode1  ; ���� 1 - ��������� ��
    ; ���� 0
    ;=====================================================
    ; ������ ���� ������. ������ ��������� �������
    ;=====================================================
    ldi temp3, 1    ; ��������� ������ ����� ����� �������������
    ; ������ ������� ����� - �������� ������������� ������� ������
    ldi XL, LOW(timer01)  
    ldi temp1, LOW(key_snd_time) 
    ldi temp2, HIGH(key_snd_time)
    rcall _set_timer_proc_
    _OCR0A_On_ temp1, temp2 ; �������� ���� - �������� ������������� ������� ������
    rjmp main_state1_mode0_return  ; 
main_state1_mode0_set_mode1:
    ;���������� ��
    ;=====================================================
    ; ������ ���� ��������. ������� � ����� 1
    ;=====================================================
    in temp1, PinB
    ldi temp2, 0x08
    or temp1, temp2
    out portB, temp1  ; ���������� � 1 ������ PS_ON ��
    ; ���������� ����� 1 ��������� 1
    inc mode
    ; ������ ������� �������� ���������/���������� ��
    ldi temp3, 1    ; ��������� ������ ����� ����� �������������
    ldi XL, LOW(timer03)  
    ldi temp1, LOW (time_wait) 
    ldi temp2, HIGH(time_wait)
    rcall _set_timer_proc_
    rjmp main_state1_mode0_return
main_state1_mode0_off:
    ; �� ��������������� ����������
    rcall set_power_error
    rjmp main_state1_mode0_set_mode1
main_state1_mode0_return:
    ret

    ;=====================================================
    ;          ��   ��������� ��������� 1 - ����� 1
    ;=====================================================
main_state1_mode1:
    rcall  pwr_ctrl_process  ; ����� �� �������� ������� PW_OK
    ; �������� ���������� ��
    cp pwr_ok_state, const_0                          ; 0 - ������ PW_OK �����������
    brne  main_state1_mode1_on          ; 1 - ������������
main_state1_mode1_off:
    ; �� ����������
    ; ��������� ������ 0 ��������� 0
    clr mode   ; ���������� ����� 0 ��������� 0
    clr state  ; ���������� ��������� 0
    ; ���������� ����������� ��������� ���������/���������� ��
    ldi temp1, 0x10 ;0xef
    in temp2, pinB
    or temp2, temp1
    out portB, temp2  ; ��������� ���������
    rjmp main_state1_mode1_return
main_state1_mode1_on:
    ; �������� ���������� ��
    lds temp1, timer03
    cpi temp1, 0
    brne main_state1_mode1_return
    ; �� �� ���������� - ���� ����������
    rcall set_power_error
    rjmp main_state1_mode1_off
main_state1_mode1_return:
    ret

;==============================================================================

    ;=====================================================
    ;                ��  ������ ���������
    ;=====================================================
main_loop_indication:
    lds temp1, timer01
    tst temp1
    brne main_loop_indication_continue
	_OCR0A_Off_ temp1, temp2    ; ��������� ����
main_loop_indication_continue:
    cp state, const_0
    brne main_loop_indication_return
    ; ��������� �������� ��������� ����������
    lds temp1, timer02
    tst temp1
    brne main_loop_indication_return
    ; ���������� ����������� ��������� ���������/���������� ��
    ldi XL, LOW(timer02)
    ldi temp1, LOW(led_light_time)
    ldi temp2, HIGH(led_light_time)
    ldi temp3, 1
    rcall _set_timer_proc_
    ldi temp1, 0x10
    in temp2, pinB
    eor temp2, temp1
    out portB, temp2
    ; ��������� �������������: ������ ������������ ��
    cp pwr_ok_state, const_1
    brne main_loop_indication_return
    and temp2, temp1
    cpi temp2, 0x10
    brne main_loop_indication_return
    ldi XL, LOW(timer01)
    ldi temp1, LOW(led_light_time)
    ldi temp2, HIGH(led_light_time)
    ldi temp3, 1
    rcall _set_timer_proc_
	_OCR0A_On_ temp1, temp2    ; �������� ����
  
main_loop_indication_return:
    ret

;===========================================================================================
;                            ����������� ����������
;===========================================================================================
tim_ovo: 
;=========================================================
;     ���������� �� ������������ ������� T0
;   ���������� ��������� ������ ����������� ��������
;=========================================================
    ; ���������� ��������� � �����
    push temp1
    in temp1, sreg
    push temp1
    push YL
    push YH
    push XL
    push r24
    push r25
    ;=====================================================
    ;               �������� ������� �� 2
    ;=====================================================
    ldi YL, low(timer01)   ; ������� ����� �� ������ ������
    clr YH
    tst fdel      ; �������� �������� �����
    breq tim_ovo_return   ; ���� 0 - ������� �����, ���� ������
    ;=====================================================
    ;           ���� �������� � ������ ���� ��������
    ;=====================================================
    ldi XL, LOW( timer0Z)   ; ��������� ��. ���� ������ ��������� timer0Z - ��������� ������ ��������
    inc XL  ; +1 ��� ���� ����� ������� XL �������� ������ ������ timer0Z � �������� brlt �� ��������� ��������� breq
tim_ovo_repeat:
    ld r24, Y   ; ��������� ��������� �������� �������
    tst r24
    breq tim_ovo_next ; ���� 0 - ������� ������ �� �������
    ldd r24, Y+1    ; �������� �������� �������� ������� - ��. ����
    ldd r25, Y+2    ; �������� �������� �������� ������� - ��. ����
    sbiw r24, 1     ; ���������� �������� �������� �������
    std Y+1, r24    ; ���������� �������� �������� ������� - ��. ����
    std Y+2, r25    ; ���������� �������� �������� ������� - ��. ����
    or r24, r25     ; �������� �� 0
    brne tim_ovo_next
    st Y, r24       ; �������� ��������� �������� ������� � 0 (�� ��������)
tim_ovo_next:
    adiw Y, 3   ; ���������� ����� �� ��������� ��������� �������
    cp YL, XL   ; ��������� �� ����� ������� ��������. ����� XL > ������ timer0Z �� 1 (timer0Z - ��������� ��������� ��������) 
    brlt tim_ovo_repeat   ; ���� ��� �� �����, �� ������� � ��������� ������.
    ;breq tim_ovo_repeat
    ;=====================================================
    ;           ��������� ��������� ����������
    ;=====================================================
tim_ovo_return:
    ldi r25, 1
    eor fdel, r25
    ; �������������� ��������� �� �����
    pop r25
    pop r24
    pop XL
    pop YH
    pop YL
    pop temp1
    out sreg, temp1
    pop temp1
    
	reti


_int0: 
;=========================================================
;  ���������� �� INT0 - ��������� ������� �� ������
;        ��������� ��� ���������� ����������
;=========================================================
    ; ���������� ��������� � �����
    push temp1
    in temp1, sreg
    push temp1
    push temp2

    ;=========================================================
    ;     key_state - ��������� ����������� ������� ������
    ;     0 - �������� - ��������� �������� - ���. ���������� key_process;
    ;     1 - ��������� ��������� ��������� ����� INT0 - ���. �����
    ;     2 - ��������� �������� �������� - ���. ���������� key_process;
    ;=========================================================
    inc key_state
    ;=========================================================
    ;       �������� ������ �� �������� ���������� INT0
    ;=========================================================
;_int0_disable_:
    _DIS_EXTINT_ temp1, temp2, 0x40  ; 0x40 - ��� ���������� �� INT0
    ; �������������� ��������� �� �����
    pop temp2
    pop temp1
    out sreg, temp1
    pop temp1
    
	reti

pcint: 
;=========================================================
;         ���������� �� PCIE2 - ��������� ������ 
;             ��������� ��������� ����� B2
;       �������� �� ����������� �������� ����������
;=========================================================
    ; ���������� ��������� � �����
    push temp1
    in temp1, sreg
    push temp1
    push temp2
   
    ; ���� ������, ��� �� ���������� ������� �������� ���, �.�. �� ��� ��������� ��������
    inc pwr_ok_event
    ;=========================================================
    ;       �������� ������ �� �������� ���������� PCIE2
    ;=========================================================
;_pcint_disable_:
    _DIS_EXTINT_ temp1, temp2, 0x20  ; 0x20 - ��� ���������� �� PCIE

    ; �������������� ��������� �� �����
    pop temp2
    pop temp1
    out sreg, temp1
    pop temp1
    
	reti

ee_rdy: 
ana_comp:
tim_compa: 
tim_compb: 
watch_dog: 
ADConv: 
reti