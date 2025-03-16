## Lab3 FIR
### Description
This FIR module implements a Finite Impulse Response (FIR) filter with an AXI4-Lite interface for configuration and AXI4-Stream interfaces for data input and output. It includes tap and data RAM for coefficient and input storage, controlled by an FSM with three states: IDLE, CALC, and DONE. The module processes input data streams, applies FIR filtering, and outputs the filtered results. Configuration registers allow users to set parameters such as data length and tap count, while efficient address generation and control logic manage data flow and computation.

![alt text](image.png)
### Hackmd report
https://hackmd.io/9N8llY-tTKGlezyOHlR_Jg