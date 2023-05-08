.eqv PATH_SIZE, 100

.global identify_mode

# Identify decryption / encryption based on the file extension
# Arguments:
#	- a0: path address
# Result:
#	- a1: 0 (encrypt), 1 (decrypt)
				
identify_mode:	
	addi t0, a0, PATH_SIZE	
	addi t0, t0, -1		# set t0 to the end of the path
	li t1, '.'
	
loop:
	lbu t2, (t0)		# t2 = *(t0)
	beq t1, t2, check_ext	# if *(t0) == '.' jump to check_ext
	addi t0, t0, -1		# decrement t0
	beq  t0, a0, encrypt	# if no extension is found -> encrypt
	j loop

check_ext:
	la t1, c_ext		# t1 - extension iterator
ext_loop:
	lbu t2, (t1)		# t2 = *(t1)
	lbu t3, (t0)		# t3 = *(t0)
	beqz t2, decrypt	# reached end of text, extension is correct
	addi t1, t1, 1		# increment t1
	addi t0, t0, 1		# increment t0
	beq t2, t3, ext_loop	# if extensions match continue, else encrypt
	j encrypt
encrypt:
	li a1, 0		# return encrypt mode
	ret
decrypt:
	li a1, 1		# return decrypt mode
	ret 
