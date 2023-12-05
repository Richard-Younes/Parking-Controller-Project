module ps2_Main(
    input CLK, reset_keyboard, reset,
    input PS2_CLK, 
    inout PS2_DAT,

    output wire key_pressed, buffer_full, key2_pressed, 
    output reg valid_key_pressed = 0,
    output reg [27:0] ID,

    output reg [3:0] key,
    output reg ctrla_pressed, esc_pressed, ctrl_pressed, a_pressed
);

wire clk_ps2, key2_on, key1_on;
wire [7:0] scandata, key1_code, key2_code;
reg [2:0] digits_counter; 
// reg [3:0] key;
reg reset_ctrla = 0;

initial begin
    ID = 28'hAAAAAA;
    digits_counter = 1;
    key = 11;
end

ps2_clock_divider inst2(
    .clock_in (CLK),
    .reset (0),
    .clock_out (clk_ps2)
);

ps2_keyboard inst1(
    .iCLK_50 (CLK),
    .ps2_dat (PS2_DAT),
    .ps2_clk (PS2_CLK),
    .sys_clk (CLK),
    .reset (reset),
    .reset1 (reset),
    .scandata (scandata),
    .key1_on (key1_on),
    .key2_on (key2_on),
    .key1_code (key1_code),
    .key2_code (key2_code)
);

reg key1OnReg = 0;
reg key2OnReg = 0;
reg reset_valid_key_pressed = 0;
reg flg = 0;

always @ (posedge CLK or posedge reset_keyboard) begin
if (reset_keyboard) begin
    digits_counter <= 1;
    ID <= 28'hAAAAAAA;
    ctrl_pressed <= 0;
    ctrla_pressed <= 0;
    a_pressed <= 0;
    esc_pressed <= 0;
    reset_ctrla <= 1;
    valid_key_pressed <= 0;
    key <= 15;
end else begin 
    key1OnReg <= key1_on;
    key2OnReg <= key2_on;
    valid_key_pressed <= 0;
    ctrl_pressed <= 0;
    ctrla_pressed <= 0;
    a_pressed <= 0;
    esc_pressed <= 0;
if (key_pressed) begin
    if (key < 10 && digits_counter < 7) digits_counter <= digits_counter + 1;
    else digits_counter <= 1;
    case(key1_code)
            8'h45, 8'h70: key <= 0;
            8'h16, 8'h69: key <= 1;
            8'h1E, 8'h72: key <= 2;
            8'h26, 8'h7A: key <= 3;
            8'h25, 8'h6B: key <= 4;
            8'h2E, 8'h73: key <= 5;
            8'h36, 8'h74: key <= 6;
            8'h3D, 8'h6C: key <= 7;
            8'h3E, 8'h75: key <= 8;
            8'h46, 8'h7D: key <= 9;
            8'h14, 16'hE014: begin
                key <= 10; // ctrl
                ctrl_pressed <= 1;
            end
            8'h76: begin
                key <= 11; // esc
                esc_pressed <= 1;
            end
            8'h1C: begin
                key <= 12; // a
                a_pressed <= 1;
            end
            default: begin
            end
    endcase
    flg <= 1;
end 
if (key2_pressed) begin
    if (key1_code == 8'h14 || key1_code == 16'hE014) begin
        if (key2_code == 8'h1C) begin
            ctrla_pressed <= 1;
        end
    end
end
if (flg) begin
    if (key < 10) begin
        valid_key_pressed <= 1;
    case(digits_counter)
        3'd7: ID[3:0] <= key;
        3'd6: ID[7:4] <= key;
        3'd5: ID[11:8] <= key;
        3'd4: ID[15:12] <= key;
        3'd3: ID[19:16] <= key;
        3'd2: ID[23:20] <= key;
        3'd1: begin
            ID[23:20] <= 24'hAAAAAA;
            ID[27:24] <= key;
        end
    endcase
    flg <= 0;
    end
end
end
end

assign key_pressed = (key1_on & !key1OnReg) ? 1 : 0;
assign key2_pressed = (key2_on & !key2OnReg) ? 1 : 0;
assign buffer_full = (digits_counter == 7) ? 1 : 0;

endmodule
