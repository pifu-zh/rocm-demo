
# __CLANG_OFFLOAD_BUNDLE____START__ hip-amdgcn-amd-amdhsa--gfx1030
	.amdgcn_target "amdgcn-amd-amdhsa--gfx1030"
	.amdhsa_code_object_version 6
	.text
	.protected	_Z22butterfly_group_kernelPKfPf ; -- Begin function _Z22butterfly_group_kernelPKfPf
	.globl	_Z22butterfly_group_kernelPKfPf
	.p2align	8
	.type	_Z22butterfly_group_kernelPKfPf,@function
_Z22butterfly_group_kernelPKfPf:        ; @_Z22butterfly_group_kernelPKfPf
; %bb.0:
	s_load_dwordx4 s[0:3], s[4:5], 0x0
	v_and_b32_e32 v0, 31, v0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v0, s[0:1]
	s_waitcnt vmcnt(0)
	ds_swizzle_b32 v2, v1 offset:swizzle(SWAP,1)
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_swizzle_b32 v2, v1 offset:swizzle(SWAP,2)
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_swizzle_b32 v2, v1 offset:swizzle(SWAP,4)
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	global_store_dword v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z22butterfly_group_kernelPKfPf
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_next_free_vgpr 3
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
.Lfunc_end0:
	.size	_Z22butterfly_group_kernelPKfPf, .Lfunc_end0-_Z22butterfly_group_kernelPKfPf
                                        ; -- End function
	.set _Z22butterfly_group_kernelPKfPf.num_vgpr, 3
	.set _Z22butterfly_group_kernelPKfPf.num_agpr, 0
	.set _Z22butterfly_group_kernelPKfPf.numbered_sgpr, 6
	.set _Z22butterfly_group_kernelPKfPf.num_named_barrier, 0
	.set _Z22butterfly_group_kernelPKfPf.private_seg_size, 0
	.set _Z22butterfly_group_kernelPKfPf.uses_vcc, 0
	.set _Z22butterfly_group_kernelPKfPf.uses_flat_scratch, 0
	.set _Z22butterfly_group_kernelPKfPf.has_dyn_sized_stack, 0
	.set _Z22butterfly_group_kernelPKfPf.has_recursion, 0
	.set _Z22butterfly_group_kernelPKfPf.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 92
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 3
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
	.protected	_Z21butterfly_wave_kernelPKfPf ; -- Begin function _Z21butterfly_wave_kernelPKfPf
	.globl	_Z21butterfly_wave_kernelPKfPf
	.p2align	8
	.type	_Z21butterfly_wave_kernelPKfPf,@function
_Z21butterfly_wave_kernelPKfPf:         ; @_Z21butterfly_wave_kernelPKfPf
; %bb.0:
	s_load_dwordx4 s[0:3], s[4:5], 0x0
	v_and_b32_e32 v0, 31, v0
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_load_dword v1, v0, s[0:1]
	s_waitcnt vmcnt(0)
	ds_swizzle_b32 v2, v1 offset:swizzle(SWAP,1)
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_swizzle_b32 v2, v1 offset:swizzle(SWAP,2)
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_swizzle_b32 v2, v1 offset:swizzle(SWAP,4)
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_swizzle_b32 v2, v1 offset:swizzle(SWAP,8)
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	ds_swizzle_b32 v2, v1 offset:swizzle(SWAP,16)
	s_waitcnt lgkmcnt(0)
	v_add_f32_e32 v1, v1, v2
	global_store_dword v0, v1, s[2:3]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z21butterfly_wave_kernelPKfPf
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 16
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
		.amdhsa_next_free_vgpr 3
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
	.size	_Z21butterfly_wave_kernelPKfPf, .Lfunc_end1-_Z21butterfly_wave_kernelPKfPf
                                        ; -- End function
	.set _Z21butterfly_wave_kernelPKfPf.num_vgpr, 3
	.set _Z21butterfly_wave_kernelPKfPf.num_agpr, 0
	.set _Z21butterfly_wave_kernelPKfPf.numbered_sgpr, 6
	.set _Z21butterfly_wave_kernelPKfPf.num_named_barrier, 0
	.set _Z21butterfly_wave_kernelPKfPf.private_seg_size, 0
	.set _Z21butterfly_wave_kernelPKfPf.uses_vcc, 0
	.set _Z21butterfly_wave_kernelPKfPf.uses_flat_scratch, 0
	.set _Z21butterfly_wave_kernelPKfPf.has_dyn_sized_stack, 0
	.set _Z21butterfly_wave_kernelPKfPf.has_recursion, 0
	.set _Z21butterfly_wave_kernelPKfPf.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 124
; TotalNumSgprs: 6
; NumVgprs: 3
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 3
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 6
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.section	.text._Z18swizzle_map_kernelILj1055EEvPj,"axG",@progbits,_Z18swizzle_map_kernelILj1055EEvPj,comdat
	.protected	_Z18swizzle_map_kernelILj1055EEvPj ; -- Begin function _Z18swizzle_map_kernelILj1055EEvPj
	.globl	_Z18swizzle_map_kernelILj1055EEvPj
	.p2align	8
	.type	_Z18swizzle_map_kernelILj1055EEvPj,@function
_Z18swizzle_map_kernelILj1055EEvPj:     ; @_Z18swizzle_map_kernelILj1055EEvPj
; %bb.0:
	v_and_b32_e32 v0, 63, v0
	s_load_dwordx2 s[0:1], s[4:5], 0x0
	ds_swizzle_b32 v1, v0 offset:swizzle(SWAP,1)
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_store_dword v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z18swizzle_map_kernelILj1055EEvPj
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 2
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
	.section	.text._Z18swizzle_map_kernelILj1055EEvPj,"axG",@progbits,_Z18swizzle_map_kernelILj1055EEvPj,comdat
.Lfunc_end2:
	.size	_Z18swizzle_map_kernelILj1055EEvPj, .Lfunc_end2-_Z18swizzle_map_kernelILj1055EEvPj
                                        ; -- End function
	.set _Z18swizzle_map_kernelILj1055EEvPj.num_vgpr, 2
	.set _Z18swizzle_map_kernelILj1055EEvPj.num_agpr, 0
	.set _Z18swizzle_map_kernelILj1055EEvPj.numbered_sgpr, 6
	.set _Z18swizzle_map_kernelILj1055EEvPj.num_named_barrier, 0
	.set _Z18swizzle_map_kernelILj1055EEvPj.private_seg_size, 0
	.set _Z18swizzle_map_kernelILj1055EEvPj.uses_vcc, 0
	.set _Z18swizzle_map_kernelILj1055EEvPj.uses_flat_scratch, 0
	.set _Z18swizzle_map_kernelILj1055EEvPj.has_dyn_sized_stack, 0
	.set _Z18swizzle_map_kernelILj1055EEvPj.has_recursion, 0
	.set _Z18swizzle_map_kernelILj1055EEvPj.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 40
; TotalNumSgprs: 6
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 2
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 6
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.section	.text._Z18swizzle_map_kernelILj2079EEvPj,"axG",@progbits,_Z18swizzle_map_kernelILj2079EEvPj,comdat
	.protected	_Z18swizzle_map_kernelILj2079EEvPj ; -- Begin function _Z18swizzle_map_kernelILj2079EEvPj
	.globl	_Z18swizzle_map_kernelILj2079EEvPj
	.p2align	8
	.type	_Z18swizzle_map_kernelILj2079EEvPj,@function
_Z18swizzle_map_kernelILj2079EEvPj:     ; @_Z18swizzle_map_kernelILj2079EEvPj
; %bb.0:
	v_and_b32_e32 v0, 63, v0
	s_load_dwordx2 s[0:1], s[4:5], 0x0
	ds_swizzle_b32 v1, v0 offset:swizzle(SWAP,2)
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_store_dword v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z18swizzle_map_kernelILj2079EEvPj
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 2
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
	.section	.text._Z18swizzle_map_kernelILj2079EEvPj,"axG",@progbits,_Z18swizzle_map_kernelILj2079EEvPj,comdat
.Lfunc_end3:
	.size	_Z18swizzle_map_kernelILj2079EEvPj, .Lfunc_end3-_Z18swizzle_map_kernelILj2079EEvPj
                                        ; -- End function
	.set _Z18swizzle_map_kernelILj2079EEvPj.num_vgpr, 2
	.set _Z18swizzle_map_kernelILj2079EEvPj.num_agpr, 0
	.set _Z18swizzle_map_kernelILj2079EEvPj.numbered_sgpr, 6
	.set _Z18swizzle_map_kernelILj2079EEvPj.num_named_barrier, 0
	.set _Z18swizzle_map_kernelILj2079EEvPj.private_seg_size, 0
	.set _Z18swizzle_map_kernelILj2079EEvPj.uses_vcc, 0
	.set _Z18swizzle_map_kernelILj2079EEvPj.uses_flat_scratch, 0
	.set _Z18swizzle_map_kernelILj2079EEvPj.has_dyn_sized_stack, 0
	.set _Z18swizzle_map_kernelILj2079EEvPj.has_recursion, 0
	.set _Z18swizzle_map_kernelILj2079EEvPj.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 40
; TotalNumSgprs: 6
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 2
; Occupancy: 16
; WaveLimiterHint : 0
; COMPUTE_PGM_RSRC2:SCRATCH_EN: 0
; COMPUTE_PGM_RSRC2:USER_SGPR: 6
; COMPUTE_PGM_RSRC2:TRAP_HANDLER: 0
; COMPUTE_PGM_RSRC2:TGID_X_EN: 1
; COMPUTE_PGM_RSRC2:TGID_Y_EN: 0
; COMPUTE_PGM_RSRC2:TGID_Z_EN: 0
; COMPUTE_PGM_RSRC2:TIDIG_COMP_CNT: 0
	.section	.text._Z18swizzle_map_kernelILj4127EEvPj,"axG",@progbits,_Z18swizzle_map_kernelILj4127EEvPj,comdat
	.protected	_Z18swizzle_map_kernelILj4127EEvPj ; -- Begin function _Z18swizzle_map_kernelILj4127EEvPj
	.globl	_Z18swizzle_map_kernelILj4127EEvPj
	.p2align	8
	.type	_Z18swizzle_map_kernelILj4127EEvPj,@function
_Z18swizzle_map_kernelILj4127EEvPj:     ; @_Z18swizzle_map_kernelILj4127EEvPj
; %bb.0:
	v_and_b32_e32 v0, 63, v0
	s_load_dwordx2 s[0:1], s[4:5], 0x0
	ds_swizzle_b32 v1, v0 offset:swizzle(SWAP,4)
	v_lshlrev_b32_e32 v0, 2, v0
	s_waitcnt lgkmcnt(0)
	global_store_dword v0, v1, s[0:1]
	s_endpgm
	.section	.rodata,"a",@progbits
	.p2align	6, 0x0
	.amdhsa_kernel _Z18swizzle_map_kernelILj4127EEvPj
		.amdhsa_group_segment_fixed_size 0
		.amdhsa_private_segment_fixed_size 0
		.amdhsa_kernarg_size 8
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
		.amdhsa_next_free_vgpr 2
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
	.section	.text._Z18swizzle_map_kernelILj4127EEvPj,"axG",@progbits,_Z18swizzle_map_kernelILj4127EEvPj,comdat
.Lfunc_end4:
	.size	_Z18swizzle_map_kernelILj4127EEvPj, .Lfunc_end4-_Z18swizzle_map_kernelILj4127EEvPj
                                        ; -- End function
	.set _Z18swizzle_map_kernelILj4127EEvPj.num_vgpr, 2
	.set _Z18swizzle_map_kernelILj4127EEvPj.num_agpr, 0
	.set _Z18swizzle_map_kernelILj4127EEvPj.numbered_sgpr, 6
	.set _Z18swizzle_map_kernelILj4127EEvPj.num_named_barrier, 0
	.set _Z18swizzle_map_kernelILj4127EEvPj.private_seg_size, 0
	.set _Z18swizzle_map_kernelILj4127EEvPj.uses_vcc, 0
	.set _Z18swizzle_map_kernelILj4127EEvPj.uses_flat_scratch, 0
	.set _Z18swizzle_map_kernelILj4127EEvPj.has_dyn_sized_stack, 0
	.set _Z18swizzle_map_kernelILj4127EEvPj.has_recursion, 0
	.set _Z18swizzle_map_kernelILj4127EEvPj.has_indirect_call, 0
	.section	.AMDGPU.csdata,"",@progbits
; Kernel info:
; codeLenInByte = 40
; TotalNumSgprs: 6
; NumVgprs: 2
; ScratchSize: 0
; MemoryBound: 0
; FloatMode: 240
; IeeeMode: 1
; LDSByteSize: 0 bytes/workgroup (compile time only)
; SGPRBlocks: 0
; VGPRBlocks: 0
; NumSGPRsForWavesPerEU: 6
; NumVGPRsForWavesPerEU: 2
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
	.type	__hip_cuid_927f9d48bcce1513,@object ; @__hip_cuid_927f9d48bcce1513
	.section	.bss,"aw",@nobits
	.globl	__hip_cuid_927f9d48bcce1513
__hip_cuid_927f9d48bcce1513:
	.byte	0                               ; 0x0
	.size	__hip_cuid_927f9d48bcce1513, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.4 26084 f58b06dce1f9c15707c5f808fd002e18c2accf7e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym __hip_cuid_927f9d48bcce1513
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z22butterfly_group_kernelPKfPf
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         _Z22butterfly_group_kernelPKfPf.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
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
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 16
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z21butterfly_wave_kernelPKfPf
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         _Z21butterfly_wave_kernelPKfPf.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     3
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z18swizzle_map_kernelILj1055EEvPj
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         _Z18swizzle_map_kernelILj1055EEvPj.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z18swizzle_map_kernelILj2079EEvPj
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         _Z18swizzle_map_kernelILj2079EEvPj.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
    .vgpr_spill_count: 0
    .wavefront_size: 32
    .workgroup_processor_mode: 1
  - .args:
      - .address_space:  global
        .offset:         0
        .size:           8
        .value_kind:     global_buffer
    .group_segment_fixed_size: 0
    .kernarg_segment_align: 8
    .kernarg_segment_size: 8
    .language:       OpenCL C
    .language_version:
      - 2
      - 0
    .max_flat_workgroup_size: 1024
    .name:           _Z18swizzle_map_kernelILj4127EEvPj
    .private_segment_fixed_size: 0
    .sgpr_count:     6
    .sgpr_spill_count: 0
    .symbol:         _Z18swizzle_map_kernelILj4127EEvPj.kd
    .uniform_work_group_size: 1
    .uses_dynamic_stack: false
    .vgpr_count:     2
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
	.globl	_Z37__device_stub__butterfly_group_kernelPKfPf # -- Begin function _Z37__device_stub__butterfly_group_kernelPKfPf
	.p2align	4
	.type	_Z37__device_stub__butterfly_group_kernelPKfPf,@function
_Z37__device_stub__butterfly_group_kernelPKfPf: # @_Z37__device_stub__butterfly_group_kernelPKfPf
	.cfi_startproc
# %bb.0:
	subq	$88, %rsp
	.cfi_def_cfa_offset 96
	movq	%rdi, 56(%rsp)
	movq	%rsi, 48(%rsp)
	leaq	56(%rsp), %rax
	movq	%rax, 64(%rsp)
	leaq	48(%rsp), %rax
	movq	%rax, 72(%rsp)
	leaq	32(%rsp), %rdi
	leaq	16(%rsp), %rsi
	leaq	8(%rsp), %rdx
	movq	%rsp, %rcx
	callq	__hipPopCallConfiguration
	movq	32(%rsp), %rsi
	movl	40(%rsp), %edx
	movq	16(%rsp), %rcx
	movl	24(%rsp), %r8d
	leaq	64(%rsp), %r9
	movl	$_Z22butterfly_group_kernelPKfPf, %edi
	pushq	(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$104, %rsp
	.cfi_adjust_cfa_offset -104
	retq
.Lfunc_end0:
	.size	_Z37__device_stub__butterfly_group_kernelPKfPf, .Lfunc_end0-_Z37__device_stub__butterfly_group_kernelPKfPf
	.cfi_endproc
                                        # -- End function
	.globl	_Z36__device_stub__butterfly_wave_kernelPKfPf # -- Begin function _Z36__device_stub__butterfly_wave_kernelPKfPf
	.p2align	4
	.type	_Z36__device_stub__butterfly_wave_kernelPKfPf,@function
_Z36__device_stub__butterfly_wave_kernelPKfPf: # @_Z36__device_stub__butterfly_wave_kernelPKfPf
	.cfi_startproc
# %bb.0:
	subq	$88, %rsp
	.cfi_def_cfa_offset 96
	movq	%rdi, 56(%rsp)
	movq	%rsi, 48(%rsp)
	leaq	56(%rsp), %rax
	movq	%rax, 64(%rsp)
	leaq	48(%rsp), %rax
	movq	%rax, 72(%rsp)
	leaq	32(%rsp), %rdi
	leaq	16(%rsp), %rsi
	leaq	8(%rsp), %rdx
	movq	%rsp, %rcx
	callq	__hipPopCallConfiguration
	movq	32(%rsp), %rsi
	movl	40(%rsp), %edx
	movq	16(%rsp), %rcx
	movl	24(%rsp), %r8d
	leaq	64(%rsp), %r9
	movl	$_Z21butterfly_wave_kernelPKfPf, %edi
	pushq	(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$104, %rsp
	.cfi_adjust_cfa_offset -104
	retq
.Lfunc_end1:
	.size	_Z36__device_stub__butterfly_wave_kernelPKfPf, .Lfunc_end1-_Z36__device_stub__butterfly_wave_kernelPKfPf
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0                          # -- Begin function main
.LCPI2_0:
	.quad	2                               # 0x2
	.quad	3                               # 0x3
.LCPI2_1:
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	1                               # 0x1
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
.LCPI2_2:
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
.LCPI2_3:
	.long	4294967199                      # 0xffffff9f
	.long	4294967199                      # 0xffffff9f
	.long	4294967199                      # 0xffffff9f
	.long	4294967199                      # 0xffffff9f
.LCPI2_4:
	.quad	-9223372034707292160            # 0x8000000080000000
	.quad	-9223372034707292160            # 0x8000000080000000
.LCPI2_5:
	.long	2147483680                      # 0x80000020
	.long	2147483680                      # 0x80000020
	.long	2147483680                      # 0x80000020
	.long	2147483680                      # 0x80000020
.LCPI2_6:
	.quad	4                               # 0x4
	.quad	4                               # 0x4
.LCPI2_7:
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
	.long	4                               # 0x4
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
	subq	$216, %rsp
	.cfi_def_cfa_offset 272
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	.cfi_escape 0x2e, 0x00
	movl	$256, %edi                      # imm = 0x100
	callq	_Znwm
	movq	%rax, %rbx
	movq	%rax, 192(%rsp)
	addq	$256, %rax                      # imm = 0x100
	movq	%rax, 208(%rsp)
	xorps	%xmm0, %xmm0
	movups	%xmm0, (%rbx)
	movups	%xmm0, 16(%rbx)
	movups	%xmm0, 32(%rbx)
	movups	%xmm0, 48(%rbx)
	movups	%xmm0, 64(%rbx)
	movups	%xmm0, 80(%rbx)
	movups	%xmm0, 96(%rbx)
	movups	%xmm0, 112(%rbx)
	movups	%xmm0, 128(%rbx)
	movups	%xmm0, 144(%rbx)
	movups	%xmm0, 160(%rbx)
	movups	%xmm0, 176(%rbx)
	movups	%xmm0, 192(%rbx)
	movups	%xmm0, 208(%rbx)
	movups	%xmm0, 224(%rbx)
	movups	%xmm0, 240(%rbx)
	movq	%rax, 200(%rsp)
.Ltmp0:                                 # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edi                      # imm = 0x100
	callq	_Znwm
.Ltmp1:                                 # EH_LABEL
# %bb.1:
	movq	%rax, %r14
	movq	%rax, 168(%rsp)
	addq	$256, %rax                      # imm = 0x100
	movq	%rax, 184(%rsp)
	xorps	%xmm0, %xmm0
	movups	%xmm0, 240(%r14)
	movups	%xmm0, 224(%r14)
	movups	%xmm0, 208(%r14)
	movups	%xmm0, 192(%r14)
	movups	%xmm0, 176(%r14)
	movups	%xmm0, 160(%r14)
	movups	%xmm0, 144(%r14)
	movups	%xmm0, 128(%r14)
	movups	%xmm0, 112(%r14)
	movups	%xmm0, 96(%r14)
	movups	%xmm0, 80(%r14)
	movups	%xmm0, 64(%r14)
	movups	%xmm0, 48(%r14)
	movups	%xmm0, 32(%r14)
	movups	%xmm0, 16(%r14)
	movups	%xmm0, (%r14)
	movq	%rax, 176(%rsp)
.Ltmp3:                                 # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edi                      # imm = 0x100
	callq	_Znwm
.Ltmp4:                                 # EH_LABEL
# %bb.2:
	movq	%rax, %r15
	movq	%rax, 144(%rsp)
	addq	$256, %rax                      # imm = 0x100
	movq	%rax, 160(%rsp)
	xorps	%xmm0, %xmm0
	movups	%xmm0, 240(%r15)
	movups	%xmm0, 224(%r15)
	movups	%xmm0, 208(%r15)
	movups	%xmm0, 192(%r15)
	movups	%xmm0, 176(%r15)
	movups	%xmm0, 160(%r15)
	movups	%xmm0, 144(%r15)
	movups	%xmm0, 128(%r15)
	movups	%xmm0, 112(%r15)
	movups	%xmm0, 96(%r15)
	movups	%xmm0, 80(%r15)
	movups	%xmm0, 64(%r15)
	movups	%xmm0, 48(%r15)
	movups	%xmm0, 32(%r15)
	movups	%xmm0, 16(%r15)
	movups	%xmm0, (%r15)
	movq	%rax, 152(%rsp)
.Ltmp6:                                 # EH_LABEL
	.cfi_escape 0x2e, 0x00
	leaq	24(%rsp), %rdi
	movl	$256, %esi                      # imm = 0x100
	callq	hipMalloc
.Ltmp7:                                 # EH_LABEL
# %bb.3:
	testl	%eax, %eax
	je	.LBB2_6
# %bb.4:
.Ltmp8:                                 # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp9:                                 # EH_LABEL
# %bb.5:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$114, %edx
	jmp	.LBB2_44
.LBB2_6:
.Ltmp11:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movabsq	$4294967297, %rdi               # imm = 0x100000001
	movabsq	$4294967360, %rdx               # imm = 0x100000040
	movl	$1, %esi
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
.Ltmp12:                                # EH_LABEL
# %bb.7:
	testl	%eax, %eax
	jne	.LBB2_10
# %bb.8:
	movq	24(%rsp), %rax
	movq	%rax, 32(%rsp)
	leaq	32(%rsp), %rax
	movq	%rax, 112(%rsp)
.Ltmp13:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	leaq	80(%rsp), %rdi
	leaq	48(%rsp), %rsi
	leaq	136(%rsp), %rdx
	leaq	128(%rsp), %rcx
	callq	__hipPopCallConfiguration
.Ltmp14:                                # EH_LABEL
# %bb.9:
	movq	80(%rsp), %rsi
	movl	88(%rsp), %edx
	movq	48(%rsp), %rcx
	movl	56(%rsp), %r8d
.Ltmp15:                                # EH_LABEL
	.cfi_escape 0x2e, 0x10
	leaq	112(%rsp), %r9
	movl	$_Z18swizzle_map_kernelILj1055EEvPj, %edi
	pushq	128(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	144(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$16, %rsp
	.cfi_adjust_cfa_offset -16
.Ltmp16:                                # EH_LABEL
.LBB2_10:
.Ltmp17:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	hipDeviceSynchronize
.Ltmp18:                                # EH_LABEL
# %bb.11:
	testl	%eax, %eax
	je	.LBB2_14
# %bb.12:
.Ltmp19:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp20:                                # EH_LABEL
# %bb.13:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$116, %edx
	jmp	.LBB2_44
.LBB2_14:
	movq	24(%rsp), %rsi
.Ltmp22:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edx                      # imm = 0x100
	movq	%rbx, %rdi
	movl	$2, %ecx
	callq	hipMemcpy
.Ltmp23:                                # EH_LABEL
# %bb.15:
	testl	%eax, %eax
	je	.LBB2_18
# %bb.16:
.Ltmp24:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp25:                                # EH_LABEL
# %bb.17:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$117, %edx
	jmp	.LBB2_44
.LBB2_18:
.Ltmp27:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movabsq	$4294967297, %rdi               # imm = 0x100000001
	movabsq	$4294967360, %rdx               # imm = 0x100000040
	movl	$1, %esi
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
.Ltmp28:                                # EH_LABEL
# %bb.19:
	testl	%eax, %eax
	jne	.LBB2_21
# %bb.20:
	movq	24(%rsp), %rdi
.Ltmp29:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	_Z33__device_stub__swizzle_map_kernelILj2079EEvPj
.Ltmp30:                                # EH_LABEL
.LBB2_21:
.Ltmp31:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	hipDeviceSynchronize
.Ltmp32:                                # EH_LABEL
# %bb.22:
	testl	%eax, %eax
	je	.LBB2_25
# %bb.23:
.Ltmp33:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp34:                                # EH_LABEL
# %bb.24:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$119, %edx
	jmp	.LBB2_44
.LBB2_25:
	movq	24(%rsp), %rsi
.Ltmp36:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edx                      # imm = 0x100
	movq	%r14, %rdi
	movl	$2, %ecx
	callq	hipMemcpy
.Ltmp37:                                # EH_LABEL
# %bb.26:
	testl	%eax, %eax
	je	.LBB2_29
# %bb.27:
.Ltmp38:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp39:                                # EH_LABEL
# %bb.28:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$120, %edx
	jmp	.LBB2_44
.LBB2_29:
.Ltmp41:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movabsq	$4294967297, %rdi               # imm = 0x100000001
	movabsq	$4294967360, %rdx               # imm = 0x100000040
	movl	$1, %esi
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
.Ltmp42:                                # EH_LABEL
# %bb.30:
	testl	%eax, %eax
	jne	.LBB2_32
# %bb.31:
	movq	24(%rsp), %rdi
.Ltmp43:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	_Z33__device_stub__swizzle_map_kernelILj4127EEvPj
.Ltmp44:                                # EH_LABEL
.LBB2_32:
.Ltmp46:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	hipDeviceSynchronize
.Ltmp47:                                # EH_LABEL
# %bb.33:
	testl	%eax, %eax
	je	.LBB2_36
# %bb.34:
.Ltmp48:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp49:                                # EH_LABEL
# %bb.35:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$122, %edx
	jmp	.LBB2_44
.LBB2_36:
	movq	24(%rsp), %rsi
.Ltmp51:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edx                      # imm = 0x100
	movq	%r15, %rdi
	movl	$2, %ecx
	callq	hipMemcpy
.Ltmp52:                                # EH_LABEL
# %bb.37:
	testl	%eax, %eax
	je	.LBB2_40
# %bb.38:
.Ltmp53:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp54:                                # EH_LABEL
# %bb.39:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$123, %edx
	jmp	.LBB2_44
.LBB2_40:
	movq	24(%rsp), %rdi
.Ltmp56:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	hipFree
.Ltmp57:                                # EH_LABEL
# %bb.41:
	testl	%eax, %eax
	je	.LBB2_46
# %bb.42:
.Ltmp58:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp59:                                # EH_LABEL
# %bb.43:
	.cfi_escape 0x2e, 0x00
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$124, %edx
.LBB2_44:
	xorl	%eax, %eax
	callq	printf
	movl	$1, %ebp
.LBB2_45:
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	%r15, %rdi
	callq	_ZdlPvm
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	%r14, %rdi
	callq	_ZdlPvm
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	%rbx, %rdi
	callq	_ZdlPvm
	movl	%ebp, %eax
	addq	$216, %rsp
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
.LBB2_46:
	.cfi_def_cfa_offset 272
	.cfi_escape 0x2e, 0x00
	leaq	192(%rsp), %rdi
	movl	$1, %esi
	callq	_ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j
	movl	%eax, 64(%rsp)                  # 4-byte Spill
	.cfi_escape 0x2e, 0x00
	leaq	168(%rsp), %rdi
	movl	$2, %esi
	callq	_ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j
	movl	%eax, %ebp
	.cfi_escape 0x2e, 0x00
	leaq	144(%rsp), %rdi
	movl	$4, %esi
	callq	_ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j
	movl	%eax, %r13d
.Ltmp61:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edi                      # imm = 0x100
	callq	_Znwm
.Ltmp62:                                # EH_LABEL
# %bb.47:
	movq	%rax, %r12
	xorps	%xmm0, %xmm0
	movups	%xmm0, 240(%rax)
	movups	%xmm0, 224(%rax)
	movups	%xmm0, 208(%rax)
	movups	%xmm0, 192(%rax)
	movups	%xmm0, 176(%rax)
	movups	%xmm0, 160(%rax)
	movups	%xmm0, 144(%rax)
	movups	%xmm0, 128(%rax)
	movups	%xmm0, 112(%rax)
	movups	%xmm0, 96(%rax)
	movups	%xmm0, 80(%rax)
	movups	%xmm0, 64(%rax)
	movups	%xmm0, 48(%rax)
	movups	%xmm0, 32(%rax)
	movups	%xmm0, 16(%rax)
	movups	%xmm0, (%rax)
.Ltmp64:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edi                      # imm = 0x100
	callq	_Znwm
.Ltmp65:                                # EH_LABEL
# %bb.48:
	addl	64(%rsp), %ebp                  # 4-byte Folded Reload
	addl	%r13d, %ebp
	xorps	%xmm0, %xmm0
	movups	%xmm0, 240(%rax)
	movups	%xmm0, 224(%rax)
	movups	%xmm0, 208(%rax)
	movups	%xmm0, 192(%rax)
	movups	%xmm0, 176(%rax)
	movups	%xmm0, 160(%rax)
	movups	%xmm0, 144(%rax)
	movups	%xmm0, 128(%rax)
	movups	%xmm0, 112(%rax)
	movups	%xmm0, 96(%rax)
	movups	%xmm0, 80(%rax)
	movups	%xmm0, 64(%rax)
	movups	%xmm0, 48(%rax)
	movups	%xmm0, 32(%rax)
	movups	%xmm0, 16(%rax)
	movq	%rax, 8(%rsp)                   # 8-byte Spill
	movups	%xmm0, (%rax)
	movaps	.LCPI2_0(%rip), %xmm0           # xmm0 = [2,3]
	movaps	.LCPI2_1(%rip), %xmm1           # xmm1 = [0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0]
	movdqa	.LCPI2_2(%rip), %xmm2           # xmm2 = [0,1,2,3]
	xorl	%eax, %eax
	movdqa	.LCPI2_3(%rip), %xmm3           # xmm3 = [4294967199,4294967199,4294967199,4294967199]
	movaps	.LCPI2_4(%rip), %xmm4           # xmm4 = [9223372039002259456,9223372039002259456]
	movdqa	.LCPI2_5(%rip), %xmm5           # xmm5 = [2147483680,2147483680,2147483680,2147483680]
	movdqa	.LCPI2_6(%rip), %xmm6           # xmm6 = [4,4]
	movdqa	.LCPI2_7(%rip), %xmm7           # xmm7 = [4,4,4,4]
	movdqa	%xmm2, %xmm8
.LBB2_49:                               # =>This Inner Loop Header: Depth=1
	movdqa	%xmm2, %xmm9
	paddd	%xmm9, %xmm9
	paddd	%xmm2, %xmm9
	paddd	%xmm3, %xmm9
	movaps	%xmm1, %xmm10
	xorps	%xmm4, %xmm10
	movaps	%xmm0, %xmm11
	xorps	%xmm4, %xmm11
	movaps	%xmm10, %xmm12
	shufps	$221, %xmm11, %xmm12            # xmm12 = xmm12[1,3],xmm11[1,3]
	pcmpeqd	%xmm4, %xmm12
	shufps	$136, %xmm11, %xmm10            # xmm10 = xmm10[0,2],xmm11[0,2]
	pcmpgtd	%xmm5, %xmm10
	pandn	%xmm12, %xmm10
	movdqa	%xmm8, %xmm11
	paddd	%xmm11, %xmm11
	paddd	%xmm8, %xmm11
	pand	%xmm10, %xmm11
	pandn	%xmm9, %xmm10
	por	%xmm11, %xmm10
	cvtdq2ps	%xmm10, %xmm9
	movups	%xmm9, (%r12,%rax,4)
	addq	$4, %rax
	paddq	%xmm6, %xmm1
	paddq	%xmm6, %xmm0
	paddd	%xmm7, %xmm2
	paddd	%xmm7, %xmm8
	cmpq	$64, %rax
	jne	.LBB2_49
# %bb.50:
	xorps	%xmm0, %xmm0
	movaps	%xmm0, 96(%rsp)
	movaps	%xmm0, 80(%rsp)
	xorps	%xmm0, %xmm0
	xorl	%eax, %eax
	jmp	.LBB2_52
.LBB2_51:                               #   in Loop: Header=BB2_52 Depth=1
	addq	$2, %rax
	cmpq	$64, %rax
	je	.LBB2_57
.LBB2_52:                               # =>This Inner Loop Header: Depth=1
	movss	(%r12,%rax,4), %xmm2            # xmm2 = mem[0],zero,zero,zero
	movl	%eax, %ecx
	shrl	$3, %ecx
	movss	80(%rsp,%rcx,4), %xmm1          # xmm1 = mem[0],zero,zero,zero
	addss	%xmm2, %xmm1
	movss	%xmm1, 80(%rsp,%rcx,4)
	cmpq	$32, %rax
	jb	.LBB2_54
# %bb.53:                               #   in Loop: Header=BB2_52 Depth=1
	movaps	%xmm0, 64(%rsp)                 # 16-byte Spill
	jmp	.LBB2_55
.LBB2_54:                               #   in Loop: Header=BB2_52 Depth=1
	addss	%xmm0, %xmm2
	movaps	%xmm2, 64(%rsp)                 # 16-byte Spill
.LBB2_55:                               #   in Loop: Header=BB2_52 Depth=1
	movss	4(%r12,%rax,4), %xmm2           # xmm2 = mem[0],zero,zero,zero
	addss	%xmm2, %xmm1
	movss	%xmm1, 80(%rsp,%rcx,4)
	jae	.LBB2_51
# %bb.56:                               #   in Loop: Header=BB2_52 Depth=1
	addss	64(%rsp), %xmm2                 # 16-byte Folded Reload
	movaps	%xmm2, %xmm0
	jmp	.LBB2_51
.LBB2_57:
.Ltmp67:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	leaq	48(%rsp), %rdi
	movl	$256, %esi                      # imm = 0x100
	callq	hipMalloc
.Ltmp68:                                # EH_LABEL
# %bb.58:
	testl	%eax, %eax
	movl	%ebp, 44(%rsp)                  # 4-byte Spill
	je	.LBB2_61
# %bb.59:
.Ltmp69:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp70:                                # EH_LABEL
# %bb.60:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$163, %edx
	jmp	.LBB2_103
.LBB2_61:
.Ltmp72:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	leaq	32(%rsp), %rdi
	movl	$256, %esi                      # imm = 0x100
	callq	hipMalloc
.Ltmp73:                                # EH_LABEL
# %bb.62:
	testl	%eax, %eax
	je	.LBB2_65
# %bb.63:
.Ltmp74:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp75:                                # EH_LABEL
# %bb.64:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$164, %edx
	jmp	.LBB2_103
.LBB2_65:
	movq	48(%rsp), %rdi
.Ltmp77:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edx                      # imm = 0x100
	movq	%r12, %rsi
	movl	$1, %ecx
	callq	hipMemcpy
.Ltmp78:                                # EH_LABEL
# %bb.66:
	testl	%eax, %eax
	je	.LBB2_69
# %bb.67:
.Ltmp79:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp80:                                # EH_LABEL
# %bb.68:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$165, %edx
	jmp	.LBB2_103
.LBB2_69:
.Ltmp82:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movabsq	$4294967297, %rdi               # imm = 0x100000001
	movabsq	$4294967328, %rdx               # imm = 0x100000020
	movl	$1, %esi
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
.Ltmp83:                                # EH_LABEL
# %bb.70:
	testl	%eax, %eax
	jne	.LBB2_72
# %bb.71:
	movq	48(%rsp), %rdi
	movq	32(%rsp), %rsi
.Ltmp84:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	_Z37__device_stub__butterfly_group_kernelPKfPf
.Ltmp85:                                # EH_LABEL
.LBB2_72:
.Ltmp87:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	hipDeviceSynchronize
.Ltmp88:                                # EH_LABEL
# %bb.73:
	testl	%eax, %eax
	je	.LBB2_76
# %bb.74:
.Ltmp89:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp90:                                # EH_LABEL
# %bb.75:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$167, %edx
	jmp	.LBB2_103
.LBB2_76:
	movq	32(%rsp), %rsi
.Ltmp92:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edx                      # imm = 0x100
	movq	8(%rsp), %rdi                   # 8-byte Reload
	movl	$2, %ecx
	callq	hipMemcpy
.Ltmp93:                                # EH_LABEL
# %bb.77:
	testl	%eax, %eax
	je	.LBB2_80
# %bb.78:
.Ltmp94:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp95:                                # EH_LABEL
# %bb.79:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$168, %edx
	jmp	.LBB2_103
.LBB2_80:
	movaps	80(%rsp), %xmm4
	movaps	%xmm4, %xmm0
	shufps	$170, %xmm4, %xmm0              # xmm0 = xmm0[2,2],xmm4[2,2]
	movaps	%xmm4, %xmm5
	shufps	$255, %xmm4, %xmm5              # xmm5 = xmm5[3,3],xmm4[3,3]
	movaps	%xmm4, %xmm6
	shufps	$0, %xmm4, %xmm6                # xmm6 = xmm6[0,0],xmm4[0,0]
	shufps	$85, %xmm4, %xmm4               # xmm4 = xmm4[1,1,1,1]
	movq	8(%rsp), %rax                   # 8-byte Reload
	movups	64(%rax), %xmm1
	movups	80(%rax), %xmm3
	movups	96(%rax), %xmm2
	movups	112(%rax), %xmm7
	movups	(%rax), %xmm8
	movups	16(%rax), %xmm9
	movups	32(%rax), %xmm10
	movups	48(%rax), %xmm11
	cmpneqps	%xmm4, %xmm11
	cmpneqps	%xmm4, %xmm10
	packssdw	%xmm11, %xmm10
	cmpneqps	%xmm6, %xmm9
	cmpneqps	%xmm6, %xmm8
	packssdw	%xmm9, %xmm8
	packsswb	%xmm10, %xmm8
	pmovmskb	%xmm8, %r13d
	cmpneqps	%xmm5, %xmm7
	cmpneqps	%xmm5, %xmm2
	packssdw	%xmm7, %xmm2
	cmpneqps	%xmm0, %xmm3
	cmpneqps	%xmm0, %xmm1
	packssdw	%xmm3, %xmm1
	packsswb	%xmm2, %xmm1
	pmovmskb	%xmm1, %ebp
	shll	$16, %ebp
	movl	%r13d, %eax
	orl	%ebp, %eax
	movl	$.L.str.6, %eax
	movl	$.L.str.5, %esi
	cmovneq	%rax, %rsi
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.4, %edi
	xorl	%eax, %eax
	callq	printf
	orl	%r13d, %ebp
	je	.LBB2_82
# %bb.81:
	movss	80(%rsp), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	xorps	%xmm1, %xmm1
	cvtss2sd	%xmm0, %xmm1
	movsd	%xmm1, 16(%rsp)                 # 8-byte Spill
	movq	8(%rsp), %r13                   # 8-byte Reload
	movss	(%r13), %xmm0                   # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.7, %edi
	xorl	%esi, %esi
	movb	$2, %al
	callq	printf
	movss	4(%r13), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.7, %edi
	movl	$1, %esi
	movsd	16(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movb	$2, %al
	callq	printf
	movss	8(%r13), %xmm0                  # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.7, %edi
	movl	$2, %esi
	movsd	16(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movb	$2, %al
	callq	printf
	movss	12(%r13), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.7, %edi
	movl	$3, %esi
	movsd	16(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movb	$2, %al
	callq	printf
	movss	16(%r13), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.7, %edi
	movl	$4, %esi
	movsd	16(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movb	$2, %al
	callq	printf
	movss	20(%r13), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.7, %edi
	movl	$5, %esi
	movsd	16(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movb	$2, %al
	callq	printf
	movss	24(%r13), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.7, %edi
	movl	$6, %esi
	movsd	16(%rsp), %xmm1                 # 8-byte Reload
                                        # xmm1 = mem[0],zero
	movb	$2, %al
	callq	printf
	movss	28(%r13), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.7, %edi
	movl	$7, %esi
	movq	16(%rsp), %xmm1                 # 8-byte Folded Reload
                                        # xmm1 = mem[0],zero
	movb	$2, %al
	callq	printf
.LBB2_82:
	cmpl	$1, %ebp
	sbbl	$-1, 44(%rsp)                   # 4-byte Folded Spill
.Ltmp97:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movabsq	$4294967297, %rdi               # imm = 0x100000001
	movabsq	$4294967328, %rdx               # imm = 0x100000020
	movl	$1, %esi
	movl	$1, %ecx
	xorl	%r8d, %r8d
	xorl	%r9d, %r9d
	callq	__hipPushCallConfiguration
.Ltmp98:                                # EH_LABEL
# %bb.83:
	testl	%eax, %eax
	jne	.LBB2_85
# %bb.84:
	movq	48(%rsp), %rdi
	movq	32(%rsp), %rsi
.Ltmp99:                                # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	_Z36__device_stub__butterfly_wave_kernelPKfPf
.Ltmp100:                               # EH_LABEL
.LBB2_85:
.Ltmp102:                               # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	hipDeviceSynchronize
.Ltmp103:                               # EH_LABEL
# %bb.86:
	testl	%eax, %eax
	je	.LBB2_89
# %bb.87:
.Ltmp104:                               # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp105:                               # EH_LABEL
# %bb.88:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$178, %edx
	jmp	.LBB2_103
.LBB2_89:
	movq	32(%rsp), %rsi
.Ltmp107:                               # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	$256, %edx                      # imm = 0x100
	movq	8(%rsp), %rdi                   # 8-byte Reload
	movl	$2, %ecx
	callq	hipMemcpy
.Ltmp108:                               # EH_LABEL
# %bb.90:
	testl	%eax, %eax
	je	.LBB2_93
# %bb.91:
.Ltmp109:                               # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp110:                               # EH_LABEL
# %bb.92:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$179, %edx
	jmp	.LBB2_103
.LBB2_93:
	movq	8(%rsp), %rax                   # 8-byte Reload
	movups	64(%rax), %xmm2
	movups	80(%rax), %xmm1
	movups	96(%rax), %xmm0
	movups	112(%rax), %xmm3
	movups	(%rax), %xmm4
	movups	16(%rax), %xmm5
	movups	32(%rax), %xmm6
	movups	48(%rax), %xmm7
	movaps	64(%rsp), %xmm9                 # 16-byte Reload
	movaps	%xmm9, %xmm8
	shufps	$0, %xmm9, %xmm8                # xmm8 = xmm8[0,0],xmm9[0,0]
	cmpneqps	%xmm8, %xmm7
	cmpneqps	%xmm8, %xmm6
	packssdw	%xmm7, %xmm6
	cmpneqps	%xmm8, %xmm5
	cmpneqps	%xmm8, %xmm4
	packssdw	%xmm5, %xmm4
	packsswb	%xmm6, %xmm4
	pmovmskb	%xmm4, %r13d
	cmpneqps	%xmm8, %xmm3
	cmpneqps	%xmm8, %xmm0
	packssdw	%xmm3, %xmm0
	cmpneqps	%xmm8, %xmm1
	cmpneqps	%xmm2, %xmm8
	packssdw	%xmm1, %xmm8
	packsswb	%xmm0, %xmm8
	pmovmskb	%xmm8, %ebp
	shll	$16, %ebp
	movl	%r13d, %eax
	orl	%ebp, %eax
	movl	$.L.str.6, %eax
	movl	$.L.str.5, %esi
	cmovneq	%rax, %rsi
	xorps	%xmm0, %xmm0
	cvtss2sd	%xmm9, %xmm0
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.8, %edi
	movsd	%xmm0, 64(%rsp)                 # 8-byte Spill
	movb	$1, %al
	callq	printf
	orl	%r13d, %ebp
	je	.LBB2_95
# %bb.94:
	movq	8(%rsp), %rax                   # 8-byte Reload
	movss	(%rax), %xmm0                   # xmm0 = mem[0],zero,zero,zero
	movss	4(%rax), %xmm1                  # xmm1 = mem[0],zero,zero,zero
	cvtss2sd	%xmm0, %xmm0
	cvtss2sd	%xmm1, %xmm1
	movss	64(%rax), %xmm2                 # xmm2 = mem[0],zero,zero,zero
	cvtss2sd	%xmm2, %xmm2
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.9, %edi
	movsd	64(%rsp), %xmm3                 # 8-byte Reload
                                        # xmm3 = mem[0],zero
	movb	$4, %al
	callq	printf
.LBB2_95:
	cmpl	$1, %ebp
	sbbl	$-1, 44(%rsp)                   # 4-byte Folded Spill
	movq	48(%rsp), %rdi
.Ltmp112:                               # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	hipFree
.Ltmp113:                               # EH_LABEL
# %bb.96:
	testl	%eax, %eax
	je	.LBB2_99
# %bb.97:
.Ltmp114:                               # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp115:                               # EH_LABEL
# %bb.98:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$189, %edx
	jmp	.LBB2_103
.LBB2_99:
	movq	32(%rsp), %rdi
.Ltmp117:                               # EH_LABEL
	.cfi_escape 0x2e, 0x00
	callq	hipFree
.Ltmp118:                               # EH_LABEL
# %bb.100:
	testl	%eax, %eax
	je	.LBB2_106
# %bb.101:
.Ltmp119:                               # EH_LABEL
	.cfi_escape 0x2e, 0x00
	movl	%eax, %edi
	callq	hipGetErrorString
.Ltmp120:                               # EH_LABEL
# %bb.102:
	.cfi_escape 0x2e, 0x00
	xorl	%r13d, %r13d
	movl	$.L.str, %edi
	movq	%rax, %rsi
	movl	$190, %edx
.LBB2_103:
	xorl	%eax, %eax
	callq	printf
	movl	$1, %ebp
.LBB2_104:
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	8(%rsp), %rdi                   # 8-byte Reload
	callq	_ZdlPvm
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	%r12, %rdi
	callq	_ZdlPvm
	testb	%r13b, %r13b
	je	.LBB2_45
# %bb.105:
	xorl	%ebp, %ebp
	cmpl	$0, 44(%rsp)                    # 4-byte Folded Reload
	setne	%bpl
	movl	$.L.str.6, %eax
	movl	$.L.str.5, %esi
	cmovneq	%rax, %rsi
	.cfi_escape 0x2e, 0x00
	movl	$.L.str.10, %edi
	xorl	%eax, %eax
	callq	printf
	jmp	.LBB2_45
.LBB2_106:
	xorl	%ebp, %ebp
	movb	$1, %r13b
	jmp	.LBB2_104
.LBB2_107:
.Ltmp121:                               # EH_LABEL
	jmp	.LBB2_120
.LBB2_108:
.Ltmp116:                               # EH_LABEL
	jmp	.LBB2_120
.LBB2_109:
.Ltmp111:                               # EH_LABEL
	jmp	.LBB2_120
.LBB2_110:
.Ltmp101:                               # EH_LABEL
	jmp	.LBB2_120
.LBB2_111:
.Ltmp106:                               # EH_LABEL
	jmp	.LBB2_120
.LBB2_112:
.Ltmp96:                                # EH_LABEL
	jmp	.LBB2_120
.LBB2_113:
.Ltmp86:                                # EH_LABEL
	jmp	.LBB2_120
.LBB2_114:
.Ltmp91:                                # EH_LABEL
	jmp	.LBB2_120
.LBB2_115:
.Ltmp81:                                # EH_LABEL
	jmp	.LBB2_120
.LBB2_116:
.Ltmp76:                                # EH_LABEL
	jmp	.LBB2_120
.LBB2_117:
.Ltmp66:                                # EH_LABEL
	movq	%rax, %rbp
	.cfi_escape 0x2e, 0x00
	jmp	.LBB2_121
.LBB2_118:
.Ltmp63:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_119:
.Ltmp71:                                # EH_LABEL
.LBB2_120:
	movq	%rax, %rbp
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	8(%rsp), %rdi                   # 8-byte Reload
	callq	_ZdlPvm
	.cfi_escape 0x2e, 0x00
.LBB2_121:
	movl	$256, %esi                      # imm = 0x100
	movq	%r12, %rdi
	callq	_ZdlPvm
	jmp	.LBB2_134
.LBB2_122:
.Ltmp60:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_123:
.Ltmp55:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_124:
.Ltmp50:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_125:
.Ltmp40:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_126:
.Ltmp35:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_127:
.Ltmp26:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_128:
.Ltmp21:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_129:
.Ltmp45:                                # EH_LABEL
	jmp	.LBB2_133
.LBB2_130:
.Ltmp5:                                 # EH_LABEL
	movq	%rax, %rbp
	jmp	.LBB2_135
.LBB2_131:
.Ltmp2:                                 # EH_LABEL
	movq	%rax, %rbp
	jmp	.LBB2_136
.LBB2_132:
.Ltmp10:                                # EH_LABEL
.LBB2_133:
	movq	%rax, %rbp
.LBB2_134:
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	%r15, %rdi
	callq	_ZdlPvm
.LBB2_135:
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	%r14, %rdi
	callq	_ZdlPvm
.LBB2_136:
	.cfi_escape 0x2e, 0x00
	movl	$256, %esi                      # imm = 0x100
	movq	%rbx, %rdi
	callq	_ZdlPvm
	.cfi_escape 0x2e, 0x00
	movq	%rbp, %rdi
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
	.uleb128 .Ltmp3-.Lfunc_begin0           # >> Call Site 3 <<
	.uleb128 .Ltmp4-.Ltmp3                  #   Call between .Ltmp3 and .Ltmp4
	.uleb128 .Ltmp5-.Lfunc_begin0           #     jumps to .Ltmp5
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp6-.Lfunc_begin0           # >> Call Site 4 <<
	.uleb128 .Ltmp9-.Ltmp6                  #   Call between .Ltmp6 and .Ltmp9
	.uleb128 .Ltmp10-.Lfunc_begin0          #     jumps to .Ltmp10
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp11-.Lfunc_begin0          # >> Call Site 5 <<
	.uleb128 .Ltmp16-.Ltmp11                #   Call between .Ltmp11 and .Ltmp16
	.uleb128 .Ltmp45-.Lfunc_begin0          #     jumps to .Ltmp45
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp17-.Lfunc_begin0          # >> Call Site 6 <<
	.uleb128 .Ltmp20-.Ltmp17                #   Call between .Ltmp17 and .Ltmp20
	.uleb128 .Ltmp21-.Lfunc_begin0          #     jumps to .Ltmp21
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp22-.Lfunc_begin0          # >> Call Site 7 <<
	.uleb128 .Ltmp25-.Ltmp22                #   Call between .Ltmp22 and .Ltmp25
	.uleb128 .Ltmp26-.Lfunc_begin0          #     jumps to .Ltmp26
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp27-.Lfunc_begin0          # >> Call Site 8 <<
	.uleb128 .Ltmp30-.Ltmp27                #   Call between .Ltmp27 and .Ltmp30
	.uleb128 .Ltmp45-.Lfunc_begin0          #     jumps to .Ltmp45
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp31-.Lfunc_begin0          # >> Call Site 9 <<
	.uleb128 .Ltmp34-.Ltmp31                #   Call between .Ltmp31 and .Ltmp34
	.uleb128 .Ltmp35-.Lfunc_begin0          #     jumps to .Ltmp35
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp36-.Lfunc_begin0          # >> Call Site 10 <<
	.uleb128 .Ltmp39-.Ltmp36                #   Call between .Ltmp36 and .Ltmp39
	.uleb128 .Ltmp40-.Lfunc_begin0          #     jumps to .Ltmp40
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp41-.Lfunc_begin0          # >> Call Site 11 <<
	.uleb128 .Ltmp44-.Ltmp41                #   Call between .Ltmp41 and .Ltmp44
	.uleb128 .Ltmp45-.Lfunc_begin0          #     jumps to .Ltmp45
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp46-.Lfunc_begin0          # >> Call Site 12 <<
	.uleb128 .Ltmp49-.Ltmp46                #   Call between .Ltmp46 and .Ltmp49
	.uleb128 .Ltmp50-.Lfunc_begin0          #     jumps to .Ltmp50
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp51-.Lfunc_begin0          # >> Call Site 13 <<
	.uleb128 .Ltmp54-.Ltmp51                #   Call between .Ltmp51 and .Ltmp54
	.uleb128 .Ltmp55-.Lfunc_begin0          #     jumps to .Ltmp55
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp56-.Lfunc_begin0          # >> Call Site 14 <<
	.uleb128 .Ltmp59-.Ltmp56                #   Call between .Ltmp56 and .Ltmp59
	.uleb128 .Ltmp60-.Lfunc_begin0          #     jumps to .Ltmp60
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp61-.Lfunc_begin0          # >> Call Site 15 <<
	.uleb128 .Ltmp62-.Ltmp61                #   Call between .Ltmp61 and .Ltmp62
	.uleb128 .Ltmp63-.Lfunc_begin0          #     jumps to .Ltmp63
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp64-.Lfunc_begin0          # >> Call Site 16 <<
	.uleb128 .Ltmp65-.Ltmp64                #   Call between .Ltmp64 and .Ltmp65
	.uleb128 .Ltmp66-.Lfunc_begin0          #     jumps to .Ltmp66
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp67-.Lfunc_begin0          # >> Call Site 17 <<
	.uleb128 .Ltmp70-.Ltmp67                #   Call between .Ltmp67 and .Ltmp70
	.uleb128 .Ltmp71-.Lfunc_begin0          #     jumps to .Ltmp71
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp72-.Lfunc_begin0          # >> Call Site 18 <<
	.uleb128 .Ltmp75-.Ltmp72                #   Call between .Ltmp72 and .Ltmp75
	.uleb128 .Ltmp76-.Lfunc_begin0          #     jumps to .Ltmp76
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp77-.Lfunc_begin0          # >> Call Site 19 <<
	.uleb128 .Ltmp80-.Ltmp77                #   Call between .Ltmp77 and .Ltmp80
	.uleb128 .Ltmp81-.Lfunc_begin0          #     jumps to .Ltmp81
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp82-.Lfunc_begin0          # >> Call Site 20 <<
	.uleb128 .Ltmp85-.Ltmp82                #   Call between .Ltmp82 and .Ltmp85
	.uleb128 .Ltmp86-.Lfunc_begin0          #     jumps to .Ltmp86
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp87-.Lfunc_begin0          # >> Call Site 21 <<
	.uleb128 .Ltmp90-.Ltmp87                #   Call between .Ltmp87 and .Ltmp90
	.uleb128 .Ltmp91-.Lfunc_begin0          #     jumps to .Ltmp91
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp92-.Lfunc_begin0          # >> Call Site 22 <<
	.uleb128 .Ltmp95-.Ltmp92                #   Call between .Ltmp92 and .Ltmp95
	.uleb128 .Ltmp96-.Lfunc_begin0          #     jumps to .Ltmp96
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp97-.Lfunc_begin0          # >> Call Site 23 <<
	.uleb128 .Ltmp100-.Ltmp97               #   Call between .Ltmp97 and .Ltmp100
	.uleb128 .Ltmp101-.Lfunc_begin0         #     jumps to .Ltmp101
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp102-.Lfunc_begin0         # >> Call Site 24 <<
	.uleb128 .Ltmp105-.Ltmp102              #   Call between .Ltmp102 and .Ltmp105
	.uleb128 .Ltmp106-.Lfunc_begin0         #     jumps to .Ltmp106
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp107-.Lfunc_begin0         # >> Call Site 25 <<
	.uleb128 .Ltmp110-.Ltmp107              #   Call between .Ltmp107 and .Ltmp110
	.uleb128 .Ltmp111-.Lfunc_begin0         #     jumps to .Ltmp111
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp112-.Lfunc_begin0         # >> Call Site 26 <<
	.uleb128 .Ltmp115-.Ltmp112              #   Call between .Ltmp112 and .Ltmp115
	.uleb128 .Ltmp116-.Lfunc_begin0         #     jumps to .Ltmp116
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp117-.Lfunc_begin0         # >> Call Site 27 <<
	.uleb128 .Ltmp120-.Ltmp117              #   Call between .Ltmp117 and .Ltmp120
	.uleb128 .Ltmp121-.Lfunc_begin0         #     jumps to .Ltmp121
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp120-.Lfunc_begin0         # >> Call Site 28 <<
	.uleb128 .Lfunc_end2-.Ltmp120           #   Call between .Ltmp120 and .Lfunc_end2
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end0:
	.p2align	2, 0x0
                                        # -- End function
	.section	.text._Z33__device_stub__swizzle_map_kernelILj1055EEvPj,"axG",@progbits,_Z33__device_stub__swizzle_map_kernelILj1055EEvPj,comdat
	.weak	_Z33__device_stub__swizzle_map_kernelILj1055EEvPj # -- Begin function _Z33__device_stub__swizzle_map_kernelILj1055EEvPj
	.p2align	4
	.type	_Z33__device_stub__swizzle_map_kernelILj1055EEvPj,@function
_Z33__device_stub__swizzle_map_kernelILj1055EEvPj: # @_Z33__device_stub__swizzle_map_kernelILj1055EEvPj
	.cfi_startproc
# %bb.0:
	subq	$72, %rsp
	.cfi_def_cfa_offset 80
	movq	%rdi, 64(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, (%rsp)
	leaq	48(%rsp), %rdi
	leaq	32(%rsp), %rsi
	leaq	24(%rsp), %rdx
	leaq	16(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	48(%rsp), %rsi
	movl	56(%rsp), %edx
	movq	32(%rsp), %rcx
	movl	40(%rsp), %r8d
	movq	%rsp, %r9
	movl	$_Z18swizzle_map_kernelILj1055EEvPj, %edi
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	32(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$88, %rsp
	.cfi_adjust_cfa_offset -88
	retq
.Lfunc_end3:
	.size	_Z33__device_stub__swizzle_map_kernelILj1055EEvPj, .Lfunc_end3-_Z33__device_stub__swizzle_map_kernelILj1055EEvPj
	.cfi_endproc
                                        # -- End function
	.section	.text._Z33__device_stub__swizzle_map_kernelILj2079EEvPj,"axG",@progbits,_Z33__device_stub__swizzle_map_kernelILj2079EEvPj,comdat
	.weak	_Z33__device_stub__swizzle_map_kernelILj2079EEvPj # -- Begin function _Z33__device_stub__swizzle_map_kernelILj2079EEvPj
	.p2align	4
	.type	_Z33__device_stub__swizzle_map_kernelILj2079EEvPj,@function
_Z33__device_stub__swizzle_map_kernelILj2079EEvPj: # @_Z33__device_stub__swizzle_map_kernelILj2079EEvPj
	.cfi_startproc
# %bb.0:
	subq	$72, %rsp
	.cfi_def_cfa_offset 80
	movq	%rdi, 64(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, (%rsp)
	leaq	48(%rsp), %rdi
	leaq	32(%rsp), %rsi
	leaq	24(%rsp), %rdx
	leaq	16(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	48(%rsp), %rsi
	movl	56(%rsp), %edx
	movq	32(%rsp), %rcx
	movl	40(%rsp), %r8d
	movq	%rsp, %r9
	movl	$_Z18swizzle_map_kernelILj2079EEvPj, %edi
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	32(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$88, %rsp
	.cfi_adjust_cfa_offset -88
	retq
.Lfunc_end4:
	.size	_Z33__device_stub__swizzle_map_kernelILj2079EEvPj, .Lfunc_end4-_Z33__device_stub__swizzle_map_kernelILj2079EEvPj
	.cfi_endproc
                                        # -- End function
	.section	.text._Z33__device_stub__swizzle_map_kernelILj4127EEvPj,"axG",@progbits,_Z33__device_stub__swizzle_map_kernelILj4127EEvPj,comdat
	.weak	_Z33__device_stub__swizzle_map_kernelILj4127EEvPj # -- Begin function _Z33__device_stub__swizzle_map_kernelILj4127EEvPj
	.p2align	4
	.type	_Z33__device_stub__swizzle_map_kernelILj4127EEvPj,@function
_Z33__device_stub__swizzle_map_kernelILj4127EEvPj: # @_Z33__device_stub__swizzle_map_kernelILj4127EEvPj
	.cfi_startproc
# %bb.0:
	subq	$72, %rsp
	.cfi_def_cfa_offset 80
	movq	%rdi, 64(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, (%rsp)
	leaq	48(%rsp), %rdi
	leaq	32(%rsp), %rsi
	leaq	24(%rsp), %rdx
	leaq	16(%rsp), %rcx
	callq	__hipPopCallConfiguration
	movq	48(%rsp), %rsi
	movl	56(%rsp), %edx
	movq	32(%rsp), %rcx
	movl	40(%rsp), %r8d
	movq	%rsp, %r9
	movl	$_Z18swizzle_map_kernelILj4127EEvPj, %edi
	pushq	16(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	32(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel
	addq	$88, %rsp
	.cfi_adjust_cfa_offset -88
	retq
.Lfunc_end5:
	.size	_Z33__device_stub__swizzle_map_kernelILj4127EEvPj, .Lfunc_end5-_Z33__device_stub__swizzle_map_kernelILj4127EEvPj
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0                          # -- Begin function _ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j
.LCPI6_0:
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	2                               # 0x2
	.long	3                               # 0x3
.LCPI6_1:
	.long	4                               # 0x4
	.long	5                               # 0x5
	.long	6                               # 0x6
	.long	7                               # 0x7
.LCPI6_2:
	.long	7                               # 0x7
	.long	7                               # 0x7
	.long	7                               # 0x7
	.long	7                               # 0x7
.LCPI6_3:
	.long	8                               # 0x8
	.long	9                               # 0x9
	.long	10                              # 0xa
	.long	11                              # 0xb
.LCPI6_4:
	.long	12                              # 0xc
	.long	13                              # 0xd
	.long	14                              # 0xe
	.long	15                              # 0xf
.LCPI6_5:
	.long	16                              # 0x10
	.long	17                              # 0x11
	.long	18                              # 0x12
	.long	19                              # 0x13
.LCPI6_6:
	.long	20                              # 0x14
	.long	21                              # 0x15
	.long	22                              # 0x16
	.long	23                              # 0x17
.LCPI6_7:
	.long	24                              # 0x18
	.long	25                              # 0x19
	.long	26                              # 0x1a
	.long	27                              # 0x1b
.LCPI6_8:
	.long	28                              # 0x1c
	.long	29                              # 0x1d
	.long	30                              # 0x1e
	.long	31                              # 0x1f
.LCPI6_9:
	.long	32                              # 0x20
	.long	33                              # 0x21
	.long	34                              # 0x22
	.long	35                              # 0x23
.LCPI6_10:
	.long	36                              # 0x24
	.long	37                              # 0x25
	.long	38                              # 0x26
	.long	39                              # 0x27
.LCPI6_11:
	.long	40                              # 0x28
	.long	41                              # 0x29
	.long	42                              # 0x2a
	.long	43                              # 0x2b
.LCPI6_12:
	.long	44                              # 0x2c
	.long	45                              # 0x2d
	.long	46                              # 0x2e
	.long	47                              # 0x2f
.LCPI6_13:
	.long	48                              # 0x30
	.long	49                              # 0x31
	.long	50                              # 0x32
	.long	51                              # 0x33
.LCPI6_14:
	.long	52                              # 0x34
	.long	53                              # 0x35
	.long	54                              # 0x36
	.long	55                              # 0x37
.LCPI6_15:
	.long	56                              # 0x38
	.long	57                              # 0x39
	.long	58                              # 0x3a
	.long	59                              # 0x3b
.LCPI6_16:
	.long	60                              # 0x3c
	.long	61                              # 0x3d
	.long	62                              # 0x3e
	.long	63                              # 0x3f
	.text
	.p2align	4
	.type	_ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j,@function
_ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j: # @_ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j
	.cfi_startproc
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	subq	$40, %rsp
	.cfi_def_cfa_offset 64
	.cfi_offset %rbx, -24
	.cfi_offset %rbp, -16
	movl	%esi, %edx
	movq	%rdi, %rbx
	movd	%esi, %xmm0
	pshufd	$0, %xmm0, %xmm10               # xmm10 = xmm0[0,0,0,0]
	movq	(%rdi), %rax
	movdqu	(%rax), %xmm4
	movdqu	16(%rax), %xmm2
	movdqu	32(%rax), %xmm7
	movdqu	48(%rax), %xmm6
	movdqa	%xmm10, %xmm1
	pxor	%xmm4, %xmm1
	movdqa	.LCPI6_0(%rip), %xmm0           # xmm0 = [0,1,2,3]
	movdqa	%xmm1, %xmm8
	pcmpeqd	%xmm0, %xmm8
	movdqa	%xmm10, %xmm5
	pxor	%xmm2, %xmm5
	movdqa	.LCPI6_1(%rip), %xmm3           # xmm3 = [4,5,6,7]
	movdqa	%xmm5, %xmm9
	pcmpeqd	%xmm3, %xmm9
	movdqa	.LCPI6_2(%rip), %xmm14          # xmm14 = [7,7,7,7]
	pcmpeqd	%xmm14, %xmm1
	pcmpeqd	%xmm14, %xmm5
	pcmpeqd	%xmm0, %xmm4
	pcmpeqd	%xmm3, %xmm2
	movdqa	%xmm10, %xmm0
	pxor	%xmm7, %xmm0
	movdqa	.LCPI6_3(%rip), %xmm12          # xmm12 = [8,9,10,11]
	movdqa	%xmm0, %xmm3
	pcmpeqd	%xmm12, %xmm3
	pand	%xmm8, %xmm3
	movdqa	%xmm10, %xmm11
	pxor	%xmm6, %xmm11
	movdqa	.LCPI6_4(%rip), %xmm8           # xmm8 = [12,13,14,15]
	movdqa	%xmm11, %xmm13
	pcmpeqd	%xmm8, %xmm13
	pand	%xmm9, %xmm13
	pcmpeqd	%xmm14, %xmm0
	pand	%xmm1, %xmm0
	pcmpeqd	%xmm14, %xmm11
	pand	%xmm5, %xmm11
	pcmpeqd	%xmm12, %xmm7
	pand	%xmm4, %xmm7
	movdqa	%xmm7, 16(%rsp)                 # 16-byte Spill
	pcmpeqd	%xmm8, %xmm6
	pand	%xmm2, %xmm6
	movdqa	%xmm6, (%rsp)                   # 16-byte Spill
	movdqu	64(%rax), %xmm14
	movdqu	80(%rax), %xmm12
	movdqa	%xmm10, %xmm1
	pxor	%xmm14, %xmm1
	movdqa	.LCPI6_5(%rip), %xmm8           # xmm8 = [16,17,18,19]
	movdqa	%xmm1, %xmm5
	pcmpeqd	%xmm8, %xmm5
	movdqa	%xmm10, %xmm15
	pxor	%xmm12, %xmm15
	movdqa	.LCPI6_6(%rip), %xmm4           # xmm4 = [20,21,22,23]
	movdqa	%xmm15, %xmm2
	pcmpeqd	%xmm4, %xmm2
	pcmpeqd	%xmm8, %xmm14
	pcmpeqd	%xmm4, %xmm12
	movdqu	96(%rax), %xmm6
	movdqa	%xmm10, %xmm4
	pxor	%xmm6, %xmm4
	movdqa	%xmm4, %xmm8
	pcmpeqd	.LCPI6_7(%rip), %xmm8
	pand	%xmm5, %xmm8
	pand	%xmm3, %xmm8
	movdqu	112(%rax), %xmm7
	movdqa	%xmm10, %xmm5
	pxor	%xmm7, %xmm5
	movdqa	%xmm5, %xmm9
	pcmpeqd	.LCPI6_8(%rip), %xmm9
	pand	%xmm2, %xmm9
	pand	%xmm13, %xmm9
	movdqa	.LCPI6_2(%rip), %xmm2           # xmm2 = [7,7,7,7]
	pcmpeqd	%xmm2, %xmm1
	pcmpeqd	%xmm2, %xmm4
	pand	%xmm1, %xmm4
	pand	%xmm0, %xmm4
	pcmpeqd	%xmm2, %xmm15
	pcmpeqd	%xmm2, %xmm5
	pand	%xmm15, %xmm5
	pand	%xmm11, %xmm5
	pcmpeqd	.LCPI6_7(%rip), %xmm6
	pand	%xmm14, %xmm6
	pand	16(%rsp), %xmm6                 # 16-byte Folded Reload
	movdqa	%xmm6, 16(%rsp)                 # 16-byte Spill
	pcmpeqd	.LCPI6_8(%rip), %xmm7
	pand	%xmm12, %xmm7
	pand	(%rsp), %xmm7                   # 16-byte Folded Reload
	movdqa	%xmm7, (%rsp)                   # 16-byte Spill
	movdqu	128(%rax), %xmm11
	movdqu	144(%rax), %xmm6
	movdqa	%xmm10, %xmm0
	pxor	%xmm11, %xmm0
	movdqa	.LCPI6_9(%rip), %xmm1           # xmm1 = [32,33,34,35]
	movdqa	%xmm0, %xmm2
	pcmpeqd	%xmm1, %xmm2
	movdqa	%xmm10, %xmm12
	pxor	%xmm6, %xmm12
	movdqa	.LCPI6_10(%rip), %xmm3          # xmm3 = [36,37,38,39]
	movdqa	%xmm12, %xmm15
	pcmpeqd	%xmm3, %xmm15
	pcmpeqd	%xmm1, %xmm11
	pcmpeqd	%xmm3, %xmm6
	movdqu	160(%rax), %xmm7
	movdqa	%xmm10, %xmm13
	pxor	%xmm7, %xmm13
	movdqa	%xmm13, %xmm1
	pcmpeqd	.LCPI6_11(%rip), %xmm1
	pand	%xmm2, %xmm1
	movdqu	176(%rax), %xmm3
	movdqa	%xmm10, %xmm14
	pxor	%xmm3, %xmm14
	movdqa	%xmm14, %xmm2
	pcmpeqd	.LCPI6_12(%rip), %xmm2
	pand	%xmm15, %xmm2
	movdqa	.LCPI6_2(%rip), %xmm15          # xmm15 = [7,7,7,7]
	pcmpeqd	%xmm15, %xmm0
	pcmpeqd	%xmm15, %xmm13
	pand	%xmm0, %xmm13
	pcmpeqd	%xmm15, %xmm12
	pcmpeqd	%xmm15, %xmm14
	pand	%xmm12, %xmm14
	pcmpeqd	.LCPI6_11(%rip), %xmm7
	pand	%xmm11, %xmm7
	pcmpeqd	.LCPI6_12(%rip), %xmm3
	pand	%xmm6, %xmm3
	movdqu	192(%rax), %xmm6
	movdqa	%xmm10, %xmm11
	pxor	%xmm6, %xmm11
	movdqa	%xmm11, %xmm15
	pcmpeqd	.LCPI6_13(%rip), %xmm15
	pand	%xmm1, %xmm15
	pand	%xmm8, %xmm15
	movdqu	208(%rax), %xmm8
	movdqa	%xmm10, %xmm12
	pxor	%xmm8, %xmm12
	movdqa	.LCPI6_14(%rip), %xmm1          # xmm1 = [52,53,54,55]
	movdqa	%xmm12, %xmm0
	pcmpeqd	%xmm1, %xmm0
	pand	%xmm2, %xmm0
	pand	%xmm9, %xmm0
	movdqa	.LCPI6_2(%rip), %xmm2           # xmm2 = [7,7,7,7]
	pcmpeqd	%xmm2, %xmm11
	pand	%xmm13, %xmm11
	pand	%xmm4, %xmm11
	pcmpeqd	%xmm2, %xmm12
	movdqa	%xmm2, %xmm13
	pand	%xmm14, %xmm12
	pand	%xmm5, %xmm12
	pcmpeqd	.LCPI6_13(%rip), %xmm6
	pand	%xmm7, %xmm6
	pand	16(%rsp), %xmm6                 # 16-byte Folded Reload
	pcmpeqd	%xmm1, %xmm8
	pand	%xmm3, %xmm8
	pand	(%rsp), %xmm8                   # 16-byte Folded Reload
	movdqu	224(%rax), %xmm1
	movdqu	240(%rax), %xmm2
	movdqa	%xmm10, %xmm3
	pxor	%xmm1, %xmm3
	movdqa	.LCPI6_15(%rip), %xmm4          # xmm4 = [56,57,58,59]
	movdqa	%xmm3, %xmm5
	pcmpeqd	%xmm4, %xmm5
	pand	%xmm15, %xmm5
	pxor	%xmm2, %xmm10
	movdqa	.LCPI6_16(%rip), %xmm7          # xmm7 = [60,61,62,63]
	movdqa	%xmm10, %xmm9
	pcmpeqd	%xmm7, %xmm9
	pand	%xmm0, %xmm9
	pand	%xmm5, %xmm9
	pcmpeqd	%xmm13, %xmm3
	pand	%xmm11, %xmm3
	pcmpeqd	%xmm13, %xmm10
	pand	%xmm12, %xmm10
	pand	%xmm3, %xmm10
	pcmpeqd	%xmm4, %xmm1
	pand	%xmm6, %xmm1
	pcmpeqd	%xmm7, %xmm2
	pand	%xmm8, %xmm2
	pand	%xmm1, %xmm2
	pslld	$31, %xmm9
	movmskps	%xmm9, %ebp
	pslld	$31, %xmm2
	movmskps	%xmm2, %eax
	pslld	$31, %xmm10
	movmskps	%xmm10, %edi
	shll	$10, %esi
	orl	$31, %esi
	cmpl	$15, %ebp
	movl	$.L.str.13, %r10d
	movl	$.L.str.12, %ecx
	cmovneq	%r10, %rcx
	cmpl	$15, %edi
	movl	$.L.str.14, %r8d
	cmovneq	%r10, %r8
	cmpl	$15, %eax
	movl	$.L.str.15, %r9d
	cmovneq	%r10, %r9
	movl	$.L.str.11, %edi
	xorl	%eax, %eax
	callq	printf
	cmpl	$15, %ebp
	je	.LBB6_2
# %bb.1:
	movl	$.L.str.16, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	4(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	8(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	12(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	16(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	20(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	24(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	28(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	32(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	36(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	40(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	44(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	48(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	52(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	56(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movq	(%rbx), %rax
	movl	60(%rax), %esi
	movl	$.L.str.17, %edi
	xorl	%eax, %eax
	callq	printf
	movl	$10, %edi
	callq	putchar@PLT
.LBB6_2:
	xorl	%eax, %eax
	cmpb	$15, %bpl
	setne	%al
	addq	$40, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end6:
	.size	_ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j, .Lfunc_end6-_ZZ4mainENKUlPKcRKSt6vectorIjSaIjEEjE_clES0_S5_j
	.cfi_endproc
                                        # -- End function
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
	movq	__hip_gpubin_handle_927f9d48bcce1513(%rip), %rbx
	testq	%rbx, %rbx
	jne	.LBB7_2
# %bb.1:
	movl	$__hip_fatbin_wrapper, %edi
	callq	__hipRegisterFatBinary
	movq	%rax, %rbx
	movq	%rax, __hip_gpubin_handle_927f9d48bcce1513(%rip)
.LBB7_2:
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z22butterfly_group_kernelPKfPf, %esi
	movl	$.L__unnamed_1, %edx
	movl	$.L__unnamed_1, %ecx
	movq	%rbx, %rdi
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z21butterfly_wave_kernelPKfPf, %esi
	movl	$.L__unnamed_2, %edx
	movl	$.L__unnamed_2, %ecx
	movq	%rbx, %rdi
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z18swizzle_map_kernelILj1055EEvPj, %esi
	movl	$.L__unnamed_3, %edx
	movl	$.L__unnamed_3, %ecx
	movq	%rbx, %rdi
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z18swizzle_map_kernelILj2079EEvPj, %esi
	movl	$.L__unnamed_4, %edx
	movl	$.L__unnamed_4, %ecx
	movq	%rbx, %rdi
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movl	$_Z18swizzle_map_kernelILj4127EEvPj, %esi
	movl	$.L__unnamed_5, %edx
	movl	$.L__unnamed_5, %ecx
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
.Lfunc_end7:
	.size	__hip_module_ctor, .Lfunc_end7-__hip_module_ctor
	.cfi_endproc
                                        # -- End function
	.p2align	4                               # -- Begin function __hip_module_dtor
	.type	__hip_module_dtor,@function
__hip_module_dtor:                      # @__hip_module_dtor
	.cfi_startproc
# %bb.0:
	movq	__hip_gpubin_handle_927f9d48bcce1513(%rip), %rdi
	testq	%rdi, %rdi
	je	.LBB8_2
# %bb.1:
	pushq	%rax
	.cfi_def_cfa_offset 16
	callq	__hipUnregisterFatBinary
	movq	$0, __hip_gpubin_handle_927f9d48bcce1513(%rip)
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
.LBB8_2:
	retq
.Lfunc_end8:
	.size	__hip_module_dtor, .Lfunc_end8-__hip_module_dtor
	.cfi_endproc
                                        # -- End function
	.type	_Z22butterfly_group_kernelPKfPf,@object # @_Z22butterfly_group_kernelPKfPf
	.section	.rodata,"a",@progbits
	.globl	_Z22butterfly_group_kernelPKfPf
	.p2align	3, 0x0
_Z22butterfly_group_kernelPKfPf:
	.quad	_Z37__device_stub__butterfly_group_kernelPKfPf
	.size	_Z22butterfly_group_kernelPKfPf, 8

	.type	_Z21butterfly_wave_kernelPKfPf,@object # @_Z21butterfly_wave_kernelPKfPf
	.globl	_Z21butterfly_wave_kernelPKfPf
	.p2align	3, 0x0
_Z21butterfly_wave_kernelPKfPf:
	.quad	_Z36__device_stub__butterfly_wave_kernelPKfPf
	.size	_Z21butterfly_wave_kernelPKfPf, 8

	.type	.L.str,@object                  # @.str
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"HIP %s @%d\n"
	.size	.L.str, 12

	.type	_Z18swizzle_map_kernelILj1055EEvPj,@object # @_Z18swizzle_map_kernelILj1055EEvPj
	.section	.rodata._Z18swizzle_map_kernelILj1055EEvPj,"aG",@progbits,_Z18swizzle_map_kernelILj1055EEvPj,comdat
	.weak	_Z18swizzle_map_kernelILj1055EEvPj
	.p2align	3, 0x0
_Z18swizzle_map_kernelILj1055EEvPj:
	.quad	_Z33__device_stub__swizzle_map_kernelILj1055EEvPj
	.size	_Z18swizzle_map_kernelILj1055EEvPj, 8

	.type	_Z18swizzle_map_kernelILj2079EEvPj,@object # @_Z18swizzle_map_kernelILj2079EEvPj
	.section	.rodata._Z18swizzle_map_kernelILj2079EEvPj,"aG",@progbits,_Z18swizzle_map_kernelILj2079EEvPj,comdat
	.weak	_Z18swizzle_map_kernelILj2079EEvPj
	.p2align	3, 0x0
_Z18swizzle_map_kernelILj2079EEvPj:
	.quad	_Z33__device_stub__swizzle_map_kernelILj2079EEvPj
	.size	_Z18swizzle_map_kernelILj2079EEvPj, 8

	.type	_Z18swizzle_map_kernelILj4127EEvPj,@object # @_Z18swizzle_map_kernelILj4127EEvPj
	.section	.rodata._Z18swizzle_map_kernelILj4127EEvPj,"aG",@progbits,_Z18swizzle_map_kernelILj4127EEvPj,comdat
	.weak	_Z18swizzle_map_kernelILj4127EEvPj
	.p2align	3, 0x0
_Z18swizzle_map_kernelILj4127EEvPj:
	.quad	_Z33__device_stub__swizzle_map_kernelILj4127EEvPj
	.size	_Z18swizzle_map_kernelILj4127EEvPj, 8

	.type	.L.str.4,@object                # @.str.4
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.4:
	.asciz	"3-step butterfly (xor1+2+4) == 8-lane group sum: %s\n"
	.size	.L.str.4, 53

	.type	.L.str.5,@object                # @.str.5
.L.str.5:
	.asciz	"PASS"
	.size	.L.str.5, 5

	.type	.L.str.6,@object                # @.str.6
.L.str.6:
	.asciz	"FAIL"
	.size	.L.str.6, 5

	.type	.L.str.7,@object                # @.str.7
.L.str.7:
	.asciz	"  lane %d: got %g want %g\n"
	.size	.L.str.7, 27

	.type	.L.str.8,@object                # @.str.8
.L.str.8:
	.asciz	"5-step butterfly (xor1..16) == compiled-wave (32) sum: %s (wave sum=%g)\n"
	.size	.L.str.8, 73

	.type	.L.str.9,@object                # @.str.9
.L.str.9:
	.asciz	"  got[0]=%g got[1]=%g got[16]=%g want=%g\n"
	.size	.L.str.9, 42

	.type	.L.str.10,@object               # @.str.10
.L.str.10:
	.asciz	"ds_swizzle_probe: %s\n"
	.size	.L.str.10, 22

	.type	.L.str.11,@object               # @.str.11
.L.str.11:
	.asciz	"code 0x%04X (N=%u): %s%s%s\n"
	.size	.L.str.11, 28

	.type	.L.str.12,@object               # @.str.12
.L.str.12:
	.asciz	"[BUTTERFLY src=i^N] "
	.size	.L.str.12, 21

	.type	.L.str.13,@object               # @.str.13
.L.str.13:
	.zero	1
	.size	.L.str.13, 1

	.type	.L.str.14,@object               # @.str.14
.L.str.14:
	.asciz	"[BROADCAST] "
	.size	.L.str.14, 13

	.type	.L.str.15,@object               # @.str.15
.L.str.15:
	.asciz	"[IDENTITY]"
	.size	.L.str.15, 11

	.type	.L.str.16,@object               # @.str.16
.L.str.16:
	.asciz	"  NOT a butterfly. first 16 entries (lane -> src): "
	.size	.L.str.16, 52

	.type	.L.str.17,@object               # @.str.17
.L.str.17:
	.asciz	"%u "
	.size	.L.str.17, 4

	.type	.L__unnamed_1,@object           # @0
.L__unnamed_1:
	.asciz	"_Z22butterfly_group_kernelPKfPf"
	.size	.L__unnamed_1, 32

	.type	.L__unnamed_2,@object           # @1
.L__unnamed_2:
	.asciz	"_Z21butterfly_wave_kernelPKfPf"
	.size	.L__unnamed_2, 31

	.type	.L__unnamed_3,@object           # @2
.L__unnamed_3:
	.asciz	"_Z18swizzle_map_kernelILj1055EEvPj"
	.size	.L__unnamed_3, 35

	.type	.L__unnamed_4,@object           # @3
.L__unnamed_4:
	.asciz	"_Z18swizzle_map_kernelILj2079EEvPj"
	.size	.L__unnamed_4, 35

	.type	.L__unnamed_5,@object           # @4
.L__unnamed_5:
	.asciz	"_Z18swizzle_map_kernelILj4127EEvPj"
	.size	.L__unnamed_5, 35

	.type	__hip_fatbin_wrapper,@object    # @__hip_fatbin_wrapper
	.section	.hipFatBinSegment,"a",@progbits
	.p2align	3, 0x0
__hip_fatbin_wrapper:
	.long	1212764230                      # 0x48495046
	.long	1                               # 0x1
	.quad	__hip_fatbin_927f9d48bcce1513
	.quad	0
	.size	__hip_fatbin_wrapper, 24

	.type	__hip_gpubin_handle_927f9d48bcce1513,@object # @__hip_gpubin_handle_927f9d48bcce1513
	.local	__hip_gpubin_handle_927f9d48bcce1513
	.comm	__hip_gpubin_handle_927f9d48bcce1513,8,8
	.section	.init_array,"aw",@init_array
	.p2align	3, 0x0
	.quad	__hip_module_ctor
	.type	__hip_cuid_927f9d48bcce1513,@object # @__hip_cuid_927f9d48bcce1513
	.bss
	.globl	__hip_cuid_927f9d48bcce1513
__hip_cuid_927f9d48bcce1513:
	.byte	0                               # 0x0
	.size	__hip_cuid_927f9d48bcce1513, 1

	.ident	"AMD clang version 22.0.0git (https://github.com/RadeonOpenCompute/llvm-project roc-7.2.4 26084 f58b06dce1f9c15707c5f808fd002e18c2accf7e)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.addrsig_sym _Z37__device_stub__butterfly_group_kernelPKfPf
	.addrsig_sym _Z36__device_stub__butterfly_wave_kernelPKfPf
	.addrsig_sym __gxx_personality_v0
	.addrsig_sym _Z33__device_stub__swizzle_map_kernelILj1055EEvPj
	.addrsig_sym _Z33__device_stub__swizzle_map_kernelILj2079EEvPj
	.addrsig_sym _Z33__device_stub__swizzle_map_kernelILj4127EEvPj
	.addrsig_sym __hip_module_ctor
	.addrsig_sym __hip_module_dtor
	.addrsig_sym _Unwind_Resume
	.addrsig_sym _Z22butterfly_group_kernelPKfPf
	.addrsig_sym _Z21butterfly_wave_kernelPKfPf
	.addrsig_sym _Z18swizzle_map_kernelILj1055EEvPj
	.addrsig_sym _Z18swizzle_map_kernelILj2079EEvPj
	.addrsig_sym _Z18swizzle_map_kernelILj4127EEvPj
	.addrsig_sym __hip_fatbin_927f9d48bcce1513
	.addrsig_sym __hip_fatbin_wrapper
	.addrsig_sym __hip_cuid_927f9d48bcce1513

# __CLANG_OFFLOAD_BUNDLE____END__ host-x86_64-unknown-linux-gnu-
