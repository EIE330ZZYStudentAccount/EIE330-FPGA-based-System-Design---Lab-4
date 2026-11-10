`timescale 1ns/1ps
module pll_tb;
    reg  sys_clk; reg  sys_rst_n; wire vga_clk;
    pll dut(.sys_clk(sys_clk), .sys_rst_n(sys_rst_n), .vga_clk(vga_clk));
    always #10 sys_clk = ~sys_clk;
    initial begin
        $dumpfile("sim/pll_tb.vcd"); $dumpvars(0, pll_tb);
        sys_clk = 1'b0; sys_rst_n = 1'b0; #25;
        sys_rst_n = 1'b1; #200;
        sys_rst_n = 1'b0; #20; sys_rst_n = 1'b1; #200;
        $display("PLL TB finished"); $finish;
    end
endmodule
