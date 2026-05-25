module palette_rom #(
    parameter FILE         = "data/palette.hex",
    parameter IDX_BITS     = 4,
    parameter CHANNEL_BITS = 8
)(
    input  wire [IDX_BITS-1:0]     I_color_idx,
    output wire [CHANNEL_BITS-1:0] O_r,
    output wire [CHANNEL_BITS-1:0] O_g,
    output wire [CHANNEL_BITS-1:0] O_b
);
    localparam DEPTH      = 1 << IDX_BITS;
    localparam TOTAL_BITS = 3 * CHANNEL_BITS;

    reg [TOTAL_BITS-1:0] rom [0:DEPTH-1];

    initial begin
        $readmemh(FILE, rom);
    end

    wire [TOTAL_BITS-1:0] full_color = rom[I_color_idx];

    assign O_r = full_color[TOTAL_BITS-1     : 2*CHANNEL_BITS];
    assign O_g = full_color[2*CHANNEL_BITS-1 : 1*CHANNEL_BITS];
    assign O_b = full_color[CHANNEL_BITS-1   : 0];

endmodule