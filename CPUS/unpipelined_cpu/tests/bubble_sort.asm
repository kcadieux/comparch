 # This is a bubble sort program. it sorts the data in mem from address=2000 
 # Our memory list is a series of words, terminated with -1
 # mem: .word 4, 5, 3, 2, 1, 8, 2, 2, 4, 86, 95, 123, 4  -1
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
 
 addi $10, $0, 13  # word number 
 mult $10, $15   # $10=4*$10, for word alignment 
 mflo $12    # assume small numbers
 add  $13, $11, $12   # Make data pointer [2000+($10)*4]
 addi $2,$0,-1    # Saved value into memory
 sw  $2, 0($13)
##############################################################
 

# Start of list processing:
main:  addi $6,  $0, 2000  # la $6,mem      # Load 'mem' address into $6
  addi   $20,$0,0         # Clear our 'out of order' flag
 
# For each element of list: 
loop: lw   $10,0($6)     # Load current value into $10
  lw   $1,4($6)    # Load next value into $1
 
  slti $21, $1, 0
  addi $22, $0, 1
  beq  $21,$22,redo     # If next < 0 (end), rescan list
  
  sub  $21,$1,$10
  sra  $21, $21, 31
  addi $19,$0,-1
  xor  $21,$21,$19
  bne  $21,$0,next   # If next >= current, advance to 'next'
 
  sw   $1,0($6)     # Store next value in current memory
  sw   $10,4($6)    # Store current value in next memory
  addi $20,$0,1       # Set our 'out of ourder' flag
 
# Advance to next list element:
next:   addi $6,$6,4     # Advance $6 to next list element
  j    loop          # Compare this element now
 
# Rescan the list:
redo:   beq $20,$0,done       # Finish if 'out of order' flag = 0
  addi $6,  $0, 2000       # Otherwise, load start of list in $6
  j    main            # and rescan the list
 
# Exit
done:  halt