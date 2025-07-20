module imem (
    input [31:0] addr,
    output [31:0] instr
);

    reg [31:0] memory [0:255];

    initial begin
        $readmemh("imem_init.mem", memory);
        $display("IMEM[0] = %h", memory[0]);
    end

    assign instr = memory[addr[9:2]];  // word-aligned fetch

endmodule
