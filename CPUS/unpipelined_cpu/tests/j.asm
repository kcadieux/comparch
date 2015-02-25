addi $1 $0 99
J change_1
addi $2 $0 11 # should skip this line
change_1: addi $2 $0 1
add $3 $1 $2
asrti $3 100
halt
