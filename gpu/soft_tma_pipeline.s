// SPDX-License-Identifier: MIT
// Copyright (C) 2024-2026, Advanced Micro Devices, Inc. All rights reserved.
//
// Demo: soft-TMA pipeline for gfx1030 (RDNA2), hand-written ISA, adapted and
// simplified from the proven lds_b4 microbenchmark kernel of the
// cuda-oxide soft-TMA research line (closed 2026-11-04 at 553 GB/s = 96.1%
// of the 575.5 GB/s empirical ceiling = 91.4% of the D2D reference —
// perfect-substitute tier). See gpu/README.md for the lineage.
//
// The design being demonstrated (cp.async / TMA substitute with NO async
// copy hardware):
//   - Deep-pipelined global loads: 4x global_load_dwordx4 issued AHEAD of
//     consumption (prologue + one loop iteration of latency hiding).
//   - vmcnt(N) PARTIAL drain: s_waitcnt vmcnt(4) lets the 4 just-issued
//     loads stay in flight while the 4 older ones are guaranteed landed —
//     the register file is the double buffer.
//   - LDS double buffer: ds_write_b128 into a 2x2KB region; s16 XOR 2048
//     flips the buffer phase each iteration, so consumers and producers
//     never share a buffer.
//   - lgkmcnt(0) before reading back what was written to LDS (LDS ops count
//     on the LGKM counter, not vmcnt).
//
// Kernel signature (kernarg, 24 bytes): src_ptr(8), dst_ptr(8),
// quads_per_wg(4, multiple of 4). One wave32 per workgroup; each lane owns
// 16 B per 512 B quad; the wave consumes quads_per_wg quads and writes its
// four accumulated f32 lanes sums to dst + wg*512 + lane*16.
//
// Assemble: clang -c -x assembler -target amdgcn-amd-amdhsa--gfx1030
//             soft_tma_pipeline.s -o soft_tma_pipeline.co
	.amdgcn_target "amdgcn-amd-amdhsa--gfx1030"
	.amdhsa_code_object_version 6
	.globl	st_tma1
	.type	st_tma1,@function
st_tma1:
	// Kernargs: s[0:1] = kernarg segment pointer (user sgpr 0).
	s_load_dwordx2 s[4:5], s[0:1], 0x0        // src
	s_load_dwordx2 s[6:7], s[0:1], 0x8        // dst
	s_load_dword   s8, s[0:1], 0x10           // quads_per_wg
	s_waitcnt lgkmcnt(0)
	v_mbcnt_lo_u32_b32 v0, -1, 0
	v_mbcnt_hi_u32_b32 v0, -1, v0             // lane id (wave32)
	v_lshlrev_b32 v1, 4, v0                   // lane * 16 B
	v_mov_b32 v3, 0
	// This workgroup's byte base = wg_id * quads_per_wg * 512.
	s_mul_i32 s10, s2, s8
	s_lshl_b32 s11, s10, 9
	s_lshr_b32 s12, s10, 23
	s_add_u32 s4, s4, s11
	s_addc_u32 s5, s5, s12
	s_mov_b32 s12, s4                         // running src base (lo)
	s_mov_b32 s13, s5                         // running src base (hi)
	s_movk_i32 s16, 0x0                       // LDS buffer base (0 / 2048)
	s_movk_i32 s18, 2048                      // phase flip
	s_mov_b32 s17, s8                         // remaining quads
	v_mov_b32 v150, 0
	v_mov_b32 v151, 0
	v_mov_b32 v152, 0
	v_mov_b32 v153, 0
	// Prologue: issue 4 quads into v[16:31] (buffer phase 0).
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[16:19], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[20:23], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[24:27], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[28:31], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	s_sub_u32 s17, s17, 4
st_tma1_loop_a:
	s_cmp_eq_u32 s17, 0
	s_cbranch_scc1 st_tma1_tail_g0
	// Issue the NEXT 4 quads into v[32:47] before touching the old ones.
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[32:35], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[36:39], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[40:43], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[44:47], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	s_sub_u32 s17, s17, 4
	// Partial drain: the 4 NEW loads keep flying; the 4 OLD ones landed.
	s_waitcnt vmcnt(4)
	v_add_co_u32 v6, vcc_lo, s16, v1
	ds_write_b128 v6, v[16:19]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 512
	ds_write_b128 v6, v[20:23]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1024
	ds_write_b128 v6, v[24:27]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1536
	ds_write_b128 v6, v[28:31]
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v6, vcc_lo, s16, v1
	ds_read_b128 v[16:19], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 512
	ds_read_b128 v[20:23], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1024
	ds_read_b128 v[24:27], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1536
	ds_read_b128 v[28:31], v6
	s_waitcnt lgkmcnt(0)
	v_add_f32 v150, v16, v150
	v_add_f32 v151, v17, v151
	v_add_f32 v152, v18, v152
	v_add_f32 v153, v19, v153
	v_add_f32 v150, v20, v150
	v_add_f32 v151, v21, v151
	v_add_f32 v152, v22, v152
	v_add_f32 v153, v23, v153
	v_add_f32 v150, v24, v150
	v_add_f32 v151, v25, v151
	v_add_f32 v152, v26, v152
	v_add_f32 v153, v27, v153
	v_add_f32 v150, v28, v150
	v_add_f32 v151, v29, v151
	v_add_f32 v152, v30, v152
	v_add_f32 v153, v31, v153
	s_xor_b32 s16, s16, s18                   // flip LDS buffer phase
	s_cmp_eq_u32 s17, 0
	s_cbranch_scc1 st_tma1_tail_g1
	// Ping-pong: issue into the other register half.
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[16:19], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[20:23], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[24:27], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	v_add_co_u32 v4, vcc_lo, s12, v1
	v_add_co_ci_u32_e64 v5, null, s13, v3, vcc_lo
	global_load_dwordx4 v[28:31], v[4:5], off
	s_add_u32 s12, s12, 512
	s_addc_u32 s13, s13, 0
	s_sub_u32 s17, s17, 4
	s_waitcnt vmcnt(4)
	v_add_co_u32 v6, vcc_lo, s16, v1
	ds_write_b128 v6, v[32:35]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 512
	ds_write_b128 v6, v[36:39]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1024
	ds_write_b128 v6, v[40:43]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1536
	ds_write_b128 v6, v[44:47]
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v6, vcc_lo, s16, v1
	ds_read_b128 v[32:35], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 512
	ds_read_b128 v[36:39], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1024
	ds_read_b128 v[40:43], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1536
	ds_read_b128 v[44:47], v6
	s_waitcnt lgkmcnt(0)
	v_add_f32 v150, v32, v150
	v_add_f32 v151, v33, v151
	v_add_f32 v152, v34, v152
	v_add_f32 v153, v35, v153
	v_add_f32 v150, v36, v150
	v_add_f32 v151, v37, v151
	v_add_f32 v152, v38, v152
	v_add_f32 v153, v39, v153
	v_add_f32 v150, v40, v150
	v_add_f32 v151, v41, v151
	v_add_f32 v152, v42, v152
	v_add_f32 v153, v43, v153
	v_add_f32 v150, v44, v150
	v_add_f32 v151, v45, v151
	v_add_f32 v152, v46, v152
	v_add_f32 v153, v47, v153
	s_xor_b32 s16, s16, s18
	s_branch st_tma1_loop_a

st_tma1_tail_g0:
	// Loop entry exhausted with the PROLOGUE quads (v[16:31]) outstanding.
	s_waitcnt vmcnt(0)
	v_add_co_u32 v6, vcc_lo, s16, v1
	ds_write_b128 v6, v[16:19]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 512
	ds_write_b128 v6, v[20:23]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1024
	ds_write_b128 v6, v[24:27]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1536
	ds_write_b128 v6, v[28:31]
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v6, vcc_lo, s16, v1
	ds_read_b128 v[16:19], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 512
	ds_read_b128 v[20:23], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1024
	ds_read_b128 v[24:27], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1536
	ds_read_b128 v[28:31], v6
	s_waitcnt lgkmcnt(0)
	v_add_f32 v150, v16, v150
	v_add_f32 v151, v17, v151
	v_add_f32 v152, v18, v152
	v_add_f32 v153, v19, v153
	v_add_f32 v150, v20, v150
	v_add_f32 v151, v21, v151
	v_add_f32 v152, v22, v152
	v_add_f32 v153, v23, v153
	v_add_f32 v150, v24, v150
	v_add_f32 v151, v25, v151
	v_add_f32 v152, v26, v152
	v_add_f32 v153, v27, v153
	v_add_f32 v150, v28, v150
	v_add_f32 v151, v29, v151
	v_add_f32 v152, v30, v152
	v_add_f32 v153, v31, v153
	s_branch st_tma1_store

st_tma1_tail_g1:
	// Exhausted right after a body iteration: v[32:47] are outstanding.
	s_waitcnt vmcnt(0)
	v_add_co_u32 v6, vcc_lo, s16, v1
	ds_write_b128 v6, v[32:35]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 512
	ds_write_b128 v6, v[36:39]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1024
	ds_write_b128 v6, v[40:43]
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1536
	ds_write_b128 v6, v[44:47]
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v6, vcc_lo, s16, v1
	ds_read_b128 v[32:35], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 512
	ds_read_b128 v[36:39], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1024
	ds_read_b128 v[40:43], v6
	v_add_co_u32 v6, vcc_lo, s16, v1
	v_add_nc_u32 v6, v6, 1536
	ds_read_b128 v[44:47], v6
	s_waitcnt lgkmcnt(0)
	v_add_f32 v150, v32, v150
	v_add_f32 v151, v33, v151
	v_add_f32 v152, v34, v152
	v_add_f32 v153, v35, v153
	v_add_f32 v150, v36, v150
	v_add_f32 v151, v37, v151
	v_add_f32 v152, v38, v152
	v_add_f32 v153, v39, v153
	v_add_f32 v150, v40, v150
	v_add_f32 v151, v41, v151
	v_add_f32 v152, v42, v152
	v_add_f32 v153, v43, v153
	v_add_f32 v150, v44, v150
	v_add_f32 v151, v45, v151
	v_add_f32 v152, v46, v152
	v_add_f32 v153, v47, v153

st_tma1_store:
	// dst + wg*512 + lane*16 <- the lane's four accumulated sums.
	s_lshl_b32 s11, s2, 9
	s_add_u32 s14, s6, s11
	s_addc_u32 s15, s7, 0
	v_add_co_u32 v4, vcc_lo, s14, v1
	v_add_co_ci_u32_e64 v5, null, s15, v3, vcc_lo
	global_store_dwordx4 v[4:5], v[150:153], off
	s_endpgm

	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel st_tma1
		.amdhsa_group_segment_fixed_size 4096
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
		.amdhsa_next_free_vgpr 156
		.amdhsa_next_free_sgpr 22
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

// ── lds_probe: buffer_load→LDS passthrough (b32), legacy MUBUF lds=1 path ──
// m0 = 0 (raw ISA owns the whole LDS window); each lane's dword lands at
// m0 + lane*4. V# word3 must be 0x31014000 on gfx1030 (zero config hits the
// OOB fill-zero path). Demonstrated: the RDNA2 hardware channel aiter never
// used outside gfx942.
	.text
	.p2align	8
	.globl	lds_probe
	.type	lds_probe,@function
lds_probe:
	s_load_dwordx2 s[4:5], s[0:1], 0x0        // g
	s_load_dwordx2 s[6:7], s[0:1], 0x8        // out
	s_load_dword   s8, s[0:1], 0x10           // n
	s_waitcnt lgkmcnt(0)
	v_mbcnt_lo_u32_b32 v0, -1, 0
	v_mbcnt_hi_u32_b32 v0, -1, v0             // lane
	v_lshlrev_b32 v2, 2, v0                   // lane * 4 (both voff and LDS slot)
	v_mov_b32 v1, 0
	s_lshl_b32 s12, s8, 2                     // num_records = n * 4 (before s8 reuse)
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
    .group_segment_fixed_size: 4096
    .kernarg_segment_align: 8
    .kernarg_segment_size: 24
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           st_tma1
    .private_segment_fixed_size: 0
    .sgpr_count:     22
    .sgpr_spill_count: 0
    .symbol:         st_tma1.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     156
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
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
