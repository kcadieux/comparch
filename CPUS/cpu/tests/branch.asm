# Perform branches (beq, bne) which would create hazards 
# and see if they are handled correctly. 
 
 # initial values 
addi $1, $0, 1 
addi $2, $0, 2 

 
# increment $1 so it equals $2 
addi $1, $1, 1 

beq $1, $2, skip1 

 
 # these shouldn't get added 
#  If they do, the third hex digit will be 1 
addi $1, $1, 256 
addi $2, $2, 256 

 
skip1:  

add $1, $1, $1  # 2 + 2 = 4 
add $2, $1, $2  # 4 + 2 = 6 
 
 
 bne $1, $2, skip2 
 
 
 # these shouldn't get added 
 #  If they do, the fourth hex digit will be 1 
addi $1, $1, 4096 
addi $2, $2, 4096 

skip2:

asrti $1 4
asrti $2 6

halt