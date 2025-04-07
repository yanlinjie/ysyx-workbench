// import "DPI-C" function void dpi_exit_simulation();
module id(
    input [31: 0] instr,

    output [6: 0] opcode,
    output [2: 0] func3,
    output [6: 0] func7,
    output [4: 0] rd,
    output [4: 0] rs1,
    output [4: 0] rs2

// //add
// output write_en,
// output rd_data
);

assign  opcode  = instr[6:0];
assign  rs1 = instr[19:15];
assign  rs2 = instr[24:20];
assign  rd  = instr[11:7];
assign  func3  = instr[14:12];
assign  func7  = instr[31:25];

// reg [31:0] csr_regs [4:0];
// reg [31:0] t;//保存旧值
// wire [11:0] csr_imm;
// assign  csr_imm = instr[31:20];

// always @(*) begin
//     case (opcode)
//         7'b1110011:begin
//             // write_reg = 1;
//             // aluOut_WB_memOut = 1;
//             // rs1Data_EX_PC = 0;
//             // rs2Data_EX_imm32_4 = 2'b01;
//             // write_mem = 2'b00;
//             // read_mem = 3'b000;
//             // aluc = 5'b00000;
//             // pcImm_NEXTPC_rs1Imm = 2'b00;
//             // extOP = 3'b000;
//             case (func3)
//                 3'b000:  dpi_exit_simulation(); // ebreak// 调用DPI-C函数，结束仿真
//                 3'b001:  begin
//                     case (csr_imm)
//                         12'h305: begin
//                             t = csr_regs[0];
//                             csr_regs[0] = 32'b1; 
//                             // $display("t = 0x%x, rd_data = 0x%x", t, csr_regs[0]);
//                         end 
//                         default: begin

//                         end
//                     endcase
//                 end
//                 default: begin
                    
//                 end
//             endcase
//         end
//         default: begin
//             // dpi_exit_simulation();
//             // nemu_trap(pc);
//         end
// endcase
// end




endmodule