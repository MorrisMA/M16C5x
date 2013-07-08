`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates
// Engineer:        Michael A. Morris
//
// Create Date:     08:46:12 07/04/2013
// Design Name:     M16C5x
// Module Name:     C:/XProjects/ISE10.1i/M16C5x/tb_M16C5x.v
// Project Name:    M16C5x
// Target Device:   SRAM FPGAs: XC3S50A-4VQG100I, XC3S200A-4VQG100I
// Tool versions:   Xilinx ISE 10.1i SP3
  
// Description: 
//
// Verilog Test Fixture created by ISE for module: M16C5x
//
// Dependencies:
// 
// Revision:
//
//  0.01    13G07   MAM     File Created
//
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_M16C5x;

reg     ClkIn;
reg     Clk_UART;
//
reg     nMCLR;
//
reg     nT0CKI;
reg     nWDTE;
reg     PROM_WE;
//
wire    TD;
reg     RD;
wire    nRTS;
reg     nCTS;
//
wire    [2:0] nCS;
wire    SCK;
wire    MOSI;
reg     MISO;
//
wire    [2:0] nCSO;
wire    nWait;

// Instantiate the Unit Under Test (UUT)

M16C5x  #(
            .pUserProg("Src/M16C5x_Tst3.coe")
        ) uut (
            .ClkIn(ClkIn),
            .Clk_UART(Clk_UART),
            
            .nMCLR(nMCLR), 

            .nT0CKI(nT0CKI), 
            .nWDTE(nWDTE), 
            .PROM_WE(PROM_WE), 

            .TD(TD), 
            .RD(RD), 
            .nRTS(nRTS), 
            .nCTS(nCTS),
            .DE(DE),

            .nCS(nCS), 
            .SCK(SCK), 
            .MOSI(MOSI), 
            .MISO(MISO),
            
            .nCSO(nCSO), 
            .nWait(nWait)
        );

initial begin
    // Initialize Inputs
    ClkIn    = 1;
    Clk_UART = 1;
    nMCLR    = 0;
    nT0CKI   = 0;
    nWDTE    = 1;
    PROM_WE  = 0;
    
    RD       = 1;
    nCTS     = 0;
    MISO     = 1;

    // Wait 100 ns for global reset to finish
    
    #201 nMCLR = 1;
    
    // Add stimulus here

end

////////////////////////////////////////////////////////////////////////////////

always #25 ClkIn = ~ClkIn;              // 20MHz Input Clk, 80MHz Internal Clk

always #10.416 Clk_UART = ~Clk_UART;    // 48MHz UART Reference Clk
      
////////////////////////////////////////////////////////////////////////////////

endmodule

