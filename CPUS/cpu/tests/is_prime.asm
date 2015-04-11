addi $s0, $0, 673       # Checks if 673 is prime (Hint: it is)
        add    $t2,$s0,$0         #make a temp copy of the variable to avoid changing it
        add    $s1,$s0,$0        #this is the ceiling (n)
        addi    $t0,$0,2     #this is the index for which to divide by
begin_loop:
        slt     $t1,$t0,$s1
        beq     $t1,$zero,prime
        div     $t2,$t0
        mfhi    $t3
        beq     $t3,$zero,done
        addi    $t0,$t0,1
        j       begin_loop
prime:
	asrti $0, 0
	halt
done:
	asrti $0, 1
	halt