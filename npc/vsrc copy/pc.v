module pc(
    input rst, clk,
    input [31: 0] next_pc,
    input  ecall_branch,
    input [31: 0] in_pc,
    output reg [31: 0] pc
);

always @(posedge clk) begin
    if(rst) pc <= 32'h80000000;
        else if (ecall_branch) 
    begin 
        pc <= in_pc;
        $display("next_pc = %h  in_pc = %h ", next_pc ,in_pc);
    end
    else pc <= next_pc;
end

endmodule