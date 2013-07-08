`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates
// Engineer:        Michael A. Morris
//
// Create Date:     13:28:23 05/10/2008 
// Design Name:     LTAS 
// Module Name:     C:/XProjects/ISE10.1i/LTAS/UART_BRG.v
// Project Name:    LTAS 
// Target Devices:  XC3S700AN-5FFG484I 
// Tool versions:   ISE 10.1i SP3 
//
// Description: This module implements the Baud Rate Generator for the SSP
//              UART described for the 1700-0403 MicroBridge Option Card.
//
//              The Baud Rate Generator implements the 16 baud rates defined
//              in Table 3 of the SSP UART Specification.
//
// Dependencies: 
//
// Revision History:
//
//  0.01    08E10   MAM     File Created
//
//  1.00    08E10   MAM     Initial Release
//
//  1.10    08E13   MAM     Changed interface so Prescaler and Divider values
//                          passed directly in by removing Baud Rate ROM.
//
//  1.11    08E14   MAM     Reduced width of divider from 10 to 8 bits.
//
//  1.20    08E15   MAM     Changed the structure of the PSCntr and Divider
//                          to use a multiplxer on the input to load or count
//                          which results in a more efficient implementation.
//                          Added a registered TC on the PSCntr which functions
//                          to break the combinatorial logic chains and speed
//                          counter implementations.
//
//  1.30    08G26   MAM     Corrected initial condition of the PSCntr, which
//                          caused the prescaler to always divide by two. 
//                          Removed FF in PSCntr TC path to remove the divide
//                          by two issue. CE_16x output remains as registered.
//
//  2.00    11B06   MAM     Converted to Verilog 2001.
//
// Additional Comments: 
//
///////////////////////////////////////////////////////////////////////////////

module UART_BRG(
    input   Rst,
    input   Clk,

    input   [3:0] PS,       // Baud Rate Generator Prescaler Load Value
    input   [7:0] Div,      // Baud Rate Generator Divider Load Value
    
    output  reg CE_16x      // Clock Enable Output - 16x Baud Rate Output 
);

///////////////////////////////////////////////////////////////////////////////    
//
//  Local Signal Declarations
//

    reg     [ 3:0] PSCntr;  // BRG Prescaler 
    reg     [ 7:0] Divider; // BRG Divider
    
    wire    TC_PSCntr;      // BRG Prescaler TC/Divider CE
    wire    TC_Divider;     // BRG Divider TC
    
///////////////////////////////////////////////////////////////////////////////
//
//  Implementation
//

//  BRG Prescaler Counter

always @(posedge Clk)
begin
    if(Rst)
        PSCntr <= #1 0;
    else if(TC_PSCntr)
        PSCntr <= #1 PS;
    else 
        PSCntr <= #1 PSCntr - 1;
end

assign TC_PSCntr = (PSCntr == 0);

// BRG Divider

always @(posedge Clk)
begin
    if(Rst)
        Divider <= #1 0;
    else if(TC_Divider)
        Divider <= #1 Div;
    else if(TC_PSCntr)
        Divider <= #1 Divider - 1;
end

assign TC_Divider = TC_PSCntr & (Divider == 0);

// Output 16x Bit Clock/CE

always @(posedge Clk)
begin    
    if(Rst)
        CE_16x <= #1 1'b0;
    else
        CE_16x <= #1 TC_Divider;
end

endmodule
