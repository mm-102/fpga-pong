module game #(
    parameter GAME_W_BITS = 16,
    parameter GAME_H_BITS = 16,
    parameter SCORE_DIGITS  = 2,
    parameter BALL_RESET_X = 19968,
    parameter BALL_RESET_Y = 11008,
    parameter BALL_SIZE = (32 << 5),
    parameter PADDLE_RESET_Y = 9984,
    parameter PADDLE_BORDER_LEFT = 3200 + (16 << 5),
    parameter PADDLE_BORDER_RIGHT = 37248,
    parameter PADDLE_SIZE = (96 << 5),
    parameter BORDER_TOP = (10 << 5),
    parameter BORDER_BOTTOM = (710 << 5)
)(
    input wire I_clk,
    input wire I_rst_n,
    input wire I_start,

    output reg [GAME_H_BITS-1:0] O_paddle_left_y,
    output reg [GAME_H_BITS-1:0] O_paddle_right_y,
    output reg [GAME_W_BITS-1:0] O_ball_x,
    output reg [GAME_H_BITS-1:0] O_ball_y,

    output wire [(4*SCORE_DIGITS)-1:0] O_bcd_score_left,
    output wire [(4*SCORE_DIGITS)-1:0] O_bcd_score_right
);

    localparam BASE_VEL_X = GAME_W_BITS'(96); // 3 pixels per frame (3 << 5)
    localparam BASE_VEL_Y = GAME_H_BITS'(80); // 1 pixel per frame (1 << 5)

    reg [GAME_W_BITS-1:0] ball_abs_vel_x = GAME_W_BITS'(0);
    reg [GAME_H_BITS-1:0] ball_abs_vel_y = GAME_H_BITS'(0);

    wire [GAME_W_BITS-1:0] ball_neg_vel_x = -ball_abs_vel_x;
    wire [GAME_H_BITS-1:0] ball_neg_vel_y = -ball_abs_vel_y;

    reg [GAME_W_BITS-1:0] ball_vel_x;
    reg [GAME_H_BITS-1:0] ball_vel_y;

    reg ball_init_dir_x;

    reg left_should_score;
    reg right_should_score;


    // "RNG"
    localparam RAND_Y_SIZE = 5;
    reg [RAND_Y_SIZE-1:0] rand_y_gen;
    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            rand_y_gen <= RAND_Y_SIZE'(0);
        end else begin
            rand_y_gen <= rand_y_gen + 1'b1; 
        end
    end


    typedef enum reg [3:0] {
        NEW_ROUND     = 4'd0,
        IDLE_FINISHED = 4'd1,
        IDLE_WAIT     = 4'd2,
        MOVE          = 4'd3,
        BOUNCE        = 4'd4

    } state_t;

    state_t state = NEW_ROUND;

    always_ff @(posedge I_clk or negedge I_rst_n) begin

        if(!I_rst_n) begin
            state <= NEW_ROUND;
            O_paddle_left_y <= GAME_H_BITS'(PADDLE_RESET_Y);
            O_paddle_right_y <= GAME_H_BITS'(PADDLE_RESET_Y);
            O_ball_x <= GAME_W_BITS'(BALL_RESET_X);
            O_ball_y <= GAME_H_BITS'(BALL_RESET_Y);
            ball_init_dir_x <= 1'b0;
            left_should_score <= 1'b0;
            right_should_score <= 1'b0;
        end else begin

            left_should_score <= 1'b0;
            right_should_score <= 1'b0;
            
            case (state)
                NEW_ROUND: begin
                    O_ball_x <= GAME_W_BITS'(BALL_RESET_X);
                    O_ball_y <= GAME_H_BITS'(BALL_RESET_Y);
                    ball_init_dir_x <= ~ball_init_dir_x;

                    if (ball_init_dir_x) begin
                        ball_vel_x <= BASE_VEL_X;
                    end else begin
                        ball_vel_x <= -BASE_VEL_X;
                    end
                    ball_abs_vel_y = BASE_VEL_Y + {1'b0, rand_y_gen[RAND_Y_SIZE-2:0], (8-1-(RAND_Y_SIZE-1))'(0)};

                    if (rand_y_gen[RAND_Y_SIZE-1]) begin
                        ball_vel_y <= ball_abs_vel_y;
                    end else begin
                        ball_vel_y <= -ball_abs_vel_y;
                    end

                    state <= IDLE_FINISHED;
                end

                IDLE_FINISHED: begin
                    if(!I_start) state <= IDLE_WAIT;
                end

                IDLE_WAIT: begin
                    if(I_start) state <= MOVE;
                end

                MOVE: begin
                    O_ball_x <= O_ball_x + ball_vel_x;
                    O_ball_y <= O_ball_y + ball_vel_y;
                    state <= BOUNCE;
                end

                BOUNCE: begin
                    state <= IDLE_FINISHED;
                    if (O_ball_y <= BORDER_TOP) ball_vel_y <= ball_abs_vel_y;
                    else if (O_ball_y >= BORDER_BOTTOM - BALL_SIZE) ball_vel_y <= -ball_abs_vel_y;

                    if (O_ball_x <= PADDLE_BORDER_LEFT) begin
                        if((O_ball_y < O_paddle_left_y + PADDLE_SIZE) &&
                           (O_ball_y + BALL_SIZE > O_paddle_left_y)) begin
                           ball_vel_x <= ball_abs_vel_x;
                           state <= IDLE_FINISHED;
                        end else begin
                            right_should_score <= 1'b1;
                            state <= NEW_ROUND;
                        end
                    end else if (O_ball_x >= PADDLE_BORDER_RIGHT - BALL_SIZE) begin
                        if((O_ball_y < O_paddle_right_y + PADDLE_SIZE) &&
                           (O_ball_y + BALL_SIZE > O_paddle_right_y)) begin
                           ball_vel_x <= ball_neg_vel_x;
                           state <= IDLE_FINISHED;
                        end else begin
                            left_should_score <= 1'b1;
                            state <= NEW_ROUND;
                        end
                    end
                end

                default: begin
                    state <= NEW_ROUND;
                end
            endcase

        end // if else

    end // always_ff


    bcd_cntr_n # (
        .N(SCORE_DIGITS)
    ) left_score_cntr (
        .I_clk(I_clk),
        .I_rst_n(I_rst_n),
        .I_ce(left_should_score),
        .O_bcd(O_bcd_score_left)
    );

    bcd_cntr_n # (
        .N(SCORE_DIGITS)
    ) right_score_cntr (
        .I_clk(I_clk),
        .I_rst_n(I_rst_n),
        .I_ce(right_should_score),
        .O_bcd(O_bcd_score_right)
    );

endmodule