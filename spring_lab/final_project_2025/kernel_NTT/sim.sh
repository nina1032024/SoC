#!/bin/bash


rm -rf csrc simv* NTT.fsdb DVEfiles

vcs test_kernel_NTT.v kernel_top.v kernel_NTT.v kernel_FFT.v bram512x128.v bram128x128.v bram32x128.v butterfly.v -full64 -R -debug_access+all +v2k +neg_tchk
    

#!/bin/bash

