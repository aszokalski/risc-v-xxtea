	.global get_size

# Get null terminated buffer string
# Arguments:
#	- a0: buffer address
# Result:
#	- a1: size

get_size:
	mv t0, a0	# string iterator	
	li a1, 0
loop:
	lbu t1, (t0)
	beqz t1, end
	addi t0, t0, 1
	addi a1, a1, 1
	j loop
end:
	ret
