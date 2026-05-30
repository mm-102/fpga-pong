module composer #( // takes all coords in screen space!
    parameter PALETTE_SIZE_BITS = 4,
    parameter SCREEN_W      = 1280,
    parameter SCREEN_W_BITS = 11,
    parameter SCREEN_H      = 720,
    parameter SCREEN_H_BITS = 11,
    parameter SCORE_DIGITS  = 2,
    parameter SCORE_NUM_DIGITS_BITS = 1,
    parameter SCORE_LEFT_X = 528,
    parameter SCORE_RIGHT_X = 656,
    parameter SCORE_Y = 50,
    parameter PADDLE_LEFT_X = 100,
    parameter PADDLE_RIGHT_X = 1164
)(
    input wire I_clk_pixel,
    input wire I_rst_n,
    input wire [SCREEN_W_BITS-1:0] I_x,
    input wire [SCREEN_H_BITS-1:0] I_y,
    input wire [SCREEN_H_BITS-1:0] I_paddle_left_y,
    input wire [SCREEN_H_BITS-1:0] I_paddle_right_y,
    input wire [SCREEN_W_BITS-1:0] I_ball_x,
    input wire [SCREEN_H_BITS-1:0] I_ball_y,

    input wire [(4*SCORE_DIGITS)-1:0] I_bcd_score_left,
    input wire [(4*SCORE_DIGITS)-1:0] I_bcd_score_right,

    output reg [PALETTE_SIZE_BITS-1:0] O_pixel_color_idx,

    // composer controls delay of display
    input wire I_hsync,
    input wire I_vsync,
    input wire I_de,
    output wire O_hsync,
    output wire O_vsync,
    output wire O_de
);

    localparam BORDER_SIZE = 10;

    // signals delayed by 2 ticks
    reg [1:0] hsync_d, vsync_d, de_d, border_d;
    
    wire is_border = (I_x < BORDER_SIZE) || (I_x >= SCREEN_W - BORDER_SIZE) || (I_y < BORDER_SIZE) || (I_y >= SCREEN_H - BORDER_SIZE);

    always @(posedge I_clk_pixel) begin
        hsync_d  <= {hsync_d[0], I_hsync};
        vsync_d  <= {vsync_d[0], I_vsync};
        de_d     <= {de_d[0], I_de};
        border_d <= {border_d[0], is_border}; // Delay border calc to match sprites
    end


    // paddle left
    wire [PALETTE_SIZE_BITS-1:0] p_l_idx;
    wire p_l_en;
    sprite_paddle #(
        .FILE("data/paddle_left.hex"),
        .PALETTE_SIZE_BITS(PALETTE_SIZE_BITS),
        .PADDLE_X(PADDLE_LEFT_X),
        .SCREEN_W_BITS(SCREEN_W_BITS),
        .SCREEN_H_BITS(SCREEN_H_BITS)
    ) paddle_left (
        .I_clk_pixel(I_clk_pixel),
        .I_rst_n(I_rst_n),
        .I_screen_x(I_x),
        .I_screen_y(I_y),
        .I_new_pos_y(I_paddle_left_y),
        .O_color_idx(p_l_idx),
        .O_color_en(p_l_en)
    );

    // paddle right
    wire [PALETTE_SIZE_BITS-1:0] p_r_idx;
    wire p_r_en;
    sprite_paddle #(
        .FILE("data/paddle_right.hex"),
        .PALETTE_SIZE_BITS(PALETTE_SIZE_BITS),
        .PADDLE_X(PADDLE_RIGHT_X),
        .SCREEN_W_BITS(SCREEN_W_BITS),
        .SCREEN_H_BITS(SCREEN_H_BITS)
    ) paddle_right (
        .I_clk_pixel(I_clk_pixel),
        .I_rst_n(I_rst_n),
        .I_screen_x(I_x),
        .I_screen_y(I_y),
        .I_new_pos_y(I_paddle_right_y),
        .O_color_idx(p_r_idx),
        .O_color_en(p_r_en)
    );

    //ball
    wire [PALETTE_SIZE_BITS-1:0] ball_idx;
    wire ball_en;
    sprite_ball #(
        .FILE("data/ball.hex"),
        .PALETTE_SIZE_BITS(PALETTE_SIZE_BITS),
        .SCREEN_W_BITS(SCREEN_W_BITS),
        .SCREEN_H_BITS(SCREEN_H_BITS)
    ) ball (
        .I_clk_pixel(I_clk_pixel),
        .I_rst_n(I_rst_n),
        .I_screen_x(I_x),
        .I_screen_y(I_y),
        .I_new_pos_x(I_ball_x),
        .I_new_pos_y(I_ball_y),
        .O_color_idx(ball_idx),
        .O_color_en(ball_en)
    );

    //score left
    wire [PALETTE_SIZE_BITS-1:0] score_left_idx;
    wire score_left_en;
    sprite_bcd #(
        .FILE("data/digits_left.hex"),
        .PALETTE_SIZE_BITS(PALETTE_SIZE_BITS),
        .BCD_X(SCORE_LEFT_X),
        .BCD_Y(SCORE_Y),
        .NUM_DIGITS(SCORE_DIGITS),
        .NUM_DIGITS_BITS(SCORE_NUM_DIGITS_BITS),
        .SCREEN_W_BITS(SCREEN_W_BITS),
        .SCREEN_H_BITS(SCREEN_H_BITS)
    ) score_left (
        .I_clk_pixel(I_clk_pixel),
        .I_rst_n(I_rst_n),
        .I_screen_x(I_x),
        .I_screen_y(I_y),
        .I_new_bcd(I_bcd_score_left),
        .O_color_idx(score_left_idx),
        .O_color_en(score_left_en)
    );

    //score right
    wire [PALETTE_SIZE_BITS-1:0] score_right_idx;
    wire score_right_en;
    sprite_bcd #(
        .FILE("data/digits_right.hex"),
        .PALETTE_SIZE_BITS(PALETTE_SIZE_BITS),
        .BCD_X(SCORE_RIGHT_X),
        .BCD_Y(SCORE_Y),
        .NUM_DIGITS(SCORE_DIGITS),
        .NUM_DIGITS_BITS(SCORE_NUM_DIGITS_BITS),
        .SCREEN_W_BITS(SCREEN_W_BITS),
        .SCREEN_H_BITS(SCREEN_H_BITS)
    ) score_right (
        .I_clk_pixel(I_clk_pixel),
        .I_rst_n(I_rst_n),
        .I_screen_x(I_x),
        .I_screen_y(I_y),
        .I_new_bcd(I_bcd_score_right),
        .O_color_idx(score_right_idx),
        .O_color_en(score_right_en)
    );

    // assign final color
    always @(*) begin
        if(border_d[1]) O_pixel_color_idx = PALETTE_SIZE_BITS'(1);
        else if (p_l_en || p_r_en) O_pixel_color_idx = p_l_idx | p_r_idx;
        else if (p_r_en) O_pixel_color_idx = p_r_idx;
        else if (ball_en) O_pixel_color_idx = ball_idx;
        else if (score_left_en || score_right_en) O_pixel_color_idx = score_left_idx | score_right_idx;
        else O_pixel_color_idx = PALETTE_SIZE_BITS'(0);
    end

    // assign delayed sync signals
    assign O_hsync = hsync_d[1];
    assign O_vsync = vsync_d[1];
    assign O_de = de_d[1];

endmodule