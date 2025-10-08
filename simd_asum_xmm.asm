section .data
align 16
abs_mask dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF

section .text
bits 64
default rel
global simd_asum_xmm

simd_asum_xmm:
  xorpd xmm0, xmm0
  xorpd xmm4, xmm4
  movapd xmm3, [abs_mask]
  mov rax, rcx
  shr rax, 3
  jz remainder4

loop:
  prefetchnta [rdx + 256] ; cache hack

  movapd xmm1, [rdx]
  movapd xmm2, [rdx + 16]
  movapd xmm5, [rdx + 32]
  movapd xmm6, [rdx + 48]

  andpd xmm1, xmm3
  andpd xmm2, xmm3

  addpd xmm0, xmm1
  addpd xmm4, xmm2

  andpd xmm5, xmm3
  andpd xmm6, xmm3

  addpd xmm0, xmm5
  addpd xmm4, xmm6

  add rdx, 64
  dec rax

  jnz loop

remainder4:
  test rcx, 4

  jz remainder2

  movapd xmm1, [rdx]
  movapd xmm2, [rdx + 16]
  andpd xmm1, xmm3
  andpd xmm2, xmm3
  addpd xmm0, xmm1
  addpd xmm4, xmm2
  add rdx, 32

remainder2:
  test rcx, 2
  jz remainder

  movapd xmm1, [rdx]
  andpd xmm1, xmm3
  addpd xmm0, xmm1
  add rdx, 16

remainder:
  test rcx, 1
  jz horizontal

  movsd xmm1, [rdx]
  andpd xmm1, xmm3
  addsd xmm0, xmm1

horizontal:
  addpd xmm0, xmm4
  haddpd xmm0, xmm0
  movsd [r8], xmm0
  ret
