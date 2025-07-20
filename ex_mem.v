module ex_mem (
    input clk,
    
    input [31:0] alu_result_in,
    input [31:0] write_data_in,
    input [31:0] pc_branch_in,
    input [4:0] write_reg_in,
    input zero_in,
    
    input mem_read_in,
    input mem_write_in,
    input mem_to_reg_in,
    input reg_write_in,
    input branch_in,

    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg [31:0] pc_branch_out,
    output reg [4:0] write_reg_out,
    output reg zero_out,

    output reg mem_read_out,
    output reg mem_write_out,
    output reg mem_to_reg_out,
    output reg reg_write_out,
    output reg branch_out
);

	
	always @(posedge clk) begin
    alu_result_out   <= alu_result_in;
    write_data_out   <= write_data_in;
    pc_branch_out    <= pc_branch_in;
    write_reg_out    <= write_reg_in;
    zero_out         <= zero_in;

    mem_read_out     <= mem_read_in;
    mem_write_out    <= mem_write_in;
    mem_to_reg_out   <= mem_to_reg_in;
    reg_write_out    <= reg_write_in;
    branch_out       <= branch_in;
end
endmodule
		