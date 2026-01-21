    .globl environ
    .bss
    .balign 8
environ:
        .zero 8

    .globl __progname
    .bss
    .balign 8
__progname:
        .zero 8
        .section .note.GNU-stack,"",@progbits
