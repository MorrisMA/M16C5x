M16C5x Microprocessor Core
=======================

Copyright (C) 2013, Michael A. Morris <morrisma@mchsi.com>.
All Rights Reserved.

Released under various licenses including LGPL. Files marked by double 
asterisks (**) are released in source form for non-commercial use only; 
commercial licensing available.

General Description
-------------------

This project demonstrates the use of a PIC16C5x-compatible core as an FPGA-
based processor. The core provided is instruction set compatible, but it is 
not a cycle accurate model of any particular PIC microcomputer. It implements 
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
strobes of the three I/O ports are generated only if the ports are being read 
using MOVF xxx,0 instructions. Similarly, the write enables for the three I/O 
ports are asserted whenever the ports are updated. This occurs during MOVWF 
instructions, or during read- modify-write operations such as XORF, MOVF, etc.

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
        **M16C5x_UART.v**    - UART with Serial Interface
            **SSPx_Slv.v**   - SSP-compatible Slave Interface
            **SSP_UART.v**   - SSP-compatible UART
                re1ce.v     - Rising Edge Clock Domain Crossing Synchronizer
                DPSFmnCE.v  - onfigurable Depth/Width LUT-based Synch FIFO
                    UART_TF.coe - UART Transmit FIFO Initialization file
                    UART_RF.coe - UART Receive FIFO Initialization file
                **UART_BRG.v**    - UART Baud Rate Generator
                **UART_TXSM.v**   - UART Transmit State Machine (includes SR)
                **UART_RXSM.v**   - UART Receive State Machine (includes SR)
                **UART_RTO.v**    - UART Receive Timeout Generator
                **UART_INT.v**    - UART Interrupt Generator

        M16C5x_Test.coe     - M16C5x Test Program Memory Initialization File
        M16C5x_Tst2.coe     - M16C5x Test #2 Program Memory Initialization File
        M16C5x_Tst3.coe     - M16C5x Test #3 Program Memory Initialization File

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
4kW of program memory, a dual-channel SPI Master I/F, and an SSP-compatible 
UART supporting baud rates from 3M bps to 1200 bps.

Using ISE 10.1i SP3, the implementation results for an XC3S50A-4VQ100I are as 
follows:

    Number of Slice FFs:                595 of 1408      42%
    Number of 4-input LUTs:            1277 of 1408      90%
    Number of Occupied Slices:          695 of  704      98%
    Total Number of 4-input LUTs:      1325 of 1408      94%

                    Logic:             1042
                    Route-Through:       48
                    16x1 RAMs:            8
                    Dual-Port RAMs:     194
                    32x1 RAMs:           32
                    Shift Registers:      1

    Number of BUFGMUXs:                   5 of   24      20%
    Number of DCMs:                       1 of    2      50%
    Number of RAMB16BWEs                  3 of    3     100%

    Best Case Achievable:           12.438 ns (0.062 ns Setup, 0.650 ns Hold)

Status
------

Design and initial verification is complete. Verification using ISim, MPLAB, 
and a board with an XC3S200AN-4VQG100I FPGA, various oscillators, SEEPROMs, 
and RS-232/RS-485 transceivers is underway.

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

###Release 2.0

In this release, the UART has been addded. An update has been made to the SPI 
I/F Master function; update correct fault with the framing of SPI Mode 3 
frames with shift lengths greater than 1 byte. A correction, not fully tested 
or verified, was made to the P16C5x core to correct anomalous behavior for 
BTFSC/BTFSS instructions.

UART integrated with the Release 1.0 core. Verification of the integrated 
interface is underway. UART is used in a commercial product, and is provided 
in source form for non-commercial use only.