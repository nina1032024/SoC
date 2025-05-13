#!/bin/bash

SOURCE=("counter_la_fir.c"
        "fir.c")

riscv32-unknown-elf-gcc -I ../../firmware -o counter_la_fir.elf "${SOURCE[@]}"
riscv32-unknown-elf-objcopy -O verilog counter_la_fir.elf counter_la_fir.hex
riscv32-unknown-elf-objdump -D counter_la_fir.elf > counter_la_fir.out



