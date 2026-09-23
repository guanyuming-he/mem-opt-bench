#pragma once

#include <cuda_runtime.h>
#include <cmath>
#include <cstdlib>
#define CUDA_CHECK(call)												   \
	do {																   \
		cudaError_t err__ = (call);										\
		if (err__ != cudaSuccess) {									   \
			std::cerr << "CUDA error at " << __FILE__ << ":" << __LINE__  \
					  << "\n  " << #call << "\n  "						 \
					  << cudaGetErrorString(err__) << '\n';			   \
			std::exit(EXIT_FAILURE);									   \
		}																  \
	} while (false)


