proc ClearWaves {} {
	restart -force
	force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns
	AddWaves
}

proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
	add wave -position end  sim:/unpipelined_cpu/clk
	add wave -position end  sim:/unpipelined_cpu/current_state
	add wave -position end  sim:/unpipelined_cpu/curr_instr_byte
	add wave -position end  sim:/unpipelined_cpu/curr_instr
	add wave -position end  sim:/unpipelined_cpu/mem_initialize
	add wave -position end  sim:/unpipelined_cpu/mem_address
	
	
	
	;#add wave -position end  -radix unsigned sim:/router_port/get_data
}

;# Useful procedures to quickly test some router port functions
proc Put {dest_x dest_y nb_words address data} {
	if {[exa /router_port/wait_put] == 1} {
		puts "ERROR: Queue is full!"
		return
	}

	;# Connect the fields to the router_port's input ports
	force -deposit put 1
	force -deposit get 0
	force -deposit put_dest_x 10#$dest_x
	force -deposit put_dest_y 10#$dest_y
	force -deposit put_nb_words 10#$nb_words
	force -deposit put_address 10#$address
	force -deposit put_data 10#$data
	
	;# Tick the clock so that the input gets written
	run 1 ns;
}

proc Get {} {
	if {[exa /router_port/wait_get] == 1} {
		puts "ERROR: Queue is empty!"
		return
	}

	;# Connect the fields to the router_port's input ports
	force -deposit put 0
	force -deposit get 1
	
	;#Read the front of the queue
	set dest_x [exa -radix unsigned /router_port/get_dest_x]
	set dest_y [exa -radix unsigned /router_port/get_dest_y]
	set nb_words [exa -radix unsigned /router_port/get_nb_words]
	set address [exa -radix unsigned /router_port/get_address]
	set data [exa -radix unsigned /router_port/get_data]
	
	set message "($dest_x, $dest_y) x$nb_words @ $address : $data"
	puts $message
	
	;# Tick the clock so that the front of the queue gets removed
	run 1 ns;
}

;# Compile components
source compile.tcl

;#Start simulation
vsim unpipelined_cpu

;#Generate a clock with 1ns period
force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns


AddWaves


