module Parking_Controller(
    input flr, power, clk, reset,

    inout PS2_DAT,
    input PS2_CLK,
    
    //input [7:0] key1_code, // to remove
    //input key1_on, // 

    output reg [6:0] first_rem_BCD, second_rem_BCD, tot_rem_BCD_left, tot_rem_BCD_right,
    output reg red_power_led, red_wrong_led, green_led,
    output wire buffer_full, esc_pressed, ctrla_pressed,
    output wire LCD_RW, LCD_EN, LCD_RS,
    output wire [7:0] LCD_DATA,
    output wire [7:0] BCD0, BCD1, BCD2, BCD3//, BCD4, BCD5, BCD6
    
);

reg MODE, reset_keyboard;
reg [5:0] state, state_N; 
wire [27:0] ID;
reg [2:0] take_action = 0;

reg [3:0] LCD_State;
reg [5:0] t;
wire key_pressed, key2_pressed, valid_key_pressed;
wire [3:0] key;
reg [1:0] flg_inp = 0;
wire id_valid, id_special, alternative_flr_full, id_exists, user_in_floor;
wire special_flr_chosen, chosen_flr_full, adminId_valid, id_restricted;
reg [2:0] remain_flr_spec_0, remain_flr_norm_0, remain_flr_1;

reg restrict_exit;





parameter OFF = 0;
parameter INITIAL = 1;
parameter NORMAL_FSM = 2;
parameter ADMIN_FSM = 3;
parameter EXIT_FSM = 4;
parameter INPUTTING = 5;

parameter CHECK_STATE_N = 0;
parameter CHECK_FLR_N = 1;
parameter INCORRECT_N = 2;
parameter GRANTED_ALT_FLR_N = 3;
parameter GRANTED_CHOSN_FLR_N = 4;
parameter NO_SPACE_N = 5;

//***************************** The following are for the Admin FSM ************************************//

reg [3:0] state_admin;
reg led_switch =1;
reg [32:0] blinking_admin_counter = 1;

// Parameters for the Admin Sub FSM 
parameter  CHECK_ADMIN = 0;
parameter  CORRECT_ADMIN = 1;
parameter  INCORRECT_ADMIN = 2;
parameter  CHOOSE_MODE_ADMIN = 3;
parameter  OPEN_GATE_ADMIN = 4;
parameter  RESTRICT_ADMIN = 5;
parameter  CHECK_RESTRICT = 6;
parameter  CHECK_RESTRICT_CORRECT = 7;
parameter  CHECK_RESTRICT_INCORRECT = 8;
parameter ENTER_ADMIN_ID = 9;

//***************************** The following are for the Exit FSM ************************************//

reg [1:0] state_E;

parameter ENTER_EXIT_ID = 0;
parameter CHECK_STATE_E = 1;
parameter CORRECT_E = 2;
parameter INCORRECT_E = 3;

initial begin
    state = 0;
    reset_keyboard = 1;
    t = 0;
    LCD_State = 15;
    flg_inp = 0;
    remain_flr_spec_0 = 2;
    remain_flr_norm_0 = 3; // 3
    remain_flr_1 = 5; // 5
    restrict_exit = 0;
end

ps2_Main keyb(
    .CLK    (clk),
    .reset   (reset),
    .reset_keyboard   (reset_keyboard),
    .PS2_CLK    (PS2_CLK),  
    .PS2_DAT    (PS2_DAT),  
    .key_pressed    (key_pressed),
    .buffer_full    (buffer_full),
    .key2_pressed    (key2_pressed),
    .valid_key_pressed (valid_key_pressed),
    .ID   (ID),
    .key (key),
    .esc_pressed (esc_pressed),
    .ctrla_pressed (ctrla_pressed),
    .ctrl_pressed (ctrl_pressed),
    .a_pressed (a_pressed)
);

MAIN_LCD lcd_inst(
    .iCLK (clk), 
    .LCD_State (LCD_State),
    .ID (ID),
    .LCD_DATA (LCD_DATA),
    .LCD_RW (LCD_RW),
    .LCD_EN (LCD_EN),
    .LCD_RS (LCD_RS)
);

// BDC_7SEGx bcd_inst(
//     .code (ID),
//     .CLK (clk),
//     .BCD0 (BCD0), 
//     .BCD1 (BCD1), 
//     .BCD2 (BCD2), 
//     .BCD3 (BCD3), 
//     .BCD4 (BCD4), 
//     .BCD5 (BCD5), 
//     .BCD6 (BCD6)
// );



floor_id_logic logic_inst(
    .ID (ID),
    .chosen_flr (flr),
    .CLK (clk),
    .action_taken (take_action),
    .MODE (MODE), // MODE==> {0: Enter, 1: Exit} 
    .id_valid (id_valid), 
    .id_restricted (id_restricted), 
    .id_special (id_special), 
    .special_flr_chosen (special_flr_chosen), 
    .chosen_flr_full (chosen_flr_full), 
    .alternative_flr_full (alternative_flr_full), 
    .adminId_valid (adminId_valid),
    .remain_flr_spec_0 (remain_flr_spec_0), 
    .remain_flr_norm_0 (remain_flr_norm_0), 
    .remain_flr_1 (remain_flr_1),
    .id_exists (id_exists),
    .user_in_floor (user_in_floor)
);

BDC_7SEG bcd_inst(
    .remain_flr_spec_0 (remain_flr_spec_0), 
    .remain_flr_norm_0 (remain_flr_norm_0), 
    .remain_flr_1 (remain_flr_1),
    .CLK (clk),
    .BCD0 (BCD0), 
    .BCD1 (BCD1), 
    .BCD2 (BCD2), 
    .BCD3 (BCD3)
);

reg [32:0] counter = 0;

always @ (posedge clk) begin
    counter <= counter + 1;
    if (counter == 32'd49999999) begin
        t <= t + 1;
        counter <= 0;
    end
    reset_keyboard <= 1;
    case(state)
        OFF: begin
            reset_keyboard <= 1;
            state_N <= CHECK_STATE_N;
            state_admin <= ENTER_ADMIN_ID;
            if (power) begin
                state <= INITIAL;
            end else state <= OFF;
        end
        INITIAL: begin
            t <= 0;
            flg_inp <= 0;
            reset_keyboard <= 0;
            state_N <= CHECK_STATE_N;
            state_admin <= ENTER_ADMIN_ID;
            state_E <= ENTER_EXIT_ID;
            restrict_exit <= 0;
            if (!power) begin
                state <= OFF;
            end else if (valid_key_pressed) begin
                state <= INPUTTING;
            end else begin
                if (esc_pressed) begin
                    state <= EXIT_FSM;
                    reset_keyboard <= 1;
                end else if (ctrla_pressed) begin
                    state <= ADMIN_FSM;
                    reset_keyboard <= 1;
                end else state <= INITIAL;
            end
        end
        INPUTTING: begin
            reset_keyboard <= 0;
            if (!power) begin
                state <= OFF;
            end else if ((flg_inp == 1 && ctrla_pressed) || (flg_inp == 3 &&ctrla_pressed)) begin
                state <= INITIAL;
                end else if (flg_inp == 2 && esc_pressed) begin
                state <= INITIAL;
                end else begin
                if (!buffer_full) begin
                    if (t < 5 && !valid_key_pressed) begin
                        state <= INPUTTING;
                    end else if (valid_key_pressed) begin
                        state <= INPUTTING;
                        t <= 0;
                    end else if (t >= 5) begin
                        state <= INITIAL;
                        t <= 0;
                        reset_keyboard <= 1;
                    end
                end 
                else begin
                    case(flg_inp)
                        0: begin
                            state <= NORMAL_FSM;
                        end
                        1: begin
                            state <= ADMIN_FSM;
                            state_admin <= CHECK_ADMIN;
                            t <= 0;
                        end
                        2: begin
                            state <= EXIT_FSM;
                            state_E <= CHECK_STATE_E;
                            t <= 0;
                        end
                        3: begin
                            state <= ADMIN_FSM;
                            state_admin <= CHECK_RESTRICT;
                            t <= 0;
                        end
                        default: begin
                            state <= INPUTTING;
                        end
                    endcase
					t <= 0;
                end
            end
        end 
        NORMAL_FSM: begin
            if (!power) begin
                state <= OFF;
            end else begin


state <= NORMAL_FSM;
reset_keyboard <= 0;
MODE <= 0;
case(state_N)
    CHECK_STATE_N: begin
        take_action <= 0;
        if (id_special && !special_flr_chosen) begin
            state_N <= GRANTED_ALT_FLR_N;
            t <= 0;
            remain_flr_spec_0 <= remain_flr_spec_0 - 1;
        end else if (id_special && special_flr_chosen) begin
            state_N <= GRANTED_CHOSN_FLR_N;
            t <= 0;
            remain_flr_spec_0 <= remain_flr_spec_0 - 1;
        end else if (id_valid) begin
            state_N <= CHECK_FLR_N;
        end else begin
            state_N <= INCORRECT_N;
            t <= 0;
        end
    end
    CHECK_FLR_N: begin
        take_action <= 0;
        if (!chosen_flr_full) begin
            state_N <= GRANTED_CHOSN_FLR_N;
            t <= 0;
            case(flr)
            0: begin
                remain_flr_norm_0 <= remain_flr_norm_0 - 1;
            end
            1: begin
                remain_flr_1 <= remain_flr_1 - 1;
            end
            endcase
        end else begin
            if (!alternative_flr_full) begin
                state_N <= GRANTED_ALT_FLR_N;
                t <= 0;
                case(flr)
                0: begin
                    remain_flr_1 <= remain_flr_1 - 1;
                end
                1: begin
                    remain_flr_norm_0 <= remain_flr_norm_0 - 1;
                end
                endcase
            end else if(chosen_flr_full && alternative_flr_full) begin
                state_N <= NO_SPACE_N;
                t <= 0;
            end
        end
    end
    INCORRECT_N: begin
        take_action <= 0;
        if (t < 5) state_N <= INCORRECT_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 0;
            reset_keyboard <= 1;
        end
    end
    GRANTED_CHOSN_FLR_N: begin
        take_action <= 2;
        if (t < 3) state_N <= GRANTED_CHOSN_FLR_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 0;
            reset_keyboard <= 1;
        end
    end
    GRANTED_ALT_FLR_N: begin
        take_action <= 1;
        if (t < 3) state_N <= GRANTED_ALT_FLR_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 0;
            reset_keyboard <= 1;
        end
    end
    NO_SPACE_N: begin
        take_action <= 0;
        if (t < 3) state_N <= NO_SPACE_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 0;
            reset_keyboard <= 1;
        end
    end
endcase
            end
        end
        ADMIN_FSM: begin
            reset_keyboard <= 0;
            if (!power) begin
                state <= OFF;
                reset_keyboard <= 1;
                t <= 0;
            end else if (ctrla_pressed) begin
                state <= INITIAL;
                t <= 0;
                reset_keyboard <= 1;
            end else begin
                reset_keyboard <= 0;
                case (state_admin)
                    ENTER_ADMIN_ID: begin
                        flg_inp <= 1;
                        state <= INPUTTING;
                        state_admin <= CHECK_ADMIN;
                        t <= 0;
                        if (ctrla_pressed) begin
                        state <= INITIAL;
                        t <= 0;
                        reset_keyboard <= 1;
                        end
                    end
                    CHECK_ADMIN: begin
                        if (adminId_valid) begin
                            state <= ADMIN_FSM;
                            state_admin <= CORRECT_ADMIN;
                            t <= 0;
                        end else if(!adminId_valid)begin
                            state <= ADMIN_FSM;
                            state_admin <= INCORRECT_ADMIN;
                            t <= 0;
                        end else if (t >= 5) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end else if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end
                        
                    end
                    CORRECT_ADMIN: begin
                        // The following is the counter used for the blinking of green and red LED
                        blinking_admin_counter <= blinking_admin_counter + 1;
                        if(blinking_admin_counter >= 6250000) begin
                            led_switch <=  ~led_switch;
                            blinking_admin_counter <= 1;
                        end
                        if(t >= 2) begin
                            state <= ADMIN_FSM;
                            state_admin <= CHOOSE_MODE_ADMIN;
                            reset_keyboard <= 1;
                            t <= 0;
                        end else if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end else begin
                            state <= ADMIN_FSM;
                            state_admin <= CORRECT_ADMIN;
                        end   
                    end
                    INCORRECT_ADMIN: begin
                        if(t >= 5) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end else if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end else begin
                            state <= ADMIN_FSM;
                            state_admin <= INCORRECT_ADMIN;
                        end 
                    end
                    CHOOSE_MODE_ADMIN: begin
                        reset_keyboard <= 0;
                        if(valid_key_pressed == 1 && key == 1) begin
                            state_admin <= OPEN_GATE_ADMIN;
                            t <= 0;
                        end else if(valid_key_pressed == 1 && key == 2) begin
                            reset_keyboard <= 0;
                            state_admin <= RESTRICT_ADMIN;
                            reset_keyboard <= 1;
                            t <= 0;
                        end else if (t >= 5) begin
                            state <= INITIAL;
                        end else if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end else begin
                            state <= ADMIN_FSM;
                            state_admin <= CHOOSE_MODE_ADMIN;
                        end 
                    end
                    OPEN_GATE_ADMIN: begin
                        if(t >= 3) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end else if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end else begin
                            state <= ADMIN_FSM;
                            state_admin <= OPEN_GATE_ADMIN;
                        end 
                    end
                    RESTRICT_ADMIN: begin
                        flg_inp <= 3;
                        reset_keyboard <= 0;
                        state <= INPUTTING;
                        if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                        end
                    end
                    CHECK_RESTRICT: begin
                        reset_keyboard <= 0;
                        if (id_exists) begin
                            if(id_restricted)begin
                                take_action <= 5; // 5 is the Unrestrict mode
                            end else begin
                                take_action <= 4; // 4 is the Restrict mode
                            end
                            state_admin <= CHECK_RESTRICT_CORRECT;
                            state <= ADMIN_FSM;
                            t <= 0;
                        end else if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                        end else begin
                            
                            state_admin <= CHECK_RESTRICT_INCORRECT;
                            state <= ADMIN_FSM;
                            t <= 0;
                        end 
                    end
                    CHECK_RESTRICT_CORRECT: begin
                        if (t >= 5) begin
                            if(take_action == 4) begin 
                            state <= EXIT_FSM;
                            state_E <= CHECK_STATE_E;
                            restrict_exit <= 1;
                            MODE <= 1;
                            end else begin
                                state <= INITIAL;
                                
                            end
                            t <= 0;
                        end else if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                        end else begin
                            state <= ADMIN_FSM;
                            state_admin <= CHECK_RESTRICT_CORRECT;
                        end 
                        
                    end
                    CHECK_RESTRICT_INCORRECT: begin
                        if(t >= 5) begin
                            state <= INITIAL;
                            t <= 0;
                            reset_keyboard <= 1;
                        end else if (ctrla_pressed) begin
                            state <= INITIAL;
                            t <= 0;
                        end else begin
                            state <= ADMIN_FSM;
                            state_admin <= CHECK_RESTRICT_INCORRECT;
                        end 
                        
                    end
                endcase
            end
        end
        EXIT_FSM: begin 
            reset_keyboard <= 0;
            if (!power) begin
                state <= OFF;
                reset_keyboard <= 1;
            end else if (esc_pressed) begin
                state <= INITIAL;
                reset_keyboard <= 1;
            end else begin 
                state <= EXIT_FSM;
                MODE <= 1;
                case(state_E)
                    ENTER_EXIT_ID: begin
                        flg_inp <= 2;
                        state <= INPUTTING;
                        state_E <= CHECK_STATE_E;
                        counter <= 0;
                        t <= 0;
                    end
                    CHECK_STATE_E: begin
                        if (id_valid || restrict_exit ) begin
                            restrict_exit <= 0;
                            take_action <= 3;
                            state_E <= CORRECT_E;
                            counter <= 0;
                            t <= 0;
                            if (user_in_floor == 0) begin 
                                remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                            end else if(user_in_floor == 1) begin
                                remain_flr_1 <= remain_flr_1 + 1;
                            end
                        end else if (id_special) begin
                            take_action <= 3;
                            state_E <= CORRECT_E;
                            counter <= 0;
                            t <= 0;
                            remain_flr_spec_0 <= remain_flr_spec_0 + 1;
                        end else begin
                            state_E <= INCORRECT_E;
                            counter <= 0;
                            t <= 0;
                        end
                    end
                    CORRECT_E: begin
                        if (t < 3) begin
                            state_E <= CORRECT_E;
                        end else begin
                            state_E <= ENTER_EXIT_ID;
                            state <= INITIAL;
                            reset_keyboard <= 1;
                        end
                    end
                    INCORRECT_E: begin
                        if (t < 5) begin
                            state_E <= INCORRECT_E;
                            
                        end else begin
                            state_E <= ENTER_EXIT_ID;
                            state <= INITIAL;
                            reset_keyboard <= 1;
                        end
                    end
                endcase
            end
        end
        default: begin
            if (power) begin
                state <= INITIAL;
            end else state <= OFF;
        end
    endcase
    
end

always @ (state, state_N, state_admin, led_switch) begin
    case(state)
        OFF: begin
            red_power_led = 0;
            red_wrong_led = 0;
            green_led = 0;
            LCD_State = 4'd15;
        end 
        INITIAL: begin
            red_power_led = 1;
            red_wrong_led = 0;
            green_led = 0;
            LCD_State = 4'd0;
        end 
        INPUTTING: begin
            green_led = 0;
            if(flg_inp == 0) begin
            LCD_State = 4'd0;
            end else if(flg_inp == 1) begin
                LCD_State = 4'd5;
            end else if (flg_inp == 2) begin
                LCD_State = 4'd3;
            end
        end
        NORMAL_FSM: begin
            case(state_N)
            CHECK_STATE_N: begin
                LCD_State = 4'd0;
            end
            CHECK_FLR_N: begin
                LCD_State = 4'd0;
            end
            INCORRECT_N: begin
                red_wrong_led = 1;
                LCD_State = 4'd2;
            end
            GRANTED_ALT_FLR_N: begin
                green_led = 1;
                LCD_State = 4'd1;
            end
            GRANTED_CHOSN_FLR_N: begin
                green_led = 1;
                LCD_State = 4'd1;
            end
            NO_SPACE_N: begin
                LCD_State = 4'd4;
            end
            endcase
        end
        EXIT_FSM: begin
            red_power_led = 1;
            red_wrong_led = 0;
            green_led = 0;
            LCD_State = 3;
            case(state_E)
                    ENTER_EXIT_ID: begin
                        LCD_State = 3;
                        red_wrong_led = 0;
                        green_led = 0;
                    end
                    CHECK_STATE_E: begin
                        LCD_State = 3;
                        red_wrong_led = 0;
                        green_led = 0;
                    end
                    CORRECT_E: begin
                        LCD_State = 4'd14;
                        green_led = 1;
                        red_wrong_led = 0;
                    end
                    INCORRECT_E: begin
                        LCD_State = 2;
                        green_led = 0;
                        red_wrong_led = 1;
                    end
            endcase
        end
        ADMIN_FSM: begin
            red_power_led = 1;
            LCD_State = 5;
            case (state_admin)
                ENTER_ADMIN_ID: begin
                    LCD_State = 6;
                end
                CHECK_ADMIN: begin
                    LCD_State = 6;
                end
                CORRECT_ADMIN: begin
                        red_wrong_led  = led_switch;
                        green_led = led_switch;
                        LCD_State = 5;
                end
                INCORRECT_ADMIN: begin
                        red_wrong_led = 1;
                        green_led = 0;
                        LCD_State = 7;
                end
                CHOOSE_MODE_ADMIN: begin
                        red_wrong_led = 0;
                        green_led = 1;
                        LCD_State = 8;
                end
                    OPEN_GATE_ADMIN: begin
                        red_wrong_led = 0;
                        green_led = 1;
                        LCD_State = 9;
                end
                RESTRICT_ADMIN: begin
                        LCD_State = 10;
                        red_wrong_led = 0;
                        green_led = 0;
                end
                CHECK_RESTRICT: begin
                        LCD_State = 10;
                        red_wrong_led = 0;
                        green_led = 0;
                end
                CHECK_RESTRICT_CORRECT: begin
                        red_wrong_led = 0;
                        green_led = 1;
                        if (take_action == 4) begin
                            LCD_State = 11;
                        end else if (take_action == 5) begin
                            LCD_State = 12;
                        end
                end
                CHECK_RESTRICT_INCORRECT: begin
                        LCD_State = 13;
                        red_wrong_led = 1;
                        green_led = 0;
                end
                endcase
        end
    endcase
end

endmodule