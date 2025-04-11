module IDU (
    input                               clk                        ,
    input                               rst                        ,//高电平有效

    input              [  31:0]         pc                         ,//当前执行的pc
    input              [  31:0]         instruction                ,//当前执行的指令

    input                               pc_valid                   ,//握手信号
    input                               ex_ready                   ,//握手信号
    output reg                          id_ready                   ,//握手信号
    output reg                          id_valid                   ,//握手信号


    output reg                          write_reg                  ,//1bit reg write en
    output reg                          rd_aluout_mem              ,// 1bit: rd from alu or mem. 0:from alu, 1:from mem 
    output reg         [   1:0]         alua_rs1_pc_zero           ,//2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
    output reg         [   1:0]         alub_rs2_imm_4             ,//2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
    output reg         [   4:0]         alu_ctr                    ,//5bit control alu
    output reg         [  31:0]         imm_32                     ,//output  32bit imm
    
    output reg                          write_mem_en               ,//1bit write mem en  
    output reg         [   1:0]         write_mem                  ,//2bit write mem ctr
    output reg                          read_mem_en                ,//1bit read mem en
    output reg         [   2:0]         read_mem                   ,//3bit read mem ctr
    output reg                          next_pcimm_rs1imm          ,// 1bit 0:pc += imm ; pc=rs1+imm;
    output reg                          out_rddata_memaddr         ,//用来判断alu_out是 写入rd中，还是mem中
    output reg         [   1:0]         jump                       ,//jal :01  jalr: 10  default:00

    // to reg_flie
    output reg         [   4:0]         rs1_addr                   ,//rs1 地址
    output reg         [   4:0]         rs2_addr                   ,//rs2 地址
    output reg         [   4:0]         rd_addr                     //rd 地址

);

    // 状态定义
localparam IDLE        = 2'b0;//等待上游模块的 valid信号
localparam WAIT_READY = 2'b1;//等待下游模块 ready信号



reg [1:0] state, next_state;


reg [2:0] imm_ctr;           //3bit control imm;
reg [2:0] func3;
reg [6:0] func7;
    // 状态转移
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
            // next_state <= IDLE;
        else
            state <= next_state;
    end

    // 状态机逻辑
    always @(*) begin
        case (state)
            IDLE: begin
                id_ready = 1'b1;
                id_valid = 1'b0;
                if (pc_valid)
                    next_state = WAIT_READY;//执行模块ready后，跳转至wait_input状态
            else next_state = IDLE ;
            end
            WAIT_READY: begin
                id_valid = 1'b1;
                id_ready = 1'b0;
                if (ex_ready) next_state = IDLE;
                else next_state = WAIT_READY;
            end

            default: next_state = IDLE;
        endcase
    end

// reg  id_start;
// // 这里和 IDU 有点不一样, 可能三选一结构延迟比较小？
// always @(posedge clk) begin
//         id_start = (state == IDLE && pc_valid);
// end
//还是使用组合逻辑吧！这样可以对齐时钟周期
    always @(*) begin
        //  if (id_start) begin  //当处于IDLE状态时,并且指令有效时,则在下一周期的上升沿开始译码！
            // // opcode <= instruction[6:0];
            rs2_addr =instruction[24:20];
            rs1_addr =instruction[19:15];

            rd_addr= instruction[11:7];
            func3 =instruction[14:12];
            func7=instruction[31:25];

            case (instruction[6:0])
                // auipc
                7'b0010111:begin
                    write_reg = 1'b1;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b01;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b01;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b11;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    alu_ctr = 5'b00000;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b001;              //3bit control imm;
                    out_rddata_memaddr =1'b0;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b00;       //jal :01  jalr: 10  default:00
                end
                // lui   x[rd] = imm[31:12] <<12 低位补0;
                7'b0110111:begin
                    write_reg = 1'b1;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b10;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b01;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b11;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    alu_ctr = 5'b0;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b001;              //3bit control imm;
                    out_rddata_memaddr =1'b0;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b00;       //jal :01  jalr: 10  default:00
                end
                //jal jump  这条指令涉及rd 我会在最后 对next_pc进行jump  
                7'b1101111:begin
                    write_reg = 1'b1;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b01;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b10;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b11;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    alu_ctr = 5'b00000;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b100;              //3bit control imm;
                    out_rddata_memaddr =1'b0;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b01;       //jal :01  jalr: 10  default:00
                end
                // jalr
                7'b1100111:begin
                    write_reg = 1'b1;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b01;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b10;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b11;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    alu_ctr = 5'b01010;                //5bit control alu
                    next_pcimm_rs1imm = 1'b1;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b000;              //3bit control imm;
                    out_rddata_memaddr =1'b0;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b10;                   //jal :01  jalr: 10  default:00
                end
                // L型指令
                7'b0000011:begin
                    write_reg = 1'b1;              //1bit reg write en
                    rd_aluout_mem = 1'b1;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b00;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b01;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b0;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    // read_mem = 3'b0;               //3bit read mem ctr
                    read_mem_en = 1'b1;            //1bit read mem en
                    alu_ctr = 5'b00000;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b000;              //3bit control imm;
                    out_rddata_memaddr =1'b1;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b00;       //jal :01  jalr: 10  default:00
                    case (func3)
                        //lb
                        3'b000: read_mem = 3'b000;
                        //lh
                        3'b001: read_mem = 3'b001;
                        //lw
                        3'b010: read_mem = 3'b010;
                        //lbu
                        3'b100: read_mem = 3'b100;
                        //lhu
                        3'b101: read_mem = 3'b101;
                        default: begin
                        end
                    endcase
                end
                //I型指令(addi类型)
                7'b0010011:begin
                    write_reg = 1'b1;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b00;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b01;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b11;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    // alu_ctr <= 5'b0;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b000;              //3bit control imm;
                    out_rddata_memaddr =1'b0;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b00;       //jal :01  jalr: 10  default:00
                    case (func3)
                        //addi    
                        3'b000: alu_ctr = 5'b00000;
                        //slti
                        3'b010: alu_ctr = 5'b00110;
                        // sltiu
                        3'b011:begin
                            alu_ctr = 5'b00111;
                        end
                        // xori
                        3'b100:begin
                            alu_ctr = 5'b00100;
                        end
                        // ori
                        3'b110:begin
                            alu_ctr = 5'b00011;
                        end
                        // andi
                        3'b111:begin
                            alu_ctr = 5'b00010;
                        end
                        // slli
                        3'b001:begin
                            alu_ctr = 5'b00101;
                        end
                        // srli, srai
                        3'b101:begin
                            if(func7[5])begin//srai
                                imm_ctr = 3'b101;
                                alu_ctr = 5'b01001;
                            end
                            else alu_ctr = 5'b01000;//srli
                        end
                        default: begin
                        end
                    endcase
                end
                //B型指令
                7'b1100011:begin
                    write_reg = 1'b0;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b00;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b00;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b0;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    // alu_ctr = 5'b0;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b011;              //3bit control imm;
                    out_rddata_memaddr =1'b0;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b00;       //jal :01  jalr: 10  default:00
                    case (func3)
                        // beq
                        3'b000:begin
                            alu_ctr = 5'b01011;
                        end
                        // bne
                        3'b001:begin
                            alu_ctr = 5'b01100;
                        end
                        // blt
                        3'b100: begin
                            alu_ctr = 5'b01101;
                        end
                        // bge
                        3'b101:begin
                            alu_ctr = 5'b01110;
                        end
                        // bltu
                        3'b110:begin
                            alu_ctr = 5'b01111;
                        end
                        // bgeu
                        3'b111:begin
                            alu_ctr = 5'b10000;
                        end
                        default:begin
                            
                        end
                    endcase
                end
                // R型指令
                7'b0110011:begin
                    write_reg = 1'b1;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b00;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b00;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b11;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    // alu_ctr = 5'b01010;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b111;              //3bit control imm;
                    out_rddata_memaddr =1'b0;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b00;                   //jal :01  jalr: 10  default:00

                    case (func3)
                        // sub, add
                        3'b000:begin
                            if(func7[5])begin
                                alu_ctr = 5'b00001;
                            end else begin
                                alu_ctr = 5'b00000;
                            end
                        end
                        // or
                        3'b110:begin
                            alu_ctr = 5'b00011;
                        end
                        // and
                        3'b111:begin
                            alu_ctr = 5'b00010;
                        end
                        // xor
                        3'b100:begin
                            alu_ctr = 5'b00100;
                        end
                        // sll
                        3'b001:begin
                            alu_ctr = 5'b00101;
                        end
                        // slt
                        3'b010:begin
                            alu_ctr = 5'b00110;
                        end
                        // sltu
                        3'b011:begin
                            alu_ctr = 5'b00111;
                        end
                        // srl, sra
                        3'b101:begin
                            if(func7[5]) alu_ctr = 5'b01001;   //sra
                            else alu_ctr = 5'b01000;           //srl
                        end 
                        default: begin
                            
                        end
                    endcase
                end
                // S型指令
                7'b0100011:begin
                    write_reg = 1'b0;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b00;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b01;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    // write_mem = 2'b11;              //2bit write mem ctr  
                    write_mem_en = 1'b1;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    alu_ctr = 5'b00000;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b010;              //3bit control imm;
                    out_rddata_memaddr =1'b1;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b00;                   //jal :01  jalr: 10  default:00
                    case (func3)
                        // sw
                        3'b010:begin
                            write_mem = 2'b10;
                        end
                        // sh
                        3'b001:begin
                            write_mem = 2'b01;
                        end
                        // sb
                        3'b000:begin
                            write_mem = 2'b00;
                        end
                        default: begin
                        end
                    endcase
                end
                    // ebreak
                7'b1110011:begin
                    write_reg = 1'b0;              //1bit reg write en
                    rd_aluout_mem = 1'b0;          //1bit: rd from alu or mem. 0:from alu, 1:from mem 
                    alua_rs1_pc_zero = 2'b00;       //2bit: alu's a from rs1 , pc , 0. 00:rs1, 01:pc, 10: 0
                    alub_rs2_imm_4 = 2'b01;         //2bit: alu's b from rs2 ,imm , 4. 00:rs2, 01:imm, 10:4
                    write_mem = 2'b11;              //2bit write mem ctr  
                    write_mem_en = 1'b0;           //1bit write mem en
                    read_mem = 3'b011;               //3bit read mem ctr 默认值使用011,
                    read_mem_en = 1'b0;            //1bit read mem en
                    // alu_ctr = 5'b00000;                //5bit control alu
                    next_pcimm_rs1imm = 1'b0;      //1bit 0:pc += imm ; pc=rs1+imm;
                    imm_ctr = 3'b000;              //3bit control imm;
                    out_rddata_memaddr =1'b0;     //1bit alu out -> rd_data or memaddr  0:rd_data; 1:memaddr;
                    jump = 2'b00;       //jal :01  jalr: 10  default:00
                    // dpi_exit_simulation();
                    case (func3)
                        3'b000:  begin  //ecall and ebreak
                            alu_ctr = 5'b10010;
                            if (func7 ==7'b0011000 ) begin
                                alu_ctr = 5'b10101;//mret
                            end
                        end
                        3'b001:   begin//csrrw
                        // write_csr_reg = 1;
                            alu_ctr = 5'b10011;
                        end//csrrw
                        3'b010: begin //csrrs
                        // write_csr_reg = 1;
                            alu_ctr = 5'b10100;
                        end

                        default: begin
                            
                        end
                    endcase
                    
                    // nemu_trap(pc);
                    
                end
                default: begin
                end

            endcase
        // end
    end

always @(*) begin


        case (imm_ctr)
            3'b000:begin 
                imm_32 = {{20{instruction[31]}}, instruction[31:20]};//3
                // $display("imm = %h, instr = %h", imm_32, instr);
            end
            3'b001:begin
                imm_32 = {instruction[31:12], 12'b0};//1
            end
            3'b010:begin
                imm_32 = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            3'b011:begin
                imm_32 = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};//4
            end
            3'b100:begin
                imm_32 = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};//2
            end
            3'b101:begin
                imm_32[10] = 0;
                imm_32 = {{20{instruction[31]}}, instruction[31:20]};
            end
            3'b111:begin
                imm_32 = 32'b0;
            end 
            default:begin
                // imm_32 = 32'b0;
            end 
        endcase
        

end








endmodule
