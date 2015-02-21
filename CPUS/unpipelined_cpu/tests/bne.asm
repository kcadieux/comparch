addi $1 $0 99
addi $2 $0 98
addi $3 $0 0
bne $1 $2 L1
addi $3 $0 9999
L1: addi $4 $0 55
asrti $3 0
asrti $4 55
halt
