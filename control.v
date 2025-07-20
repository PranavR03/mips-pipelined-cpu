module control ( 
	input [5:0] opcode,
	output reg reg_dst, alu_src, mem_to_reg, reg_write,
	output reg mem_read, mem_write, branch,
	output reg [1:0] alu_op
	);
	
	always @(*) begin
	//default values
	reg_dst = 0;
	alu_src = 0;
	mem_to_reg = 0;
	reg_write = 0;
	mem_read = 0;
	mem_write = 0;
	branch = 0;
	alu_op = 2'b00;
	
	case (opcode)
		6'b000000: begin // R-type
			reg_dst = 1;
			mem_to_reg = 1;
			reg_write = 1;
			mem_read = 1;
			alu_op =2'b00;
		end
		6'b100011: begin //lw
			alu_src = 1;
			mem_to_reg = 1;
			reg_write = 1;
			mem_read = 1;
			alu_op = 2'b00;
		end
		6'b101011: begin //sw
			alu_src = 1;
			mem_write = 1;
			alu_op = 2'b00;
		end
		6'b000100: begin //beq
			branch = 1;
			alu_op = 2'b01;
		end
		endcase
	end
endmodule