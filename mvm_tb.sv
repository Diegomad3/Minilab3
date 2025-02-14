`timescale 1 ps / 1 ps

module MVM_tb;
  parameter DATA_WIDTH = 8;
  parameter NUM_MAC    = 8;               // Number of MAC units (and FIFOs)
  parameter DEPTH      = 8;               // Number of memory rows to process
  parameter ACC_WIDTH  = DATA_WIDTH * 3;  // MAC accumulator width (24 bits)

  reg         clk;
  reg         rst_n;
  reg         Clr;
  reg  [3:0]  KEY;

  // Output from MAC array; each MAC outputs ACC_WIDTH bits
  wire [ACC_WIDTH-1:0] result [0:NUM_MAC-1];
 MVM #(
    .DATA_WIDTH(DATA_WIDTH),
    .NUM_MAC(NUM_MAC),
    .DEPTH(DEPTH)
  ) dut (
    .clk    (clk),
    .rst_n  (rst_n),
    .Clr    (Clr),
    .KEY    (KEY),
    .result (result)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    // Initialize signals
    rst_n = 0;     
    Clr   = 0;
    KEY   = 4'b0000;

    // Hold reset for a few clock cycles
    #20;
    rst_n = 1;           
    KEY   = 4'b0001;  

    // Wait for the design to initialize and fill the FIFOs from memory.
    #100;

    

    // Wait enough time for the entire operation to complete.
    #5000;
    // End simulation after a short delay.
    $finish;
  end

endmodule
