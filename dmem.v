module dmem (
    input clk,
    input mem_read,
    input mem_write,
    input [31:0] addr,
    input [31:0] write_data,
    output reg [31:0] read_data
);

    reg [31:0] memory [0:255];

    always @(posedge clk) begin
        if (mem_write)
            memory[addr[9:2]] <= write_data;
    end

    always @(*) begin
        if (mem_read)
            read_data = memory[addr[9:2]];
        else
            read_data = 32'b0;
    end
endmodule
