`timescale 1 ps / 1 ps
module spart_tb();
    reg clk;
    reg rst_n;
    reg iocs0, iocs1;
    reg iorw0, iorw1;
    reg rda0, rda1;
    reg tbr0, tbr1;
    reg  [1:0] ioaddr0, ioaddr1;
    wire  [7:0] databus0, databus0_spart, databus0_driver, databus1_spart;
    reg  txd0, txd1;
    reg  rxd0,rxd1;
    reg en;
    reg [1:0] br_cfg0;

spart spart0(
    .clk(clk),
    .rst(rst_n),
    .iocs(iocs0),
    .iorw(iorw0),
    .rda(rda0),
    .tbr(tbr0),
    .ioaddr(ioaddr0),
    .databus(databus0),
    .txd(txd0),
    .rxd(txd1)
    );

 spart spart1(
    .clk(clk),
    .rst(rst_n),
    .iocs(iocs1),
    .iorw(iorw1),
    .rda(rda1),
    .tbr(tbr1),
    .ioaddr(ioaddr1),
    .databus(databus1),
    .txd(txd1),
    .rxd(txd0)
    );   

driver driver0(
    .clk(clk),
    .rst_n(rst_n),
    .br_cfg(br_cfg0),
    .iocs(iocs0),
    .iorw(iorw0),
    .rda(rda0),
    .tbr(tbr0),
    .ioaddr(ioaddr0),
    .databus(databus0)
);

assign databus1_spart = (iorw1) ? 8'hAB : 'z;
assign databus0 = (iorw0) ? databus0_spart : databus0_driver;

initial begin
    clk = 0;
    forever #20 clk = ~clk;
end
  
  initial begin
    // Initialize signals
    rst_n = 0;     

    br_cfg0   = 2'b00;

    // Hold reset for a few clock cycles
    #20;
    rst_n = 1;           
    br_cfg0   = 4'b00;  
    ioaddr1 = 2'b00;
    iocs1 = 1'b0;
    iorw1 = 1'b0;

    @ (posedge rda1);
    assert (databus1 == databus0) 
    else $error("Assertion failed: databus1=%0d, expected=%0d at time %0t", databus1, databus0, $time);
    #50;

    // End simulation after a short delay.
    $stop;
  end

endmodule