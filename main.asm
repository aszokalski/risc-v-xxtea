	.global main
	
	# PARAMETERS
	.eqv FILE_SIZE, 100
	.eqv PATH_SIZE, 100
	.eqv KEY_SIZE, 128
	
	# SYSCALLS
	.eqv PRINT_STR, 4
	.eqv READ_STR, 8
	.eqv SYS_EXIT, 10
	.eqv READ_FILE, 63
	.eqv WRITE_FILE, 64
	.eqv OPEN_FILE, 1024
	.eqv CLOSE_FILE, 57

	.data
prompt: .string "Please enter the plaintext file path: "
result: .string "File successfully encrypted as: "
error:	.string "Error: "
buf:	.space	FILE_SIZE
f_path:	.space	PATH_SIZE
key:	.space	KEY_SIZE
c_ext:	.string ".xxtea"

	.text
main:
	li a7, PRINT_STR	
	la a0, prompt		
	ecall 			# Print prompt
	
	li a7, READ_STR		
	la a0, f_path
	li a1, PATH_SIZE
	ecall			# Read filepath to f_path
	
	call identify_mode
	
	beqz a1, encryption

decryption:
	# TODO
	j end

encryption:
	# TODO
	j end

end:
	li a7, SYS_EXIT		# return 0
	ecall
	


identify_mode:			# Identify decryption / encryption based on the file extension
				# Arguments:
				#	- a0: path address
				# Result:
				#	- a1: 0 (encrypt), 1 (decrypt)

	addi t0, a0, PATH_SIZE	
	addi t0, t0, -1		# Set t0 to the end of the path
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
	li a1, 0
	ret
decrypt:
	li a1, 1
	ret 