module spart_baud_gen(
    input clk,               // Clock signal
    input rst,               // Active-high reset
    input [1:0] ioaddr,      // Address bus to select high/low byte of divisor
    input [7:0] databus,     // Data bus to load divisor
    input en,                // Enable signal for baud rate generation
    input clr,               // Clear signal to reset the counter
    output reg baud_clk      // Baud clock output
);

    reg [15:0] baud_buffer_divisor; // Divisor value for baud rate
    reg [15:0] baud_cnt;            // Counter for baud rate timing

    // === Divisor Loading Logic ===
    // Load the high or low byte of the divisor based on ioaddr
    always @(posedge clk or negedge rst) begin
        if (!rst)
            baud_buffer_divisor <= 16'd325; // default to 4800 baud
        else if (en) begin
            if (ioaddr == 2'b10)
                baud_buffer_divisor[7:0] <= databus; // Load low byte
            else if (ioaddr == 2'b11)
                baud_buffer_divisor[15:8] <= databus; // Load high byte
        end
    end

    // === Baud Rate Counter Logic ===
    // Down counter for baud rate timing
    always @(posedge clk or negedge rst) begin
        if (!rst)
            baud_cnt <= 16'h0000; // Reset counter on reset
        else if (clr)
            baud_cnt <= baud_buffer_divisor; // Reload divisor on clear
        else if (en) begin
            if (baud_cnt == 16'h0000)
                baud_cnt <= baud_buffer_divisor; // Reload divisor when counter reaches 0
            else
                baud_cnt <= baud_cnt - 1; // Decrement counter
        end
    end

    // === Baud Clock Generation ===
    // Generate baud_clk when the counter reaches 0
    always @(posedge clk or negedge rst) begin
        if (!rst)
            baud_clk <= 1'b0; // Reset baud clock on reset
        else if (en && baud_cnt == 16'h0000)
            baud_clk <= 1'b1; // Assert baud_clk when counter reaches 0
        else
            baud_clk <= 1'b0; // Deassert baud_clk otherwise
    end

endmodule