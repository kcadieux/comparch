addi  $1 $0 100
addi  $2 $0 666
sw	  $2 0($1)
lw    $3 0($1)
asrti $3 666
halt
