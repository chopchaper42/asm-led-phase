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

.set SHORT, 10
.set LONG, 20

_start: @ jako main v c
    bl setup_clock  @ bl - branch and link
    bl setup_gpio
    
    mov r2, 0          @ counter
loop:
    ldr r0, =GPIOA_IDR  @ Read input of port A
    ldr r1, [r0]        @ load the value stored on address from r0 to r1. r1 = 0x40010808
    tst r1, #0x1        @ Test if 1st pin is HIGH
    
    @ if button isn't pressed, goto loop1
    
    beq loop1          

    @ if button is pressed:
    
    teq r2, #3              @ if r2 equals 3
    beq reset_counter       @ if Z = 0 (r2 != 3)
    bne increase_counter    @ reset counter

loop1:
    teq r2, #0
    beq sequence_A

    teq r2, #1
    beq sequence_B

    teq r2, #2
    beq sequence_C

    teq r2, #3
    beq sequence_D

    mov r0, #30
    bl delay
    
b loop

reset_counter:
    mov r2, 0
bx lr

increase_counter:
    add r2, #1
bx lr

sequence_A:
    
    mov r3, #3       @ 3 times

@ short
short_1A:
    
    @ Blue SOS
    bl blue_led_on
    bl green_led_off
    mov r0, SHORT
    bl delay

    @ Green SOS
    bl blue_led_off
    bl green_led_on
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne short_1A

    mov r3, #3
long_A:
    bl blue_led_on
    bl green_led_off
    mov r0, LONG
    bl delay

    bl blue_led_off
    bl green_led_on
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne long_A

    mov r3, #3
short_2A:

    @ Blue SOS
    bl blue_led_on
    bl green_led_off
    mov r0, SHORT
    bl delay

    @ Green SOS
    bl blue_led_off
    bl green_led_on
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne short_2A

    bl green_led_off
    bl blue_led_off

    mov r0, LONG
    bl delay

b loop

sequence_B:
    bl blue_led_off

    mov r3, #3       @ 3 times

@ short
short_1B:
    
    bl green_led_on
    mov r0, SHORT
    bl delay

    bl green_led_off
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne short_1B

    mov r3, #3      @ 3 times
long_B:
    bl green_led_on
    mov r0, LONG
    bl delay

    bl green_led_off
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne long_B

    mov r3, #3
short_2B:

    bl green_led_on
    mov r0, SHORT
    bl delay

    @ Green SOS
    bl green_led_off
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne short_2B

    mov r0, LONG
    bl delay

b loop

sequence_C:
    bl blue_led_off

    mov r3, #3       @ 3 times

@ short
short_1C:
    
    bl blue_led_on
    mov r0, SHORT
    bl delay

    bl blue_led_off
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne short_1C

    mov r3, #3      @ 3 times
long_C:
    bl blue_led_on
    mov r0, LONG
    bl delay

    bl blue_led_off
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne long_C

    mov r3, #3
short_2C:

    bl blue_led_on
    mov r0, SHORT
    bl delay

    @ Green SOS
    bl blue_led_off
    mov r0, SHORT
    bl delay

    subs r3, #1
    bne short_2C

    mov r0, LONG
    bl delay

b loop

sequence_D:
    bl blue_led_on
    bl green_led_on

b loop

blue_led_on:
    ldr r0, =GPIOC_ODR @ load GPIOC_ODR address to R0
    ldr r1, [r0]         @ move r0 to r1
    orr r1, #0x100     @ set 8th pin to 1
    str r1, [r0]       @ store R1 to [R0] - GPIOC_ODR

bx lr

blue_led_off:
    ldr r0, =GPIOC_ODR  @ load GPIOC_ODR address to R0
    ldr r1, [r0]
    bic r1, #0x100        @ put 0 to r1
    str r1, [r0]        @ store 0 from r1 to GPIOC_ODR

bx lr

green_led_on:
    ldr r0, =GPIOC_ODR @ load GPIOC_ODR address to R0
    ldr r1, [r0]         @ move r0 to r1
    orr r1, #0x200     @ set 8th pin to 1
    str r1, [r0]       @ store R1 to [R0] - GPIOC_ODR

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

delay:
    ldr r1, =0x1F000
delay_second:
    subs r1, #1
    bne delay_second
    subs r0, #1
    bne delay
bx lr
