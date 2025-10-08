# SIMD Programming Project: ASUM Kernel Optimization

This report details the implementation and performance analysis of an ASUM (sum of absolute values) kernel. The project goal was to explore the performance impact of SIMD (Single Instruction, Multiple Data) programming by creating four distinct versions of the kernel:

1.  **Standard C**
2.  **Scalar x86-64 Assembly**
3.  **SIMD x86-64 Assembly (128-bit XMM Registers)**
4.  **SIMD x86-64 Assembly (256-bit YMM Registers)**

The project was developed using **Visual Studio 2022** on a Windows x64 platform, as required by the specification. All kernels were benchmarked across various vector sizes, and the results were analyzed to compare their efficiency. The vector `a` was initialized with the values `a[j] = sin((double)j * 0.0003) * cos((double)j * 0.0007) * 1000.0`.

---

## Program Output and Correctness Check

The following screenshots display the program's output, including execution times, correctness verification against the C reference kernel, and boundary condition checks for all required vector sizes.

### **Release Mode Output**

<img width="921" height="746" alt="Release" src="https://github.com/user-attachments/assets/eeb3a444-c1a9-47c9-95b9-213095a5c021" />

### **Debug Mode Output**

<img width="935" height="736" alt="Debug" src="https://github.com/user-attachments/assets/b86bed58-fe0d-407e-bb3d-b1881d43c48e" />

---

## Comparative Performance Analysis

The performance of each kernel was measured by averaging its execution time over 30 runs. The analysis below is based on the results obtained from the **Release** build, which has compiler optimizations enabled.

#### **Table 1: Average Execution Time (Release Mode, in milliseconds)**

| Kernel | Vector Size: 2^20 | Vector Size: 2^26 | Vector Size: 2^30 |
| :--- | :--- | :--- | :--- |
| **C Kernel** | 0.376970 ms | 24.817803 ms | 394.713410 ms |
| **ASM (x86-64)** | 0.394840 ms | 24.670783 ms | 396.502193 ms |
| **SIMD (XMM)** | **0.083933 ms** | **0.334314 ms** | **5.527103 ms** |
| **SIMD (YMM)** | 0.114167 ms | 10.763133 ms | 164.091947 ms |

#### **Table 2: Speedup Factor (Relative to C Kernel)**

| Kernel | Vector Size: 2^20 | Vector Size: 2^26 | Vector Size: 2^30 |
| :--- | :--- | :--- | :--- |
| **ASM (x86-64)** | 0.96x | 1.01x | 1.00x |
| **SIMD (XMM)** | **4.49x** | **74.24x** | **71.41x** |
| **SIMD (YMM)** | 3.30x | 2.31x | 2.41x |

### **Analysis of Results**

1.  **Debug vs. Release Mode**: There is a significant performance gap between the Debug and Release builds. The Release configuration enables compiler optimizations that dramatically reduce execution time. For instance, the C kernel is over **6x faster** in Release mode for the 2^20 vector size.

2.  **C vs. Scalar x86-64 Assembly**: The performance of the handwritten scalar assembly code is **nearly identical** to the compiler-optimized C code in Release mode. This is a testament to how effectively modern compilers can optimize straightforward C code, often matching or even exceeding the performance of simple, hand-coded assembly.

3.  **The Power of SIMD (XMM)**: The SIMD kernel using XMM registers delivered a **massive performance improvement**, achieving a speedup of over **70 times** compared to the C kernel on large vector sizes. This efficiency stems from several factors:
    * **Data Parallelism**: SIMD instructions perform the same operation on multiple data elements simultaneously. Since XMM registers are 128 bits, they can process two 64-bit doubles at once.
    * **Loop Unrolling & Pipelining**: The `simd_asum_xmm.asm` implementation unrolls the main loop to process eight doubles (using four XMM registers) in each iteration. By using two separate accumulator registers (`xmm0` and `xmm4`), it creates two independent dependency chains. This allows the CPU to hide instruction latency by executing other instructions in parallel, making better use of its execution pipelines.
    * **Cache Optimization**: The use of the `prefetchnta` instruction hints to the CPU to load upcoming data into the cache, ensuring the pipeline is not starved waiting for memory access.

4.  **SIMD YMM Performance Anomaly**: Unexpectedly, the YMM kernel, which uses wider 256-bit registers to process four doubles at once, was significantly slower than the XMM version. The reason lies not in the AVX2 instruction set itself, but in the implementation strategy. The algorithm in `simd_asum_ymm.asm` uses a simple loop that processes only one YMM register per iteration. It **lacks the aggressive loop unrolling and latency-hiding techniques** that make the XMM kernel so fast. This result is a crucial insight: a superior instruction set does not guarantee superior performance without an optimized implementation that fully leverages the underlying CPU architecture.

---

## Challenges, Solutions, and "Aha!" Moments

* **Challenge 1: Floating-Point Precision**
    * **Problem**: When summing millions of double-precision numbers, small floating-point inaccuracies can accumulate, causing the final results of the optimized kernels to differ slightly from the C reference.
    * **Solution**: A **dynamic tolerance** was implemented in the `main.c` driver. The `compute_tolerance` function calculates an acceptable error margin that scales with the vector size `n`. This prevents false negatives during the correctness check while still ensuring the results are within an acceptable range.

* **Challenge 2: Handling Boundary Conditions**
    * **Problem**: Vector sizes are not always perfectly divisible by the number of elements a SIMD register can process (2 for XMM, 4 for YMM). A naive SIMD loop would either miss the final elements or read beyond the allocated memory, causing incorrect results or a crash.
    * **Solution**: Both SIMD implementations feature a **remainder-handling section**. After the main loop processes the bulk of the data in large chunks, a series of checks processes the final 1-7 elements individually. The `simd_asum_xmm.asm` implementation uses a cascade of `test` instructions to handle remaining chunks, while the `simd_asum_ymm.asm` implementation uses a bitwise `and` and a small secondary loop.

* **"Aha!" Moment: Micro-Optimization Trumps Brute Force**
    * The most enlightening discovery was seeing the highly optimized XMM kernel outperform the simpler YMM implementation. It was a powerful demonstration that **algorithmic structure and an understanding of CPU architecture are more important than just using wider registers.** The unique methodology in the XMM kernel—combining data parallelism with instruction-level parallelism via loop unrolling and multiple accumulators—was the key to its exceptional performance. This insight underscores that true optimization requires a holistic approach that considers both the instruction set and the execution pipeline of the target processor.
