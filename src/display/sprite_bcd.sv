module sprite_bcd #(
    parameter FILE = "data/digits_left.hex",
    parameter PALETTE_SIZE_BITS = 4,
    parameter BCD_X = 200,
    parameter BCD_Y = 50,
    parameter NUM_DIGITS = 2,
    parameter NUM_DIGITS_BITS = 1,
    parameter SCREEN_W_BITS = 11,
    parameter SCREEN_H_BITS = 11
)(
    input wire I_clk_pixel,
    input wire I_rst_n,

    input wire [SCREEN_W_BITS-1:0] I_screen_x,
    input wire [SCREEN_H_BITS-1:0] I_screen_y,

    input wire [(4*NUM_DIGITS)-1:0] I_new_bcd,

    output wire [PALETTE_SIZE_BITS-1:0] O_color_idx,
    output wire O_color_en
);
    localparam SPRITE_W = 32;
    localparam SPRITE_W_ALL = SPRITE_W * NUM_DIGITS;
    localparam SPRITE_H = 64;

    localparam ROM_X_BITS = 5;
    localparam ROM_X_BITS_ALL = ROM_X_BITS + NUM_DIGITS_BITS;
    localparam ROM_Y_BITS = 6;

    reg [(4*NUM_DIGITS)-1:0] bcd;

    always @(posedge I_clk_pixel or negedge I_rst_n) begin
        if (!I_rst_n) bcd <= (4*NUM_DIGITS)'(0);
        else bcd <= I_new_bcd;
    end

    wire [ROM_X_BITS_ALL-1:0] driver_rom_x;
    wire [ROM_Y_BITS-1:0] driver_rom_y;
    wire                  driver_visible;

    sprite_sync_coord #(
        .SCREEN_W_BITS(SCREEN_W_BITS),
        .SCREEN_H_BITS(SCREEN_H_BITS),
        .SPRITE_W(SPRITE_W_ALL),
        .SPRITE_H(SPRITE_H),
        .ROM_X_BITS(ROM_X_BITS_ALL),
        .ROM_Y_BITS(ROM_Y_BITS)
    ) driver (
        .I_clk(I_clk_pixel),
        .I_pixel_x(I_screen_x),
        .I_pixel_y(I_screen_y),
        .I_sprite_x(SCREEN_W_BITS'(BCD_X)),
        .I_sprite_y(SCREEN_H_BITS'(BCD_Y)),
        .O_rom_x(driver_rom_x),
        .O_rom_y(driver_rom_y),
        .O_visible(driver_visible)
    );

    wire [ROM_X_BITS-1:0] digit_rom_x = driver_rom_x[ROM_X_BITS-1:0];
    wire [NUM_DIGITS_BITS-1:0] digit_no = driver_rom_x[ROM_X_BITS_ALL-1 -: NUM_DIGITS_BITS];

    wire [3:0] digit = bcd[((NUM_DIGITS - digit_no) << 2)-1 -: 4];

    wire [PALETTE_SIZE_BITS-1:0] raw_color_idx;

    multi_sprite_sync_rom #(
        .FILE(FILE),
        .Z_BITS(4),
        .Z_SIZE(10),
        .X_BITS(ROM_X_BITS),
        .Y_BITS(ROM_Y_BITS),
        .COLOR_BITS(PALETTE_SIZE_BITS)
    ) rom (
        .I_clk(I_clk_pixel),
        .I_z(digit),
        .I_x(digit_rom_x),
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