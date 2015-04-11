# This is a fizzbuzz implementation. If a given number is divisible by 3,
# the flag fizz is set. If it is divisible by 5, the flag buzz is set. If
# it is divisible by 15, the flag fizzbuzz is set.
# Our memory list is a series of words, terminated with -1
# mem: .word 4, 5, 3, 2, 15, 8, 25, 30, 9, 90, 60, 123, 120, 20, 24, 52, 33, 150, 300, 316, 315, -1
###########Setting the data memory ##############
 
 addi $11,  $0, 2000   # initializing the beginning of Data Section address in memory
 addi $15, $0, 4   # word size in byte
 
 addi $10, $0, 0
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,4
 sw  $2, 0($13)
 
 addi $10, $0, 1
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,5 
 sw  $2, 0($13)
 
 addi $10, $0, 2
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,3 
 sw  $2, 0($13)
 
 addi $10, $0, 3
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,2 
 sw  $2, 0($13)
 
 addi $10, $0, 4   # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,15    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 5   # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,8    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 6   # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,25    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 7   # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,30   # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 8      # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,9   # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 9   # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,90    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 10  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,60    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 11  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,123    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 12  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,120    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 14  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,20    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 15  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,24    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 16  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,52    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 17  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,33    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 18  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,150    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 19  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,300    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 20  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,316    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 21  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,315    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 22  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,-1    # Saved value into memory
 sw  $2, 0($13)

##############################################################
 

# Start of list processing:
  addi $6,  $0, 2000  
  addi $20,$0,0         # Clear our 'fizz' flag
  addi $21,$0,0         # Clear our 'buzz' flag
  addi $22,$0,0         # Clear our 'fizzbuzz' flag  
  addi $24,$0,1		    # Flag to signal the end of list
  addi $25,$0,3			# Compare value for 'fizz'
  addi $26,$0,5			# Compare value for 'buzz'
  addi $27,$0,15		# Compare value for 'fizzbuzz'
  
# For each element of list: 
loop: 
  lw   $10,0($6)     # Load current value into $10
  slti $23, $10, 0
  beq  $23,$24,done     # If end of list, our work here is done
  
  div $10,$25		# divide by 3
  mfhi $3 			# reminder of the division (modulo equivalence)
  bne $3,$0,buzz # If not equal to 0, skip fizz flag
  
  addi $20,$20,1	# Add 1 to the fizz flag
  
buzz:
  div $10,$26			# divide by 5
  mfhi $3 				# reminder of the division (modulo equivalence)
  bne $3,$0,fizzbuzz # If not equal to 0, skip fizz flag
  addi $21,$21,1	# Add 1 to the buzz flag
  
fizzbuzz:
  div $10,$27			# divide by 15
  mfhi $3 				# reminder of the division (modulo equivalence)
  bne $3,$0,nofizzbuzz  # If not equal to 0, skip fizz flag
  addi $22,$22,1	# Add 1 to the fizzbuzz flag

nofizzbuzz:
  addi $6,$6,4     # Advance $6 to next list element
  j    loop          # Compare this element now

# Done
done:
asrti $20,13  # The amount of fizz (/3) = 13
asrti $21,11  # The amount of buzz (/5) = 11
asrti $22,8  # The amount of fizzbuzz (/15) = 8
halt