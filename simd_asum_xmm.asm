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
  xorpd xmm8, xmm8
  xorpd xmm9, xmm9
  movapd xmm3, [abs_mask]
  mov rax, rcx
  shr rax, 4
  jz remainder8

loop:
  prefetchnta [rdx + 512] ; cache hack

  movapd xmm1, [rdx]
  movapd xmm2, [rdx + 16]
  movapd xmm5, [rdx + 32]
  movapd xmm6, [rdx + 48]

  andpd xmm1, xmm3
  andpd xmm2, xmm3
  andpd xmm5, xmm3
  andpd xmm6, xmm3

  addpd xmm0, xmm1
  addpd xmm4, xmm2
  addpd xmm8, xmm5
  addpd xmm9, xmm6

  movapd xmm1, [rdx + 64]
  movapd xmm2, [rdx + 80]
  movapd xmm5, [rdx + 96]
  movapd xmm6, [rdx + 112]

  andpd xmm1, xmm3
  andpd xmm2, xmm3
  andpd xmm5, xmm3
  andpd xmm6, xmm3

  addpd xmm0, xmm1
  addpd xmm4, xmm2
  addpd xmm8, xmm5
  addpd xmm9, xmm6

  add rdx, 128
  dec rax
  jnz loop

remainder8:
  test rcx, 8
  jz remainder4

  movapd xmm1, [rdx]
  movapd xmm2, [rdx + 16]
  movapd xmm5, [rdx + 32]
  movapd xmm6, [rdx + 48]

  andpd xmm1, xmm3
  andpd xmm2, xmm3
  andpd xmm5, xmm3
  andpd xmm6, xmm3

  addpd xmm0, xmm1
  addpd xmm4, xmm2
  addpd xmm8, xmm5
  addpd xmm9, xmm6

  add rdx, 64

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
  addpd xmm8, xmm9
  addpd xmm0, xmm8

  haddpd xmm0, xmm0
  movsd [r8], xmm0
  ret
