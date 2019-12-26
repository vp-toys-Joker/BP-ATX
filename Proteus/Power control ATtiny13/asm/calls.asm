/*
 * calls.asm
 *
 *  Created: 30.10.2019 17:00:56
 *   Author: vp
 */ 
.CSEG              

    ;=====================================================
    ;          ��   ������������� ��������
    ;=====================================================
_set_timer_proc_:
    tst r18
    brne _set_timer_start
    ;=====================================================
    ;   ������������ ������ ������� �� ������� ������� 
    ;=====================================================
    cli
    st X+, r18    ; �������� ���� ������� - ������ ������������ ���������� �������
    st X+, r16    ; ���������������� ��. ���� �������� �������
    st X,  r17    ; ���������������� ��. ���� �������� �������
    sei
    rjmp _set_timer_return
    ;=====================================================
    ;           ������������ ������ ������� 
    ;        ������ ��� ������������� ������� 
    ;=====================================================
_set_timer_start:
    adiw X, 3
    cli
    st -X, r17    ; ���������������� ��. ���� �������� ������� 
    st -X, r16    ; ���������������� ��. ���� �������� ������� 
    st -X, r18    ; ���������� ���� ������� - ����������� ������ ������� � ������ �����������
    sei
_set_timer_return:
    ret

    ;=====================================================
    ;           �� ��������� ������� ������ 
    ; (��������� � ������� ��������� � ������������ int0)
    ;=====================================================
key_process:
    lds r16, key_state
    cpi r16, 0
    breq key_process_return ; ��� �������
    ; ���� �������
    cpi r16, 2
    breq key_process_ready  ; key_state == 2 - �������� ������� ��������
    ; key_state == 1
    ; ������ ������� ��������
    inc r16
    sts key_state, r16  ; key_state = 2
    ldi XL, LOW(timer0Z)  
    ldi r16, LOW(key_wait) 
    ldi r17, HIGH(key_wait)
    rcall _set_timer_proc_
    rjmp key_process_return
key_process_ready:
    ; key_state == 2
    ; �������� ������� ��������
    lds r16, timer0Z
    cpi r16, 0
    brne key_process_return
    ; �������� ����� PB1
    in r17, pinB
    ldi r18, 0x02
    and r17, r18
    lsr r17
    sts button, r17
.ifdef _DEBUG_
    ; ************ ������ ������� - ������ ***********
    lds r16, shatter_count
    inc r16
    cpi r16, 2
    brne key_process_debug1
    clr r16
key_process_debug1:
    sts shatter_count, r16
   ;*********** ������ ������� - ����� ***********
 .endif
    clr r16
    sts key_state, r16   ; key_state = 0
    _EN_EXTINT_ r16, r17, 0x40  ; 0x40 - ��� ���������� �� INT0
key_process_return:
    ret

    ;==============================================================
    ; �� �������� ������� PW_OK ������������� ������� �������� �� 
    ; (��������� ��������� � ������������ tim_ovo pcint)
    ;==============================================================
pwr_ctrl_process:
    lds r16, pwr_volatile   ; �������� �������
    cpi r16, 0                ; � ����� 1 - ��������� ��������� �����
    breq pwr_ctrl_process_return    ; --> pwr_volatile == 0 - ������� ���, ����������
    ; pwr_volatile != 0 - ������� ���������
    cpi r16, 2
    breq pwr_ctrl_process_ready  ; pwr_volatile == 2 - �������� ������� ��������
    ; pwr_volatile == 1
    ; ������ ������� ��������
    inc r16
    sts pwr_volatile, r16  ; pwr_volatile = 2
    ldi XL, LOW(timer0Z)  
    ldi r16, LOW(key_wait) 
    ldi r17, HIGH(key_wait)
    rcall _set_timer_proc_
    rjmp pwr_ctrl_process_return
pwr_ctrl_process_ready:
    ; pwr_volatile == 2
    ; �������� ������� ��������
    lds r16, timer0Z
    cpi r16, 0
    brne pwr_ctrl_process_return
    ; �������� ��������� ����� PB2 �������� ������� PW_OK
    in r17, pinB
    ldi r18, 0x04
    and r17, r18
    lsr r17
    lsr r17
    sts pwr_state, r17
.ifdef _DEBUG_
    ; ************ ������ ������� - ������ ***********
    lds r16, shatter2_count
    inc r16
    cpi r16, 2
    brne pwr_ctrl_process_debug1
    clr r16
pwr_ctrl_process_debug1:
    sts shatter2_count, r16
   ;*********** ������ ������� - ����� ***********
 .endif
    clr r16
    sts pwr_volatile, r16   ; pwr_volatile = 0
pwr_ctrl_process_return:
    _EN_EXTINT_ r16, r17, 0x20  ; 0x20 - ��� ���������� �� PCIE
    ret

    ;=====================================================
    ;           �� ��������� ������ �� 
    ;=====================================================
set_power_error:
    ; �� �� ��������� - ���� ���������
	_OCR0A_On_ r16, r17    ; �������� ���� ���� ������������
    ldi XL, LOW(timer01)
    ldi r16, LOW(err_snd_time) 
    ldi r17, HIGH(err_snd_time)
    ldi r18, 1
    rcall _set_timer_proc_
    ; ��������� ������ 0 ��������� 0
    clr r16
    sts mode, r16   ; ���������� ����� 0 ��������� 0
    sts state, r16  ; ���������� ��������� 0
    ret
 
    ;=====================================================
    ;  �� ��������� �������� ����� � �������� ������� 
    ;=====================================================
set_sound_wait_timers:
    ; ������ ������� �����
    ldi XL, LOW(timer01)  
    ldi r16, LOW(key_snd_time) 
    ldi r17, HIGH(key_snd_time)
    rcall _set_timer_proc_
    ; ������ ������� �������� ���������/���������� ��
    ldi XL, LOW(timer03)  
    ldi r16, LOW (time_wait) 
    ldi r17, HIGH(time_wait)
    rcall _set_timer_proc_
    ret
