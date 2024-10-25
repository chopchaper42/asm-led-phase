@ TST - bitwise AND

.syntax unified @ divided nebo unified

.word 0x20001000
.word _start

.global _start
.type _start, %function

.set RCC_APB2ENR, 0x40021018 @ enable clock for ports

.set GPIOC_CRH, 0x40011004
.set GPIOC_IDR, 0x40011008
.set GPIOC_ODR, 0x4001100C

.set GPIOA_CRL, 0x40010800
.set GPIOA_ODR, 0x4001080C
.set GPIOA_IDR, 0x40010808

.set SHORT_PHASE_LENGTH, 0x54759  @A8EB2  @ 0,1 sec * 3 = 0,3 sec
.set  LONG_PHASE_LENGTH, 0xE1398  @1C2730 @ 0,1 sec * 8 = 0,8 sec
.set DELAY_LENGTH, 0x8CC3F        @11987E       @ 0,1 sec * 5 = 0,5 sec
.set PAUSE_LENGTH, 0x384E60       @709CC0       @ 0,1 sec * 20 = 2 sec

@ R5 - TIMER
@ R6 - PHASE STATE flag - there are two states in each loop 1-2-1-2-1-2
@ R7 - PHASE COUNTER
@ R8 - LOOP COUNTER
@ R9 - SEQUENCE NUMBER
@ R10 - DELAY ARGUMENT for TIMER

_start:
    bl setup_clock
    bl setup_gpio

    mov r5, #0          @ set TIMER to 0
    mov r6, #1          @ set PHASE STATE to 1
    mov r7, #0          @ set PHASE COUNTER to 0
    mov r8, #0          @ set LOOP COUNTER to 0
    mov r9, #0          @ set SEQUENCE NUMBER to 0 (Sequence A)
    bl blue_led_off
    bl green_led_off
    
loop:
    ldr r0, =GPIOA_IDR  @ Read input of port A
    ldr r1, [r0]        @ load the value stored on address from r0 to r1. r1 = 0x40010808
    tst r1, #1          @ Test if 1st pin is HIGH
    beq timer           @ if button isnt pressed, skip debouncing
    
    bl set_defaults     @ set default values for a sequence

    @ change sequence number. If it is 3, set to 0
    teq r9, #4  @ if seq. num == 3
    ite eq
    moveq r9, #0    @ reset the SEQUENCE_COUNTER
    addne r9, #1    @ otherwise, add 1

    @ debounce
debounce:
    ldr r0, =0x8CC3F     @ ~0,5sec
debounce_internal:
    subs r0, #1
    bne debounce_internal
b timer


timer:
    cmp r5, #0          @ compare TIMER with 0
    beq on_timer_zero   @ if TIMER == 0, jump to on_timer_zero

    subs r5, #1          @ else subtract 1 from TIMER
    b loop               @ and jump to loop

@ control PHASE COUNTER, LOOP COUNTER and PHASE STATE
@ choose the sequence
on_timer_zero:

    @ PHASE STATE
    eor r6, #1            @ toggle the PHASE STATE [0 -> 1, 1 -> 0]

    @ LOOP COUNTER
    teq r6, #0              @ check if the PHASE STATE == 0
    bne sequence_switch     @ if not, jump to sequence_switch
                            @ otherwise increment the LOOP COUNTER
    teq r8, #3              @ check if the LOOP COUNTER == 3
    ite eq
    moveq r8, #0            @ reset the LOOP COUNTER
    addne r8, #1            @ increment the LOOP COUNTER
        
phase_counter:
    @ PHASE COUNTER -> LOOP COUNTER

    teq r8, #0            @ check if LOOP COUNTER == 0
    bne sequence_switch   @ if not, go to sequence_switch

    @ LOOP COUNTER has been reset, 
    @ if PHASE COUNTER is overflown, reset it
    teq r7, #2            @ check if the PHASE COUNTER == 3
    itte ne
    addne r7, #1          @ otherwise, add 1 to PHASE COUNTER
    movne r8, #1          @ set LOOP COUNTER to 1
    moveq r7, #0          @ if yes, reset the PHASE COUNTER
    
    @ if PHASE COUNTER has been reset, need to pause
    teq r7, #0               @ check if the PHASE COUNTER == 0
    bne sequence_switch      @ if not, go to sequence_switch
    
    ldr r5, =PAUSE_LENGTH   @ load 2sec to TIMER
    b loop

sequence_switch:
    teq r7, #1      @ check if the PHASE == 1
    ite eq
    ldreq r10, =LONG_PHASE_LENGTH   @ [PHASE == 1 --> load long delay]
    ldrne r10, =SHORT_PHASE_LENGTH  @ [PHASE == 0 or 2 --> load short delay]

    teq r6, #1
    ite eq
    ldreq r5, =DELAY_LENGTH    @ load the delay length to TIMER
    movne r5, r10              @ load delay length to TIMER

    bl green_led_off
    bl blue_led_off

    @ SEQUENCE
    teq r9, #0
    beq sequence_A

    teq r9, #1
    beq sequence_B

    teq r9, #2
    beq sequence_C

    teq r9, #3
    beq sequence_D

sequence_A:
    teq r6, #1      @ check if STATE 1
    beq A_state_B   @ if so, go to state B [DELAY is a constant]

A_state_A:
    bl green_led_off
    bl blue_led_on

b loop

A_state_B:
    bl blue_led_off
    bl green_led_on

b loop

sequence_B:
    teq r6, #1      @ check if STATE 1
    beq B_state_B   @ if so, go to state B [DELAY is a constant]

B_state_A:
    mov r5, r10  @ load delay length to TIMER
    bl green_led_on

b loop

B_state_B:
    ldr r5, =DELAY_LENGTH    @ load the delay length to TIMER
    bl green_led_off

b loop

sequence_C:
    teq r6, #1      @ check if STATE 1
    beq B_state_B   @ if so, go to state B [DELAY is a constant]

C_state_A:
    mov r5, r10  @ load delay length to TIMER
    bl blue_led_on

b loop

C_state_B:
    ldr r5, =DELAY_LENGTH    @ load the delay length to TIMER
    bl blue_led_off

b loop

sequence_D:
    bl blue_led_on
    bl green_led_on

b loop

set_defaults:
    mov r5, #0          @ set TIMER to 0
    mov r6, #1          @ set PHASE STATE to 1
    mov r7, #0          @ set PHASE COUNTER to 0
    mov r8, #0          @ set LOOP COUNTER to 0
bx lr

blue_led_on:
    ldr r0, =GPIOC_ODR @ load GPIOC_ODR address to R0
    ldr r1, [r0]         @ move r0 to r1
    orr r1, #0x100     @ set 8th pin to 1
    str r1, [r0]       @ store R1 to [R0] - GPIOC_ODR

bx lr

green_led_on:
    ldr r0, =GPIOC_ODR @ load GPIOC_ODR address to R0
    ldr r1, [r0]         @ move r0 to r1
    orr r1, #0x200     @ set 9th pin to 1
    str r1, [r0]       @ store R1 to [R0] - GPIOC_ODR

bx lr

blue_led_off:
    ldr r0, =GPIOC_ODR  @ load GPIOC_ODR address to R0
    ldr r1, [r0]
    bic r1, #0x100        @ put 0 to r1
    str r1, [r0]        @ store 0 from r1 to GPIOC_ODR

bx lr

green_led_off:
    ldr r0, =GPIOC_ODR  @ load GPIOC_ODR address to R0
    ldr r1, [r0]
    bic r1, #0x200        @ put 0 to r1
    str r1, [r0]        @ store 0 from r1 to GPIOC_ODR

bx lr

setup_clock:
    ldr r0, =RCC_APB2ENR @ load from rcc_apb2enr to r0
    ldr r1, [r0] @ load value from r0 to r1
    orr r1, #0x1C @ start clock for ports A, B and C
    str r1, [r0]

bx lr   @ skok do link registru


setup_gpio:
    ldr r0, =GPIOC_CRH @ CRH - control register high
    ldr r1, [r0]       @ write value of r0 to r1
    bic r1, #0xFF      @ clear first 8 bits (pins 8 and 9)
    orr r1, #0x11       @ set first 8 bits to 0000 0001 (push-pull OUT 10MHz) PC8
    str r1, [r0]       @ store R1 to GPIOC_CRH

    ldr r0, =GPIOA_CRL   @ load GPIOA_CRL to R0
    ldr r1, [r0]
    bic r1, #0xFF
    orr r1, #0x8         @ set PA0 to INPUT pull down
    str r1, [r0]

bx lr