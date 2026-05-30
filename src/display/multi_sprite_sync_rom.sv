module multi_sprite_sync_rom #(
    parameter FILE       = "digits.hex",
    parameter Z_BITS     = 4,
    parameter Z_SIZE     = 10, // does not need to be ^2
    parameter X_BITS     = 5,
    parameter Y_BITS     = 6,
    parameter COLOR_BITS = 4 // size of palette idx
)(
    input  wire                  I_clk,
    input  wire [Z_BITS-1:0]     I_z,
    input  wire [X_BITS-1:0]     I_x,
    input  wire [Y_BITS-1:0]     I_y,
    output reg [COLOR_BITS-1:0]  O_color_idx
);
    localparam DEPTH = Z_SIZE  * (1 << (X_BITS + Y_BITS));

    reg [COLOR_BITS-1:0] rom [0:DEPTH-1];

    initial begin
        $readmemh(FILE, rom);
    end

    always @(posedge I_clk) begin
        O_color_idx <= rom[{I_z, I_y, I_x}];
    end

endmodule