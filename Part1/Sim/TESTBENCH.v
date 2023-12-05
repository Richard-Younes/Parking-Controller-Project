module Parking_Controller_tb;

    // Inputs
    reg flr;
    reg power;
    reg clk;
    reg [27:0] ID;

    // Outputs
    wire [6:0] first_rem_BCD;
    wire [6:0] second_rem_BCD;
    wire [6:0] tot_rem_BCD_left;
    wire [6:0] tot_rem_BCD_right;
    wire red_power_led;
    wire red_wrong_led;
    wire green_led;

    // Instantiate the Unit Under Test (UUT)
    Parking_Controller uut (
        .flr(flr), 
        .power(power), 
        .clk(clk), 
        .ID (ID),
        .first_rem_BCD(first_rem_BCD), 
        .second_rem_BCD(second_rem_BCD), 
        .tot_rem_BCD_left(tot_rem_BCD_left), 
        .tot_rem_BCD_right(tot_rem_BCD_right),
        .red_power_led(red_power_led), 
        .red_wrong_led(red_wrong_led), 
        .green_led(green_led)
    );

    initial begin
        // Initialize Inputs
        flr = 0;
        power = 0;
        clk = 0;
        ID = 28'hAAAAAAA;

        // Wait 100 ns for global reset to finish
        #100;
        power = 1;

        #10;
        ID = 28'h1234567;
        #20

        #10
        ID = 28'h2023010;
        #20
        

        #10
        ID = 28'h2023010;
        #20
        

        #10
        ID = 28'h2023011;
        #20
        

        
        #10
        flr = 1;
        ID = 28'h2023011;
        #20
        flr = 0;

        // #10
        // ID = 28'h
        // #20
        // key1_on = 0;

        // #10
        // ID = 28'h
        // #20
        // key1_on = 0;

        // #10
        // ID = 28'h
        // #20
        // key1_on = 0;

        // #10
        // ID = 28'h
        // #20
        // key1_on = 0;

        // #10
        // ID = 28'h
        // #20
        // key1_on = 0;

        #1000;
        $stop;

    end
      
    // Clock generator
    always begin
        #1 clk = ~clk;
    end

endmodule
