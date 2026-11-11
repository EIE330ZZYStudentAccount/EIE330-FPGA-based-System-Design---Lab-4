`timescale 1ns / 1ps
module vga_control(
    input  wire       vga_clk,
    input  wire       sys_rst_n,
    output reg        hsync,
    output reg        vsync,
    output reg [9:0]  pix_x,
    output reg [9:0]  pix_y,
    output reg        pix_data_req,
    output reg        rgb_valid
);
    reg [9:0] cnt_h;
    reg [9:0] cnt_v;
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            cnt_h <= 10'd0;
            cnt_v <= 10'd0;
        end else begin
            if (cnt_h == 10'd799) begin
                cnt_h <= 10'd0;
                if (cnt_v == 10'd524)
                    cnt_v <= 10'd0;
                else
                    cnt_v <= cnt_v + 10'd1;
            end else begin
                cnt_h <= cnt_h + 10'd1;
            end
        end
    end

    always @(*) begin
        hsync = (cnt_h < 10'd96);
        vsync = (cnt_v < 10'd2);

        pix_data_req =
            (cnt_h >= 10'd143) && (cnt_h <= 10'd782) &&
            (cnt_v >= 10'd35)  && (cnt_v <= 10'd514);

        rgb_valid =
            (cnt_h >= 10'd144) && (cnt_h <= 10'd783) &&
            (cnt_v >= 10'd35)  && (cnt_v <= 10'd514);

        if ((cnt_h >= 10'd143) && (cnt_h <= 10'd782))
            pix_x = cnt_h - 10'd143;
        else
            pix_x = 10'd1023;

        if ((cnt_v >= 10'd35) && (cnt_v <= 10'd514))
            pix_y = cnt_v - 10'd35;
        else
            pix_y = 10'd1023;
    end
endmodule
