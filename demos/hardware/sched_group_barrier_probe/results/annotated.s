
# __CLANG_OFFLOAD_BUNDLE____START__ hip-amdgcn-amd-amdhsa--gfx1030
	.amdgcn_target "amdgcn-amd-amdhsa--gfx1030"
	.amdhsa_code_object_version 6
	.text
	.protected	_Z9dot_plainPKfS0_Pfi   ; -- Begin function _Z9dot_plainPKfS0_Pfi
	.globl	_Z9dot_plainPKfS0_Pfi
	.p2align	8
	.type	_Z9dot_plainPKfS0_Pfi,@function
_Z9dot_plainPKfS0_Pfi:                  ; @_Z9dot_plainPKfS0_Pfi
; %bb.0:
	s_clause 0x1
	s_load_dword s0, s[4:5], 0x2c
	s_load_dword s1, s[4:5], 0x18
	s_waitcnt lgkmcnt(0)
	s_and_b32 s0, s0, 0xffff
	v_mad_u64_u32 v[0:1], null, s6, s0, v[0:1]
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_i32_e64 s1, v0
	s_cbranch_execz .LBB0_2
; %bb.1:
	s_load_dwordx4 s[0:3], s[4:5], 0x0
	v_lshlrev_b32_e32 v1, 4, v0
	s_load_dwordx2 s[4:5], s[4:5], 0x10
	v_ashrrev_i32_e32 v2, 31, v1
	v_lshlrev_b64 v[1:2], 2, v[1:2]
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v29, vcc_lo, s2, v1
	v_add_co_ci_u32_e64 v30, null, s3, v2, vcc_lo
	v_add_co_u32 v25, vcc_lo, s0, v1
	v_add_co_ci_u32_e64 v26, null, s1, v2, vcc_lo
	global_load_dwordx4 v[1:4], v[29:30], off
	s_clause 0x1
	global_load_dwordx4 v[5:8], v[25:26], off
	global_load_dwordx4 v[9:12], v[25:26], off offset:16
	s_clause 0x1
	global_load_dwordx4 v[13:16], v[29:30], off offset:16
	global_load_dwordx4 v[17:20], v[29:30], off offset:32
	s_clause 0x1
	global_load_dwordx4 v[21:24], v[25:26], off offset:32
	global_load_dwordx4 v[25:28], v[25:26], off offset:48
	global_load_dwordx4 v[29:32], v[29:30], off offset:48
	s_waitcnt vmcnt(6)
	v_fma_f32 v5, v5, v1, 0
	v_ashrrev_i32_e32 v1, 31, v0
	v_fmac_f32_e32 v5, v6, v2
	v_lshlrev_b64 v[0:1], 2, v[0:1]
	v_fmac_f32_e32 v5, v7, v3
	v_add_co_u32 v0, vcc_lo, s4, v0
	v_add_co_ci_u32_e64 v1, null, s5, v1, vcc_lo
	v_fmac_f32_e32 v5, v8, v4
	s_waitcnt vmcnt(4)
	v_fmac_f32_e32 v5, v9, v13
	v_fmac_f32_e32 v5, v10, v14
	v_fmac_f32_e32 v5, v11, v15
	v_fmac_f32_e32 v5, v12, v16
	s_waitcnt vmcnt(2)
	v_fmac_f32_e32 v5, v21, v17
	v_fmac_f32_e32 v5, v22, v18
	v_fmac_f32_e32 v5, v23, v19
	v_fmac_f32_e32 v5, v24, v20
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v5, v25, v29
	v_fmac_f32_e32 v5, v26, v30
	v_fmac_f32_e32 v5, v27, v31
	v_fmac_f32_e32 v5, v28, v32
	global_store_dword v[0:1], v5, off
.LBB0_2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z9dot_plainPKfS0_Pfi
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 288
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
		.amdhsa_system_sgpr_private_segment_wavefront_offset 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 33
		.amdhsa_next_free_sgpr 7
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
	.size	_Z9dot_plainPKfS0_Pfi, .Lfunc_end0-_Z9dot_plainPKfS0_Pfi
                                        ; -- End function
	.set _Z9dot_plainPKfS0_Pfi.num_vgpr, 33
	.set _Z9dot_plainPKfS0_Pfi.num_agpr, 0
	.set _Z9dot_plainPKfS0_Pfi.numbered_sgpr, 7
	.set _Z9dot_plainPKfS0_Pfi.num_named_barrier, 0
	.set _Z9dot_plainPKfS0_Pfi.private_seg_size, 0
	.set _Z9dot_plainPKfS0_Pfi.uses_vcc, 1
	.set _Z9dot_plainPKfS0_Pfi.uses_flat_scratch, 0
	.set _Z9dot_plainPKfS0_Pfi.has_dyn_sized_stack, 0
	.set _Z9dot_plainPKfS0_Pfi.has_recursion, 0
	.set _Z9dot_plainPKfS0_Pfi.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 324
; TotalNumSgprs: 9
; NumVgprs: 33
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 4
; NumSGPRsForWavesPerEU: 9
; NumVGPRsForWavesPerEU: 33
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 6
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.text
	.protected	_Z13dot_annotatedPKfS0_Pfi ; -- Begin function _Z13dot_annotatedPKfS0_Pfi
	.globl	_Z13dot_annotatedPKfS0_Pfi
	.p2align	8
	.type	_Z13dot_annotatedPKfS0_Pfi,@function
_Z13dot_annotatedPKfS0_Pfi:             ; @_Z13dot_annotatedPKfS0_Pfi
; %bb.0:
	s_clause 0x1
	s_load_dword s0, s[4:5], 0x2c
	s_load_dword s1, s[4:5], 0x18
	s_waitcnt lgkmcnt(0)
	s_and_b32 s0, s0, 0xffff
	v_mad_u64_u32 v[0:1], null, s6, s0, v[0:1]
	s_mov_b32 s0, exec_lo
	v_cmpx_gt_i32_e64 s1, v0
	s_cbranch_execz .LBB1_4
; %bb.1:
	s_clause 0x1
	s_load_dwordx4 s[8:11], s[4:5], 0x0
	s_load_dwordx2 s[2:3], s[4:5], 0x10
	v_lshlrev_b32_e32 v1, 4, v0
	s_mov_b64 s[4:5], 0
	v_ashrrev_i32_e32 v2, 31, v1
	v_lshlrev_b64 v[4:5], 2, v[1:2]
	v_mov_b32_e32 v2, 0
	s_waitcnt lgkmcnt(0)
	v_add_co_u32 v1, vcc_lo, s8, v4
	v_add_co_ci_u32_e64 v3, null, s9, v5, vcc_lo
	v_add_co_u32 v4, vcc_lo, s10, v4
	v_add_co_ci_u32_e64 v5, null, s11, v5, vcc_lo
	.p2align	6
.LBB1_2:                                ; =>This Inner Loop Header: Depth=1
	v_add_co_u32 v6, vcc_lo, v1, s4
	v_add_co_u32 v8, s0, v4, s4
	v_add_co_ci_u32_e64 v7, null, s5, v3, vcc_lo
	v_add_co_ci_u32_e64 v9, null, s5, v5, s0
	s_add_u32 s4, s4, 4
	global_load_dword v6, v[6:7], off
	s_addc_u32 s5, s5, 0
	global_load_dword v7, v[8:9], off
	s_cmp_eq_u32 s4, 64
	; sched_group_barrier mask(0x00000008) size(2) SyncID(0)
	; sched_group_barrier mask(0x00000011) size(4) SyncID(0)
	s_waitcnt vmcnt(0)
	v_fmac_f32_e32 v2, v6, v7
	s_cbranch_scc0 .LBB1_2
; %bb.3:
	v_ashrrev_i32_e32 v1, 31, v0
	v_lshlrev_b64 v[0:1], 2, v[0:1]
	v_add_co_u32 v0, vcc_lo, s2, v0
	v_add_co_ci_u32_e64 v1, null, s3, v1, vcc_lo
	global_store_dword v[0:1], v2, off
.LBB1_4:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z13dot_annotatedPKfS0_Pfi
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 288
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
		.amdhsa_system_sgpr_private_segment_wavefront_offset 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 10
		.amdhsa_next_free_sgpr 12
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
.Lfunc_end1:
	.size	_Z13dot_annotatedPKfS0_Pfi, .Lfunc_end1-_Z13dot_annotatedPKfS0_Pfi
                                        ; -- End function
	.set _Z13dot_annotatedPKfS0_Pfi.num_vgpr, 10
	.set _Z13dot_annotatedPKfS0_Pfi.num_agpr, 0
	.set _Z13dot_annotatedPKfS0_Pfi.numbered_sgpr, 12
	.set _Z13dot_annotatedPKfS0_Pfi.num_named_barrier, 0
	.set _Z13dot_annotatedPKfS0_Pfi.private_seg_size, 0
	.set _Z13dot_annotatedPKfS0_Pfi.uses_vcc, 1
	.set _Z13dot_annotatedPKfS0_Pfi.uses_flat_scratch, 0
	.set _Z13dot_annotatedPKfS0_Pfi.has_dyn_sized_stack, 0
	.set _Z13dot_annotatedPKfS0_Pfi.has_recursion, 0
	.set _Z13dot_annotatedPKfS0_Pfi.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 304
; TotalNumSgprs: 14
; NumVgprs: 10
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 1
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 10
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
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
	.type	__hip_cuid_6a5d713ad1b1c230,@object ; @__hip_cuid_6a5d713ad1b1c230
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_6a5d713ad1b1c230
__hip_cuid_6a5d713ad1b1c230:
	.byte	0                               ; 0x0
	.size	__hip_cuid_6a5d713ad1b1c230, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.4 26084 f58b06dce1f9c15707c5f808fd002e18c2accf7e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_6a5d713ad1b1c230
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
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .offset:         24
        .size:           4
        .value_kind:     by_value
      - .offset:         32
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         36
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         40
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         44
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         46
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         48
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         50
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         52
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         54
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         80
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         88
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         96
        .size:           2
        .value_kind:     hidden_grid_dims
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 288
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z9dot_plainPKfS0_Pfi
    .private_segment_fixed_size: 0
    .sgpr_count:     9
    .sgpr_spill_count: 0
    .symbol:         _Z9dot_plainPKfS0_Pfi.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     33
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
      - .address_space:  global
        .offset:         16
        .size:           8
        .value_kind:     global_buffer
      - .offset:         24
        .size:           4
        .value_kind:     by_value
      - .offset:         32
        .size:           4
        .value_kind:     hidden_block_count_x
      - .offset:         36
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         40
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         44
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         46
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         48
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         50
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         52
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         54
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         80
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         88
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         96
        .size:           2
        .value_kind:     hidden_grid_dims
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 288
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z13dot_annotatedPKfS0_Pfi
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         _Z13dot_annotatedPKfS0_Pfi.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     10
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
amdhsa.target:   amdgcn-amd-amdhsa--gfx1030
amdhsa.version:
  - 1
  - 2
...

	.end_amdgpu_metadata

# __CLANG_OFFLOAD_BUNDLE____END__ hip-amdgcn-amd-amdhsa--gfx1030

# __CLANG_OFFLOAD_BUNDLE____START__ host-x86_64-unknown-linux-gnu-
	.file	"main.hip"
	.text
	.globl	_Z24__device_stub__dot_plainPKfS0_Pfi # -- Begin function _Z24__device_stub__dot_plainPKfS0_Pfi
	.p2align	4
	.type	_Z24__device_stub__dot_plainPKfS0_Pfi,@function
_Z24__device_stub__dot_plainPKfS0_Pfi:  # @_Z24__device_stub__dot_plainPKfS0_Pfi
	.cfi_startproc
# %bb.0:
	subq	$120, %rsp
	.cfi_def_cfa_offset 128
	movq	%rdi, 72(%rsp)
	movq	%rsi, 64(%rsp)
	movq	%rdx, 56(%rsp)
	movl	%ecx, 4(%rsp)
	leaq	72(%rsp), %rax
	movq	%rax, 80(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, 88(%rsp)
	leaq	56(%rsp), %rax
	movq	%rax, 96(%rsp)
	leaq	4(%rsp), %rax
	movq	%rax, 104(%rsp)
	leaq	40(%rsp), %rdi
	leaq	24(%rsp), %rsi
	leaq	16(%rsp), %rdx
	leaq	8(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	40(%rsp), %rsi
	movl	48(%rsp), %edx
	movq	24(%rsp), %rcx
	movl	32(%rsp), %r8d
	leaq	80(%rsp), %r9
	movl	$_Z9dot_plainPKfS0_Pfi, %edi
	pushq	8(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	24(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$136, %rsp
	.cfi_adjust_cfa_offset -136
	retq
.Lfunc_end0:
	.size	_Z24__device_stub__dot_plainPKfS0_Pfi, .Lfunc_end0-_Z24__device_stub__dot_plainPKfS0_Pfi
	.cfi_endproc
                                        # -- End function
	.globl	_Z28__device_stub__dot_annotatedPKfS0_Pfi # -- Begin function _Z28__device_stub__dot_annotatedPKfS0_Pfi
	.p2align	4
	.type	_Z28__device_stub__dot_annotatedPKfS0_Pfi,@function
_Z28__device_stub__dot_annotatedPKfS0_Pfi: # @_Z28__device_stub__dot_annotatedPKfS0_Pfi
	.cfi_startproc
# %bb.0:
	subq	$120, %rsp
	.cfi_def_cfa_offset 128
	movq	%rdi, 72(%rsp)
	movq	%rsi, 64(%rsp)
	movq	%rdx, 56(%rsp)
	movl	%ecx, 4(%rsp)
	leaq	72(%rsp), %rax
	movq	%rax, 80(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, 88(%rsp)
	leaq	56(%rsp), %rax
	movq	%rax, 96(%rsp)
	leaq	4(%rsp), %rax
	movq	%rax, 104(%rsp)
	leaq	40(%rsp), %rdi
	leaq	24(%rsp), %rsi
	leaq	16(%rsp), %rdx
	leaq	8(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	40(%rsp), %rsi
	movl	48(%rsp), %edx
	movq	24(%rsp), %rcx
	movl	32(%rsp), %r8d
	leaq	80(%rsp), %r9
	movl	$_Z13dot_annotatedPKfS0_Pfi, %edi
	pushq	8(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	24(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$136, %rsp
	.cfi_adjust_cfa_offset -136
	retq
.Lfunc_end1:
	.size	_Z28__device_stub__dot_annotatedPKfS0_Pfi, .Lfunc_end1-_Z28__device_stub__dot_annotatedPKfS0_Pfi
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2, 0x0                          # -- Begin function main
.LCPI2_0:
	.long	0x3a83126f                      # float 0.00100000005
.LCPI2_1:
	.long	0x3b03126f                      # float 0.00200000009
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0
.LCPI2_2:
	.long	2                               # 0x2
	.long	2                               # 0x2
	.long	2                               # 0x2
	.long	2                               # 0x2
	.text
	.globl	main
	.p2align	4
	.type	main,@function
main:                                   # @main
.Lfunc_begin0:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception0
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$40, %rsp
	.cfi_def_cfa_offset 96
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movl	$4194304, %edi                  # imm = 0x400000
	callq	_Znwm
	movq	%rax, %rbx
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
.Ltmp0:                                 # EH_LABEL
	movl	$4194304, %edi                  # imm = 0x400000
	callq	_Znwm
.Ltmp1:                                 # EH_LABEL
# %bb.1:
	movq	%rax, %r14
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
.Ltmp3:                                 # EH_LABEL
	movl	$1024, %edi                     # imm = 0x400
	callq	_Znwm
.Ltmp4:                                 # EH_LABEL
# %bb.2:
	movq	%rax, %r15
	movl	$1024, %edx                     # imm = 0x400
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
.Ltmp6:                                 # EH_LABEL
	movl	$1024, %edi                     # imm = 0x400
	callq	_Znwm
.Ltmp7:                                 # EH_LABEL
# %bb.3:
	movq	%rax, %r12
	xorl	%r13d, %r13d
	movl	$1024, %edx                     # imm = 0x400
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
	.p2align	4
.LBB2_4:                                # =>This Inner Loop Header: Depth=1
	xorps	%xmm0, %xmm0
	cvtsi2ss	%r13d, %xmm0
	movss	%xmm0, 4(%rsp)                  # 4-byte Spill
	movss	.LCPI2_0(%rip), %xmm1           # xmm1 = [1.00000005E-3,0.0E+0,0.0E+0,0.0E+0]
	mulss	%xmm1, %xmm0
	callq	sinf
	movss	%xmm0, (%rbx,%r13,4)
	movss	.LCPI2_1(%rip), %xmm0           # xmm0 = [2.00000009E-3,0.0E+0,0.0E+0,0.0E+0]
	movss	4(%rsp), %xmm1                  # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	mulss	%xmm0, %xmm1
	movaps	%xmm1, %xmm0
	callq	cosf
	leal	1(%r13), %eax
	xorps	%xmm1, %xmm1
	cvtsi2ss	%eax, %xmm1
	movss	%xmm1, 4(%rsp)                  # 4-byte Spill
	movss	%xmm0, (%r14,%r13,4)
	movaps	%xmm1, %xmm0
	mulss	.LCPI2_0(%rip), %xmm0
	callq	sinf
	movss	%xmm0, 4(%rbx,%r13,4)
	movss	4(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	mulss	.LCPI2_1(%rip), %xmm0
	callq	cosf
	movss	%xmm0, 4(%r14,%r13,4)
	addq	$2, %r13
	cmpq	$1048576, %r13                  # imm = 0x100000
	jne	.LBB2_4
# %bb.5:
.Ltmp9:                                 # EH_LABEL
	leaq	16(%rsp), %rdi
	movl	$4194304, %esi                  # imm = 0x400000
	callq	hipMalloc
.Ltmp10:                                # EH_LABEL
# %bb.6:
	testl	%eax, %eax
	je	.LBB2_13
# %bb.7:
.Ltmp11:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp12:                                # EH_LABEL
# %bb.8:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$83, %edx
	jmp	.LBB2_9
.LBB2_13:
.Ltmp14:                                # EH_LABEL
	leaq	8(%rsp), %rdi
	movl	$4194304, %esi                  # imm = 0x400000
	callq	hipMalloc
.Ltmp15:                                # EH_LABEL
# %bb.14:
	testl	%eax, %eax
	je	.LBB2_17
# %bb.15:
.Ltmp16:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp17:                                # EH_LABEL
# %bb.16:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$84, %edx
	jmp	.LBB2_9
.LBB2_17:
.Ltmp19:                                # EH_LABEL
	leaq	32(%rsp), %rdi
	movl	$1024, %esi                     # imm = 0x400
	callq	hipMalloc
.Ltmp20:                                # EH_LABEL
# %bb.18:
	testl	%eax, %eax
	je	.LBB2_21
# %bb.19:
.Ltmp21:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp22:                                # EH_LABEL
# %bb.20:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$85, %edx
	jmp	.LBB2_9
.LBB2_21:
.Ltmp24:                                # EH_LABEL
	leaq	24(%rsp), %rdi
	movl	$1024, %esi                     # imm = 0x400
	callq	hipMalloc
.Ltmp25:                                # EH_LABEL
# %bb.22:
	testl	%eax, %eax
	je	.LBB2_25
# %bb.23:
.Ltmp26:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp27:                                # EH_LABEL
# %bb.24:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$86, %edx
	jmp	.LBB2_9
.LBB2_25:
	movq	16(%rsp), %rdi
.Ltmp29:                                # EH_LABEL
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rbx, %rsi
	movl	$1, %ecx
	callq	hipMemcpy
.Ltmp30:                                # EH_LABEL
# %bb.26:
	testl	%eax, %eax
	je	.LBB2_29
# %bb.27:
.Ltmp31:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp32:                                # EH_LABEL
# %bb.28:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$87, %edx
	jmp	.LBB2_9
.LBB2_29:
	movq	8(%rsp), %rdi
.Ltmp34:                                # EH_LABEL
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%r14, %rsi
	movl	$1, %ecx
	callq	hipMemcpy
.Ltmp35:                                # EH_LABEL
# %bb.30:
	testl	%eax, %eax
	je	.LBB2_33
# %bb.31:
.Ltmp36:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp37:                                # EH_LABEL
# %bb.32:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$88, %edx
	jmp	.LBB2_9
.LBB2_33:
.Ltmp39:                                # EH_LABEL
	movabsq	$4294967552, %rdi               # imm = 0x100000100
	movl	$1, %esi
	movq	%rdi, %rdx
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
.Ltmp40:                                # EH_LABEL
# %bb.34:
	testl	%eax, %eax
	jne	.LBB2_36
# %bb.35:
	movq	16(%rsp), %rdi
	movq	8(%rsp), %rsi
	movq	32(%rsp), %rdx
.Ltmp41:                                # EH_LABEL
	movl	$256, %ecx                      # imm = 0x100
	callq	_Z24__device_stub__dot_plainPKfS0_Pfi
.Ltmp42:                                # EH_LABEL
.LBB2_36:
.Ltmp43:                                # EH_LABEL
	movabsq	$4294967552, %rdi               # imm = 0x100000100
	movl	$1, %esi
	movq	%rdi, %rdx
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
.Ltmp44:                                # EH_LABEL
# %bb.37:
	testl	%eax, %eax
	jne	.LBB2_39
# %bb.38:
	movq	16(%rsp), %rdi
	movq	8(%rsp), %rsi
	movq	24(%rsp), %rdx
.Ltmp45:                                # EH_LABEL
	movl	$256, %ecx                      # imm = 0x100
	callq	_Z28__device_stub__dot_annotatedPKfS0_Pfi
.Ltmp46:                                # EH_LABEL
.LBB2_39:
.Ltmp48:                                # EH_LABEL
	callq	hipDeviceSynchronize
.Ltmp49:                                # EH_LABEL
# %bb.40:
	testl	%eax, %eax
	je	.LBB2_43
# %bb.41:
.Ltmp50:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp51:                                # EH_LABEL
# %bb.42:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$92, %edx
	jmp	.LBB2_9
.LBB2_43:
	movq	32(%rsp), %rsi
.Ltmp53:                                # EH_LABEL
	movl	$1024, %edx                     # imm = 0x400
	movq	%r15, %rdi
	movl	$2, %ecx
	callq	hipMemcpy
.Ltmp54:                                # EH_LABEL
# %bb.44:
	testl	%eax, %eax
	je	.LBB2_47
# %bb.45:
.Ltmp55:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp56:                                # EH_LABEL
# %bb.46:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$93, %edx
	jmp	.LBB2_9
.LBB2_47:
	movq	24(%rsp), %rsi
.Ltmp58:                                # EH_LABEL
	movl	$1024, %edx                     # imm = 0x400
	movq	%r12, %rdi
	movl	$2, %ecx
	callq	hipMemcpy
.Ltmp59:                                # EH_LABEL
# %bb.48:
	testl	%eax, %eax
	je	.LBB2_51
# %bb.49:
.Ltmp60:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp61:                                # EH_LABEL
# %bb.50:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$94, %edx
	jmp	.LBB2_9
.LBB2_51:
	movq	16(%rsp), %rdi
.Ltmp63:                                # EH_LABEL
	callq	hipFree
.Ltmp64:                                # EH_LABEL
# %bb.52:
	testl	%eax, %eax
	je	.LBB2_55
# %bb.53:
.Ltmp65:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp66:                                # EH_LABEL
# %bb.54:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$95, %edx
	jmp	.LBB2_9
.LBB2_55:
	movq	8(%rsp), %rdi
.Ltmp68:                                # EH_LABEL
	callq	hipFree
.Ltmp69:                                # EH_LABEL
# %bb.56:
	testl	%eax, %eax
	je	.LBB2_59
# %bb.57:
.Ltmp70:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp71:                                # EH_LABEL
# %bb.58:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$96, %edx
	jmp	.LBB2_9
.LBB2_59:
	movq	32(%rsp), %rdi
.Ltmp73:                                # EH_LABEL
	callq	hipFree
.Ltmp74:                                # EH_LABEL
# %bb.60:
	testl	%eax, %eax
	je	.LBB2_63
# %bb.61:
.Ltmp75:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp76:                                # EH_LABEL
# %bb.62:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$97, %edx
	jmp	.LBB2_9
.LBB2_63:
	movq	24(%rsp), %rdi
.Ltmp78:                                # EH_LABEL
	callq	hipFree
.Ltmp79:                                # EH_LABEL
# %bb.64:
	testl	%eax, %eax
	je	.LBB2_65
# %bb.69:
.Ltmp80:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp81:                                # EH_LABEL
# %bb.70:
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$98, %edx
.LBB2_9:
	xorl	%eax, %eax
	callq	printf
	movl	$1, %ebp
.LBB2_68:
	movl	$1024, %esi                     # imm = 0x400
	movq	%r12, %rdi
	callq	_ZdlPvm
	movl	$1024, %esi                     # imm = 0x400
	movq	%r15, %rdi
	callq	_ZdlPvm
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%r14, %rdi
	callq	_ZdlPvm
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%rbx, %rdi
	callq	_ZdlPvm
	movl	%ebp, %eax
	addq	$40, %rsp
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB2_65:
	.cfi_def_cfa_offset 96
	xorps	%xmm1, %xmm1
	xorl	%eax, %eax
	movdqa	.LCPI2_2(%rip), %xmm0           # xmm0 = [2,2,2,2]
	pxor	%xmm2, %xmm2
.LBB2_66:                               # =>This Inner Loop Header: Depth=1
	movdqu	(%r15,%rax,4), %xmm3
	movdqu	16(%r15,%rax,4), %xmm4
	movdqu	32(%r15,%rax,4), %xmm5
	movdqu	48(%r15,%rax,4), %xmm6
	movdqu	(%r12,%rax,4), %xmm7
	pcmpeqd	%xmm3, %xmm7
	paddd	%xmm1, %xmm7
	movdqu	16(%r12,%rax,4), %xmm3
	pcmpeqd	%xmm4, %xmm3
	paddd	%xmm2, %xmm3
	movdqu	32(%r12,%rax,4), %xmm1
	pcmpeqd	%xmm5, %xmm1
	movdqu	48(%r12,%rax,4), %xmm2
	pcmpeqd	%xmm6, %xmm2
	paddd	%xmm0, %xmm1
	paddd	%xmm7, %xmm1
	paddd	%xmm0, %xmm2
	paddd	%xmm3, %xmm2
	addq	$16, %rax
	cmpq	$256, %rax                      # imm = 0x100
	jne	.LBB2_66
# %bb.67:
	paddd	%xmm1, %xmm2
	pshufd	$238, %xmm2, %xmm0              # xmm0 = xmm2[2,3,2,3]
	paddd	%xmm2, %xmm0
	pshufd	$85, %xmm0, %xmm1               # xmm1 = xmm0[1,1,1,1]
	paddd	%xmm0, %xmm1
	movd	%xmm1, %edx
	xorl	%ebp, %ebp
	testl	%edx, %edx
	setne	%bpl
	movl	$.L.str.2, %eax
	movl	$.L.str.3, %esi
	cmovneq	%rax, %rsi
	movl	$.L.str.1, %edi
	movl	$256, %ecx                      # imm = 0x100
	xorl	%eax, %eax
	callq	printf
	jmp	.LBB2_68
.LBB2_71:
.Ltmp82:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_88:
.Ltmp77:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_87:
.Ltmp72:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_86:
.Ltmp67:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_85:
.Ltmp62:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_84:
.Ltmp57:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_83:
.Ltmp52:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_82:
.Ltmp47:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_81:
.Ltmp38:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_80:
.Ltmp33:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_79:
.Ltmp28:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_78:
.Ltmp23:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_77:
.Ltmp18:                                # EH_LABEL
	jmp	.LBB2_73
.LBB2_12:
.Ltmp8:                                 # EH_LABEL
	movq	%rax, %r13
	jmp	.LBB2_74
.LBB2_11:
.Ltmp5:                                 # EH_LABEL
	movq	%rax, %r13
	jmp	.LBB2_75
.LBB2_10:
.Ltmp2:                                 # EH_LABEL
	movq	%rax, %r13
	jmp	.LBB2_76
.LBB2_72:
.Ltmp13:                                # EH_LABEL
.LBB2_73:
	movq	%rax, %r13
	movl	$1024, %esi                     # imm = 0x400
	movq	%r12, %rdi
	callq	_ZdlPvm
.LBB2_74:
	movl	$1024, %esi                     # imm = 0x400
	movq	%r15, %rdi
	callq	_ZdlPvm
.LBB2_75:
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%r14, %rdi
	callq	_ZdlPvm
.LBB2_76:
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%rbx, %rdi
	callq	_ZdlPvm
	movq	%r13, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end2:
	.size	main, .Lfunc_end2-main
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table2:
.Lexception0:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end0-.Lcst_begin0
.Lcst_begin0:
	.uleb128 .Lfunc_begin0-.Lfunc_begin0    # >> Call Site 1 <<
	.uleb128 .Ltmp0-.Lfunc_begin0           #   Call between .Lfunc_begin0 and .Ltmp0
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp0-.Lfunc_begin0           # >> Call Site 2 <<
	.uleb128 .Ltmp1-.Ltmp0                  #   Call between .Ltmp0 and .Ltmp1
	.uleb128 .Ltmp2-.Lfunc_begin0           #     jumps to .Ltmp2
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp1-.Lfunc_begin0           # >> Call Site 3 <<
	.uleb128 .Ltmp3-.Ltmp1                  #   Call between .Ltmp1 and .Ltmp3
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp3-.Lfunc_begin0           # >> Call Site 4 <<
	.uleb128 .Ltmp4-.Ltmp3                  #   Call between .Ltmp3 and .Ltmp4
	.uleb128 .Ltmp5-.Lfunc_begin0           #     jumps to .Ltmp5
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp4-.Lfunc_begin0           # >> Call Site 5 <<
	.uleb128 .Ltmp6-.Ltmp4                  #   Call between .Ltmp4 and .Ltmp6
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp6-.Lfunc_begin0           # >> Call Site 6 <<
	.uleb128 .Ltmp7-.Ltmp6                  #   Call between .Ltmp6 and .Ltmp7
	.uleb128 .Ltmp8-.Lfunc_begin0           #     jumps to .Ltmp8
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp7-.Lfunc_begin0           # >> Call Site 7 <<
	.uleb128 .Ltmp9-.Ltmp7                  #   Call between .Ltmp7 and .Ltmp9
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp9-.Lfunc_begin0           # >> Call Site 8 <<
	.uleb128 .Ltmp12-.Ltmp9                 #   Call between .Ltmp9 and .Ltmp12
	.uleb128 .Ltmp13-.Lfunc_begin0          #     jumps to .Ltmp13
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp14-.Lfunc_begin0          # >> Call Site 9 <<
	.uleb128 .Ltmp17-.Ltmp14                #   Call between .Ltmp14 and .Ltmp17
	.uleb128 .Ltmp18-.Lfunc_begin0          #     jumps to .Ltmp18
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp19-.Lfunc_begin0          # >> Call Site 10 <<
	.uleb128 .Ltmp22-.Ltmp19                #   Call between .Ltmp19 and .Ltmp22
	.uleb128 .Ltmp23-.Lfunc_begin0          #     jumps to .Ltmp23
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp24-.Lfunc_begin0          # >> Call Site 11 <<
	.uleb128 .Ltmp27-.Ltmp24                #   Call between .Ltmp24 and .Ltmp27
	.uleb128 .Ltmp28-.Lfunc_begin0          #     jumps to .Ltmp28
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp29-.Lfunc_begin0          # >> Call Site 12 <<
	.uleb128 .Ltmp32-.Ltmp29                #   Call between .Ltmp29 and .Ltmp32
	.uleb128 .Ltmp33-.Lfunc_begin0          #     jumps to .Ltmp33
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp34-.Lfunc_begin0          # >> Call Site 13 <<
	.uleb128 .Ltmp37-.Ltmp34                #   Call between .Ltmp34 and .Ltmp37
	.uleb128 .Ltmp38-.Lfunc_begin0          #     jumps to .Ltmp38
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp39-.Lfunc_begin0          # >> Call Site 14 <<
	.uleb128 .Ltmp46-.Ltmp39                #   Call between .Ltmp39 and .Ltmp46
	.uleb128 .Ltmp47-.Lfunc_begin0          #     jumps to .Ltmp47
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp48-.Lfunc_begin0          # >> Call Site 15 <<
	.uleb128 .Ltmp51-.Ltmp48                #   Call between .Ltmp48 and .Ltmp51
	.uleb128 .Ltmp52-.Lfunc_begin0          #     jumps to .Ltmp52
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp53-.Lfunc_begin0          # >> Call Site 16 <<
	.uleb128 .Ltmp56-.Ltmp53                #   Call between .Ltmp53 and .Ltmp56
	.uleb128 .Ltmp57-.Lfunc_begin0          #     jumps to .Ltmp57
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp58-.Lfunc_begin0          # >> Call Site 17 <<
	.uleb128 .Ltmp61-.Ltmp58                #   Call between .Ltmp58 and .Ltmp61
	.uleb128 .Ltmp62-.Lfunc_begin0          #     jumps to .Ltmp62
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp63-.Lfunc_begin0          # >> Call Site 18 <<
	.uleb128 .Ltmp66-.Ltmp63                #   Call between .Ltmp63 and .Ltmp66
	.uleb128 .Ltmp67-.Lfunc_begin0          #     jumps to .Ltmp67
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp68-.Lfunc_begin0          # >> Call Site 19 <<
	.uleb128 .Ltmp71-.Ltmp68                #   Call between .Ltmp68 and .Ltmp71
	.uleb128 .Ltmp72-.Lfunc_begin0          #     jumps to .Ltmp72
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp73-.Lfunc_begin0          # >> Call Site 20 <<
	.uleb128 .Ltmp76-.Ltmp73                #   Call between .Ltmp73 and .Ltmp76
	.uleb128 .Ltmp77-.Lfunc_begin0          #     jumps to .Ltmp77
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp78-.Lfunc_begin0          # >> Call Site 21 <<
	.uleb128 .Ltmp81-.Ltmp78                #   Call between .Ltmp78 and .Ltmp81
	.uleb128 .Ltmp82-.Lfunc_begin0          #     jumps to .Ltmp82
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp81-.Lfunc_begin0          # >> Call Site 22 <<
	.uleb128 .Lfunc_end2-.Ltmp81            #   Call between .Ltmp81 and .Lfunc_end2
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end0:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	4                               # -- Begin function __hip_module_ctor
	.type	__hip_module_ctor,@function
__hip_module_ctor:                      # @__hip_module_ctor
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	subq	$32, %rsp
	.cfi_def_cfa_offset 48
	.cfi_offset %rbx, -16
	movq	__hip_gpubin_handle_6a5d713ad1b1c230(%rip), %rbx
	testq	%rbx, %rbx
	jne	.LBB3_2
# %bb.1:
	movl	$__hip_fatbin_wrapper, %edi
	callq	__hipRegisterFatBinary
	movq	%rax, %rbx
	movq	%rax, __hip_gpubin_handle_6a5d713ad1b1c230(%rip)
.LBB3_2:
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z9dot_plainPKfS0_Pfi, %esi
	movl	$.L__unnamed_1, %edx
	movl	$.L__unnamed_1, %ecx
	movq	%rbx, %rdi
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z13dot_annotatedPKfS0_Pfi, %esi
	movl	$.L__unnamed_2, %edx
	movl	$.L__unnamed_2, %ecx
	movq	%rbx, %rdi
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction
	movl	$__hip_module_dtor, %edi
	addq	$32, %rsp
	.cfi_def_cfa_offset 16
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	atexit                          # TAILCALL
.Lfunc_end3:
	.size	__hip_module_ctor, .Lfunc_end3-__hip_module_ctor
	.cfi_endproc
                                        # -- End function
	.p2align	4                               # -- Begin function __hip_module_dtor
	.type	__hip_module_dtor,@function
__hip_module_dtor:                      # @__hip_module_dtor
	.cfi_startproc
# %bb.0:
	movq	__hip_gpubin_handle_6a5d713ad1b1c230(%rip), %rdi
	testq	%rdi, %rdi
	je	.LBB4_2
# %bb.1:
	pushq	%rax
	.cfi_def_cfa_offset 16
	callq	__hipUnregisterFatBinary
	movq	$0, __hip_gpubin_handle_6a5d713ad1b1c230(%rip)
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
.LBB4_2:
	retq
.Lfunc_end4:
	.size	__hip_module_dtor, .Lfunc_end4-__hip_module_dtor
	.cfi_endproc
                                        # -- End function
	.type	_Z9dot_plainPKfS0_Pfi,@object   # @_Z9dot_plainPKfS0_Pfi
	.section	.rodata,"a",@progbits
	.globl	_Z9dot_plainPKfS0_Pfi
	.p2align	3, 0x0
_Z9dot_plainPKfS0_Pfi:
	.quad	_Z24__device_stub__dot_plainPKfS0_Pfi
	.size	_Z9dot_plainPKfS0_Pfi, 8

	.type	_Z13dot_annotatedPKfS0_Pfi,@object # @_Z13dot_annotatedPKfS0_Pfi
	.globl	_Z13dot_annotatedPKfS0_Pfi
	.p2align	3, 0x0
_Z13dot_annotatedPKfS0_Pfi:
	.quad	_Z28__device_stub__dot_annotatedPKfS0_Pfi
	.size	_Z13dot_annotatedPKfS0_Pfi, 8

	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"HIP %s @%d\n"
	.size	.L.str, 12

	.type	.L.str.1,@object                # @.str.1
.L.str.1:
	.asciz	"F1 annotated vs plain (bitwise): %s (%d/%d mismatch)\n"
	.size	.L.str.1, 54

	.type	.L.str.2,@object                # @.str.2
.L.str.2:
	.asciz	"FAIL"
	.size	.L.str.2, 5

	.type	.L.str.3,@object                # @.str.3
.L.str.3:
	.asciz	"PASS"
	.size	.L.str.3, 5

	.type	.L__unnamed_1,@object           # @0
.L__unnamed_1:
	.asciz	"_Z9dot_plainPKfS0_Pfi"
	.size	.L__unnamed_1, 22

	.type	.L__unnamed_2,@object           # @1
.L__unnamed_2:
	.asciz	"_Z13dot_annotatedPKfS0_Pfi"
	.size	.L__unnamed_2, 27

	.type	__hip_fatbin_wrapper,@object    # @__hip_fatbin_wrapper
	.section	.hipFatBinSegment,"a",@progbits
	.p2align	3, 0x0
__hip_fatbin_wrapper:
	.long	1212764230                      # 0x48495046
	.long	1                               # 0x1
	.quad	__hip_fatbin_6a5d713ad1b1c230
	.quad	0
	.size	__hip_fatbin_wrapper, 24

	.type	__hip_gpubin_handle_6a5d713ad1b1c230,@object # @__hip_gpubin_handle_6a5d713ad1b1c230
	.local	__hip_gpubin_handle_6a5d713ad1b1c230
	.comm	__hip_gpubin_handle_6a5d713ad1b1c230,8,8
	.section	.init_array,"aw",@init_array
	.p2align	3, 0x0
	.quad	__hip_module_ctor
	.type	__hip_cuid_6a5d713ad1b1c230,@object # @__hip_cuid_6a5d713ad1b1c230
	.bss
	.globl	__hip_cuid_6a5d713ad1b1c230
__hip_cuid_6a5d713ad1b1c230:
	.byte	0                               # 0x0
	.size	__hip_cuid_6a5d713ad1b1c230, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.4 26084 f58b06dce1f9c15707c5f808fd002e18c2accf7e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym _Z24__device_stub__dot_plainPKfS0_Pfi
	.addrsig_sym _Z28__device_stub__dot_annotatedPKfS0_Pfi
	.addrsig_sym __gxx_personality_v0
	.addrsig_sym __hip_module_ctor
	.addrsig_sym __hip_module_dtor
	.addrsig_sym _Unwind_Resume
	.addrsig_sym _Z9dot_plainPKfS0_Pfi
	.addrsig_sym _Z13dot_annotatedPKfS0_Pfi
	.addrsig_sym __hip_fatbin_6a5d713ad1b1c230
	.addrsig_sym __hip_fatbin_wrapper
	.addrsig_sym __hip_cuid_6a5d713ad1b1c230

# __CLANG_OFFLOAD_BUNDLE____END__ host-x86_64-unknown-linux-gnu-
