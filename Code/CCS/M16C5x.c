#include <M16C5x.h>

int PortA, PortB, PortC;

#byte PortA         = 0x05
#byte PortB         = 0x06
#byte PortC         = 0x07

#bit  SPI_SR_TF_EF  = 5.0
#bit  SPI_SR_TF_FF  = 5.1
#bit  SPI_SR_RF_EF  = 5.2
#bit  SPI_SR_RF_FF  = 5.3

int SPI_SR;
int Dly_Cntr;
int SPI_Cmd, SPI_Addr[3];
int SPI_CR, SPI_DIO_H, SPI_DIO_L, xSPI_CR;

#byte SPI_SR        = 0x05      // Port A data input is SPI IF Status Register
#byte Dly_Cntr      = 0x10      // Delay Counter
#byte SPI_Cmd       = 0x18      // SPI Command Buffer
#byte SPI_Addr      = 0x19      // SPI Address Buffer
#byte SPI_CR        = 0x1C      // Holding Register for SPI Control Register
#byte SPI_DIO_H     = 0x1D      // Holding Register for UART Rd Data High
#byte SPI_DIO_L     = 0x1E      // Holding Register for UART Rd Data Low
#byte xSPI_CR       = 0x1F      // Holding Register for Ext SPI Configuration

#bit  SPI_CR_REn    = 0x1C.0    // Receive Enable
#bit  SPI_CR_SSel   = 0x1C.1    // Internal SPI: 1; External SPI: 0
#bit  SPI_CR_MD0    = 0x1C.2    // SPI Mode: 0, 1, 2, 3
#bit  SPI_CR_MD1    = 0x1C.3
#bit  SPI_CR_BR0    = 0x1C.4    // SPI SCK Bit Rate: 48MHz/(2**(BR + 1))
#bit  SPI_CR_BR1    = 0x1C.5
#bit  SPI_CR_BR2    = 0x1C.6
#bit  SPI_CR_DIR    = 0x1C.7    // SPI Shift Direction: 0 - MSB; 1 - LSB

#bit  SPI_DIO_RRdy  = 0x1D.2    // UART Rx Data Ready Bit
#bit  SPI_DIO_RErr  = 0x1D.0    // UART Rx Data Error Bit

#bit  RD_Ext_ASCII  = 0x1E.7    // MSB of ASCII data from UART

#bit  xSPI_Manual   = 0x1F.7    // Enables manual assertion of nCS[1:0]
#bit  xSPI_MRAM     = 0x1F.6    // Enables External SPI MRAM CS
#bit  xSPI_Flash    = 0x1F.5    // Enables External SPI Flash CS

#define COM0 0x00               // UART #1: SSP[15] = RA[2] = 0
#define COM1 0x80               // UART #2: SSP[15] = RA[2] = 1

#define FLSH 0x20               // TRIS A.5 Selects External SPI Flash
#define MRAM 0x40               // TRIS A.6 selects External SPI MRAM

#define READ  0x03              // Read
#define WRENA 0x06              // Write Enable
#define WRITE 0x02              // Write Page (256)
#define WRDIS 0x04              // Write Disable
#define VSRWE 0x50              // Volatile SR Write Enable
#define RDSR1 0x05              // Read Status Register #1
#define WRSR1 0x01              // Write Status Register #1
#define RDSR2 0x35              // Read Status register #2
#define WRSR2 0x31              // Write Status Register #2
#define RDSR3 0x15              // Read Status Register #3
#define WRSR3 0x11              // Write Status Register #3
#define ERASE 0xC7              // Chip Erase (0xC7/0x60)
#define EPSUS 0x75              // Erase/Program Suspend
#define EPRES 0x7A              // Erase/Program Resume
#define PWRDN 0xB9              // Power Down
#define RLSPD 0xAB              // Release Power Down (plus ID)
#define MANID 0x90              // Manufacturer/Device ID
#define JEDID 0x9F              // JEDEC ID (MAN ID/ID[15:0]
#define GLBLK 0x7E              // Global Block Lock
#define GLBUL 0x98              // Global Block Unlock
#define ENRST 0x66              // Enable Reset
#define RESET 0x99              // Reset Device
#define RDUID 0x4B              // Read Unique ID
#define ERA04 0x20              // Sector Erase (4kB)
#define ERA32 0x52              // Block Erase (32kB)
#define ERA64 0xD8              // Block Erase (64kB)
#define FASTR 0x0B              // Fast Read
#define RSFDP 0x5A              // Read SFDP Register
#define ERSEC 0x44              // Erase Security Register
#define WRSEC 0x42              // Write/Program Security Register
#define RDSEC 0x48              // Read Security Register
#define LKIBL 0x36              // Lock Individual Block
#define ULIBL 0x39              // Unlock Individual Block
#define RDBLK 0x3D              // Read Block Lock

#use fast_io(ALL)

void set_baud(int port)
{
    SPI_CR_REn  = 0;
    SPI_CR_SSel = 1;
    set_tris_C(SPI_CR);
    
    PortC = (port ^ 0x13);
    PortC = 0x00;
    PortC = (port ^ 0x30);
    PortC = 0x01;

    while(~SPI_SR_TF_EF);
}

int1 get_char(int port)
{
    SPI_CR_REn  = 1;
    SPI_CR_SSel = 1;
    set_tris_C(SPI_CR);
    
    PortC = (port ^ 0x60); PortC = 0xFF;
    
    while(~SPI_SR_TF_EF); SPI_DIO_H = PortC;
    while( SPI_SR_RF_EF); SPI_DIO_L = PortC;
    
    return(SPI_DIO_RRdy && ~SPI_DIO_RErr);
}

void put_char(int port)
{
        // Process received data - lc to uc and uc to lc, otherwise unchanged
        
        if(~RD_Ext_ASCII) {     // if Extended ASCII data, skip conversion
            if((SPI_DIO_L >= 'A') && (SPI_DIO_L <= 'z')) {
                if((SPI_DIO_L <= 'Z') || (SPI_DIO_L >= 'a')) {
                    SPI_DIO_L ^= 0x20;
                }
            }
        }
        
        // Write processed data to UART transmit FIFO

        SPI_CR_REn  = 0;
        SPI_CR_SSel = 1;
        set_tris_C(SPI_CR);
        
        PortC = (port ^ 0x50); PortC = SPI_DIO_L;    // Transmit data
        
        while(~SPI_SR_TF_EF);
}

void xSPI_Manual(int Manual)
{
    if(Manual) xSPI_CR |= 0x80; else xSPI_CR &= ~0x80;
    set_tris_A(xSPI_CR);
}

void put_SPI_data24(int data[3])
{
    SPI_CR_REn = 0;
    set_tris_C(SPI_CR);
    
    while(SPI_SR_TF_FF); PortC = data[2];
    while(SPI_SR_TF_FF); PortC = data[1];
    while(SPI_SR_TF_FF); PortC = data[0];
}

void put_SPI_data16(int data[2])
{
    SPI_CR_REn = 0;
    set_tris_C(SPI_CR);
    
    while(SPI_SR_TF_FF); PortC = data[1];
    while(SPI_SR_TF_FF); PortC = data[0];
}

void put_SPI_data08(int data)
{
    SPI_CR_REn = 0;
    set_tris_C(SPI_CR);
    
    while(SPI_SR_TF_FF); PortC = data;
}

void get_SPI_data16(void)
{
    while(~SPI_SR_TF_EF);
    
    SPI_CR_REn = 1;
    set_tris_C(SPI_CR);
    
    PortC = 0xFF; PortC = 0xFF;

    while(~SPI_SR_TF_EF); SPI_DIO_H = PortC;
    while( SPI_SR_RF_EF); SPI_DIO_L = PortC;
}

void get_SPI_data08(void)
{
    while(~SPI_SR_TF_EF);
    
    SPI_CR_REn  = 1;
    set_tris_C(SPI_CR);
    
    PortC = 0xFF;

    while(~SPI_SR_TF_EF); SPI_DIO_L = PortC;
}


void main()
{
    set_tris_A(0x1F);
    set_tris_B(0x1F);
    xSPI_CR = 0x1F;
    
    set_tris_C(0x1E);
    SPI_CR = 0x1E;

    Dly_Cntr = 8;
    while(--Dly_Cntr > 0);
    
    set_baud(COM0);
    set_baud(COM1);
    
    while(TRUE) {
        if(get_char(COM0)) {
            put_char(COM0);
        }    
        
        if(get_char(COM1)) {
            put_char(COM1);
        }    
    }

}
