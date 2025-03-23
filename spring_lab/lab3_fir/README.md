## Lab3 FIR
### Overview
This `FIR` module is implemented with an `AXI4-Lite` interface for configuration and `AXI4-Stream` interfaces for input and output data transfer. The design includes a main `FSM` for overall FIR operation control, a `core engine` for computation, and a `BRAM signal processor` for managing coefficient addressing and data storage.

![alt text](image.png)
### Hackmd report
For more details, refer to :
[Lab3--FIR Report](https://hackmd.io/9N8llY-tTKGlezyOHlR_Jg)

### File description
hdl:
    fir.v                   // main design

py :
    fir.py                  // generate golden datasets
    .dat                    // golden datasets 

rtlsim : 
    tb.v                    // TA's testbench (test multiple testcase, random delay, invalid write)
    my_tb                   // My testbench (test random delay, invalid write)
    bram32.v                // 32 * 32 bram for storing data and taps
    Makefile                // Automates the compilation, simulation, and cleanup process
    run.f                   // List of Verilog source files
    lab3_sim_autocheck.log  // Generated autocheck results

syn :
    netlist                 // Generated netlist 
    report                  // timing, area report 
    
gatesim:
    lab3_gatesim.log        // Results after syn