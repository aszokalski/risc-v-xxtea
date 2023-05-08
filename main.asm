	.global main
	.global c_ext
	
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
f_err:	.string "File not found"
buf:	.space	FILE_SIZE
f_path:	.space	PATH_SIZE
key:	.space	KEY_SIZE
c_ext:	.string ".xxtea"

res_n:	.string "res.txt"
res_n_e:.string "res.txt.xxtea"

	.text
main:
	li a7, PRINT_STR	
	la a0, prompt		
	ecall 			# print prompt
	
	li a7, READ_STR		
	la a0, f_path
	li a1, PATH_SIZE
	ecall			# read filepath to f_path
	
	la a0, f_path
	call strip_string	# strip the new line from path
	
	li a7, OPEN_FILE	
	la a0, f_path	
	li a1, 0		# read only mode (0)
	ecall 			# open file from f_path 
	
	bltz a0, file_not_found	# handle errors
	
	mv s6, a0 		# save the file descriptor
	
	li a7, READ_FILE
	mv a0, s6
	la a1, buf
	li a2, FILE_SIZE
	ecall			# read file
	
	li a7, CLOSE_FILE
	mv a0, s6
	ecall			# close file
	
	la a0, f_path
	call identify_mode	# identify mode
	
	beqz a1, encryption

decryption:
	# TODO
	
	li a7, OPEN_FILE	
	la a0, res_n
	li a1, 1		# write only mode (1)
	ecall 			# create new file
	
	j end

encryption:
	# TODO
	
	li a7, OPEN_FILE	
	la a0, res_n_e
	li a1, 1		# write only mode (1)
	ecall 			# create new file
	
	j end
	
file_not_found:
	li a7, PRINT_STR	
	la a0, error		
	ecall 			# print error prompt
	
	li a7, PRINT_STR	
	la a0, f_err		
	ecall 			# print file not found error
	
	j end
	
end:
	li a7, SYS_EXIT		# return 0
	ecall