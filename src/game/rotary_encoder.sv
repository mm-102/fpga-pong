module rotary_encoder (
    input  wire I_clk,
    input  wire I_rst_n,
    input  wire I_a,
    input  wire I_b,
    output reg  O_tick_cw,
    output reg  O_tick_ccw
);

    // ~1ms sampling for debounce
    reg [15:0] sample_clk;
    wire sample_en = (sample_clk == 16'd0);

    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) sample_clk <= 16'd0;
        else sample_clk <= sample_clk + 1'b1;
    end

    // Shift registers for debouncing
    reg [2:0] a_shift, b_shift;
    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            a_shift <= 3'b000;
            b_shift <= 3'b000;
        end else if (sample_en) begin
            a_shift <= {a_shift[1:0], I_a};
            b_shift <= {b_shift[1:0], I_b};
        end
    end

    // Wait for 3 identical samples to declare the line "stable"
    reg a_stable, b_stable;
    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            a_stable <= 1'b1; // Default to 1 (pull-up state)
            b_stable <= 1'b1;
        end else if (sample_en) begin
            if (a_shift == 3'b111) a_stable <= 1'b1;
            else if (a_shift == 3'b000) a_stable <= 1'b0;
            
            if (b_shift == 3'b111) b_stable <= 1'b1;
            else if (b_shift == 3'b000) b_stable <= 1'b0;
        end
    end

    // Bulletproof Quadrature State Machine
    reg [1:0] prev_state;
    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            prev_state <= 2'b11;
            O_tick_cw <= 1'b0;
            O_tick_ccw <= 1'b0;
        end else begin
            O_tick_cw <= 1'b0;
            O_tick_ccw <= 1'b0;
            
            if (sample_en) begin
                if (prev_state != {a_stable, b_stable}) begin
                    // Check all 4 valid transitions for each direction
                    case ({prev_state, a_stable, b_stable})
                        4'b00_01, 4'b01_11, 4'b11_10, 4'b10_00: O_tick_cw <= 1'b1;
                        4'b00_10, 4'b10_11, 4'b11_01, 4'b01_00: O_tick_ccw <= 1'b1;
                        default: ; // Invalid transition (ignored)
                    endcase
                    prev_state <= {a_stable, b_stable};
                end
            end
        end
    end
endmodule