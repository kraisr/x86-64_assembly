# Few important notes / questions:
# 	1. Since we have so many system calls to malloc, strdup etc. (not sure if this is good idea?)
# 	that take %rdi as their first argument, maybe use stack (slide 212 + 213 for reference) to
#	preserve the variables, instead of the %rdi, %rsi, etc. because we would
#	have to shift them back and forth before and afer each sys call (very annoying)
#		- Remember to "allocate" enough space on the stack for all the variables
#		by shifting stack pointer down
#		- We still need reference to the origin of stack but we save it in %rbp,
#		so use %rbp as reference to the origin
#		- Remember to use multiples of 8 to preserve alignment
#		- When allocating make sure to account for the alignment, so for example 24 / 8 = 3 vars	
.text
mallocStr: 
	.string "malloc"

#long HashTable_ASM_hash(void * table, char * word); 
.globl HashTable_ASM_hash
HashTable_ASM_hash:
	pushq 	%rbp							# Save frame pointer
	movq 	%rsp, %rbp

	# Add your implementation here
	subq 	$60, %rsp						# "allocate" space on stack by shifting stack pointer down
	movq 	%rdi, -8(%rbp) 					# save *table argument
	movq 	%rsi, -16(%rbp) 				# save *word argument
	movq 	%rdi, -24(%rbp) 				# *hashTable = table
	movq 	$1, -32(%rbp) 					# hashNum = 1

	movq 	-16(%rbp), %rdi
	call 	strlen@PLT 						# strlen(word)
	movq 	%rax, -40(%rbp) 				# len = strlen(word)
	movq 	$0, -48(%rbp) 					# i = 0

HashTable_ASM_hash_loop:
	movq 	-48(%rbp), %rax 				# rax = i
	cmpq 	-40(%rbp), %rax 				# compare i with len
	jge 	HashTable_ASM_hash_loop_done	# if (i >= len)
	# here i < len
	movq 	-32(%rbp), %rcx 				# rcx = hashNum
	imulq 	$32, %rcx 						# rcx = hashNum * 32
	subq 	-32(%rbp), %rcx 				# rcx = hashNum * 31
	addq 	-16(%rbp), %rax 				# rax = &word[i]
	movzbq 	(%rax), %rax 					# rax = word[i]
	addq 	%rcx, %rax 						# rax = hashNum * 31 + word[i]
	movq 	%rax, -32(%rbp) 				# hashNum = hashNum * 31 + word[i]
	addq 	$1, -48(%rbp) 						# i++
	jmp 	HashTable_ASM_hash_loop

HashTable_ASM_hash_loop_done:
	movq 	-32(%rbp), %rax 				# rax = hashNum
	testq 	%rax, %rax
	jge 	HashTable_ASM_hash_end_if
	# here hashNum < 0
	negq 	-32(%rbp) 						# hashNum = -hashNum

HashTable_ASM_hash_end_if:
	movq 	-24(%rbp), %rax 				# %rax = hashTable
	movq 	48(%rax), %rcx 					# %rcx = hashTable->nBuckets
	movq 	-32(%rbp), %rax 				# rax = hashNum
	movq 	$0, %rdx 						# rdx = 0
	divq 	%rcx
	movq 	%rdx, %rax 						# rax = hashNum % hashTable->nBuckets
	leave
	ret

#long HashTable_ASM_lookup(void * table, char * word, long * value);
.globl HashTable_ASM_lookup
HashTable_ASM_lookup:
	pushq 	%rbp							# Save frame pointer
	movq 	%rsp, %rbp

	# Add your implementation here
	subq 	$60, %rsp						# "allocate" memory on the stack for variables (shift stack pointer down)
	movq 	%rdi, -8(%rbp) 					# save table in -8 stack
	movq 	%rsi, -16(%rbp) 				# save word
	movq 	%rdx, -24(%rbp) 				# save value
	
	movq 	%rdi,-32(%rbp) 					# *hashTable = table

	movq 	-32(%rbp), %rdi
	movq 	-16(%rbp), %rsi
	call 	HashTable_ASM_hash
	movq 	%rax, -40(%rbp) 				# hashNum = HashTable_ASM_hash(hashTable,word);

	movq 	-32(%rbp), %rcx 				# rcx = hashTable
	movq 	56(%rcx), %rcx 					# rcx = hashTable->array
	
	# [NOTE] This part probably can be improved in opt
	movq 	-40(%rbp), %rax 				# [NOTE] remove this for opt version
	movq 	%rax, %rdx 						# rdx = hashNum
	addq 	%rdx, %rdx 						# rdx = 2 * hashNum
	addq 	%rdx, %rax 						# rax = 3 * hashNum
	imulq 	$8, %rax 						# rax = 8 * 3 * hashNum
	addq 	%rcx, %rax 						# rax = hashTable->array[hashNum]
	movq 	16(%rax), %rax 					# rax = hashTable->array[hashNum].next
	movq 	%rax, -48(%rbp) 				# elem = hashTable->array[hashNum].next

HashTable_ASM_lookup_while:
	movq 	-48(%rbp), %rdi
	cmpq 	$0, %rdi
	je 		HashTable_ASM_lookup_while_done

	movq 	(%rdi), %rdi 					# %rdi = elem->word
	movq 	-16(%rbp), %rsi
	call 	strcmp@PLT
	cmpq 	$0, %rax
	je 		HashTable_ASM_lookup_while_done
											# here elem != NULL && strcmp(elem->word,word) != 0
	movq 	-48(%rbp), %rax 				# rax = elem
	movq 	16(%rax), %rax 					# rax = elem->next
	movq 	%rax, -48(%rbp) 				# elem = elem->next
	jmp 	HashTable_ASM_lookup_while

HashTable_ASM_lookup_while_done:
	movq 	-48(%rbp), %rax 				# %rax = elem
	cmpq 	$0, %rax
	jne 	HashTable_ASM_lookup_if_done
											# not found
	movq	$0, %rax						# return false
	jmp 	HashTable_ASM_lookup_done

HashTable_ASM_lookup_if_done:
	movq 	8(%rax), %rdx 					# rdx= elem->value
	movq 	-24(%rbp), %rax 				# rax = *value
	movq 	%rdx, (%rax) 					# *value = elem->value
	movq 	$1, %rax 						# return true

HashTable_ASM_lookup_done:
	leave
	ret


#long HashTable_ASM_update(void * table, char * word, long value); 
.globl HashTable_ASM_update
HashTable_ASM_update:
	pushq 	%rbp							# Save frame pointer
	movq 	%rsp, %rbp

	# Add your implementation here
	subq	$80, %rsp						# "allocate" mem on stack (shift stack ptr down)
	movq	%rdi, -8(%rbp)					# save table
	movq	%rsi, -16(%rbp)					# save word
	movq	%rdx, -24(%rbp)					# save value

	movq	%rdi, -32(%rbp)					# *hashTable = table

	movq	-32(%rbp), %rdi
	movq	-16(%rbp), %rsi
	call	HashTable_ASM_hash				# hash the hashTable (return value will be in %rax)

	movq	%rax, -40(%rbp)					# hashNum = HashTable_ASM_hash(hashTable,word);

	movq	-32(%rbp), %rcx					# %rcx = hashTable
	movq	56(%rcx), %rcx					# %rcx = hashTable->array

	# [NOTE] this can be improved in opt

	movq	-40(%rbp), %rax					# maybe this can be removed in opt?

	movq	%rax, %rdx						# %rdx = hashNum
	addq	%rdx, %rdx						# %rdx = hashNum + hashNum = 2 * hashNum
	addq	%rdx, %rax						# %rax = 2 * hashNum + hashNum = 3 * hashNum
	imulq	$8, %rax						# %rax = 8 * 3 * hashNum
	addq	%rcx, %rax						# %rax = hashTable->array[hashNum]
	movq 	%rax, -48(%rbp)					# elem = hashTable->array[hashNum]

HashTable_ASM_update_while:
	movq	-48(%rbp), %rdi					# %rdi = elem
	movq	16(%rdi), %rdi					# %rdi = elem->next
	cmpq	$0, %rdi						# if (elem->next == 0)
	je		HashTable_ASM_update_while_done	#

	movq	(%rdi), %rdi					# %rdi = elem->next->word
	movq	-16(%rbp), %rsi
	call	strcmp@PLT						# use strcmp (return val in %eax not %rax!!!)
	
	# strcmp(elem->next->word,word) != 0
	cmpq	$0, %rax						
	je		HashTable_ASM_update_while_done	# done

	# here elem->next != NULL && strcmp(elem->next->word,word) != 0
	movq	-48(%rbp), %rax					# %rax = elem
	movq	16(%rax), %rax					# %rax = elem->next
	movq	%rax, -48(%rbp)					# elem = elem->next
	jmp		HashTable_ASM_update_while

HashTable_ASM_update_while_done:
	movq 	-48(%rbp), %rax					# %rax = elem
	movq	16(%rax), %rax					# %rax = elem->next
	cmpq	$0, %rax						# if (elem->next == 0)
	je		HashTable_ASM_update_if_zero	# not found

	# else found
	movq	-24(%rbp), %rcx					# %rcx = value
	movq	%rcx, 8(%rax)					# elem->next->value = value
	movq	$1, %rax						# return true
	jmp		HashTable_ASM_update_done		# pop frame ptr and return to caller

HashTable_ASM_update_if_zero:
	# Handle not found
	movq	$24, %rdi						# 24 = 8 * 3
	call	malloc@PLT
	movq	%rax, -56(%rbp)					# e = (struct HashTableElement *) malloc(sizeof(struct HashTableElement));

	cmpq	$0, %rax
	jne		HashTable_ASM_update_if

	leaq	mallocStr(%rip), %rdi
	call	perror@PLT						# call perror("malloc")
	movq	$1, %rdi
	call	exit@PLT						# call exit(1)

HashTable_ASM_update_if:
	movq	-48(%rbp), %rax					# %rax = elem
	movq	-56(%rbp), %rcx					# %rcx = e
	movq	%rcx, 16(%rax)					# elem->next = e
	movq	-16(%rbp), %rdi					# %rdi = word
	call	strdup@PLT						# %rax = strdup(word)

	movq	-56(%rbp), %rdi					# %rdi = e
	movq	%rax, (%rdi)					# e->word = strdup(word)
	movq	-24(%rbp), %rax
	movq	%rax, 8(%rdi)					# e->value = value
	movq	$0, 16(%rdi)					# e->next = NULL
	movq	$0, %rax						# return false

HashTable_ASM_update_done:
	leave
	ret
