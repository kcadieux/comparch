#compute the sum of the numbers of 1 to 10
sub $0,$0,$0     # set reg[0] to 0, use as base  
lw  $1,0($0)     # reg[1] <- mem[0] (= 1)  
lw  $2,4($0)     # reg[2] <- mem[4] (= A)  
lw  $3,8($0)     # reg[3] <- mem[8] (= B) 
sub $4,$4,$4     #reg[4] <- 0, running total  
add $4,$2,$4     #reg[4]+ = A  
slt $5,$2,$3     # reg[5] <- A < B  
beq $5,$0,2      # if reg[5] = FALSE, go forward 2 instructions  
add $2,$1,$2     # A++  
beq $0,$0,-5     # go back 5 instructions  
sw  $4,0($0)     #mem[0] <- reg[4]  
beq $0,$0,-1     #program is over, keep looping back to here 

astri 0($0) 55
halt