module spart_rx(
    input clk,
    input rst,
    input baud_clk,
    input rxd,
	output logic en,
    output logic [7:0] rx_data,
    output logic rda
);


    // Flops for metastability prevention
    logic rxd_FF1, rxd_FF2, enable, start, done, set_rdy, receiving, rdy_reg1, rdy_reg2;
	logic [3:0] bit_cnt;
	
	//assign en = enable || receiving;
    assign en = 1'b1;
	
	// === State Machine ===
    typedef enum reg {IDLE, RECEIVE} state_t; // Define states: IDLE and RECEIVE

    state_t state, nxt_state; // Current and next state

    
     // Shift register for received data
    logic [8:0] rx_shft_reg;    // Shift register for serial-to-parallel conversion (9 bits for stop/start bits)

    // Double-flop the RX input to prevent metastability issues
    always_ff @(posedge clk, negedge rst)
        if (!rst) begin
            rxd_FF1 <= 1'b1;       // Default idle state for RX is high
            rxd_FF2 <= 1'b1;
        end
        else begin
            rxd_FF1 <= rxd;      // First flip-flop captures RX
            rxd_FF2 <= rxd_FF1; // Second flip-flop synchronizes RX to the clock domain
        end
     
	//assign enable = (rxd_FF2 !== rxd_FF1) && (state !== RECEIVE);
        // === Shift Register Logic ===
    // Serial-to-parallel conversion of received data
    always_ff @(posedge clk, negedge rst) begin
        if (!rst)
            rx_shft_reg <= 9'h1FF; // Default all bits high
        else if (baud_clk)
            rx_shft_reg <= {rxd_FF2, rx_shft_reg[8:1]}; // Shift in the RX signal (LSB first)
        else if (start)
            rx_shft_reg <= 9'h1FF; // Default all bits high
    end
     // Extract the 8-bit data from the shift register
    assign rx_data = rx_shft_reg[7:0];
	
	 // === Bit Counter Logic ===
    // Count the number of bits received in the current frame
    always_ff @(posedge clk, negedge rst)
        if (!rst)
            bit_cnt <= 4'h0; // Reset bit counter
        else if (start)
            bit_cnt <= 4'h0; // Start a new frame, already counting start bit
        else if (baud_clk && receiving)
            bit_cnt <= bit_cnt + 1; // Increment bit counter after each shift

    // Determine when the reception of the frame is complete
    assign done = (bit_cnt == 4'b1010) ? 1'b1 : 1'b0; // Done after receiving 10 bits (1 start, 8 data, 1 stop)


    // State transition logic
    always_ff @(posedge clk, negedge rst) begin
        if (!rst) begin
            state <= IDLE; // Reset to IDLE state
			enable  <= 0;
		end	
        else begin
            state <= nxt_state; // Transition to the next state
			enable <= (rxd_FF2 !== rxd_FF1) && (state !== RECEIVE);
		end	
	end
    // Next-state logic and control signal generation
    always_comb begin
        // Default values for control signals
        set_rdy = 0;
		start = 0;
		receiving = 0;
        nxt_state = state;

        case (state)
            IDLE: if (enable) begin  // Detect start bit (RX goes low)
					start = 1;
                    nxt_state = RECEIVE; // Move to RECEIVE state
                  end

            RECEIVE: begin
						receiving = 1;
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
    always_ff @(posedge clk, negedge rst) begin
        if (!rst) begin
		// Reset the ready signal
			rdy_reg1 <= 1'b0;
			rdy_reg2 <= 1'b0;
		end	
        else if (set_rdy)begin
            rdy_reg1 <= 1'b1;
			rdy_reg2 <= rdy_reg1; // Set the ready signal when data is received
		end	
		else if (enable) begin
			rdy_reg1 <= 1'b0;
			rdy_reg2 <= 1'b0;  // Clear on next start bit (new frame)
		end
		else begin
			rdy_reg1 <= 1'b0;
			rdy_reg2 <= rdy_reg1;
		end	
    end
	// Assign output rdy from the rdy flop		
	assign rda = rdy_reg1 || rdy_reg2;
    //assign rda = (bit_cnt == 4'b1010);
endmodule