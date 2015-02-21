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
set TARGET_CPU		"unpipelined_cpu"

proc CompileComponent {componentName} {
	global SRC_FOLDER
	
	if {[expr ![file exists work]]} {
		vlib work
	}
	
	set componentIsCompiled [file exists work/$componentName]
	set srcTime 			[file mtime "$SRC_FOLDER/$componentName.vhd"]
	
	set compiledTime		0
	if {$componentIsCompiled} {
		set compiledTime 	[file mtime work/$componentName]
	}
	
	if {[expr !$componentIsCompiled] || $srcTime >= $compiledTime} {
		puts "Source version is more recent than compiled version. Compiling $componentName..."
		vcom -quiet "$SRC_FOLDER/$componentName.vhd"
	}
}

proc CompileCPU {} {
	CompileComponent architecture_constants
	CompileComponent op_codes
	CompileComponent alu_codes
	CompileComponent alu
	CompileComponent Main_Memory
	CompileComponent register_file
	CompileComponent instr_decoder
	CompileComponent unpipelined_cpu
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
	vsim -quiet $TARGET_CPU -gFile_Address_Read="$datFileName.dat" -gFile_Address_Write="$datFileName$memDump.dat"
	
	GenerateCPUClock
	
	run 1 ns
}

proc RebootCPU {} {
	restart -force
	GenerateCPUClock
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

proc ExecuteInstruction {args} {
	global ASSEMBLER_EXE
	global TARGET_CPU
	
	;#Verify that CPU is in FETCH state
	if {[exa /$TARGET_CPU/current_state] != "FETCH"} {
		puts "The CPU must be in the FETCH state to insert an instruction"
		return -1
	}
	
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

proc RunTest {testName} {
	global TEST_FOLDER
	global TARGET_CPU

	if {[VerifyTestExists $testName] != 0} {
		return
	}
	
	if {[AssembleTest $testName] != 0} {
		return
	}
	
	InitCPU "$TEST_FOLDER/$testName"
	
	when -label test_prog {/unpipelined_cpu/finished_prog == '1' || /unpipelined_cpu/assertion == '1'} {
		stop
	}

	run 2000 us

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