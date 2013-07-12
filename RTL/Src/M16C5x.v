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
//                  P16C5x.v
//                      P16C5x_IDec.v
//                      P16C5x_ALU.v
//                  M16C5x_SPI.v
//                      DPSFmnCE.v
//                      SPIxIF.v
//
// Revision:
//
//  0.01    13F15   MAM     Initial creation of the M16C5x module.
// 
// Additional Comments: 
//
////////////////////////////////////////////////////////////////////////////////

module M16C5x #(
    parameter pWDT_Size  = 20,          // Use 20 for synthesis and 10 for Sim.
    parameter pAddrsLen  = 12,          // User Program ROM address width
    parameter pUserProg  = "Src/M16C5x_Tst3.coe",   // Tst Pgm file: 4096 x 12
    parameter pRAMA_Init = "Src/RAMA.coe",  // RAM A initial value file ( 8x8)
    parameter pRAMB_Init = "Src/RAMB.coe"   // RAM B initial value file (64x8)
)(
    input   ClkIn,                      // External Clk - drives 4x DCM
    input   Clk_UART,                   // External UART Reference Clk

    input   nMCLR,                      // Master Clear Input
    input   nT0CKI,                     // Timer 0 Clk Input
    input   nWDTE,                      // Watch Dog Timer Enable
    
    input   PROM_WE,                    // Temporary Signal to Force Block RAM
    
    output  TD,                         // UART TD Output
    input   RD,                         // UART RD Input
    output  nRTS,                       // UART Request To Send (active low) Out
    input   nCTS,                       // UART Clear to Send (active low) Input
    output  DE,                         // UART RS-485 Driver Enable
    
    output  [2:0] nCS,                  // SPI Chip Select (active low) Output
    output  SCK,                        // SPI Serial Clock
    output  MOSI,                       // SPI Master Out/Slave In Output
    input   MISO,                       // SPI Master In/Slave Out Input
    
    //  Test Signals
    
    output  [2:0] nCSO,
    output  nWait
);

////////////////////////////////////////////////////////////////////////////////
//
//  Declarations
//

reg     ClkEn;

reg     [11:0] PROM[4095:0];            // User Program ROM (3x Block RAMs)
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

// Instantiate the Clk and Reset Generator Module

M16C5x_ClkGen   ClkGen (
                    .nRst(nMCLR), 
                    .ClkIn(ClkIn),
                    
                    .Clk(Clk),          // Clk    <= 4x ClkIn
                    .BufClkIn(),        // RefClk <= Buffered ClkIn

                    .Rst(Rst)
                );

//  Generate Clock Enable (Clk/2)

always @(posedge Clk or posedge Rst) ClkEn <= #1 ((Rst) ? 0 : ~ClkEn);

//  Register Inputs and connect to CPU

always @(posedge Clk) nWDTE_IFD  <= #1 ((Rst) ? 1 : nWDTE );
always @(posedge Clk) nT0CKI_IFD <= #1 ((Rst) ? 1 : nT0CKI);

assign WDTE  = ~nWDTE_IFD;
assign T0CKI = ~nT0CKI_IFD;

// Instantiate the P16C5x module

P16C5x  CPU (
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

assign WE_PROM = ClkEn & WE_PORTA & PROM_WE;

always @(posedge Clk)
begin
    if(Rst)
        PROM_DO <= #1 0;
    else if(WE_PROM)
        PROM[{PORTB[7:0], TRISB[7:4]}] <= #1 {TRISB[3:0], TRISA[7:0]};
    else
        PROM_DO <= #1 PROM[PROM_Addrs];
end

//always @(posedge <clock>) begin
//    if (<enableA>) begin
//        if (<write_enableA>)
//            <ram_name>[<addressA>] <= <input_dataA>;
//        <output_dataA> <= <ram_name>[<addressA>];
//    end
//    if (<enableB>)
//        <output_dataB> <= <ram_name>[<addressB>];
//end

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
        3'b1xx  : IO_DI <= {IRQ, CTS, RTS, DE, RF_FF, RF_EF, TF_FF, TF_EF};
        3'b01x  : IO_DI <= PORTB;
        3'b001  : IO_DI <= SPI_DO;
        default : IO_DI <= 0;
    endcase
end 

//assign TD      = ~PORTA[7];
//assign nRTS    = ~PORTA[6];
assign nCSO[2] = 1;
assign nCSO[1] = 1;
assign nCSO[0] = ~CS[0];
assign nWait   = ~CS[1];

// Instantiate the M16C5x SPI Interface module

assign SPI_MISO = ((CS[1]) ? SSP_MISO : MISO);

M16C5x_SPI  SPI (
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
            
assign nCS[0] = ~CS[0];
assign nCS[1] = ~CS[1];
assign nCS[2] = 1'b1;

assign MOSI = SPI_MOSI;

//  Instantiate Global Clock Buffer for driving the SPI Clock to internal nodes

BUFG    BUF1 (
            .I(SCK), 
            .O(SPI_SCK)
        );

//  Instantiate UART with an NXP LPC213x/LPC214x SSP-compatible interface

assign CTS = ~nCTS;

M16C5x_UART UART (
                .Rst(Rst), 
                
                .Clk_UART(Clk), 
                
                .SSEL(CS[1]), 
                .SCK(SPI_SCK), 
                .MOSI(SPI_MOSI), 
                .MISO(SSP_MISO), 
              
                .TxD(TD), 
                .RTS(RTS), 
                .RxD(RD), 
                .CTS(CTS), 
                
                .DE(DE),
                
                .IRQ(IRQ)
            );
            
assign nRTS = ~RTS;

endmodule
