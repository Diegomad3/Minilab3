//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    
// Design Name: 
// Module Name:    driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module driver(
    input clk,
    input rst_n,
    input [1:0] br_cfg,
    output logic iocs,
    output logic iorw,
    input rda,
    input tbr,
    output logic [1:0] ioaddr,
    inout wire [7:0] databus
);
//br_cfg
wire [15:0] baud_rate;
wire [15:0] down_count;
reg [1:0] br_cfg_ff;
reg [7:0] databus_ff;

assign baud_rate = (~br_cfg[0] & ~br_cfg[1]) ? 4800 : 
                   (br_cfg[0] & ~br_cfg[1])  ? 9600 :
                   (~br_cfg[0] & br_cfg[1])  ? 19200 :
                                               38400;
assign down_count = 25000000/(16 * baud_rate) - 1;


// === State Machine ===
typedef enum reg [2:0] {IDLE, RECEIVED, TRANSMIT, CHANGING_BAUD_LOW, CHANGING_BAUD_HIGH} state_t; // Define states: IDLE and RECEIVE
state_t state, nxt_state; // Current and next state
assign databus = (state !== IDLE) || ((state !== RECEIVED)) ? databus_ff : databus;




// State transition logic
always @(posedge clk, negedge rst_n)
    if (!rst_n)
        state <= IDLE; // Reset to IDLE state
    else
        state <= nxt_state; // Transition to the next state
// fatabus ff logic
always @(posedge clk, negedge rst_n)
    if (!rst_n)
        databus_ff <= 0; // Reset 
    else if(state == RECEIVED)
        databus_ff <= databus; // Transition to the next state

// Check if baud_rate has changed
always @(posedge clk, negedge rst_n)
    if (!rst_n)
        br_cfg_ff <= 2'b00; // Reset to IDLE state
    else 
        br_cfg_ff <= br_cfg; // Transition to the next state

// Next-state logic and control signal generation
always @(*) begin
// Default values for control signals
    nxt_state = state;
    case (state)
        IDLE: begin
            iocs <= 1'b0;
            iorw <= 1'b1;
            ioaddr <= 2'b00;
            if (br_cfg_ff !== br_cfg)
                nxt_state <= CHANGING_BAUD_LOW;
            if (rda)
                nxt_state <= RECEIVED;
        end
        RECEIVED: begin
            iocs <= 1'b0;
            iorw <= 1'b1;
            ioaddr <= 2'b00;
            if (tbr)
                nxt_state <= TRANSMIT;

        end
        TRANSMIT: begin
            iocs <= 1'b0;
            iorw <= 1'b0;
            ioaddr <= 2'b00;
            if (~tbr)
                nxt_state <= IDLE;

        end

        CHANGING_BAUD_LOW: begin
            iocs <= 1'b1;
            databus_ff <= down_count[7:0];
            ioaddr <= 2'b10;
            nxt_state <= CHANGING_BAUD_HIGH;
  
        end
        CHANGING_BAUD_HIGH: begin
            iocs <= 1'b1;
            databus_ff <= down_count[15:8];
            ioaddr <= 2'b11;
            nxt_state <= IDLE;
            
        end
            
        default: nxt_state = IDLE; // Default case to avoid latches
        
    endcase
end
    

endmodule
