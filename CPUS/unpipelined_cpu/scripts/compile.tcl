if {[expr {![file exists work]}]} {
	vlib work
}

vcom -quiet "$topLevelDir/src/architecture_constants.vhd"
vcom -quiet "$topLevelDir/src/op_codes.vhd"
vcom -quiet "$topLevelDir/src/alu_codes.vhd"
vcom -quiet "$topLevelDir/src/alu.vhd"
vcom -quiet "$topLevelDir/src/Main_Memory.vhd"
vcom -quiet "$topLevelDir/src/register_file.vhd"
vcom -quiet "$topLevelDir/src/instr_decoder.vhd"
vcom -quiet "$topLevelDir/src/unpipelined_cpu.vhd"