
module alu (
    input start,
    input [4:0] aluc,
    input [31:0] a, b,

    output reg [31:0] out,
    output reg condition_branch

 
);



  // ========= SRA Helper =========
  wire [31:0] SRA_mask = 32'hffff_ffff >> b[4:0];
  wire [31:0] sra_result = (a >> b[4:0]) & SRA_mask | ({32{a[31]}} & ~SRA_mask);

  // ========= 组合逻辑 =========
  always @(*) begin
    if(start) begin
    out = 32'b0;
    condition_branch = 1'b0;
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
            default:begin
      end
    endcase
    end else condition_branch = 1'b0;//维持一个时钟周期 , 不然会对后续有影响。！！！
end


endmodule
