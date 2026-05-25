module timing (
    input  wire I_clk_pixel,
    input  wire I_rst_n,
    output wire O_hsync,
    output wire O_vsync,
    output wire O_de,
    output wire [11:0] O_x,
    output wire [11:0] O_y
);

    // 1280x720 @ 60Hz timing parameters
//    localparam H_ACTIVE = 1280;
//    localparam H_FP     = 110;
//    localparam H_SYNC   = 40;
//    localparam H_BP     = 220;
//    localparam H_TOTAL  = H_ACTIVE + H_FP + H_SYNC + H_BP; // 1650

//    localparam V_ACTIVE = 720;
//    localparam V_FP     = 5;
//    localparam V_SYNC   = 5;
//    localparam V_BP     = 20;
//    localparam V_TOTAL  = V_ACTIVE + V_FP + V_SYNC + V_BP; // 750

    // 1280x720 @ 50Hz timing parameters
    localparam H_ACTIVE = 1280;
    localparam H_FP     = 440;
    localparam H_SYNC   = 40;
    localparam H_BP     = 220;
    localparam H_TOTAL  = H_ACTIVE + H_FP + H_SYNC + H_BP; // 1980

    localparam V_ACTIVE = 720;
    localparam V_FP     = 5;
    localparam V_SYNC   = 5;
    localparam V_BP     = 20;
    localparam V_TOTAL  = V_ACTIVE + V_FP + V_SYNC + V_BP; // 750

    reg [11:0] h_cnt = 0;
    reg [11:0] v_cnt = 0;

    always @(posedge I_clk_pixel or negedge I_rst_n) begin
        if (!I_rst_n) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= 0;
                if (v_cnt == V_TOTAL - 1)
                    v_cnt <= 0;
                else
                    v_cnt <= v_cnt + 1;
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end
    end

    assign O_hsync = (h_cnt >= H_ACTIVE + H_FP && h_cnt < H_ACTIVE + H_FP + H_SYNC);
    assign O_vsync = (v_cnt >= V_ACTIVE + V_FP && v_cnt < V_ACTIVE + V_FP + V_SYNC);
    assign O_de    = (h_cnt < H_ACTIVE && v_cnt < V_ACTIVE);

    assign O_x = h_cnt;
    assign O_y = v_cnt;

endmodule