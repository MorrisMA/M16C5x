M16C5x Soft-Core Microcomputer
=======================

Copyright (C) 2013, Michael A. Morris <morrisma@mchsi.com>.
All Rights Reserved.

Released under LGPL.

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
        M16C5x_UART.v       - UART with Serial Interface
            SSPx_Slv.v      - SSP-compatible Slave Interface
            SSP_UART.v      - SSP-compatible UART
                re1ce.v     - Rising Edge Clock Domain Crossing Synchronizer
                DPSFmnCE.v  - onfigurable Depth/Width LUT-based Synch FIFO
                    UART_TF.coe - UART Transmit FIFO Initialization file
                    UART_RF.coe - UART Receive FIFO Initialization file
                UART_BRG.v  - UART Baud Rate Generator
                UART_TXSM.v - UART Transmit State Machine (includes SR)
                UART_RXSM.v - UART Receive State Machine (includes SR)
                UART_RTO.v  - UART Receive Timeout Generator
                UART_INT.v  - UART Interrupt Generator

        M16C5x_Test.coe     - M16C5x Test Program Memory Initialization File
        M16C5x_Tst2.coe     - M16C5x Test #2 Program Memory Initialization File
        M16C5x_Tst3.coe     - M16C5x Test #3 Program Memory Initialization File

        M16C5x.ucf          - M16C5x User Constraint File
        M16C5x.bmm          - M16C5x Block RAM Memory Map File

Verilog tesbench files are included for the processor core, the FIFO, and the 
SPI modules.

    tb_M16C5x.v             - testbench for the soft-core processor module
    tb_P16C5x.v             - testbench for the processor core module
    tb_DPSFmnCE.v           - testbench for the LUT-based FIFO module
    tb_SPIxIF.v             - testbench for the SPI Master Interface module
    
Also provided is the MPLAB project and the source files used to create the 
memory initialization files for testing the microcomputer application. These 
files are found in the MPLAB subdirectory of the Code directory.

Finally, the configuration of the Xilinx tools used to synthesize, map, place, 
and route are captured in the the TCL file:

        M16C5x.tcl          - TCL file for XC3S200A-4VQG100I FPGA
        M16C5x_3S50A.tcl    - TCL file for XC3S50A-4VQG100I FPGA
        
Added utility program to convert MPLAB Intel Hex programming files into MEM 
files for use with Xilinx Data2MEM utility program to speed the process of 
incorporating program/data/parameter data into block RAMs. TCL also 
incorporates the process parameter changes to get the BMM file processed by 
Map/PAR/Bitgen.

Synthesis
---------

The primary objective of the M16C5x is to synthesize a processor core, 4kW of 
program memory, a buffered SPI master, and a buffered UART into a Xilinx 
XC3S50A-4VQG100I FPGA. The present implementation includes the P16C5x core, 
4kW of program memory, a dual-channel SPI Master I/F, and an SSP-compatible 
UART supporting baud rates from 3M bps to 1200 bps.

Using ISE 10.1i SP3, the implementation results for an XC3S50A-4VQ100I are as 
follows:

    Number of Slice FFs:                613 of 1408      43%
    Number of 4-input LUTs:            1297 of 1408      92%
    Number of Occupied Slices:          699 of  704      99%
    Total Number of 4-input LUTs:      1344 of 1408      95%

                    Logic:             1062
                    Route-Through:       47
                    16x1 RAMs:            8
                    Dual-Port RAMs:     194
                    32x1 RAMs:           32
                    Shift Registers:      1

    Number of BUFGMUXs:                   4 of   24      16%
    Number of DCMs:                       1 of    2      50%
    Number of RAMB16BWEs                  3 of    3     100%

    Best Case Achievable:           12.431 ns (0.069 ns Setup, 0.767 ns Hold)

Status
------

Design and initial verification is complete. Verification using ISim, MPLAB, 
and a board with an XC3S200AN-4VQG100I FPGA, various oscillators, SEEPROMs, 
and RS-232/RS-485 transceivers is underway.

In circuit testing of the M16C5x soft-core microcomputer has demonstrated that 
the M16C5x can operate to **147.4560 MHz**. At this internal system clock 
frequency, a 10x multiplication of the external reference oscillator, the SPI 
shift clock divider must be set to divide the system clock by 4, which 
generates an SPI shift clock frequency of 36.864 MHz. Various combinations of 
the DCM multiplier have been generated at tested in the XC3S200A-4VQG100I 
FPGA. The following table shows the system clock frequencies tested, the SPI 
shift clock frequencies tested, and the maximum achievable standard UART bit 
rate:

    DCM Multiplier  System Clock (MHz)  SPI Clock (MHz) Max UART bit rate (MHz)
        4x               58.9824            29.4912         3.6864
        5x               73.7280            36.8640         0.9216
        6x               88.4736            44.2368         0.9216
        6.5x             95.8464            47.9232         0.4608
        7x              103.2192            51.6096         0.9216
        7.5x            110.5920            55.2960         0.4608
        8x              117.9648            58.9824         7.3728
        8.5x            125.3376            62.6688         0.4608
        10x             147.4560            36.8640         1.8432

These results are only applicable to this particular configuration. The period 
constraint for the system clock is set for 12.5 ns, or 80 MHz. The 
relationship between the clock enable, 0.5 of the system clock, does not seem 
to be accomodated by the reported performance values. Further investigation is 
needed to establish if the results provided in the previous table should be 
accepted as the performance limits of the M16C5x core in this FPGA family.

A board has been configured with an XC3S50A-4VQG100I components, and it 
operates as expected at 80 MHz. Testing like that performed above with the 
XC3S200A-4VQG100I FPGA will be performed shortly. New interna resource 
configuration makes the UART clock, Clk_UART, and fixed output of the DCM. The 
UART clock is fixed at 2x ClkIn, or in this case, the UART clocl is fixed at 
29.4912 MHz.
    
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
interface is underway.

###Release 2.1

Testing with an M16C5x core processor program assembled using 
MPLAB and ISIM showed that polling of the UART status register to determine 
whether the transmit FIFO was empty or not (using the iTFE interrupt flag) 
would clear the generated interrupt flags before they had actually been 
captured and shifted in the SSP response to the core.

This indicated a clock domain crossing issue in the interrupt clearing logic. 
This release fixes that issue. Previous use of the UART does not poll the USR, 
so this problem does not manisfest itself in a reasonable amount of time, if 
ever. In other words, the synchronization fault has been present all along in 
the implementation, but the module's usage in the application (or testbench) 
did not present the conditions under which the fault manifests.

The correction required registering the USR data on the SSP clock domain, and 
qualifying the clearing of the interrupt flags on the basis of whether the 
flag is set in both domains when the USR is read. The addition of the register 
reduced the logic utilization, and only a small additonal time delay was 
incurred. The resulting design is still able to fit into a Spartan 3A XC3S50A-
4VQG100I FPGA.

Modified the UART Baud Rate Generator. Removed the fixed 16x12 ROM that 
provided the pre-scaler and divider constants for a fixed set of 16 baud 
rates. Added a 12-bit, write-only register, BRR - Baud Rate Register, that can 
be used to set the baud rate from 1/16 of the processor clock. With a 
58.9824 MHz oscillator, the baud rate can range from 3.6864Mbps down to 900 bps. 
Set the default baud rate to 9600 for a 58.9824 MHz UART clock.

Utilization for a XC3S50A-4VQG100I FPGA is 100%. The 128 byte LUT-based 
receive FIFO can be reduced to accomodate some additional functions. Synthesis 
and MAP/PAR able to implement the design. There is also some place holder 
logic that can be used for other purposes.

###Release 2.2

Updated the soft-core so as to be able to parameterize the microcontroller 
from the top module. Changed the frequency multiplication from 4 to 5 in order 
to test operation at the frequency which the UCF constrains Map/PAR tools. The 
input clock is driven by a 14.7456 MHz oscillator, and the clock multiplier 
(DCM) generates **73.7280 MHz**. The default baud rate, 9600, required that the 
default settings be adjusted. All other parameters remain the same.

Also added a Block RAM Memory Map file to the project. Utilized Xilinx's 
Data2MEM tool to insert modified program contents into the affected Block RAMs 
using MEM files dereived from standard MPLAB outputs. Tutorial on this subject 
is being prepared and will be released on an associated Wiki soon.

###Release 2.3

Updated the soft-core microcomputer. Fixed the UART clock, Clk_UART, to twice 
the input frequency. This means that the UART operates with a fixed reference 
frequency unlike Release 2.2 where Clk_UART was set to the system clock 
frequency. Also added asynchronous resets to several register in the UART so 
that the would simulate correcly with ISim.