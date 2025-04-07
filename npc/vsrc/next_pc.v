module next_pc(
    input clk,
    input rst,
    input [1: 0] pcImm_NEXTPC_rs1Imm,
    input condition_branch,
    input [31: 0] pc, offset, rs1Data,
    // input  ecall_branch,
    // input [31: 0] in_pc,
    output reg [31: 0] next_pc
);

always @(posedge clk) begin  //jal & 分支跳转应该能合并使用一个加法器
    if (rst) begin
        next_pc<=32'h80000000;
    end
    else if(pcImm_NEXTPC_rs1Imm == 2'b01) next_pc <= pc + offset;//jal pc = pc+imm
    else if(pcImm_NEXTPC_rs1Imm == 2'b10) next_pc <= rs1Data + offset; //jalr指令 pc = rs1+imm
    else if(condition_branch) next_pc <= pc + offset;//分支跳转 pc = pc + imm
    else next_pc <= pc + 4;
    

end

endmodule