// `timescale directive sets the time unit and precision for the simulation.
// 1ns is the time unit (e.g., #1 means 1ns).
// 1ps is the precision (e.g., delays can be specified with a precision of 1 picosecond).
`timescale 1ns / 1ps

// Module definition for the top-level pipelined CPU.
// It has two inputs: a clock signal (clk) and a reset signal (reset).
module pipelined_cpu (
	input clk,
	input reset
);
	
	//================================================================================
	// WIRE DECLARATIONS
	// These wires connect the different stages and modules of the pipeline.
	//================================================================================

	//------------------------------------------------
	// Instruction Fetch (IF) Stage Wires
	//------------------------------------------------
	wire [31:0] pc_current; // The current value of the Program Counter (PC).
	wire [31:0] pc_next;    // The value the PC will be updated to in the next clock cycle.
	wire [31:0] instr_if;   // The instruction fetched from instruction memory in the IF stage.

	//------------------------------------------------
	// Instruction Decode (ID) Stage Wires
	//------------------------------------------------
	wire [31:0] pc_id;         // The PC value passed from the IF stage to the ID stage.
	wire [31:0] instr_id;      // The instruction passed from the IF stage to the ID stage.
	wire [4:0]  rs_id;         // The 5-bit register specifier for the first source operand (rs).
	wire [4:0]  rt_id;         // The 5-bit register specifier for the second source operand (rt).
	wire [4:0]  rd_id;         // The 5-bit register specifier for the destination operand (rd).
	wire [31:0] reg_data1_id;  // The data read from the register file corresponding to rs.
	wire [31:0] reg_data2_id;  // The data read from the register file corresponding to rt.
	wire [31:0] sign_ext_id;   // The 32-bit sign-extended immediate value from the instruction.
	
	//------------------------------------------------
	// Execute (EX) Stage Wires
	//------------------------------------------------
	wire [31:0] reg_data1_ex;  // Data from register rs, passed from the ID stage.
	wire [31:0] reg_data2_ex;  // Data from register rt, passed from the ID stage.
	wire [31:0] sign_ext_ex;   // Sign-extended immediate, passed from the ID stage.
	wire [4:0]  rs_ex;         // Register specifier rs, passed from the ID stage.
	wire [4:0]  rt_ex;         // Register specifier rt, passed from the ID stage.
	wire [4:0]  rd_ex;         // Register specifier rd, passed from the ID stage.
	wire [2:0]  alu_ctrl_ex;   // The 3-bit control signal for the ALU operation.
	wire [31:0] alu_result_ex; // The result of the ALU computation.
	wire [31:0] alu_in2_ex;    // The second input to the ALU (either reg_data2_ex or sign_ext_ex).
	wire        zero_ex;       // A flag that is high if the ALU result is zero.
	wire [31:0] pc_ex;         // The PC value, passed from the ID stage.
	
	//------------------------------------------------
	// Memory Access (MEM) Stage Wires
	//------------------------------------------------
	wire [31:0] write_data_mem;  // Data to be written to memory (from reg_data2). Passed from EX stage.
	wire [31:0] alu_result_mem;  // ALU result, passed from the EX stage. Used as memory address.
	wire [31:0] pc_branch_mem;   // The calculated branch target address, passed from the EX stage.
	wire        zero_mem;        // The zero flag, passed from the EX stage.
	wire [4:0]  write_reg_mem;   // The destination register specifier, passed from the EX stage.
	
	//------------------------------------------------
	// Write Back (WB) Stage Wires
	//------------------------------------------------
	wire [31:0] read_data_mem;   // Data read from data memory in the MEM stage.
	wire [31:0] write_data_wb;   // The final data to be written back to the register file.
	wire [4:0]  write_reg_wb;    // The destination register specifier, passed from the MEM stage.
	wire [31:0] mem_data_wb;     // Data read from memory, passed from the MEM stage.
	wire [31:0] alu_result_wb;   // ALU result, passed from the MEM stage.
	
	//================================================================================
	// CONTROL SIGNAL WIRES
	//================================================================================

	// Control signals generated in the ID stage by the Control unit.
	wire reg_dst;     // Selects between rd and rt as the destination register.
	wire alu_src;     // Selects between a register and the sign-extended immediate as the ALU's second operand.
	wire mem_to_reg;  // Selects between memory data and ALU result to be written back to a register.
	wire reg_write;   // Enables writing to the register file.
	wire mem_read;    // Enables reading from data memory.
	wire mem_write;   // Enables writing to data memory.
	wire branch;      // Indicates a branch instruction.
	wire [1:0] alu_op;  // 2-bit signal for the ALU Control to determine the specific ALU operation.
	
	// Control signals pipelined to the EX stage.
	wire reg_dst_ex;
	wire alu_src_ex;
	wire mem_to_reg_ex;
	wire reg_write_ex;
	wire mem_read_ex;
	wire mem_write_ex;
	wire branch_ex;
	wire [1:0] alu_op_ex;
	
	// Control signals pipelined to the MEM stage.
	wire mem_to_reg_mem;
	wire reg_write_mem;
	wire mem_read_mem;
	wire mem_write_mem;
	wire branch_mem;
	
	// Control signals pipelined to the WB stage.
	wire mem_to_reg_wb;
	wire reg_write_wb;
	
	//================================================================================
	// COMBINATIONAL LOGIC & MODULE INSTANTIATIONS
	//================================================================================

	//----------------------------------------------------------------------
	// INSTRUCTION FETCH (IF) STAGE
	// Fetches the next instruction from memory using the Program Counter.
	//----------------------------------------------------------------------
	
	// Program Counter (PC) module.
	// On the rising edge of the clock, it updates its value from `pc_next`.
	pc PC (.clk(clk), .reset(reset), .next_pc(pc_next), .pc(pc_current));
	
	// Instruction Memory (imem) module.
	// Asynchronously reads the instruction at the address specified by `pc_current`.
	imem IMEM (.addr(pc_current), .instr(instr_if));
	
	//----------------------------------------------------------------------
	// IF/ID PIPELINE REGISTER
	// Stores the fetched instruction and PC value to be used in the next stage.
	//----------------------------------------------------------------------
	if_id IF_ID (
		.clk(clk), 
		.pc_in(pc_current), // Input: PC value from the IF stage.
		.instr_in(instr_if),  // Input: Instruction from the IF stage.
		.pc_out(pc_id),       // Output: PC value for the ID stage.
		.instr_out(instr_id)  // Output: Instruction for the ID stage.
	);
		
	//----------------------------------------------------------------------
	// INSTRUCTION DECODE (ID) STAGE
	// Decodes the instruction, generates control signals, and reads from the register file.
	//----------------------------------------------------------------------
		
	// Control unit.
	// Generates all the main control signals based on the instruction's opcode.
	control CONTROL (
		.opcode(instr_id[31:26]), // Input: Opcode field of the instruction.
		.reg_dst(reg_dst),       // Output: Determines destination register.
		.alu_src(alu_src),       // Output: Selects ALU's second operand.
		.mem_to_reg(mem_to_reg), // Output: Selects data for write-back.
		.reg_write(reg_write),   // Output: Enables register file write.
		.mem_read(mem_read),     // Output: Enables data memory read.
		.mem_write(mem_write),   // Output: Enables data memory write.
		.branch(branch),         // Output: Indicates a branch instruction.
		.alu_op(alu_op)          // Output: Control bits for ALU Control unit.
	);
			
	// Register File (regfile) module.
	// Reads from two registers (rs, rt) and can write to one register (rd).
	regfile REGFILE (
		.clk(clk), 
		.reg_write(reg_write_wb),       // Input: Write enable signal from WB stage.
		.rs(instr_id[25:21]),           // Input: Address of the first source register.
		.rt(instr_id[20:16]),           // Input: Address of the second source register.
		.rd(write_reg_wb),              // Input: Address of the destination register from WB stage.
		.write_data(write_data_wb),     // Input: Data to write, from WB stage.
		.read_data1(reg_data1_id),      // Output: Data read from rs.
		.read_data2(reg_data2_id)       // Output: Data read from rt.
	);
				
	// Sign Extension logic.
	// Takes the 16-bit immediate from the instruction and extends it to 32 bits.
	// It replicates the most significant bit (bit 15) to the upper 16 bits.
	assign sign_ext_id = {{16{instr_id[15]}}, instr_id[15:0]};
		
	//----------------------------------------------------------------------
	// ID/EX PIPELINE REGISTER
	// Passes decoded instruction information and control signals to the EX stage.
	//----------------------------------------------------------------------
	id_ex ID_EX (
		.clk(clk),
		// Inputs from the ID stage
		.pc_in(pc_id), 
		.read_data1_in(reg_data1_id), 
		.read_data2_in(reg_data2_id), 
		.sign_ext_in(sign_ext_id),
		.rs_in(instr_id[25:21]), 
		.rt_in(instr_id[20:16]), 
		.rd_in(instr_id[15:11]),
		.reg_dst_in(reg_dst), 
		.alu_src_in(alu_src), 
		.mem_to_reg_in(mem_to_reg), 
		.reg_write_in(reg_write),
		.mem_read_in(mem_read), 
		.mem_write_in(mem_write), 
		.branch_in(branch),
		.alu_op_in(alu_op),
		
		// Outputs to the EX stage
		.pc_out(pc_ex), 
		.read_data1_out(reg_data1_ex), 
		.read_data2_out(reg_data2_ex), 
		.sign_ext_out(sign_ext_ex),
		.rs_out(rs_ex), 
		.rt_out(rt_ex), 
		.rd_out(rd_ex),
		.reg_dst_out(reg_dst_ex), 
		.alu_src_out(alu_src_ex), 
		.mem_to_reg_out(mem_to_reg_ex), 
		.reg_write_out(reg_write_ex),
		.mem_read_out(mem_read_ex), 
		.mem_write_out(mem_write_ex), 
		.branch_out(branch_ex),
		.alu_op_out(alu_op_ex)
	);
		
	//----------------------------------------------------------------------
	// EXECUTE (EX) STAGE
	// Performs the ALU operation and calculates the branch target address.
	//----------------------------------------------------------------------
		
	// ALU Control unit.
	// Determines the specific 4-bit ALU operation code based on ALUOp and the function field.
	alu_control ALUCTRL (
		.alu_op(alu_op_ex),       // Input: 2-bit control from main Control unit.
		.funct(sign_ext_ex[5:0]), // Input: Function field from the immediate value (for R-type).
		.alu_ctrl(alu_ctrl_ex)    // Output: 3-bit code for the ALU operation.
	);

	// Mux to select the second ALU input.
	// If alu_src_ex is 1 (I-type), select the sign-extended immediate.
	// If alu_src_ex is 0 (R-type), select the data from the second register (rt).
	assign alu_in2_ex = alu_src_ex ? sign_ext_ex : reg_data2_ex;

	// Arithmetic Logic Unit (ALU).
	// Performs the operation specified by alu_ctrl_ex on its inputs.
	alu ALU (
		.a(reg_data1_ex),        // Input: First operand (from rs).
		.b(alu_in2_ex),          // Input: Second operand (from mux).
		.alu_ctrl(alu_ctrl_ex),  // Input: Operation to perform.
		.result(alu_result_ex),  // Output: Result of the computation.
		.zero(zero_ex)           // Output: Flag, high if the result is zero.
	);
	
	// Mux to select the destination register.
	// If reg_dst_ex is 1 (R-type), the destination is rd.
	// If reg_dst_ex is 0 (I-type, e.g., lw), the destination is rt.
	assign write_reg_ex = reg_dst_ex ? rd_ex : rt_ex;
	
	// Branch target address calculation.
	// Adds the PC (from the instruction's location) to the sign-extended, shifted immediate value.
	assign pc_branch_calc = pc_ex + (sign_ext_ex << 2);

	//----------------------------------------------------------------------
	// EX/MEM PIPELINE REGISTER
	// Passes ALU result, data, and control signals to the MEM stage.
	//----------------------------------------------------------------------
	ex_mem EX_MEM (
		.clk(clk),
		// Inputs from the EX stage
		.alu_result_in(alu_result_ex), 
		.write_data_in(reg_data2_ex), // `reg_data2_ex` is passed through to be used as write_data in `sw`
		.pc_branch_in(pc_branch_calc),
		.write_reg_in(write_reg_ex), 
		.zero_in(zero_ex),
		.mem_read_in(mem_read_ex), 
		.mem_write_in(mem_write_ex), 
		.mem_to_reg_in(mem_to_reg_ex),
		.reg_write_in(reg_write_ex), 
		.branch_in(branch_ex),

		// Outputs to the MEM stage
		.alu_result_out(alu_result_mem), 
		.write_data_out(write_data_mem), 
		.pc_branch_out(pc_branch_mem),
		.write_reg_out(write_reg_mem), 
		.zero_out(zero_mem),
		.mem_read_out(mem_read_mem), 
		.mem_write_out(mem_write_mem), 
		.mem_to_reg_out(mem_to_reg_mem),
		.reg_write_out(reg_write_mem), 
		.branch_out(branch_mem)
	);

	//----------------------------------------------------------------------
	// MEMORY ACCESS (MEM) STAGE
	// Reads from or writes to data memory if required by the instruction.
	//----------------------------------------------------------------------
	
	// Data Memory (dmem) module.
	// Can perform a read or a write in one clock cycle.
	dmem DMEM (
		.clk(clk), 
		.mem_read(mem_read_mem),     // Input: Read enable signal.
		.mem_write(mem_write_mem),   // Input: Write enable signal.
		.addr(alu_result_mem),       // Input: Address for read/write (from ALU result).
		.write_data(write_data_mem), // Input: Data to be written to memory.
		.read_data(read_data_mem)    // Output: Data read from memory.
	);

	//----------------------------------------------------------------------
	// MEM/WB PIPELINE REGISTER
	// Passes memory data or ALU result to the WB stage for writing to the register file.
	//----------------------------------------------------------------------
	mem_wb MEM_WB (
		.clk(clk),
		// Inputs from the MEM stage
		.mem_data_in(read_data_mem), 
		.alu_result_in(alu_result_mem), 
		.write_reg_in(write_reg_mem),
		.mem_to_reg_in(mem_to_reg_mem), 
		.reg_write_in(reg_write_mem),

		// Outputs to the WB stage
		.mem_data_out(mem_data_wb), 
		.alu_result_out(alu_result_wb), 
		.write_reg_out(write_reg_wb),
		.mem_to_reg_out(mem_to_reg_wb), 
		.reg_write_out(reg_write_wb)
	);

	//----------------------------------------------------------------------
	// WRITE BACK (WB) STAGE
	// Writes the final result back to the register file.
	//----------------------------------------------------------------------
	
	// Mux to select the data to be written back to the register file.
	// If mem_to_reg_wb is 1 (e.g., lw), select the data from memory.
	// If mem_to_reg_wb is 0 (e.g., R-type), select the result from the ALU.
	assign write_data_wb = mem_to_reg_wb ? mem_data_wb : alu_result_wb;

	//----------------------------------------------------------------------
	// PC UPDATE LOGIC
	// Determines the address of the next instruction.
	//----------------------------------------------------------------------
	
	// This logic selects the next PC value.
	// NOTE: This is a simplified branch logic that does not handle stalls or flushing.
	// It checks the branch condition from the MEM stage.
	// `1'bx` is used here to represent an unknown or 'don't care' state during the initial cycles.
	// If branch and zero signals are unknown, default to PC + 4.
	// Otherwise, if the branch is taken (branch_mem is 1 and zero_mem is 1), update PC to the branch target address.
	// If the branch is not taken, update PC to the next sequential address (PC + 4).
	assign pc_next = ((branch_mem === 1'bx) || (zero_mem === 1'bx)) ?
						pc_current + 4 :
						(branch_mem && zero_mem) ? pc_branch_mem : pc_current + 4;


endmodule
