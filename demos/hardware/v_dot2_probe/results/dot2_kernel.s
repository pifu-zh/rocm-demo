
# __CLANG_OFFLOAD_BUNDLE____START__ hip-amdgcn-amd-amdhsa--gfx1030
	.amdgcn_target "amdgcn-amd-amdhsa--gfx1030"
	.amdhsa_code_object_version 6
	.text
	.protected	_Z19dot2_correct_kernelPKjPKfPf ; -- Begin function _Z19dot2_correct_kernelPKjPKfPf
	.globl	_Z19dot2_correct_kernelPKjPKfPf
	.p2align	8
	.type	_Z19dot2_correct_kernelPKjPKfPf,@function
_Z19dot2_correct_kernelPKjPKfPf:        ; @_Z19dot2_correct_kernelPKjPKfPf
; %bb.0:
	s_clause 0x2
	s_load_dword s0, s[4:5], 0x24
	s_load_dwordx4 s[8:11], s[4:5], 0x0
	s_load_dwordx2 s[2:3], s[4:5], 0x10
	v_lshlrev_b32_e32 v1, 2, v0
	v_mov_b32_e32 v2, 0
	s_mov_b32 s4, 0
	s_waitcnt lgkmcnt(0)
	s_and_b32 s1, s0, 0xffff
	s_lshl_b32 s5, s1, 2
	.p2align	6
.LBB0_1:                                ; =>This Inner Loop Header: Depth=1
	v_add_co_u32 v3, vcc_lo, s8, v1
	v_add_co_ci_u32_e64 v4, null, s9, v2, vcc_lo
	v_add_co_u32 v5, vcc_lo, s10, v1
	v_add_co_ci_u32_e64 v6, null, s11, v2, vcc_lo
	global_load_dword v7, v[3:4], off
	global_load_dword v5, v[5:6], off
	v_add_nc_u32_e32 v0, s1, v0
	v_add_co_u32 v3, vcc_lo, s2, v1
	v_add_co_ci_u32_e64 v4, null, s3, v2, vcc_lo
	v_add_co_u32 v1, vcc_lo, v1, s5
	v_cmp_lt_u32_e64 s0, 0xfffff, v0
	v_add_co_ci_u32_e64 v2, null, 0, v2, vcc_lo
	s_or_b32 s4, s0, s4
	s_waitcnt vmcnt(0)
	v_dot2c_f32_f16 v5, v7, v7
	global_store_dword v[3:4], v5, off
	s_andn2_b32 exec_lo, exec_lo, s4
	s_cbranch_execnz .LBB0_1
; %bb.2:
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z19dot2_correct_kernelPKjPKfPf
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 280
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
		.amdhsa_next_free_vgpr 8
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
.Lfunc_end0:
	.size	_Z19dot2_correct_kernelPKjPKfPf, .Lfunc_end0-_Z19dot2_correct_kernelPKjPKfPf
                                        ; -- End function
	.set _Z19dot2_correct_kernelPKjPKfPf.num_vgpr, 8
	.set _Z19dot2_correct_kernelPKjPKfPf.num_agpr, 0
	.set _Z19dot2_correct_kernelPKjPKfPf.numbered_sgpr, 12
	.set _Z19dot2_correct_kernelPKjPKfPf.num_named_barrier, 0
	.set _Z19dot2_correct_kernelPKjPKfPf.private_seg_size, 0
	.set _Z19dot2_correct_kernelPKjPKfPf.uses_vcc, 1
	.set _Z19dot2_correct_kernelPKjPKfPf.uses_flat_scratch, 0
	.set _Z19dot2_correct_kernelPKjPKfPf.has_dyn_sized_stack, 0
	.set _Z19dot2_correct_kernelPKjPKfPf.has_recursion, 0
	.set _Z19dot2_correct_kernelPKjPKfPf.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 192
; TotalNumSgprs: 14
; NumVgprs: 8
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 14
; NumVGPRsForWavesPerEU: 8
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
	.protected	_Z22dot2_throughput_kernelPKiPfi ; -- Begin function _Z22dot2_throughput_kernelPKiPfi
	.globl	_Z22dot2_throughput_kernelPKiPfi
	.p2align	8
	.type	_Z22dot2_throughput_kernelPKiPfi,@function
_Z22dot2_throughput_kernelPKiPfi:       ; @_Z22dot2_throughput_kernelPKiPfi
; %bb.0:
	s_load_dwordx4 s[0:3], s[4:5], 0x0
	v_lshlrev_b32_e32 v0, 2, v0
	s_load_dword s4, s[4:5], 0x10
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v0, s[0:1]
	s_cmp_lt_i32 s4, 1
	s_waitcnt vmcnt(0)
	v_mul_hi_i32 v2, 0x92492493, v1
	v_add_nc_u32_e32 v2, v2, v1
	v_lshrrev_b32_e32 v3, 31, v2
	v_ashrrev_i32_e32 v2, 2, v2
	v_add_nc_u32_e32 v2, v2, v3
	v_mul_lo_u32 v2, v2, 7
	v_sub_nc_u32_e32 v1, v1, v2
	v_mov_b32_e32 v2, 0
	v_add_nc_u32_e32 v1, 1, v1
	v_cvt_f32_i32_e32 v1, v1
	s_cbranch_scc1 .LBB1_3
; %bb.1:
	v_mov_b32_e32 v2, 0
	s_mov_b32 s0, 0
.LBB1_2:                                ; =>This Inner Loop Header: Depth=1
	s_and_b32 s1, s0, 0x7ff
	v_mul_f32_e32 v2, 0xda24260, v2
	s_add_i32 s1, s1, 0x3c003c00
	v_add_f32_e32 v1, 0xda24260, v1
	v_mov_b32_e32 v3, s1
	s_add_i32 s0, s0, 1
	s_cmp_eq_u32 s4, s0
	v_dot2c_f32_f16 v2, s1, v3
	s_cbranch_scc0 .LBB1_2
.LBB1_3:
	v_add_f32_e32 v1, v2, v1
	global_store_dword v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z22dot2_throughput_kernelPKiPfi
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
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
		.amdhsa_system_sgpr_private_segment_wavefront_offset 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 6
		.amdhsa_reserve_vcc 0
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
	.size	_Z22dot2_throughput_kernelPKiPfi, .Lfunc_end1-_Z22dot2_throughput_kernelPKiPfi
                                        ; -- End function
	.set _Z22dot2_throughput_kernelPKiPfi.num_vgpr, 4
	.set _Z22dot2_throughput_kernelPKiPfi.num_agpr, 0
	.set _Z22dot2_throughput_kernelPKiPfi.numbered_sgpr, 6
	.set _Z22dot2_throughput_kernelPKiPfi.num_named_barrier, 0
	.set _Z22dot2_throughput_kernelPKiPfi.private_seg_size, 0
	.set _Z22dot2_throughput_kernelPKiPfi.uses_vcc, 0
	.set _Z22dot2_throughput_kernelPKiPfi.uses_flat_scratch, 0
	.set _Z22dot2_throughput_kernelPKiPfi.has_dyn_sized_stack, 0
	.set _Z22dot2_throughput_kernelPKiPfi.has_recursion, 0
	.set _Z22dot2_throughput_kernelPKiPfi.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 172
; TotalNumSgprs: 6
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 4
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
	.protected	_Z21fma_throughput_kernelPKiPfi ; -- Begin function _Z21fma_throughput_kernelPKiPfi
	.globl	_Z21fma_throughput_kernelPKiPfi
	.p2align	8
	.type	_Z21fma_throughput_kernelPKiPfi,@function
_Z21fma_throughput_kernelPKiPfi:        ; @_Z21fma_throughput_kernelPKiPfi
; %bb.0:
	s_load_dwordx4 s[0:3], s[4:5], 0x0
	v_lshlrev_b32_e32 v0, 2, v0
	s_load_dword s4, s[4:5], 0x10
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v0, s[0:1]
	s_cmp_lt_i32 s4, 1
	s_waitcnt vmcnt(0)
	v_mul_hi_i32 v2, 0x92492493, v1
	v_add_nc_u32_e32 v2, v2, v1
	v_lshrrev_b32_e32 v3, 31, v2
	v_ashrrev_i32_e32 v2, 2, v2
	v_add_nc_u32_e32 v2, v2, v3
	v_mul_lo_u32 v2, v2, 7
	v_sub_nc_u32_e32 v1, v1, v2
	v_mov_b32_e32 v2, 0
	v_add_nc_u32_e32 v1, 1, v1
	v_cvt_f32_i32_e32 v1, v1
	s_cbranch_scc1 .LBB2_3
; %bb.1:
	v_mov_b32_e32 v2, 0
	s_mov_b32 s0, 0
.LBB2_2:                                ; =>This Inner Loop Header: Depth=1
	s_and_b32 s1, s0, 0x7ff
	v_mul_f32_e32 v2, 0xda24260, v2
	v_cvt_f32_u32_e32 v3, s1
	v_add_f32_e32 v1, 0xda24260, v1
	s_add_i32 s0, s0, 1
	s_cmp_eq_u32 s4, s0
	v_fma_f32 v3, 0x33d6bf95, v3, 1.0
	v_fmac_f32_e32 v2, v3, v3
	s_cbranch_scc0 .LBB2_2
.LBB2_3:
	v_add_f32_e32 v1, v2, v1
	global_store_dword v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z21fma_throughput_kernelPKiPfi
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
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
		.amdhsa_system_sgpr_private_segment_wavefront_offset 0
		.amdhsa_system_sgpr_workgroup_id_x 1
		.amdhsa_system_sgpr_workgroup_id_y 0
		.amdhsa_system_sgpr_workgroup_id_z 0
		.amdhsa_system_sgpr_workgroup_info 0
		.amdhsa_system_vgpr_workitem_id 0
		.amdhsa_next_free_vgpr 4
		.amdhsa_next_free_sgpr 6
		.amdhsa_reserve_vcc 0
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
.Lfunc_end2:
	.size	_Z21fma_throughput_kernelPKiPfi, .Lfunc_end2-_Z21fma_throughput_kernelPKiPfi
                                        ; -- End function
	.set _Z21fma_throughput_kernelPKiPfi.num_vgpr, 4
	.set _Z21fma_throughput_kernelPKiPfi.num_agpr, 0
	.set _Z21fma_throughput_kernelPKiPfi.numbered_sgpr, 6
	.set _Z21fma_throughput_kernelPKiPfi.num_named_barrier, 0
	.set _Z21fma_throughput_kernelPKiPfi.private_seg_size, 0
	.set _Z21fma_throughput_kernelPKiPfi.uses_vcc, 0
	.set _Z21fma_throughput_kernelPKiPfi.uses_flat_scratch, 0
	.set _Z21fma_throughput_kernelPKiPfi.has_dyn_sized_stack, 0
	.set _Z21fma_throughput_kernelPKiPfi.has_recursion, 0
	.set _Z21fma_throughput_kernelPKiPfi.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 176
; TotalNumSgprs: 6
; NumVgprs: 4
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 4
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
	.type	__hip_cuid_3f01f50a3011088d,@object ; @__hip_cuid_3f01f50a3011088d
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_3f01f50a3011088d
__hip_cuid_3f01f50a3011088d:
	.byte	0                               ; 0x0
	.size	__hip_cuid_3f01f50a3011088d, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.4 26084 f58b06dce1f9c15707c5f808fd002e18c2accf7e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_3f01f50a3011088d
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
        .value_kind:     hidden_block_count_x
      - .offset:         28
        .size:           4
        .value_kind:     hidden_block_count_y
      - .offset:         32
        .size:           4
        .value_kind:     hidden_block_count_z
      - .offset:         36
        .size:           2
        .value_kind:     hidden_group_size_x
      - .offset:         38
        .size:           2
        .value_kind:     hidden_group_size_y
      - .offset:         40
        .size:           2
        .value_kind:     hidden_group_size_z
      - .offset:         42
        .size:           2
        .value_kind:     hidden_remainder_x
      - .offset:         44
        .size:           2
        .value_kind:     hidden_remainder_y
      - .offset:         46
        .size:           2
        .value_kind:     hidden_remainder_z
      - .offset:         64
        .size:           8
        .value_kind:     hidden_global_offset_x
      - .offset:         72
        .size:           8
        .value_kind:     hidden_global_offset_y
      - .offset:         80
        .size:           8
        .value_kind:     hidden_global_offset_z
      - .offset:         88
        .size:           2
        .value_kind:     hidden_grid_dims
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 280
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z19dot2_correct_kernelPKjPKfPf
    .private_segment_fixed_size: 0
    .sgpr_count:     14
    .sgpr_spill_count: 0
    .symbol:         _Z19dot2_correct_kernelPKjPKfPf.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     8
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 20
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z22dot2_throughput_kernelPKiPfi
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         _Z22dot2_throughput_kernelPKiPfi.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 20
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z21fma_throughput_kernelPKiPfi
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         _Z21fma_throughput_kernelPKiPfi.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     4
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
	.globl	_Z34__device_stub__dot2_correct_kernelPKjPKfPf # -- Begin function _Z34__device_stub__dot2_correct_kernelPKjPKfPf
	.p2align	4
	.type	_Z34__device_stub__dot2_correct_kernelPKjPKfPf,@function
_Z34__device_stub__dot2_correct_kernelPKjPKfPf: # @_Z34__device_stub__dot2_correct_kernelPKjPKfPf
	.cfi_startproc
# %bb.0:
	subq	$104, %rsp
	.cfi_def_cfa_offset 112
	movq	%rdi, 72(%rsp)
	movq	%rsi, 64(%rsp)
	movq	%rdx, 56(%rsp)
	leaq	72(%rsp), %rax
	movq	%rax, 80(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, 88(%rsp)
	leaq	56(%rsp), %rax
	movq	%rax, 96(%rsp)
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
	movl	$_Z19dot2_correct_kernelPKjPKfPf, %edi
	pushq	8(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	24(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$120, %rsp
	.cfi_adjust_cfa_offset -120
	retq
.Lfunc_end0:
	.size	_Z34__device_stub__dot2_correct_kernelPKjPKfPf, .Lfunc_end0-_Z34__device_stub__dot2_correct_kernelPKjPKfPf
	.cfi_endproc
                                        # -- End function
	.globl	_Z37__device_stub__dot2_throughput_kernelPKiPfi # -- Begin function _Z37__device_stub__dot2_throughput_kernelPKiPfi
	.p2align	4
	.type	_Z37__device_stub__dot2_throughput_kernelPKiPfi,@function
_Z37__device_stub__dot2_throughput_kernelPKiPfi: # @_Z37__device_stub__dot2_throughput_kernelPKiPfi
	.cfi_startproc
# %bb.0:
	subq	$104, %rsp
	.cfi_def_cfa_offset 112
	movq	%rdi, 72(%rsp)
	movq	%rsi, 64(%rsp)
	movl	%edx, 12(%rsp)
	leaq	72(%rsp), %rax
	movq	%rax, 80(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, 88(%rsp)
	leaq	12(%rsp), %rax
	movq	%rax, 96(%rsp)
	leaq	48(%rsp), %rdi
	leaq	32(%rsp), %rsi
	leaq	24(%rsp), %rdx
	leaq	16(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	48(%rsp), %rsi
	movl	56(%rsp), %edx
	movq	32(%rsp), %rcx
	movl	40(%rsp), %r8d
	leaq	80(%rsp), %r9
	movl	$_Z22dot2_throughput_kernelPKiPfi, %edi
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	32(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$120, %rsp
	.cfi_adjust_cfa_offset -120
	retq
.Lfunc_end1:
	.size	_Z37__device_stub__dot2_throughput_kernelPKiPfi, .Lfunc_end1-_Z37__device_stub__dot2_throughput_kernelPKiPfi
	.cfi_endproc
                                        # -- End function
	.globl	_Z36__device_stub__fma_throughput_kernelPKiPfi # -- Begin function _Z36__device_stub__fma_throughput_kernelPKiPfi
	.p2align	4
	.type	_Z36__device_stub__fma_throughput_kernelPKiPfi,@function
_Z36__device_stub__fma_throughput_kernelPKiPfi: # @_Z36__device_stub__fma_throughput_kernelPKiPfi
	.cfi_startproc
# %bb.0:
	subq	$104, %rsp
	.cfi_def_cfa_offset 112
	movq	%rdi, 72(%rsp)
	movq	%rsi, 64(%rsp)
	movl	%edx, 12(%rsp)
	leaq	72(%rsp), %rax
	movq	%rax, 80(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, 88(%rsp)
	leaq	12(%rsp), %rax
	movq	%rax, 96(%rsp)
	leaq	48(%rsp), %rdi
	leaq	32(%rsp), %rsi
	leaq	24(%rsp), %rdx
	leaq	16(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	48(%rsp), %rsi
	movl	56(%rsp), %edx
	movq	32(%rsp), %rcx
	movl	40(%rsp), %r8d
	leaq	80(%rsp), %r9
	movl	$_Z21fma_throughput_kernelPKiPfi, %edi
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	32(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$120, %rsp
	.cfi_adjust_cfa_offset -120
	retq
.Lfunc_end2:
	.size	_Z36__device_stub__fma_throughput_kernelPKiPfi, .Lfunc_end2-_Z36__device_stub__fma_throughput_kernelPKiPfi
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2, 0x0                          # -- Begin function main
.LCPI3_0:
	.long	0x49742400                      # float 1.0E+6
.LCPI3_1:
	.long	0xc0000000                      # float -2
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0
.LCPI3_2:
	.quad	0x3f50624dd2f1a9fc              # double 0.001
	.quad	0x3f50624dd2f1a9fc              # double 0.001
.LCPI3_3:
	.quad	0x41f86a0000000000              # double 6.5536E+9
	.quad	0x41e86a0000000000              # double 3.2768E+9
.LCPI3_4:
	.quad	0x426d1a94a2000000              # double 1.0E+12
	.quad	0x426d1a94a2000000              # double 1.0E+12
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
	subq	$88, %rsp
	.cfi_def_cfa_offset 144
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
	movabsq	$6364136223846793005, %r15      # imm = 0x5851F42D4C957F2D
	movabsq	$1442695040888963407, %r12      # imm = 0x14057B7EF767814F
	xorl	%r13d, %r13d
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
	movl	$53362, %eax                    # imm = 0xD072
	movss	.LCPI3_0(%rip), %xmm0           # xmm0 = [1.0E+6,0.0E+0,0.0E+0,0.0E+0]
	movss	.LCPI3_1(%rip), %xmm1           # xmm1 = [-2.0E+0,0.0E+0,0.0E+0,0.0E+0]
	.p2align	4
.LBB3_2:                                # =>This Inner Loop Header: Depth=1
	imulq	%r15, %rax
	addq	%r12, %rax
	movq	%rax, %rcx
	shrq	$33, %rcx
	movl	%ecx, %edx
	shrl	$3, %edx
	andl	$1023, %edx                     # imm = 0x3FF
	andl	$8380416, %ecx                  # imm = 0x7FE000
	leal	(%rdx,%rcx,8), %ecx
	addl	$1006648320, %ecx               # imm = 0x3C003C00
	movl	%ecx, (%rbx,%r13,4)
	imulq	%r15, %rax
	addq	%r12, %rax
	movq	%rax, %rcx
	shrq	$33, %rcx
	imulq	$1125898781, %rcx, %rdx         # imm = 0x431BDA1D
	shrq	$50, %rdx
	imull	$1000001, %edx, %edx            # imm = 0xF4241
	subl	%edx, %ecx
	shll	$2, %ecx
	xorps	%xmm2, %xmm2
	cvtsi2ss	%ecx, %xmm2
	divss	%xmm0, %xmm2
	addss	%xmm1, %xmm2
	movss	%xmm2, (%r14,%r13,4)
	incq	%r13
	cmpq	$1048576, %r13                  # imm = 0x100000
	jne	.LBB3_2
# %bb.3:
.Ltmp3:                                 # EH_LABEL
	leaq	40(%rsp), %rdi
	movl	$4194304, %esi                  # imm = 0x400000
	callq	hipMalloc
.Ltmp4:                                 # EH_LABEL
# %bb.4:
	testl	%eax, %eax
	je	.LBB3_8
# %bb.5:
.Ltmp5:                                 # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp6:                                 # EH_LABEL
# %bb.6:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$212, %edx
	jmp	.LBB3_7
.LBB3_8:
.Ltmp8:                                 # EH_LABEL
	leaq	80(%rsp), %rdi
	movl	$4194304, %esi                  # imm = 0x400000
	callq	hipMalloc
.Ltmp9:                                 # EH_LABEL
# %bb.9:
	testl	%eax, %eax
	je	.LBB3_12
# %bb.10:
.Ltmp10:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp11:                                # EH_LABEL
# %bb.11:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$213, %edx
	jmp	.LBB3_7
.LBB3_12:
.Ltmp13:                                # EH_LABEL
	leaq	72(%rsp), %rdi
	movl	$4194304, %esi                  # imm = 0x400000
	callq	hipMalloc
.Ltmp14:                                # EH_LABEL
# %bb.13:
	testl	%eax, %eax
	je	.LBB3_16
# %bb.14:
.Ltmp15:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp16:                                # EH_LABEL
# %bb.15:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$214, %edx
	jmp	.LBB3_7
.LBB3_16:
	movq	40(%rsp), %rdi
.Ltmp18:                                # EH_LABEL
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rbx, %rsi
	movl	$1, %ecx
	callq	hipMemcpy
.Ltmp19:                                # EH_LABEL
# %bb.17:
	testl	%eax, %eax
	je	.LBB3_20
# %bb.18:
.Ltmp20:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp21:                                # EH_LABEL
# %bb.19:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$215, %edx
	jmp	.LBB3_7
.LBB3_20:
	movq	80(%rsp), %rdi
.Ltmp23:                                # EH_LABEL
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%r14, %rsi
	movl	$1, %ecx
	callq	hipMemcpy
.Ltmp24:                                # EH_LABEL
# %bb.21:
	testl	%eax, %eax
	je	.LBB3_24
# %bb.22:
.Ltmp25:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp26:                                # EH_LABEL
# %bb.23:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$216, %edx
	jmp	.LBB3_7
.LBB3_24:
.Ltmp28:                                # EH_LABEL
	movabsq	$4294967297, %rdi               # imm = 0x100000001
	movabsq	$4294967552, %rdx               # imm = 0x100000100
	movl	$1, %esi
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
.Ltmp29:                                # EH_LABEL
# %bb.25:
	testl	%eax, %eax
	jne	.LBB3_27
# %bb.26:
	movq	40(%rsp), %rdi
	movq	80(%rsp), %rsi
	movq	72(%rsp), %rdx
.Ltmp30:                                # EH_LABEL
	callq	_Z34__device_stub__dot2_correct_kernelPKjPKfPf
.Ltmp31:                                # EH_LABEL
.LBB3_27:
.Ltmp33:                                # EH_LABEL
	callq	hipDeviceSynchronize
.Ltmp34:                                # EH_LABEL
# %bb.28:
	testl	%eax, %eax
	je	.LBB3_31
# %bb.29:
.Ltmp35:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp36:                                # EH_LABEL
# %bb.30:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$218, %edx
.LBB3_7:
	xorl	%eax, %eax
	callq	printf
	movl	$1, %ebp
	movb	$1, %r12b
.LBB3_60:
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%r14, %rdi
	callq	_ZdlPvm
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%rbx, %rdi
	callq	_ZdlPvm
	testb	%r15b, %r15b
	je	.LBB3_67
# %bb.61:
	leaq	40(%rsp), %rdi
	movl	$65536, %esi                    # imm = 0x10000
	callq	hipMalloc
	testl	%eax, %eax
	je	.LBB3_63
# %bb.62:
	movl	$252, %ebx
	jmp	.LBB3_65
.LBB3_63:
	movq	40(%rsp), %rsi
	movl	$_ZL11launch_dot2iiPf, %edi
	callq	_ZL11time_kernelPFviiPfEiiS_
	movaps	%xmm0, 16(%rsp)                 # 16-byte Spill
	movq	40(%rsp), %rsi
	movl	$_ZL10launch_fmaiiPf, %edi
	callq	_ZL11time_kernelPFviiPfEiiS_
	movaps	%xmm0, 48(%rsp)                 # 16-byte Spill
	movq	40(%rsp), %rdi
	callq	hipFree
	testl	%eax, %eax
	je	.LBB3_66
# %bb.64:
	movl	$256, %ebx                      # imm = 0x100
.LBB3_65:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	%ebx, %edx
	xorl	%eax, %eax
	callq	printf
	movl	$1, %ebp
.LBB3_67:
	movl	%ebp, %eax
	addq	$88, %rsp
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
.LBB3_66:
	.cfi_def_cfa_offset 144
	movaps	16(%rsp), %xmm0                 # 16-byte Reload
	unpcklps	48(%rsp), %xmm0                 # 16-byte Folded Reload
                                        # xmm0 = xmm0[0],mem[0],xmm0[1],mem[1]
	cvtps2pd	%xmm0, %xmm1
	movapd	.LCPI3_2(%rip), %xmm2           # xmm2 = [1.0E-3,1.0E-3]
	mulpd	%xmm1, %xmm2
	movapd	.LCPI3_3(%rip), %xmm0           # xmm0 = [6.5536E+9,3.2768E+9]
	divpd	%xmm2, %xmm0
	divpd	.LCPI3_4(%rip), %xmm0
	movapd	%xmm0, %xmm2
	unpckhpd	%xmm0, %xmm2                    # xmm2 = xmm2[1],xmm0[1]
	movapd	%xmm0, %xmm4
	divsd	%xmm2, %xmm4
	movapd	%xmm1, %xmm3
	unpckhpd	%xmm1, %xmm3                    # xmm3 = xmm3[1],xmm1[1]
	movl	$.L.str.4, %edi
	movl	$256, %esi                      # imm = 0x100
	movl	$64, %edx
	movb	$5, %al
	callq	printf
	movl	$.L.str.7, %eax
	movl	$.L.str.6, %esi
	testb	%r12b, %r12b
	cmovneq	%rax, %rsi
	movl	$.L.str.5, %edi
	xorl	%eax, %eax
	callq	printf
	xorb	$1, %r12b
	movzbl	%r12b, %ebp
	jmp	.LBB3_67
.LBB3_31:
.Ltmp38:                                # EH_LABEL
	movl	$4194304, %edi                  # imm = 0x400000
	callq	_Znwm
.Ltmp39:                                # EH_LABEL
# %bb.32:
	movq	%rax, %r13
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
	movq	72(%rsp), %rsi
.Ltmp41:                                # EH_LABEL
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%r13, %rdi
	movl	$2, %ecx
	callq	hipMemcpy
.Ltmp42:                                # EH_LABEL
# %bb.33:
	testl	%eax, %eax
	je	.LBB3_40
# %bb.34:
.Ltmp43:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp44:                                # EH_LABEL
# %bb.35:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$220, %edx
	jmp	.LBB3_36
.LBB3_40:
	movq	40(%rsp), %rdi
.Ltmp46:                                # EH_LABEL
	callq	hipFree
.Ltmp47:                                # EH_LABEL
# %bb.41:
	testl	%eax, %eax
	je	.LBB3_44
# %bb.42:
.Ltmp48:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp49:                                # EH_LABEL
# %bb.43:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$221, %edx
	jmp	.LBB3_36
.LBB3_44:
	movq	80(%rsp), %rdi
.Ltmp51:                                # EH_LABEL
	callq	hipFree
.Ltmp52:                                # EH_LABEL
# %bb.45:
	testl	%eax, %eax
	je	.LBB3_48
# %bb.46:
.Ltmp53:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp54:                                # EH_LABEL
# %bb.47:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$222, %edx
	jmp	.LBB3_36
.LBB3_48:
	movq	72(%rsp), %rdi
.Ltmp56:                                # EH_LABEL
	callq	hipFree
.Ltmp57:                                # EH_LABEL
# %bb.49:
	testl	%eax, %eax
	je	.LBB3_50
# %bb.54:
.Ltmp58:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp59:                                # EH_LABEL
# %bb.55:
	xorl	%r15d, %r15d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$223, %edx
.LBB3_36:
	xorl	%eax, %eax
	callq	printf
	movl	$1, %ebp
	movb	$1, %r12b
.LBB3_59:
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%r13, %rdi
	callq	_ZdlPvm
	jmp	.LBB3_60
.LBB3_50:
	xorl	%r15d, %r15d
	movq	%r13, 64(%rsp)                  # 8-byte Spill
	xorl	%r13d, %r13d
	xorl	%r12d, %r12d
.LBB3_51:                               # =>This Inner Loop Header: Depth=1
	movl	(%rbx,%r15,4), %ebp
	movss	(%r14,%r15,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 48(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	callq	_ZL7model_ajf
	movss	%xmm0, 16(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	movd	48(%rsp), %xmm0                 # 4-byte Folded Reload
                                        # xmm0 = mem[0],zero,zero,zero
	callq	_ZL7model_bjf
	movd	16(%rsp), %xmm1                 # 4-byte Folded Reload
                                        # xmm1 = mem[0],zero,zero,zero
	movd	%xmm1, %eax
	movq	64(%rsp), %rcx                  # 8-byte Reload
	movl	(%rcx,%r15,4), %ecx
	xorl	%edx, %edx
	cmpl	%eax, %ecx
	sete	%dl
	addq	%rdx, %r13
	movd	%xmm0, %eax
	xorl	%edx, %edx
	cmpl	%eax, %ecx
	sete	%dl
	addq	%rdx, %r12
	incq	%r15
	cmpq	$1048576, %r15                  # imm = 0x100000
	jne	.LBB3_51
# %bb.52:
	xorl	%ebp, %ebp
	movl	$.L.str.1, %edi
	movl	$1048576, %esi                  # imm = 0x100000
	movq	%r13, %rdx
	movl	$1048576, %ecx                  # imm = 0x100000
	movq	%r12, %r8
	movl	$1048576, %r9d                  # imm = 0x100000
	xorl	%eax, %eax
	callq	printf
	movb	$1, %r15b
	cmpq	$1048576, %r13                  # imm = 0x100000
	je	.LBB3_53
# %bb.57:
	cmpq	$1048576, %r12                  # imm = 0x100000
	je	.LBB3_53
# %bb.58:
	movl	$.Lstr, %edi
	callq	puts@PLT
	movl	(%rbx), %ebp
	movzwl	%bp, %edi
	callq	_ZL15f16_bits_to_f32t
	movss	%xmm0, 16(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	shrl	$16, %edi
	callq	_ZL15f16_bits_to_f32t
	movss	16(%rsp), %xmm1                 # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	cvtss2sd	%xmm1, %xmm1
	movsd	%xmm1, 16(%rsp)                 # 8-byte Spill
	cvtss2sd	%xmm0, %xmm0
	movsd	%xmm0, 48(%rsp)                 # 8-byte Spill
	movq	64(%rsp), %r13                  # 8-byte Reload
	movss	(%r13), %xmm0                   # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	movsd	%xmm0, 32(%rsp)                 # 8-byte Spill
	movss	(%r14), %xmm0                   # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 8(%rsp)                  # 4-byte Spill
	movl	%ebp, %edi
	callq	_ZL7model_ajf
	movss	%xmm0, 12(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	movss	8(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	callq	_ZL7model_bjf
	movss	12(%rsp), %xmm1                 # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	cvtss2sd	%xmm1, %xmm3
	cvtss2sd	%xmm0, %xmm4
	xorl	%r12d, %r12d
	movl	$.L.str.3, %edi
	xorl	%esi, %esi
	movsd	16(%rsp), %xmm0                 # 8-byte Reload
                                        # xmm0 = mem[0],zero
	movsd	48(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movsd	32(%rsp), %xmm2                 # 8-byte Reload
                                        # xmm2 = mem[0],zero
	movb	$5, %al
	callq	printf
	movl	4(%rbx), %ebp
	movzwl	%bp, %edi
	callq	_ZL15f16_bits_to_f32t
	movss	%xmm0, 16(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	shrl	$16, %edi
	callq	_ZL15f16_bits_to_f32t
	movss	16(%rsp), %xmm1                 # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	cvtss2sd	%xmm1, %xmm1
	movsd	%xmm1, 16(%rsp)                 # 8-byte Spill
	cvtss2sd	%xmm0, %xmm0
	movsd	%xmm0, 48(%rsp)                 # 8-byte Spill
	movss	4(%r13), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	movsd	%xmm0, 32(%rsp)                 # 8-byte Spill
	movss	4(%r14), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 8(%rsp)                  # 4-byte Spill
	movl	%ebp, %edi
	callq	_ZL7model_ajf
	movss	%xmm0, 12(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	movss	8(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	callq	_ZL7model_bjf
	movss	12(%rsp), %xmm1                 # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	xorps	%xmm3, %xmm3
	cvtss2sd	%xmm1, %xmm3
	xorps	%xmm4, %xmm4
	cvtss2sd	%xmm0, %xmm4
	movl	$.L.str.3, %edi
	movl	$1, %esi
	movsd	16(%rsp), %xmm0                 # 8-byte Reload
                                        # xmm0 = mem[0],zero
	movsd	48(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movsd	32(%rsp), %xmm2                 # 8-byte Reload
                                        # xmm2 = mem[0],zero
	movb	$5, %al
	callq	printf
	movl	8(%rbx), %ebp
	movzwl	%bp, %edi
	callq	_ZL15f16_bits_to_f32t
	movss	%xmm0, 16(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	shrl	$16, %edi
	callq	_ZL15f16_bits_to_f32t
	movss	16(%rsp), %xmm1                 # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	cvtss2sd	%xmm1, %xmm1
	movsd	%xmm1, 16(%rsp)                 # 8-byte Spill
	cvtss2sd	%xmm0, %xmm0
	movsd	%xmm0, 48(%rsp)                 # 8-byte Spill
	movss	8(%r13), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	movsd	%xmm0, 32(%rsp)                 # 8-byte Spill
	movss	8(%r14), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 8(%rsp)                  # 4-byte Spill
	movl	%ebp, %edi
	callq	_ZL7model_ajf
	movss	%xmm0, 12(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	movss	8(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	callq	_ZL7model_bjf
	movss	12(%rsp), %xmm1                 # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	xorps	%xmm3, %xmm3
	cvtss2sd	%xmm1, %xmm3
	xorps	%xmm4, %xmm4
	cvtss2sd	%xmm0, %xmm4
	movl	$.L.str.3, %edi
	movl	$2, %esi
	movsd	16(%rsp), %xmm0                 # 8-byte Reload
                                        # xmm0 = mem[0],zero
	movsd	48(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movsd	32(%rsp), %xmm2                 # 8-byte Reload
                                        # xmm2 = mem[0],zero
	movb	$5, %al
	callq	printf
	movl	12(%rbx), %ebp
	movzwl	%bp, %edi
	callq	_ZL15f16_bits_to_f32t
	movss	%xmm0, 16(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	shrl	$16, %edi
	callq	_ZL15f16_bits_to_f32t
	movss	16(%rsp), %xmm1                 # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	cvtss2sd	%xmm1, %xmm1
	movsd	%xmm1, 16(%rsp)                 # 8-byte Spill
	cvtss2sd	%xmm0, %xmm0
	movsd	%xmm0, 48(%rsp)                 # 8-byte Spill
	movss	12(%r13), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	movsd	%xmm0, 32(%rsp)                 # 8-byte Spill
	movss	12(%r14), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 8(%rsp)                  # 4-byte Spill
	movl	%ebp, %edi
	callq	_ZL7model_ajf
	movss	%xmm0, 12(%rsp)                 # 4-byte Spill
	movl	%ebp, %edi
	movss	8(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	callq	_ZL7model_bjf
	movss	12(%rsp), %xmm1                 # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	xorps	%xmm3, %xmm3
	cvtss2sd	%xmm1, %xmm3
	xorps	%xmm4, %xmm4
	cvtss2sd	%xmm0, %xmm4
	movl	$.L.str.3, %edi
	movl	$3, %esi
	movsd	16(%rsp), %xmm0                 # 8-byte Reload
                                        # xmm0 = mem[0],zero
	movsd	48(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movsd	32(%rsp), %xmm2                 # 8-byte Reload
                                        # xmm2 = mem[0],zero
	movb	$5, %al
	callq	printf
	xorl	%ebp, %ebp
	jmp	.LBB3_59
.LBB3_53:
	movb	$1, %r12b
	movq	64(%rsp), %r13                  # 8-byte Reload
	jmp	.LBB3_59
.LBB3_56:
.Ltmp60:                                # EH_LABEL
	jmp	.LBB3_39
.LBB3_80:
.Ltmp55:                                # EH_LABEL
	jmp	.LBB3_39
.LBB3_79:
.Ltmp50:                                # EH_LABEL
	jmp	.LBB3_39
.LBB3_37:
.Ltmp40:                                # EH_LABEL
	jmp	.LBB3_71
.LBB3_38:
.Ltmp45:                                # EH_LABEL
.LBB3_39:
	movq	%r13, %rdi
	movq	%rax, %r12
	movl	$4194304, %esi                  # imm = 0x400000
	callq	_ZdlPvm
	jmp	.LBB3_72
.LBB3_77:
.Ltmp32:                                # EH_LABEL
	jmp	.LBB3_71
.LBB3_78:
.Ltmp37:                                # EH_LABEL
	jmp	.LBB3_71
.LBB3_76:
.Ltmp27:                                # EH_LABEL
	jmp	.LBB3_71
.LBB3_75:
.Ltmp22:                                # EH_LABEL
	jmp	.LBB3_71
.LBB3_74:
.Ltmp17:                                # EH_LABEL
	jmp	.LBB3_71
.LBB3_73:
.Ltmp12:                                # EH_LABEL
	jmp	.LBB3_71
.LBB3_68:
.Ltmp2:                                 # EH_LABEL
	movq	%rax, %r12
	jmp	.LBB3_69
.LBB3_70:
.Ltmp7:                                 # EH_LABEL
.LBB3_71:
	movq	%rax, %r12
.LBB3_72:
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%r14, %rdi
	callq	_ZdlPvm
.LBB3_69:
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%rbx, %rdi
	callq	_ZdlPvm
	movq	%r12, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end3:
	.size	main, .Lfunc_end3-main
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table3:
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
	.uleb128 .Ltmp6-.Ltmp3                  #   Call between .Ltmp3 and .Ltmp6
	.uleb128 .Ltmp7-.Lfunc_begin0           #     jumps to .Ltmp7
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp8-.Lfunc_begin0           # >> Call Site 5 <<
	.uleb128 .Ltmp11-.Ltmp8                 #   Call between .Ltmp8 and .Ltmp11
	.uleb128 .Ltmp12-.Lfunc_begin0          #     jumps to .Ltmp12
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp13-.Lfunc_begin0          # >> Call Site 6 <<
	.uleb128 .Ltmp16-.Ltmp13                #   Call between .Ltmp13 and .Ltmp16
	.uleb128 .Ltmp17-.Lfunc_begin0          #     jumps to .Ltmp17
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp18-.Lfunc_begin0          # >> Call Site 7 <<
	.uleb128 .Ltmp21-.Ltmp18                #   Call between .Ltmp18 and .Ltmp21
	.uleb128 .Ltmp22-.Lfunc_begin0          #     jumps to .Ltmp22
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp23-.Lfunc_begin0          # >> Call Site 8 <<
	.uleb128 .Ltmp26-.Ltmp23                #   Call between .Ltmp23 and .Ltmp26
	.uleb128 .Ltmp27-.Lfunc_begin0          #     jumps to .Ltmp27
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp28-.Lfunc_begin0          # >> Call Site 9 <<
	.uleb128 .Ltmp31-.Ltmp28                #   Call between .Ltmp28 and .Ltmp31
	.uleb128 .Ltmp32-.Lfunc_begin0          #     jumps to .Ltmp32
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp33-.Lfunc_begin0          # >> Call Site 10 <<
	.uleb128 .Ltmp36-.Ltmp33                #   Call between .Ltmp33 and .Ltmp36
	.uleb128 .Ltmp37-.Lfunc_begin0          #     jumps to .Ltmp37
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp36-.Lfunc_begin0          # >> Call Site 11 <<
	.uleb128 .Ltmp38-.Ltmp36                #   Call between .Ltmp36 and .Ltmp38
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp38-.Lfunc_begin0          # >> Call Site 12 <<
	.uleb128 .Ltmp39-.Ltmp38                #   Call between .Ltmp38 and .Ltmp39
	.uleb128 .Ltmp40-.Lfunc_begin0          #     jumps to .Ltmp40
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp39-.Lfunc_begin0          # >> Call Site 13 <<
	.uleb128 .Ltmp41-.Ltmp39                #   Call between .Ltmp39 and .Ltmp41
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp41-.Lfunc_begin0          # >> Call Site 14 <<
	.uleb128 .Ltmp44-.Ltmp41                #   Call between .Ltmp41 and .Ltmp44
	.uleb128 .Ltmp45-.Lfunc_begin0          #     jumps to .Ltmp45
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp46-.Lfunc_begin0          # >> Call Site 15 <<
	.uleb128 .Ltmp49-.Ltmp46                #   Call between .Ltmp46 and .Ltmp49
	.uleb128 .Ltmp50-.Lfunc_begin0          #     jumps to .Ltmp50
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp51-.Lfunc_begin0          # >> Call Site 16 <<
	.uleb128 .Ltmp54-.Ltmp51                #   Call between .Ltmp51 and .Ltmp54
	.uleb128 .Ltmp55-.Lfunc_begin0          #     jumps to .Ltmp55
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp56-.Lfunc_begin0          # >> Call Site 17 <<
	.uleb128 .Ltmp59-.Ltmp56                #   Call between .Ltmp56 and .Ltmp59
	.uleb128 .Ltmp60-.Lfunc_begin0          #     jumps to .Ltmp60
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp59-.Lfunc_begin0          # >> Call Site 18 <<
	.uleb128 .Lfunc_end3-.Ltmp59            #   Call between .Ltmp59 and .Lfunc_end3
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end0:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	4                               # -- Begin function _ZL7model_ajf
	.type	_ZL7model_ajf,@function
_ZL7model_ajf:                          # @_ZL7model_ajf
	.cfi_startproc
# %bb.0:
                                        # kill: def $edi killed $edi def $rdi
	movl	%edi, %ecx
	shrl	$10, %ecx
	andl	$31, %ecx
	movl	%edi, %eax
	shll	$16, %eax
	andl	$-2147483648, %eax              # imm = 0x80000000
	cmpl	$31, %ecx
	je	.LBB4_3
# %bb.1:
	movl	%edi, %edx
	andl	$1023, %edx                     # imm = 0x3FF
	testl	%ecx, %ecx
	jne	.LBB4_4
# %bb.2:
	shll	$13, %edx
	orl	%edx, %eax
	jmp	.LBB4_5
.LBB4_3:
	movl	%edi, %ecx
	shll	$13, %ecx
	andl	$8380416, %ecx                  # imm = 0x7FE000
	addl	%ecx, %eax
	addl	$2139095040, %eax               # imm = 0x7F800000
	jmp	.LBB4_5
.LBB4_4:
	shll	$23, %ecx
	shll	$13, %edx
	orl	%ecx, %edx
	addl	%edx, %eax
	addl	$939524096, %eax                # imm = 0x38000000
.LBB4_5:
	movl	%edi, %ecx
	shrl	$16, %ecx
	movl	%edi, %edx
	shrl	$26, %edx
	andl	$31, %edx
	andl	$-2147483648, %edi              # imm = 0x80000000
	cmpl	$31, %edx
	je	.LBB4_8
# %bb.6:
	andl	$1023, %ecx                     # imm = 0x3FF
	testl	%edx, %edx
	jne	.LBB4_9
# %bb.7:
	shll	$13, %ecx
	orl	%edi, %ecx
	jmp	.LBB4_10
.LBB4_8:
	shll	$13, %ecx
	orl	%edi, %ecx
	orl	$2139095040, %ecx               # imm = 0x7F800000
	jmp	.LBB4_10
.LBB4_9:
	shll	$23, %edx
	shll	$13, %ecx
	orl	%edx, %ecx
	addl	%edi, %ecx
	addl	$939524096, %ecx                # imm = 0x38000000
.LBB4_10:
	movd	%eax, %xmm1
	movd	%ecx, %xmm2
	mulss	%xmm1, %xmm1
	mulss	%xmm2, %xmm2
	addss	%xmm2, %xmm0
	addss	%xmm1, %xmm0
	retq
.Lfunc_end4:
	.size	_ZL7model_ajf, .Lfunc_end4-_ZL7model_ajf
	.cfi_endproc
                                        # -- End function
	.p2align	4                               # -- Begin function _ZL7model_bjf
	.type	_ZL7model_bjf,@function
_ZL7model_bjf:                          # @_ZL7model_bjf
	.cfi_startproc
# %bb.0:
                                        # kill: def $edi killed $edi def $rdi
	movl	%edi, %ecx
	shrl	$10, %ecx
	andl	$31, %ecx
	movl	%edi, %eax
	shll	$16, %eax
	andl	$-2147483648, %eax              # imm = 0x80000000
	cmpl	$31, %ecx
	je	.LBB5_3
# %bb.1:
	movl	%edi, %edx
	andl	$1023, %edx                     # imm = 0x3FF
	testl	%ecx, %ecx
	jne	.LBB5_4
# %bb.2:
	shll	$13, %edx
	orl	%edx, %eax
	jmp	.LBB5_5
.LBB5_3:
	movl	%edi, %ecx
	shll	$13, %ecx
	andl	$8380416, %ecx                  # imm = 0x7FE000
	addl	%ecx, %eax
	addl	$2139095040, %eax               # imm = 0x7F800000
	jmp	.LBB5_5
.LBB5_4:
	shll	$23, %ecx
	shll	$13, %edx
	orl	%ecx, %edx
	addl	%edx, %eax
	addl	$939524096, %eax                # imm = 0x38000000
.LBB5_5:
	movl	%edi, %ecx
	shrl	$16, %ecx
	movl	%edi, %edx
	shrl	$26, %edx
	andl	$31, %edx
	andl	$-2147483648, %edi              # imm = 0x80000000
	cmpl	$31, %edx
	je	.LBB5_8
# %bb.6:
	andl	$1023, %ecx                     # imm = 0x3FF
	testl	%edx, %edx
	jne	.LBB5_9
# %bb.7:
	shll	$13, %ecx
	orl	%edi, %ecx
	jmp	.LBB5_10
.LBB5_8:
	shll	$13, %ecx
	orl	%edi, %ecx
	orl	$2139095040, %ecx               # imm = 0x7F800000
	jmp	.LBB5_10
.LBB5_9:
	shll	$23, %edx
	shll	$13, %ecx
	orl	%edx, %ecx
	addl	%edi, %ecx
	addl	$939524096, %ecx                # imm = 0x38000000
.LBB5_10:
	movd	%eax, %xmm1
	movd	%ecx, %xmm2
	mulss	%xmm2, %xmm2
	mulss	%xmm1, %xmm1
	addss	%xmm1, %xmm0
	addss	%xmm2, %xmm0
	retq
.Lfunc_end5:
	.size	_ZL7model_bjf, .Lfunc_end5-_ZL7model_bjf
	.cfi_endproc
                                        # -- End function
	.p2align	4                               # -- Begin function _ZL15f16_bits_to_f32t
	.type	_ZL15f16_bits_to_f32t,@function
_ZL15f16_bits_to_f32t:                  # @_ZL15f16_bits_to_f32t
	.cfi_startproc
# %bb.0:
                                        # kill: def $edi killed $edi def $rdi
	movl	%edi, %ecx
	shrl	$10, %ecx
	andl	$31, %ecx
	movl	%edi, %eax
	shll	$16, %eax
	andl	$-2147483648, %eax              # imm = 0x80000000
	cmpl	$31, %ecx
	je	.LBB6_3
# %bb.1:
	andl	$1023, %edi                     # imm = 0x3FF
	testl	%ecx, %ecx
	jne	.LBB6_4
# %bb.2:
	shll	$13, %edi
	orl	%edi, %eax
	movd	%eax, %xmm0
	retq
.LBB6_3:
	shll	$13, %edi
	orl	%edi, %eax
	orl	$2139095040, %eax               # imm = 0x7F800000
	movd	%eax, %xmm0
	retq
.LBB6_4:
	shll	$23, %ecx
	shll	$13, %edi
	orl	%ecx, %edi
	addl	%edi, %eax
	addl	$939524096, %eax                # imm = 0x38000000
	movd	%eax, %xmm0
	retq
.Lfunc_end6:
	.size	_ZL15f16_bits_to_f32t, .Lfunc_end6-_ZL15f16_bits_to_f32t
	.cfi_endproc
                                        # -- End function
	.p2align	4                               # -- Begin function _ZL11time_kernelPFviiPfEiiS_
	.type	_ZL11time_kernelPFviiPfEiiS_,@function
_ZL11time_kernelPFviiPfEiiS_:           # @_ZL11time_kernelPFviiPfEiiS_
	.cfi_startproc
# %bb.0:
	pushq	%r14
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	subq	$24, %rsp
	.cfi_def_cfa_offset 48
	.cfi_offset %rbx, -24
	.cfi_offset %r14, -16
	movq	%rsi, %r14
	movq	%rdi, %rbx
	leaq	16(%rsp), %rdi
	callq	hipEventCreate
	testl	%eax, %eax
	je	.LBB7_2
# %bb.1:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$154, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_2:
	leaq	8(%rsp), %rdi
	callq	hipEventCreate
	testl	%eax, %eax
	je	.LBB7_4
# %bb.3:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$155, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_4:
	movl	$64, %edi
	movl	$200000, %esi                   # imm = 0x30D40
	movq	%r14, %rdx
	callq	*%rbx
	callq	hipDeviceSynchronize
	testl	%eax, %eax
	je	.LBB7_6
# %bb.5:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$157, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_6:
	movq	16(%rsp), %rdi
	xorl	%esi, %esi
	callq	hipEventRecord
	testl	%eax, %eax
	je	.LBB7_8
# %bb.7:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$158, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_8:
	movl	$64, %edi
	movl	$200000, %esi                   # imm = 0x30D40
	movq	%r14, %rdx
	callq	*%rbx
	movq	8(%rsp), %rdi
	xorl	%esi, %esi
	callq	hipEventRecord
	testl	%eax, %eax
	je	.LBB7_10
# %bb.9:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$160, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_10:
	movq	8(%rsp), %rdi
	callq	hipEventSynchronize
	testl	%eax, %eax
	je	.LBB7_12
# %bb.11:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$161, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_12:
	movl	$0, 4(%rsp)
	movq	16(%rsp), %rsi
	movq	8(%rsp), %rdx
	leaq	4(%rsp), %rdi
	callq	hipEventElapsedTime
	testl	%eax, %eax
	je	.LBB7_14
# %bb.13:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$163, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_14:
	movq	16(%rsp), %rdi
	callq	hipEventDestroy
	testl	%eax, %eax
	je	.LBB7_16
# %bb.15:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$164, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_16:
	movq	8(%rsp), %rdi
	callq	hipEventDestroy
	testl	%eax, %eax
	je	.LBB7_18
# %bb.17:
	movl	%eax, %edi
	callq	hipGetErrorString
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$165, %edx
	xorl	%eax, %eax
	callq	printf
.LBB7_18:
	movss	4(%rsp), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	addq	$24, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end7:
	.size	_ZL11time_kernelPFviiPfEiiS_, .Lfunc_end7-_ZL11time_kernelPFviiPfEiiS_
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0                          # -- Begin function _ZL11launch_dot2iiPf
.LCPI8_0:
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
.LCPI8_1:
	.long	131                             # 0x83
	.long	131                             # 0x83
	.long	131                             # 0x83
	.long	131                             # 0x83
.LCPI8_2:
	.long	524                             # 0x20c
	.long	524                             # 0x20c
	.long	524                             # 0x20c
	.long	524                             # 0x20c
.LCPI8_3:
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
	.text
	.p2align	4
	.type	_ZL11launch_dot2iiPf,@function
_ZL11launch_dot2iiPf:                   # @_ZL11launch_dot2iiPf
.Lfunc_begin1:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception1
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%rbx
	.cfi_def_cfa_offset 40
	subq	$104, %rsp
	.cfi_def_cfa_offset 144
	.cfi_offset %rbx, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rdx, %r14
	movl	%esi, %ebx
	cmpq	$0, _ZZL11launch_dot2iiPfE5seeds(%rip)
	jne	.LBB8_10
# %bb.1:
	movl	%edi, %ebp
	.cfi_escape 0x2e, 0x00
	movl	$_ZZL11launch_dot2iiPfE5seeds, %edi
	movl	$1024, %esi                     # imm = 0x400
	callq	hipMalloc
	testl	%eax, %eax
	je	.LBB8_3
# %bb.2:
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$172, %edx
	xorl	%eax, %eax
	callq	printf
.LBB8_3:
	.cfi_escape 0x2e, 0x00
	movl	$1024, %edi                     # imm = 0x400
	callq	_Znwm
	movq	%rax, %r15
	.cfi_escape 0x2e, 0x00
	movl	$1024, %edx                     # imm = 0x400
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
	movdqa	.LCPI8_0(%rip), %xmm0           # xmm0 = [0,1,2,3]
	movl	$4, %eax
	movdqa	.LCPI8_1(%rip), %xmm1           # xmm1 = [131,131,131,131]
	movdqa	.LCPI8_2(%rip), %xmm2           # xmm2 = [524,524,524,524]
	movdqa	.LCPI8_3(%rip), %xmm3           # xmm3 = [8,8,8,8]
	.p2align	4
.LBB8_4:                                # =>This Inner Loop Header: Depth=1
	movdqa	%xmm0, %xmm4
	pmuludq	%xmm1, %xmm4
	pshufd	$232, %xmm4, %xmm4              # xmm4 = xmm4[0,2,2,3]
	pshufd	$245, %xmm0, %xmm5              # xmm5 = xmm0[1,1,3,3]
	pmuludq	%xmm1, %xmm5
	pshufd	$232, %xmm5, %xmm5              # xmm5 = xmm5[0,2,2,3]
	punpckldq	%xmm5, %xmm4            # xmm4 = xmm4[0],xmm5[0],xmm4[1],xmm5[1]
	movdqu	%xmm4, -16(%r15,%rax,4)
	paddd	%xmm2, %xmm4
	movdqu	%xmm4, (%r15,%rax,4)
	paddd	%xmm3, %xmm0
	addq	$8, %rax
	cmpq	$260, %rax                      # imm = 0x104
	jne	.LBB8_4
# %bb.5:
	movq	_ZZL11launch_dot2iiPfE5seeds(%rip), %rdi
.Ltmp61:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$1024, %edx                     # imm = 0x400
	movq	%r15, %rsi
	movl	$1, %ecx
	callq	hipMemcpy
.Ltmp62:                                # EH_LABEL
# %bb.6:
	testl	%eax, %eax
	je	.LBB8_9
# %bb.7:
.Ltmp63:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp64:                                # EH_LABEL
# %bb.8:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$175, %edx
	xorl	%eax, %eax
	callq	printf
.LBB8_9:
	.cfi_escape 0x2e, 0x00
	movl	$1024, %esi                     # imm = 0x400
	movq	%r15, %rdi
	callq	_ZdlPvm
	movl	%ebp, %edi
.LBB8_10:
	movl	%edi, %edi
	movabsq	$4294967296, %rdx               # imm = 0x100000000
	orq	%rdx, %rdi
	orq	$256, %rdx                      # imm = 0x100
	.cfi_escape 0x2e, 0x00
	movl	$1, %esi
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
	testl	%eax, %eax
	jne	.LBB8_12
# %bb.11:
	movq	_ZZL11launch_dot2iiPfE5seeds(%rip), %rax
	movq	%rax, 72(%rsp)
	movq	%r14, 64(%rsp)
	movl	%ebx, 12(%rsp)
	leaq	72(%rsp), %rax
	movq	%rax, 80(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, 88(%rsp)
	leaq	12(%rsp), %rax
	movq	%rax, 96(%rsp)
	.cfi_escape 0x2e, 0x00
	leaq	48(%rsp), %rdi
	leaq	32(%rsp), %rsi
	leaq	24(%rsp), %rdx
	leaq	16(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	48(%rsp), %rsi
	movl	56(%rsp), %edx
	movq	32(%rsp), %rcx
	movl	40(%rsp), %r8d
	.cfi_escape 0x2e, 0x10
	leaq	80(%rsp), %r9
	movl	$_Z22dot2_throughput_kernelPKiPfi, %edi
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	32(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$16, %rsp
	.cfi_adjust_cfa_offset -16
.LBB8_12:
	.cfi_escape 0x2e, 0x00
	callq	hipGetLastError
	testl	%eax, %eax
	je	.LBB8_14
# %bb.13:
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$179, %edx
	xorl	%eax, %eax
	callq	printf
.LBB8_14:
	addq	$104, %rsp
	.cfi_def_cfa_offset 40
	popq	%rbx
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB8_15:
	.cfi_def_cfa_offset 144
.Ltmp65:                                # EH_LABEL
	movq	%rax, %rbx
	.cfi_escape 0x2e, 0x00
	movl	$1024, %esi                     # imm = 0x400
	movq	%r15, %rdi
	callq	_ZdlPvm
	.cfi_escape 0x2e, 0x00
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end8:
	.size	_ZL11launch_dot2iiPf, .Lfunc_end8-_ZL11launch_dot2iiPf
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table8:
.Lexception1:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end1-.Lcst_begin1
.Lcst_begin1:
	.uleb128 .Lfunc_begin1-.Lfunc_begin1    # >> Call Site 1 <<
	.uleb128 .Ltmp61-.Lfunc_begin1          #   Call between .Lfunc_begin1 and .Ltmp61
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp61-.Lfunc_begin1          # >> Call Site 2 <<
	.uleb128 .Ltmp64-.Ltmp61                #   Call between .Ltmp61 and .Ltmp64
	.uleb128 .Ltmp65-.Lfunc_begin1          #     jumps to .Ltmp65
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp64-.Lfunc_begin1          # >> Call Site 3 <<
	.uleb128 .Lfunc_end8-.Ltmp64            #   Call between .Ltmp64 and .Lfunc_end8
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end1:
	.p2align	2, 0x0
                                        # -- End function
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0                          # -- Begin function _ZL10launch_fmaiiPf
.LCPI9_0:
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
.LCPI9_1:
	.long	131                             # 0x83
	.long	131                             # 0x83
	.long	131                             # 0x83
	.long	131                             # 0x83
.LCPI9_2:
	.long	524                             # 0x20c
	.long	524                             # 0x20c
	.long	524                             # 0x20c
	.long	524                             # 0x20c
.LCPI9_3:
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
	.text
	.p2align	4
	.type	_ZL10launch_fmaiiPf,@function
_ZL10launch_fmaiiPf:                    # @_ZL10launch_fmaiiPf
.Lfunc_begin2:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception2
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%rbx
	.cfi_def_cfa_offset 40
	subq	$104, %rsp
	.cfi_def_cfa_offset 144
	.cfi_offset %rbx, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rdx, %r14
	movl	%esi, %ebx
	cmpq	$0, _ZZL10launch_fmaiiPfE5seeds(%rip)
	jne	.LBB9_10
# %bb.1:
	movl	%edi, %ebp
	.cfi_escape 0x2e, 0x00
	movl	$_ZZL10launch_fmaiiPfE5seeds, %edi
	movl	$1024, %esi                     # imm = 0x400
	callq	hipMalloc
	testl	%eax, %eax
	je	.LBB9_3
# %bb.2:
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$184, %edx
	xorl	%eax, %eax
	callq	printf
.LBB9_3:
	.cfi_escape 0x2e, 0x00
	movl	$1024, %edi                     # imm = 0x400
	callq	_Znwm
	movq	%rax, %r15
	.cfi_escape 0x2e, 0x00
	movl	$1024, %edx                     # imm = 0x400
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
	movdqa	.LCPI9_0(%rip), %xmm0           # xmm0 = [0,1,2,3]
	movl	$4, %eax
	movdqa	.LCPI9_1(%rip), %xmm1           # xmm1 = [131,131,131,131]
	movdqa	.LCPI9_2(%rip), %xmm2           # xmm2 = [524,524,524,524]
	movdqa	.LCPI9_3(%rip), %xmm3           # xmm3 = [8,8,8,8]
	.p2align	4
.LBB9_4:                                # =>This Inner Loop Header: Depth=1
	movdqa	%xmm0, %xmm4
	pmuludq	%xmm1, %xmm4
	pshufd	$232, %xmm4, %xmm4              # xmm4 = xmm4[0,2,2,3]
	pshufd	$245, %xmm0, %xmm5              # xmm5 = xmm0[1,1,3,3]
	pmuludq	%xmm1, %xmm5
	pshufd	$232, %xmm5, %xmm5              # xmm5 = xmm5[0,2,2,3]
	punpckldq	%xmm5, %xmm4            # xmm4 = xmm4[0],xmm5[0],xmm4[1],xmm5[1]
	movdqu	%xmm4, -16(%r15,%rax,4)
	paddd	%xmm2, %xmm4
	movdqu	%xmm4, (%r15,%rax,4)
	paddd	%xmm3, %xmm0
	addq	$8, %rax
	cmpq	$260, %rax                      # imm = 0x104
	jne	.LBB9_4
# %bb.5:
	movq	_ZZL10launch_fmaiiPfE5seeds(%rip), %rdi
.Ltmp66:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$1024, %edx                     # imm = 0x400
	movq	%r15, %rsi
	movl	$1, %ecx
	callq	hipMemcpy
.Ltmp67:                                # EH_LABEL
# %bb.6:
	testl	%eax, %eax
	je	.LBB9_9
# %bb.7:
.Ltmp68:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp69:                                # EH_LABEL
# %bb.8:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$187, %edx
	xorl	%eax, %eax
	callq	printf
.LBB9_9:
	.cfi_escape 0x2e, 0x00
	movl	$1024, %esi                     # imm = 0x400
	movq	%r15, %rdi
	callq	_ZdlPvm
	movl	%ebp, %edi
.LBB9_10:
	movl	%edi, %edi
	movabsq	$4294967296, %rdx               # imm = 0x100000000
	orq	%rdx, %rdi
	orq	$256, %rdx                      # imm = 0x100
	.cfi_escape 0x2e, 0x00
	movl	$1, %esi
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
	testl	%eax, %eax
	jne	.LBB9_12
# %bb.11:
	movq	_ZZL10launch_fmaiiPfE5seeds(%rip), %rax
	movq	%rax, 72(%rsp)
	movq	%r14, 64(%rsp)
	movl	%ebx, 12(%rsp)
	leaq	72(%rsp), %rax
	movq	%rax, 80(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, 88(%rsp)
	leaq	12(%rsp), %rax
	movq	%rax, 96(%rsp)
	.cfi_escape 0x2e, 0x00
	leaq	48(%rsp), %rdi
	leaq	32(%rsp), %rsi
	leaq	24(%rsp), %rdx
	leaq	16(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	48(%rsp), %rsi
	movl	56(%rsp), %edx
	movq	32(%rsp), %rcx
	movl	40(%rsp), %r8d
	.cfi_escape 0x2e, 0x10
	leaq	80(%rsp), %r9
	movl	$_Z21fma_throughput_kernelPKiPfi, %edi
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	32(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$16, %rsp
	.cfi_adjust_cfa_offset -16
.LBB9_12:
	.cfi_escape 0x2e, 0x00
	callq	hipGetLastError
	testl	%eax, %eax
	je	.LBB9_14
# %bb.13:
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$191, %edx
	xorl	%eax, %eax
	callq	printf
.LBB9_14:
	addq	$104, %rsp
	.cfi_def_cfa_offset 40
	popq	%rbx
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB9_15:
	.cfi_def_cfa_offset 144
.Ltmp70:                                # EH_LABEL
	movq	%rax, %rbx
	.cfi_escape 0x2e, 0x00
	movl	$1024, %esi                     # imm = 0x400
	movq	%r15, %rdi
	callq	_ZdlPvm
	.cfi_escape 0x2e, 0x00
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end9:
	.size	_ZL10launch_fmaiiPf, .Lfunc_end9-_ZL10launch_fmaiiPf
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table9:
.Lexception2:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end2-.Lcst_begin2
.Lcst_begin2:
	.uleb128 .Lfunc_begin2-.Lfunc_begin2    # >> Call Site 1 <<
	.uleb128 .Ltmp66-.Lfunc_begin2          #   Call between .Lfunc_begin2 and .Ltmp66
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp66-.Lfunc_begin2          # >> Call Site 2 <<
	.uleb128 .Ltmp69-.Ltmp66                #   Call between .Ltmp66 and .Ltmp69
	.uleb128 .Ltmp70-.Lfunc_begin2          #     jumps to .Ltmp70
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp69-.Lfunc_begin2          # >> Call Site 3 <<
	.uleb128 .Lfunc_end9-.Ltmp69            #   Call between .Ltmp69 and .Lfunc_end9
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end2:
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
	movq	__hip_gpubin_handle_3f01f50a3011088d(%rip), %rbx
	testq	%rbx, %rbx
	jne	.LBB10_2
# %bb.1:
	movl	$__hip_fatbin_wrapper, %edi
	callq	__hipRegisterFatBinary
	movq	%rax, %rbx
	movq	%rax, __hip_gpubin_handle_3f01f50a3011088d(%rip)
.LBB10_2:
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z19dot2_correct_kernelPKjPKfPf, %esi
	movl	$.L__unnamed_1, %edx
	movl	$.L__unnamed_1, %ecx
	movq	%rbx, %rdi
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z22dot2_throughput_kernelPKiPfi, %esi
	movl	$.L__unnamed_2, %edx
	movl	$.L__unnamed_2, %ecx
	movq	%rbx, %rdi
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z21fma_throughput_kernelPKiPfi, %esi
	movl	$.L__unnamed_3, %edx
	movl	$.L__unnamed_3, %ecx
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
.Lfunc_end10:
	.size	__hip_module_ctor, .Lfunc_end10-__hip_module_ctor
	.cfi_endproc
                                        # -- End function
	.p2align	4                               # -- Begin function __hip_module_dtor
	.type	__hip_module_dtor,@function
__hip_module_dtor:                      # @__hip_module_dtor
	.cfi_startproc
# %bb.0:
	movq	__hip_gpubin_handle_3f01f50a3011088d(%rip), %rdi
	testq	%rdi, %rdi
	je	.LBB11_2
# %bb.1:
	pushq	%rax
	.cfi_def_cfa_offset 16
	callq	__hipUnregisterFatBinary
	movq	$0, __hip_gpubin_handle_3f01f50a3011088d(%rip)
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
.LBB11_2:
	retq
.Lfunc_end11:
	.size	__hip_module_dtor, .Lfunc_end11-__hip_module_dtor
	.cfi_endproc
                                        # -- End function
	.type	_Z19dot2_correct_kernelPKjPKfPf,@object # @_Z19dot2_correct_kernelPKjPKfPf
	.section	.rodata,"a",@progbits
	.globl	_Z19dot2_correct_kernelPKjPKfPf
	.p2align	3, 0x0
_Z19dot2_correct_kernelPKjPKfPf:
	.quad	_Z34__device_stub__dot2_correct_kernelPKjPKfPf
	.size	_Z19dot2_correct_kernelPKjPKfPf, 8

	.type	_Z22dot2_throughput_kernelPKiPfi,@object # @_Z22dot2_throughput_kernelPKiPfi
	.globl	_Z22dot2_throughput_kernelPKiPfi
	.p2align	3, 0x0
_Z22dot2_throughput_kernelPKiPfi:
	.quad	_Z37__device_stub__dot2_throughput_kernelPKiPfi
	.size	_Z22dot2_throughput_kernelPKiPfi, 8

	.type	_Z21fma_throughput_kernelPKiPfi,@object # @_Z21fma_throughput_kernelPKiPfi
	.globl	_Z21fma_throughput_kernelPKiPfi
	.p2align	3, 0x0
_Z21fma_throughput_kernelPKiPfi:
	.quad	_Z36__device_stub__fma_throughput_kernelPKiPfi
	.size	_Z21fma_throughput_kernelPKiPfi, 8

	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"HIP %s @%d\n"
	.size	.L.str, 12

	.type	.L.str.1,@object                # @.str.1
.L.str.1:
	.asciz	"F2 numeric model over %d single dot2 steps: modelA(fl32(a0b0 + fl32(a1b1+c))) exact %ld/%d, modelB(fl32(a1b1 + fl32(a0b0+c))) exact %ld/%d\n"
	.size	.L.str.1, 140

	.type	.L.str.3,@object                # @.str.3
.L.str.3:
	.asciz	"  j=%d a=%g b=%g got=%g (modelA %a, modelB %a)\n"
	.size	.L.str.3, 48

	.type	.L.str.4,@object                # @.str.4
.L.str.4:
	.asciz	"F3 throughput (f16 dot2 vs f32 fma, %d lanes x %d blocks): dot2 %.2f TMAC/s (ms %.3f), fma %.2f TMAC/s (ms %.3f), ratio %.2fx\n"
	.size	.L.str.4, 127

	.type	.L.str.5,@object                # @.str.5
.L.str.5:
	.asciz	"v_dot2_probe: %s\n"
	.size	.L.str.5, 18

	.type	.L.str.6,@object                # @.str.6
.L.str.6:
	.asciz	"FAIL"
	.size	.L.str.6, 5

	.type	.L.str.7,@object                # @.str.7
.L.str.7:
	.asciz	"PASS"
	.size	.L.str.7, 5

	.type	_ZZL11launch_dot2iiPfE5seeds,@object # @_ZZL11launch_dot2iiPfE5seeds
	.local	_ZZL11launch_dot2iiPfE5seeds
	.comm	_ZZL11launch_dot2iiPfE5seeds,8,8
	.type	_ZZL10launch_fmaiiPfE5seeds,@object # @_ZZL10launch_fmaiiPfE5seeds
	.local	_ZZL10launch_fmaiiPfE5seeds
	.comm	_ZZL10launch_fmaiiPfE5seeds,8,8
	.type	.L__unnamed_1,@object           # @0
.L__unnamed_1:
	.asciz	"_Z19dot2_correct_kernelPKjPKfPf"
	.size	.L__unnamed_1, 32

	.type	.L__unnamed_2,@object           # @1
.L__unnamed_2:
	.asciz	"_Z22dot2_throughput_kernelPKiPfi"
	.size	.L__unnamed_2, 33

	.type	.L__unnamed_3,@object           # @2
.L__unnamed_3:
	.asciz	"_Z21fma_throughput_kernelPKiPfi"
	.size	.L__unnamed_3, 32

	.type	__hip_fatbin_wrapper,@object    # @__hip_fatbin_wrapper
	.section	.hipFatBinSegment,"a",@progbits
	.p2align	3, 0x0
__hip_fatbin_wrapper:
	.long	1212764230                      # 0x48495046
	.long	1                               # 0x1
	.quad	__hip_fatbin_3f01f50a3011088d
	.quad	0
	.size	__hip_fatbin_wrapper, 24

	.type	__hip_gpubin_handle_3f01f50a3011088d,@object # @__hip_gpubin_handle_3f01f50a3011088d
	.local	__hip_gpubin_handle_3f01f50a3011088d
	.comm	__hip_gpubin_handle_3f01f50a3011088d,8,8
	.section	.init_array,"aw",@init_array
	.p2align	3, 0x0
	.quad	__hip_module_ctor
	.type	__hip_cuid_3f01f50a3011088d,@object # @__hip_cuid_3f01f50a3011088d
	.bss
	.globl	__hip_cuid_3f01f50a3011088d
__hip_cuid_3f01f50a3011088d:
	.byte	0                               # 0x0
	.size	__hip_cuid_3f01f50a3011088d, 1

	.type	.Lstr,@object                   # @str
	.section	.rodata.str1.1,"aMS",@progbits,1
.Lstr:
	.asciz	"  -> neither model bit-exact; dumping first divergence"
	.size	.Lstr, 55

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.4 26084 f58b06dce1f9c15707c5f808fd002e18c2accf7e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym _Z34__device_stub__dot2_correct_kernelPKjPKfPf
	.addrsig_sym _Z37__device_stub__dot2_throughput_kernelPKiPfi
	.addrsig_sym _Z36__device_stub__fma_throughput_kernelPKiPfi
	.addrsig_sym __gxx_personality_v0
	.addrsig_sym _ZL11launch_dot2iiPf
	.addrsig_sym _ZL10launch_fmaiiPf
	.addrsig_sym __hip_module_ctor
	.addrsig_sym __hip_module_dtor
	.addrsig_sym _Unwind_Resume
	.addrsig_sym _Z19dot2_correct_kernelPKjPKfPf
	.addrsig_sym _Z22dot2_throughput_kernelPKiPfi
	.addrsig_sym _Z21fma_throughput_kernelPKiPfi
	.addrsig_sym _ZZL11launch_dot2iiPfE5seeds
	.addrsig_sym _ZZL10launch_fmaiiPfE5seeds
	.addrsig_sym __hip_fatbin_3f01f50a3011088d
	.addrsig_sym __hip_fatbin_wrapper
	.addrsig_sym __hip_cuid_3f01f50a3011088d

# __CLANG_OFFLOAD_BUNDLE____END__ host-x86_64-unknown-linux-gnu-
