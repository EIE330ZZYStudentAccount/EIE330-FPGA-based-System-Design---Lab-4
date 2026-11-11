`timescale 1ns/1ps
module debounce_tb;
    reg clk, rst_n, key_in; wire press_pulse; integer pulse_cnt = 0;
    debounce #(.CLK_FREQ(50_000_000), .DEBOUNCE_MS(10)) dut(.clk(clk), .rst_n(rst_n), .key_in(key_in), .press_pulse(press_pulse));
    always #10 clk = ~clk;
    always @(posedge clk) if (press_pulse) pulse_cnt = pulse_cnt + 1;
    task clean_click; begin key_in = 0; #20_000_000; key_in = 1; #20_000_000; end endtask
    task bounce_click; integer i; begin
        key_in = 0; #200_000;
        for (i = 0; i < 10; i = i + 1) begin key_in = ~key_in; #200_000; end
        key_in = 0; #15_000_000; key_in = 1; #20_000_000;
    end endtask
    task long_press; begin key_in = 0; #50_000_000; key_in = 1; #20_000_000; end endtask
    initial begin
                $dumpfile("sim/debounce_tb.vcd");
        $dumpvars(0, debounce_tb.key_in);
        $dumpvars(0, debounce_tb.press_pulse);
        $dumpvars(0, debounce_tb.pulse_cnt);
        $dumpvars(0, debounce_tb.dut.key_deb);
        $dumpvars(0, debounce_tb.dut.cnt);
        clk = 0; rst_n = 0; key_in = 1; #100_000; rst_n = 1; #1_000_000;
        clean_click; if (pulse_cnt !== 1) $display("FAIL clean");
        bounce_click; if (pulse_cnt !== 2) $display("FAIL bounce");
        long_press; if (pulse_cnt !== 3) $display("FAIL long");
        key_in = 0; #5_000_000; rst_n = 0; #1_000_000; rst_n = 1; #20_000_000;
        key_in = 1; #20_000_000; if (pulse_cnt !== 3) $display("FAIL reset-held");
        $display("DEBOUNCE TB finished, pulses=%0d", pulse_cnt); $finish;
    end
endmodule
