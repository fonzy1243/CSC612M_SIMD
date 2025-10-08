section .data
abs_mask dq 0x7FFFFFFFFFFFFFFF

section .text
bits 64
default rel
global asm_asum

asm_asum:
    vxorpd xmm0, xmm0, xmm0               
    vmovsd xmm2, [abs_mask]

.loop:
    vmovsd xmm1, [rdx]
    vandpd xmm1, xmm1, xmm2
    vaddsd xmm0, xmm0, xmm1
    add rdx, 8
    loop .loop

.done:
    vmovsd [r8], xmm0
    ret