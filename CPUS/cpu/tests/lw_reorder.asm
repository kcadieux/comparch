addi $11,  $0, 2000  	# initializing the beginning of Data Section address in memory
addi $15, $0, 4 		# word size in byte
addi $10, $0, 0
mult $10, $15			# $lo=4*$10, for word alignment 
mflo $12				# assume small numbers
add  $13, $11, $12 		# Make data pointer [2000+($10)*4]
addi $2,$0,34 
sw	 $2, 0($13)

lw    $10 0($11)
addi $10,$10,42
addi $10,$0,55
add $11 $10 $14
add $14, $0, $0
add $10, $0, $0
add $16, $17, $18

asrti $14,0
asrti $10,0
halt