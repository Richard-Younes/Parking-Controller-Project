module floor_id_logic(
    input [27:0] ID,
    input chosen_flr, CLK, // MODE==> 0: Enter, 1: Exit // action_taken==> 0: Nothing, 1: Go Alternative Floor, 2: Go Chosen Floor
    input [1:0] MODE, action_taken,
    output wire id_valid, id_special, special_flr_chosen, chosen_flr_full, alternative_flr_full, adminId_valid,
    output reg [2:0] remain_flr_spec_0, remain_flr_norm_0, remain_flr_1
);

reg [95:0] users = {8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17, 8'h18, 8'h19, 8'h20, 8'h21};
reg [11:0] users_status = 12'd0;
reg [11:0] users_flr = 12'd0;
reg [15:0] special_users = {8'h00, 8'h01};
reg [1:0] special_users_status = 2'd0;
reg [1:0] special_users_flr = 2'd0;
reg [15:0] admin_users = {8'h05, 8'h06};

parameter ID_PREFIX = 20'h20230;

assign id_valid = (((
({1'b1, ID} == {users_status[11], ID_PREFIX, users[95:88]}) || ({1'b1, ID} == {users_status[10], ID_PREFIX, users[87:80]}) || ({1'b1, ID} == {users_status[9], ID_PREFIX, users[79:72]}) ||
({1'b1, ID} == {users_status[8], ID_PREFIX, users[71:64]}) || ({1'b1, ID} == {users_status[7], ID_PREFIX, users[63:56]}) || ({1'b1, ID} == {users_status[6], ID_PREFIX, users[55:48]}) ||
({1'b1, ID} == {users_status[5], ID_PREFIX, users[47:40]}) || ({1'b1, ID} == {users_status[4], ID_PREFIX, users[39:32]}) || ({1'b1, ID} == {users_status[3], ID_PREFIX, users[31:24]}) ||
({1'b1, ID} == {users_status[2], ID_PREFIX, users[23:16]}) || ({1'b1, ID} == {users_status[1], ID_PREFIX, users[15:8]})  || ({1'b1, ID} == {users_status[0], ID_PREFIX, users[7:0]}))
&& (MODE == 1) )
||
((
({1'b0, ID} == {users_status[11], ID_PREFIX, users[95:88]}) || ({1'b0, ID} == {users_status[10], ID_PREFIX, users[87:80]}) || ({1'b0, ID} == {users_status[9], ID_PREFIX, users[79:72]}) ||
({1'b0, ID} == {users_status[8], ID_PREFIX, users[71:64]}) || ({1'b0, ID} == {users_status[7], ID_PREFIX, users[63:56]}) || ({1'b0, ID} == {users_status[6], ID_PREFIX, users[55:48]}) ||
({1'b0, ID} == {users_status[5], ID_PREFIX, users[47:40]}) || ({1'b0, ID} == {users_status[4], ID_PREFIX, users[39:32]}) || ({1'b0, ID} == {users_status[3], ID_PREFIX, users[31:24]}) ||
({1'b0, ID} == {users_status[2], ID_PREFIX, users[23:16]}) || ({1'b0, ID} == {users_status[1], ID_PREFIX, users[15:8]})  || ({1'b0, ID} == {users_status[0], ID_PREFIX, users[7:0]}))
&& (!MODE) )
) ? 1 : 0;

assign id_special = ((({1'b0, ID} == {special_users_status[1], ID_PREFIX, special_users[15:8]})  || ({1'b0, ID} == {special_users_status[0], ID_PREFIX, special_users[7:0]})
&& (!MODE)) ||
(({1'b1, ID} == {special_users_status[1], ID_PREFIX, special_users[15:8]})  || ({1'b1, ID} == {special_users_status[0], ID_PREFIX, special_users[7:0]}) && (MODE == 1)))
? 1 : 0;

assign adminId_valid = ((ID == {ID_PREFIX, admin_users[15:8]}) || (ID == {ID_PREFIX, admin_users[7:0]})) ? 1 : 0;

assign special_flr_chosen = (chosen_flr == 0) ? 1 : 0;

assign chosen_flr_full = (((!chosen_flr) && (remain_flr_norm_0 == 0)) || ((chosen_flr) && (remain_flr_1 == 0))) ? 1 : 0;
assign alternative_flr_full = (((!chosen_flr) && (remain_flr_1 == 0)) || ((chosen_flr) && (remain_flr_norm_0 == 0))) ? 1 : 0;

wire [7:0] id_postfix;

assign id_postfix = ID[7:0];


initial begin
    remain_flr_spec_0 = 2;
    remain_flr_norm_0 = 3;
    remain_flr_1 = 5;
end

always @ (posedge CLK) begin
    if (MODE == 0) begin // Enter Mode
        if (id_valid && (action_taken == 1 || action_taken == 2)) begin
            case(id_postfix)
            8'h10: begin
                users_status[11] <= 1;
                if (action_taken == 1) users_flr[11] <= !chosen_flr;
                else if (action_taken == 2) users_flr[11] <= chosen_flr; 
            end 
            8'h11: begin
                users_status[10] <= 1;
                if (action_taken == 1) users_flr[10] <= !chosen_flr;
                else if (action_taken == 2) users_flr[10] <= chosen_flr; 
            end
            8'h12: begin
                users_status[9] <= 1;
                if (action_taken == 1) users_flr[9] <= !chosen_flr;
                else if (action_taken == 2) users_flr[9] <= chosen_flr; 
            end
            8'h13: begin
                users_status[8] <= 1;
                if (action_taken == 1) users_flr[8] <= !chosen_flr;
                else if (action_taken == 2) users_flr[8] <= chosen_flr; 
            end
            8'h14: begin
                users_status[7] <= 1;
                if (action_taken == 1) users_flr[7] <= !chosen_flr;
                else if (action_taken == 2) users_flr[7] <= chosen_flr; 
            end
            8'h15: begin
                users_status[6] <= 1;
                if (action_taken == 1) users_flr[6] <= !chosen_flr;
                else if (action_taken == 2) users_flr[6] <= chosen_flr; 
            end
            8'h16: begin
                users_status[5] <= 1;
                if (action_taken == 1) users_flr[5] <= !chosen_flr;
                else if (action_taken == 2) users_flr[5] <= chosen_flr; 
            end
            8'h17: begin
                users_status[4] <= 1;
                if (action_taken == 1) users_flr[4] <= !chosen_flr;
                else if (action_taken == 2) users_flr[4] <= chosen_flr; 
            end
            8'h18: begin
                users_status[3] <= 1;
                if (action_taken == 1) users_flr[3] <= !chosen_flr;
                else if (action_taken == 2) users_flr[3] <= chosen_flr; 
            end
            8'h19: begin
                users_status[2] <= 1;
                if (action_taken == 1) users_flr[2] <= !chosen_flr;
                else if (action_taken == 2) users_flr[2] <= chosen_flr; 
            end
            8'h20: begin
                users_status[1] <= 1;
                if (action_taken == 1) users_flr[1] <= !chosen_flr;
                else if (action_taken == 2) users_flr[1] <= chosen_flr; 
            end
            8'h21: begin
                users_status[0] <= 1;
                if (action_taken == 1) users_flr[0] <= !chosen_flr;
                else if (action_taken == 2) users_flr[0] <= chosen_flr; 
            end
            default: begin
                
            end
            endcase
            if (action_taken == 1) begin //Alt
                case(chosen_flr)
                0: begin
                    remain_flr_1 <= remain_flr_1 - 1;
                end
                1: begin
                    remain_flr_norm_0 <= remain_flr_norm_0 - 1;
                end
                endcase
            end else if (action_taken == 2) begin //Chosn
                case(chosen_flr)
                0: begin
                    remain_flr_norm_0 <= remain_flr_norm_0 - 1;
                end
                1: begin
                    remain_flr_1 <= remain_flr_1 - 1;
                end
                endcase
            end
        end
    end else if (MODE == 1) begin // Exit Mode
        if (id_valid && (action_taken == 3)) begin
            case(id_postfix)
            8'h10: begin
                users_status[11] <= 0;
                if(users_flr[11]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end 
            8'h11: begin
                users_status[10] <= 0;
                if(users_flr[10]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h12: begin
                users_status[9] <= 0;
                if(users_flr[9]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h13: begin
                users_status[8] <= 0;
                if(users_flr[8]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h14: begin
                users_status[7] <= 0;
                if(users_flr[7]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h15: begin
                users_status[6] <= 0;
                if(users_flr[6]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h16: begin
                users_status[5] <= 0;
                if(users_flr[5]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h17: begin
                users_status[4] <= 0;
                if(users_flr[4]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h18: begin
                users_status[3] <= 0;
                if(users_flr[3]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h19: begin
                users_status[2] <= 0;
                if(users_flr[2]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h20: begin
                users_status[1] <= 0;
                if(users_flr[1]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            8'h21: begin
                users_status[0] <= 0;
                if(users_flr[0]) begin
                    remain_flr_1 <= remain_flr_1 + 1;
                end else begin
                    remain_flr_norm_0 <= remain_flr_norm_0 + 1;
                end
            end
            default: begin
                
            end
            endcase
        end
    end else if (MODE == 2) begin // Restrict Mode
        
    end
end



endmodule