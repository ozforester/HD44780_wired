
# Copyright (c) 2021 ozforester. All rights reserved.
# Use of this source code is goverened by a MIT license
# that can be found in the LICENSE file.

TARGET	 = HD44780_wired
SOURCES := $(wildcard *.c)
OBJECTS  = $(SOURCES:.S=.o)

all:
	avr-gcc -c -Wall -Os -mmcu=atmega8 -o ${TARGET}.o ${TARGET}.S
	avr-gcc -Wall -Os -mmcu=atmega8 -o ${TARGET} ${TARGET}.o
	avr-objcopy -O ihex ${TARGET} ${TARGET}.hex
	avr-size ${TARGET}
	avr-size ${TARGET}.hex

flash:
	avrdude -c usbasp -p m8 -B 3 -U flash:w:${TARGET}.hex

clean:
	rm -f $(OBJECTS) $(TARGET) $(TARGET).hex
