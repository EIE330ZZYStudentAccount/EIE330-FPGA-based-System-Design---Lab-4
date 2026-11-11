`timescale 1ns / 1ps
module vga_pic(
    input  wire        vga_clk,
    input  wire        sys_rst_n,
    input  wire [1:0]  screen_sel,
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    input  wire        pix_data_req,
    output reg  [15:0] pix_data
);
    function [7:0] g_m;
        input [2:0] r;
        begin
            case (r)
                3'd0: g_m = 8'hC3;
                3'd1: g_m = 8'hE7;
                3'd2: g_m = 8'hFF;
                3'd3: g_m = 8'hDB;
                3'd4: g_m = 8'hC3;
                3'd5: g_m = 8'hC3;
                3'd6: g_m = 8'hC3;
                3'd7: g_m = 8'hC3;
                default: g_m = 8'h00;
            endcase
        end
    endfunction

    function [7:0] g_u;
        input [2:0] r;
        begin
            case (r)
                3'd0: g_u = 8'hC3;
                3'd1: g_u = 8'hC3;
                3'd2: g_u = 8'hC3;
                3'd3: g_u = 8'hC3;
                3'd4: g_u = 8'hC3;
                3'd5: g_u = 8'hC3;
                3'd6: g_u = 8'hE7;
                3'd7: g_u = 8'h7E;
                default: g_u = 8'h00;
            endcase
        end
    endfunction

    function [7:0] g_s;
        input [2:0] r;
        begin
            case (r)
                3'd0: g_s = 8'h7E;
                3'd1: g_s = 8'hC3;
                3'd2: g_s = 8'hC0;
                3'd3: g_s = 8'h7E;
                3'd4: g_s = 8'h03;
                3'd5: g_s = 8'h03;
                3'd6: g_s = 8'hC3;
                3'd7: g_s = 8'h7E;
                default: g_s = 8'h00;
            endcase
        end
    endfunction

    function [7:0] g_t;
        input [2:0] r;
        begin
            case (r)
                3'd0: g_t = 8'hFF;
                3'd1: g_t = 8'hFF;
                3'd2: g_t = 8'h18;
                3'd3: g_t = 8'h18;
                3'd4: g_t = 8'h18;
                3'd5: g_t = 8'h18;
                3'd6: g_t = 8'h18;
                3'd7: g_t = 8'h18;
                default: g_t = 8'h00;
            endcase
        end
    endfunction

    function [7:0] g_e;
        input [2:0] r;
        begin
            case (r)
                3'd0: g_e = 8'hFF;
                3'd1: g_e = 8'hC0;
                3'd2: g_e = 8'hC0;
                3'd3: g_e = 8'hFC;
                3'd4: g_e = 8'hC0;
                3'd5: g_e = 8'hC0;
                3'd6: g_e = 8'hC0;
                3'd7: g_e = 8'hFF;
                default: g_e = 8'h00;
            endcase
        end
    endfunction

    function [7:0] g_n;
        input [2:0] r;
        begin
            case (r)
                3'd0: g_n = 8'hC3;
                3'd1: g_n = 8'hE3;
                3'd2: g_n = 8'hF3;
                3'd3: g_n = 8'hDB;
                3'd4: g_n = 8'hCF;
                3'd5: g_n = 8'hC7;
                3'd6: g_n = 8'hC3;
                3'd7: g_n = 8'hC3;
                default: g_n = 8'h00;
            endcase
        end
    endfunction

    function [7:0] g_d;
        input [2:0] r;
        begin
            case (r)
                3'd0: g_d = 8'hFC;
                3'd1: g_d = 8'hC6;
                3'd2: g_d = 8'hC3;
                3'd3: g_d = 8'hC3;
                3'd4: g_d = 8'hC3;
                3'd5: g_d = 8'hC3;
                3'd6: g_d = 8'hC6;
                3'd7: g_d = 8'hFC;
                default: g_d = 8'h00;
            endcase
        end
    endfunction
    function [0:0] must_bit;
        input [1:0] ch;     
        input [2:0] row;
        input [2:0] col;
        begin
            case (ch)
                2'd0: must_bit = (g_m(row) >> (7 - col)) & 8'h01;
                2'd1: must_bit = (g_u(row) >> (7 - col)) & 8'h01;
                2'd2: must_bit = (g_s(row) >> (7 - col)) & 8'h01;
                2'd3: must_bit = (g_t(row) >> (7 - col)) & 8'h01;
                default: must_bit = 1'b0;
            endcase
        end
    endfunction

    function [0:0] end_bit;
        input [1:0] ch;
        input [2:0] row;
        input [2:0] col;
        begin
            case (ch)
                2'd0: end_bit = (g_e(row) >> (7 - col)) & 8'h01;
                2'd1: end_bit = (g_n(row) >> (7 - col)) & 8'h01;
                2'd2: end_bit = (g_d(row) >> (7 - col)) & 8'h01;
                default: end_bit = 1'b0;
            endcase
        end
    endfunction

    function [15:0] bar_pixel;
        input [9:0] x;
        reg [3:0] idx;
        begin
            idx = x[9:6]; 
            case (idx)
                4'd0: bar_pixel = 16'hF800;   //red
                4'd1: bar_pixel = 16'hFC00;   //orange
                4'd2: bar_pixel = 16'hFFE0;    //yellow
                4'd3: bar_pixel = 16'h07E0;   //green
                4'd4: bar_pixel = 16'h07FF;    //ccyan
                4'd5: bar_pixel = 16'h001F;   //blue
                4'd6: bar_pixel = 16'h780F;    //purple
                4'd7: bar_pixel = 16'h0000;   //black
                4'd8: bar_pixel = 16'hFFFF;   //white
                4'd9: bar_pixel = 16'hC618;    //gray
                default: bar_pixel = 16'h0000;
            endcase
        end
    endfunction

    function [15:0] must_pixel;
        input [9:0] x;
        input [9:0] y;
        begin
            must_pixel = 16'h0000;

            if ((y >= 10'd208) && (y < 10'd272)) begin
                if ((x >= 10'd144) && (x < 10'd208)) begin
                    if (must_bit(2'd0, (y - 10'd208) >> 3, (x - 10'd144) >> 3)) 
                        must_pixel = 16'hFFFF;
                end
                else if ((x >= 10'd240) && (x < 10'd304)) begin
                    if (must_bit(2'd1, (y - 10'd208) >> 3, (x - 10'd240) >> 3)) 
                        must_pixel = 16'hFFFF;
                end
                else if ((x >= 10'd336) && (x < 10'd400)) begin
                    if (must_bit(2'd2, (y - 10'd208) >> 3, (x - 10'd336) >> 3)) 
                        must_pixel = 16'hFFFF;
                end
                else if ((x >= 10'd432) && (x < 10'd496)) begin
                    if (must_bit(2'd3, (y - 10'd208) >> 3, (x - 10'd432) >> 3)) 
                        must_pixel = 16'hFFFF;
                end
            end
        end
    endfunction

    function [15:0] end_pixel;
        input [9:0] x;
        input [9:0] y;
        begin
            end_pixel = 16'h0000;

            if ((y >= 10'd208) && (y < 10'd272)) begin
                if ((x >= 10'd192) && (x < 10'd256)) begin
                    if (end_bit(2'd0, (y - 10'd208) >> 3, (x - 10'd192) >> 3)) 
                        end_pixel = 16'hFFFF;
                end
                else if ((x >= 10'd288) && (x < 10'd352)) begin
                    if (end_bit(2'd1, (y - 10'd208) >> 3, (x - 10'd288) >> 3)) 
                        end_pixel = 16'hFFFF;
                end
                else if ((x >= 10'd384) && (x < 10'd448)) begin
                    if (end_bit(2'd2, (y - 10'd208) >> 3, (x - 10'd384) >> 3)) 
                        end_pixel = 16'hFFFF;
                end
            end
        end
    endfunction

    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            pix_data <= 16'h0000;
        end else if (pix_data_req) begin
            case (screen_sel)
                2'b00: pix_data <= bar_pixel(pix_x);
                2'b01: pix_data <= must_pixel(pix_x, pix_y);
                2'b10: pix_data <= end_pixel(pix_x, pix_y);
                default: pix_data <= 16'h0000;
            endcase
        end else begin
            pix_data <= 16'h0000;
        end
    end
endmodule
