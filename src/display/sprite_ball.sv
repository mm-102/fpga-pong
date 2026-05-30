module sprite_ball #(
    parameter FILE = "data/ball.hex",
    parameter PALETTE_SIZE_BITS = 4,
    parameter SCREEN_W_BITS = 11,
    parameter SCREEN_H_BITS = 11
)(
    input wire I_clk_pixel,
    input wire I_rst_n,

    input wire [SCREEN_W_BITS-1:0] I_screen_x,
    input wire [SCREEN_H_BITS-1:0] I_screen_y,

    input wire [SCREEN_W_BITS-1:0] I_new_pos_x,
    input wire [SCREEN_H_BITS-1:0] I_new_pos_y,
    
    output wire [PALETTE_SIZE_BITS-1:0] O_color_idx,
    output wire O_color_en
);

    localparam SPRITE_W = 32;
    localparam SPRITE_H = 32;
    localparam ROM_X_BITS = 5;
    localparam ROM_Y_BITS = 5;

    reg [SCREEN_W_BITS-1:0] pos_x;
    reg [SCREEN_H_BITS-1:0] pos_y;

    always @(posedge I_clk_pixel or negedge I_rst_n) begin
        if (!I_rst_n) begin
            pos_x <= SCREEN_W_BITS'(0);
            pos_y <= SCREEN_H_BITS'(0);
        end else begin
            pos_x <= I_new_pos_x;
            pos_y <= I_new_pos_y;
        end
    end

    wire [ROM_X_BITS-1:0] driver_rom_x;
    wire [ROM_Y_BITS-1:0] driver_rom_y;
    wire                  driver_visible;

    // takes 1 clock
    sprite_sync_coord #(
        .SCREEN_W_BITS(SCREEN_W_BITS),
        .SCREEN_H_BITS(SCREEN_H_BITS),
        .SPRITE_W(SPRITE_W),
        .SPRITE_H(SPRITE_H),
        .ROM_X_BITS(ROM_X_BITS),
        .ROM_Y_BITS(ROM_Y_BITS)
    ) driver (
        .I_clk(I_clk_pixel),
        .I_pixel_x(I_screen_x),
        .I_pixel_y(I_screen_y),
        .I_sprite_x(pos_x),
        .I_sprite_y(pos_y),
        .O_rom_x(driver_rom_x),
        .O_rom_y(driver_rom_y),
        .O_visible(driver_visible)
    );

    wire [PALETTE_SIZE_BITS-1:0] raw_color_idx;

    // takes 1 clock
    sprite_sync_rom #(
        .FILE(FILE),
        .X_BITS(ROM_X_BITS),
        .Y_BITS(ROM_Y_BITS),
        .Y_SIZE(SPRITE_H),
        .COLOR_BITS(PALETTE_SIZE_BITS)
    ) rom (
        .I_clk(I_clk_pixel),
        .I_x(driver_rom_x),
        .I_y(driver_rom_y),
        .O_color_idx(raw_color_idx)
    );

    // align visible from sync coord with rom
    reg visible_delayed;
    always @(posedge I_clk_pixel) begin
        visible_delayed <= driver_visible;
    end

    assign O_color_idx = raw_color_idx;
    assign O_color_en = visible_delayed && (raw_color_idx != 0);

endmodule