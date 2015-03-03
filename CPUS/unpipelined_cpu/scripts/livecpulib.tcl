;# Create variables for the registers to be able
;# to access them with the dollar sign. Otherwise
;# we would have to escape the dollar sign every time.
set 0  "\$0"; 	set zero "\$0"
set 1  "\$1"; 	set at   "\$1";
set 2  "\$2"; 	set v0   "\$2";
set 3  "\$3"; 	set v1   "\$3";
set 4  "\$4"; 	set a0   "\$4";
set 5  "\$5"; 	set a1   "\$5";
set 6  "\$6"; 	set a2   "\$6";
set 7  "\$7"; 	set a3   "\$7";
set 8  "\$8"; 	set t0   "\$8";
set 9  "\$9"; 	set t1   "\$9";
set 10 "\$10"; 	set t2   "\$10";
set 11 "\$11"; 	set t3   "\$11";
set 12 "\$12"; 	set t4   "\$12";
set 13 "\$13"; 	set t5   "\$13";
set 14 "\$14"; 	set t6   "\$14";
set 15 "\$15"; 	set t7   "\$15";
set 16 "\$16"; 	set s0   "\$16";
set 17 "\$17"; 	set s1   "\$17";
set 18 "\$18"; 	set s2   "\$18";
set 19 "\$19"; 	set s3   "\$19";
set 20 "\$20"; 	set s4   "\$20";
set 21 "\$21"; 	set s5   "\$21";
set 22 "\$22"; 	set s6   "\$22";
set 23 "\$23"; 	set s7   "\$23";
set 24 "\$24"; 	set t8   "\$24";
set 25 "\$25"; 	set t9   "\$25";
set 26 "\$26"; 	set k0   "\$26";
set 27 "\$27"; 	set k1   "\$27";
set 28 "\$28"; 	set gp   "\$28";
set 29 "\$29"; 	set sp   "\$29";
set 30 "\$30"; 	set fp   "\$30";
set 31 "\$31"; 	set ra   "\$31";

set SRC_FOLDER		"$topLevelDir/src"
set TEST_FOLDER		"$topLevelDir/tests"
set ASSEMBLER_EXE 	"$topLevelDir/bin/Assembler.exe"
set TARGET_CPU		"cpu"

proc AddWaves {} {
	global TARGET_CPU
	
	;#Define radixes
	radix define OP_CODE {
		6'b000000 "ALU",
		6'b001000 "ADDI",
		6'b001010 "SLTI",
		6'b001100 "ANDI",
		6'b001101 "ORI",
		6'b001110 "XORI",
		6'b001111 "LUI",
		6'b100011 "LW",
		6'b100000 "LB",
		6'b101011 "SW",
		6'b101000 "SB",
		6'b000100 "BEQ",
		6'b000101 "BNE",
		6'b000010 "J",
		6'b000011 "JAL",
		6'b010100 "ASRT",
		6'b010101 "ASRTI"
		6'b010110 "HALT",
		-default hex
	}
	
	radix define ALU_FUNCT {
		6'b100000 "ADD",
		6'b100010 "SUB",
		6'b011000 "MULT",
		6'b011010 "DIV",
		6'b101010 "SLT",
		6'b100100 "AND",
		6'b100101 "OR",
		6'b100111 "NOR",
		6'b100110 "XOR",
		6'b000000 "SLL",
		6'b000010 "SRL",
		6'b000011 "SRA",
		6'b010000 "MFHI",
		6'b010010 "MFLO",
		6'b001000 "JR",
		-default hex
	}
	

	;#Add standard waves we might be interested in to the Wave window
	add wave -position end  sim:/$TARGET_CPU/clk
	add wave -position end  sim:/$TARGET_CPU/current_state
	
	;#IF stage signals
	add wave -group "IF Stage"  -radix unsigned sim:/$TARGET_CPU/if_i.pc\
								sim:/$TARGET_CPU/if_i.instr_ready\
								-radix binary sim:/$TARGET_CPU/if_i.instr\
								-radix binary sim:/$TARGET_CPU/if_i.instr_selection\
								sim:/$TARGET_CPU/if_i.can_issue\
								sim:/$TARGET_CPU/if_i.mem_is_free\
	                            sim:/$TARGET_CPU/if_i.mem_tx_ongoing\
								sim:/$TARGET_CPU/if_i.mem_tx_complete\
								sim:/$TARGET_CPU/if_i.mem_lock\
								-radix unsigned sim:/$TARGET_CPU/if_i.mm_address
								
	;#ID stage signals
	add wave -group "ID Stage"  -radix unsigned sim:/$TARGET_CPU/id.pc\
								-radix unsigned sim:/$TARGET_CPU/id.pos\
								-radix OP_CODE sim:/$TARGET_CPU/id.op\
								-radix ALU_FUNCT sim:/$TARGET_CPU/id.funct\
								-radix unsigned sim:/$TARGET_CPU/id.rs_addr\
								-radix unsigned sim:/$TARGET_CPU/id.rt_addr\
								-radix unsigned sim:/$TARGET_CPU/id.rd_addr\
								-radix unsigned sim:/$TARGET_CPU/id.dst_addr\
								-radix unsigned sim:/$TARGET_CPU/id.result\
								-radix unsigned sim:/$TARGET_CPU/id_i.next_pc\
								-radix binary sim:/$TARGET_CPU/idx.instr\
								sim:/$TARGET_CPU/id_i.is_stalled\
								sim:/$TARGET_CPU/id_i.branch_requested\
								sim:/$TARGET_CPU/id_i.halt_requested\
	                            -radix unsigned sim:/$TARGET_CPU/id_i.branch_addr\
								sim:/$TARGET_CPU/id_i.forward_rs\
								sim:/$TARGET_CPU/id_i.forward_rt
								
	;#EX stage signals
	add wave -group "EX Stage"  -radix unsigned sim:/$TARGET_CPU/ex.pc\
								-radix unsigned sim:/$TARGET_CPU/ex.pos\
								-radix OP_CODE sim:/$TARGET_CPU/ex.op\
								-radix ALU_FUNCT sim:/$TARGET_CPU/ex.funct\
								-radix unsigned sim:/$TARGET_CPU/ex.rs_addr\
								-radix unsigned sim:/$TARGET_CPU/ex.rt_addr\
								-radix unsigned sim:/$TARGET_CPU/ex.rd_addr\
								-radix unsigned sim:/$TARGET_CPU/ex.dst_addr\
								-radix unsigned sim:/$TARGET_CPU/ex.result\
								-radix decimal sim:/$TARGET_CPU/exx.rs_val\
								-radix decimal sim:/$TARGET_CPU/exx.rt_val\
								-radix decimal sim:/$TARGET_CPU/exx.imm\
								-radix decimal sim:/$TARGET_CPU/exx.imm_sign_ext\
								-radix unsigned sim:/$TARGET_CPU/exx.imm_zero_ext\
								-radix unsigned sim:/$TARGET_CPU/exx.shamt\
								sim:/$TARGET_CPU/ex_i.is_stalled\
								-radix decimal sim:/$TARGET_CPU/ex_i.rs_fwd_val\
								-radix decimal sim:/$TARGET_CPU/ex_i.rt_fwd_val\
								sim:/$TARGET_CPU/ex_i.assertion
								
	;#MEM stage signals
	add wave -group "MEM Stage" -radix unsigned sim:/$TARGET_CPU/mem.pc\
								-radix unsigned sim:/$TARGET_CPU/mem.pos\
								-radix OP_CODE sim:/$TARGET_CPU/mem.op\
								-radix ALU_FUNCT sim:/$TARGET_CPU/mem.funct\
								-radix unsigned sim:/$TARGET_CPU/mem.rs_addr\
								-radix unsigned sim:/$TARGET_CPU/mem.rt_addr\
								-radix unsigned sim:/$TARGET_CPU/mem.rd_addr\
								-radix unsigned sim:/$TARGET_CPU/mem.dst_addr\
								-radix unsigned sim:/$TARGET_CPU/mem.result\
								-radix decimal sim:/$TARGET_CPU/memx.rt_val\
								sim:/$TARGET_CPU/mem_i.is_stalled\
								sim:/$TARGET_CPU/mem_i.mem_request_lock\
								sim:/$TARGET_CPU/mem_i.mem_lock\
								sim:/$TARGET_CPU/mem_i.mem_tx_ongoing\
								sim:/$TARGET_CPU/mem_i.mem_tx_done\
								sim:/$TARGET_CPU/mem_i.mm_read\
								sim:/$TARGET_CPU/mem_i.mm_word_byte\
								-radix unsigned sim:/$TARGET_CPU/mem_i.mm_address\
								-radix decimal sim:/$TARGET_CPU/mem_i.mm_data
								
	;#WB stage signals
	add wave -group "WB Stage"  -radix unsigned sim:/$TARGET_CPU/wb.pc\
								-radix unsigned sim:/$TARGET_CPU/wb.pos\
								-radix OP_CODE sim:/$TARGET_CPU/wb.op\
								-radix ALU_FUNCT sim:/$TARGET_CPU/wb.funct\
								-radix unsigned sim:/$TARGET_CPU/wb.rs_addr\
								-radix unsigned sim:/$TARGET_CPU/wb.rt_addr\
								-radix unsigned sim:/$TARGET_CPU/wb.rd_addr\
								-radix unsigned sim:/$TARGET_CPU/wb.dst_addr\
								-radix unsigned sim:/$TARGET_CPU/wb.result
								
								
	;#Instruction decoder signals
	add wave -group "Instruction Decoder"\
								-radix OP_CODE sim:/$TARGET_CPU/dec_opcode\
								-radix unsigned sim:/$TARGET_CPU/dec_rs\
								-radix unsigned sim:/$TARGET_CPU/dec_rt\
								-radix unsigned sim:/$TARGET_CPU/dec_rd\
								-radix unsigned sim:/$TARGET_CPU/dec_shamt\
								-radix ALU_FUNCT sim:/$TARGET_CPU/dec_funct\
								-radix unsigned sim:/$TARGET_CPU/dec_imm\
								-radix decimal sim:/$TARGET_CPU/dec_imm_sign_ext\
								-radix unsigned sim:/$TARGET_CPU/dec_imm_zero_ext\
								-radix unsigned sim:/$TARGET_CPU/dec_branch_addr\
								-radix unsigned sim:/$TARGET_CPU/dec_jump_addr\
								
	;#Register file signals
	add wave -group Registers   -radix unsigned sim:/$TARGET_CPU/reg_read1_addr\
								-radix decimal  sim:/$TARGET_CPU/reg_read1_data\
								-radix unsigned sim:/$TARGET_CPU/reg_read2_addr\
								-radix decimal  sim:/$TARGET_CPU/reg_read2_data\
	                            sim:/$TARGET_CPU/reg_we\
								-radix unsigned sim:/$TARGET_CPU/reg_write_addr\
								-radix decimal  sim:/$TARGET_CPU/reg_write_data
	
	;#ALU signals
	add wave -group ALU  		-radix decimal  sim:/$TARGET_CPU/alu_a\
								-radix decimal  sim:/$TARGET_CPU/alu_a\
								-radix decimal  sim:/$TARGET_CPU/alu_b\
								-radix ALU_FUNCT sim:/$TARGET_CPU/alu_funct\
								-radix unsigned sim:/$TARGET_CPU/alu_shamt\
								-radix decimal  sim:/$TARGET_CPU/alu_result
	
	;#Memory signals
	add wave -group Memory     	-radix unsigned sim:/$TARGET_CPU/mm_address\
								sim:/$TARGET_CPU/mm_word_byte\
								sim:/$TARGET_CPU/mm_we\
								sim:/$TARGET_CPU/mm_wr_done\
								sim:/$TARGET_CPU/mm_re\
								sim:/$TARGET_CPU/mm_rd_ready\
								-radix decimal  sim:/$TARGET_CPU/mm_data
								
								
	configure wave -namecolwidth 250
	WaveRestoreZoom {0 ns} {8 ns}
}


proc CompileComponent {componentName} {
	global SRC_FOLDER

	vcom "$SRC_FOLDER/$componentName.vhd"
}

proc CompileCPU {} {

	if {[expr ![file exists work]]} {
		vlib work
	}

    CompileComponent architecture_constants
    CompileComponent op_codes
    CompileComponent alu_codes
    CompileComponent alu
	CompileComponent Memory_in_Byte
    CompileComponent Main_Memory
    CompileComponent register_file
    CompileComponent instr_decoder
	CompileComponent cpu_lib
    CompileComponent cpu
}

proc GenerateCPUClock {} {
	global TARGET_CPU
	force -deposit /$TARGET_CPU/clk 0 0 ns, 1 0.5 ns -repeat 1 ns
}

proc InitCPU {args} {
	global TARGET_CPU

	set datFileName [lindex $args 0]
	if {$datFileName == ""} {
		set datFileName "Init"
	}	
	
	set memDump "_memdump"
	vsim -quiet $TARGET_CPU -gFile_Address_Read="$datFileName.dat" -gFile_Address_Write="$datFileName$memDump.dat" -gMem_Size_in_Word=4096
	
	GenerateCPUClock
	
	AddWaves
	
	run 1 ns
}

proc RebootCPU {} {
	restart -force
	GenerateCPUClock
	run 1 ns
}

proc AssembleInstruction {args} {
	global ASSEMBLER_EXE
	set instr [join $args " "]
	
	set assemblerResult [exec "$ASSEMBLER_EXE" -i "$instr"];
	
	if {[string first "ERROR" [string toupper $assemblerResult]] != -1} {
		puts "ASSEMBLER FAILURE: $assemblerResult"
		return
	}
	
	return $assemblerResult
}

proc bin {args} {
	global ASSEMBLER_EXE
	set instr [join $args " "]
	puts [exec "$ASSEMBLER_EXE" -i "$instr"]
}


proc ExecuteInstruction {args} {
	global ASSEMBLER_EXE
	global TARGET_CPU
	
	;# Activate live mode
	force -deposit /$TARGET_CPU/live_mode 1
	
	set instr [eval AssembleInstruction $args]
	
	if {$instr == ""} {
		return
	}
	
	force -deposit /$TARGET_CPU/live_instr $instr
	run 1 ns
	
	set clockCycles 0
	set clockCycleLimit 200
	while {[exa /$TARGET_CPU/finished_instr] != 1 && [exa /$TARGET_CPU/finished_prog] != 1 && [exa /$TARGET_CPU/assertion] != 1 && $clockCycles < $clockCycleLimit} {
		run 1 ns
		set clockCycles [expr {$clockCycles + 1}]
	}
	
	if {$clockCycles == $clockCycleLimit} {
		puts "Error: the instruction was in execution for an unexpectedly high number of cycles"
	}
	
	;# Deactivate live mode
	force -deposit /$TARGET_CPU/live_mode 0
}

proc asm {args} {
	eval ExecuteInstruction $args
}

proc GetRegisterValue {regVar args} {
	global TARGET_CPU

	set regNumber [string replace $regVar 0 0 ""]
	
	if {$regNumber == ""} {
		puts "Invalid register, make sure to include the dollar sign (\$)"
		return
	}
	
	set radix "signed"
	
	if {[lindex $args 0] != ""} {
		set radix [lindex $args 0]
	}
	
	set regValue 0
	if {$regNumber > 0} {
		set regValue [exa -radix $radix /$TARGET_CPU/reg_file/regs($regNumber)]
	}
	
	puts "\$$regNumber:\t$regValue"
}

proc reg {args} {
	eval GetRegisterValue $args
}

proc DumpAllRegisters {args} {
	for {set i 0} {$i <= 31} {incr i} {
		reg "\$$i" $args
	}
}

proc regs {args} {
	eval DumpAllRegisters $args
}

proc VerifyTestExists {testName} {
	global TEST_FOLDER

	if {[expr ![file exists "$TEST_FOLDER/$testName.asm"]]} {
		puts "USAGE FAILURE: The specified test does not exist"
		return -1
	}
	
	return 0
}

proc AssembleTest {testName} {
	global ASSEMBLER_EXE
	global TEST_FOLDER
	
	set assemblerResult [exec "$ASSEMBLER_EXE" "$TEST_FOLDER/$testName.asm"]
	
	if {[string first "error" $assemblerResult] != -1} {
		puts "ASSEMBLER FAILURE: $assemblerResult"
		return -1
	}
	
	return 0
}

proc InitTest {testName} {
	global TEST_FOLDER
	global TARGET_CPU

	if {[VerifyTestExists $testName] != 0} {
		return
	}
	
	if {[AssembleTest $testName] != 0} {
		return
	}
	
	InitCPU "$TEST_FOLDER/$testName"
}

proc RunTest {testName} {
	global TARGET_CPU

	InitTest $testName
	
	when -label test_prog {/cpu/finished_prog == '1' || /cpu/assertion == '1'} {
		stop
	}

	run 1 us

	if {[exa /$TARGET_CPU/finished_prog] == 1} {
		puts "SUCCESS"
	} elseif {[exa /$TARGET_CPU/assertion] == 1} {
		set failureLocation [expr [exa -radix unsigned /$TARGET_CPU/assertion_pc] / 4 + 1];
		puts "CPU FAILURE: assertion at instruction $failureLocation"
	} else {
		puts "CPU FAILURE: program did not finish before timeout"
	
	}

	nowhen test_prog
}

proc test {args} {
	eval RunTest $args
}