
if {[expr ![file exists work]]} {
	vlib work
}

vcom architecture_constants.vhd
vcom op_codes.vhd
vcom alu_codes.vhd
vcom alu.vhd
vcom Memory_in_Byte.vhd
vcom Main_Memory.vhd
vcom register_file.vhd
vcom instr_decoder.vhd
vcom cpu_lib.vhd
vcom bpb.vhd
vcom cpu.vhd
vcom cpu_tb.vhd