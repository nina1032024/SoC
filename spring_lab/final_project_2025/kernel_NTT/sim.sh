#!/bin/bash

# 清除舊資料
rm -rf csrc simv* NTT.fsdb DVEfiles

# 編譯
vcs divN.v test_kernel_NTT.v kernel_top.v kernel_NTT.v kernel_FFT.v bram512x128.v bram128x128.v bram32x128.v butterfly.v -full64 -R -debug_access+all +v2k +neg_tchk
    

# 如果要產生波形建議在 testbench 加入
# `if ($test$plusargs("FSDB")) $fsdbDumpfile("verdi.fsdb");`
# `if ($test$plusargs("FSDB")) $fsdbDumpvars(0, tb_kernel_NTT);`


#!/bin/bash

