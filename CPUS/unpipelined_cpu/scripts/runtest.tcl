
;#Compile all components
source "$topLevelDir/scripts/compile.tcl"

;#Assemble the test file
set assemblerResult [exec "$topLevelDir/bin/Assembler.exe" "$topLevelDir/tests/$testName.asm"]

if {[string first "error" $assemblerResult] != -1} {
	puts "FAILURE: $assemblerResult"
	quit
}

;#Load the test into the CPU
vsim -quiet unpipelined_cpu -gFile_Address_Read="$topLevelDir/tests/$testName.dat"

;# Generate a 1ns clock
force -deposit /unpipelined_cpu/clk 0 0 ns, 1 0.5 ns -repeat 1 ns

when -label test_prog {/unpipelined_cpu/finished_prog == '1' || /unpipelined_cpu/assertion == '1'} {
	stop
}

run 2000 us

if {[exa /unpipelined_cpu/finished_prog] == 1} {
	puts "SUCCESS"
} elseif {[exa /unpipelined_cpu/assertion] == 1} {
	set failureLocation [expr [exa -radix unsigned /unpipelined_cpu/assertion_pc] / 4 + 1];
	puts "FAILURE: assertion at instruction $failureLocation"
} else {
	puts "FAILURE: program did not finish before timeout"
}

nowhen test_prog