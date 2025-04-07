// import "DPI-C" function void dpi_exit_simulation();
// module csr_file (
//     input clk,
//     input [4:0] aluc,
//     input [31:0] rs1_val,
//     input [31:0] csr_addr,
//     input [31:0] pc_current,

//     output reg [31:0] csr_rd_data,
//     output reg [31:0] out_pc,
//     output reg ecall_branch
// );
//     reg [31:0] csr_regs[0:3]; // mtvec=0, mstatus=1, mcause=2, mepc=3

//     always @(posedge clk) begin
//         ecall_branch <= 1'b0;

//         case (aluc)
//             5'b10010: begin  // csrrw
//                 case (csr_addr)
//                     32'h305: begin csr_rd_data <= csr_regs[0]; csr_regs[0] <= rs1_val; end
//                     32'h300: begin csr_rd_data <= csr_regs[1]; csr_regs[1] <= rs1_val; end
//                     32'h342: begin csr_rd_data <= csr_regs[2]; csr_regs[2] <= rs1_val; end
//                     32'h341: begin csr_rd_data <= csr_regs[3]; csr_regs[3] <= rs1_val; end
//                     default: csr_rd_data <= 32'b0;
//                 endcase
//             end

//             5'b10100: begin // csrrs
//                 case (csr_addr)
//                     32'h305: begin csr_rd_data <= csr_regs[0]; csr_regs[0] <= csr_regs[0] | rs1_val; end
//                     32'h300: begin csr_rd_data <= csr_regs[1]; csr_regs[1] <= csr_regs[1] | rs1_val; end
//                     32'h342: begin csr_rd_data <= csr_regs[2]; csr_regs[2] <= csr_regs[2] | rs1_val; end
//                     32'h341: begin csr_rd_data <= csr_regs[3]; csr_regs[3] <= csr_regs[3] | rs1_val; end
//                     default: csr_rd_data <= 32'b0;
//                 endcase
//             end

//             5'b10011: begin // ecall
//                 if (csr_addr == 0) begin
//                     csr_regs[2] <= -1; // mcause
//                     csr_regs[3] <= pc_current + 4; // mepc
//                     out_pc <= csr_regs[0]; // jump to mtvec
//                     ecall_branch <= 1'b1;
//                 end else begin
//                     dpi_exit_simulation(); // ebreak
//                 end
//             end

//             5'b10101: begin // mret
//                 ecall_branch <= 1'b1;
//                 out_pc <= csr_regs[3];
//             end
// default begin
    
// end
//         endcase
//     end
// endmodule
