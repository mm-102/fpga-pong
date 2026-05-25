module display #( // takes all coords in game space!
    parameter CHANNEL_BITS  = 8,
    parameter GAME_W_BITS   = 16,
    parameter GAME_H_BITS   = 16,
    parameter SCORE_DIGITS  = 2,
    parameter PADDLE_LEFT_X = 3200,
    parameter PADDLE_RIGHT_X = 36736
)(
    input wire I_clk_pixel,
    input wire I_rst_n,

    input wire [GAME_H_BITS-1:0] I_paddle_left_y,
    input wire [GAME_H_BITS-1:0] I_paddle_right_y,
    input wire [GAME_W_BITS-1:0] I_ball_x,
    input wire [GAME_H_BITS-1:0] I_ball_y,

    input wire [(4*SCORE_DIGITS)-1:0] I_bcd_score_left,
    input wire [(4*SCORE_DIGITS)-1:0] I_bcd_score_right,
    
    output wire O_hsync,
    output wire O_vsync,
    output wire O_de,
    output wire [CHANNEL_BITS-1:0] O_r,
    output wire [CHANNEL_BITS-1:0] O_g,
    output wire [CHANNEL_BITS-1:0] O_b
);
    localparam PALETTE = "data/palette.hex";
    localparam PALETTE_SIZE_BITS = 4; // 16 colors

    localparam SCREEN_W      = 1280;
    localparam SCREEN_W_BITS = 11;
    localparam SCREEN_H      = 720;
    localparam SCREEN_H_BITS = 11; // for simplicity

    localparam COORD_SHIFT_X = GAME_W_BITS - SCREEN_W_BITS;
    localparam COORD_SHIFT_Y = GAME_H_BITS - SCREEN_H_BITS;

    wire hsync_raw, vsync_raw, de_raw;

    wire [SCREEN_W_BITS-1:0] screen_x;
    wire [SCREEN_H_BITS-1:0] screen_y;

    timing timing_inst (
        .I_clk_pixel(I_clk_pixel),
        .I_rst_n(I_rst_n),
        .O_hsync(hsync_raw),
        .O_vsync(vsync_raw),
        .O_de(de_raw),
        .O_x(screen_x),
        .O_y(screen_y)
    );

    wire [PALETTE_SIZE_BITS-1:0] final_color_idx;

    localparam [SCREEN_W_BITS-1:0] P_LEFT_X = PADDLE_LEFT_X[GAME_W_BITS-1 -: SCREEN_W_BITS];
    localparam [SCREEN_W_BITS-1:0] P_RIGHT_X = PADDLE_RIGHT_X[GAME_W_BITS-1 -: SCREEN_W_BITS];

    composer #(
        .PALETTE_SIZE_BITS(PALETTE_SIZE_BITS),
        .SCREEN_W(SCREEN_W),
        .SCREEN_W_BITS(SCREEN_W_BITS),
        .SCREEN_H(SCREEN_H),
        .SCREEN_H_BITS(SCREEN_H_BITS),
        .SCORE_DIGITS(SCORE_DIGITS),
        .PADDLE_LEFT_X(P_LEFT_X),
        .PADDLE_RIGHT_X(P_RIGHT_X)
    ) composer_inst (
        .I_clk_pixel(I_clk_pixel),
        .I_rst_n(I_rst_n),
        .I_x(screen_x),
        .I_y(screen_y),
        .I_paddle_left_y(I_paddle_left_y[GAME_H_BITS-1 -: SCREEN_H_BITS]),
        .I_paddle_right_y(I_paddle_right_y[GAME_H_BITS-1 -: SCREEN_H_BITS]),
        .I_ball_x(I_ball_x[GAME_W_BITS-1 -: SCREEN_W_BITS]),
        .I_ball_y(I_ball_y[GAME_H_BITS-1 -: SCREEN_H_BITS]),
        .I_bcd_score_left(I_bcd_score_left),
        .I_bcd_score_right(I_bcd_score_right),
        .O_pixel_color_idx(final_color_idx),
        .I_hsync(hsync_raw),
        .I_vsync(vsync_raw),
        .I_de(de_raw),
        .O_hsync(O_hsync),
        .O_vsync(O_vsync),
        .O_de(O_de)
    );



    wire [CHANNEL_BITS-1:0] raw_r, raw_g, raw_b;

    palette_rom #(
        .FILE(PALETTE),
        .IDX_BITS(PALETTE_SIZE_BITS),
        .CHANNEL_BITS(CHANNEL_BITS)
    ) palette_inst (
        .I_color_idx(final_color_idx),
        .O_r(raw_r),
        .O_g(raw_g),
        .O_b(raw_b)
    );

    assign O_r = O_de ? raw_r : CHANNEL_BITS'(0);
    assign O_g = O_de ? raw_g : CHANNEL_BITS'(0);
    assign O_b = O_de ? raw_b : CHANNEL_BITS'(0);

endmodule