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
    reg [7:0] input_bus;

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

    // Test Data Assignment
    assign databus1_spart = (~iorw1) ? input_bus : 'z;

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
        
		repeat(5) @(posedge clk);
        // =========================
        // First Test (0xAB)
        // =========================
        input_bus = 8'hAB;
        ioaddr1 = 2'b00;
        iocs1 = 1'b1;
        iorw1 = 1'b0; // Write operation

        @(posedge tbr1);
        iocs1 = 1'b0;
        iorw1 = 1'b1; // End write

       // @(posedge rda0); // Wait for data ready
	   @(posedge driver0.current_state == 3'd4);
        //repeat(2) @(posedge clk);
        #10;
        if (databus0 == 8'hAB) begin
            $display("PASSED 1st transmission: 8'hAB matches databus0=%0h at time %0t", databus0, $time);
        end else begin
            $error("FAILED 1st transmission: databus0=%0h, expected=8'hAB at time %0t", databus0, $time);
        end

        @(posedge rda1); // Wait for spart1 to be ready
        repeat(2) @(posedge clk);

        if (spart1.rx_data == 8'hAB) begin
            $display("PASSED 2nd transmission: spart1 received 8'hAB at time %0t", $time);
        end else begin
            $error("FAILED 2nd transmission: rx_data=%0h, expected=8'hAB at time %0t", spart1.rx_data, $time);
        end

        // =========================
        // Second Test (0xCD)
        // =========================
        input_bus = 8'hCD;
        ioaddr1 = 2'b00;
        iocs1 = 1'b1;
        iorw1 = 1'b0;

        @(posedge tbr1);
        iocs1 = 1'b0;
        iorw1 = 1'b1;

        //@(posedge rda0);
		@(posedge driver0.current_state == 3'd4);
       // repeat(2) @(posedge clk);
        #10;
        if (databus0 == 8'hCD) begin
            $display("PASSED 3rd transmission: 8'hCD matches databus0=%0h at time %0t", databus0, $time);
        end else begin
            $error("FAILED 3rd transmission: databus0=%0h, expected=8'hCD at time %0t", databus0, $time);
        end

        @(posedge rda1);
        repeat(2) @(posedge clk);

        if (spart1.rx_data == 8'hCD) begin
            $display("PASSED 4th transmission: spart1 received 8'hCD at time %0t", $time);
        end else begin
            $error("FAILED 4th transmission: rx_data=%0h, expected=8'hCD at time %0t", spart1.rx_data, $time);
        end

       // repeat(10) @(posedge clk);
       // $stop;
    //end
	// no delay in between tests
		// =========================
        // Third Test (0x50)
        // =========================
        input_bus = 8'h50;
        ioaddr1 = 2'b00;
        iocs1 = 1'b1;
        iorw1 = 1'b0;

        @(posedge tbr1);
        iocs1 = 1'b0;
        iorw1 = 1'b1;

        //@(posedge rda0);
		@(posedge driver0.current_state == 3'd4);
       // repeat(2) @(posedge clk);
        #10;
        if (databus0 == 8'h50) begin
            $display("PASSED 5th transmission: 8'h50 matches databus0=%0h at time %0t", databus0, $time);
        end else begin
            $error("FAILED 5th transmission: databus0=%0h, expected=8'h50 at time %0t", databus0, $time);
        end

        @(posedge rda1);
        repeat(2) @(posedge clk);

        if (spart1.rx_data == 8'h50) begin
            $display("PASSED 6th transmission: spart1 received 8'h50 at time %0t", $time);
        end else begin
            $error("FAILED 6th transmission: rx_data=%0h, expected=8'h50 at time %0t", spart1.rx_data, $time);
        end

        repeat(10) @(posedge clk);
        $stop;
    end

endmodule
