
Tested with: ModelSim ALTERA STARTER EDITION 10.1d

Preliminary step:
1. Place unpipelined_cpu_tb.vhd and compile.tcl inside the CPUS/unpipelined_cpu/src folder

How to test a program:
1. Place your assembled program (.dat file) in CPUS/unpipelined_cpu/src folder
2. Open ModelSim
3. Use the CD command in the ModelSim command line to go the CPUS/unpipelined_cpu/src folder
4. Type the following command: "source compile.tcl" to compile the processor
5. Type the following command: "vsim unpipelined_cpu_tb -gFile_Address_Read="Name_Of_Assembled_Program_File.dat" -gMem_Size_in_Word="Enter_Size_Of_Memory_Here" -gExecution_Cycles="Enter_Number_Of_Cycles_For_Execution_Here"
	e.g. vsim unpipelined_cpu_tb -gFile_Address_Read="sb_lb.dat" -gMem_Size_in_Word="1000" -gExecution_Cycles="10000"
6. Type the following command: "run -a"
7. Wait a little while (long enough to make sure execution of the program is complete)
8. Hit stop icon to stop the simulation
9. View the memory content in MemCon.dat in the src folder

Note: Instructions on how to assemble a program are included in the top level readme.md file. Make sure to end all your programs with a "halt" instruction.

Known assembler bug: The assembler will crash if there is a label but no instruction on the same line (e.g. "Loop: " will crash, but not "Loop: addi $1 $0 100")