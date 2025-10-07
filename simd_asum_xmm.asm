section .data
abs_mask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF

section .text
bits 64
default rel
global simd_asum_xmm

simd_asum_xmm:
  xorpd xmm0, xmm0
  movapd xmm3, [abs_mask]

  mov rax, rcx
  shr rax, 1
  jz remainder

loop:
  movupd xmm1, [rdx]
  andpd xmm1, xmm3
  addpd xmm0, xmm1
  add rdx, 16
  dec rax
  jnz loop

remainder:
  test rcx, 1
  jz horizontal

  movsd xmm1, [rdx]
  andpd xmm1, xmm3
  addsd xmm0, xmm1

horizontal:
  movhlps xmm1, xmm0
  addsd xmm0, xmm1

  movsd [r8], xmm0
  ret
