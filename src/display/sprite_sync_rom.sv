module sprite_sync_rom #(
    parameter FILE       = "sprite.hex",
    parameter X_BITS     = 5,
    parameter Y_BITS     = 5,
    parameter Y_SIZE     = 32, // does not need to be ^2
    parameter COLOR_BITS = 4 // size of palette idx
)(
    input  wire                  I_clk,
    input  wire [X_BITS-1:0]     I_x,
    input  wire [Y_BITS-1:0]     I_y,
    output reg [COLOR_BITS-1:0]  O_color_idx
);
    localparam DEPTH = Y_SIZE * (1 << X_BITS);

    reg [COLOR_BITS-1:0] rom [0:DEPTH-1];

    initial begin
        $readmemh(FILE, rom);
    end

    always @(posedge I_clk) begin
        O_color_idx <= rom[{I_y, I_x}];
    end

endmodule