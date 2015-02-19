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

proc RebootCPU {} {
	restart -force
	InitCPU
}

proc InitCPU {} {
	;# Generate a 1ns clock
	force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns
	
	;# Activate live mode
	force -deposit live_mode 1
	
	run 1 ns
}

proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	add wave -position end  sim:/unpipelined_cpu/clk
	add wave -position end  sim:/unpipelined_cpu/current_state
	add wave -position end  sim:/unpipelined_cpu/curr_instr_byte
	add wave -position end  sim:/unpipelined_cpu/curr_instr
	add wave -position end  sim:/unpipelined_cpu/mem_initialize
	add wave -position end  sim:/unpipelined_cpu/mem_address
	add wave -position end  sim:/unpipelined_cpu/live_instr
	add wave -position end  sim:/unpipelined_cpu/finished_instr
	add wave -position end  sim:/unpipelined_cpu/regs
	;#add wave -position end  -radix unsigned sim:/router_port/get_data
}

proc asmToBin {args} {
	global topLevelDir
	set instr [join $args " "]
	puts [exec $topLevelDir/bin/Assembler.exe -i "$instr"];
}

proc asm {args} {
	global topLevelDir
	set instr [join $args " "]
	force -deposit live_instr [exec $topLevelDir/bin/Assembler.exe -i "$instr"]
	run 1 ns
	
	set clockCycles 0
	set clockCycleLimit 200
	while {[exa /unpipelined_cpu/finished_instr] != 1 && [exa /unpipelined_cpu/finished_prog] != 1 && [exa /unpipelined_cpu/assertion] != 1 && $clockCycles < $clockCycleLimit} {
		run 1 ns
		set clockCycles [expr {$clockCycles + 1}]
	}
	
	if {$clockCycles == $clockCycleLimit} {
		puts "Error: the instruction was in execution for an unexpectedly high number of cycles"
	}
}

proc asmSlow {args} {
	global topLevelDir
	set instr [join $args " "]
	force -deposit live_instr [exec $topLevelDir/bin/Assembler.exe -i "$instr"]
}

proc reg {args} {
	set regNumber [string replace [lindex $args 0] 0 0 ""]
	
	if {$regNumber == ""} {
		puts "Invalid register, make sure to include the dollar sign (\$)"
		return
	}
	
	set radix "signed"
	
	if {[llength $args] > 1} {
		set radix [lindex $args 1]
	}
	
	set regValue [exa -radix $radix /unpipelined_cpu/regs($regNumber)]
	puts "Value: $regValue"
}

;#Compile all components
source $topLevelDir/scripts/compile.tcl

;#Start simulation
vsim -quiet unpipelined_cpu

InitCPU
AddWaves
