# 🚀 5-Stage Pipelined MIPS CPU (Verilog)

This project is a Verilog implementation of a classic 5-stage pipelined MIPS processor — the same kind that’s taught in computer architecture courses, but fully coded and simulated from scratch.

Built using Xilinx Vivado and tested using simulation waveforms.

## 🧠 What It Does

This MIPS CPU goes through five pipeline stages:

1. **IF** – Instruction Fetch  
2. **ID** – Instruction Decode & Register Fetch  
3. **EX** – Execute / ALU Ops  
4. **MEM** – Memory Access  
5. **WB** – Write Back to Registers

It supports instruction flow, branching, and memory operations with basic control logic and no forwarding/stall logic (yet!).


## 📂 Project Structure

| File              | What It Does                          |
|-------------------|----------------------------------------|
| `pipelined_cpu.v` | Top-level module connecting all stages |
| `pc.v`            | Program Counter logic                  |
| `alu.v`           | ALU unit with arithmetic/logic ops     |
| `regfile.v`       | 32-register file for data storage      |
| `control.v`       | Main control logic unit                |
| `if_id.v` etc.    | Pipeline register modules              |
| `imem.v`          | Instruction memory                     |
| `dmem.v`          | Data memory                            |
| `tb_cpu.v`        | Testbench for simulating the design    |
| `imem_init.mem`   | Sample instructions in hex format      |

---

## 🛠️ How to Run (Simulation in Vivado)

1. Open **Vivado** and create a new RTL project
2. Add all `.v` source files and the testbench
3. Add `imem_init.mem` under **Simulation Sources**
4. Set `tb_cpu.v` as the **top module**
5. Run Simulation → Launch Waveform Viewer
6. Watch the pipeline flow happen 👀



