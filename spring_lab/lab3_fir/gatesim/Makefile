sim:
	vcs -R +v2k -full64 tb.v ../hdl/fir.v -debug_acc +notimingcheck +define+FSDB
	
gatesim:
	vcs -R +v2k -full64 tb.v ../syn/netlist/fir_syn.v -v /usr/cadtool/ee5216/CBDK_TSMC90GUTM_Arm_f1.0/CIC/Verilog/tsmc090.v +define+SDF -debug_acc +neg_tchk 
