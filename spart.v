//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module spart(
    input clk,
    input rst,
    input iocs,
    input iorw,
    output rda,
    output tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
);

    // Internal signals
    wire en_baud, clr_baud;
    wire baud_clk;
    wire en_tx, en_rx;
    wire [7:0] rx_data;

    // Baud rate generator enable and clear logic
    assign en_baud = (en_tx || en_rx || (ioaddr == 2'b10 || ioaddr == 2'b11)) ? 1'b1 : 1'b0; // Enable for Division Buffers
    assign clr_baud = ((iocs == 1'b0) && (en_rx == 1'b0)) ? 1'b1 : 1'b0; // Clear when SPART is not selected

    // Instantiate the baud rate generator
    spart_baud_gen BAUD_GEN(
        .clk(clk),
        .rst(rst),
        .ioaddr(ioaddr),
        .databus(databus),
        .en(en_baud),
        .clr(clr_baud),
        .baud_clk(baud_clk)
    );

    // Transmit logic
    assign en_tx = (iocs && ioaddr == 2'b00 && iorw == 1'b0) ? 1'b1 : 1'b0; // Enable TX when writing to Transmit Buffer

    spart_tx TX(
        .clk(clk),
        .rst(rst),
        .en(en_tx),
        .baud_clk(baud_clk),
        .tx_data(databus),
        .txd(txd),
        .tbr(tbr)
    );

    // Receive logic
    //assign en_rx = (iocs && ioaddr == 2'b00 && iorw == 1'b1) ? 1'b1 : 1'b0; // Enable RX when reading from Receive Buffer

    spart_rx RX(
        .clk(clk),
        .rst(rst),
        .en(en_rx),
        .baud_clk(baud_clk),
        .rx_data(rx_data),
        .rxd(rxd),
        .rda(rda)
    );

    // DATABUS control for reading received data
    assign databus = (iocs && ioaddr == 2'b00 && iorw == 1'b1) ? rx_data : 8'bzzzzzzzz;

endmodule
