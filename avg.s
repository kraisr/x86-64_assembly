.data
  .comm n, 8
  .comm val, 8

.text
str1:
  .string "Type n: "
str2:
  .string "%ld"
str4:
  .string "The average is=%ld\n"

.globl main
main:
  pushq %rbp                # save frame pointer
  movq  %rsp, %rbp

  pushq %rbx
  pushq %r13

  movq  $0, %rbx            # sum = 0
  movq  $0, %r13            # i = 0

  movq  $str1, %rdi         # %rdi (arg 1) = "Type n: "
  movq  $0, %rax            # %rax = 0
  call  printf              # printf("Type n: ")

  movq  $str2, %rdi         # %rdi (arg 1) = "%ld"
  movq  $n, %rsi            # %rsi (arg 2) = &n
  movq  $0, %rax            # %rax = 0
  call  scanf               # scanf("%ld", &n)

while:
  cmpq  %r13, n             # while (i < n)
  je   end

  movq  $str2, %rdi         # %rdi (arg 1) = "%ld"
  movq  $val, %rsi          # %rsi (arg 2) = &val
  movq  $0, %rax            # %rax = 0
  call  scanf               # scanf("%ld", &n)

  addq  val, %rbx           # sum += val
  addq  $1, %r13            # i++
  jmp   while

end:
  movq  %rbx, %rax          # %rax = sum
  idivq n                   # %rax / n = sum / n
  movq  $str4, %rdi         # %rdi = "The average is=%ld\n"
  movq  %rax, %rsi          # %rsi = sum / n
  movq  $0, %rax
  call  printf              # printf("The average is=%ld\n", sum / n)

  popq  %r13
  popq  %rbx
  leave                     # restore frame ptr
  ret
