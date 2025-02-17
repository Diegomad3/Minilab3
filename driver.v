module driver(
    input clk,
    input rst,
    input [1:0] br_cfg,      // Baud rate configuration (DIP settings)
    output reg iocs,          // I/O Chip Select
    output reg iorw,          // I/O Read/Write control
    input rda,                // Receive Data Available
    input tbr,                // Transmit Buffer Ready
    output reg [1:0] ioaddr,  // I/O Address
    inout [7:0] databus       // Bidirectional data bus
);

    // Internal registers
    reg [7:0] data_out;       // Data to be driven onto the DATABUS
    reg data_out_en;          // Enable signal for DATABUS output
	reg [1:0]br_cfg_FF;
	reg [7:0] receive_buffer, receive_buffer_flopped;
	reg       rda_flopped1, rda_flopped2;
	
	
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rda_flopped1 <= 1'b0;
			rda_flopped2 <= 1'b0;
			receive_buffer <= 8'hFF;
			receive_buffer_flopped <= 8'hFF;
        end else if(rda || rda_flopped1 || rda_flopped2) begin
			receive_buffer <= databus;
			receive_buffer_flopped  <= receive_buffer;
			rda_flopped1 <= rda;
			rda_flopped2 <= rda_flopped1;
		end else begin
			receive_buffer <= receive_buffer;
			receive_buffer_flopped  <= receive_buffer;			
			rda_flopped1 <= 1'b0;
			rda_flopped2 <= rda_flopped1;
        end
    end

    // Baud rate divisor values (for 25 MHz clock)
    reg [15:0] baud_divisor;  // 16-bit divisor value
    reg [7:0] divisor_low;    // Low byte of divisor
    reg [7:0] divisor_high;   // High byte of divisor

    // Bidirectional DATABUS control
    assign databus = (data_out_en) ? data_out : 8'bzzzzzzzz;

    // Map br_cfg to baud divisor values
    always @(*) begin
        case (br_cfg)
            2'b00: baud_divisor = 16'd325; // 4800 baud
            2'b01: baud_divisor = 16'd162; // 9600 baud
            2'b10: baud_divisor = 16'd81;  // 19200 baud
            2'b11: baud_divisor = 16'd40;  // 38400 baud
            default: baud_divisor = 16'd162; // Default to 9600 baud
        endcase

        // Split the 16-bit divisor into high and low bytes
        divisor_low = baud_divisor[7:0];
        divisor_high = baud_divisor[15:8];
    end
	
	    // Map br_cfg to baud divisor values
    always @(*) begin
        case (br_cfg)
            2'b00: baud_divisor = 16'd325; // 4800 baud
            2'b01: baud_divisor = 16'd162; // 9600 baud
            2'b10: baud_divisor = 16'd81;  // 19200 baud
            2'b11: baud_divisor = 16'd40;  // 38400 baud
            default: baud_divisor = 16'd162; // Default to 9600 baud
        endcase

        // Split the 16-bit divisor into high and low bytes
        divisor_low = baud_divisor[7:0];
        divisor_high = baud_divisor[15:8];
    end

    // State machine states
  /*  typedef enum {
        IDLE,
        WRITE_DIVISOR_LOW,
        WRITE_DIVISOR_HIGH,
        READ_STATUS,
        READ_DATA,
        WRITE_DATA
    } state_t; */
	
	parameter IDLE              = 3'b000;
	parameter WRITE_DIVISOR_LOW  = 3'b001;
	parameter WRITE_DIVISOR_HIGH = 3'b010;
	parameter READ_STATUS       = 3'b011;
	parameter READ_DATA         = 3'b100;
	parameter WRITE_DATA        = 3'b101;

	reg [2:0] current_state, next_state;

    // State machine transition logic
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= IDLE;
			br_cfg_FF <= 2'b00;
        end else begin
            current_state <= next_state;
			br_cfg_FF <= br_cfg;
        end
    end

    // State machine logic
    always @(*) begin
        // Default values
        iocs = 1'b0;
        iorw = 1'b1; // Default to read
        ioaddr = 2'b00;
        data_out = 8'b0;
        data_out_en = 1'b0;
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (br_cfg != br_cfg_FF) begin
                    next_state = WRITE_DIVISOR_LOW; // Configure baud rate
                end else if (rda) begin
                    next_state = READ_DATA; // Data available, read it
                end else if (rda_flopped2 && tbr) begin
                    next_state = WRITE_DATA; // Transmit buffer ready, write data
                end else begin
                    next_state = READ_STATUS; // Check status
                end
            end

            WRITE_DIVISOR_LOW: begin
                iocs = 1'b1; // Select SPART
                iorw = 1'b0; // Write operation
                ioaddr = 2'b10; // Address for Divisor Low Byte
                data_out = divisor_low; // Send low byte of divisor
                data_out_en = 1'b1; // Enable DATABUS output
                next_state = WRITE_DIVISOR_HIGH;
            end

            WRITE_DIVISOR_HIGH: begin
                iocs = 1'b1; // Select SPART
                iorw = 1'b0; // Write operation
                ioaddr = 2'b11; // Address for Divisor High Byte
                data_out = divisor_high; // Send high byte of divisor
                data_out_en = 1'b1; // Enable DATABUS output
                next_state = IDLE;
            end

            READ_STATUS: begin
                iocs = 1'b1; // Select SPART
                iorw = 1'b1; // Read operation
                ioaddr = 2'b01; // Address for Status Register
                next_state = IDLE;
            end

            READ_DATA: begin
                iocs = 1'b1; // Select SPART
                iorw = 1'b1; // Read operation
                ioaddr = 2'b00; // Address for Receive Buffer
                next_state = IDLE;
            end

            WRITE_DATA: begin
                iocs = 1'b1; // Select SPART
                iorw = 1'b0; // Write operation
                ioaddr = 2'b00; // Address for Transmit Buffer
                data_out = receive_buffer_flopped; // data to transmit
                data_out_en = 1'b1; // Enable DATABUS output
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule