`timescale 1ns / 1ps
module debounce #(
    parameter CLK_FREQ    = 50_000_000,
    parameter DEBOUNCE_MS = 10
)(
    input  wire clk,
    input  wire rst_n,
    input  wire key_in,
    output wire press_pulse
);

localparam DEBOUNCE_MAX = 500000;
localparam CNT_W        = 19;

    reg [1:0]          sync;
    reg [CNT_W-1:0]    cnt;
    reg                key_deb;
    reg                key_deb_d;
    reg                armed; 

       always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync      <= 2'b00; 
            cnt       <= {CNT_W{1'b0}};
            key_deb   <= 1'b1;
            key_deb_d <= 1'b1;
            armed     <= 1'b0;
        end else begin
            sync      <= {sync[0], key_in};
            key_deb_d <= key_deb;

            if (sync[1] != key_deb) begin
                if (cnt == DEBOUNCE_MAX - 1) begin
                    key_deb <= sync[1];
                    cnt     <= {CNT_W{1'b0}};
                    if (sync[1])
                        armed <= 1'b1;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end else begin
                cnt <= {CNT_W{1'b0}};
                if (sync[1] && key_deb)
                    armed <= 1'b1;
            end
        end
    end
    assign press_pulse = key_deb_d & (~key_deb) & armed;
endmodule
