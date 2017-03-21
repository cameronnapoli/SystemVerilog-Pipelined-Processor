// Group Name: The Motherboard Maniacs
// Cameron Napoli  73223093
// Matt Rommel     43905998
// Noah Correa     83305686
// Yuen Chong Lai  82761961

module datapath(
    input logic clk, reset,
    input logic [1:0] RegSrcD,
    input logic RegWrite,
    input logic [1:0] ImmSrc,
    input logic ALUSrc,
    input logic [3:0] ALUControl,
    input logic MemtoReg,

    input logic PCSrcD, // Modified PCSrc for Pipeline Registers

    output logic [3:0] ALUFlags,
    output logic [31:0] PCF,
    input logic [31:0] InstrF,
    output logic [31:0] ALUResult, WriteData,
    input logic [31:0] ReadData,
    input logic BL);

    logic stallF;
    logic BranchTakenE;
    logic [31:0] PCNext, PCNext2, PCPlus4; //No longer use PCPlus8
    logic [31:0] ExtImm, SrcA, SrcB, ResultW;
    logic [31:0] Shamt, Out3, Reg, WD;
    logic [3:0] RA1, RA2, RA3, WA; //Added RA3, WriteData, Write Address


    // next PC logic
    mux2 #(32) pcmux(PCPlus4, ResultW, PCSrcW, PCNext); //1 Confirmed
    mux2 #(32) pcmux2(PCNext, ALUResultE, BranchTakenE, PCNext2);//2 confirmed

    /****** Instruction Fetch ******/
    regPCPCF pcreg(clk, stallF, PCNext2, PCF); //3 confirmed

    adder #(32) pcadd1(PCF, 32'b100, PCPlus4); //4
    //5: Imem implemented elsewhere. Datapath gives PCF to Imem and gets InstrF in return

    /****** Instruction Decode ******/
    logic [31:0] InstrD; // TODO connect this to output
    //Fetch-Decode Register
    regIFID fdreg(clk, flushD, stallD, InstrF, InstrD); //6 Confirmed

    // register file logic
    mux2 #(4) ra1mux(InstrD[19:16], 4'b1111, RegSrcD[0], RA1); //7 confirmed
    mux2 #(4) ra2mux(InstrD[3:0], InstrD[15:12], RegSrcD[1], RA2); //8 confirmed
    mux2 #(4) writeaddress(InstrF[15:12], 4'b1110, BL, WA); //TODO write address depends on BL
    mux2 #(32) writedata(Result, PCPlus4, BL, WD); //TODO write data depends on BL
    // clk, we, ra1, ra2, ra3,
    // wa, wd3, r15, rd1, rd2, rd3
    regfile rf(clk, RegWriteW, RA1, RA2, InstrD[11:8],
        WA, WD, PCPlus8, //TODO Switch to PCPlus4 ???
        SrcA, WriteData, Out3); //9 --remember RegWriteW. --WA and WD?


    extend ext(InstrD[23:0], ImmSrc, ExtImm); //10

    /****** Instruction Execute ******/
    // SrcA -> RD1, WriteData -> RD2, Out3 -> RD3
    // Need to connect these!!!
    logic [31:0] RD1E, RD2E, RD3E, ExtendE;
    logic PCSrcE, RegWriteE, MemtoRegE, MemWriteE;
    logic [3:0] ALUControlE;
    logic BranchE, ALUSrcE, FlagWriteE, CondE;
    logic [1:0] ImmSrcE;

    regIDEX dxreg(clk, flushE, SrcA, RD1E, WriteData, RD2E, Out3, RD3E, // 11
            ExtImm, ExtendE, PCSrcD, PCSrcE, RegWriteD, RegWriteE, // TODO Need to modify control bits
            MemtoRegD, MemtoRegE, MemWriteD, MemWriteE, ALUControlD,
            ALUControlE, BranchD, BranchE, ALUSrcD, ALUSrcE, FlagWriteD,
            FlagWriteE, ImmSrcD, ImmSrcE, CondD, CondE);

    /****** Instruction MEM ******/
    logic CondExE; // TODO need to add this as input
    // Add more wires for regEXMEM
    logic PCSrcM, RegWriteM, MemtoRegM, MemWriteM;
    logic [31:0] WriteDataM, ALUOutM, WA3M;
    regEXMEM xmreg(clk, (PCSrcE & CondExE) | (BranchE & CondExE) , PCSrcM, RegWriteE & CondExE, //12
                    RegWriteM, MemtoRegE, MemtoRegM, MemWriteE & CondExE, MemWriteM, ALUResultE, ALUOutM,
                    WriteDataE, WriteDataM, WA3E, WA3M);


    //Shift Logic
    mux2 #(32) shamtmux(ExtImm, Out3,  InstrD[4], Shamt);
	shifter shftr(Instr[6:5], Instr[4], ALUFlags[1], WriteData, Shamt, Reg, ALUFlags[1]); // InstrD???

    // ALU logic
    mux2 #(32) srcbmux(Reg, ExtImm, ALUSrc, SrcB); // Instr[25] should be the control...
    alu alu(SrcA, SrcB, ALUControl, ALUResult, ALUFlags); // TODO: Modify

    /****** Instruction Write Back ******/
    logic PCSrcW;
    regMEMWB mwreg(clk, PCSrcM, PCSrcW, RegWriteM, RegWriteW, MemtoRegM, //13
                    MemtoRegW, ReadDataM, ReadDataW, ALUOutM, ALUOutW, //ALUResult, WriteData, ReadData,
                    WA3M, WA3W);

    logic MemtoRegW;
    mux2 #(32) resmux(ALUResult, ReadDataW, MemtoRegW, Result); // TODO modify this, 21?
endmodule


module shifter(
    input logic [1:0] sh, // control bits
	input logic bit4, carry
    input logic [31:0] readVal1, // R2 value from RegFile
    input logic [31:0] shiftAmount, // R3 value or shamt from instruction
    output logic [31:0] shiftedOutput // shifted output
	output logic carryFlag);

always_comb
    case(sh)
        2'b00: // LSL (Logical Shift Left)
            shiftedOutput = readVal1 << shiftAmount;
        2'b01: // LSR (Logical Shift Right)
            shiftedOutput = readVal1 >> shiftAmount;
        2'b10: // ASR (Arithmetic Shift Right)
            shiftedOutput = readVal1 >>> shiftAmount;
        2'b11: // ROR (Rotate Right)
            case(shiftAmount[4:0])
                5'b00000: shiftedOutput = readVal1[31:0];
                5'b00001: shiftedOutput = {readVal1[0], readVal1[31:1]};
                5'b00010: shiftedOutput = {readVal1[1:0], readVal1[31:2]};
                5'b00011: shiftedOutput = {readVal1[2:0], readVal1[31:3]};
                5'b00100: shiftedOutput = {readVal1[3:0], readVal1[31:4]};
                5'b00101: shiftedOutput = {readVal1[4:0], readVal1[31:5]};
                5'b00110: shiftedOutput = {readVal1[5:0], readVal1[31:6]};
                5'b00111: shiftedOutput = {readVal1[6:0], readVal1[31:7]};
                5'b01000: shiftedOutput = {readVal1[7:0], readVal1[31:8]};
                5'b01001: shiftedOutput = {readVal1[8:0], readVal1[31:9]};
                5'b01010: shiftedOutput = {readVal1[9:0], readVal1[31:10]};
                5'b01011: shiftedOutput = {readVal1[10:0], readVal1[31:11]};
                5'b01100: shiftedOutput = {readVal1[11:0], readVal1[31:12]};
                5'b01101: shiftedOutput = {readVal1[12:0], readVal1[31:13]};
                5'b01110: shiftedOutput = {readVal1[13:0], readVal1[31:14]};
                5'b01111: shiftedOutput = {readVal1[14:0], readVal1[31:15]};
                5'b10000: shiftedOutput = {readVal1[15:0], readVal1[31:16]};
                5'b10001: shiftedOutput = {readVal1[16:0], readVal1[31:17]};
                5'b10010: shiftedOutput = {readVal1[17:0], readVal1[31:18]};
                5'b10011: shiftedOutput = {readVal1[18:0], readVal1[31:19]};
                5'b10100: shiftedOutput = {readVal1[19:0], readVal1[31:20]};
                5'b10101: shiftedOutput = {readVal1[20:0], readVal1[31:21]};
                5'b10110: shiftedOutput = {readVal1[21:0], readVal1[31:22]};
                5'b10111: shiftedOutput = {readVal1[22:0], readVal1[31:23]};
                5'b11000: shiftedOutput = {readVal1[23:0], readVal1[31:24]};
                5'b11001: shiftedOutput = {readVal1[24:0], readVal1[31:25]};
                5'b11010: shiftedOutput = {readVal1[25:0], readVal1[31:26]};
                5'b11011: shiftedOutput = {readVal1[26:0], readVal1[31:27]};
                5'b11100: shiftedOutput = {readVal1[27:0], readVal1[31:28]};
                5'b11101: shiftedOutput = {readVal1[28:0], readVal1[31:29]};
                5'b11110: shiftedOutput = {readVal1[29:0], readVal1[31:30]};
				5'b11111:
					if(bit4) // RRX
					{
						shiftedOutput = {carry, readVal1[31:1]};
						carryFlag = readVal1[0];
					}
					else  // ROR
						shiftedOutput = {readVal1[30:0], readVal1[31]};
            endcase
        default:
            shiftedOutput = 32'bx;
    endcase

endmodule

module match(
   input logic [3:0] R1,
   input logic [3:0] R2,
   output logic eq);

eq = (R1==R2);
end module
