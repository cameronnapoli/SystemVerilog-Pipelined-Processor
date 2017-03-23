module arm(
    input logic clk, reset,
    output logic [31:0] PCF, // {datapath} O to imem
    input logic [31:0] InstrF, // {datapath} I from imem
    output logic MemWriteM, // {datapath} O to datapath
    output logic [31:0] ALUResultM, WriteDataM, // {datapath} O to dmem
    input logic [31:0] ReadDataM,
    output logic BEDmem); // {datapath} to dmem

    logic [3:0] ALUFlagsE, ALUControl, CondE, FlagsEO;
    logic RegWrite, Branch, ALUSrc, MemtoReg, PCSrc, MemWrite, FlagWriteE, FlagsE;
    logic [1:0] RegSrc, ImmSrc, FlagWriteD;
    logic [31:0] InstrD; // Intermediary signal to allow Instr to pass through pipe
	logic PCSE, RegWriteD, MemWriteE, BranchE, BLE;
	logic PCSrcEO, RegWriteEO, MemWriteEO, BranchEO, BLEO;
    logic BEDmemE, BranchD, BL;

    logic [27:26] Op;
	logic [25:20] Funct;
	logic [15:12] Rd;


    controller c(
        // control unit input
        clk, reset, Op, Funct, Rd,
    	// control unit output
		PCSrc, RegWrite, MemtoReg, MemWrite,
		ALUControl, Branch, ALUSrc, FlagWriteE, ImmSrc, RegSrc,
		BEDmemE, BL,
		// condlogic input
		CondE, ALUFlagsE, FlagWrite, FlagsE,
		PCSE, RegWriteD, MemWriteE, BranchE, BLE,
		// condlogic output
		FlagsEO,
		PCSrcEO, RegWriteEO, MemWriteEO, BranchEO, BLEO);


    datapath dp(clk, reset,
        // imem
        PCF, InstrF,
        // control unit (decoder)
        Op, Funct, Rd,
        PCSrc, RegWriteD, MemtoRegD, MemWriteD,
        ALUControlD, BranchD, ALUSrcD, ImmSrcD,
        RegSrcD, FlagWriteD, BLD,
        // For condlogic
        CondE, ALUFlagsE, FlagWriteE, FlagsE,
        PCSrcE, RegWriteE, MemWriteE, BranchE, BLE,
        FlagsEO,
        PCSrcEO, RegWriteEO, MemWriteEO, BranchEO, BLEO,
        // For DMEM
        MemWriteM,
        ALUResultM, WriteDataM,
        ReadDataM);


endmodule
