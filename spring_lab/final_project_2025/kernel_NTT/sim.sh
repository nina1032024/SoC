#!/bin/bash

OUT=sim.out

VCD_FILE=wave.vcd

iverilog -o $OUT \
  test_kernel_NTT.v \
  divN.v \
  kernel_top.v \
  kernel_NTT.v \
  kernel_FFT.v \
  bram512x128.v \
  bram128x128.v \
  bram32x128.v \
  butterfly.v

vvp $OUT

gtkwave $VCD_FILE
