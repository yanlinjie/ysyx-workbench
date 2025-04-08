//三选一 数据选择器 00:a 01:b 10:c
module mux3_1(
    input start,
    input [1:0] signal,
    input [31:0] a, b, c,
    output reg [31:0] out
);

always @(*) begin
    // if(start) begin
        case (signal)
            2'b00: out = a;
            2'b01: out = b;
            2'b10: out = c;
            default: out = 32'b0; // 可选的默认情况，避免综合警告
        endcase
    // end

end

endmodule
