`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
// Company:         M. A. Morris & Associates
// Engineer:        Michael A. Morris
//
// Create Date:     12:30:30 05/11/2008 
// Design Name:     Synchronous Serial Peripheral (SSP) Interface UART 
// Module Name:     ../VerilogCoponentsLib/SSP_UART/SSP_UART.v
// Project Name:    Verilog Components Library
// Target Devices:  XC3S700AN-5FFG484I 
// Tool versions:   ISE 10.1i SP3 
//
// Description: This module integrates the various elements of a simplified 
//              UART to create a UART that is efficiently supported using a 
//              serial interface. The module also incorporates the logic to 
//              support four operating modes, and controls the signal muxes 
//              necessary.
//
// Dependencies: re1ce.v, BRSFmnCE.v, UART_BRG.v, UART_TXSM.v, UART_RXSM.v,
//               UART_RTO.v, UART_INT.v, redet.v
//
// Revision History:
//
//  0.01    08E10   MAM     File Created
//
//  0.10    O8E12   MAM     Incorporated the ROMs for decoding the format
//                          and buad rate. Updated the interfaces to the
//                          BRG, TxSM, and RxSM.
//
//  0.11    08E14   MAM     Added the RTO ROM for setting the length of the
//                          receive timeout interval on the basis of the 
//                          character frame format. Modified the baud rate 
//                          table to remove the 300 and 600 baud entries and
//                          add entries for 28.8k and 14.4k baud. Reduced the
//                          width of the baud rate divider from 10 to 8 bits.
//
//  1.00    08G23   MAM     Modified the SSP Interface to operate with the new
//                          SSPx_Slv interface which uses registers for SSP_DI
//                          and SSP_DO. The falling edge of SCK is used for the
//                          latching and transfering read/write operations from
//                          the SCK clock domain to the Clk clock domain.
//
//  1.01    08G24   MAM     Corrected error in the TFC/RFC pulse enables that
//                          allowed any write to the SSP UART with 1's in these
//                          bit positions to generate a THR/RHR FIFO reset.
//
//  1.10    08G26   MAM     Modified to implement a multiplexed register set
//                          with the SPR address. Additional status registers
//                          added for various purposes including revision, 
//                          FIFO output, FIFO len, and FIFO count registers.
//                          Since an XC2S30 is required, and there is no other
//                          function required in the FPGA, increased the FIFO
//                          depth of the Tx FIFO to 128 words using distributed
//                          RAM.
//
//  1.11    08G27   MAM     Modified the organization of the SPR window status
//                          registers to match Table 5 in the 17000-0403C SSP
//                          UART specification.
//
//  1.20    08G27   MAM     Modified Tx signal path to include a FF that will 
//                          prevent the Tx SM from shifting until the Tx FIFO
//                          is loaded with the full message up to the size of
//                          FIFO. The bit is normally written as a 0 and ORed
//                          with the TF_EF. In this state, Tx SM starts the
//                          shift operation immediately. When the bit is set,
//                          then the OR with the TF_EF prevents the Tx SM from
//                          sending the Tx FIFO contents until HLD bit is reset
//
//  1.30    08H02   MAM     Modified the FIFOs to use the Block RAM FIFOs. 
//                          Updated the default parameters to set the depth to
//                          match the 1024 word depth of the Block RAM FIFOs.
//
//  1.40    08H09   MAM     Added Rx/Tx FIFO Threshold Resgister, reordered SPR
//                          sub-registers to incorporate programmable threshold
//                          for the FIFOs into the design. Set the default of 
//                          the threshold for the Rx/Tx FIFOs to half.
//
//  1.41    08H12   MAM     Registered the RxD input signal; reset State forced
//                          mark condition. Modified the RTFThr register so
//                          a logic 1 is required in SSP_DI[8] to write it.
//
//  2.00    11B06   MAM     Converted to Verilog 2001. Added an external enable
//                          signal, reordered the registers, and set the SPI
//                          interface to operate in the same manner as for the
//                          LTAS module.
//
//  2.01    11B08   MAM     Changed En to SSP_SSEL, and changed the SSP_DO bus
//                          to a tri-state bus enabled by SSP_SSEL so that the
//                          module can used along with other SSP-compatible
//                          modules in the same FPGA. Corrected minor encoding
//                          error for RS/TS fields.
//
// Additional Comments:
//
//  The SSP UART is defined in 1700-0403C. The following is a summary of the 
//  register and field definitions contained in the referenced document. If any
//  conflicts arise in the definitions, the implementation defined in this file
//  will take precedence over the document.
//
//  The UART consists of five registers:
// 
//      (1) UCR - UART Control Register     (3'b000)
//      (2) USR - UART Status Register      (3'b001)
//      (3) TDR - Transmit Data Register    (3'b010)
//      (4) RDR - Receive Data Register     (3'b011)
//      (5) SPR - Scratch Pad Register      (3'b100)
//
//  The Synchronous Serial Peripheral of the ARM is configured to send 16 bits.
//  The result is that the 3 most significant bits are interpreted as an regis-
//  ter select. In this manner, the SSP UART minimizes the number of serial
//  transfers required to send and receive serial data from the SSP UART. The
//  reads from the TDR/RDR address also provides status information regarding
//  the transmit and receive state machines, and the FIFO-based holding regis-
//  ters.
//
//  With each SSP/SPI operation to the TDR/RDR address, the SSP UART will read
//  and write the receive and transmit holding registers, respectively. These
//  holding registers are implemented using 9-bit and 8-bit FIFOs, respective-
//  ly. The FIFOs are independently configured so that they can be easily
//  replaced with other implementations as required.
//
//  The USR implements a read-only register for the UART status bits other than
//  the RERR - Receiver Error, RTO - Receiver Time-Out, RRDY - Receiver Ready,
//  and the TRDY - Transmitter Ready status bits read out in the RDR. The USR
//  provides access to the UART mode and baud rate bits from the UCR. The RTSi 
//  and CTSi bits reflect the state of the external RTS and CTS signals in the
//  RS-232 modes. In the RS-485 modes, RTSi reflects the state of the external
//  transceiver drive enable signal, and CTSi should be read as a logic 1. The
//  CTSi bit is set internally to a logic 1 by the SSP UART in the RS-485 modes
//  because it is always ready to receive. The receiver serial input data pin 
//  is controlled in the RS-485 modes so that the external transceiver output
//  enable can always be enabled. 
//
//  UART Control Register - UCR (RA = 3'b000)
//
//  11:10 - MD  :   Mode (see table below)
//      9 - RTSo:   Request To Send, set to assert external RTS in Mode 0
//      8 - IE  :   Interrupt Enable, set to enable Xmt/Rcv interrupts
//    7:4 - FMT :   Format (see table below)
//    3:0 - BAUD:   Baud Rate (see table below)
//
//  UART Status Register - USR (RA = 3'b001)
//
//  11:10 - MD  :   Mode (see table below)
//      9 - RTSi:   Request To Send In, set as discussed above
//      8 - CTSi:   Clear To Send In, set as discussed above
//    7:6 - RS  :   Receive Status:  0 - Empty, 1 < Half, 2 >= Half, 3 - Full
//    5:4 - TS  :   Transmit Status: 0 - Empty, 1 < Half, 2 >= Half, 3 - Full
//      3 - iRTO:   Receive Timeout Interrupt Flag
//      2 - iRDA:   Receive Data Available Interupt Flag (FIFO >= Half Full)
//      1 - iTHE:   Transmit FIFO Half Empty Interrupt Flag
//      0 - iTFE:   Transmit FIFO Empty Interrupt Flag
//
//  Transmit Data Register - TDR (RA = 3'b010)
//
//   11 - TFC   :   Transmit FIFO Clear, cleared at end of current cycle
//   10 - RFC   :   Receive FIFO Clear, cleared at end of current cycle
//    9 - HLD   :   Transmit Hold: 0 - normal; 1 - hold until Tx FIFO filled
//    8 - Rsvd  :   Reserved for Future Use
//  7:0 - TD    :   Transmit Data, written to Xmit FIFO when WnR is set.
//
//  Receive Data Register - RDR (RA = 3'b011)
//
//   11 - TRDY  :   Transmit Ready, set if Xmt FIFO not full
//   10 - RRDY  :   Receive Ready, set if Rcv FIFO has data 
//    9 - RTO   :   Receive Time Out, set if no data received in 3 char. times
//    8 - RERR  :   Receiver Error, set if current RD[7:0] has an error
//  7:0 - RD    :   Receive Data
//
//  Scratch Pad Register - SPR (RA = 3'b100)
//
//  11:0 - SPR  :   Scratch Pad Data, R/W location
//
///////////////////////////////////////////////////////////////////////////////
//
//  MD[1:0] - Operating Mode
//
//   2'b00 - RS-232 without Handshaking, xRTS <= RTSi <= RTSo, CTSi <= xCTS
//   2'b01 - RS-232 with Handshaking, xRTS <= RTSi <= ~TxIdle, CTSi <= xCTS
//   2'b10 - RS-485 without Loopback, RD <= CTSi <= 1, DE <= RTSi <= ~TxIdle
//   2'b11 - RS-485 with Loopback, RD <= RxD, DE <= RTSi <= ~TxIdle, CTSi <= 1
//
//  FMT[3:0] - Asynchronous Serial Format
//
//   4'b0000 - 8N1, 4'b1000 - 8O2
//   4'b0001 - 8N1, 4'b1001 - 8E2
//   4'b0010 - 8O1, 4'b1010 - 8S2
//   4'b0011 - 8E1, 4'b1011 - 8M2
//   4'b0100 - 8S1, 4'b1100 - 7O1
//   4'b0101 - 8M1, 4'b1101 - 7E1
//   4'b0110 - 8N1, 4'b1110 - 7O2
//   4'b0111 - 8N2, 4'b1111 - 7E2
//
//  BAUD[3:0] - Serial Baud Rate (48 MHz Reference Clock, 16x UART)
//
//   4'b0000 -  1500 kbps,  4'b1000 - 38.4 kbps
//   4'b0001 -  1000 kbps,  4'b1001 - 28.8 kbps
//   4'b0010 -   500 kbps,  4'b1010 - 19.2 kbps
//   4'b0011 - 187.5 kbps,  4'b1011 - 14.4 kbps
//   4'b0100 - 230.4 kbps,  4'b1100 -  9.6 kbps
//   4'b0101 - 115.2 kbps,  4'b1101 -  4.8 kbps
//   4'b0110 -  76.8 kbps,  4'b1110 -  2.4 kbps
//   4'b0111 -  57.6 kbps,  4'b1111 -  1.2 kbps
// 
///////////////////////////////////////////////////////////////////////////////
//
//  SPR Sub-Addresses - Additional Status Registers
//
//      Accessed by setting the 3 MSBs of the SPR to the address of the desired
//      status register. Unused bits in the status registers set to 0.
//      Unassigned sub-addresses default to the SPR.
//
//   1 - [7:0] Revision Register
//   2 - [7:0] FIFO Length: RFLen - 7:4, TFLen - 3:0; (1 << (xFLen + 4))
//   3 - [7:0] Rx/Tx FIFO Threshold: RFThr - 7:4, TFThr - 3:0; (xFLen >> 1)
//   4 - [7:0] Tx Holding Register, reading THR does not advance FIFO
//   5 - [8:0] Rx Holding Register, reading RHR does not advance FIFO
//   6 - [(TFLen + 4):0] Tx FIFO Count
//   7 - [(RFLen + 4):0] Rx FIFO Count
//
///////////////////////////////////////////////////////////////////////////////

module SSP_UART #( 
    parameter pVersion = 8'h21,     // Version: 2.1
    parameter pRTOChrDlyCnt = 3
)(
    input   Rst,                    // System Reset
    input   Clk,                    // System Clock
    
    //  SSP Interface
    
    input   SSP_SSEL,               // SSP Slave Select
    
    input   SSP_SCK,                // Synchronous Serial Port Serial Clock
    input   [2:0] SSP_RA,           // SSP Register Address
    input   SSP_WnR,                // SSP Command
    input   SSP_EOC,                // SSP End-Of-Cycle
    input   [11:0] SSP_DI,          // SSP Data In
    output  reg [11:0] SSP_DO,      // SSP Data Out
    
    //  External UART Interface
    
    output  TxD_232,                // RS-232 Mode TxD
    input   RxD_232,                // RS-232 Mode RxD
    output  reg xRTS,               // RS-232 Mode RTS (Ready-To-Receive)
    input   xCTS,                   // RS-232 Mode CTS (Okay-To-Send)
    
    output  TxD_485,                // RS-485 Mode TxD
    input   RxD_485,                // RS-485 Mode RxD
    output  xDE,                    // RS-485 Mode Transceiver Drive Enable

    //  External Interrupt Request
    
    output  reg IRQ,                // Interrupt Request
    
    //  TxSM/RxSM Status
    
    output  TxIdle,
    output  RxIdle
); 

///////////////////////////////////////////////////////////////////////////////
//
//  Module Parameters
// 

//  Register Addresses

localparam pUCR = 0;    // UART Control Register
localparam pUSR = 1;    // UART Status Register
localparam pTDR = 2;    // Tx Data Register
localparam pRDR = 3;    // Rx Data Register
localparam pSPR = 4;    // Scratch Pad Register (and Aux. Status Registers)

//  TDR Bit Positions

localparam pTFC = 11;    // Tx FIFO Clear bit position
localparam pRFC = 10;    // Rx FIFO Clear bit position
localparam pHLD =  9;    // Tx SM Hold bit position

//  FIFO Parameters

localparam pTFLen = 0;   // Tx FIFO Len: (1 << (TFlen + 4))
localparam pRFLen = 3;   // Rx FIFO Len: (1 << (RFLen + 4))
localparam pWidth = 8;   // Maximum Character width
localparam pxFThr = 8;   // Default FIFO Threshold (Half Full)

//  SPR Sub-Addresses

localparam pRev   = 1;   // Revision Register:   {0, pVersion}
localparam pLen   = 2;   // Length Reg:          {0, pRFLen, pTFLen}
localparam pFThr  = 3;   // Rx/Tx FIFO Threshold:{0, RFThr[3:0], TFThr[3:0]}
localparam pTHR   = 4;   // Tx Holding Register: {0, THR[7:0]}
localparam pRHR   = 5;   // Rx Holding Register: {0, RHR[8:0]}
localparam pTFCnt = 6;   // Tx Count:            {0, TFCnt[(pTFLen + 4):0]}
localparam pRFCnt = 7;   // Rx Count:            {0, RFCnt[(pRFLen + 4):0]}

///////////////////////////////////////////////////////////////////////////////    
//
//  Local Signal Declarations
//

    wire    SCK;                    // Internal name for SSP_SCK
    
    wire    [2:0] RSel;             // Internal name for SSP_RA
    wire    Sel_TDR;                // Select - Transmit Data Register
    wire    Sel_RDR;                // Select - Receive Data Register
    wire    Sel_UCR;                // Select - UART Control Register
    wire    Sel_SPR;                // Select - Scratch Pad Register
    
    wire    [7:0] TD, THR;          // Transmit Data, Transmit Holding Register
    wire    TFC;                    // TDR: Transmit FIFO Clear
    reg     HLD;                    // TDR: Transmit Hold
    reg     TxHold;                 // Transmit Hold, synchronized to Clk
    wire    RE_THR;                 // Read Enable - Transmit Holding Register
    wire    WE_THR, ClrTHR;         // Write Enable - THR, Clear/Reset THR
    wire    TF_FF, TF_EF, TF_HF;    // Transmit FIFO Flags - Full, Empty, Half

    wire    [8:0] RD, RHR;          // Receive Data (In), Receive Holding Reg
    wire    RFC;                    // TDR: Receive FIFO Clear
    wire    WE_RHR;                 // Write Enable - RHR
    wire    RE_RHR, ClrRHR;         // Read Enable - RHR, Clear/Reset RHR
    wire    RF_FF, RF_EF, RF_HF;    // Receive FIFO Flags - Full, Empty, Half
    wire    [(pTFLen + 4):0] TFCnt; // Tx FIFO Count
    wire    [(pRFLen + 4):0] RFCnt; // RX FIFO Count
    
    reg     [ 7:0] TDR;             // Transmit Data Register
    wire    [11:0] RDR, USR;        // Receive Data Register, UART Status Reg
    reg     [11:0] UCR, SPR;        // UART Control Register, Scratch Pad Reg
    reg     [ 7:0] RTFThr;          // UART Rx/Tx FIFO Threshold Register
    
    wire    [1:0] MD;               // UCR: Operating Mode
    wire    RTSo, IE;               // UCR: RTS Output, Interrupt Enable
    wire    [3:0] FMT, Baud;        // UCR: Format, Baud Rate

    reg     Len, NumStop, ParEn;    // Char Length, # Stop Bits, Parity Enable
    reg     [1:0] Par;              // Parity Selector
    reg     [3:0] PS;               // Baud Rate Prescaler
    reg     [7:0] Div;              // Baud Rate Divider
    reg     [3:0] CCntVal;          // RTO Character Length: {10 | 11 | 12} - 1
    wire    [3:0] RTOVal;           // RTO Character Delay Value: (N - 1)
    
    wire    RTSi, CTSi;             // USR: RTS Input, CTS Input
    reg     [1:0] RS, TS;           // USR: Rcv Status, Xmt Status
    wire    iRTO;                   // USR: Receive Timeout Interrupt
    wire    iRDA;                   // USR: Receive Data Available Interrupt
    wire    iTHE;                   // USR: Transmit Half Empty Interrupt
    wire    iTFE;                   // USR: Transmit FIFO Empty Interrupt
    
    wire    Clr_Int;                // Clear Interrupt Flags - read of USR
    
    wire    WE_SPR;                 // Write Enable: Scratch Pad Register
    wire    WE_RTFThr;              // Write Enable: Rx/Tx FIFO Threshold Reg.
    reg     [11:0] SPR_DO;          // SPR Output Data
    
    wire    TxD;                    // UART TxD Output (Mode Multiplexer Input)
    reg     RxD;                    // UART RxD Input (Mode Multiplexer Output)
    
    wire    TRDY;                   // RDR: Transmit Ready
    wire    RRDY;                   // RDR: Receive Ready
    wire    RTO;                    // RDR: Receive Timeout
    wire    RERR;                   // RDR: Receive Error 
    
    wire    RcvTimeout;             // Receive Timeout
    
    wire    [7:0] Version = pVersion;
    wire    [3:0] TFLen   = pTFLen; // Len = (2**(pTFLen + 4))
    wire    [3:0] RFLen   = pRFLen;
    wire    [3:0] TFThr   = pxFThr; // Thr = pxFThr ? pxFThr * (2**pTFLen) : 1
    wire    [3:0] RFThr   = pxFThr;   

///////////////////////////////////////////////////////////////////////////////    
//
//  Implementation
//

assign SCK = SSP_SCK;

//  Assign SSP Read/Write Strobes

assign SSP_WE = SSP_SSEL &  SSP_WnR & SSP_EOC;
assign SSP_RE = SSP_SSEL & ~SSP_WnR & SSP_EOC;

//  Break out Register Select Address

assign RSel = SSP_RA;

assign Sel_TDR = (RSel == pTDR);
assign Sel_RDR = (RSel == pRDR);
assign Sel_USR = (RSel == pUSR);
assign Sel_UCR = (RSel == pUCR);
assign Sel_SPR = (RSel == pSPR);

//  Assign SPR Data Output based on sub-addresses: SPR[11:9]

always @(*)
begin
    case(SPR[11:9])
        pRev    : SPR_DO <= {4'b0, Version[7:0]};
        pLen    : SPR_DO <= {4'b0, RFLen[3:0], TFLen[3:0]};
        pFThr   : SPR_DO <= {4'b0, RTFThr};
        pTHR    : SPR_DO <= {4'b0, THR};
        pRHR    : SPR_DO <= {3'b0, RHR};
        pTFCnt  : SPR_DO <= {1'b0, TFCnt[(pTFLen + 4):0]};
        pRFCnt  : SPR_DO <= {1'b0, RFCnt[(pRFLen + 4):0]};
        default : SPR_DO <= SPR;
    endcase
end

//  Drive SSP Output Data Bus

always @(*)
begin
    case(RSel)
        pUCR    : SSP_DO <= ((SSP_SSEL) ? UCR                           : 0);
        pUSR    : SSP_DO <= ((SSP_SSEL) ? USR                           : 0);
        pTDR    : SSP_DO <= ((SSP_SSEL) ? TDR                           : 0);
        pRDR    : SSP_DO <= ((SSP_SSEL) ? RDR                           : 0);
        pSPR    : SSP_DO <= ((SSP_SSEL) ? SPR_DO                        : 0);
        default : SSP_DO <= ((SSP_SSEL) ? {1'b0, RFCnt[(pRFLen + 4):0]} : 0);
    endcase
end

//  Assert IRQ when IE is set

assign Rst_IRQ = Rst | Clr_Int;

always @(posedge Clk)
begin
    if(Rst_IRQ)
        IRQ <= 0;
    else if(~IRQ)
        IRQ <= #1 IE & (iTFE | iTHE | iRDA | iRTO);
end

///////////////////////////////////////////////////////////////////////////////
//
//  Write UART Control Register
//

assign WE_UCR = SSP_WE & Sel_UCR;

always @(negedge SCK or posedge Rst)
begin
    if(Rst)
        UCR <= #1 0;
    else if(WE_UCR)
        UCR <= #1 SSP_DI;
end

//  Assign UCR Fields

assign MD   = UCR[11:10];
assign RTSo = UCR[9];
assign IE   = UCR[8];
assign FMT  = UCR[7:4];
assign Baud = UCR[3:0];

//  Format Decode

always @(FMT)
case(FMT)
    4'b0000 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b0, 1'b0, 2'b00};   // 8N1
    4'b0001 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b0, 1'b0, 2'b00};   // 8N1
    4'b0010 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b0, 1'b1, 2'b00};   // 8O1
    4'b0011 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b0, 1'b1, 2'b01};   // 8E1
    4'b0100 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b0, 1'b1, 2'b10};   // 8S1
    4'b0101 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b0, 1'b1, 2'b11};   // 8M1
    4'b0110 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b0, 1'b0, 2'b00};   // 8N1
    4'b0111 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b1, 1'b0, 2'b00};   // 8N2
    4'b1000 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b1, 1'b1, 2'b00};   // 8O2
    4'b1001 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b1, 1'b1, 2'b01};   // 8E2
    4'b1010 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b1, 1'b1, 2'b10};   // 8S2
    4'b1011 : {Len, NumStop, ParEn, Par} <= {1'b0, 1'b1, 1'b1, 2'b11};   // 8M2
    4'b1100 : {Len, NumStop, ParEn, Par} <= {1'b1, 1'b0, 1'b1, 2'b00};   // 7O1
    4'b1101 : {Len, NumStop, ParEn, Par} <= {1'b1, 1'b0, 1'b1, 2'b01};   // 7E1
    4'b1110 : {Len, NumStop, ParEn, Par} <= {1'b1, 1'b1, 1'b1, 2'b00};   // 7O2
    4'b1111 : {Len, NumStop, ParEn, Par} <= {1'b1, 1'b1, 1'b1, 2'b01};   // 7E2
endcase

//  Baud Rate Generator's PS and Div for defined Baud Rates (48 MHz Oscillator)

always @(Baud)
begin
    case(Baud)
        4'b0000 : {PS, Div} <= {4'h0, 8'h01}; // PS= 1; Div=  2; BR=1.5M
        4'b0001 : {PS, Div} <= {4'h0, 8'h02}; // PS= 1; Div=  3; BR=1.0M
        4'b0010 : {PS, Div} <= {4'h0, 8'h05}; // PS= 1; Div=  6; BR=500.0k
        4'b0011 : {PS, Div} <= {4'h0, 8'h0F}; // PS= 1; Div= 16; BR=187.5k
        4'b0100 : {PS, Div} <= {4'hC, 8'h00}; // PS=13; Div=  1; BR=230.4k
        4'b0101 : {PS, Div} <= {4'hC, 8'h01}; // PS=13; Div=  2; BR=115.2k
        4'b0110 : {PS, Div} <= {4'hC, 8'h02}; // PS=13; Div=  3; BR= 76.8k
        4'b0111 : {PS, Div} <= {4'hC, 8'h03}; // PS=13; Div=  4; BR= 57.6k
        4'b1000 : {PS, Div} <= {4'hC, 8'h05}; // PS=13; Div=  6; BR= 38.4k
        4'b1001 : {PS, Div} <= {4'hC, 8'h07}; // PS=13; Div=  8; BR= 28.8k
        4'b1010 : {PS, Div} <= {4'hC, 8'h0B}; // PS=13; Div= 12; BR= 19.2k
        4'b1011 : {PS, Div} <= {4'hC, 8'h0F}; // PS=13; Div= 16; BR= 14.4k
        4'b1100 : {PS, Div} <= {4'hC, 8'h17}; // PS=13; Div= 24; BR=  9.6k
        4'b1101 : {PS, Div} <= {4'hC, 8'h2F}; // PS=13; Div= 48; BR=  4.8k
        4'b1110 : {PS, Div} <= {4'hC, 8'h5F}; // PS=13; Div= 96; BR=  2.4k
        4'b1111 : {PS, Div} <= {4'hC, 8'hBF}; // PS=13; Div=192; BR=  1.2k
    endcase
end

//  Receive Timeout Character Frame Length

always @(FMT)
case(FMT)
    4'b0000 : CCntVal <= 4'h9;   // 8N1,  9 <= 10 - 1
    4'b0001 : CCntVal <= 4'h9;   // 8N1,  9 <= 10 - 1
    4'b0010 : CCntVal <= 4'hA;   // 8O1, 10 <= 11 - 1
    4'b0011 : CCntVal <= 4'hA;   // 8E1, 10 <= 11 - 1
    4'b0100 : CCntVal <= 4'hA;   // 8S1, 10 <= 11 - 1
    4'b0101 : CCntVal <= 4'hA;   // 8M1, 10 <= 11 - 1
    4'b0110 : CCntVal <= 4'h9;   // 8N1,  9 <= 10 - 1
    4'b0111 : CCntVal <= 4'hA;   // 8N2, 10 <= 11 - 1
    4'b1000 : CCntVal <= 4'hB;   // 8O2, 11 <= 12 - 1
    4'b1001 : CCntVal <= 4'hB;   // 8E2, 11 <= 12 - 1
    4'b1010 : CCntVal <= 4'hB;   // 8S2, 11 <= 12 - 1
    4'b1011 : CCntVal <= 4'hB;   // 8M2, 11 <= 12 - 1
    4'b1100 : CCntVal <= 4'h9;   // 7O1,  9 <= 10 - 1
    4'b1101 : CCntVal <= 4'h9;   // 7E1,  9 <= 10 - 1
    4'b1110 : CCntVal <= 4'h9;   // 7O2,  9 <= 10 - 1
    4'b1111 : CCntVal <= 4'h9;   // 7E2,  9 <= 10 - 1
endcase

assign RTOVal = (pRTOChrDlyCnt - 1);    // Set RTO Character Delay Count

///////////////////////////////////////////////////////////////////////////////
//
//  USR Register and Operations
//

always @(*)
begin
    case({RF_FF, RF_HF, RF_EF})
        3'b000 : RS <= 2'b01;   // Not Empty, < Half Full
        3'b001 : RS <= 2'b00;   // Empty
        3'b010 : RS <= 2'b10;   // > Half Full, < Full
        3'b011 : RS <= 2'b00;   // Not Possible/Not Allowed
        3'b100 : RS <= 2'b00;   // Not Possible/Not Allowed
        3'b101 : RS <= 2'b00;   // Not Possible/Not Allowed
        3'b110 : RS <= 2'b11;   // Full
        3'b111 : RS <= 2'b00;   // Not Possible/Not Allowed
    endcase
end

always @(*)
begin
    case({TF_FF, TF_HF, TxIdle})
        3'b000 : TS <= 2'b01;   // Not Empty, < Half Full
        3'b001 : TS <= 2'b00;   // Empty
        3'b010 : TS <= 2'b10;   // > Half Full, < Full
        3'b011 : TS <= 2'b00;   // Not Possible/Not Allowed
        3'b100 : TS <= 2'b00;   // Not Possible/Not Allowed
        3'b101 : TS <= 2'b00;   // Not Possible/Not Allowed
        3'b110 : TS <= 2'b11;   // Full
        3'b111 : TS <= 2'b00;   // Not Possible/Not Allowed
    endcase
end

assign USR = {MD, RTSi, CTSi, RS, TS, iRTO, iRDA, iTHE, iTFE};

//  Read UART Status Register

re1ce   RED1 (
            .den(Sel_USR),
            .din(~SCK), 
            .clk(Clk),
            .rst(Rst), 
            .trg(),
            .pls(Clr_Int)
        );

///////////////////////////////////////////////////////////////////////////////
//
//  TDR/RDR Registers and Operations
//

//  Write Transmit Data Register

assign WE_TDR = SSP_WE & Sel_TDR & TRDY;

always @(posedge SCK or posedge Rst)
begin
    if(Rst)
        TDR <= #1 8'b0;
    else if(WE_TDR)
        TDR <= #1 SSP_DI[7:0];
end

assign TD = TDR;

//  Clear Transmit Holding Register

assign TFC = SSP_DI[pTFC] & WE_TDR;

re1ce   RED2 (
            .den(TFC),
            .din(SCK), 
            .clk(Clk),
            .rst(Rst), 
            .trg(),
            .pls(ClrTHR)
        );

//  Clear Receive Holding Register

assign RFC = SSP_DI[pRFC] & WE_TDR;

re1ce   RED3 (
            .den(RFC), 
            .din(SCK), 
            .clk(Clk),
            .rst(Rst), 
            .trg(),
            .pls(ClrRHR)
        );

//  Latch the Transmit Hold Bit on writes to TDR

always @(posedge SCK or posedge Rst)
begin
    if(Rst)
        HLD <= #1 0;
    else if(WE_TDR)
        HLD <= #1 SSP_DI[pHLD];
end

//  Write Transmit Holding Register (FIFO)

re1ce   RED4 (
            .den(WE_TDR),
            .din(SCK), 
            .clk(Clk),
            .rst(Rst), 
            .trg(),
            .pls(WE_THR)
        );

//  Set TxHold when the THR is written
           
always @(posedge Clk)
begin
    if(Rst)
        TxHold <= #1 0;
    else if(WE_THR)
        TxHold <= #1 HLD;
end

//  Read Receive Data Register

assign TRDY = ~TF_FF;
assign RRDY = ~RF_EF;
assign RTO  = RcvTimeout;
assign RERR = RHR[8];

assign RDR  = {TRDY, RRDY, RTO, RERR, RHR[7:0]};            

//  Read Receive Holding Register

assign RE_RDR = SSP_RE & Sel_RDR & RRDY;

re1ce   RED5 (
            .den(RE_RDR), 
            .din(SCK), 
            .clk(Clk),
            .rst(Rst), 
            .trg(),
            .pls(RE_RHR)
        );

///////////////////////////////////////////////////////////////////////////////
//
//  Write Scratch Pad Register
//

assign WE_SPR = SSP_WE & Sel_SPR;

always @(posedge SCK or posedge Rst)
begin
    if(Rst)
        SPR <= #1 0;
    else if(WE_SPR)
        SPR <= #1 SSP_DI;
end

assign WE_RTFThr = SSP_WE & Sel_SPR & (SSP_DI[11:9] == pFThr) & SSP_DI[8];

always @(posedge SCK or posedge Rst)
begin
    if(Rst)
        RTFThr <= #1 {RFThr, TFThr};
    else if(WE_RTFThr)
        RTFThr <= #1 SSP_DI;
end

///////////////////////////////////////////////////////////////////////////////
//
//  Xmt/Rcv Holding Register Instantiations - Dual-Port Synchronous FIFOs
//
//  THR FIFO - 64x8 FIFO

DPSFnmCE    #(
                .addr((pTFLen + 4)),
                .width(pWidth),
                .init("Src/UART_TF.coe")
            ) TF1 (
                .Rst(Rst | ClrTHR), 
                .Clk(Clk), 
                .WE(WE_THR), 
                .RE(RE_THR), 
                .DI(TD), 
                .DO(THR), 
                .FF(TF_FF),
                .HF(TF_HF), 
                .EF(TF_EF), 
                .Cnt(TFCnt)
            );

//  RHR FIFO - 128x9 FIFO

DPSFnmCE    #(
                .addr((pRFLen + 4)),
                .width((pWidth + 1)),
                .init("Src/UART_RF.coe")
            ) RF1 (
                .Rst(Rst | ClrRHR), 
                .Clk(Clk), 
                .WE(WE_RHR), 
                .RE(RE_RHR), 
                .DI(RD), 
                .DO(RHR), 
                .FF(RF_FF),
                .HF(RF_HF), 
                .EF(RF_EF), 
                .Cnt(RFCnt)
            );

/*
BRSFmnCE    #(
                .pAddr((pTFLen + 4)), 
                .pWidth(pWidth), 
                .pRAMInitSize(0)
            ) TF1 (
                .Rst(Rst | ClrTHR), 
                .Clk(Clk),
                .Clr(ClrTHR),
                .Thr(RTFThr[3:0]),
                .WE(WE_THR), 
                .DI(TD),
                .RE(RE_THR),
                .DO(THR),
                .ACK(),
                .FF(TF_FF),
                .AF(),
                .HF(TF_HF),
                .AE(),
                .EF(TF_EF),
                .Cnt(TFCnt)
            );

BRSFmnCE    #(
                .pAddr((pRFLen + 4)), 
                .pWidth((pWidth + 1)), 
                .pRAMInitSize(128)
            ) RF1 (
                .Rst(Rst), 
                .Clk(Clk),
                .Clr(ClrRHR),
                .Thr(RTFThr[7:4]),
                .WE(WE_RHR), 
                .DI(RD),
                .RE(RE_RHR),
                .DO(RHR),
                .ACK(),
                .FF(RF_FF),
                .AF(),
                .HF(RF_HF),
                .AE(),
                .EF(RF_EF),
                .Cnt(RFCnt)
            );
*/
                 
///////////////////////////////////////////////////////////////////////////////
//
//  Configure external/internal serial port signals according to MD[1:0]
//      MD[1:0] = 0,1 - RS-233; 2,3 - RS-485

assign RS232 = ~MD[1];
assign RS485 =  MD[1];

//  Set RS-232/Rs-485 TxD

assign TxD_232 = (RS232 ? TxD : 1);
assign TxD_485 = (RS485 ? TxD : 1);

//  Assert DE in the RS-485 modes whenever the TxSM is not idle, and deassert
//      whenever the RS-485 modes are not selected

assign xDE = (RS485 ? ~TxIdle : 0);

//  Connect the UART's RxD serial input to the appropriate external RxD input
//      Hold RxD to logic 1 when in the RS-485 w/o Loopback mode and the TxSM
//      is transmitting data. In this manner, the external xOE signal to the 
//      RS-485 transceiver can always be asserted.

always @(posedge Clk or posedge Rst)
begin
    if(Rst)
        RxD <= #1 1;
    else
        case(MD)
            2'b00 : RxD <= #1 RxD_232;
            2'b01 : RxD <= #1 RxD_232;
            2'b10 : RxD <= #1 (TxIdle ? RxD_485 : 1);
            2'b11 : RxD <= #1 RxD_485;
        endcase
end

// RS-232 auto-Handshaking is implemented as Ready-To-Receive (RTR) based on
//      the Rcv FIFO flag settings. xRTS, which should connect to the receiving
//      side's xCTS, is asserted whenever the local receive FIFO is less than 
//      half full. If a similar UART with hardware handshaking is connected,
//      then that transmitter should stop sending until the local FIFO is read
//      so that it is below the HF mark. Since local reads of the receive FIFO
//      are expected to be much faster than the RS-232 baud rate, it is not 
//      expected that hysteresis will be required to prevent rapid assertion
//      and deassertion of RTS.
//
//      This handshaking mechanism was selected for the automatic handshaking
//      mode because it prevents (or attempts to prevent) receive FIFO over-
//      flow in the receiver. Furthermore, it reduces the software workload in
//      the transmitter's send routines.
//
//      For all other modes, the CTSi control signal to the UART_TXSM is held
//      at logic one. This effectively disables the TxSM's handshaking logic,
//      and allows the transmitter to send data as soon as data is written to
//      Xmt FIFO.

always @(*)
begin
    case(MD)
        2'b00 : xRTS <= RTSo;
        2'b01 : xRTS <= ~RF_HF;
        2'b10 : xRTS <= 0;
        2'b11 : xRTS <= 0;
    endcase
end

assign RTSi = ((RS232) ? xRTS : xDE);
assign CTSi = ((MD == 1) ? xCTS : 1);

///////////////////////////////////////////////////////////////////////////////
//
//  UART Baud Rate Generator Instantiation
//

UART_BRG    BRG (
                .Rst(Rst), 
                .Clk(Clk), 
                .PS(PS), 
                .Div(Div), 
                .CE_16x(CE_16x)
            );

///////////////////////////////////////////////////////////////////////////////
//
//  UART Transmitter State Machine & Shift Register Instantiation
//

UART_TXSM   XMT (
                .Rst(Rst), 
                .Clk(Clk), 
                
                .CE_16x(CE_16x), 
                
                .Len(Len), 
                .NumStop(NumStop), 
                .ParEn(ParEn), 
                .Par(Par),
                
                .TF_RE(RE_THR), 
                .THR(THR), 
                .TF_EF(TF_EF | TxHold), 
                
                .TxD(TxD), 
                .CTSi(CTSi), 
            
                .TxIdle(TxIdle), 
                .TxStart(), 
                .TxShift(), 
                .TxStop()
            );

///////////////////////////////////////////////////////////////////////////////
//
//  UART Receiver State Machine & Shift Register Instantiation
//

UART_RXSM   RCV (
                .Rst(Rst), 
                .Clk(Clk), 
                
                .CE_16x(CE_16x),
                
                .Len(Len), 
                .NumStop(NumStop), 
                .ParEn(ParEn), 
                .Par(Par),
                
                .RxD(RxD), 
                
                .RD(RD), 
                .WE_RHR(WE_RHR), 
                
                .RxWait(), 
                .RxIdle(RxIdle), 
                .RxStart(), 
                .RxShift(), 
                .RxParity(), 
                .RxStop(), 
                .RxError()
            );

///////////////////////////////////////////////////////////////////////////////
//
//  UART Receive Timeout Module Instantiation
//

UART_RTO    TMR (
                .Rst(Rst), 
                .Clk(Clk),
                
                .CE_16x(CE_16x),
                
                .WE_RHR(WE_RHR), 
                .RE_RHR(RE_RHR),
                
                .CCntVal(CCntVal), 
                .RTOVal(RTOVal),
                
                .RcvTimeout(RcvTimeout)
            );

///////////////////////////////////////////////////////////////////////////////
//
//  UART Interrupt Generator Instantiation
//

UART_INT    INT (
                .Rst(Rst), 
                .Clk(Clk), 
                .TF_HF(TF_HF), 
                .TF_EF(TF_EF), 
                .RF_HF(RF_HF), 
                .RF_EF(RF_EF),
                .RTO(RTO), 
                .Clr_Int(Clr_Int),
                .iTFE(iTFE), 
                .iTHE(iTHE), 
                .iRDA(iRDA), 
                .iRTO(iRTO)
            );

endmodule