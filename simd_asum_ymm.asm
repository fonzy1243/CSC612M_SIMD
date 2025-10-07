section .data
abs_mask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF

section .text
bits 64
default rel
global simd_asum_ymm

simd_asum_ymm:
    vxorpd ymm0, ymm0, ymm0          ; to accumulate the sum
    mov rax, rcx                     ; save a copy of n to check remainder elements later
    shr rcx, 2                       ; 4 doubles per ymm
    vbroadcastsd ymm2, [abs_mask]   

.loop:
    vmovdqu ymm1, [rdx]
    vandpd ymm1, ymm1, ymm2          ; absolute value 
    vaddpd ymm0, ymm0, ymm1
    add rdx, 32
    dec rcx
    jnz .loop

.sum:
    vextractf128 xmm1, ymm0, 1
    vaddpd xmm0, xmm0, xmm1
    vhaddpd xmm0, xmm0, xmm0
    and rax, 3                       ; check for remainder elements
    jz .done

.handle_remainder:
    vmovsd xmm1, [rdx]
    vandpd xmm1, xmm1, xmm2
    vaddsd xmm0, xmm0, xmm1
    add rdx, 8
    dec rax
    jnz .handle_remainder

.done:
    vmovsd [r8], xmm0
    ret