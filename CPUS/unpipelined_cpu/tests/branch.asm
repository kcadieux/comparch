 # Perform branches (beq, bne) which would create hazards 
 # and see if they are handled correctly. 
 
 # initial values 
addi $0, $zero, 1 
addi $1, $zero, 2 

 
 # increment $0 so it equals $1 
 addi $0, $0, 1 

 beq $0, $1, skip1 

 
 # these shouldn't get added 
#  If they do, the third hex digit will be 1 
 addi $0, $0, 256 
addi $1, $1, 256 

 
skip1: 

 
 add $0, $0, $1  # 2 + 2 = 4 
 add $1, $0, $1  # 4 + 2 = 6 
 
 
 bne $0, $1, skip2 
 
 
 # these shouldn't get added 
 #  If they do, the fourth hex digit will be 1 
addi $0, $0, 4096 
addi $1, $1, 4096 

skip2:

astri $0 4
astri $1 6
