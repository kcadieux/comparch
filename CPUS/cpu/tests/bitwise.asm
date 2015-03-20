# Differences between bitwise and logical operators (& vs &&, | vs ||)
# $1: x = 3
# $2: y = 4
# $3: z = x & y    */ bitwise AND: 0...0011 and 0...0100 = 0...0 /*
# $4: w = x && y   */ logical AND: both are nonzero, so w = 1 /*
# $5: a = x | y    */ bitwise OR: 0...0011 and 0...0100 = 0...0111 /*
# $6: b = x || y   */ logical OR: at least one is nonzero, so w = 1 /*


				addi  $11, $0, 2000  	# initializing the beginning of Data Section address in memory
				addi  $15, $0, 4 		# word size in byte
				
Bitwise:        addi  $1, $0, 3
                addi  $2, $0, 4
                and   $3, $1, $2         # z = x & y
				asrti $3 0
				
				addi  $10, $0, 0
				mult  $10, $15			# $lo=4*$10, for word alignment 
				mflo  $12				# assume small numbers
				asrti $12 0
				add   $13, $11, $12 		# Make data pointer [2000+($10)*4]
				asrti $13 2000
				add   $2,$0,$3 
				asrti $2 0 
				sw	  $2, 0($13)

                # w = x && y
                beq   $1, $0, False      # branch to False if x = 0
                beq   $2, $0, False      # branch to False if y = 0
                addi  $4, $0, 1          # x and y are both nonzero, so w = 1
				
				addi  $10, $0, 1
				mult  $10, $15			# $lo=4*$10, for word alignment 
				mflo  $12				# assume small numbers
				add   $13, $11, $12 		# Make data pointer [2000+($10)*4]
				add   $2,$0,$4 
				sw	  $2, 0($13)
				
                j Continue
False:          addi  $4, $0, 0          # x and/or y are 0, so w = 0

Continue:       or    $5, $1, $2         # a = x | y
				asrti $5  3
				
				addi  $10, $0, 3
				mult  $10, $15			# $lo=4*$10, for word alignment 
				mflo  $12				# assume small numbers
				asrti $12 12
				add   $13, $11, $12 		# Make data pointer [2000+($10)*4]
				asrti $13 2012
				add   $2,$0,$5 
				sw	 $2, 0($13)
				
                # w = x || y
                bne  $1, $0, True       # branch to True if x is non-zero
                bne  $2, $0, True       # branch to True if y is non-zero
                addi $6, $0, 0          # x and y are both zero, so b = 0
				
				addi $10, $0, 4
				mult $10, $15			# $lo=4*$10, for word alignment 
				mflo $12				# assume small numbers
				add  $13, $11, $12 		# Make data pointer [2000+($10)*4]
				add  $2,$0,$6 
				sw	 $2, 0($13)
				
                j End
True:           addi $6, $0, 1          # x and/or y are non-zero, so b = 1


End:			asrti $4 0
				asrti $6 1
				
				lw    $20 0($11)
				lw    $21 12($11)
				
				asrti $20 0
				asrti $21 3
				halt
