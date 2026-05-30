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


    CLKDIV u_clkdiv (
        .RESETN(sys_rst_n),
        .HCLKIN(clk_serial), 
        .CLKOUT(clk_pixel),  
        .CALIB (1'b1)
    );
    defparam u_clkdiv.DIV_MODE = "5";
    defparam u_clkdiv.GSREN = "false";

    
    

    // temp
    localparam BASE_SPEED_X = 12;
    localparam BASE_SPEED_Y = 3;
    reg [GAME_W_BITS-1:0] speed_x = GAME_W_BITS'(BASE_SPEED_X);
    reg [GAME_W_BITS-1:0] speed_y = GAME_W_BITS'(BASE_SPEED_Y);
    reg [GAME_W_BITS-1:0] ball_x = GAME_W_BITS'(19968);
    reg [GAME_H_BITS-1:0] ball_y = GAME_H_BITS'(11008);
    reg [16:0] div;

    always @(posedge clk_pixel or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            ball_x <= GAME_W_BITS'(19968);
            ball_y <= GAME_H_BITS'(11008);
        end else if (clk_pixel) begin
            div <= div + 1;
            if (div == 16'b0) begin
                if (ball_x < (10 << 5)) speed_x <= BASE_SPEED_X;
                else if (ball_x > (1238 << 5)) speed_x <= -BASE_SPEED_X;

                if (ball_y < (10 << 5)) speed_y <= BASE_SPEED_Y;
                else if (ball_y > (678 << 5)) speed_y <= -BASE_SPEED_Y;

                ball_x <= ball_x + speed_x;
                ball_y <= ball_y + speed_y;
            end
        end
    end


    wire hsync, vsync, de;
    wire [CHANNEL_BITS-1:0] r, g, b;

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
        
        // TODO game logic
        .I_paddle_left_y(GAME_H_BITS'(9984)),
        .I_paddle_right_y(GAME_H_BITS'(9984)),
        //.I_ball_x(GAME_W_BITS'(19968)),
        //.I_ball_y(GAME_H_BITS'(11008)),
        .I_ball_x(ball_x),
        .I_ball_y(ball_y),

        .I_bcd_score_left(12'h123),
        .I_bcd_score_right(12'h789),

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