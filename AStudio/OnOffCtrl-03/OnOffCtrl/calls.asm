/*
 * calls.asm
 *
 *  Created: 30.10.2019 17:00:56
 *   Author: vp
 */ 
.CSEG              

    ;=====================================================
    ;           ПП обработки нажатия кнопки 
    ; (состояние и дребезг совместно с обработчиком int0)
    ;=====================================================
key_process:
    cp key_state, const_0
    breq key_process_return ; нет события
    ; есть событие
    cp key_state, const_2
    breq key_process_ready  ; key_state == 2 - проверка таймера дребезга
    ; key_state == 1
    ; запуск таймера дребезга
    inc key_state    ; key_state = 2
    ldi XL, LOW(timer0Z)  
    ldi temp1, LOW(key_wait) 
    ldi temp2, HIGH(key_wait)
    rcall _set_timer_proc_
    rjmp key_process_return
key_process_ready:
    ; key_state == 2
    ; проверка таймера дребезга
    lds temp1, timer0Z
    cpi temp1, 0
    brne key_process_return
    ; проверка порта PB1
    in temp2, pinB
    ldi temp3, 0x02
    and temp2, temp3
    lsr temp2
    mov button_state, temp2
.ifdef _DEBUG_
    ; ************ секция отладки - начало ***********
    lds temp1, shatter_count
    inc temp1
    cpi temp1, 2
    brne key_process_debug1
    clr temp1
key_process_debug1:
    sts shatter_count, temp1
   ;*********** секция отладки - конец ***********
 .endif
    clr key_state   ; key_state = 0
    mov button_event, const_1
    _EN_EXTINT_ temp1, temp2, 0x40  ; 0x40 - бит прерывания от INT0
key_process_return:
    ret

    ;==============================================================
    ; ПП контроля сигнала PW_OK определяющего рабочее состоние БП 
    ; (состояние совместно с обработчиком tim_ovo pcint)
    ;==============================================================
pwr_ctrl_process:
    ; проверка события
    cp pwr_ok_event, const_0                ; в общем 1 - изменение состояния входа
    breq pwr_ctrl_process_return    ; --> pwr_ok_event == 0 - события нет, завершение
    ; pwr_ok_event != 0 - событие произошло
    cp pwr_ok_event, const_2
    breq pwr_ctrl_process_ready  ; pwr_ok_event == 2 - проверка таймера дребезга
    ; pwr_ok_event == 1
    ; запуск таймера дребезга
    inc pwr_ok_event    ; pwr_ok_event = 2
    ldi XL, LOW(timer0Z)  
    ldi temp1, LOW(key_wait) 
    ldi temp2, HIGH(key_wait)
    rcall _set_timer_proc_
    rjmp pwr_ctrl_process_return
pwr_ctrl_process_ready:
    ; pwr_ok_event == 2
    ; проверка таймера дребезга
    lds temp1, timer0Z
    cpi temp1, 0
    brne pwr_ctrl_process_return
    ; проверка состояния входа PB2 контроля сигнала PW_OK
    in temp2, pinB
    ldi temp3, 0x04
    and temp2, temp3
    lsr temp2
    lsr temp2
    mov pwr_ok_state, temp2
.ifdef _DEBUG_
    ; ************ секция отладки - начало ***********
    lds temp1, shatter2_count
    inc temp1
    cpi temp1, 2
    brne pwr_ctrl_process_debug1
    clr temp1
pwr_ctrl_process_debug1:
    sts shatter2_count, temp1
   ;*********** секция отладки - конец ***********
 .endif
    clr pwr_ok_event   ; pwr_ok_event = 0
pwr_ctrl_process_return:
    _EN_EXTINT_ temp1, temp2, 0x20  ; 0x20 - бит прерывания от PCIE
    ret

    ;=====================================================
    ;           ПП включение ошибки БП 
    ;=====================================================
set_power_error:
    ; БП не включился - сбой включения
	_OCR0A_On_ temp1, temp2    ; включить звук сбоя оборудования
    ldi XL, LOW(timer01)
    ldi temp1, LOW(err_snd_time) 
    ldi temp2, HIGH(err_snd_time)
    ldi temp3, 1
    rcall _set_timer_proc_
    ret
 
    ;=====================================================
    ;  ПП включение таймеров звука и ожидания события 
    ;=====================================================
set_sound_wait_timers:
    ; запуск таймера звука
    ldi XL, LOW(timer01)  
    ldi temp1, LOW(key_snd_time) 
    ldi temp2, HIGH(key_snd_time)
    rcall _set_timer_proc_
    ; запуск таймера ожидания включения/отключения БП
    ldi XL, LOW(timer03)  
    ldi temp1, LOW (time_wait) 
    ldi temp2, HIGH(time_wait)
    rcall _set_timer_proc_
    ret

    ;=====================================================
    ;          ПП   инициализации таймеров
    ;=====================================================
_set_timer_proc_:
    tst temp3
    brne _set_timer_start
    ;=====================================================
    ;   иницирование нового таймера со сбросом старого 
    ;=====================================================
    cli
    st X+, temp3    ; обнулить флаг таймера - запрет немедленного выполнения таймера
    st X+, temp1    ; инициализировать мл. байт значения таймера
    st X,  temp2    ; инициализировать ст. байт значения таймера
    sei
    rjmp _set_timer_return
    ;=====================================================
    ;           иницирование нового таймера 
    ;        вместо уже отработавшего старого 
    ;=====================================================
_set_timer_start:
    adiw X, 3
    cli
    st -X, temp2    ; инициализировать ст. байт значения таймера 
    st -X, temp1    ; инициализировать мл. байт значения таймера 
    st -X, temp3    ; установить флаг таймера - немедленный запуск таймера с новыми параметрами
    sei
_set_timer_return:
    ret

