
/home/zhuo/workspace/src/rocm-demo/demos/mori/compiler/shmem_bitcode_pipeline/results/ir/api_ref.codegen.co:	file format elf64-amdgpu
	.amdgcn_target "amdgcn-amd-amdhsa-unknown-gfx1030"

Disassembly of section .text:

0000000000001b00 <_ZN4mori5shmem14device_add_oneEPjPKji>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000001B00: BF8C0000
	v_and_b32_e32 v5, 0x3ff, v31                               // 000000001B04: 360A3EFF 000003FF
	s_mov_b32 s5, exec_lo                                      // 000000001B0C: BE85037E
	v_cmpx_lt_i32_e32 v5, v4                                   // 000000001B10: 7D220905
	s_cbranch_execz 48                                         // 000000001B14: BF880030 <_ZN4mori5shmem14device_add_oneEPjPKji+0xd8>
	v_mov_b32_e32 v6, 0                                        // 000000001B18: 7E0C0280
	s_getpc_b64 s[6:7]                                         // 000000001B1C: BE861F00
	s_add_u32 s6, s6, 0x22b0                                   // 000000001B20: 8006FF06 000022B0
	s_addc_u32 s7, s7, lit(0x0)                                // 000000001B28: 8207FF07 00000000
	s_load_dword s4, s[8:9], 0xc                               // 000000001B30: F4000104 FA00000C
	global_load_dword v7, v6, s[6:7]                           // 000000001B38: DC308000 07060006
	s_mov_b32 s7, 0                                            // 000000001B40: BE870380
	s_waitcnt lgkmcnt(0)                                       // 000000001B44: BF8CC07F
	s_and_b32 s6, s4, 0xffff                                   // 000000001B48: 8706FF04 0000FFFF
	s_nop 0                                                    // 000000001B50: BF800000
	s_nop 0                                                    // 000000001B54: BF800000
	s_nop 0                                                    // 000000001B58: BF800000
	s_nop 0                                                    // 000000001B5C: BF800000
	s_nop 0                                                    // 000000001B60: BF800000
	s_nop 0                                                    // 000000001B64: BF800000
	s_nop 0                                                    // 000000001B68: BF800000
	s_nop 0                                                    // 000000001B6C: BF800000
	s_nop 0                                                    // 000000001B70: BF800000
	s_nop 0                                                    // 000000001B74: BF800000
	s_nop 0                                                    // 000000001B78: BF800000
	s_nop 0                                                    // 000000001B7C: BF800000
	v_ashrrev_i32_e32 v6, 31, v5                               // 000000001B80: 300C0A9F
	v_lshlrev_b64 v[8:9], 2, v[5:6]                            // 000000001B84: D6FF0008 02020A82
	v_add_nc_u32_e32 v5, s6, v5                                // 000000001B8C: 4A0A0A06
	v_add_co_u32 v10, vcc_lo, v2, v8                           // 000000001B90: D70F6A0A 02021102
	v_add_co_ci_u32_e64 v11, null, v3, v9, vcc_lo              // 000000001B98: D5287D0B 01AA1303
	v_cmp_ge_i32_e32 vcc_lo, v5, v4                            // 000000001BA0: 7D0C0905
	v_add_co_u32 v8, s4, v0, v8                                // 000000001BA4: D70F0408 02021100
	flat_load_dword v6, v[10:11]                               // 000000001BAC: DC300000 067D000A
	v_add_co_ci_u32_e64 v9, null, v1, v9, s4                   // 000000001BB4: D5287D09 00121301
	s_or_b32 s7, vcc_lo, s7                                    // 000000001BBC: 8807076A
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000001BC0: BF8C0070
	v_add_nc_u32_e32 v6, v6, v7                                // 000000001BC4: 4A0C0F06
	flat_store_dword v[8:9], v6                                // 000000001BC8: DC700000 007D0608
	s_andn2_b32 exec_lo, exec_lo, s7                           // 000000001BD0: 8A7E077E
	s_cbranch_execnz 65514                                     // 000000001BD4: BF89FFEA <_ZN4mori5shmem14device_add_oneEPjPKji+0x80>
	s_or_b32 exec_lo, exec_lo, s5                              // 000000001BD8: 887E057E
	s_waitcnt lgkmcnt(0)                                       // 000000001BDC: BF8CC07F
	s_setpc_b64 s[30:31]                                       // 000000001BE0: BE80201E
		...

0000000000001c00 <__cxa_pure_virtual>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000001C00: BF8C0000
	s_trap 2                                                   // 000000001C04: BF920002
		...

0000000000001c40 <__cxa_deleted_virtual>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000001C40: BF8C0000
	s_trap 2                                                   // 000000001C44: BF920002
		...

0000000000001d00 <shmem_internal_test_kernel>:
	s_clause 0x1                                               // 000000001D00: BFA10001
	s_load_dwordx4 s[12:15], s[4:5], null                      // 000000001D04: F4080302 FA000000
	s_load_dword s6, s[4:5], 0x10                              // 000000001D0C: F4000182 FA000010
	s_add_u32 s0, s0, s7                                       // 000000001D14: 80000700
	s_addc_u32 s1, s1, 0                                       // 000000001D18: 82018001
	v_mov_b32_e32 v31, v0                                      // 000000001D1C: 7E3E0300
	s_add_u32 s8, s4, 24                                       // 000000001D20: 80089804
	s_addc_u32 s9, s5, 0                                       // 000000001D24: 82098005
	s_getpc_b64 s[4:5]                                         // 000000001D28: BE841F00
	s_add_u32 s4, s4, 0xfffffdd4                               // 000000001D2C: 8004FF04 FFFFFDD4
	s_addc_u32 s5, s5, lit(0xffffffff)                         // 000000001D34: 8205FF05 FFFFFFFF
	s_mov_b32 s32, 0                                           // 000000001D3C: BEA00380
	s_waitcnt lgkmcnt(0)                                       // 000000001D40: BF8CC07F
	v_mov_b32_e32 v0, s12                                      // 000000001D44: 7E00020C
	v_mov_b32_e32 v1, s13                                      // 000000001D48: 7E02020D
	v_mov_b32_e32 v2, s14                                      // 000000001D4C: 7E04020E
	v_mov_b32_e32 v3, s15                                      // 000000001D50: 7E06020F
	v_mov_b32_e32 v4, s6                                       // 000000001D54: 7E080206
	s_swappc_b64 s[30:31], s[4:5]                              // 000000001D58: BE9E2104
	s_endpgm                                                   // 000000001D5C: BF810000
