module spart_baud_gen(
    input clk,
    input rst,
    input [1:0] ioaddr,
    input [7:0] databus,
    input en,
    input clr,
    output baud_clk
)
    reg [15:0] baud_buffer_divisor //Value to count down from for the baud rate. 
    reg [15:0] baud_cnt;           // Counter for baud rate timing
    reg [3:0]  bit_cnt;            // Counter to track the number of bits sent

    // Set or update the Baud rate of the spart.
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            baud_buffer_divisor <= 16'h0000;      // Reset baud counter
        else if (ioaddr == 2'b10)
            baud_buffer_divisor[7:0] <= databus[7:0];    
        else if (ioaddr == 2'b11)
            baud_buffer_divisor[15:7] <= databus[7:0];
    end

    // Down counter for the baud rate. Will transmit after counted down from baud_buffer_divisor
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            baud_cnt <= 16'h0000;         // Reset baud counter
        else if (clr | shift)
            baud_cnt <= baud_buffer_divisor;         // Reset baud counter at the start of transmission or after a shift
        else if (en)
            baud_cnt <= baud_cnt - 1 ;   // Increment counter while transmitting. Set after 16 samples/
    end
    // Generate the shift signal when the baud counter reaches the baud period (2604 in this case)
    assign shift = (baud_cnt == 16'h0000) ? 1'b1 : 1'b0;

    // === Bit Counter Logic ===
    // Counts the total number of bits transmitted in the current frame
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 4'h0;            // Reset bit counter
        else if (clr)
            bit_cnt <= 4'h0;            // Reset bit counter at the start of transmission
        else if (shift)
            bit_cnt <= bit_cnt + 1;     // Increment counter on each shift
    end

    // Check if all bits of the frame (10 bits: 1 start, 8 data, 1 stop) have been transmitted
    assign baud_clk = (bit_cnt == 4'b1111) ? 1'b1 : 1'b0;


endmodule