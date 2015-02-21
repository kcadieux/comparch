addi  $1 $0 7
addi  $2 $0 9
mult  $1 $2
mflo  $3
asrti $3 63
lui   $1 1
mult  $1 $1
mfhi  $3
asrti $3 1
halt
