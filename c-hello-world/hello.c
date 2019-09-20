#include <stdio.h>
#include <stdlib.h>

#ifndef ARCH
#define ARCH "Undefined"
#endif
 
int main() 
{
    printf("Hello, architecture from uname is %s\n", ARCH);

    switch (sizeof(void *))
    {
        case 4:
            printf("32-bit machine\n");
            break;
        case 8:
            printf("64-bit machine\n");
            break;
        default:
            printf("unknown machine\n");
    }
    exit(0);
}
