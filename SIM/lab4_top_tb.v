`timescale 1ns/1ps
module lab4_top_tb;
    reg sys_clk, sys_rst_n, key_in; wire hsync, vsync; wire [15:0] rgb;
    vga_top dut(.sys_clk(sys_clk), .sys_rst_n(sys_rst_n), .key_in(key_in), .hsync(hsync), .vsync(vsync), .rgb(rgb));
    always #10 sys_clk = ~sys_clk;
    task clean_click; begin key_in = 0; #20_000_000; key_in = 1; #20_000_000; end endtask
    task bounce_click; integer i; begin
        key_in = 0; #200_000; for (i = 0; i < 10; i = i + 1) begin key_in = ~key_in; #200_000; end
        key_in = 0; #15_000_000; key_in = 1; #20_000_000;
    end endtask
    task long_press; begin key_in = 0; #50_000_000; key_in = 1; #20_000_000; end endtask
    task reset_pulse; begin sys_rst_n = 0; #1_000_000; sys_rst_n = 1; #1_000_000; end endtask
    task expect_state; input [1:0] exp; begin
        if (dut.u_screen_fsm.state !== exp) begin $display("FAIL state at %0t", $time); $finish; end
    end endtask
    initial begin
        $dumpfile("sim/lab4_top.vcd");
        $dumpvars(0, lab4_top_tb.key_in);
        $dumpvars(0, lab4_top_tb.sys_rst_n);
        $dumpvars(0, lab4_top_tb.dut.press_pulse);
        $dumpvars(0, lab4_top_tb.dut.u_screen_fsm.state);
        $dumpvars(0, lab4_top_tb.dut.screen_frame); 
        $dumpvars(0, lab4_top_tb.dut.u_vga_control.cnt_h); 
        $dumpvars(0, lab4_top_tb.dut.u_vga_control.cnt_v); 
        $dumpvars(0, lab4_top_tb.dut.u_vga_control.rgb_valid); 
         $dumpvars(0, lab4_top_tb.dut.vsync); 
          $dumpvars(0, lab4_top_tb.rgb); 
        
        sys_clk = 0; sys_rst_n = 0; key_in = 1; #100_000; sys_rst_n = 1; #1_000_000;
        expect_state(2'b00); clean_click; expect_state(2'b01);
        bounce_click; expect_state(2'b10); long_press; expect_state(2'b00);
        clean_click; expect_state(2'b01); reset_pulse; expect_state(2'b00);
        reset_pulse; 
        expect_state(2'b00);
        
        clean_click; 
        expect_state(2'b01);
        
        key_in = 1'b0; 
        #5_000_000;
        
        sys_rst_n = 1'b0; #1_000_000;
        sys_rst_n = 1'b1; #20_000_000;
        expect_state(2'b00); 
      
        expect_state(2'b00); 

        key_in = 1'b1; #20_000_000;
        expect_state(2'b00);

        clean_click;
        expect_state(2'b01); 

        $display("LAB4 TOP TB PASS"); 
        $finish;
    end
endmodule
