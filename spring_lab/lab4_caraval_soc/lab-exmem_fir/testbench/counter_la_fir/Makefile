CC=riscv32-unknown-elf-gcc
OBJCOPY=riscv32-unknown-elf-objcopy
OBJDUMP=riscv32-unknown-elf-objdump

CFLAGS=-I ../../firmware
SOURCE=counter_la_fir.c fir.c

all: counter_la_fir.elf counter_la_fir.hex counter_la_fir.out

counter_la_fir.elf: $(SOURCE)
	$(CC) $(CFLAGS) -o $@ $^

counter_la_fir.hex: counter_la_fir.elf
	$(OBJCOPY) -O verilog $< $@

counter_la_fir.out: counter_la_fir.elf
	$(OBJDUMP) -D $< > $@

clean:
	rm -f counter_la_fir.elf counter_la_fir.hex counter_la_fir.out
