`timescale 1ns / 1ps
module vga_top(
    input  wire        sys_clk,
    input  wire        sys_rst_n,
    input  wire        key_in,
    output wire        hsync,
    output wire        vsync,
    output wire [15:0] rgb
);
    wire        vga_clk;
    wire        press_pulse;
    wire [1:0]  screen_sel;
    wire        hsync_i;
    wire        vsync_i;
    wire [9:0]  pix_x;
    wire [9:0]  pix_y;
    wire        pix_data_req;
    wire        rgb_valid;
    wire [15:0] pix_data;

    pll u_pll(
        .sys_clk   (sys_clk),
        .sys_rst_n (sys_rst_n),
        .vga_clk   (vga_clk)
    );

    debounce u_debounce(
        .clk         (sys_clk),
        .rst_n       (sys_rst_n),
        .key_in      (key_in),
        .press_pulse (press_pulse)
    );

    screen_fsm u_screen_fsm(
        .clk        (sys_clk),
        .rst_n      (sys_rst_n),
        .press      (press_pulse),
        .screen_sel (screen_sel)
    );
    reg [1:0] screen_meta;
    reg [1:0] screen_sync;
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            screen_meta <= 2'b00;
            screen_sync <= 2'b00;
        end else begin
            screen_meta <= screen_sel;
            screen_sync <= screen_meta;
        end
    end

    vga_control u_vga_control(
        .vga_clk      (vga_clk),
        .sys_rst_n    (sys_rst_n),
        .hsync        (hsync_i),
        .vsync        (vsync_i),
        .pix_x        (pix_x),
        .pix_y        (pix_y),
        .pix_data_req (pix_data_req),
        .rgb_valid    (rgb_valid)
    );

    reg [1:0] screen_frame;
    reg       vsync_d;
    always @(posedge vga_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            screen_frame <= 2'b00;
            vsync_d      <= 1'b0;
        end else begin
            vsync_d <= vsync_i;
            if (vsync_d && !vsync_i) 
                screen_frame <= screen_sync;
        end
    end
    vga_pic u_vga_pic(
        .vga_clk      (vga_clk),
        .sys_rst_n    (sys_rst_n),
        .screen_sel   (screen_frame),
        .pix_x        (pix_x),
        .pix_y        (pix_y),
        .pix_data_req (pix_data_req),
        .pix_data     (pix_data)
    );

    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign rgb   = rgb_valid ? pix_data : 16'h0000;
endmodule
