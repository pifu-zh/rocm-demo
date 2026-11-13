// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Hardware-mechanism demo: buffer_load -> LDS passthrough (b32) on gfx1030.
// Measured facts baked into this kernel (2026-11-13, RX 6950 XT / ROCm 7.2.4):
//   - V# word3 config MUST be 0x31014000 on gfx1030; zero config silently
//     routes every load to the OOB fill-zero path (aiter make_gmem lesson).
//   - The LDS destination is a wave-UNIFORM base (m0); hardware adds lane*4.
//   - Multi-wave: two waves sharing m0 fault — 1 wave per workgroup.
//   - Explicit s_waitcnt vmcnt(0) before LDS consumption; bar.sync does not
//     cover the VMcnt FIFO.
	.amdgcn_target "amdgcn-amd-amdhsa--gfx1030"
	.amdhsa_code_object_version 6
	.text
	.p2align	8
	.globl	lds_probe
	.type	lds_probe,@function
lds_probe:
	s_load_dwordx2 s[4:5], s[0:1], 0x0        // src
	s_load_dwordx2 s[6:7], s[0:1], 0x8        // out
	s_load_dword   s8, s[0:1], 0x10           // n
	s_waitcnt lgkmcnt(0)
	v_mbcnt_lo_u32_b32 v0, -1, 0
	v_mbcnt_hi_u32_b32 v0, -1, v0             // lane
	v_lshlrev_b32 v2, 2, v0                   // lane * 4 (voffset and LDS slot)
	v_mov_b32 v1, 0
	s_lshl_b32 s12, s8, 2                     // num_records = n * 4
	s_mov_b32 s8, s4                          // V# base lo
	s_mov_b32 s9, s5                          // V# base hi
	s_mov_b32 s10, s12                        // num_records
	s_mov_b32 s11, 0x31014000                 // V# word3 (gfx1030 config)
	s_mov_b32 m0, 0x0                         // LDS base: segment starts at 0
	buffer_load_dword v2, s[8:11], 0 offen lds
	s_waitcnt vmcnt(0)
	s_waitcnt lgkmcnt(0)
	ds_read_b32 v4, v2                        // read back our slot
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v5, vcc_lo, s6, v2
	v_add_co_ci_u32_e64 v6, null, s7, v1, vcc_lo
	global_store_dword v[5:6], v4, off
	s_endpgm

	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel lds_probe
		.amdhsa_group_segment_fixed_size 1024
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 24
		.amdhsa_user_sgpr_count 2
		.amdhsa_user_sgpr_private_segment_buffer 0
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_flat_scratch_init 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_system_sgpr_private_segment_wavefront_offset 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 8
		.amdhsa_next_free_sgpr 14
		.amdhsa_reserve_vcc 1
		.amdhsa_reserve_flat_scratch 0
		.amdhsa_float_round_mode_32 0
		.amdhsa_float_round_mode_16_64 0
		.amdhsa_float_denorm_mode_32 3
		.amdhsa_float_denorm_mode_16_64 3
		.amdhsa_dx10_clamp 1
		.amdhsa_ieee_mode 1
		.amdhsa_fp16_overflow 0
		.amdhsa_workgroup_processor_mode 1
		.amdhsa_memory_ordered 1
		.amdhsa_forward_progress 1
		.amdhsa_shared_vgpr_count 0
		.amdhsa_exception_fp_ieee_invalid_op 0
		.amdhsa_exception_fp_denorm_src 0
		.amdhsa_exception_fp_ieee_div_zero 0
		.amdhsa_exception_fp_ieee_overflow 0
		.amdhsa_exception_fp_ieee_underflow 0
		.amdhsa_exception_fp_ieee_inexact 0
		.amdhsa_exception_int_div_zero 0
	.end_amdhsa_kernel

	.text
	.p2align	8
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .offset:         16
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 1024
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           lds_probe
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         lds_probe.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     8
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target:   amdgcn-amd-amdhsa--gfx1030
amdhsa.version:
  - 1
  - 2
...
	.end_amdgpu_metadata
