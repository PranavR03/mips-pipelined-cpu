`timescale 1ns / 1ps

module tb_pipelined_cpu;

    // Inputs
    reg clk;
    reg reset;

    // Instantiate the Unit Under Test (UUT)
    pipelined_cpu uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Initial setup
    initial begin
        // Initialize inputs
        clk = 0;
        reset = 1;

        // Hold reset for 2 cycles (20ns)
        #20;
        reset = 0;

        // Let the CPU run for some cycles
        #1000;

        $finish;
    end

    // Display useful debug info every cycle
    initial begin
        $display("Time\tPC\t\tInstr\t\tRegWrite\tWriteReg\tWriteData");
        $monitor("%0t\t%h\t%h\t%b\t\t%h\t\t%h", 
            $time, 
            uut.pc_current,
            uut.instr_if,
            uut.reg_write_wb,
            uut.write_reg_wb,
            uut.write_data_wb
        );
    end

endmodule
