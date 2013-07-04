M65C02 Microprocessor Core
=======================

Copyright (C) 2013, Michael A. Morris <morrisma@mchsi.com>.
All Rights Reserved.

Released under LGPL.

General Description
-------------------

This project demonstrates the use of a PIC16C5x-compatible core as an FPGA-
based processor. The core provided is instruction set compatible, but it is 
not a cycle accurate model of a particular PIC microcomputer. It implements 
the 12-bit instruction set, the timer 0 module, the pre-scaler, and the watchdog 
timer.

As configured the core supports 2 cycle operation with internal block RAM 
serving as program memory. In addition to the block RAM program store, a 4x 
clock generator and reset controller is included as part of the in the 
demonstration. 

Three I/O ports are supported, but they are accessed as external registers and 
buffers using a bidirectional data bus. The TRIS I/O control registers are 
similarly supported. Thus, the core's user is able to map the TRIS and I/O 
port registers in a manner appropriate to the intended application.

Read-modify-operations on the I/O ports do not generate read strobes. Read 
strobes of the three I/O ports are generated only if the ports are being read. 
Similarly, the write enables for the three I/O ports are asserted whenever the 
ports are updated. This occurs during MOVWF instructions, or during read-
modify-write operations such as XORF, MOVF, etc.

Implementation
--------------

The implementation of the core provided consists of several Verilog source files 
and memory initialization files:

    M16C5x.v                - Top level module
        M16C5x_ClkGen.v     - M16C5x Clock/Reset Generator
        P16C5x.v            - PIC16C5x-compatible processor core
            P16C5x_IDEC.v   - ROM-based instruction decoder for PIC16C5x core
            P16C5x_ALU.v    - Arithmetic & Logic Unit for PIC16C5x core
        M16C5x_SPI.v        - High-Speed, FIFO-buffered SPI Master Interface
            DPSFmnCE.v      - Configurable Depth/Width LUT-based Synch FIFO
                TF_Init.coe - Transmit FIFO Initialization file
                RF_Init.coe - Receive FIFO Initialization file
            SPIxIF.v        - Configurable Master SPI I/F with clock Generator

        M16C5x_Test.coe     - M16C5x Test Program Memory Initialization File

        M16C5x.ucf          - M16C5x User Constraint File

Verilog tesbench files are included for the processor core, the FIFO, and the 
SPI modules.

    tb_P16C5x.v             - testbench for the processor core module
    tb_DPSFmnCE.v           - testbench for the LUT-based FIFO module
    tb_SPIxIF.v             - testbench for the SPI Master Interface module
    
Also provided is the MPLAB project and the source files used to create the 
memory initialization files for testing the microcomputer application. These 
files are found in the MPLAB subdirectory of the Code directory.

Finally, the configuration of the Xilinx tools used to synthesize, map, place, 
and route are captured in the the TCL file:

        M16C5x.tcl

Synthesis
---------

The primary objective of the M16C5x is to synthesize a processor core, 4kW of 
program memory, a buffered SPI master, and a buffered UART into a Xilinx 
XC3S50A-4VQG100I FPGA. The present implementation includes the P16C5x core, 
4kW of program memory, a dual-channel SPI Master I/F, and some registers to 
act as placeholders for the UART. (The complete UART module will be added soon.)

Using ISE 10.1i SP3, the implementation results for an XC3S50A-4VQ100I are as 
follows:

    Number of Slice FFs:            343 of 1408      24%
    Number of 4-input LUTs:         671 of 1408      47%
    Number of Occupied Slices:      445 of  704      63%
    Total Number of 4-input LUTs:   717 of 1408      50%

                    Logic:          596
                    Route-Through:   46
                    16x1 RAMs:        8
                    Dual-Port RAMs:  34
                    32x1 RAMs:       32
                    Shift Registers:  1

    Number of BUFGMUXs:             3   of 24        12%
    Number of DCMs:                 1   of  2        50%
    Number of RAMB16BWEs            3   of  3       100%

    Best Case Achievable:           12.389 ns (0.111 ns Setup, 0.704 ns Hold)

Status
------

Design and initial verification is complete.

Release Notes
-------------

###Release 1.0

In this release, the M16C5x has been synthesized, mapped, placed, routed, and 
used to configure an FPGA. The FPGA used for this initial test of the M16C5x 
was the XC3S200A-4VQG100I FPGA. The test program provided demonstrated that 
the M16C5x was executing the program in the same manner as simulated with the 
MPLAB simulator.

Using an external 14.7456 MHz oscillator, selected for use for use with the 
UART, square waves were generated by the core to illuminate external LEDs 
using the upper 6 bits of PortA. The square waves have the appropriate ratios, 
and the frequency of the fastest LED drive signal is ~4.753kHz.

The clock generator multiplies the input frequency to 58.9824 MHz which 
results in an effective instruction frequency of 29.4912 MHz because of the 
two cycle nature of the core. The instruction loop is essentially 8*(*+3*256), 
which equals 6208 cycles per LED toggle. The measured toggle frequency of the 
fastest LED is approximately equal to 29.4912 MHz / 6208, or 4.750 kHz.

Work will continue to verify the testbench results with the FPGA. The next 
release should include the UART, and test the ability of the core to 
send/receive data using the FIFOs at rates of 115,200 baud or greater.
