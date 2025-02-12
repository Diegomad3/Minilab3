module spart_rx(
    input clk,
    input rst,
    input en,
    input baud_clk,
    input rxd,
    output [7:0] rx_data,
    output rda
)


    // Flops for metastability prevention
    reg rxd_FF1, rxd_FF2;
    
    wire done;

     // Shift register for received data
    reg [8:0] rx_shft_reg;    // Shift register for serial-to-parallel conversion (9 bits for stop/start bits)

    // Double-flop the RX input to prevent metastability issues
    always @(posedge clk, negedge rst_n)
        if (!rst_n) begin
            rxd_FF1 <= 1'b1;       // Default idle state for RX is high
            rxd_FF2 <= 1'b1;
        end
        else begin
            rxd_FF1 <= rxd;      // First flip-flop captures RX
            rxd_FF2 <= rxd_FF1; // Second flip-flop synchronizes RX to the clock domain
        end

        // === Shift Register Logic ===
    // Serial-to-parallel conversion of received data
    always @(posedge clk, negedge rst_n)
        if (!rst_n)
            rx_shft_reg <= 9'h1FF; // Default all bits high
        else if (baud_clk)
            rx_shft_reg <= {rxd_FF2, rx_shft_reg[8:1]}; // Shift in the RX signal (LSB first)

     // Extract the 8-bit data from the shift register
    assign rx_data = rx_shft_reg[7:0];

    // === State Machine ===
    typedef enum reg {IDLE, RECEIVE} state_t; // Define states: IDLE and RECEIVE

    state_t state, nxt_state; // Current and next state

    // State transition logic
    always @(posedge clk, negedge rst_n)
        if (!rst_n)
            state <= IDLE; // Reset to IDLE state
        else
            state <= nxt_state; // Transition to the next state

    // Next-state logic and control signal generation
    always @(*) begin
        // Default values for control signals
        set_rdy = 0;
        nxt_state = state;

        case (state)
            IDLE: if (~rxd_FF2 & en) begin  // Detect start bit (RX goes low)
                    nxt_state = RECEIVE; // Move to RECEIVE state
                  end

            RECEIVE: begin
                        if (done) begin // If the frame is complete
                            receiving = 0;
                            set_rdy = 1; // Set the ready flag
                            nxt_state = IDLE; // Return to IDLE state
                        end
                     end

            default: nxt_state = IDLE; // Default case to avoid latches
        endcase
    end
    
    // Generate the ready signal (`rdy`) to indicate valid data is available
    always_ff @(posedge clk, negedge rst_n)
        if (!rst_n)
            rdy_reg <= 1'b0; // Reset the ready signal
        else if (set_rdy)
            rdy_reg <= 1'b1; // Set the ready signal when data is received
    // === Rx Counter Logic ===
    // Counts the total number of bits transmitted in the current frame
    always @(posedge baud_clk, negedge rst_n) begin
        if (!rst_n )
            rx_buffer_cnt <= 4'h0;            // Reset bit counter
        else if (state == RECEIVE)
            rx_buffer_cnt <= rx_buffer_cnt + 1;     // Increment counter on each shift
        if (rx_buffer_cnt == 4'h7) begin
            done <= 1'b1;
            rx_buffer_cnt = 4'h0;
        end
    end
	// Assign output rdy from the rdy flop		
	assign rda = rdy_reg;
endmodule