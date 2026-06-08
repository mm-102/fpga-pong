module game #(
    parameter GAME_W_BITS,
    parameter GAME_H_BITS,
    parameter SCORE_DIGITS,
    parameter BALL_RESET_X,
    parameter BALL_RESET_Y,
    parameter BALL_SIZE,
    parameter PADDLE_RESET_Y,
    parameter PADDLE_BORDER_LEFT,
    parameter PADDLE_BORDER_RIGHT,
    parameter SCORE_BORDER_LEFT,
    parameter SCORE_BORDER_RIGHT,
    parameter PADDLE_SIZE,
    parameter PADDLE_SPEED,
    parameter BORDER_TOP,
    parameter BORDER_BOTTOM
)(
    input wire I_clk,
    input wire I_rst_n,
    input wire I_start,
    
    input wire I_enc1_cw,
    input wire I_enc1_ccw,
    input wire I_enc2_cw,
    input wire I_enc2_ccw,

    output reg [GAME_H_BITS-1:0] O_paddle_left_y,
    output reg [GAME_H_BITS-1:0] O_paddle_right_y,
    output reg [GAME_W_BITS-1:0] O_ball_x,
    output reg [GAME_H_BITS-1:0] O_ball_y,

    output wire [(4*SCORE_DIGITS)-1:0] O_bcd_score_left,
    output wire [(4*SCORE_DIGITS)-1:0] O_bcd_score_right
);

    localparam BASE_VEL_X = GAME_W_BITS'(128);
    localparam BASE_VEL_Y = GAME_H_BITS'(80);
    localparam VEL_X_INC  = GAME_W_BITS'(12);

    reg [GAME_W_BITS-1:0] current_abs_vel_x;
    reg [GAME_H_BITS-1:0] current_abs_vel_y;

    reg [GAME_W_BITS-1:0] ball_vel_x;
    reg [GAME_H_BITS-1:0] ball_vel_y;

    reg ball_init_dir_x;
    reg left_should_score;
    reg right_should_score;

    reg marked_for_score;

    reg [GAME_H_BITS-1:0] next_paddle_left_y;
    reg [GAME_H_BITS-1:0] next_paddle_right_y;

    // Update paddle positions
    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) begin
            next_paddle_left_y <= GAME_H_BITS'(PADDLE_RESET_Y);
            next_paddle_right_y <= GAME_H_BITS'(PADDLE_RESET_Y);
        end else begin
            // Left
            if (I_enc1_cw && (next_paddle_left_y < BORDER_BOTTOM - PADDLE_SIZE))
                next_paddle_left_y <= next_paddle_left_y + PADDLE_SPEED;
            else if (I_enc1_ccw && (next_paddle_left_y > BORDER_TOP))
                next_paddle_left_y <= next_paddle_left_y - PADDLE_SPEED;

            // Right
            if (I_enc2_cw && (next_paddle_right_y < BORDER_BOTTOM - PADDLE_SIZE))
                next_paddle_right_y <= next_paddle_right_y + PADDLE_SPEED;
            else if (I_enc2_ccw && (next_paddle_right_y > BORDER_TOP))
                next_paddle_right_y <= next_paddle_right_y - PADDLE_SPEED;
        end
    end

    // "rng"
    localparam RAND_SIZE = 8;
    reg [RAND_SIZE-1:0] rand_gen;
    always_ff @(posedge I_clk or negedge I_rst_n) begin
        if (!I_rst_n) rand_gen <= RAND_SIZE'(0);
        else rand_gen <= rand_gen + 1'b1; 
    end

    // main game fsm
    typedef enum reg [3:0] {
        NEW_ROUND     = 4'd0,
        IDLE_FINISHED = 4'd1,
        IDLE_WAIT     = 4'd2,
        MOVE          = 4'd3,
        BOUNCE        = 4'd4
    } state_t;

    state_t state;

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
            marked_for_score <= 1'b0;
            current_abs_vel_x <= GAME_W_BITS'(0);
            current_abs_vel_y <= GAME_H_BITS'(0);
            ball_vel_x <= GAME_W_BITS'(0);
            ball_vel_y <= GAME_H_BITS'(0);
        end else begin
            
            left_should_score <= 1'b0;
            right_should_score <= 1'b0;

            case (state)
                NEW_ROUND: begin
                    O_ball_x <= GAME_W_BITS'(BALL_RESET_X);
                    O_ball_y <= GAME_H_BITS'(BALL_RESET_Y);
                    marked_for_score <= 1'b0;
                    ball_init_dir_x <= ~ball_init_dir_x;

                    // Fixed: Just add the random bits directly. 
                    // rand_gen[7:3] adds 0 to 31 sub-pixels to Y (~1 pixel variance)
                    // rand_gen[2:0] adds 0 to 7 sub-pixels to X (~0.2 pixel variance)
                    current_abs_vel_y <= BASE_VEL_Y + rand_gen[7:3];
                    current_abs_vel_x <= BASE_VEL_X + rand_gen[2:0];

                    // Apply starting direction safely
                    if (ball_init_dir_x) 
                        ball_vel_x <= BASE_VEL_X + rand_gen[2:0];
                    else 
                        ball_vel_x <= -(BASE_VEL_X + rand_gen[2:0]);

                    if (rand_gen[7]) 
                        ball_vel_y <= BASE_VEL_Y + rand_gen[7:3];
                    else 
                        ball_vel_y <= -(BASE_VEL_Y + rand_gen[7:3]);

                    state <= IDLE_FINISHED;
                end

                IDLE_FINISHED: begin
                    if(!I_start) state <= IDLE_WAIT;
                end

                IDLE_WAIT: begin
                    if(I_start) begin
                        state <= MOVE;
                        O_paddle_right_y <= next_paddle_right_y;
                    end
                end

                MOVE: begin
                    O_ball_x <= O_ball_x + ball_vel_x;
                    O_ball_y <= O_ball_y + ball_vel_y;
                    state <= BOUNCE;
                end

                BOUNCE: begin
                    state <= IDLE_FINISHED; 

                    // Top/Bottom
                    if (O_ball_y <= BORDER_TOP) 
                        ball_vel_y <= current_abs_vel_y;
                    else if (O_ball_y >= BORDER_BOTTOM - BALL_SIZE) 
                        ball_vel_y <= -current_abs_vel_y;

                    // Score
                    // also chack if ball x went negative
                    if (O_ball_x <= SCORE_BORDER_LEFT || O_ball_x[GAME_W_BITS-1]) begin
                        right_should_score <= 1'b1;
                        state <= NEW_ROUND;
                    end 
                    else if (O_ball_x >= SCORE_BORDER_RIGHT) begin
                        left_should_score <= 1'b1;
                        state <= NEW_ROUND;
                    end
                    
                    // Paddles
                    else if (!marked_for_score) begin
                        
                        // Left 
                        if (O_ball_x <= PADDLE_BORDER_LEFT && ball_vel_x[GAME_W_BITS-1]) begin
                            if((O_ball_y < O_paddle_left_y + PADDLE_SIZE) && (O_ball_y + BALL_SIZE > O_paddle_left_y)) begin
                                current_abs_vel_x <= current_abs_vel_x + VEL_X_INC;
                                ball_vel_x <= current_abs_vel_x + VEL_X_INC; 
                            end else begin
                                marked_for_score <= 1'b1; 
                            end
                        end 
                        
                        // Right 
                        else if (O_ball_x >= PADDLE_BORDER_RIGHT - BALL_SIZE && !ball_vel_x[GAME_W_BITS-1]) begin
                            if((O_ball_y < O_paddle_right_y + PADDLE_SIZE) && (O_ball_y + BALL_SIZE > O_paddle_right_y)) begin
                                current_abs_vel_x <= current_abs_vel_x + VEL_X_INC;
                                ball_vel_x <= -(current_abs_vel_x + VEL_X_INC);
                            end else begin
                                marked_for_score <= 1'b1;
                            end
                        end
                        
                    end
                end

                default: begin
                    state <= NEW_ROUND;
                end
            endcase
        end
    end

    // Score BCD Counters
    bcd_cntr_n #(.N(SCORE_DIGITS)) left_score_cntr (.I_clk(I_clk), .I_rst_n(I_rst_n), .I_ce(left_should_score), .O_bcd(O_bcd_score_left));
    bcd_cntr_n #(.N(SCORE_DIGITS)) right_score_cntr (.I_clk(I_clk), .I_rst_n(I_rst_n), .I_ce(right_should_score), .O_bcd(O_bcd_score_right));

endmodule