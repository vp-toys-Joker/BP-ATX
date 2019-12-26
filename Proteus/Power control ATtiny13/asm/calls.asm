/*
 * calls.asm
 *
 *  Created: 30.10.2019 17:00:56
 *   Author: vp
 */ 
.CSEG              

    ;=====================================================
    ;          ПП   инициализации таймеров
    ;=====================================================
_set_timer_proc_:
    tst r18
    brne _set_timer_start
    ;=====================================================
    ;   иницирование нового таймера со сбросом старого 
    ;=====================================================
    cli
    st X+, r18    ; обнулить флаг таймера - запрет немедленного выполнения таймера
    st X+, r16    ; инициализировать мл. байт значения таймера
    st X,  r17    ; инициализировать ст. байт значения таймера
    sei
    rjmp _set_timer_return
    ;=====================================================
    ;           иницирование нового таймера 
    ;        вместо уже отработавшего старого 
    ;=====================================================
_set_timer_start:
    adiw X, 3
    cli
    st -X, r17    ; инициализировать ст. байт значения таймера 
    st -X, r16    ; инициализировать мл. байт значения таймера 
    st -X, r18    ; установить флаг таймера - немедленный запуск таймера с новыми параметрами
    sei
_set_timer_return:
    ret

    ;=====================================================
    ;           ПП обработки нажатия кнопки 
    ; (состояние и дребезг совместно с обработчиком int0)
    ;=====================================================
key_process:
    lds r16, key_state
    cpi r16, 0
    breq key_process_return ; нет события
    ; есть событие
    cpi r16, 2
    breq key_process_ready  ; key_state == 2 - проверка таймера дребезга
    ; key_state == 1
    ; запуск таймера дребезга
    inc r16
    sts key_state, r16  ; key_state = 2
    ldi XL, LOW(timer0Z)  
    ldi r16, LOW(key_wait) 
    ldi r17, HIGH(key_wait)
    rcall _set_timer_proc_
    rjmp key_process_return
key_process_ready:
    ; key_state == 2
    ; проверка таймера дребезга
    lds r16, timer0Z
    cpi r16, 0
    brne key_process_return
    ; проверка порта PB1
    in r17, pinB
    ldi r18, 0x02
    and r17, r18
    lsr r17
    sts button, r17
.ifdef _DEBUG_
    ; ************ секция отладки - начало ***********
    lds r16, shatter_count
    inc r16
    cpi r16, 2
    brne key_process_debug1
    clr r16
key_process_debug1:
    sts shatter_count, r16
   ;*********** секция отладки - конец ***********
 .endif
    clr r16
    sts key_state, r16   ; key_state = 0
    _EN_EXTINT_ r16, r17, 0x40  ; 0x40 - бит прерывания от INT0
key_process_return:
    ret

    ;==============================================================
    ; ПП контроля сигнала PW_OK определяющего рабочее состоние БП 
    ; (состояние совместно с обработчиком tim_ovo pcint)
    ;==============================================================
pwr_ctrl_process:
    lds r16, pwr_volatile   ; проверка события
    cpi r16, 0                ; в общем 1 - изменение состояния входа
    breq pwr_ctrl_process_return    ; --> pwr_volatile == 0 - события нет, завершение
    ; pwr_volatile != 0 - событие произошло
    cpi r16, 2
    breq pwr_ctrl_process_ready  ; pwr_volatile == 2 - проверка таймера дребезга
    ; pwr_volatile == 1
    ; запуск таймера дребезга
    inc r16
    sts pwr_volatile, r16  ; pwr_volatile = 2
    ldi XL, LOW(timer0Z)  
    ldi r16, LOW(key_wait) 
    ldi r17, HIGH(key_wait)
    rcall _set_timer_proc_
    rjmp pwr_ctrl_process_return
pwr_ctrl_process_ready:
    ; pwr_volatile == 2
    ; проверка таймера дребезга
    lds r16, timer0Z
    cpi r16, 0
    brne pwr_ctrl_process_return
    ; проверка состояния входа PB2 контроля сигнала PW_OK
    in r17, pinB
    ldi r18, 0x04
    and r17, r18
    lsr r17
    lsr r17
    sts pwr_state, r17
.ifdef _DEBUG_
    ; ************ секция отладки - начало ***********
    lds r16, shatter2_count
    inc r16
    cpi r16, 2
    brne pwr_ctrl_process_debug1
    clr r16
pwr_ctrl_process_debug1:
    sts shatter2_count, r16
   ;*********** секция отладки - конец ***********
 .endif
    clr r16
    sts pwr_volatile, r16   ; pwr_volatile = 0
pwr_ctrl_process_return:
    _EN_EXTINT_ r16, r17, 0x20  ; 0x20 - бит прерывания от PCIE
    ret

    ;=====================================================
    ;           ПП включение ошибки БП 
    ;=====================================================
set_power_error:
    ; БП не включился - сбой включения
	_OCR0A_On_ r16, r17    ; включить звук сбоя оборудования
    ldi XL, LOW(timer01)
    ldi r16, LOW(err_snd_time) 
    ldi r17, HIGH(err_snd_time)
    ldi r18, 1
    rcall _set_timer_proc_
    ; установка режима 0 состояния 0
    clr r16
    sts mode, r16   ; установить режим 0 состояния 0
    sts state, r16  ; установить состояние 0
    ret
 
    ;=====================================================
    ;  ПП включение таймеров звука и ожидания события 
    ;=====================================================
set_sound_wait_timers:
    ; запуск таймера звука
    ldi XL, LOW(timer01)  
    ldi r16, LOW(key_snd_time) 
    ldi r17, HIGH(key_snd_time)
    rcall _set_timer_proc_
    ; запуск таймера ожидания включения/отключения БП
    ldi XL, LOW(timer03)  
    ldi r16, LOW (time_wait) 
    ldi r17, HIGH(time_wait)
    rcall _set_timer_proc_
    ret
