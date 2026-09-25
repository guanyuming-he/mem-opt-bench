#ifndef COMPUTE_STEPS
#error "COMPUTE_STEPS must be defined"
#endif

#define WARP_SIZE 32

#include "../utils.h"

#include <iomanip>
#include <iostream>
#include <numeric>
#include <vector>

// out[id] = 
// sum(compute(x[id+i*32]) for i in 0..iterations) 
// iterations * 32 = n.
__global__
void prefetch_with_compute(
	const float* __restrict__ x,
	float* __restrict__ out,
	int n,
	int iterations
) {
	int index = threadIdx.x;
	float accumulator = 0.0f;

#ifdef PREFETCH_REGISTER // prefetch into register
	float current;
	float next;

	const float* current_ptr = x + index;
	asm volatile(
		"ld.global.f32 %0, [%1];"
		: "=f"(current)
		: "l"(current_ptr)
	);

	#pragma unroll 1
	for (int i = 0; i < iterations; ++i) {
		if (i + 1 < iterations) {
			const float* next_ptr =
				x + index + (i + 1) * WARP_SIZE;
			asm volatile(
				"ld.global.f32 %0, [%1];"
				: "=f"(next)
				: "l"(next_ptr)
			);
		}

		#pragma unroll
		for (int k = 0; k < COMPUTE_STEPS; ++k) {
			current = current * 1.000001f + 0.000001f;
		}

		accumulator += current;

		if (i + 1 < iterations) {
			current = next;
		}
	}
#elif defined(PREFETCH_CACHE) // prefetch into l1 cache
	#pragma unroll 1
	for (int i = 0; i < iterations; ++i) {
		if (i + 1 < iterations) {
			const float* next_ptr =
				x + index + (i + 1) * WARP_SIZE;
			asm volatile(
				"prefetch.global.L1 [%0];"
				:
				: "l"(next_ptr));
		}

		const float* current_ptr =
			x + index + i * WARP_SIZE;
		float current;
		asm volatile(
			"ld.global.f32 %0, [%1];"
			: "=f"(current)
			: "l"(current_ptr)
		);

		#pragma unroll
		for (int k = 0; k < COMPUTE_STEPS; ++k) {
			current = current * 1.000001f + 0.000001f;
		}

		accumulator += current;
	}
#else // don't prefetch
	#pragma unroll 1
	for (int i = 0; i < iterations; ++i) {
		const float* current_ptr =
			x + index + i * WARP_SIZE;

		float current;
		asm volatile(
			"ld.global.f32 %0, [%1];"
			: "=f"(current)
			: "l"(current_ptr)
		);

		#pragma unroll
		for (int k = 0; k < COMPUTE_STEPS; ++k) {
			current = current * 1.000001f + 0.000001f;
		}

		accumulator += current;
	}
#endif

	out[index] = accumulator;
}


int main(int argc, char** argv)
{
	// Size of float array
	int iterations;

	if (argc != 2) {
		std::cerr << "Usage: " << argv[0] << " <num_iterations>.\n";
		return EXIT_FAILURE;
	}

	iterations = std::atoi(argv[1]);
	int n = WARP_SIZE * iterations;

	if (iterations <= 0) {
		std::cerr << "Arguments must be positive.\n";
		return EXIT_FAILURE;
	}

	int device = 0;
	cudaDeviceProp properties{};
	CUDA_CHECK(cudaGetDeviceProperties(&properties, device));
	CUDA_CHECK(cudaSetDevice(device));

	std::cout << "Device: " << properties.name << '\n';

	std::vector<float> host_x(n);
	for (int i = 0; i < n; ++i) {
		host_x[i] = 1.0f + 0.001f * static_cast<float>(i % 1000);
	}

	float* d_x = nullptr;
	float* d_out = nullptr;

	CUDA_CHECK(cudaMalloc(
		reinterpret_cast<void**>(&d_x),
		static_cast<std::size_t>(n) * sizeof(float)));
	CUDA_CHECK(cudaMalloc(
		reinterpret_cast<void**>(&d_out),
		WARP_SIZE * sizeof(float)));
	CUDA_CHECK(cudaMemcpy(
		d_x,
		host_x.data(),
		static_cast<std::size_t>(n) * sizeof(float),
		cudaMemcpyHostToDevice));

	// Just run one warp
	prefetch_with_compute<<<1, WARP_SIZE>>>(d_x, d_out, n, iterations);

	CUDA_CHECK(cudaGetLastError());
	CUDA_CHECK(cudaDeviceSynchronize());
	CUDA_CHECK(cudaFree(d_x));
	CUDA_CHECK(cudaFree(d_out));
	CUDA_CHECK(cudaDeviceReset());

	return EXIT_SUCCESS;
}
