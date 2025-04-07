// 声明 DPI-C 函数
// import "DPI-C" function void dpi_exit_simulation();


module controller(
    input [31:0] pc,
    input              [   6:0]         opcode                     ,
    input              [   2:0]         func3                      ,
    input              [   6:0]         func7                      ,
output reg write_csr_reg,
    output reg         [   4:0]         aluc                       ,//选择ALU执行的操作
    output reg                          aluOut_WB_memOut, rs1Data_EX_PC, //
    //aluOut_WB_memOut ：宽度为1bit，选择寄存器rd写回数据来源，为0时选择ALU输出，为1时选择数据存储器输出。
    //rs1Data_EX_PC ：宽度为1bit，选择ALU输入端A的来源。为0时选择rs1，为1时选择PC
    output reg         [   1:0]         rs2Data_EX_imm32_4         ,
    output reg                          write_reg                  ,//控制是否对寄存器rd进行写回，为1时写回寄存器
    output reg         [   1:0]         write_mem                  ,//宽度为1bit，选择寄存器rd写回数据来源，为0时选择ALU输出，为1时选择数据存储器输出。
    output reg         [   2:0]         read_mem                   ,
    //宽度为3bit，控制数据存储器读格式。最高位为1时带符号读，为0时无符号读。低二位为00时直接返回32'b0，为01时为4字节读（无需判断符号），为10时为2字节读，为11时为1字节读。
    output reg         [   2:0]         extOP                      ,//选择立即数产生器的输出类型 I U S B J  000 001 010 011 100
    output reg         [   1:0]         pcImm_NEXTPC_rs1Imm         //aluOut_WB_memOut ：宽度为1bit，选择寄存器rd写回数据来源，为0时选择ALU输出，为1时选择数据存储器输出。
);

always @(*) begin
    case (opcode)
        // lui
        7'b0110111:begin
            write_reg = 1;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem = 2'b00;
            read_mem = 3'b000;
            aluc = 5'b10001;
            pcImm_NEXTPC_rs1Imm = 2'b00;
            extOP = 3'b001;
        end
        // auipc
        7'b0010111:begin
            write_reg = 1;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 1;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem = 2'b00;
            read_mem = 3'b000;
            aluc = 5'b00000;
            pcImm_NEXTPC_rs1Imm = 2'b00;
            extOP = 3'b001;
        end
        // jal
        7'b1101111:begin
            write_reg = 1;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 1;
            rs2Data_EX_imm32_4 = 2'b11;
            write_mem = 2'b00;
            read_mem = 3'b000;
            aluc = 5'b00000;
            pcImm_NEXTPC_rs1Imm = 2'b01;
            extOP = 3'b100;
        end
        // jalr
        7'b1100111:begin
            write_reg = 1;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 1;
            rs2Data_EX_imm32_4 = 2'b11;
            write_mem = 2'b00;
            read_mem = 3'b000;
            aluc = 5'b01010;
            pcImm_NEXTPC_rs1Imm = 2'b10;
            extOP = 3'b000;
        end
        // B型指令
        7'b1100011:begin
            write_reg = 0;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b00;
            write_mem = 2'b00;
            read_mem = 3'b000;
            pcImm_NEXTPC_rs1Imm = 2'b00;
            extOP = 3'b011;
            case (func3)
                // beq
                3'b000:begin
                    aluc = 5'b01011;
                end
                // bne
                3'b001:begin
                    aluc = 5'b01100;
                end
                // blt
                3'b100: begin
                    aluc = 5'b01101;
                end
                // bge
                3'b101:begin
                    aluc = 5'b01110;
                end
                // bltu
                3'b110:begin
                    aluc = 5'b01111;
                end
                // bgeu
                3'b111:begin
                    aluc = 5'b10000;
                end
                default:begin
                    
                end
            endcase
        end
        // L型指令
        7'b0000011:begin
            write_reg = 1;
            write_csr_reg = 0;
            aluOut_WB_memOut = 1;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem = 2'b00;
            read_mem = 3'b000;
            aluc = 5'b00000;
            pcImm_NEXTPC_rs1Imm = 2'b00;
            extOP = 3'b000;
            case (func3)
                // lw
                3'b010:begin
                    read_mem = 3'b001;
                end
                // lh
                3'b001:begin
                    read_mem = 3'b110;
                end
                // lb
                3'b000:begin
                    read_mem = 3'b111;
                end
                // lbu
                3'b100:begin
                    read_mem = 3'b011;
                end
                // lhu
                3'b101:begin
                    read_mem = 3'b010;
                end
                default: begin
                    
                end
            endcase
        end
        // S型指令
        7'b0100011:begin
            write_reg = 0;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem = 2'b00;
            read_mem = 3'b000;
            aluc = 5'b00000;
            pcImm_NEXTPC_rs1Imm = 2'b00;
            extOP = 3'b010;
            case (func3)
                // sw
                3'b010:begin
                    write_mem = 2'b01;
                end
                // sh
                3'b001:begin
                    write_mem = 2'b10;
                end
                // sb
                3'b000:begin
                    write_mem = 2'b11;
                end
                default: begin
                    
                end
            endcase
        end
        // I型指令
        7'b0010011:begin
            write_reg = 1;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem = 2'b00;
            read_mem = 3'b000;
            pcImm_NEXTPC_rs1Imm = 2'b00;

            extOP = 3'b000;
            case (func3)
                // addi
                3'b000:begin
                    aluc = 5'b00000;
                end
                // slti
                3'b010:begin
                    aluc = 5'b00110;
                end
                // sltiu
                3'b011:begin
                    aluc = 5'b00111;
                end
                // xori
                3'b100:begin
                    aluc = 5'b00100;
                end
                // ori
                3'b110:begin
                    aluc = 5'b00011;
                end
                // andi
                3'b111:begin
                    aluc = 5'b00010;
                end
                // slli
                3'b001:begin
                    aluc = 5'b00101;
                end
                // srli, srai
                3'b101:begin
                    if(func7[5])begin//srai
                        extOP = 3'b101;
                        aluc = 5'b01001;
                    end
                    else aluc = 5'b01000;//srli
                end
                default:begin
                    
                end
            endcase
        end
        // R型指令
        7'b0110011:begin
            write_reg = 1;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b00;
            write_mem = 2'b00;
            read_mem = 3'b000;
            pcImm_NEXTPC_rs1Imm = 2'b00;
            extOP = 3'b111;
            case (func3)
                // sub, add
                3'b000:begin
                    if(func7[5])begin
                        aluc = 5'b00001;
                    end else begin
                        aluc = 5'b00000;
                    end
                end
                // or
                3'b110:begin
                    aluc = 5'b00011;
                end
                // and
                3'b111:begin
                    aluc = 5'b00010;
                end
                // xor
                3'b100:begin
                    aluc = 5'b00100;
                end
                // sll
                3'b001:begin
                    aluc = 5'b00101;
                end
                // slt
                3'b010:begin
                    aluc = 5'b00110;
                end
                // sltu
                3'b011:begin
                    aluc = 5'b00111;
                end
                // srl, sra
                3'b101:begin
                    if(func7[5]) aluc = 5'b01001;   //sra
                    else aluc = 5'b01000;           //srl
                end 
                default: begin
                    
                end
            endcase
        end
        // ebreak
        7'b1110011:begin
            write_reg = 0;
            write_csr_reg = 0;
            aluOut_WB_memOut = 0;
            rs1Data_EX_PC = 0;
            rs2Data_EX_imm32_4 = 2'b01;
            write_mem = 2'b00;
            read_mem = 3'b000;
            
            pcImm_NEXTPC_rs1Imm = 2'b00;
            extOP = 3'b000;
            case (func3)
                3'b000:  begin  //ecall and ebreak
                    aluc = 5'b10011;
                    if (func7 ==7'b0011000 ) begin
                        aluc = 5'b10101;
                    end
                end//dpi_exit_simulation(); // ebreak// 调用DPI-C函数，结束仿真
                3'b001:   begin//csrrw
                write_csr_reg = 1;
                    aluc = 5'b10010;
                end//csrrw
                3'b010: begin //csrrs
                write_csr_reg = 1;
                    aluc = 5'b10100;
                end

                default: begin
                    
                end
            endcase
            
            // nemu_trap(pc);
            
        end

        default: begin
            // dpi_exit_simulation();
            // nemu_trap(pc);
        end
    endcase
end

endmodule