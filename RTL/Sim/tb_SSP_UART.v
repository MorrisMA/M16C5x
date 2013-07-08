`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates
// Engineer:        Michael A. Morris
//
// Create Date:     18:21:47 06/13/2008
// Design Name:     LTAS
// Module Name:     C:/XProjects/ISE10.1i/LTAS/tb_SSP_UART.v
// Project Name:    LTAS
// Target Device:   XC3S700AN-5FGG484I
// Tool versions:   ISE 10.1i SP3
//
// Description: Test Fixture for full SSP UART 
//
// Verilog Test Fixture created by ISE for module: SSP_UART
//
// Dependencies:    SSP_UART
// 
// Revision History:
//
//  0.01    08F13   MAM     File Created
//
// Additional Comments: 
//
////////////////////////////////////////////////////////////////////////////////

module tb_SSP_UART_v;

// UUT Interface

reg     Rst;
reg     Clk;

reg     SSP_SSEL;
reg     SSP_SCK;
reg     [2:0] SSP_RA;
reg     SSP_WnR;
reg     SSP_EOC;
reg     [11:0] SSP_DI;
wire    [11:0] SSP_DO;

wire    TxD_232;
reg     RxD_232;
wire    xRTS;
reg     xCTS;

wire    TxD_485;
reg     RxD_485;
wire    xDE;

wire    IRQ;

wire    TxIdle;
wire    RxIdle;

// Instantiate the Unit Under Test (UUT)

SSP_UART    uut (
                .Rst(Rst), 
                .Clk(Clk),
                
                .SSP_SSEL(SSP_SSEL),
                .SSP_SCK(SSP_SCK), 
                .SSP_RA(SSP_RA),
                .SSP_WnR(SSP_WnR),
                .SSP_EOC(SSP_EOC), 
                .SSP_DI(SSP_DI), 
                .SSP_DO(SSP_DO),
                
                .TxD_232(TxD_232), 
                .RxD_232(RxD_232), 
                .xRTS(xRTS), 
                .xCTS(xCTS),
                
                .TxD_485(TxD_485), 
                .RxD_485(RxD_485), 
                .xDE(xDE),
                
                .IRQ(IRQ),
                
                .TxIdle(TxIdle),
                .RxIdle(RxIdle)
            );

initial begin
    // Initialize Inputs
    Rst      = 1;
    Clk      = 1;
    SSP_SSEL = 0;
    SSP_SCK  = 1;
    SSP_RA   = 0;
    SSP_WnR  = 0;
    SSP_EOC  = 0;
    SSP_DI   = 0;
    RxD_232  = 1;
    xCTS     = 0;
    RxD_485  = 1;

    // Wait 100 ns for global reset to finish
    #101 Rst = 0;
    
    // Add stimulus here

end

///////////////////////////////////////////////////////////////////////////////
//
//  Simulation Clocks
//

always #5 Clk = ~Clk;
  
endmodule

