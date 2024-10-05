program: main.s
	arm-none-eabi-as -mthumb main.s -o main.o
	arm-none-eabi-ld -Ttext 0x08000000 main.o -o main.elf
	arm-none-eabi-objcopy  -O binary main.elf main.bin
	arm-none-eabi-size main.elf
	st-info --probe
	st-flash write main.bin 0x08000000