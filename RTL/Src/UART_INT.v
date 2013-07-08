`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates
// Engineer:        Michael A. Morris
//
// Create Date:     09:37:34 06/15/2008 
// Design Name:     LTAS 
// Module Name:     C:/XProjects/ISE10.1i/LTAS/LTAS_Top.v
// Project Name:    LTAS 
// Target Devices:  XC3S700AN-5FFG484I 
// Tool versions:   ISE 10.1i SP3 
//
// Description: This module implements the interrupt request logic for the SSP
//              UART. Interrupt requests are generated for four conditions:
//
//                  (1) Transmit FIFO Empty;
//                  (2) Transmit FIFO Half Empty;
//                  (3) Receive FIFO Half Full;
//                  (4) and Receive Timeouts.
//
//              These four conditions are used as the interrupt sources. Inter-
//              rupts are not generated for CTS Change-Of-State and Rx Errors
//              because that information is either not useful (CTS) or reported
//              for each received character (RERR). The interrupt flags gene-
//              rated by this module must be combined externally to form a
//              interrupt request to the client.
//
//              The interrupt flags will be reset/cleared as indicated below
//              except the if the rst/clr pulse is coincident with the pulse 
//              which would set the flag, the flag remains set so that the new
//              assertion pulse is not lost. 
//
//              There remains a small probability that the second pulse may be
//              lost. This can be remedied by stretching the setting pulse to a
//              width equal to the uncertainty between the setting and reset-
//              ting pulses: approximately 4 clock cycles when re1ce modules
//              used to generate the Clr_Int pulse.
//
// Dependencies: redet.v, fedet.v
//
// Revision History:
//
//  0.01    08E15   MAM     File Created
//
//  1.00    08G24   MAM     Corrected the reset function for the four flags.
//                          The previous implementation would not reset or
//                          allow the flags to be initialized to the "Off"
//                          state. Added the RF_EF as a port, and added a 
//                          rising edge detector on the RF_EF to reset the
//                          RTO flag.
//
//  1.10    08H10   MAM     Changed the reset logic for the iTFE and iTHF
//                          so that they remain set until read by the host.
//
//  2.00    11B06   MAM     Converted to Verilog 2001.
//
// Additional Comments: 
//
//      The interrupt flags are set and reset under a variety of conditions.
// 
//      iTFE -  Set on the rising edge of the Transmit FIFO Empty Flag (TF_EF)
//              Rst on Clr_Int.
//
//      iTHE -  Set on the falling edge of Transmit FIFO Half Full (TF_HF) 
//              Rst on Clr_Int.
//
//      iRDA -  Set on the rising edge of Receive FIFO Half Full (RF_HF)
//              Rst on Clr_Int or on the falling edge of RF_HF.
//
//      iRTO -  Set on the rising edge of RTO
//              Rst on Clr_Int.
//
///////////////////////////////////////////////////////////////////////////////

module UART_INT(
    input   Rst,
    input   Clk,
    
    input   TF_HF,
    input   TF_EF,
    input   RF_HF,
    input   RF_EF,
    
    input   RTO,
    
    input   Clr_Int,
    
    output  reg iTFE,
    output  reg iTHE,
    output  reg iRDA,
    output  reg iRTO
);

///////////////////////////////////////////////////////////////////////////////
//
//  Local Signal Declarations
//

    wire    reTF_EF, feTF_HF;
    wire    reRF_HF, feRF_HF, reRF_EF;
    wire    reRTO;
    
///////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

redet   RE1 (.rst(Rst), .clk(Clk), .din(TF_EF), .pls(reTF_EF));
fedet   FE1 (.rst(Rst), .clk(Clk), .din(TF_HF), .pls(feTF_HF));

redet   RE2 (.rst(Rst), .clk(Clk), .din(RF_HF), .pls(reRF_HF));
fedet   FE2 (.rst(Rst), .clk(Clk), .din(RF_HF), .pls(feRF_HF));
redet   RE3 (.rst(Rst), .clk(Clk), .din(RF_EF), .pls(reRF_EF));

redet   RE4 (.rst(Rst), .clk(Clk), .din(RTO),   .pls(reRTO));

///////////////////////////////////////////////////////////////////////////////
//
//  Transmit FIFO Empty Interrupt Flag
//

assign Rst_iTFE = Rst | iTFE & Clr_Int;

always @(posedge Clk)
begin
    if(reTF_EF)
        iTFE <= #1 1;
    else if(Rst_iTFE)
        iTFE <= #1 reTF_EF;
end

///////////////////////////////////////////////////////////////////////////////
//
//  Transmit FIFO Half Empty Interrupt Flag
//

assign Rst_iTHE = Rst | iTHE & Clr_Int;

always @(posedge Clk)
begin
    if(feTF_HF)
        iTHE <= #1 1;
    else if(Rst_iTHE)
        iTHE <= #1 feTF_HF;
end

///////////////////////////////////////////////////////////////////////////////
//
//  Receive Data Available Interrupt Flag
//

assign Rst_iRDA = Rst | iRDA & (Clr_Int | feRF_HF | reRF_EF);

always @(posedge Clk)
begin
    if(reRF_HF)
        iRDA <= #1 1;
    else if(Rst_iRDA)
        iRDA <= #1 reRF_HF;
end

///////////////////////////////////////////////////////////////////////////////
//
//  Receive Timeout Interrupt Flag
//

assign Rst_iRTO = Rst | iRTO & Clr_Int;

always @(posedge Clk)
begin
    if(reRTO)
        iRTO <= #1 1;
    else if(Rst_iRTO)
        iRTO <= #1 reRTO;
end

endmodule
