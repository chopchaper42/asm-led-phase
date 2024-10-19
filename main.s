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

@ R5 - TIMER
@ R6 - PHASE flag
@ R7 - BUTTON_PRESSED

_start: @ jako main v c
    bl setup_clock
    bl setup_gpio
    mov r6, #0           @ set LEDS_ON flag to zero
    mov r5, #0           @ set TIMER to 0
    mov r7, #0           @ set BUTTON_PRESSED to 0
    bl turn_leds_off    @ turn leds off
    
loop:
    ldr r0, =GPIOA_IDR  @ Read input of port A
    ldr r1, [r0]        @ load the value stored on address from r0 to r1. r1 = 0x40010808
    tst r1, #1          @ Test if 1st pin is HIGH

    ittee ne            @ if the button is pressed
    movne r5, #0        @ reset the timer to go straight to on_timer_zero
    movne r7, #1        @ set the BUTTON_PRESSED flag
    moveq r7, #0        @ else clear the BUTTON_PRESSED flag and
    beq timer           @ go straight to timer (no need to debounce)

debounce:
    ldr r0, =0x384E6     @ ~0,1sec
debounce_internal:
    subs r0, #1
    bne debounce_internal

timer:
    cmp r5, #0          @ compare TIMER with 0
    beq on_timer_zero   @ if TIMER == 0, jump to on_timer_zero

    subs r5, #1          @ else subtract 1 from TIMER
    b loop               @ and jump to loop

on_timer_zero:
    ldr r5, =0x8CC3F   @ set TIMER for ~0,5 sec
    eor r6, #1          @ toggle the PHASE flag

    cmp r7, #0          @ check if the BUTTON_PRESSED flag is 0
    beq out_of_phase    @ if button isn't pressed, goto out_of_phase

    @ otherwise in phase
    cmp r6, #0          @ check if PHASE flag is zero
    beq turn_on         @ if it is zero, turn the leds on
    bl blue_led_off    @ otherwise turn leds off
    bl green_led_off

b loop

turn_on:
    bl blue_led_on
    bl green_led_on

b loop

out_of_phase:
    bl turn_leds_off
    
    cmp r6, #0      @ check the PHASE flag
    beq green_phase @ turn on the green
    bl blue_led_on
    bl green_led_off

b loop

green_phase:
    bl blue_led_off
    bl green_led_on

b loop

turn_leds_off:
    ldr r0, =GPIOC_ODR   @ load GPIOC_ODR address to R0
    ldr r1, [r0]         @ move r0 to r1
    bic r1, #0x300       @ set 8th pin to 1
    str r1, [r0]         @ store R1 to [R0] - GPIOC_ODR

bx lr

turn_leds_on:
    ldr r0, =GPIOC_ODR @ load GPIOC_ODR address to R0
    ldr r1, [r0]         @ move r0 to r1
    orr r1, #0x300     @ set 8th pin to 1
    str r1, [r0]       @ store R1 to [R0] - GPIOC_ODR

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

toggle_green:
    ldr r0, =GPIOC_ODR @ load GPIOC_ODR address to R0
    ldr r1, [r0]         @ move r0 to r1
    eor r1, #0x200     @ set 9th pin to 1
    str r1, [r0]       @ store R1 to [R0] - GPIOC_ODR

bx lr

@ make sure that leds have different state if you want them to be out of phase
toggle_leds:
    ldr r0, =GPIOC_ODR @ load GPIOC_ODR address to R0
    ldr r1, [r0]         @ move r0 to r1
    eor r1, #0x300     @ toggle 8th and 9th pins
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

check_btn:
