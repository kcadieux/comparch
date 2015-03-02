TARGET: addi $1 $0 2
addi $2 $0 2
beq  $1 $2 TARGET
sub $1 $2 $3
halt