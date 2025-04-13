module delay_pipeline (
    input                               clk                        ,
    input                               rst                        ,

    input              [  31:0]         araddr                     ,//  IFU(pc) or LSU
    input                               arvalid                    ,//  IFU or LSU
    output reg                          arready                    ,



    output                              din                        ,
    input                               dout                        
);

reg [10:0] cnt;
always @(posedge clk) begin
    if (rst) begin
        cnt <= 0;
    end else begin
        cnt = cnt + 1;

        if (cnt == 10) begin
            cnt <= 10;
            // arvalid_o <= 
        end
    end
    
end

endmodule
