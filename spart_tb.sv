`timescale 1 ps / 1 ps
module spart_tb();
    // Declare signals
    reg clk;
    reg rst_n;
    reg iocs0, iocs1;
    reg iorw0, iorw1;
    reg rda0, rda1;
    reg tbr0, tbr1;
    reg [1:0] ioaddr0, ioaddr1;
    wire [7:0] databus0, databus1_spart;
    reg txd0, txd1;
    reg rxd0, rxd1;
    reg en;
    reg [1:0] br_cfg0;

    // Instantiate the modules
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
        .databus(databus1_spart),
        .txd(txd1),
        .rxd(txd0)
    );

    driver driver0(
        .clk(clk),
        .rst(rst_n),
        .br_cfg(br_cfg0),
        .iocs(iocs0),
        .iorw(iorw0),
        .rda(rda0),
        .tbr(tbr0),
        .ioaddr(ioaddr0),
        .databus(databus0)
    );

    // Test Data Assignment (for read/write)
    assign databus1_spart = (~iorw1) ? 8'hAB : 'z;

    // Clock generation
    initial begin
        clk = 0;
        forever #20 clk = ~clk; // 50 MHz clock
    end

    // Testbench initial block
    initial begin
        // Initialize signals
        rst_n = 0;
        br_cfg0 = 2'b00;

        // Hold reset for a few clock cycles
        repeat(2) @(posedge clk);
        rst_n = 1; // Release reset
        br_cfg0 = 2'b00; // Initial baud rate configuration

        // Set up addresses and control signals for first transmission
        ioaddr1 = 2'b00;
        iocs1 = 1'b1;    // Assert I/O chip select
        iorw1 = 1'b0;    // Indicate write/tx operation

        // Wait for tbr1 to trigger (transmit buffer ready for transmission)
        @(posedge tbr1);
        iocs1 = 1'b0;    // Deassert chip select
        iorw1 = 1'b1;    // deassert write/tx operation

        // Wait for rda0 to be set high indicating data is ready for reception
        @(posedge rda0);
        repeat(3) @(posedge clk); // Wait for 3 clock cycles

        // Assert and check databus values
        if (databus0 == 8'hAB) begin
            $display("PASSED 1st transmission: 8'hAB matches databus0=%0h at time %0t", databus0, $time);
            repeat(2) @(posedge clk);
        end else begin
            $error("Failed 1st transmission: databus0=%0h, expected=%0h at time %0t", databus0, 8'hAB, $time);
            repeat(3) @(posedge clk);
        end

        // Second transmission check
        // Wait for rda1 signal to indicate the reception is ready for validation
        @(posedge rda1);
        

        repeat(3) @(posedge clk); // Wait for 3 clock cycles to ensure data stability

        // Check if spart1 correctly received the expected data
        if (spart1.rx_data == 8'hAB) begin
            $display("PASSED 2nd transmission: spart1 received correct data rx_data=%0h at time %0t", spart1.rx_data, $time);
            repeat(2) @(posedge clk); 
        end else begin
            $error("Failed 2nd transmission: rx_data=%0h, expected=%0h at time %0t", spart1.rx_data, 8'hAB, $time);
            repeat(3) @(posedge clk);
        end

        // End the simulation with a delay
        $stop;
    end

endmodule
