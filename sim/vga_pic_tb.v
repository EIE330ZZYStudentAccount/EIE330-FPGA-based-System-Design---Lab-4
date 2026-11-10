`timescale 1ns/1ps
module vga_pic_tb;
    reg vga_clk, sys_rst_n, pix_data_req; reg [1:0] screen_sel; reg [9:0] pix_x, pix_y; wire [15:0] pix_data;
    vga_pic dut(vga_clk, sys_rst_n, screen_sel, pix_x, pix_y, pix_data_req, pix_data);
    always #20 vga_clk = ~vga_clk;
    task check_pixel; input [9:0] x, y; input [1:0] sel; input [15:0] exp; begin
        screen_sel = sel; pix_x = x; pix_y = y; pix_data_req = 1; @(posedge vga_clk); #1;
        if (pix_data !== exp) $display("FAIL pixel x=%0d y=%0d", x, y);
        pix_data_req = 0; @(posedge vga_clk);
    end endtask
    initial begin
        $dumpfile("sim/vga_pic_tb.vcd"); $dumpvars(0, vga_pic_tb);
        vga_clk = 0; sys_rst_n = 0; screen_sel = 0; pix_x = 0; pix_y = 0; pix_data_req = 0; #50; sys_rst_n = 1;
        check_pixel(0, 0, 2'b00, 16'hF800); check_pixel(144, 208, 2'b01, 16'hFFFF);
        check_pixel(192, 208, 2'b10, 16'hFFFF); check_pixel(160, 208, 2'b01, 16'h0000);
        $display("VGA PIC TB finished"); $finish;
    end
endmodule
