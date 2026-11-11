`timescale 1ns / 1ps
module screen_fsm(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       press,
    output reg  [1:0] screen_sel
);
    localparam S_BARS = 2'b00;
    localparam S_MUST = 2'b01;
    localparam S_END  = 2'b10;

    reg [1:0] state;
    reg [1:0] next_state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_BARS;
        else
            state <= next_state;
    end
    always @(*) begin
        next_state = state;
        case (state)
            S_BARS: if (press) next_state = S_MUST;
            S_MUST: if (press) next_state = S_END;
            S_END:  if (press) next_state = S_BARS;
            default: next_state = S_BARS;
        endcase
    end
    always @(*) begin
        screen_sel = state;
    end
endmodule
