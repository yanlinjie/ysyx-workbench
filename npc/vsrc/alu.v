import "DPI-C" function void dpi_exit_simulation();

module alu (
    input clk,
    input [31:0] pc_current,
    input [4:0] aluc,
    input [31:0] a, b,

    output reg [31:0] out,
    output reg condition_branch,

    output reg ecall_branch,
    output reg [31:0] out_pc,
    output [31:0] csr_rd_data
);

  // ========= CSR 寄存器 =========
  reg [31:0] mtvec, mstatus, mcause, mepc;

  // ========= 中间组合变量 =========
  reg [31:0] csr_rd_data_temp;
  reg ecall_pending;
  reg [31:0] next_pc;

  // ========= SRA Helper =========
  wire [31:0] SRA_mask = 32'hffff_ffff >> b[4:0];
  wire [31:0] sra_result = (a >> b[4:0]) & SRA_mask | ({32{a[31]}} & ~SRA_mask);

  // ========= 组合逻辑 =========
  always @(*) begin
    out = 32'b0;
    condition_branch = 1'b0;
    csr_rd_data_temp = 32'b0;
    ecall_pending = 1'b0;
    next_pc = 32'b0;

    case (aluc)
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

      5'b10001: out = b;

      // csrrw
      5'b10010: begin
        case (b)
          32'h305: csr_rd_data_temp = mtvec;
          32'h300: csr_rd_data_temp = mstatus;
          32'h342: csr_rd_data_temp = mcause;
          32'h341: csr_rd_data_temp = mepc;
        endcase
      end

      // csrrs
      5'b10100: begin
        case (b)
          32'h305: csr_rd_data_temp = mtvec;
          32'h300: csr_rd_data_temp = mstatus;
          32'h342: csr_rd_data_temp = mcause;
          32'h341: csr_rd_data_temp = mepc;
        endcase
      end

      // ecall
      5'b10011: begin
        if (b[0] == 1'b0) begin
          ecall_pending = 1'b1;
          next_pc = mtvec;
        //   $display("next_pc ");

          $display("mepc = %h  mcause = %h mtvec = %h ", mepc ,mcause,mtvec);
        end else dpi_exit_simulation(); // ebreak
      end

      // mret
      5'b10101: begin
        ecall_pending = 1'b1;
        next_pc = mepc;
        $display("1111  mepc = %h  mcause = %h mtvec = %h jump_pc = %h", mepc ,mcause,mtvec ,next_pc);

      end
            default:begin
        
      end
    endcase
  end

  assign csr_rd_data = csr_rd_data_temp;

  // ========= 时序逻辑 =========
  always @(posedge clk) begin
    case (aluc)
      5'b10010: begin // csrrw
        case (b)
          32'h305: mtvec <= a;
          32'h300: mstatus <= a;
          32'h342: mcause <= a;
          32'h341: mepc <= a;
        endcase
      end

      5'b10100: begin // csrrs
        case (b)
          32'h305: mtvec <= mtvec | a;
          32'h300: mstatus <= mstatus | a;
          32'h342: mcause <= mcause | a;
          32'h341: mepc <= mepc | a;
        endcase
      end

      5'b10011: begin // ecall
        if (b[0] == 1'b0) begin
          mcause <= 32'hffffffff;
          mepc <= pc_current + 4;
        end
      end
      default:begin
        
      end
    endcase

    // ecall 和 mret 的统一时序处理
    ecall_branch <= ecall_pending;
    out_pc <= next_pc;
  end

endmodule
