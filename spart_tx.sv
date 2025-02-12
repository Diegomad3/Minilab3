module spart_tx(
    input clk,
    input rst,
    input en,
    input baud_clk,
    input [7:0] tx_data,
    output txd,
    output tbr
)

    // Internal control signals
    logic set_done;               // Signal to set the `tx_done` flag
    logic byte_valid;             // Signal indicating all bits of the frame are sent

    // Internal registers
    logic [8:0] tx_shft_reg;      // 9-bit shift register (1 start bit, 8 data bits)
    logic [3:0] bit_cnt;          // Counter to track the number of bits sent

    // Serializes the data for transmission by shifting it out bit by bit
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            tx_shft_reg <= 9'h1FF;            // Default idle state with all bits high
        else if (en)
            tx_shft_reg <= {tx_data, 1'b0};  // Load the data with a start bit (LSB = 0)
        else if (baud_clk)
            tx_shft_reg <= {1'b1, tx_shft_reg[8:1]}; // Shift out the LSB, pad with 1s (stop bits)

    // Assign the LSB of the shift register to the TX line
    assign txd = tx_shft_reg[0];

    // === Empty Tx buffer Counter Logic ===
    // Counts the total number of bits transmitted in the current frame
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            bit_cnt <= 4'h0;            // Reset bit counter
        else if (en)
            bit_cnt <= 4'h0;            // Reset bit counter at the start of transmission
        else if (baud_clk)
            bit_cnt <= bit_cnt + 1;     // Increment counter on each shift
    end

    // Check if all bits of the frame (10 bits: 1 start, 8 data, 1 stop) have been transmitted
    assign byte_valid = (bit_cnt == 4'h0) ? 1'b1 : 1'b0;

    // === State Machine ===
    typedef enum reg {IDLE, TRANSMIT} state_t; // Define states: IDLE and TRANSMIT

    state_t state, nxt_state; // Current and next state

    // State transition logic
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            state <= IDLE; // Reset to IDLE state
        else
            state <= nxt_state; // Transition to the next state
    end

    // Next-state logic and control signal generation
    always_comb begin
        set_done = 0;
        nxt_state = state;

        case (state)
            IDLE: if (en) begin        // If transmit request is asserted
                      tbr = 1
                      nxt_state = TRANSMIT;
                  end

            TRANSMIT: begin
                if (byte_valid) begin    // If all bits of the frame are sent
                    set_done = 1;        // Set the transmission done flag
                    nxt_state = IDLE;    // Return to IDLE state
                end
            end

            default: nxt_state = IDLE;   // Default case to avoid latches
        endcase
    end



endmodule