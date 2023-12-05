module Parking_Controller(
    input flr, power, clk,

    // inout PS2_DAT,
    // input PS2_CLK,
    
    input [27:0] ID, 

    output reg [6:0] first_rem_BCD, second_rem_BCD, tot_rem_BCD_left, tot_rem_BCD_right,
    output reg red_power_led, red_wrong_led, green_led,
    output wire buffer_full, esc_pressed, ctrla_pressed
    // output wire LCD_RW, LCD_EN, LCD_RS,
    // output wire [7:0] LCD_DATA,
    // output wire [7:0] BCD0, BCD1, BCD2, BCD3, BCD4, BCD5, BCD6
    
);

reg reset, dec_flr_0, dec_flr_1;
reg [5:0] state, state_N;
reg [1:0] take_action, MODE;

reg [3:0] LCD_State;
reg [5:0] t;
wire key_pressed, key2_pressed, valid_key_pressed;
wire [3:0] key;
reg [1:0] flg_inp = 0;
wire id_valid, id_special, alternative_flr_full;
wire special_flr_chosen, chosen_flr_full, adminId_valid;
wire [2:0] remain_flr_spec_0, remain_flr_norm_0, remain_flr_1;






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

initial begin
    state = 0;
    state_N = 0;
    reset = 1;
    t = 0;
    LCD_State = 15;
    flg_inp = 0;
end

// ps2_Main keyb(
//     .CLK    (clk),
//     .reset   (reset),
//     .PS2_CLK    (PS2_CLK),   //
//     .PS2_DAT    (PS2_DAT),  //
//     .key_pressed    (key_pressed),
//     .buffer_full    (buffer_full),
//     .key2_pressed    (key2_pressed),
//     .valid_key_pressed (valid_key_pressed),
//     .ID   (ID),
//     .key (key),
//     .esc_pressed (esc_pressed),
//     .ctrla_pressed (ctrla_pressed),
//     .ctrl_pressed (ctrl_pressed),
//     .a_pressed (a_pressed)
// );

// MAIN_LCD lcd_inst(
//     .iCLK (clk), 
//     .LCD_State (LCD_State),
//     .ID (ID),
//     .LCD_DATA (LCD_DATA),
//     .LCD_RW (LCD_RW),
//     .LCD_EN (LCD_EN),
//     .LCD_RS (LCD_RS)
// );

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
    .id_special (id_special), 
    .special_flr_chosen (special_flr_chosen), 
    .chosen_flr_full (chosen_flr_full), 
    .alternative_flr_full (alternative_flr_full), 
    .adminId_valid (adminId_valid),
    .remain_flr_spec_0 (remain_flr_spec_0), 
    .remain_flr_norm_0 (remain_flr_norm_0), 
    .remain_flr_1 (remain_flr_1)
);

// BDC_7SEG bcd_inst(
//     .remain_flr_spec_0 (remain_flr_spec_0), 
//     .remain_flr_norm_0 (remain_flr_norm_0), 
//     .remain_flr_1 (remain_flr_1),
//     .CLK (clk),
//     .BCD0 (BCD0), 
//     .BCD1 (BCD1), 
//     .BCD2 (BCD2), 
//     .BCD3 (BCD3)
// );

reg [32:0] counter = 0;

always @ (posedge clk) begin
t <= t + 1;
take_action <= 0;
reset <= 0;
MODE <= 0;
state <= NORMAL_FSM;
reset <= 0;
MODE <= 0;
case(state_N)
    CHECK_STATE_N: begin
        if (id_valid) begin
            state_N <= CHECK_FLR_N;
            if (id_special && !special_flr_chosen) begin
                state_N <= GRANTED_ALT_FLR_N;
                t <= 0;
            end else if (id_special && special_flr_chosen) begin
                state_N <= GRANTED_CHOSN_FLR_N;
                t <= 0;
            end
        end else begin
            state_N <= INCORRECT_N;
            t <= 0;
        end
    end
    CHECK_FLR_N: begin
        if (!chosen_flr_full) begin
            state_N <= GRANTED_CHOSN_FLR_N;
            t <= 0;
        end else begin
            if (!alternative_flr_full) begin
                state_N <= GRANTED_ALT_FLR_N;
                t <= 0;
            end else begin
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
        end
    end
    GRANTED_CHOSN_FLR_N: begin
        take_action <= 2;
        if (t < 3) state_N <= GRANTED_CHOSN_FLR_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 0;
        end
    end
    GRANTED_ALT_FLR_N: begin
        take_action <= 1;
        if (t < 3) state_N <= GRANTED_ALT_FLR_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 0;
        end
    end
    NO_SPACE_N: begin
        take_action <= 0;
        if (t < 3) state_N <= NO_SPACE_N;
        else begin
            state_N <= CHECK_STATE_N;
            state <= INITIAL;
            t <= 0;
        end
    end
endcase


end

always @ (state, state_N) begin

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

endmodule

// set_location_assignment PIN_AC17 -to first_rem_BCD[6]
// set_location_assignment PIN_AA15 -to first_rem_BCD[5]
// set_location_assignment PIN_AB15 -to first_rem_BCD[4]
// set_location_assignment PIN_AB17 -to first_rem_BCD[3]
// set_location_assignment PIN_AA16 -to first_rem_BCD[2]
// set_location_assignment PIN_AB16 -to first_rem_BCD[1]
// set_location_assignment PIN_AA17 -to first_rem_BCD[0]

// set_location_assignment PIN_AE18 -to second_rem_BCD[6]
// set_location_assignment PIN_AF19 -to second_rem_BCD[5]
// set_location_assignment PIN_AE19 -to second_rem_BCD[4]
// set_location_assignment PIN_AH21 -to second_rem_BCD[3]
// set_location_assignment PIN_AG21 -to second_rem_BCD[2]
// set_location_assignment PIN_AA19 -to second_rem_BCD[1]
// set_location_assignment PIN_AB19 -to second_rem_BCD[0]

// set_location_assignment PIN_U24 -to tot_rem_BCD_left[6]
// set_location_assignment PIN_U23 -to tot_rem_BCD_left[5]
// set_location_assignment PIN_W25 -to tot_rem_BCD_left[4]
// set_location_assignment PIN_W22 -to tot_rem_BCD_left[3]
// set_location_assignment PIN_W21 -to tot_rem_BCD_left[2]
// set_location_assignment PIN_Y22 -to tot_rem_BCD_left[1]
// set_location_assignment PIN_M24 -to tot_rem_BCD_left[0]

// set_location_assignment PIN_H22 -to tot_rem_BCD_right[6]
// set_location_assignment PIN_J22 -to tot_rem_BCD_right[5]
// set_location_assignment PIN_L25 -to tot_rem_BCD_right[4]
// set_location_assignment PIN_L26 -to tot_rem_BCD_right[3]
// set_location_assignment PIN_E17 -to tot_rem_BCD_right[2]
// set_location_assignment PIN_F22 -to tot_rem_BCD_right[1]
// set_location_assignment PIN_G18 -to tot_rem_BCD_right[0]

// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[6]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[5]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[4]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[3]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[2]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[1]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to first_rem_BCD[0]

// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[6]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[5]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[4]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[3]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[2]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[1]
// set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to second_rem_BCD[0]

// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[6]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[5]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[4]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[3]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[2]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[1]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_left[0]

// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[6]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[5]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[4]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[3]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[2]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[1]
// set_instance_assignment -name IO_STANDARD "2.5 V" -to tot_rem_BCD_right[0]