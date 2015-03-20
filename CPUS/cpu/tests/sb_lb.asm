addi  $1 $0 100
addi  $2 $0 -1    #FFFFFFFF
addi  $3 $0 -256  #FFFFFF00
asrti $1 100
asrti $2 -1
asrti $3 -256
sb    $2 0($1)
sb    $3 1($1)
addi  $4 $0 0
addi  $5 $0 -1
lb    $4 0($1)
lb    $5 1($1)
asrti $4 -1
asrti $5 0
halt  