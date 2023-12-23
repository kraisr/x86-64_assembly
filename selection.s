.globl selectionsort
selectionsort:                  # void selectionsort(long ascending, long n, long * a);
                                #    // asc = %rdi      n = %rsi
                                #    // a = %rdx        i = %r8
                                #    // j = %r9         idx = %r10
                                #
        pushq   %rbp            # Save frame pointer
        movq    %rsp, %rbp      #
                                #
        movq    $0, %r8         # i = 0
        movq    %rsi, %r12
        decq    %r12            # n--

outer_loop:
        cmpq    %r8, %r12       # i < n - 1
        jle     end

        movq    %r8, %r10       # long index = i
        movq    %r8, %r9        # j = i
        incq    %r9             # j = i + 1

inner_loop:
        cmpq    %r9, %rsi       # j < n
        jl      swap            # Jump if j < n

        movq    %r9, %rcx       # store a[j] in %rcx
        imulq   $8, %rcx        # 
        addq    %rdx, %rcx      #

        movq    %r10, %rax
        imulq   $8, %rax
        addq    %rdx, %rax

        cmpq    $1, %rdi        # Check if flag ascending = 1
        je      ascending       
        jne     descending

swap:
        cmpq    %r8, %r10
        je      increment_i

        movq    %r8, %rcx       # store i in %rcx
        imulq   $8, %rcx        # %rcx = 8 * i
        addq    %rdx, %rcx

        movq    (%rcx), %r11
        movq    (%rax), %rbx
        movq    %rbx, (%rcx)
        movq    %r11, (%rax)

increment_i:
        incq    %r8             # i++
        jmp     outer_loop

increment_j:
        incq    %r9             # j++
        jmp     inner_loop

ascending:
        movq    (%rcx), %r11    # %r11 = %rcx
        cmpq    (%rax), %r11    
        jg      increment_j     # jump if %r11 > %rax
        movq    %r9, %r10       # %r10 (idx) = %r9 (j)          // Found new min
        jmp     increment_j     

descending:
        movq    (%rcx), %r11
        cmpq    (%rax), %r11
        jl      increment_j
        movq    %r9, %r10
        jmp     increment_j

end:
        leave                  # pops the frame pointer
        ret                    # }
