	.global strip_string

# Removes new line symbol from the user input
# Arguments:
#	- a0: string address

strip_string:
	mv t0, a0	# string iterator
	li t2, '\n'	
loop:
	lbu t1, (t0)
	beq t1, t2, remove
	beqz t1, end
	addi t0, t0, 1
	j loop
remove:
	sb zero, (t0)
end:
	ret
