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
wire en_baud, clr_baud;
assign en_baud = (ioaddr == 2'b00) ? 1'b1 : 1'b0;
assign clr_baud = (iocs == 1'b0) ? 1'b0 : 1'b1;
spart_baud_gen BAUD_GEN(
    .clk(clk),
    .rst_n(rst),
    .ioaddr(ioaddr) ,
    .databus(databus),
    .en(en_baud),
    .clr(clr_baud),
    .baud_clk(baud_clk)
);
assign en_tx = (ioaddr == 2'b00) ? (iorw == 1'b0) ? 1'b1 : 1'b0 : 1'b0;
spart_tx TX(
    .clk(clk),
    .rst_n(rst),
    .en(en_tx),
    .baud_clk(baud_clk),
    .tx_data(databus),
    .txd(txd),
    .tbr(tbr)
);
assign en_tx = (ioaddr == 2'b00) ? (iorw == 1'b1) ? 1'b1 : 1'b0 : 1'b0;
spart_rx RX(
    .clk(clk),
    .rst_n(rst),
    .en(en_rx),
    .baud_clk(baud_clk),
    .rx_data(rx_data),
    .rxd(rxd),
    .rda(rda)
);
assign databus = rda == 1'b1 ? rx_data : databus;

endmodule
