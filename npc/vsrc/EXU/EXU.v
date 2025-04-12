// import "DPI-C" function void dpi_exit_simulation();

module EXU(
    input                               clk                        ,
    input                               rst                        ,
    // input [31:0]pc,
    //to mem & reg
    input              [   1:0]         jump                       ,
    output reg         [   1:0]         ex_jump                    ,
    input                               write_mem_en               ,
    input                               read_mem_en                ,
    input              [   1:0]         write_mem                  ,
    input              [   2:0]         read_mem                   ,
    input                               write_reg                  ,
    input              [   4:0]         rd_addr                    ,

    input                               rd_aluout_mem              ,//from idu
    input                               out_rddata_memaddr         ,//用来判断alu_out是 写入rd中，还是mem中

    output reg                          ex_write_mem_en            ,
    output reg                          ex_read_mem_en             ,
    output reg         [   1:0]         ex_write_mem               ,
    output reg         [   2:0]         ex_read_mem                ,
    output reg                          ex_write_reg               ,
    output reg         [   4:0]         ex_rd_addr                 ,
    output reg                          ex_rd_aluout_mem           ,

    output reg         [  31:0]         jump_pc                    ,
    input              [  31:0]         instruction                ,
    input                               id_valid                   ,
    input                               ls_ready                   ,
    //alu
    input              [   4:0]         alu_ctr                    ,
    output reg         [  31:0]         out_rd                     ,// 计算结果输出给rd 
    output reg         [  31:0]         out_mem_addr               ,//计算结果输出给mem_addr 作为地址
    output reg                          jump_flag                  ,//used to jump
    // output reg [31:0] ex_imm,
    // mux_a 
    input              [   1:0]         muxa_ctr                   ,
    input              [  31:0]         rs1_data                   ,
    input              [  31:0]         pc                         ,
    // mux_b
    input              [   1:0]         muxb_ctr                   ,
    input              [  31:0]         rs2_data                   ,
    input              [  31:0]         imm                        ,


    output reg         [  31:0]         ex_rs2_data                ,
    output reg         [  31:0]         jump_next_pc               ,

    output reg                          ex_valid                   ,
    output reg                          ex_ready                   ,

    //ecall mret
    // output reg ecall_pending,
    //csrrw csrrs写回寄存器 传送到wbu模块进行写回，
    output reg                          write_csr_en               ,
    output reg         [  31:0]         csr_rd_data                ,
    output reg         [   4:0]         csr_rd_addr                 

    
);

// 状态定义
localparam                              IDLE        = 3'd0         ;//等待上游模块的 valid信号
localparam                              WAIT_READY = 3'd1          ;//等待下游模块 ready信号
localparam                              PC_JUMP = 3'd2          ;//等待下游模块 ready信号


// ========= CSR 寄存器 =========
reg                    [  31:0]         mtvec, mstatus, mcause, mepc;

reg                    [   2:0]         state, next_state          ;


wire                   [  31:0]         a                          ;
wire                   [  31:0]         b                          ;
reg                    [  31:0]         out                        ;
reg                    [  31:0]         current_pc                 ;
  // ========= SRA Helper =========
  wire [31:0] SRA_mask = 32'hffff_ffff >> b[4:0];
  wire [31:0] sra_result = (a >> b[4:0]) & SRA_mask | ({32{a[31]}} & ~SRA_mask);

    // 状态转移
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else begin
        state <= next_state;
        current_pc<=pc;
    end

end

reg condition_branch;

// 状态机逻辑
//jump_pc 可以直接在exu中计算，不管是B型指令，还是jal 还是jalr！
//对于B型指令，则直接传送给IFU
//对于jal 和jalr可以继续执行后续模块，最后赋值给next_pc ！
always @(*) begin
    case (state)
        IDLE: begin
            jump_flag = 1'b0;
            ex_ready = 1'b1;
            ex_valid = 1'b0;
            write_csr_en = 1'b0;
            // ecall_pending = 1'b0;

            if (id_valid)
                next_state = WAIT_READY;
            else
                next_state = IDLE;
        end

        WAIT_READY: begin
            ex_ready = 1'b0;
            write_csr_en = 1'b0;
            ex_valid = 1'b0;
            // ecall_pending = 1'b0;
            jump_flag = 1'b0;
            // next_state = WAIT_READY;
            if (ls_ready) begin
                next_state = IDLE;
            end else next_state = WAIT_READY;
            
            condition_branch = 1'b0;
                case (alu_ctr)
                5'b00000: out = a + b;
                5'b00001: out = a - b;
                5'b00010: out = a & b;
                5'b00011: out = a | b;
                5'b00100: out = a ^ b;
                5'b00101: out = a << b[4:0];
                5'b00110: out = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
                5'b00111: out = (a < b) ? 32'b1 : 32'b0;
                5'b01000: out = a >> b[4:0];
                5'b01001: out = sra_result;
                5'b01010: begin out = a + b; out[0] = 1'b0; end

                // branch condition
                5'b01011: condition_branch = (a == b);
                5'b01100: condition_branch = (a != b);
                5'b01101: condition_branch = ($signed(a) < $signed(b));
                5'b01110: condition_branch = ($signed(a) >= $signed(b));
                5'b01111: condition_branch = (a < b);
                5'b10000: condition_branch = (a >= b);
                // 5'b10101:begin
                //             jump_flag = 1'b1;
                //             jump_pc = mepc;
                //             ex_valid = 1'b0;
                //             // next_state = PC_JUMP;
                //             next_state = IDLE;
                // end
                default:begin
                end
                endcase
            if (alu_ctr == 5'b10011 || alu_ctr == 5'b10100) begin  // CSR 指令
                write_csr_en = 1'b1;
                csr_rd_data = (imm == 32'h305) ? mtvec :
                              (imm == 32'h300) ? mstatus :
                              (imm == 32'h342) ? mcause :
                              (imm == 32'h341) ? mepc : 32'b0;
                csr_rd_addr = rd_addr;

                case (alu_ctr)
                    5'b10011: begin  // csrrw
                        case (imm)
                            32'h305: mtvec   = rs1_data;
                            32'h300: mstatus = rs1_data;
                            32'h342: mcause  = rs1_data;
                            32'h341: mepc    = rs1_data;
                        endcase
                    end
                    5'b10100: begin  // csrrs
                        case (imm)
                            32'h305: mtvec   = mtvec   | rs1_data;
                            32'h300: mstatus = mstatus | rs1_data;
                            32'h342: mcause  = mcause  | rs1_data;
                            32'h341: mepc    = mepc    | rs1_data;
                        endcase
                    end
                    default:begin end
                endcase

                ex_valid = 1'b1;
                next_state = IDLE;
            end
            else if (alu_ctr == 5'b10010) begin  // ecall/ebreak
                if (imm[0] == 1'b0) begin  // ecall
                    jump_flag = 1'b1;
                    jump_pc = mtvec;
                    mcause = 32'hffffffff;
                    mepc = current_pc + 4;
                    ex_valid = 1'b0;
                    // next_state = PC_JUMP;
                    next_state = IDLE;
                end 
                else begin  // ebreak
                    // dpi_exit_simulation();
                end
            end
            else if (alu_ctr == 5'b10101) begin  // mret
                jump_flag = 1'b1;
                jump_pc = mepc;
                ex_valid = 1'b0;
                // next_state = PC_JUMP;
                next_state = IDLE;
            end
            else if (condition_branch) begin  // B型指令
                jump_flag = 1'b1;
                jump_pc = current_pc + imm;
                ex_valid = 1'b0;
                // next_state = PC_JUMP;
                next_state = IDLE;

            end
            else if (jump[0]) begin  // jal
                jump_next_pc = current_pc + imm;
                ex_valid = 1'b1;
                next_state = IDLE;
            end
            else if (jump[1]) begin  // jalr
                jump_next_pc = rs1_data + imm;
                ex_valid = 1'b1;
                next_state = IDLE;
            end
            else begin
                ex_valid = 1'b1;
                next_state = IDLE;
            end
        end

        PC_JUMP:begin
            jump_flag = 1'b1;
            next_state = IDLE;
        end
        default: begin
            next_state = IDLE;
        end
    endcase
end


reg  ex_start;

always @(posedge clk) begin
        ex_start = (state == IDLE && id_valid);
end

always @(*) begin 
        if (out_rddata_memaddr) out_mem_addr = out;
        else out_rd = out ;
        ex_write_mem_en = write_mem_en;
        ex_read_mem_en = read_mem_en;
        ex_write_mem = write_mem;
        ex_read_mem = read_mem;
        ex_write_reg = write_reg;
        ex_rd_addr = rd_addr;
        ex_rd_aluout_mem = rd_aluout_mem;
        ex_jump = jump;
        ex_rs2_data = rs2_data;
end

mux3_1 mux3_1_inst_a(
    .start                             (ex_start                  ),
    .signal                            (muxa_ctr                  ),
    .a                                 (rs1_data                  ),
    .b                                 (pc                        ),
    .c                                 (32'b0                     ),

    .out                               (a                     ) 
);

mux3_1 mux3_1_inst_b(
    .start                             (ex_start                  ),
    .signal                            (muxb_ctr                  ),
    .a                                 (rs2_data                  ),
    .b                                 (imm                       ),
    .c                                 (32'h4                     ),

    .out                               (b                     ) 
);




//   // ========= 组合逻辑 =========
//   always @(*) begin
//     // condition_branch = 1'b0;
//     // out = 32'b0;
//     // case (alu_ctr)
//     //   5'b00000: out = a + b;
//     //   5'b00001: out = a - b;
//     //   5'b00010: out = a & b;
//     //   5'b00011: out = a | b;
//     //   5'b00100: out = a ^ b;
//     //   5'b00101: out = a << b[4:0];
//     //   5'b00110: out = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
//     //   5'b00111: out = (a < b) ? 32'b1 : 32'b0;
//     //   5'b01000: out = a >> b[4:0];
//     //   5'b01001: out = sra_result;
//     //   5'b01010: begin out = a + b; out[0] = 1'b0; end

//     //   // branch condition
//     //   5'b01011: condition_branch = (a == b);
//     //   5'b01100: condition_branch = (a != b);
//     //   5'b01101: condition_branch = ($signed(a) < $signed(b));
//     //   5'b01110: condition_branch = ($signed(a) >= $signed(b));
//     //   5'b01111: condition_branch = (a < b);
//     //   5'b10000: condition_branch = (a >= b);
//     //         default:begin
//     //   end
//     // endcase

// end

endmodule