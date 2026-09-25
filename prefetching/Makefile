NVCC := nvcc

BUILD_DIR := ../build/prefetching
CXX_FLAGS := -O2 -std=c++17
CU_FLAGS := -lineinfo -arch=sm_89
# Default to 64 data elements = 2 iterations when executing for profiling
NUM_ELEMENTS ?= 64

comp_steps := 4 16 64 128 256 512 1024
targets := \
	$(comp_steps:%=$(BUILD_DIR)/%_nopref) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_reg) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_cache)
profile_targets := \
	$(comp_steps:%=$(BUILD_DIR)/%_nopref.nsys-rep) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_reg.nsys-rep) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_cache.nsys-rep) \
	$(comp_steps:%=$(BUILD_DIR)/%_nopref.ncu-rep) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_reg.ncu-rep) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_cache.ncu-rep)
extract_targets := \
	$(comp_steps:%=$(BUILD_DIR)/%_nopref.ptx) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_reg.ptx) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_cache.ptx) \
	$(comp_steps:%=$(BUILD_DIR)/%_nopref.sass) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_reg.sass) \
	$(comp_steps:%=$(BUILD_DIR)/%_pref_cache.sass)

.PHONY: all profile-all extract-all nsys-summary

all: $(targets)
profile-all: $(profile_targets)
extract-all: $(extract_targets)
nsys-summary: | profile-all
	for f in $(BUILD_DIR)/*.nsys-rep; do nsys stats --report cuda_gpu_kern_sum "$$f"; done

$(BUILD_DIR):
	mkdir -p $@

clean:
	-rm -rf $(BUILD_DIR)

$(BUILD_DIR)/%_nopref: ../utils.h ctrl_comp_iteration.cu | $(BUILD_DIR)
	$(NVCC) $(CXX_FLAGS) $(CU_FLAGS) \
		-DCOMPUTE_STEPS=$* \
		ctrl_comp_iteration.cu -o $@

$(BUILD_DIR)/%_pref_reg: ../utils.h ctrl_comp_iteration.cu | $(BUILD_DIR)
	$(NVCC) $(CXX_FLAGS) $(CU_FLAGS) \
		-DCOMPUTE_STEPS=$* \
		-DPREFETCH_REGISTER \
		ctrl_comp_iteration.cu -o $@

$(BUILD_DIR)/%_pref_cache: ../utils.h ctrl_comp_iteration.cu | $(BUILD_DIR)
	$(NVCC) $(CXX_FLAGS) $(CU_FLAGS) \
		-DCOMPUTE_STEPS=$* \
		-DPREFETCH_CACHE \
		ctrl_comp_iteration.cu -o $@

$(BUILD_DIR)/%.nsys-rep: $(BUILD_DIR)/%
	nsys profile -f true -o $@ $< $(NUM_ELEMENTS)
$(BUILD_DIR)/%.ncu-rep: $(BUILD_DIR)/%
	ncu --set detailed --import-source yes -fo $@ $< $(NUM_ELEMENTS)

$(BUILD_DIR)/%.ptx: $(BUILD_DIR)/%
	cuobjdump --dump-ptx $< | sed '/^Fatbin/,/^$$/d' >$@
$(BUILD_DIR)/%.sass: $(BUILD_DIR)/%
	cuobjdump --dump-sass $< >$@
