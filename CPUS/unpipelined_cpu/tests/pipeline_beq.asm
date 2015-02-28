TARGET: addi $1 $0 2
addi $2 $0 4
beq  $2 $4 TARGET
sub $1 $2 $3
halt