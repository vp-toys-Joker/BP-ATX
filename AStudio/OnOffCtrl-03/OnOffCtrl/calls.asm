/*
 * calls.asm
 *
 *  Created: 30.10.2019 17:00:56
 *   Author: vp
 */ 
.CSEG              

    ;=====================================================
    ;           �� ��������� ������� ������ 
    ; (��������� � ������� ��������� � ������������ int0)
    ;=====================================================
key_process:
    cp key_state, const_0
    breq key_process_return ; ��� �������
    ; ���� �������
    cp key_state, const_2
    breq key_process_ready  ; key_state == 2 - �������� ������� ��������
    ; key_state == 1
    ; ������ ������� ��������
    inc key_state    ; key_state = 2
    ldi XL, LOW(timer0Z)  
    ldi temp1, LOW(key_wait) 
    ldi temp2, HIGH(key_wait)
    rcall _set_timer_proc_
    rjmp key_process_return
key_process_ready:
    ; key_state == 2
    ; �������� ������� ��������
    lds temp1, timer0Z
    cpi temp1, 0
    brne key_process_return
    ; �������� ����� PB1
    in temp2, pinB
    ldi temp3, 0x02
    and temp2, temp3
    lsr temp2
    mov button_state, temp2
.ifdef _DEBUG_
    ; ************ ������ ������� - ������ ***********
    lds temp1, shatter_count
    inc temp1
    cpi temp1, 2
    brne key_process_debug1
    clr temp1
key_process_debug1:
    sts shatter_count, temp1
   ;*********** ������ ������� - ����� ***********
 .endif
    clr key_state   ; key_state = 0
    mov button_event, const_1
    _EN_EXTINT_ temp1, temp2, 0x40  ; 0x40 - ��� ���������� �� INT0
key_process_return:
    ret

    ;==============================================================
    ; �� �������� ������� PW_OK ������������� ������� �������� �� 
    ; (��������� ��������� � ������������ tim_ovo pcint)
    ;==============================================================
pwr_ctrl_process:
    ; �������� �������
    cp pwr_ok_event, const_0                ; � ����� 1 - ��������� ��������� �����
    breq pwr_ctrl_process_return    ; --> pwr_ok_event == 0 - ������� ���, ����������
    ; pwr_ok_event != 0 - ������� ���������
    cp pwr_ok_event, const_2
    breq pwr_ctrl_process_ready  ; pwr_ok_event == 2 - �������� ������� ��������
    ; pwr_ok_event == 1
    ; ������ ������� ��������
    inc pwr_ok_event    ; pwr_ok_event = 2
    ldi XL, LOW(timer0Z)  
    ldi temp1, LOW(key_wait) 
    ldi temp2, HIGH(key_wait)
    rcall _set_timer_proc_
    rjmp pwr_ctrl_process_return
pwr_ctrl_process_ready:
    ; pwr_ok_event == 2
    ; �������� ������� ��������
    lds temp1, timer0Z
    cpi temp1, 0
    brne pwr_ctrl_process_return
    ; �������� ��������� ����� PB2 �������� ������� PW_OK
    in temp2, pinB
    ldi temp3, 0x04
    and temp2, temp3
    lsr temp2
    lsr temp2
    mov pwr_ok_state, temp2
.ifdef _DEBUG_
    ; ************ ������ ������� - ������ ***********
    lds temp1, shatter2_count
    inc temp1
    cpi temp1, 2
    brne pwr_ctrl_process_debug1
    clr temp1
pwr_ctrl_process_debug1:
    sts shatter2_count, temp1
   ;*********** ������ ������� - ����� ***********
 .endif
    clr pwr_ok_event   ; pwr_ok_event = 0
pwr_ctrl_process_return:
    _EN_EXTINT_ temp1, temp2, 0x20  ; 0x20 - ��� ���������� �� PCIE
    ret

    ;=====================================================
    ;           �� ��������� ������ �� 
    ;=====================================================
set_power_error:
    ; �� �� ��������� - ���� ���������
	_OCR0A_On_ temp1, temp2    ; �������� ���� ���� ������������
    ldi XL, LOW(timer01)
    ldi temp1, LOW(err_snd_time) 
    ldi temp2, HIGH(err_snd_time)
    ldi temp3, 1
    rcall _set_timer_proc_
    ret
 
    ;=====================================================
    ;  �� ��������� �������� ����� � �������� ������� 
    ;=====================================================
set_sound_wait_timers:
    ; ������ ������� �����
    ldi XL, LOW(timer01)  
    ldi temp1, LOW(key_snd_time) 
    ldi temp2, HIGH(key_snd_time)
    rcall _set_timer_proc_
    ; ������ ������� �������� ���������/���������� ��
    ldi XL, LOW(timer03)  
    ldi temp1, LOW (time_wait) 
    ldi temp2, HIGH(time_wait)
    rcall _set_timer_proc_
    ret

    ;=====================================================
    ;          ��   ������������� ��������
    ;=====================================================
_set_timer_proc_:
    tst temp3
    brne _set_timer_start
    ;=====================================================
    ;   ������������ ������ ������� �� ������� ������� 
    ;=====================================================
    cli
    st X+, temp3    ; �������� ���� ������� - ������ ������������ ���������� �������
    st X+, temp1    ; ���������������� ��. ���� �������� �������
    st X,  temp2    ; ���������������� ��. ���� �������� �������
    sei
    rjmp _set_timer_return
    ;=====================================================
    ;           ������������ ������ ������� 
    ;        ������ ��� ������������� ������� 
    ;=====================================================
_set_timer_start:
    adiw X, 3
    cli
    st -X, temp2    ; ���������������� ��. ���� �������� ������� 
    st -X, temp1    ; ���������������� ��. ���� �������� ������� 
    st -X, temp3    ; ���������� ���� ������� - ����������� ������ ������� � ������ �����������
    sei
_set_timer_return:
    ret

