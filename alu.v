module alu (
	input [31:0] a, b,
	input [2:0] alu_ctrl,
	output reg [31:0] result,
	output zero
	);
	
	always @(*) begin
		case (alu_ctrl)
			3'b000: result = a & b;
			3'b001: result = a | b;
			3'b010: result = a + b;
			3'b011: result = a ^ b;
			3'b100: result = ~(a | b);
			3'b101: result = b << a[4:0];    //SLL
			3'b110: result = a - b;
			3'b111: result = (a < b) ? 1 : 0; //SLT
			default: result  = 0;
		endcase
	end
	assign zeero = (result == 0);
endmodule