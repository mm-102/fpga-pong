module bcd_cntr (
    input  wire I_clk,
    input  wire I_rst_n,
    input  wire I_ce,
    output reg [3:0] O_q,
    output wire O_carry
);

    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            O_q <= 4'd0;
        end else if (I_ce) begin
            if (O_q == 4'd9) begin
                O_q <= 4'd0;
            end else begin
                O_q <= O_q + 1'b1;
            end
        end
    end

    assign O_carry = I_ce && (O_q == 4'd9);

endmodule