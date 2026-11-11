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
        $dumpfile("sim/vga_pic_tb.vcd");
        $dumpvars(0, vga_pic_tb);
        vga_clk      = 1'b0;
        sys_rst_n    = 1'b0;
        screen_sel   = 2'b00;
        pix_x        = 10'd0;
        pix_y        = 10'd0;
        pix_data_req = 1'b0;

        #50;
        sys_rst_n = 1'b1;

        check_pixel(10'd0,   10'd10, 2'b00, 16'hF800); 
        check_pixel(10'd64,  10'd10, 2'b00, 16'hFC00); 
        check_pixel(10'd128, 10'd10, 2'b00, 16'hFFE0); 
        check_pixel(10'd192, 10'd10, 2'b00, 16'h07E0); 
        check_pixel(10'd256, 10'd10, 2'b00, 16'h07FF); 
        check_pixel(10'd320, 10'd10, 2'b00, 16'h001F); 
        check_pixel(10'd384, 10'd10, 2'b00, 16'h780F); 
        check_pixel(10'd448, 10'd10, 2'b00, 16'h0000); 
        check_pixel(10'd512, 10'd10, 2'b00, 16'hFFFF); 
        check_pixel(10'd576, 10'd10, 2'b00, 16'hC618); 

        check_pixel(10'd144, 10'd208, 2'b01, 16'hFFFF); 
        check_pixel(10'd160, 10'd208, 2'b01, 16'h0000); 
        check_pixel(10'd207, 10'd271, 2'b01, 16'hFFFF); 
        check_pixel(10'd240, 10'd240, 2'b01, 16'hFFFF); 
        check_pixel(10'd272, 10'd271, 2'b01, 16'hFFFF); 
        check_pixel(10'd336, 10'd240, 2'b01, 16'hFFFF); 
        check_pixel(10'd368, 10'd208, 2'b01, 16'hFFFF); 
        check_pixel(10'd432, 10'd208, 2'b01, 16'hFFFF); 
        check_pixel(10'd463, 10'd208, 2'b01, 16'hFFFF); 
        check_pixel(10'd463, 10'd240, 2'b01, 16'hFFFF); 
        check_pixel(10'd100, 10'd208, 2'b01, 16'h0000); 
        check_pixel(10'd220, 10'd240, 2'b01, 16'h0000); 

        check_pixel(10'd192, 10'd208, 2'b10, 16'hFFFF); 
        check_pixel(10'd240, 10'd240, 2'b10, 16'h0000); 
        check_pixel(10'd192, 10'd271, 2'b10, 16'hFFFF); 
        check_pixel(10'd288, 10'd208, 2'b10, 16'hFFFF); 
        check_pixel(10'd320, 10'd240, 2'b10, 16'hFFFF); 
        check_pixel(10'd384, 10'd208, 2'b10, 16'hFFFF); 
        check_pixel(10'd447, 10'd240, 2'b10, 16'hFFFF); 
        check_pixel(10'd416, 10'd240, 2'b10, 16'h0000); 
        check_pixel(10'd300, 10'd100, 2'b10, 16'h0000); 

        check_pixel(10'd639, 10'd479, 2'b00, 16'hC618); 
        check_pixel(10'd639, 10'd479, 2'b01, 16'h0000); 
        check_pixel(10'd639, 10'd479, 2'b10, 16'h0000); 

        $display("VGA PIC TB finished - All pixel checks passed!");
        $finish;
    end
    
    
endmodule
