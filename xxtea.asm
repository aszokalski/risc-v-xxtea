	.global xxtea_encrypt
	.global xxtea_decrypt
	.eqv DELTA, 0x9e3779b9


# Calculates MX (doesn't use t0)
.macro calculate_mx(%z_reg, %y_reg, %sum_reg, %key_reg, %p_reg, %e_reg, %result_reg)
  	srli t1, %z_reg, 5       # t1 = z >> 5
  	slli t2, %y_reg, 2       # t2 = y << 2
  	xor t3, t1, t2		 # t3 = (z>>5)^(y<<2)
  	srli t1, %y_reg, 3       # t1 = y >> 3
  	slli t2, %z_reg, 4       # t2 = z << 4
  	xor t4, t1, t2           # t4 = (y>>3)^(z<<4)
  	add t1, t3, t4           # t1 = (z>>5^y<<2) + (y>>3^z<<4)
  
  	xor t2, %sum_reg, %y_reg # t2 = sum^y
  	andi t3, %p_reg, 3	 # t3 = p&3
  	xor t3, t3, %e_reg       # t3 = (p&3)^e

  	slli t3, t3, 2		 # t3 *= 4
  	add t3, t3, %key_reg	 # t3 = &key + (p&3)^e
  	lw t3, (t3)		 # t3 = key[(p&3)^e]
  
  	xor t3, t3, %z_reg	 # t3 = key[(p&3)^e] ^ z
  	add t2, t2, t3		 # t2 = (sum^y) +  (key[(p&3)^e] ^ z)
  
  	xor %result_reg, t1, t2  # return ((z>>5^y<<2) + (y>>3^z<<4)) ^ ((sum^y) + key[(p&3)^e])
.end_macro 


# Encrypts the block using XXTEA 
# Arguments:
# 	a0: block address	(v)
# 	a1: block size in bytes (n)
# 	a2: 16-byte key address (key)
# Result: input block will be encrypted
xxtea_encrypt:
	li t0, 52
	div s0, t0, a1		
	addi s0, s0, 6		# rounds (s0) = 52/n + 6	
	li s1, 0		# sum (s1) = 0
	
	mv t3, a0		# t3 = &v
	addi t1, a1, -1		# t1 = n - 1
	slli t1, t1, 2		# t1 *= 4
	add t3, t3, t1		# t3 = &v + 4(n-1)
	lw s2, (t3)		# z (s2) = v[n-1];
	
round:
	li t0, DELTA		# t0 = DELTA
	add s1, s1, t0		# sum += DELTA
	
	srli t1, s1, 2		# t1 = sum >> 2
	andi s4, t1, 3 		# e (s4) = t1 & 3
	
	li t0, 0		# p (t0) = 0
	addi s7, a1, -1		# s7 = n - 1
	
for_loop:
	bge  t0, s7, end_for_loop	
	
	mv t3, a0		# t3 = &v (iterator)
	addi t4, t0 , 1		# t4 = p + 1	
	slli t4, t4, 2		# t4 *= 4
	add t3, t3, t4		# t3 = &v + 4(p+1)
	lw s3, (t3)		# y (s3) = v[p+1]
	
	addi s5, t3, -4		# s5 = --t3 = &v + 4(p)
	
	calculate_mx(s2, s3, s1, a2, t0, s4, t5) # t5 = MX
	
	lw s2, (s5)		# z = v[p]
	add s2, s2, t5		# z += MX
	sw s2, (s5)		# v[p] = z

	addi t0, t0, 1		# ++p
	j for_loop
	
end_for_loop:
	lw s3, (a0)		# y = v[0]
	
	calculate_mx(s2, s3, s1, a2, t0, s4, t5) # t5 = MX
	
	mv t3, a0		# t3 = &v
	addi t1, a1, -1		# t1 = n - 1
	slli t1, t1, 2		# t1 *= 4
	add t3, t3, t1		# t3 = &v + 4(n-1)
		
	lw s2, (t3)		# z (s2) = v[n-1];
	add s2, s2, t5		# z += MX
	sw s2, (t3)		# v[n-1] = z
	
	addi s0, s0, -1		# --rounds
	bnez s0, round		# round loop condition
end:
	ret



# Decrypts the block using XXTEA 
# Arguments:
# 	a0: block address	(v)
# 	a1: block size in bytes (n)
# 	a2: 16-byte key address (key)
# Result: input block will be decrypted
xxtea_decrypt:
	li t0, 52
	div s0, t0, a1		
	addi s0, s0, 6		# rounds (s0) = 52/n + 6
	li s1, DELTA
	mul s1, s1, s0		# sum (s1) = rounds * DELTA
	lw s3, (a0)		# y (s3) = v[0]
	
d_round:
	srli t1, s1, 2		# t1 = sum >> 2
	andi s4, t1, 3 		# e (s4) = t1 & 3
	
	addi t0, a1, -1		# p (t0) = n - 1
	
	
d_for_loop:
	beqz  t0, d_end_for_loop	
	mv t3, a0		# t3 = &v (iterator)
	addi t4, t0 , -1	# t4 = p - 1	
	slli t4, t4, 2		# t4 *= 4
	add t3, t3, t4		# t3 = &v + 4(p-1)
	lw s2, (t3)		# z (s2) = v[p-1]
	
	addi s5, t3, 4		# s5 = ++t3 = &v + 4(p)
	
	calculate_mx(s2, s3, s1, a2, t0, s4, t5) # t5 = MX
	
	lw s3, (s5)		# y = v[p]
	sub s3, s3, t5		# z -= MX
	sw s3, (s5)		# v[p] = z

	addi t0, t0, -1		# --p
	j d_for_loop
	
d_end_for_loop:
	mv t3, a0		# t3 = &v
	addi t1, a1, -1		# t1 = n - 1
	slli t1, t1, 2		# t1 *= 4
	add t3, t3, t1		# t3 = &v + 4(n-1)
	
	lw s2, (t3)		# z (s2) = v[n-1]
	
	calculate_mx(s2, s3, s1, a2, t0, s4, t5) # t5 = MX
	
	lw s3, (a0)		# y = v[0]
	sub s3, s3, t5		# y -= MX
	sw s3, (a0)		# v[0] = y
	
	li t0, DELTA
	sub s1, s1, t0		# sum -= DELTA
	
	addi s0, s0, -1		# --rounds
	bnez s0, d_round	# round loop condition
d_end:
	ret
