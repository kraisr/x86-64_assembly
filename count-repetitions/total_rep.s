  .text
.globl total_repetitions      # int total_repetitions(long n, long array, long value)
total_repetitions:
  pushq %rbp                  # save frame pointer
  movq  %rsp, %rbp

  # push registers onto stack (restore at the end)
  pushq %rbx
  pushq %r10
  pushq %r13
  pushq %r14

  movq  %rsi, %rbx            # %rsi => long *p = array
  movq  $0, %r10              # %r10 => long counter = 0
  movq  $0, %r13              # %r13 => long i = 0

while:
  cmpq  %r13, %rdi            # while (i < n)
  jle   end
  movq  (%rbx), %r14          # %r14 = *array

  cmpq  %r14, %rdx            # if (*array == value)
  jne   after                 # counter++;
  addq  $1, %r10              # else

after:
  addq  $8, %rbx              # array + sizeof(long) || p++
  addq  $1, %r13              # i++
  jmp   while

end:
  movq  %r10, %rax            # return value = counter
  # restore registers from stack
  popq  %r14
  popq  %r13
  popq  %r10
  popq  %rbx
  # restore framer pointer
  leave
  ret
  