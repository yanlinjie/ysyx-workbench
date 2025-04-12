module delay_pipeline #(
    parameter WIDTH = 32,   // 信号位宽
    parameter STAGES = 3    // 打拍数量
)(
    input                  clk,
    input                  rst,
    input  [WIDTH-1:0]     din,
    output [WIDTH-1:0]     dout
);

    reg [WIDTH-1:0] pipeline [0:STAGES-1];  // 多级寄存器阵列

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < STAGES; i = i + 1)
                pipeline[i] <= {WIDTH{1'b0}};
        end else begin
            pipeline[0] <= din;
            for (i = 1; i < STAGES; i = i + 1)
                pipeline[i] <= pipeline[i-1];
        end
    end

    assign dout = pipeline[STAGES-1];

endmodule
