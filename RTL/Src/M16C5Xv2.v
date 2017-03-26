////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2013 by Michael A. Morris, dba M. A. Morris & Associates
//
//  All rights reserved. The source code contained herein is publicly released
//  under the terms and conditions of the GNU Lesser Public License. No part of
//  this source code may be reproduced or transmitted in any form or by any
//  means, electronic or mechanical, including photocopying, recording, or any
//  information storage and retrieval system in violation of the license under
//  which the source code is released.
//
//  The source code contained herein is free; it may be redistributed and/or
//  modified in accordance with the terms of the GNU Lesser General Public
//  License as published by the Free Software Foundation; either version 2.1 of
//  the GNU Lesser General Public License, or any later version.
//
//  The source code contained herein is freely released WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
//  PARTICULAR PURPOSE. (Refer to the GNU Lesser General Public License for
//  more details.)
//
//  A copy of the GNU Lesser General Public License should have been received
//  along with the source code contained herein; if not, a copy can be obtained
//  by writing to:
//
//  Free Software Foundation, Inc.
//  51 Franklin Street, Fifth Floor
//  Boston, MA  02110-1301 USA
//
//  Further, no use of this source code is permitted in any form or means
//  without inclusion of this banner prominently in any derived works.
//
//  Michael A. Morris
//  Huntsville, AL
//
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates 
// Engineer:        Michael A. Morris 
// 
// Create Date:     19:30:58 06/15/2013 
// Design Name:     Microcomputer Implementation using P16C5x Processor Core
// Module Name:     M16C5x.v 
// Project Name:    C;\XProjects\ISE10.1i\M16C5x
// Target Devices:  RAM-based FPGA 
// Tool versions:   Xilinx ISE 10.1i SP3
//
// Description:
//
//  This module is a microcomputer implementation using an FPGA-based processor
//  core based on the P16C5x module. The P16C5x is derived from the released
//  PIC16C5x core found on GitHUB. The P16C5x differs from that core in that the
//  TRISA..TRISC registers, and the IO Ports A..C have been removed and replaced
//  by a number of WE and RE strobes and an IO data bus.
//
//  This modification has been done to demonstrate how the PIC16C5x core can be
//  adapted to interface to a UART or an SPI Master. By using the P16C5x core,
//  a microcomputer implementation can be generated for a small FPGA that pro-
//  vides significant processing capabilities. By using a core like the P16C5x,
//  standard programming languages and support tools can be used to ease the 
//  development of sophisticated FPGA-based products.
//
// Dependencies:    M16C5x_ClkGen.v
//                      ClkGen.xaw
//                      fedet.v
//                  P16C5x.v
//                      P16C5x_IDec.v
//                      P16C5x_ALU.v
//                  M16C5x_SPI.v
//                      DPSFmnCE.v
//                      SPIxIF.v
//                  M16C5x_UART.v
//                      SSPx_Slv.v
//                      SSP_UART.v
//                          re1ce.v
//                          DPSFmnCE.v
//                          UART_BRG.v
//                          UART_TXSM.v
//                          UART_RXSM.v
//                          UART_RTO.v
//                          UART_INT.v
//                              redet.v
//                              fedet.v
//
// Revision:
//
//  0.01    13F15   MAM     Initial creation of the M16C5x module.
//
//  2.20    13G14   MAM     Updated all of the module instantiations and the top
//                          module to support the parameterization of the soft-
//                          core microcontroller from the top level: M16C5x. Up-
//                          dated Dependencies section, and set revision to
//                          match the release number on GitHUB.
//
//  2.30    13G21   MAM     Changed UART Clk to operate from the Clk2x output of
//                          DCM. Gives a fixed value for the UART Clk regardless
//                          of the ClkFX output frequency. Adjusted default PS,
//                          Div values to produce 9600 bps as the default.
//
//  2.40    13J18   MAM     Remove CE TFF, and force single cycle operation.
//                          Changed clock edge for internal block RAM from the
//                          rising edge to the falling edge. This allows M16C5x
//                          to function as a single cycle core when operating 
//                          from internal block RAM.
//
//  2.41    13J19   MAM     Modified the UART FIFOs to be 64 elements deep.
//
//  2.50    14D08   MAM     Modified to support the Chameleon Arduino-compatible
//                          FPGA Shield Board, 1033-1004. Removed the clock
//                          generator module, ClkGen, mapped ClkIn (48MHz) to
//                          Clk, and added Clk_UART port to input 29.4912MHz
//                          oscillator for the UART clock. Modified the UCF to
//                          connect Chameleon Port A to the M16C5x UART.
//
//  2.60    14D13   MAM     Modified to support dual UARTs. Second UART selected
//                          when SSP RA[2] is set, and first UART is selected
//                          when SSP RA[2] is not set.
// 
// Additional Comments: 
//
////////////////////////////////////////////////////////////////////////////////

module M16C5Xv2 #(
    // P16C5x Module Parameter Settings
    
    parameter pWDT_Size  = 20,              // 20 - synthesis; 10 - Simulation
    parameter pRstVector = 12'h7FF,         // Reset Vector Location (PIC16F59)
//    parameter pUserProg  = "Src/M16C5x_Tst4.coe",   // Tst Pgm file: 4096 x 12
    parameter pUserProg  = "Src/M16C5x.coe",   // Tst Pgm file: 4096 x 12
    parameter pRAMA_Init = "Src/RAMA.coe",  // RAM A initial value file ( 8x8)
    parameter pRAMB_Init = "Src/RAMB.coe",  // RAM B initial value file (64x8)

    // M16C5x_SPI Module Parameter Settings

    parameter pSPI_CR_Default = 8'b0_110_00_0_0,    // SPI Interface Defaults
    parameter pSPI_TF_Depth   = 4,                  // Tx FIFO: 2**pTF_Depth
    parameter pSPI_RF_Depth   = 4,                  // Rx FIFO: 2**pRF_Depth
    parameter pSPI_TF_Init    = "Src/TF_Init.coe",  // Tx FIFO Memory Init
    parameter pSPI_RF_Init    = "Src/RF_Init.coe",  // Rx FIFO Memory Init

    // SSP_UART Module Parameter Settings

    parameter pPS_Default    = 4'h0,        // see baud rate tables SSP_UART
    parameter pDiv_Default   = 8'hBF,       // BR = 9600 @UART_Clk = 29.4912 MHz
    parameter pRTOChrDlyCnt  = 3,           // Rcv Time Out Character Dly Count
    parameter pUART_TF_Depth = 2,           // Tx FIFO Depth: 2**(pTF_Depth + 4)
    parameter pUART_RF_Depth = 2,           // Rx FIFO Depth: 2**(pRF_Depth + 4)
    parameter pUART_TF_Init  = "Src/UART_TF.coe",   // Tx FIFO Memory Init
    parameter pUART_RF_Init  = "Src/UART_RF.coe"    // Rx FIFO Memory Init
)(
    input   ClkIn,                      // External Clk for CPU:  48.0000 MHz
    input   Clk_UART,                   // External Clk for UART: 29.4912 MHz
    
    input   nMCLR,                      // Master Clear Input
    input   nT0CKI,                     // Timer 0 Clk Input
    input   nWDTE,                      // Watch Dog Timer Enable
    
    input   PROM_WE,                    // Temporary Signal to Force Block RAM
    
    output  TD_A,                       // COM0 TD Output
    input   RD_A,                       // COM0 RD Input
    output  nRTS_A,                     // COM0 Request To Send (active low) Out
    input   nCTS_A,                     // COM0 Clear to Send (active low) Input
    output  DE_A,                       // COM0 RS-485 Driver Enable
    
    output  TD_B,                       // COM1 TD Output
    input   RD_B,                       // COM1 RD Input
    output  nRTS_B,                     // COM1 Request To Send (active low) Out
    input   nCTS_B,                     // COM1 Clear to Send (active low) Input
    output  DE_B,                       // COM1 RS-485 Driver Enable
    
    output  reg [1:0] nCS,              // SPI Chip Select (active low) Output
    output  SCK,                        // SPI Serial Clock
    output  MOSI,                       // SPI Master Out/Slave In Output
    input   MISO,                       // SPI Master In/Slave Out Input
    
    //  Test Signals
    
    output  [1:0] LED
);

////////////////////////////////////////////////////////////////////////////////
//
//  Declarations
//

reg     Rst;                            // Synchronization FF for External Rst

wire    ClkEn;                          // Multi-cycle Clock Enable (Default=1)

reg     [11:0] PROM [4095:0];           // User Program ROM (3x Block RAMs)
wire    [11:0] PROM_Addrs;              // Program Counter from CPU
reg     [11:0] PROM_DO;                 // Instruction Register to CPU

reg     nWDTE_IFD, nT0CKI_IFD;          // IOB FFs for external inputs
wire    WDTE, T0CKI;

wire    [7:0] IO_DO;                    // IO Data Output bus
reg     [7:0] IO_DI;                    // IO Data Input bus

reg     [7:0] TRISA, TRISB;             // IO Ports
reg     [7:0] PORTA, PORTB;

wire    [1:0] CS;                       // Chip select outputs of the SPI Mstr
wire    SPI_SCK;                        // SPI SCK for internal components
wire    SPI_MOSI, SPI_MISO;

wire    [7:0] SPI_DO;                   // Output Data Bus of SPI Master module
wire    TF_EF, TF_FF, RF_EF, RF_FF;     // SPI Module Status Signals

wire    SSP_MISO;                       // SSP UART MISO signal
wire    RTS, CTS;                       // SSP UART Modem Control Signals
wire    IRQ;                            // SSP UART Interrupt Request Signal

////////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

assign Clk = ClkIn;                     // Assign system clock to input clock

always @(posedge Clk) Rst <= #1 ~nMCLR;

//  Force Single Cycle Operation

assign ClkEn = 1;

//  Register Inputs and connect to CPU

always @(posedge Clk)
begin
    if(Rst) begin
        nWDTE_IFD  <= #1 ~0;
        nT0CKI_IFD <= #1 ~0;
    end else if(ClkEn) begin
        nWDTE_IFD  <= #1 nWDTE;
        nT0CKI_IFD <= #1 nT0CKI;
    end
end 

assign WDTE  = ~nWDTE_IFD;
assign T0CKI = ~nT0CKI_IFD;

// Instantiate the P16C5x module

P16C5x  #(
            .pRstVector(pRstVector),
            .pWDT_Size(pWDT_Size),
            .pRAMA_Init(pRAMA_Init),
            .pRAMB_Init(pRAMB_Init)
        ) CPU (
            .POR(Rst), 
            .Clk(Clk), 
            .ClkEn(ClkEn),
            
            .MCLR(Rst), 
            .T0CKI(T0CKI), 
            .WDTE(WDTE), 
            
            .PC(PROM_Addrs),
            .ROM(PROM_DO),
            
            .WE_TRISA(WE_TRISA), 
            .WE_TRISB(WE_TRISB), 
            .WE_TRISC(WE_TRISC), 
            .WE_PORTA(WE_PORTA), 
            .WE_PORTB(WE_PORTB), 
            .WE_PORTC(WE_PORTC), 
            .RE_PORTA(RE_PORTA), 
            .RE_PORTB(RE_PORTB), 
            .RE_PORTC(RE_PORTC),
            
            .IO_DO(IO_DO), 
            .IO_DI(IO_DI), 

            .Rst(),

            .OPTION(), 
            .IR(), 
            .dIR(), 
            .ALU_Op(), 
            .KI(),
            .Msk(),            
            .Err(), 
            .Skip(), 
            .TOS(), 
            .NOS(), 
            .W(), 
            .FA(), 
            .DO(), 
            .DI(), 
            .TMR0(), 
            .FSR(), 
            .STATUS(), 
            .T0CKI_Pls(), 
            .WDTClr(), 
            .WDT(), 
            .WDT_TC(), 
            .WDT_TO(), 
            .PSCntr(), 
            .PSC_Pls()
        );

////////////////////////////////////////////////////////////////////////////////
//
//  User Program ROM
//
        
initial
  $readmemh(pUserProg, PROM, 0, 4095);

assign WE_PROM = ClkEn & PROM_WE & WE_PORTB;

always @(negedge Clk)
begin
    if(Rst)
        PROM_DO <= #1 0;
    else if(WE_PROM)
        PROM[{TRISB[3:0], TRISA[7:0]}] <= #1 {TRISB[7:4], PORTB[7:0]};
    else
        PROM_DO <= #1 PROM[PROM_Addrs];
end

////////////////////////////////////////////////////////////////////////////////
//
//  M16C5x I/O
//

always @(posedge Clk)
begin
    if(Rst) begin
        TRISA <= #1 ~0;
        TRISB <= #1 ~0;
        //
        PORTA <= #1 ~0;
        PORTB <= #1 ~0;
    end else if(ClkEn) begin
        TRISA <= #1 ((WE_TRISA) ? IO_DO : TRISA);
        TRISB <= #1 ((WE_TRISB) ? IO_DO : TRISB);
        //
        PORTA <= #1 ((WE_PORTA) ? IO_DO : PORTA);
        PORTB <= #1 ((WE_PORTB) ? IO_DO : PORTB);
    end
end

always @(*)
begin
    casex({RE_PORTA, RE_PORTB, RE_PORTC})
        3'b1xx  : IO_DI <= {IRQ, 3'b000, RF_FF, RF_EF, TF_FF, TF_EF};
        3'b01x  : IO_DI <= PORTB;
        3'b001  : IO_DI <= SPI_DO;
        default : IO_DI <= 0;
    endcase
end 

assign LED[1] = CS[1];
assign LED[0] = CS[0];

// Instantiate the M16C5x SPI Interface module

assign SPI_MISO = ((CS[1]) ? SSP_MISO : MISO);

M16C5x_SPI  #(
                .pCR_Default(pSPI_CR_Default),
                .pTF_Depth(pSPI_TF_Depth),
                .pRF_Depth(pSPI_RF_Depth),
                .pTF_Init(pSPI_TF_Init),
                .pRF_Init(pSPI_RF_Init)
            ) SPI (
                .Rst(Rst), 
                .Clk(Clk),
                
                .ClkEn(ClkEn),
                
                .WE_CR(WE_TRISC), 
                .WE_TF(WE_PORTC), 
                .RE_RF(RE_PORTC), 
                .DI(IO_DO), 
                .DO(SPI_DO), 
                
                .CS(CS[1:0]), 
                .SCK(SCK), 
                .MOSI(SPI_MOSI), 
                .MISO(SPI_MISO), 
                
                .SS(SS), 
                .TF_FF(TF_FF), 
                .TF_EF(TF_EF), 
                .RF_FF(RF_FF), 
                .RF_EF(RF_EF)
            );

always @(*)
begin
    case({TRISA[7:5], CS[0]})
        4'b000_0 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b000_1 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b001_0 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b001_1 : nCS <= 2'b10;    // Select SPI Flash Device
        4'b010_0 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b010_1 : nCS <= 2'b01;    // Select SPI MRAM/FRAM Device
        4'b011_0 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b011_1 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b100_0 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b100_1 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b101_0 : nCS <= 2'b10;    // Select SPI Flash Device
        4'b101_1 : nCS <= 2'b10;    // Select SPI Flash Device
        4'b110_0 : nCS <= 2'b01;    // Select SPI MRAM/FRAM Device
        4'b110_1 : nCS <= 2'b01;    // Select SPI MRAM/FRAM Device
        4'b111_0 : nCS <= 2'b11;    // No External SPI Device Selected
        4'b111_1 : nCS <= 2'b11;    // No External SPI Device Selected
    endcase
end
            
assign MOSI = SPI_MOSI;

//  Instantiate Global Clock Buffer for driving the SPI Clock to internal nodes

BUFG    BUF1 (
            .I(SCK), 
            .O(SPI_SCK)
        );

//  Instantiate UART with an NXP LPC213x/LPC214x SSP-compatible interface

assign CTS_A = ~nCTS_A;
assign CTS_B = ~nCTS_B;

M16C5x_UARTv2   #(
                    .pPS_Default(pPS_Default),
                    .pDiv_Default(pDiv_Default),
                    .pRTOChrDlyCnt(pRTOChrDlyCnt),
                    .pTF_Depth(pUART_TF_Depth),
                    .pRF_Depth(pUART_RF_Depth),
                    .pTF_Init(pUART_TF_Init),
                    .pRF_Init(pUART_RF_Init)
                ) UART (
                    .Rst(Rst), 
                    
                    .Clk_UART(Clk_UART), 
                    
                    .SSEL(CS[1]), 
                    .SCK(SPI_SCK), 
                    .MOSI(SPI_MOSI), 
                    .MISO(SSP_MISO), 
                  
                    .TxD_A(TD_A), 
                    .RTS_A(RTS_A), 
                    .RxD_A(RD_A), 
                    .CTS_A(CTS_A), 

                    .DE_A(DE_A),
                    
                    .TxD_B(TD_B), 
                    .RTS_B(RTS_B), 
                    .RxD_B(RD_B), 
                    .CTS_B(CTS_B), 
                    
                    .DE_B(DE_B),
                    
                    .IRQ(IRQ)
                );
            
assign nRTS_A = ~RTS_A;
assign nRTS_B = ~RTS_B;

endmodule
