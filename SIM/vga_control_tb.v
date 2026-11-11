`timescale 1ns/1ps
module vga_control_tb;
    reg vga_clk, sys_rst_n; wire hsync, vsync, pix_data_req, rgb_valid; wire [9:0] pix_x, pix_y;
    vga_control dut(vga_clk, sys_rst_n, hsync, vsync, pix_x, pix_y, pix_data_req, rgb_valid);
    always #20 vga_clk = ~vga_clk;
    initial begin
        $dumpfile("sim/vga_control_tb.vcd"); $dumpvars(0, vga_control_tb);
        vga_clk = 0; sys_rst_n = 0; #100; sys_rst_n = 1; #1_000_000;
        $display("VGA CONTROL TB finished"); $finish;
    end
endmodule
