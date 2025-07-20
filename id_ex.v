module id_ex (
	input clk,
	input [31:0] pc_in,
	input [31:0] read_data1_in,
	input [31:0] read_data2_in,
	input [31:0] sign_ext_in,
	input [4:0] rs_in,
	input [4:0] rt_in,
	input [4:0] rd_in,
	input reg_dst_in,
	input alu_src_in,
	input mem_to_reg_in,
	input reg_write_in,
	input mem_read_in,
	input mem_write_in,
	input branch_in,
	input [1:0] alu_op_in,
	
	output reg [31:0] pc_out,
	output reg [31:0] read_data1_out,
	output reg [31:0] read_data2_out,
	output reg [31:0] sign_ext_out,
	output reg [4:0] rs_out,
	output reg [4:0] rt_out,
	output reg [4:0] rd_out,
	output reg reg_dst_out,
	output reg alu_src_out,
	output reg mem_to_reg_out,
	output reg reg_write_out,
	output reg mem_read_out,
	output reg mem_write_out,
	output reg branch_out,
	output reg [1:0] alu_op_out
	);
	
	always @(posedge clk) begin
		pc_out            <= pc_in;
		read_data1_out    <= read_data1_in;
		read_data2_out    <= read_data2_in;
		sign_ext_out      <= sign_ext_in;
		rs_out            <= rs_in;
		rt_out            <= rt_in;
		rd_out            <= rd_in;
		reg_dst_out       <= reg_dst_in;
		alu_src_out       <= alu_src_in;
		mem_to_reg_out    <= mem_to_reg_in;
		reg_write_out     <= reg_write_in;
		mem_read_out      <= mem_read_in;
		mem_write_out     <= mem_write_in;
		branch_out        <= branch_in;
		alu_op_out        <= alu_op_in;
	end
endmodule