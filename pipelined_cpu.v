`timescale 1ns / 1ps


module pipelined_cpu (
	input clk,
	input reset
);
	
	wire [31:0] pc_current, pc_next, instr_if;
	wire [31:0] pc_id, instr_id;
	wire [4:0] rs_id, rt_id, rd_id;
	wire [31:0] reg_data1_id, reg_data2_id;
	wire [31:0] sign_ext_id;
	
	wire [31:0] reg_data1_ex, reg_data2_ex, sign_ext_ex;
	wire [4:0] rs_ex, rt_ex, rd_ex;
	wire [2:0] alu_ctrl_ex;
	wire [31:0] alu_result_ex, alu_in2_ex;
	wire zero_ex;
	
	wire [31:0] write_data_mem, alu_result_mem, pc_branch_mem;
	wire zero_mem;
	wire [4:0] write_reg_mem;
	
	wire [31:0] read_data_mem;
	wire [31:0] write_data_wb;
	wire [4:0] write_reg_wb;
	wire [31:0] pc_ex;
	wire [31:0] mem_data_wb, alu_result_wb;
	
	//Control Signals
	wire reg_dst, alu_src, mem_to_reg, reg_write;
	wire mem_read, mem_write, branch;
	wire [1:0] alu_op;
	
	wire reg_dst_ex, alu_src_ex, mem_to_reg_ex, reg_write_ex;
	wire mem_read_ex, mem_write_ex, branch_ex;
	wire [1:0] alu_op_ex;
	
	wire mem_to_reg_mem, reg_write_mem, mem_read_mem, mem_write_mem, branch_mem;
	wire mem_to_reg_wb, reg_write_wb;
	
	//wire for handling write reg_mux
	wire [4:0] write_reg_ex;
	assign write_reg_ex = reg_dst_ex ? rd_ex : rt_ex;
	
	//branch target address
	wire [31:0] pc_branch_calc;
	assign pc_branch_calc = pc_ex + (sign_ext_ex << 2);
	
	//pc
	pc PC (.clk(clk), .reset(reset), .next_pc(pc_next), .pc(pc_current));
	
	//Instruction memory
	imem IMEM (.addr(pc_current), .instr(instr_if));
	
	//IF/ID pipeline reg
	if_id IF_ID (
		.clk(clk), .pc_in(pc_current), .instr_in(instr_if),
		.pc_out(pc_id), .instr_out(instr_id)
		);
		
		//control
		control CONTROL (
			.opcode(instr_id[31:26]),
			.reg_dst(reg_dst), .alu_src(alu_src), .mem_to_reg(mem_to_reg),
			.reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
			.branch(branch), .alu_op(alu_op)
			);
			
		//reg file
		regfile REGFILE (
			.clk(clk), .reg_write(reg_write_wb),
			.rs(instr_id[25:21]), .rt(instr_id[26:20]), .rd(write_reg_wb),
			.write_data(write_data_wb),
			.read_data1(reg_data1_id), .read_data2(reg_data2_id)
			);
				
		assign sign_ext_id = {{16{instr_id[15]}}, instr_id[15:0]};
		
	//ID/EX pipeline reg
	id_ex ID_EX (
		.clk(clk),
		.pc_in(pc_id), .read_data1_in(reg_data1_id), .read_data2_in(reg_data2_id), .sign_ext_in(sign_ext_id),
		.rs_in(instr_id[25:21]), .rt_in(instr_id[26:20]), .rd_in(instr_id[15:11]),
		.reg_dst_in(reg_dst), .alu_src_in(alu_src), .mem_to_reg_in(mem_to_reg), .reg_write_in(reg_write),
		.mem_read_in(mem_read), .mem_write_in(mem_write), .branch_in(branch),
		.alu_op_in(alu_op),
		
		.pc_out(pc_ex), .read_data1_out(reg_data1_ex), .read_data2_out(reg_data2_ex), .sign_ext_out(sign_ext_ex),
		.rs_out(rs_ex), .rt_out(rt_ex), .rd_out(rd_ex),
		.reg_dst_out(reg_dst_ex), .alu_src_out(alu_src_ex), .mem_to_reg_out(mem_to_reg_ex), .reg_write_out(reg_write_ex),
		.mem_read_out(mem_read_ex), .mem_write_out(mem_write_ex), .branch_out(branch_ex),
		.alu_op_out(alu_op_ex)
		
		);
		
		  // ALU Control
    alu_control ALUCTRL (
        .alu_op(alu_op_ex), .funct(sign_ext_ex[5:0]), .alu_ctrl(alu_ctrl_ex)
    );

    assign alu_in2_ex = alu_src_ex ? sign_ext_ex : reg_data2_ex;

    // ALU
    alu ALU (
        .a(reg_data1_ex), .b(alu_in2_ex), .alu_ctrl(alu_ctrl_ex), .result(alu_result_ex), .zero(zero_ex)
    );

    // EX/MEM Pipeline Register
    ex_mem EX_MEM (
        .clk(clk),
        .alu_result_in(alu_result_ex), .write_data_in(reg_data2_ex), .pc_branch_in(pc_branch_calc),
        .write_reg_in(write_reg_ex), .zero_in(zero_ex),
        .mem_read_in(mem_read_ex), .mem_write_in(mem_write_ex), .mem_to_reg_in(mem_to_reg_ex),
        .reg_write_in(reg_write_ex), .branch_in(branch_ex),

        .alu_result_out(alu_result_mem), .write_data_out(write_data_mem), .pc_branch_out(pc_branch_mem),
        .write_reg_out(write_reg_mem), .zero_out(zero_mem),
        .mem_read_out(mem_read_mem), .mem_write_out(mem_write_mem), .mem_to_reg_out(mem_to_reg_mem),
        .reg_write_out(reg_write_mem), .branch_out(branch_mem)
    );

    // Data Memory
    dmem DMEM (
        .clk(clk), .mem_read(mem_read_mem), .mem_write(mem_write_mem),
        .addr(alu_result_mem), .write_data(write_data_mem), .read_data(read_data_mem)
    );

    // MEM/WB Pipeline Register
    mem_wb MEM_WB (
        .clk(clk),
        .mem_data_in(read_data_mem), .alu_result_in(alu_result_mem), .write_reg_in(write_reg_mem),
        .mem_to_reg_in(mem_to_reg_mem), .reg_write_in(reg_write_mem),

        .mem_data_out(mem_data_wb), .alu_result_out(alu_result_wb), .write_reg_out(write_reg_wb),
        .mem_to_reg_out(mem_to_reg_wb), .reg_write_out(reg_write_wb)
    );

    assign write_data_wb = mem_to_reg_wb ? mem_data_wb : alu_result_wb;

    // PC logic
    assign pc_next = ((branch_mem === 1'bx) || (zero_mem === 1'bx)) ?
                  pc_current + 4 :
                 (branch_mem && zero_mem) ? pc_branch_mem : pc_current + 4;


endmodule