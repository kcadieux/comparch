# This is a linear search program. It searches the array for 
# the answer to life, the universe and everything.
# Our memory list is a series of words, terminated with -1
# mem: .word 4, 5, 3, 2, 1, 8, 2, 2, 4, 86, 95, 123, 4, 13, 24, 52, 33, 34, 38, 31, 42, 13, 12, -1
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
 addi $2,$0,1    # Saved value into memory
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
 addi $2,$0,2    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 7   # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,2   # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 8      # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,4   # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 9   # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,86    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 10  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,95    # Saved value into memory
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
 addi $2,$0,4    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 14  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,13    # Saved value into memory
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
 addi $2,$0,34    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 19  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,38    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 20  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,31    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 21  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,42    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 22  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,13    # Saved value into memory
 sw  $2, 0($13)
 
 addi $10, $0, 23  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,52    # Saved value into memory
 sw  $2, 0($12)
 
 addi $10, $0, 24  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,-1    # Saved value into memory
 sw  $2, 0($12)

##############################################################
 

# Start of list processing:
main:  addi $6,  $0, 2000  
  addi   $20,$0,0         # Clear our 'found' flag
  addi	 $16,$0,42		  # The number we are looking for
# For each element of list: 
loop: lw   $10,0($6)     # Load current value into $10
 
  beq $10, $16,found	# If value was found, our work here is done
 
  slti $21, $10, 0
  addi $22, $0, 1
  beq  $21,$22,done     # If end of list, our work here is done
 
  addi $6,$6,4     # Advance $6 to next list element
  j    loop          # Compare this element now
 
# The answer was found
found:   addi $20,$0,1	# Set our found flag
  j    done
 
# Done
done:  	asrti $20,1  # The value was found
  halt