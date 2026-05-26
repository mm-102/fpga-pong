module top (
    input  wire I_clk_27m,
    output wire O_tmds_clk_p,
    output wire O_tmds_clk_n,
    output wire [2:0] O_tmds_d_p,
    output wire [2:0] O_tmds_d_n
);

    localparam CHANNEL_BITS = 8;
    localparam GAME_W_BITS = 16;
    localparam GAME_H_BITS = 16;
    localparam SCORE_DIGITS = 2;

    localparam PADDLE_LEFT_X = 3200;
    localparam PADDLE_RIGHT_X = 37248;

    wire clk_serial; // 371.25 MHz for dvi
    wire clk_pixel;  // 74.25 MHz
    wire pll_lock;

    Gowin_rPLL pll_inst (
        .clkin(I_clk_27m),
        .clkout(clk_serial), 
        .lock(pll_lock)
    );

    wire sys_rst_n = pll_lock;


    CLKDIV u_clkdiv (
        .RESETN(sys_rst_n),
        .HCLKIN(clk_serial), 
        .CLKOUT(clk_pixel),  
        .CALIB (1'b1)
    );
    defparam u_clkdiv.DIV_MODE = "5";
    defparam u_clkdiv.GSREN = "false";


    wire hsync, vsync, de;
    wire [CHANNEL_BITS-1:0] r, g, b;

    // paddle 16 x 96
    // ball 32 x 32

    display #(
        .CHANNEL_BITS(CHANNEL_BITS),
        .GAME_W_BITS(GAME_W_BITS),
        .GAME_H_BITS(GAME_H_BITS),
        .SCORE_DIGITS(SCORE_DIGITS),
        .PADDLE_LEFT_X(PADDLE_LEFT_X),
        .PADDLE_RIGHT_X(PADDLE_RIGHT_X)
    ) display_inst (
        .I_clk_pixel(clk_pixel),
        .I_rst_n(sys_rst_n),
        
        // TODO game logic
        .I_paddle_left_y(GAME_H_BITS'(9984)),
        .I_paddle_right_y(GAME_H_BITS'(9984)),
        .I_ball_x(GAME_W_BITS'(19968)),
        .I_ball_y(GAME_H_BITS'(11008)),

        .I_bcd_score_left(8'h12),
        .I_bcd_score_right(8'h34),

        .O_hsync(hsync),
        .O_vsync(vsync),
        .O_de(de),
        .O_r(r), .O_g(g), .O_b(b)
    );


    // hdmi / dvi optput
    DVI_TX_Top dvi_tx_inst (
        .I_rst_n(sys_rst_n),
        .I_serial_clk(clk_serial),
        .I_rgb_clk(clk_pixel),
        .I_rgb_vs(vsync),
        .I_rgb_hs(hsync),
        .I_rgb_de(de),
        .I_rgb_r(r),
        .I_rgb_g(g),
        .I_rgb_b(b),
        .O_tmds_clk_p(O_tmds_clk_p),
        .O_tmds_clk_n(O_tmds_clk_n),
        .O_tmds_data_p(O_tmds_d_p),
        .O_tmds_data_n(O_tmds_d_n)
    );

endmodule