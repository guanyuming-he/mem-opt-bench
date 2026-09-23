NVCC := nvcc

BUILD_DIR := ../build/prefetching
CXX_FLAGS := -O2 -std=c++17

comp_steps := 4 16 64 128 256 512 1024
targets := $(comp_steps:%=$(BUILD_DIR)/%_nopref) \
           $(comp_steps:%=$(BUILD_DIR)/%_pref_reg) \
           $(comp_steps:%=$(BUILD_DIR)/%_pref_cache)

all: $(targets)

$(BUILD_DIR):
	mkdir -p $@

clean:
	-rm -rf $(BUILD_DIR)

$(BUILD_DIR)/%_nopref: ../utils.h ctrl_comp_iteration.cu | $(BUILD_DIR)
	$(NVCC) $(CXX_FLAGS) \
		-DCOMPUTE_STEPS=$* \
		-arch=sm_89 \
		ctrl_comp_iteration.cu -o $@

$(BUILD_DIR)/%_pref_reg: ../utils.h ctrl_comp_iteration.cu | $(BUILD_DIR)
	$(NVCC) $(CXX_FLAGS) \
		-DCOMPUTE_STEPS=$* \
		-DPREFETCH_REGISTER \
		-arch=sm_89 \
		ctrl_comp_iteration.cu -o $@

$(BUILD_DIR)/%_pref_cache: ../utils.h ctrl_comp_iteration.cu | $(BUILD_DIR)
	$(NVCC) $(CXX_FLAGS) \
		-DCOMPUTE_STEPS=$* \
		-DPREFETCH_CACHE \
		-arch=sm_89 \
		ctrl_comp_iteration.cu -o $@
