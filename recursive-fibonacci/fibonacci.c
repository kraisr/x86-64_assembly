#include <stdio.h>

extern int fibonacci(int n);

int main()
{
  for (int i = 1; i <= 10; i++) {
    printf("fib(%d)=%d\n", i, fibonacci(i));
  }
}