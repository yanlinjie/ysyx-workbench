module reg_file(
    input                               rst, clk, write_reg        ,
    input              [   4: 0]        rs1, rs2, target_reg       ,
    input              [  31: 0]        write_rd_data              ,
    input [4:0] reg_csr_rd_addr,
    input [31:0] csr_data,
input write_csr_en,
    output reg         [  31: 0]        read_rs1_data              ,
    output reg         [  31: 0]        read_rs2_data               
);

reg [31: 0] regs[31: 0];
integer i;
always @(posedge clk) begin
    if(rst == 1'b1) begin
    for(i=0;i<32;i=i+1)begin
        regs[i] <= 32'b0;
        end
    end	
    else if (write_reg && target_reg != 5'h0) 
    begin 
        regs[target_reg] <= write_rd_data;
        // regs[target_reg] <= csr_data;
    end
    else if(write_csr_en && reg_csr_rd_addr != 5'h0 ) begin
            regs[reg_csr_rd_addr] <= csr_data;
            // $display("csr_data = %h  target_reg = %h" ,csr_data ,target_reg);
    end
end

initial begin
    // regs[5'd2] = 32'd128;
    regs[5'd2] = 32'd0;
end


//read rs1, rs2
always @(*) begin
    if(rs1 == 5'h0)begin
        read_rs1_data = 32'h0000_0000;
    end else begin
        read_rs1_data = regs[rs1];
    end
end

always @(*) begin
    if(rs2 == 5'h0)begin
        read_rs2_data = 32'h0000_0000;
    end else begin
        read_rs2_data = regs[rs2];
    end
end

endmodule