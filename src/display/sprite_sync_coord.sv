module sprite_sync_coord #(
    parameter SCREEN_W_BITS = 11,
    parameter SCREEN_H_BITS = 11,
    parameter SPRITE_W      = 32, 
    parameter SPRITE_H      = 32,
    parameter ROM_X_BITS    = 5,
    parameter ROM_Y_BITS    = 5
)(
    input  wire                     I_clk,
    input  wire [SCREEN_W_BITS-1:0] I_pixel_x,
    input  wire [SCREEN_H_BITS-1:0] I_pixel_y,
    input  wire [SCREEN_W_BITS-1:0] I_sprite_x,
    input  wire [SCREEN_H_BITS-1:0] I_sprite_y,
    
    output reg  [ROM_X_BITS-1:0]    O_rom_x,
    output reg  [ROM_Y_BITS-1:0]    O_rom_y,
    output reg                      O_visible
);

    wire [SCREEN_W_BITS-1:0] right_edge  = I_sprite_x + SPRITE_W;
    wire [SCREEN_H_BITS-1:0] bottom_edge = I_sprite_y + SPRITE_H;

    always @(posedge I_clk) begin
        if ((I_pixel_x >= I_sprite_x) && (I_pixel_x < right_edge) &&
            (I_pixel_y >= I_sprite_y) && (I_pixel_y < bottom_edge)) begin
            
            O_visible <= 1'b1;
            O_rom_x      <= (I_pixel_x - I_sprite_x);
            O_rom_y      <= (I_pixel_y - I_sprite_y);
            
        end else begin
            O_visible <= 1'b0;
            O_rom_x      <= 0;
            O_rom_y      <= 0;
        end
    end

endmodule