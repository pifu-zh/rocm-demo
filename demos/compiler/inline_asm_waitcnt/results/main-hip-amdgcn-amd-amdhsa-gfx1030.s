	.amdgcn_target "amdgcn-amd-amdhsa--gfx1030"
	.amdhsa_code_object_version 6
	.text
	.protected	_Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i ; -- Begin function _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i
	.globl	_Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i
	.p2align	8
	.type	_Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i,@function
_Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i: ; @_Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i
; %bb.0:
	s_clause 0x1
	s_load_dword s12, s[4:5], 0x10
	s_load_dwordx4 s[8:11], s[4:5], 0x0
	s_add_u32 s0, s0, s7
	s_addc_u32 s1, s1, 0
	v_lshlrev_b32_e32 v4, 4, v0
	s_mov_b32 s7, 0
	s_mov_b32 s17, s7
	s_waitcnt lgkmcnt(0)
	s_ashr_i32 s13, s12, 31
	s_mul_hi_u32 s5, s12, s6
	v_cmp_lt_i64_e64 s4, s[12:13], 1
	s_mul_i32 s13, s13, s6
	s_mul_i32 s14, s12, s6
	s_add_i32 s15, s5, s13
	s_and_b32 vcc_lo, exec_lo, s4
	s_cbranch_vccnz .LBB0_3
; %bb.1:                                ; %.lr.ph
	s_add_i32 s4, s12, -1
	s_min_u32 s13, s4, 3
	s_lshl_b64 s[4:5], s[14:15], 9
	s_add_i32 s17, s13, 1
	s_add_u32 s4, s8, s4
	s_addc_u32 s5, s9, s5
	v_add_co_u32 v0, s4, s4, v4
	v_add_co_ci_u32_e64 v1, null, s5, 0, s4
	s_mov_b32 s4, 0
	s_mov_b32 s5, s17
	.p2align	6
.LBB0_2:                                ; =>This Inner Loop Header: Depth=1
	global_load_dwordx4 v[5:8], v[0:1], off
	v_add_co_u32 v0, vcc_lo, 0x200, v0
	v_mov_b32_e32 v2, s4
	v_add_co_ci_u32_e64 v1, null, 0, v1, vcc_lo
	s_add_i32 s5, s5, -1
	s_add_i32 s4, s4, 16
	s_cmp_eq_u32 s5, 0
	s_waitcnt vmcnt(0)
	buffer_store_dword v8, v2, s[0:3], 0 offen offset:12
	buffer_store_dword v7, v2, s[0:3], 0 offen offset:8
	buffer_store_dword v6, v2, s[0:3], 0 offen offset:4
	buffer_store_dword v5, v2, s[0:3], 0 offen
	s_cbranch_scc0 .LBB0_2
.LBB0_3:                                ; %Flow126
	v_add_co_u32 v5, s4, s8, v4
	v_add_co_ci_u32_e64 v6, null, s9, 0, s4
	s_movk_i32 s5, 0x50
	s_movk_i32 s8, 0x60
	s_movk_i32 s9, 0x70
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v7, 16
	v_mov_b32_e32 v8, 32
	v_mov_b32_e32 v9, 48
	v_mov_b32_e32 v10, s5
	v_mov_b32_e32 v11, s8
	v_mov_b32_e32 v12, s9
	v_mov_b32_e32 v1, 0
	v_mov_b32_e32 v2, 0
	v_mov_b32_e32 v3, 0
	s_mov_b32 s13, 0
	s_mov_b32 s16, s17
	s_branch .LBB0_5
.LBB0_4:                                ; %._crit_edge
                                        ;   in Loop: Header=BB0_5 Depth=1
	;;#ASMSTART
	s_waitcnt lgkmcnt(0)
	;;#ASMEND
	s_clause 0xf
	buffer_load_dword v30, off, s[0:3], 0 offset:76
	buffer_load_dword v31, off, s[0:3], 0 offset:72
	buffer_load_dword v32, off, s[0:3], 0 offset:68
	buffer_load_dword v33, off, s[0:3], 0 offset:64
	buffer_load_dword v34, v10, s[0:3], 0 offen offset:12
	buffer_load_dword v35, v10, s[0:3], 0 offen offset:8
	buffer_load_dword v36, v10, s[0:3], 0 offen offset:4
	buffer_load_dword v37, v10, s[0:3], 0 offen
	buffer_load_dword v38, v11, s[0:3], 0 offen offset:12
	buffer_load_dword v39, v11, s[0:3], 0 offen offset:8
	buffer_load_dword v40, v11, s[0:3], 0 offen offset:4
	buffer_load_dword v41, v11, s[0:3], 0 offen
	buffer_load_dword v42, v12, s[0:3], 0 offen offset:12
	buffer_load_dword v43, v12, s[0:3], 0 offen offset:8
	buffer_load_dword v44, v12, s[0:3], 0 offen offset:4
	buffer_load_dword v45, v12, s[0:3], 0 offen
	ds_read_b128 v[14:17], v13
	ds_read_b128 v[18:21], v13 offset:512
	ds_read_b128 v[22:25], v13 offset:1024
	ds_read_b128 v[26:29], v13 offset:1536
	s_xor_b32 s13, s13, 1
	s_mov_b32 s17, 4
	s_mov_b32 vcc_lo, s4
	s_waitcnt vmcnt(15)
	buffer_store_dword v30, off, s[0:3], 0 offset:12
	s_waitcnt vmcnt(14)
	buffer_store_dword v31, off, s[0:3], 0 offset:8
	s_waitcnt vmcnt(13)
	buffer_store_dword v32, off, s[0:3], 0 offset:4
	s_waitcnt vmcnt(12)
	buffer_store_dword v33, off, s[0:3], 0
	s_waitcnt vmcnt(11)
	buffer_store_dword v34, v7, s[0:3], 0 offen offset:12
	s_waitcnt vmcnt(10)
	buffer_store_dword v35, v7, s[0:3], 0 offen offset:8
	s_waitcnt vmcnt(9)
	buffer_store_dword v36, v7, s[0:3], 0 offen offset:4
	s_waitcnt vmcnt(8)
	buffer_store_dword v37, v7, s[0:3], 0 offen
	s_waitcnt vmcnt(7)
	buffer_store_dword v38, v8, s[0:3], 0 offen offset:12
	s_waitcnt vmcnt(6)
	buffer_store_dword v39, v8, s[0:3], 0 offen offset:8
	s_waitcnt vmcnt(5)
	buffer_store_dword v40, v8, s[0:3], 0 offen offset:4
	s_waitcnt vmcnt(4)
	buffer_store_dword v41, v8, s[0:3], 0 offen
	s_waitcnt vmcnt(3)
	buffer_store_dword v42, v9, s[0:3], 0 offen offset:12
	s_waitcnt vmcnt(2)
	buffer_store_dword v43, v9, s[0:3], 0 offen offset:8
	s_waitcnt vmcnt(1)
	buffer_store_dword v44, v9, s[0:3], 0 offen offset:4
	s_waitcnt vmcnt(0)
	buffer_store_dword v45, v9, s[0:3], 0 offen
	s_waitcnt lgkmcnt(3)
	v_add_f32_e32 v1, v1, v15
	v_add_f32_e32 v3, v3, v17
	v_add_f32_e32 v0, v0, v14
	v_add_f32_e32 v2, v2, v16
	s_waitcnt lgkmcnt(2)
	v_add_f32_e32 v1, v1, v19
	v_add_f32_e32 v3, v3, v21
	v_add_f32_e32 v0, v0, v18
	v_add_f32_e32 v2, v2, v20
	s_waitcnt lgkmcnt(1)
	v_add_f32_e32 v1, v1, v23
	v_add_f32_e32 v3, v3, v25
	v_add_f32_e32 v0, v0, v22
	v_add_f32_e32 v2, v2, v24
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v27
	v_add_f32_e32 v3, v3, v29
	v_add_f32_e32 v0, v0, v26
	v_add_f32_e32 v2, v2, v28
	s_cbranch_vccnz .LBB0_12
.LBB0_5:                                ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB0_11 Depth 2
	s_sub_i32 s4, s12, s16
	s_mov_b32 s18, -1
	s_cmp_lt_i32 s4, 4
	s_cselect_b32 s4, -1, 0
	s_and_b32 s4, exec_lo, s4
	s_mov_b32 vcc_lo, s4
	s_cbranch_vccnz .LBB0_8
; %bb.6:                                ; %Flow124
                                        ;   in Loop: Header=BB0_5 Depth=1
	s_andn2_b32 vcc_lo, exec_lo, s18
	s_cbranch_vccz .LBB0_9
.LBB0_7:                                ;   in Loop: Header=BB0_5 Depth=1
	v_lshl_or_b32 v13, s13, 11, v4
	s_cmp_eq_u32 s17, 0
	s_cbranch_scc0 .LBB0_10
	s_branch .LBB0_4
.LBB0_8:                                ;   in Loop: Header=BB0_5 Depth=1
	;;#ASMSTART
	s_waitcnt vmcnt(0)
	;;#ASMEND
	s_cbranch_execnz .LBB0_7
.LBB0_9:                                ; %.preheader.preheader
                                        ;   in Loop: Header=BB0_5 Depth=1
	s_ashr_i32 s19, s16, 31
	s_add_u32 s18, s14, s16
	s_addc_u32 s19, s15, s19
	s_add_i32 s20, s16, 1
	s_lshl_b64 s[18:19], s[18:19], 9
	s_ashr_i32 s21, s20, 31
	s_add_u32 s20, s14, s20
	s_addc_u32 s21, s15, s21
	v_add_co_u32 v13, vcc_lo, v5, s18
	v_add_co_ci_u32_e64 v14, null, s19, v6, vcc_lo
	s_lshl_b64 s[18:19], s[20:21], 9
	v_mov_b32_e32 v29, s5
	v_add_co_u32 v17, vcc_lo, v5, s18
	s_add_i32 s18, s16, 2
	v_add_co_ci_u32_e64 v18, null, s19, v6, vcc_lo
	s_ashr_i32 s19, s18, 31
	s_add_u32 s18, s14, s18
	s_addc_u32 s19, s15, s19
	s_add_i32 s20, s16, 3
	s_lshl_b64 s[18:19], s[18:19], 9
	s_ashr_i32 s21, s20, 31
	s_add_u32 s20, s14, s20
	s_addc_u32 s21, s15, s21
	v_add_co_u32 v21, vcc_lo, v5, s18
	v_add_co_ci_u32_e64 v22, null, s19, v6, vcc_lo
	s_lshl_b64 s[18:19], s[20:21], 9
	s_clause 0x1
	global_load_dwordx4 v[13:16], v[13:14], off
	global_load_dwordx4 v[17:20], v[17:18], off
	v_add_co_u32 v25, vcc_lo, v5, s18
	v_add_co_ci_u32_e64 v26, null, s19, v6, vcc_lo
	s_clause 0x1
	global_load_dwordx4 v[21:24], v[21:22], off
	global_load_dwordx4 v[25:28], v[25:26], off
	s_add_i32 s16, s16, 4
	v_mov_b32_e32 v30, s8
	v_mov_b32_e32 v31, s9
	s_waitcnt vmcnt(3)
	buffer_store_dword v16, off, s[0:3], 0 offset:76
	buffer_store_dword v15, off, s[0:3], 0 offset:72
	buffer_store_dword v14, off, s[0:3], 0 offset:68
	buffer_store_dword v13, off, s[0:3], 0 offset:64
	s_waitcnt vmcnt(2)
	buffer_store_dword v20, v29, s[0:3], 0 offen offset:12
	buffer_store_dword v19, v29, s[0:3], 0 offen offset:8
	buffer_store_dword v18, v29, s[0:3], 0 offen offset:4
	buffer_store_dword v17, v29, s[0:3], 0 offen
	s_waitcnt vmcnt(1)
	buffer_store_dword v24, v30, s[0:3], 0 offen offset:12
	buffer_store_dword v23, v30, s[0:3], 0 offen offset:8
	buffer_store_dword v22, v30, s[0:3], 0 offen offset:4
	buffer_store_dword v21, v30, s[0:3], 0 offen
	s_waitcnt vmcnt(0)
	buffer_store_dword v28, v31, s[0:3], 0 offen offset:12
	buffer_store_dword v27, v31, s[0:3], 0 offen offset:8
	buffer_store_dword v26, v31, s[0:3], 0 offen offset:4
	buffer_store_dword v25, v31, s[0:3], 0 offen
	;;#ASMSTART
	s_waitcnt vmcnt(4)
	;;#ASMEND
	v_lshl_or_b32 v13, s13, 11, v4
	s_cmp_eq_u32 s17, 0
	s_cbranch_scc1 .LBB0_4
.LBB0_10:                               ; %.lr.ph68.preheader
                                        ;   in Loop: Header=BB0_5 Depth=1
	v_mov_b32_e32 v14, v13
	s_mov_b32 s18, 0
	.p2align	6
.LBB0_11:                               ; %.lr.ph68
                                        ;   Parent Loop BB0_5 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	v_mov_b32_e32 v18, s18
	s_add_i32 s17, s17, -1
	s_add_i32 s18, s18, 16
	s_cmp_eq_u32 s17, 0
	s_clause 0x3
	buffer_load_dword v15, v18, s[0:3], 0 offen
	buffer_load_dword v16, v18, s[0:3], 0 offen offset:4
	buffer_load_dword v17, v18, s[0:3], 0 offen offset:8
	buffer_load_dword v18, v18, s[0:3], 0 offen offset:12
	s_waitcnt vmcnt(0)
	ds_write_b128 v14, v[15:18]
	v_add_nc_u32_e32 v14, 0x200, v14
	s_cbranch_scc0 .LBB0_11
	s_branch .LBB0_4
.LBB0_12:
	s_lshl_b64 s[4:5], s[6:7], 9
	s_add_u32 s4, s10, s4
	s_addc_u32 s5, s11, s5
	global_store_dwordx4 v4, v[0:3], s[4:5]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i
		.amdhsa_group_segment_fixed_size 4096
		.amdhsa_private_segment_fixed_size 144
		.amdhsa_kernarg_size 20
		.amdhsa_user_sgpr_count 6
		.amdhsa_user_sgpr_private_segment_buffer 1
		.amdhsa_user_sgpr_dispatch_ptr 0
		.amdhsa_user_sgpr_queue_ptr 0
		.amdhsa_user_sgpr_kernarg_segment_ptr 1
		.amdhsa_user_sgpr_dispatch_id 0
		.amdhsa_user_sgpr_flat_scratch_init 0
		.amdhsa_user_sgpr_private_segment_size 0
		.amdhsa_wavefront_size32 1
		.amdhsa_uses_dynamic_stack 0
		.amdhsa_system_sgpr_private_segment_wavefront_offset 1
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 113
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
	.text
.Lfunc_end0:
	.size	_Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i, .Lfunc_end0-_Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i
                                        ; -- End function
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.num_vgpr, 46
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.num_agpr, 0
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.numbered_sgpr, 22
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.num_named_barrier, 0
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.private_seg_size, 144
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.uses_vcc, 1
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.uses_flat_scratch, 0
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.has_dyn_sized_stack, 0
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.has_recursion, 0
	.set _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 1384
; TotalNumSgprs: 24
; NumVgprs: 46
; ScratchSize: 144
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 4096 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 14
; NumSGPRsForWavesPerEU: 24
; NumVGPRsForWavesPerEU: 113
; Occupancy: 8
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 1
; COMPUTE_PGM_RSRC2:USER_SGPR: 6
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.p2alignl 6, 3214868480
	.fill 48, 4, 3214868480
	.section	.AMDGPU.gpr_maximums,"",@progbits
	.set amdgpu.max_num_vgpr, 0
	.set amdgpu.max_num_agpr, 0
	.set amdgpu.max_num_sgpr, 0
	.text
	.type	__hip_cuid_36b90e9d1999e6cd,@object ; @__hip_cuid_36b90e9d1999e6cd
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_36b90e9d1999e6cd
__hip_cuid_36b90e9d1999e6cd:
	.byte	0                               ; 0x0
	.size	__hip_cuid_36b90e9d1999e6cd, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.4 26084 f58b06dce1f9c15707c5f808fd002e18c2accf7e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_36b90e9d1999e6cd
	.amdgpu_metadata
---
amdhsa.kernels:
  - .args:
      - .actual_access:  read_only
        .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
      - .actual_access:  write_only
        .address_space:  global
        .offset:         8
        .size:           8
        .value_kind:     global_buffer
      - .offset:         16
        .size:           4
        .value_kind:     by_value
    .group_segment_fixed_size: 4096
    .kernarg_segment_align: 8
    .kernarg_segment_size: 20
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 32
    .name:           _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i
    .private_segment_fixed_size: 144
    .sgpr_count:     24
    .sgpr_spill_count: 0
    .symbol:         _Z19partial_drain_probePK15HIP_vector_typeIfLj4EEPS0_i.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     46
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target:   amdgcn-amd-amdhsa--gfx1030
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata
