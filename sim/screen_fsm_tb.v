`timescale 1ns/1ps
module screen_fsm_tb;
    reg clk, rst_n, press; wire [1:0] screen_sel;
    screen_fsm dut(.clk(clk), .rst_n(rst_n), .press(press), .screen_sel(screen_sel));
    always #10 clk = ~clk;
    task pulse_press; begin press = 1; #20; press = 0; #100; end endtask
    task check_state; input [1:0] exp; begin if (screen_sel !== exp) begin $display("FAIL"); $finish; end end endtask
    initial begin
        $dumpfile("sim/screen_fsm_tb.vcd"); $dumpvars(0, screen_fsm_tb);
        clk = 0; rst_n = 0; press = 0; #50; rst_n = 1; #50;
        check_state(2'b00); pulse_press; check_state(2'b01); pulse_press; check_state(2'b10); pulse_press; check_state(2'b00);
        pulse_press; check_state(2'b01); rst_n = 0; #50; rst_n = 1; #50; check_state(2'b00);
        $display("SCREEN FSM TB PASS"); $finish;
    end
endmodule
