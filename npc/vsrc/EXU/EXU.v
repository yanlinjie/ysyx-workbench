import "DPI-C" function void dpi_exit_simulation();

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
    output reg                          ex_ready                    ,

    //ecall mret
    output reg ecall_pending,
    //csrrw csrrs写回寄存器 传送到wbu模块进行写回，
    output reg write_csr_en ,
    output reg [31:0] csr_rd_data ,
    output reg [4:0] csr_rd_addr

    
);

// 状态定义
localparam                              IDLE        = 2'b0         ;//等待上游模块的 valid信号
localparam                              WAIT_READY = 2'b1          ;//等待下游模块 ready信号

// ========= CSR 寄存器 =========
reg                    [  31:0]         mtvec, mstatus, mcause, mepc;

reg                    [   1:0]         state, next_state          ;


wire                   [  31:0]         alu_a                      ;
wire                   [  31:0]         alu_b                      ;
wire                   [  31:0]         out                        ;
reg                    [  31:0]         current_pc                 ;

    // 状态转移
always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else begin
        state <= next_state;
        current_pc<=pc;
    end

end

wire condition_branch;

// 状态机逻辑
//jump_pc 可以直接在exu中计算，不管是B型指令，还是jal 还是jalr！
//对于B型指令，则直接传送给IFU
//对于jal 和jalr可以继续执行后续模块，最后赋值给next_pc ！
always @(*) begin
    case (state)
        IDLE: begin
            jump_flag=1'b0;
            ex_ready = 1'b1;
            ex_valid = 1'b0;
            write_csr_en = 1'b0;
            ecall_pending = 1'b0;
            if (id_valid)   begin
                next_state = WAIT_READY;//执行模块ready后，跳转至wait_input状态
                case (alu_ctr) //在这里写存储部分吧 目前主要csrrs csrrw : x[rd] = csrs[csr],ecall,mret, ebreak 放到下一时钟周期
                     //保存旧值，下一时钟周期再载入新值
                     5'b10011:begin //csrrw
                        case (imm)
                            32'h305:begin
                                write_csr_en = 1'b1;
                                csr_rd_data = mtvec;
                                csr_rd_addr = rd_addr;
                            end 
                            32'h300:begin
                                write_csr_en = 1'b1;
                                csr_rd_data = mstatus;
                                csr_rd_addr = rd_addr;
                            end 
                            32'h342:begin
                                write_csr_en = 1'b1;
                                csr_rd_data = mcause;
                                csr_rd_addr = rd_addr;
                            end 
                            32'h341:begin
                                write_csr_en = 1'b1;
                                csr_rd_data = mepc;
                                csr_rd_addr = rd_addr;
                            end     
                        endcase
                        // $display("6666 imm = %h  csr_rd_data = %h  mtvec = %h pc = %h ", imm ,csr_rd_data , mtvec ,pc);

                     end
                     5'b10100:begin //csrrs
                        case (imm)
                            32'h305:begin
                                write_csr_en = 1'b1;
                                csr_rd_data = mtvec;
                                csr_rd_addr = rd_addr;
                            end 
                            32'h300:begin
                                write_csr_en = 1'b1;
                                csr_rd_data = mstatus;
                                csr_rd_addr = rd_addr;
                            end 
                            32'h342:begin
                                write_csr_en = 1'b1;
                                csr_rd_data = mcause;
                                csr_rd_addr = rd_addr;
                            end 
                            32'h341:begin
                                write_csr_en = 1'b1;
                                csr_rd_data = mepc;
                                csr_rd_addr = rd_addr;
                            end     
                        endcase
                        // $display("5555 imm = %h  csr_rd_data = %h  mtvec = %h mstatus = %h mcause = %h mepc = %h pc = %h ", imm ,csr_rd_data , mtvec , mstatus, mcause, mepc ,pc);

                     end
                    default: begin
                    end
                endcase
            end

            else next_state = IDLE ;
        end
        WAIT_READY: begin
            ex_ready = 1'b0;
            write_csr_en = 1'b0;
            if (ls_ready) next_state = IDLE;                    
            else next_state = WAIT_READY;
            if (alu_ctr == 5'b10011 || alu_ctr == 5'b10100 || alu_ctr == 5'b10010 || alu_ctr == 5'b10101) begin
                case (alu_ctr) //在这里写存储部分吧 目前主要csrrs csrrw : x[rd] = csrs[csr],ecall,mret, ebreak 放到下一时钟周期
                    
                    5'b10011:begin //csrrw
                                case (imm)
                                    32'h305:mtvec = rs1_data;
                                    32'h300:mstatus = rs1_data;
                                    32'h342:mcause = rs1_data;
                                    32'h341:mepc = rs1_data;  
                                    // 32'h305:mtvec = rs1_data | mtvec;
                                    // 32'h300:mstatus = rs1_data | mstatus;
                                    // 32'h342:mcause = rs1_data | mcause;
                                    // 32'h341:mepc = rs1_data | mepc;       
                                endcase
                                ex_valid = 1'b1;
                                next_state = IDLE;
                            end
                    5'b10100:begin //csrrs
                                case (imm)
                                    32'h305:mtvec = rs1_data | mtvec;
                                    32'h300:mstatus = rs1_data | mstatus;
                                    32'h342:mcause = rs1_data | mcause;
                                    32'h341:mepc = rs1_data | mepc;   
                                endcase
                                ex_valid = 1'b1;
                                next_state = IDLE;
                            end
                    5'b10010: begin
                                if (imm[0] == 1'b0) begin//ecall
                                    jump_flag = 1'b1;
                                    ex_valid = 1'b0;
                                    jump_pc = mtvec;
                                    mcause = 32'hffffffff;//这个由软件设置,目前设置的是-1
                                    mepc = current_pc + 4;// 相当于当前pc + 4 记录自陷的时候当前pc ，+4是为了防止一直陷入
                                    next_state = IDLE;
                                //   $display("pc = %h ", pc);
                                // $display("ecall mepc = %h  mcause = %h mtvec = %h jump_pc = %h current_pc = %h", mepc ,mcause,mtvec, jump_pc ,current_pc);
                                end else dpi_exit_simulation(); // ebreak
                            end 
                    5'b10101:begin //mret
                            jump_flag = 1'b1;
                            ex_valid = 1'b0;
                            jump_pc = mepc ;
                            next_state = IDLE;
                            //  $display("mret  mepc = %h  mcause = %h mtvec = %h jump_pc = %h", mepc ,mcause,mtvec ,jump_pc);
                    end
                    default: begin
                    end
                endcase
            end
            else if(condition_branch)begin//B type 指令
                jump_flag = 1'b1;
                jump_pc = current_pc + imm;
                next_state = IDLE;
                ex_valid = 1'b0;
            end else if(jump[0]) begin//jal
                jump_next_pc = current_pc + imm;
                next_state = IDLE;
                ex_valid = 1'b1;
            end else if(jump[1]) begin//jal
                jump_next_pc = rs1_data + imm;
                next_state = IDLE;
                ex_valid = 1'b1;
            end 
                else ex_valid = 1'b1;

        end

        default: next_state = IDLE;
    endcase
end

reg  ex_start;

always @(posedge clk) begin
        ex_start = (state == IDLE && id_valid);
end

always @(*) begin 
    // if(ex_start) begin
        if (out_rddata_memaddr) out_mem_addr = out;
        else out_rd = out ;
        //输出给下一个模块 
        ex_write_mem_en = write_mem_en;
        ex_read_mem_en = read_mem_en;
        ex_write_mem = write_mem;
        ex_read_mem = read_mem;
        ex_write_reg = write_reg;
        ex_rd_addr = rd_addr;
        ex_rd_aluout_mem = rd_aluout_mem;
        // ex_imm = imm;
        ex_jump = jump;
        ex_rs2_data = rs2_data;
    // end  
    // else out_mem_addr = 1'b0;
end

mux3_1 mux3_1_inst_a(
    .start                             (ex_start                  ),
    .signal                            (muxa_ctr                  ),
    .a                                 (rs1_data                  ),
    .b                                 (pc                        ),
    .c                                 (32'b0                     ),

    .out                               (alu_a                     ) 
);

mux3_1 mux3_1_inst_b(
    .start                             (ex_start                  ),
    .signal                            (muxb_ctr                  ),
    .a                                 (rs2_data                  ),
    .b                                 (imm                       ),
    .c                                 (32'h4                     ),

    .out                               (alu_b                     ) 
);



alu u_alu(
    .start                             (ex_start                  ),
    .aluc                              (alu_ctr                   ),
    .a                                 (alu_a                     ),
    .b                                 (alu_b                     ),
    .out                               (out                       ),
    .condition_branch                  (condition_branch          ) 
);



endmodule