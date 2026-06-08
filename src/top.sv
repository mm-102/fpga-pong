module top (
    input  wire I_clk_27m,
    input wire I_enc1_a,
    input wire I_enc1_b,
    input wire I_enc2_a,
    input wire I_enc2_b,
    input wire I_rst_p,
    output wire O_tmds_clk_p,
    output wire O_tmds_clk_n,
    output wire [2:0] O_tmds_d_p,
    output wire [2:0] O_tmds_d_n
);

    localparam CHANNEL_BITS = 8;

    localparam GAME_W_BITS = 16;
    localparam GAME_H_BITS = 16;

    localparam SCORE_DIGITS = 3;
    localparam SCORE_NUM_DIGITS_BITS = 2;
    localparam SCORE_LEFT_X = 16896;
    localparam SCORE_RIGHT_X = 20992;
    localparam SCORE_Y = 1600;

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
    wire game_rst_n = sys_rst_n & !I_rst_p;


    CLKDIV u_clkdiv (
        .RESETN(sys_rst_n),
        .HCLKIN(clk_serial), 
        .CLKOUT(clk_pixel),  
        .CALIB (1'b1)
    );
    defparam u_clkdiv.DIV_MODE = "5";
    defparam u_clkdiv.GSREN = "false";

    
    wire [GAME_W_BITS-1:0] ball_x;
    wire [GAME_H_BITS-1:0] ball_y;
    wire [GAME_H_BITS-1:0] paddle_left_y;
    wire [GAME_H_BITS-1:0] paddle_right_y;

    wire [(4*SCORE_DIGITS)-1:0] bcd_score_left;
    wire [(4*SCORE_DIGITS)-1:0] bcd_score_right;

    wire hsync, vsync, de;
    wire [CHANNEL_BITS-1:0] r, g, b;

    wire enc1_tick_cw;
    wire enc1_tick_ccw;
    rotary_encoder enc1_inst (
        .I_clk(clk_pixel),
        .I_rst_n(game_rst_n),
        .I_a(I_enc1_a),
        .I_b(I_enc1_b),
        .O_tick_cw(enc1_tick_cw),
        .O_tick_ccw(enc1_tick_ccw)
    );

    wire enc2_tick_cw;
    wire enc2_tick_ccw;
    rotary_encoder enc2_inst (
        .I_clk(clk_pixel),
        .I_rst_n(game_rst_n),
        .I_a(I_enc2_a),
        .I_b(I_enc2_b),
        .O_tick_cw(enc2_tick_cw),
        .O_tick_ccw(enc2_tick_ccw)
    );

    game #(
        .GAME_W_BITS(GAME_W_BITS),
        .GAME_H_BITS(GAME_H_BITS),
        .SCORE_DIGITS(SCORE_DIGITS),
        .BALL_RESET_X((640 - 16) << 5),
        .BALL_RESET_Y((360 - 16) << 5),
        .BALL_SIZE(32 << 5),
        .PADDLE_RESET_Y((360 - 48) << 5),
        .PADDLE_BORDER_LEFT(PADDLE_LEFT_X + (16 << 5)),
        .PADDLE_BORDER_RIGHT(PADDLE_RIGHT_X),
        .SCORE_BORDER_LEFT(10 << 5),
        .SCORE_BORDER_RIGHT(1270 << 5),
        .PADDLE_SIZE(96 << 5),
        .PADDLE_SPEED(18 << 5),
        .BORDER_TOP(10 << 5),
        .BORDER_BOTTOM(710 << 5)
    ) game_inst (
        .I_clk(clk_pixel),
        .I_rst_n(game_rst_n),
        .I_start(vsync), // start processing frame when nothing is drawn
        .I_enc1_cw(enc1_tick_cw),
        .I_enc1_ccw(enc1_tick_ccw),
        .I_enc2_cw(enc2_tick_cw),
        .I_enc2_ccw(enc2_tick_ccw),
        .O_paddle_left_y(paddle_left_y),
        .O_paddle_right_y(paddle_right_y),
        .O_ball_x(ball_x),
        .O_ball_y(ball_y),
        .O_bcd_score_left(bcd_score_left),
        .O_bcd_score_right(bcd_score_right)
    );



    // paddle 16 x 96
    // ball 32 x 32

    display #(
        .CHANNEL_BITS(CHANNEL_BITS),
        .GAME_W_BITS(GAME_W_BITS),
        .GAME_H_BITS(GAME_H_BITS),
        .SCORE_DIGITS(SCORE_DIGITS),
        .SCORE_NUM_DIGITS_BITS(SCORE_NUM_DIGITS_BITS),
        .SCORE_LEFT_X(SCORE_LEFT_X),
        .SCORE_RIGHT_X(SCORE_RIGHT_X),
        .SCORE_Y(SCORE_Y),
        .PADDLE_LEFT_X(PADDLE_LEFT_X),
        .PADDLE_RIGHT_X(PADDLE_RIGHT_X)
    ) display_inst (
        .I_clk_pixel(clk_pixel),
        .I_rst_n(sys_rst_n),
        
        .I_paddle_left_y(paddle_left_y),
        .I_paddle_right_y(paddle_right_y),
        .I_ball_x(ball_x),
        .I_ball_y(ball_y),

        .I_bcd_score_left(bcd_score_left),
        .I_bcd_score_right(bcd_score_right),

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