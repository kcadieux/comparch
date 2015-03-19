
# Test whether operations which require a stall and 
 # forward work correctly. 

 
 # initial values 
 addi $3, $0, 5 
addi $1, $0, 7 
addi $2, $0, 9 
 
 
 # store words in memory 
 sw $3, 0($0)  # 5 
 sw $1, 4($0)  # 7 

# read the memory and perform an operation 
#   *** stall and forward required *** 
 lw $2, 4($0) # 7 
add $4, $3, $2   # 5 + 7 = 12 

astri $4 12
