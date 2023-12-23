.text
.globl fibonacci
fibonacci:
  pushq %rbp              # Save frame pointer
  movq  %rsp, %rbp
  subq  $256, %rsp        # allocate space on stack

	pushq %rbx              # Save register

  movq  %rdi, -8(%rbp)    # Save n on the stack

  movq  %rdi, %rax        # return val = n
  # if (n == 0) return n
  cmpq  $0, %rdi
  je    return_n
  # if (n == 1) return n
  cmpq  $1, %rdi
  je    return_n
  
  # else return fib(n - 1) + fib (n - 2)
  movq  -8(%rbp), %rdi  # %rdi = n
  subq  $1, %rdi        # n - 1
  call  fibonacci       # fib(n - 1)
  movq  %rax, %rbx      # %rbx = fib(n - 1)

  movq  -8(%rbp), %rdi  # %rdi = n
  subq  $2, %rdi        # n - 2
  call  fibonacci       # fib(n - 2)
  
  addq  %rbx, %rax      # %rax = fib(n - 1) + fib(n - 2)

return_n:
  # Restore registers
	popq %rbx
  leave
  ret
