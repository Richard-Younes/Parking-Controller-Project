module MAIN_LCD(
    iCLK, SafeGuard_State,
    LCD_DATA,LCD_RW,LCD_EN,LCD_RS
);

input			iCLK;
input   [2:0]   SafeGuard_State;
output	[7:0]	LCD_DATA;
output			LCD_RW,LCD_EN,LCD_RS;
wire clk;

reg [127:0] line1, line2;

always @ (SafeGuard_State) begin
    case(SafeGuard_State)
        2'd0: begin
				line1 = "Armed           "; 
				line2 = "Enter Pass Key  ";
			end
        2'd1: begin
				line1 = "Wrong Pass Key  ";
				line2 = "Safeguard locked";
			end
			
        2'd2: begin 
				line1 = "Safeguard       ";
				line2 = "Is Opened       ";
			end
        default: begin
				line1 = "                ";
				line2 = "                ";
			end
    endcase
end

LCD_CDivider inst1 (
    .clock_in (iCLK),
    .reset (0),
    .clock_out (clk)
);

LCD inst2(
    .iCLK (iCLK),
    .iRST_N (clk),
    .line1 (line1),
    .line2 (line2),
    .LCD_DATA (LCD_DATA),
    .LCD_RW (LCD_RW),
    .LCD_EN (LCD_EN),
    .LCD_RS (LCD_RS)
);

endmodule