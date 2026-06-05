module bcd_cntr_n #(
    parameter int N = 4
)(
    input  wire I_clk,
    input  wire I_rst_n,
    input  wire I_ce,
    output wire [(4*N)-1:0] O_bcd
);

    wire [N:0] carry;
    assign carry[0] = I_ce;

    genvar i;
    generate
        for (i = 0; i < N; i++) begin : gen_bcd_digits
            bcd_cntr u_digit (
                .I_clk(I_clk),
                .I_rst_n(I_rst_n),
                .I_ce(carry[i]),
                .O_q(O_bcd[(i*4) +: 4]),
                .O_carry(carry[i+1])
            );
        end
    endgenerate

endmodule