#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <windows.h>

void c_asum(size_t n, const double* a, double* asum);
extern void asm_asum(size_t n, const double* a, double* asum);
extern void simd_asum_xmm(size_t n, const double* a, double* asum);
extern void simd_asum_ymm(size_t n, const double* a, double* asum);

#define NUM_RUNS 30

#define N1 (1 << 20)
#define N2 (1 << 26)
#define N3 (1 << 30) // Can be reduced to 28/29 if needed
#define BOUNDARY_N 1003

#define TOLERANCE 0.0001

void c_asum(size_t n, const double* a, double* asum) {
    double local_sum = 0.0;
    for (size_t i = 0; i < n; i++) {
        local_sum += fabs(a[i]);
    }
    *asum = local_sum;
}

void run_and_time_kernel(const char* kernel_name, void (*kernel_func)(size_t, const double*, double*), size_t n, const double* a, double reference_asum) {
    double result_asum = 0.0;
    LARGE_INTEGER frequency, start, end;
    double total_time = 0.0;

    QueryPerformanceFrequency(&frequency);

    for (int i = 0; i < NUM_RUNS; ++i) {
        QueryPerformanceCounter(&start);
        kernel_func(n, a, &result_asum);
        QueryPerformanceCounter(&end);
        total_time += (double)(end.QuadPart - start.QuadPart);
    }

    double avg_time_ms = (total_time * 1000.0) / (frequency.QuadPart * NUM_RUNS);

    printf("Kernel: %-15s | Avg Time: %10.6f ms | Result: %-15.6f | ", kernel_name, avg_time_ms, result_asum);

    if (kernel_func != c_asum) {
        if (fabs(result_asum - reference_asum) < TOLERANCE) {
            printf("Correct\n");
        }
        else {
            printf("INCORRECT\n");
        }
    }
    else {
        printf("Reference\n");
    }
}

int main() {
    size_t test_sizes[] = { N1, N2, N3, BOUNDARY_N };
    const char* test_names[] = { "2^20", "2^26", "2^30", "1003 (Boundary)" };
    int num_tests = sizeof(test_sizes) / sizeof(test_sizes[0]);

    for (int i = 0; i < num_tests; ++i) {
        size_t n = test_sizes[i];
        printf("=========================================================================\n");
        printf("Processing for vector size n = %s (%zu elements)\n", test_names[i], n);
        printf("=========================================================================\n");

        double* a = (double*)malloc(n * sizeof(double));
        if (a == NULL) {
            fprintf(stderr, "Failed to allocate memory for vector A.\n");
            return 1;
        }

        for (size_t j = 0; j < n; ++j) {
            a[j] = sin((double)j * 0.0003) * cos((double)j * 0.0007) * 1000.0;
        }

        double reference_asum = 0.0;

        c_asum(n, a, &reference_asum);

        run_and_time_kernel("C Kernel", c_asum, n, a, reference_asum);
        run_and_time_kernel("ASM (x86-64)", asm_asum, n, a, reference_asum);
        run_and_time_kernel("SIMD (XMM)", simd_asum_xmm, n, a, reference_asum);
        run_and_time_kernel("SIMD (YMM)", simd_asum_ymm, n, a, reference_asum);

        printf("\n");

        free(a);
    }

    return 0;
}