module composer #( // takes all coords in screen space!
    parameter PALETTE_SIZE_BITS = 4,
    parameter SCREEN_W      = 1280,
    parameter SCREEN_W_BITS = 11,
    parameter SCREEN_H      = 720,
    parameter SCREEN_H_BITS = 11,
    parameter SCORE_DIGITS  = 2,
    parameter PADDLE_LEFT_X = 100,
    parameter PADDLE_RIGHT_X = 1148
)(
    input wire I_clk_pixel,
    input wire I_rst_n,
    input wire [SCREEN_W_BITS-1:0] I_x,
    input wire [SCREEN_H_BITS-1:0] I_y,
    input wire [SCREEN_W_BITS-1:0] I_paddle_left_x,
    input wire [SCREEN_H_BITS-1:0] I_paddle_left_y,
    input wire [SCREEN_W_BITS-1:0] I_paddle_right_x,
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


    // assign final color
    always @(*) begin
        if (border_d[1]) O_pixel_color_idx = PALETTE_SIZE_BITS'(1);
        else O_pixel_color_idx = PALETTE_SIZE_BITS'(0);
    end

    // assign delayed sync signals
    assign O_hsync = hsync_d[1];
    assign O_vsync = vsync_d[1];
    assign O_de = de_d[1];

endmodule