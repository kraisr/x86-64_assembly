# Notes:
#	1. Maybe bit shifting (shlq) instead of imulq? (Is it faster?)
#	2. Reduce the mem accessess 
# 3. Use power of 2 for size of hashtable, and instead of idivq use bitmasking
# 4. Dont use stack (slow)
# 5. Instead of strcmp, use maybe repe cmpsb (compares byte by byte until first diff)
#		 Since we only care about whether strings are equal or not
# 6. 


# changes:
#		HashTable_ASM_OPT_hash:
#				1. use registers instead of stack
#				2. inline strlen function
#				3. reduce memory accesses by using logical operators
#		HashTable_ASM_OPT_lookup:
#				1. inline call to HashTable_ASM_OPT_hash
#				2. inline call to strcmp
.text
mallocStr: 
	.string "malloc"


#long HashTable_ASM_OPT_hash(void * table, char * word); 
.globl HashTable_ASM_OPT_hash
HashTable_ASM_OPT_hash:
	# pushq %rbp
	# movq 	%rsp, %rbp

	# Add your implementation here
	# opt 1: Dont use stack
	# opt 2: Dont use strlen, inline it.

	xorq	%rax, %rax							# %rax = 0

HashTable_ASM_hash_loop:
	movb 	(%rsi), %cl
	testb	%cl, %cl
	jz 		HashTable_ASM_hash_loop_done	# if (chr == 0)

	# here chr != 0
	movq	%rax, %r9
	shlq 	$5, %r9									# %r9 = 32 * hashNum
	subq	%rax, %r9								# %r9 = 31 * hashNum

	addq	%rcx, %r9								# 
	movq	%r9, %rax								# %rax = word

	incq	%rsi										# move the ptr to next val
	jmp		HashTable_ASM_hash_loop

HashTable_ASM_hash_loop_done:
	testq %rax, %rax
	jge 	HashTable_ASM_hash_end_if
	# here hashNum < 0
	negq 	%rax				 						# hashNum = -hashNum

HashTable_ASM_hash_end_if:
	# [NOTE] Seems kinda slow probably because of collisions (find a way to reduce them)
	andq 		$0xfffff, %rax 						# rax = hashNum = hashNum % hashTable->nBuckets
	# leaq 	(%rax, %rax, 2), %rax   	# Multiply by 3: rax = rax + rax*2
	# movq 	%rax, %rcx
	# shlq 	$20, %rcx               	# Shift by 20 bits to the left
	# addq 	%rcx, %rax
	# movq 	%rax, %rcx
	# shlq 	$19, %rcx               	# Shift by 19 bits to the left
	# addq 	%rcx, %rax
	
	# leave
	ret

#long HashTable_ASM_OPT_lookup(void * table, char * word, long * value);
.globl HashTable_ASM_OPT_lookup
HashTable_ASM_OPT_lookup:
	# pushq %rbp
	# movq %rsp, %rbp

	# Add your implementation here
	movq	%rdi, %r12							# *hashTable = table
	movq	%rsi, %r8								# save word
	movq	%rdx, %r11							# save value

# hashNum = HashTable_C_hash(hashTable, word)
	xorq	%rax, %rax							# %rax = 0

inline_hash_loop:
	movb 	(%rsi), %cl
	testb	%cl, %cl
	jz 		inline_hash_loop_done	# if (chr == 0)

	# here chr != 0
	movq	%rax, %r9
	shlq 	$5, %r9									# %r9 = 32 * hashNum
	subq	%rax, %r9								# %r9 = 31 * hashNum

	addq	%rcx, %r9								# 
	movq	%r9, %rax								# %rax = word

	incq	%rsi										# move the ptr to next val
	jmp		inline_hash_loop

inline_hash_loop_done:
	testq %rax, %rax
	jge 	inline_hash_end_if
	# here hashNum < 0
	negq 	%rax				 						# hashNum = -hashNum

inline_hash_end_if:
	andq 		$0xfffff, %rax 						# rax = hashNum = hashNum % hashTable->nBuckets

	movq	%r12, %rcx 							# %rcx = hashTable
	movq	56(%rcx), %rcx					# %rcx = hashTable->array
	
	# [NOTE] improve this :)
	movq	%rax, %rdx							# %rdx = hashNum
	shlq	$4, %rax								# %rax = 16 * hashNum
	shlq	$3, %rdx								# %rdx = 8 * hashNum
	addq	%rdx, %rax							# %rax = 16 * hashNum + 8 * hashNum = 24 * hashNum

	addq	%rcx, %rax							# rax = hashTable->array[hashNum]
	movq	16(%rax), %r14					# %rax = hashTable->array[hashNum].next

HashTable_ASM_lookup_while:
	# movq 	%r14, %rdi
	testq %r14, %r14							# check if elem == NULL
	je 		HashTable_ASM_lookup_notfound

	# here elem != null
	movq 	(%r14), %rdi 						# %rdi = elem->word
	movq 	%r8, %rsi


inline_strcmp:
	movzbq	(%rdi), %r13					# %r13 = byte from str1
	movzbq	(%rsi), %r15

	cmpb		%r13b, %r15b
	jne			increment_iter				# if bytes not equal, go to next element			

	testb		%r13b, %r15b						# if we reach end of str (\0) == strs equal
	je			HashTable_ASM_lookup_while_found

	inc			%rdi
	inc			%rsi
	jmp			inline_strcmp

increment_iter:
	# here not equal [elem != NULL && strcmp(elem->word,word) != 0]
	movq 	16(%r14), %r14 					# %rax = elem->next
	jmp 	HashTable_ASM_lookup_while

HashTable_ASM_lookup_while_found:
	movq 	8(%r14), %rax 					# %rax= elem->value
	movq 	%rax, (%r11) 							# *value = elem->value
	movl 	$1, %eax 								# return true (1)
	# leave
	ret

HashTable_ASM_lookup_notfound:
	# not found
	xorl 	%eax, %eax 							# return false (0)
	# leave
	ret

#long HashTable_ASM_OPT_update(void * table, char * word, long value); 
.globl HashTable_ASM_OPT_update
HashTable_ASM_OPT_update:
	pushq %rbp
	movq %rsp, %rbp

	# Add your implementation here
	movq	%rdi, %r12							# *hashTable = table
	movq	%rsi, %r10								# save word
	movq	%rdx, %r14							# save value

	# hashNum = HashTable_C_hash(hashTable, word)
	xorq	%rax, %rax							# %rax = 0
	
inline_hash_loop2:
	movb 	(%rsi), %cl
	testb	%cl, %cl
	jz 		inline_hash_loop_done2	# if (chr == 0)

	# here chr != 0
	movq	%rax, %r9
	shlq 	$5, %r9									# %r9 = 32 * hashNum
	subq	%rax, %r9								# %r9 = 31 * hashNum

	addq	%rcx, %r9								# 
	movq	%r9, %rax								# %rax = word

	incq	%rsi										# move the ptr to next val
	jmp		inline_hash_loop2

inline_hash_loop_done2:
	testq %rax, %rax
	jge 	inline_hash_end_if2
	# here hashNum < 0
	negq 	%rax				 						# hashNum = -hashNum

inline_hash_end_if2:
	andq 	$0xfffff, %rax 						# rax = hashNum = hashNum % hashTable->nBuckets
	
	movq 	56(%r12), %r12 					# %rcx = hashTable->array
	
	movq 	%rax, %rdx 							# %rdx = hashNum
	shlq 	$4, %rax 								# %rax = 16 * hashNum
	shlq 	$3, %rdx 								# %rdx = 8 * hashNum
	addq	%rdx, %rax							# %rax = 16 * hashNum + 8 * hashNum = 24 * hashNum

	addq	%rax, %r12							# rax = hashTable->array[hashNum]

HashTable_ASM_update_while:
	movq 	16(%r12), %r15 					# %rdi = elem->next
	testq %r15, %r15							# if elem == null -> jump
	je		HashTable_ASM_update_notfound

	movq 	(%r15), %rdi 						# %rdi = elem->next->word
	movq 	%r10, %rsi

inline_strcmp2:
	movzbq	(%rdi), %r13					# %r13 = byte from str1
	movzbq	(%rsi), %r8

	cmpb		%r13b, %r8b
	jne			increment_iter2				# if bytes not equal, go to next element			

	testb		%r13b, %r8b						# if we reach end of str (\0) == strs equal
	je			HashTable_ASM_update_while_found

	inc			%rdi
	inc			%rsi
	jmp			inline_strcmp2

increment_iter2:
	# here elem->next != NULL && strcmp(elem->next->word,word) != 0
	movq	%r15, %r12
	jmp		HashTable_ASM_update_while

HashTable_ASM_update_while_found:
	# found
	movq	%r14, 8(%r15)
	movl 	$1, %eax 									# return true
	
	leave
	ret


HashTable_ASM_update_notfound:
	# Handle not found
	movq    $24, %rdi                             # 24 = 8 * 3
	call    malloc@PLT

	testq   %rax, %rax
	je      HashTable_ASM_update_error

	movq    %rax, 16(%r12)                        # e = (struct HashTableElement *) malloc(sizeof(struct HashTableElement)); 
	movq    %rax, %r12
	movq    %r14, 8(%r12)
	movq    $0, 16(%r12)

	# Begin inlining of strdup
	movq    $32, %rdi                          # Set %rdi for malloc
	call    malloc@PLT

	# Copy the string from %r10 to %rax using strcpy-like loop
	movq    %r10, %rsi                          # Source string pointer
	movq    %rax, %rdx                          # Destination string pointer
	xorq    %rcx, %rcx                          # Reset counter %rcx to count the length of string copied

strdup_strcpy_loop:
	movb    (%rsi), %bl                         # Load byte from source
	movb    %bl, (%rdx)                         # Store byte to destination
	incq    %rcx                                # Increase counter for length copied
	testb   %bl, %bl                            # Test if byte is null terminator
	je      strdup_strcpy_done
	incq    %rsi                                # Move to next character in source
	incq    %rdx                                # Move to next character in destination
	jmp     strdup_strcpy_loop

strdup_strcpy_done:
	# Check if length %rcx is aligned to 8 bytes
	movq    %rcx, %r8                           # Copy %rcx to %r8 for manipulation
	andq    $7, %r8                             # %r8 will hold remainder when divided by 8
	jz      string_already_aligned              # If remainder is zero, string is already aligned
	subq    $8, %r8                             # Calculate how many zeros to pad
	negq    %r8                                 # Convert to positive

pad_zeros_loop:
	movb    $0, (%rdx)                          # Store zero to destination
	incq    %rdx                                # Move to next character in destination
	decq    %r8                                 # Decrease counter for zeros to be padded
	jnz     pad_zeros_loop                      # If more zeros are needed, continue loop

string_already_aligned:
	# End of inlining strdup
	movq    %rax, (%r12)                        # Store the address of the new string
	xorq    %rax, %rax

	leave
	ret



HashTable_ASM_update_error:
	leaq	mallocStr(%rip), %rdi
	call	perror@PLT							# call perror("malloc")
	movq	$1, %rdi
	call	exit@PLT								# call exit(1)
	
