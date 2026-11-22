
proto.co:	file format elf64-amdgpu
	.amdgcn_target "amdgcn-amd-amdhsa-unknown-gfx1030"

Disassembly of section .text:

0000000000001d00 <_Z15producer_kernelP3CmdiyiPj>:
	s_clause 0x1                                               // 000000001D00: BFA10001
	s_load_dword s0, s[4:5], 0x34                              // 000000001D04: F4000002 FA000034
	s_load_dword s1, s[4:5], 0x8                               // 000000001D0C: F4000042 FA000008
	s_waitcnt lgkmcnt(0)                                       // 000000001D14: BF8CC07F
	s_and_b32 s0, s0, 0xffff                                   // 000000001D18: 8700FF00 0000FFFF
	v_mad_u64_u32 v[0:1], null, s6, s0, v[0:1]                 // 000000001D20: D5767D00 04000006
	s_mov_b32 s0, exec_lo                                      // 000000001D28: BE80037E
	v_cmpx_gt_i32_e32 s1, v0                                   // 000000001D2C: 7D280001
	s_cbranch_execz 69                                         // 000000001D30: BF880045 <_Z15producer_kernelP3CmdiyiPj+0x148>
	s_clause 0x2                                               // 000000001D34: BFA10002
	s_load_dwordx2 s[0:1], s[4:5], 0x10                        // 000000001D38: F4040002 FA000010
	s_load_dwordx2 s[2:3], s[4:5], null                        // 000000001D40: F4040082 FA000000
	s_load_dword s4, s[4:5], 0x18                              // 000000001D48: F4000102 FA000018
	v_ashrrev_i32_e32 v1, 31, v0                               // 000000001D50: 3002009F
	s_waitcnt lgkmcnt(0)                                       // 000000001D54: BF8CC07F
	v_add_co_u32 v18, vcc_lo, s0, v0                           // 000000001D58: D70F6A12 02020000
	v_add_co_ci_u32_e64 v19, null, s1, v1, vcc_lo              // 000000001D60: D5287D13 01AA0201
	v_mad_i64_i32 v[0:1], null, 0x50, v0, s[2:3]               // 000000001D68: D5777D00 000A00FF 00000050
	v_mul_lo_u32 v2, 0x9e3779b1, v18                           // 000000001D74: D5690002 020224FF 9E3779B1
	s_cmp_eq_u32 s4, 0                                         // 000000001D80: BF068004
	v_xor_b32_e32 v3, 0x9e3779b9, v2                           // 000000001D84: 3A0604FF 9E3779B9
	v_xor_b32_e32 v4, 0x3c6ef372, v2                           // 000000001D8C: 3A0804FF 3C6EF372
	v_xor_b32_e32 v5, 0xdaa66d2b, v2                           // 000000001D94: 3A0A04FF DAA66D2B
	v_xor_b32_e32 v6, 0x78dde6e4, v2                           // 000000001D9C: 3A0C04FF 78DDE6E4
	v_xor_b32_e32 v7, 0x1715609d, v2                           // 000000001DA4: 3A0E04FF 1715609D
	v_xor_b32_e32 v8, 0xb54cda56, v2                           // 000000001DAC: 3A1004FF B54CDA56
	v_xor_b32_e32 v9, 0x5384540f, v2                           // 000000001DB4: 3A1204FF 5384540F
	v_xor_b32_e32 v10, 0xf1bbcdc8, v2                          // 000000001DBC: 3A1404FF F1BBCDC8
	v_xor_b32_e32 v11, 0x8ff34781, v2                          // 000000001DC4: 3A1604FF 8FF34781
	v_xor_b32_e32 v12, 0x2e2ac13a, v2                          // 000000001DCC: 3A1804FF 2E2AC13A
	v_xor_b32_e32 v13, 0xcc623af3, v2                          // 000000001DD4: 3A1A04FF CC623AF3
	v_xor_b32_e32 v14, 0x6a99b4ac, v2                          // 000000001DDC: 3A1C04FF 6A99B4AC
	v_xor_b32_e32 v15, 0x8d12e65, v2                           // 000000001DE4: 3A1E04FF 08D12E65
	v_xor_b32_e32 v16, 0xa708a81e, v2                          // 000000001DEC: 3A2004FF A708A81E
	v_xor_b32_e32 v17, 0x454021d7, v2                          // 000000001DF4: 3A2204FF 454021D7
	global_store_dwordx4 v[0:1], v[2:5], off offset:16         // 000000001DFC: DC788010 007D0200
	global_store_dwordx4 v[0:1], v[6:9], off offset:32         // 000000001E04: DC788020 007D0600
	global_store_dwordx4 v[0:1], v[10:13], off offset:48       // 000000001E0C: DC788030 007D0A00
	global_store_dwordx4 v[0:1], v[14:17], off offset:64       // 000000001E14: DC788040 007D0E00
	global_store_dwordx2 v[0:1], v[18:19], off offset:8        // 000000001E1C: DC748008 007D1200
	s_cbranch_scc1 5                                           // 000000001E24: BF850005 <_Z15producer_kernelP3CmdiyiPj+0x13c>
	s_waitcnt_vscnt null, 0x0                                  // 000000001E28: BBFD0000
	buffer_gl1_inv                                             // 000000001E2C: E1C80000 00000000
	buffer_gl0_inv                                             // 000000001E34: E1C40000 00000000
	v_mov_b32_e32 v2, 1                                        // 000000001E3C: 7E040281
	flat_store_dword v[0:1], v2                                // 000000001E40: DC700000 007D0200
	s_endpgm                                                   // 000000001E48: BF810000
	s_nop 0                                                    // 000000001E4C: BF800000
	s_nop 0                                                    // 000000001E50: BF800000
	s_nop 0                                                    // 000000001E54: BF800000
	s_nop 0                                                    // 000000001E58: BF800000
	s_nop 0                                                    // 000000001E5C: BF800000
	s_nop 0                                                    // 000000001E60: BF800000
	s_nop 0                                                    // 000000001E64: BF800000
	s_nop 0                                                    // 000000001E68: BF800000
	s_nop 0                                                    // 000000001E6C: BF800000
	s_nop 0                                                    // 000000001E70: BF800000
	s_nop 0                                                    // 000000001E74: BF800000
	s_nop 0                                                    // 000000001E78: BF800000
	s_nop 0                                                    // 000000001E7C: BF800000
	s_nop 0                                                    // 000000001E80: BF800000
	s_nop 0                                                    // 000000001E84: BF800000
	s_nop 0                                                    // 000000001E88: BF800000
	s_nop 0                                                    // 000000001E8C: BF800000
	s_nop 0                                                    // 000000001E90: BF800000
	s_nop 0                                                    // 000000001E94: BF800000
	s_nop 0                                                    // 000000001E98: BF800000
	s_nop 0                                                    // 000000001E9C: BF800000
	s_nop 0                                                    // 000000001EA0: BF800000
	s_nop 0                                                    // 000000001EA4: BF800000
	s_nop 0                                                    // 000000001EA8: BF800000
	s_nop 0                                                    // 000000001EAC: BF800000
	s_nop 0                                                    // 000000001EB0: BF800000
	s_nop 0                                                    // 000000001EB4: BF800000
	s_nop 0                                                    // 000000001EB8: BF800000
	s_nop 0                                                    // 000000001EBC: BF800000
	s_nop 0                                                    // 000000001EC0: BF800000
	s_nop 0                                                    // 000000001EC4: BF800000
	s_nop 0                                                    // 000000001EC8: BF800000
	s_nop 0                                                    // 000000001ECC: BF800000
	s_nop 0                                                    // 000000001ED0: BF800000
	s_nop 0                                                    // 000000001ED4: BF800000
	s_nop 0                                                    // 000000001ED8: BF800000
	s_nop 0                                                    // 000000001EDC: BF800000
	s_nop 0                                                    // 000000001EE0: BF800000
	s_nop 0                                                    // 000000001EE4: BF800000
	s_nop 0                                                    // 000000001EE8: BF800000
	s_nop 0                                                    // 000000001EEC: BF800000
	s_nop 0                                                    // 000000001EF0: BF800000
	s_nop 0                                                    // 000000001EF4: BF800000
	s_nop 0                                                    // 000000001EF8: BF800000
	s_nop 0                                                    // 000000001EFC: BF800000

0000000000001f00 <_Z13waiter_kernelPViPyi>:
	v_or_b32_e32 v0, s6, v0                                    // 000000001F00: 38000006
	s_mov_b32 s0, exec_lo                                      // 000000001F04: BE80037E
	v_cmpx_eq_u32_e32 0, v0                                    // 000000001F08: 7DA40080
	s_cbranch_execz 24                                         // 000000001F0C: BF880018 <_Z13waiter_kernelPViPyi+0x70>
	s_load_dwordx4 s[0:3], s[4:5], null                        // 000000001F10: F4080002 FA000000
	v_mov_b32_e32 v0, 0                                        // 000000001F18: 7E000280
	s_memtime s[6:7]                                           // 000000001F1C: F4900180 00000000
	s_waitcnt lgkmcnt(0)                                       // 000000001F24: BF8CC07F
	global_load_dword v1, v0, s[0:1] glc dlc                   // 000000001F28: DC319000 01000000
	s_waitcnt vmcnt(0)                                         // 000000001F30: BF8C3F70
	v_cmp_ne_u32_e32 vcc_lo, 0, v1                             // 000000001F34: 7D8A0280
	s_cbranch_vccz 14                                          // 000000001F38: BF86000E <_Z13waiter_kernelPViPyi+0x74>
	s_memtime s[0:1]                                           // 000000001F3C: F4900000 00000000
	s_waitcnt lgkmcnt(0)                                       // 000000001F44: BF8CC07F
	buffer_gl1_inv                                             // 000000001F48: E1C80000 00000000
	buffer_gl0_inv                                             // 000000001F50: E1C40000 00000000
	s_sub_u32 s0, s0, s6                                       // 000000001F58: 80800600
	s_subb_u32 s1, s1, s7                                      // 000000001F5C: 82810701
	v_mov_b32_e32 v1, s0                                       // 000000001F60: 7E020200
	v_mov_b32_e32 v2, s1                                       // 000000001F64: 7E040201
	global_store_dwordx2 v0, v[1:2], s[2:3]                    // 000000001F68: DC748000 00020100
	s_endpgm                                                   // 000000001F70: BF810000
	s_load_dword s4, s[4:5], 0x10                              // 000000001F74: F4000102 FA000010
	s_waitcnt lgkmcnt(0)                                       // 000000001F7C: BF8CC07F
	s_cmp_lg_u32 s4, 0                                         // 000000001F80: BF078004
	s_cselect_b32 s4, -1, 0                                    // 000000001F84: 850480C1
	s_branch 5                                                 // 000000001F88: BF820005 <_Z13waiter_kernelPViPyi+0xa0>
	global_load_dword v1, v0, s[0:1] glc dlc                   // 000000001F8C: DC319000 01000000
	s_waitcnt vmcnt(0)                                         // 000000001F94: BF8C3F70
	v_cmp_eq_u32_e32 vcc_lo, 0, v1                             // 000000001F98: 7D840280
	s_cbranch_vccz 65511                                       // 000000001F9C: BF86FFE7 <_Z13waiter_kernelPViPyi+0x3c>
	s_and_b32 s5, s4, exec_lo                                  // 000000001FA0: 87057E04
	s_cselect_b32 s5, 1, 0                                     // 000000001FA4: 85058081
	s_cmp_lg_u32 s5, 1                                         // 000000001FA8: BF078105
	s_cbranch_scc1 65527                                       // 000000001FAC: BF85FFF7 <_Z13waiter_kernelPViPyi+0x8c>
	s_sleep 2                                                  // 000000001FB0: BF8E0002
	s_branch 65525                                             // 000000001FB4: BF82FFF5 <_Z13waiter_kernelPViPyi+0x8c>
	s_code_end                                                 // 000000001FB8: BF9F0000
	s_code_end                                                 // 000000001FBC: BF9F0000
	s_code_end                                                 // 000000001FC0: BF9F0000
	s_code_end                                                 // 000000001FC4: BF9F0000
	s_code_end                                                 // 000000001FC8: BF9F0000
	s_code_end                                                 // 000000001FCC: BF9F0000
	s_code_end                                                 // 000000001FD0: BF9F0000
	s_code_end                                                 // 000000001FD4: BF9F0000
	s_code_end                                                 // 000000001FD8: BF9F0000
	s_code_end                                                 // 000000001FDC: BF9F0000
	s_code_end                                                 // 000000001FE0: BF9F0000
	s_code_end                                                 // 000000001FE4: BF9F0000
	s_code_end                                                 // 000000001FE8: BF9F0000
	s_code_end                                                 // 000000001FEC: BF9F0000
	s_code_end                                                 // 000000001FF0: BF9F0000
	s_code_end                                                 // 000000001FF4: BF9F0000
	s_code_end                                                 // 000000001FF8: BF9F0000
	s_code_end                                                 // 000000001FFC: BF9F0000
	s_code_end                                                 // 000000002000: BF9F0000
	s_code_end                                                 // 000000002004: BF9F0000
	s_code_end                                                 // 000000002008: BF9F0000
	s_code_end                                                 // 00000000200C: BF9F0000
	s_code_end                                                 // 000000002010: BF9F0000
	s_code_end                                                 // 000000002014: BF9F0000
	s_code_end                                                 // 000000002018: BF9F0000
	s_code_end                                                 // 00000000201C: BF9F0000
	s_code_end                                                 // 000000002020: BF9F0000
	s_code_end                                                 // 000000002024: BF9F0000
	s_code_end                                                 // 000000002028: BF9F0000
	s_code_end                                                 // 00000000202C: BF9F0000
	s_code_end                                                 // 000000002030: BF9F0000
	s_code_end                                                 // 000000002034: BF9F0000
	s_code_end                                                 // 000000002038: BF9F0000
	s_code_end                                                 // 00000000203C: BF9F0000
	s_code_end                                                 // 000000002040: BF9F0000
	s_code_end                                                 // 000000002044: BF9F0000
	s_code_end                                                 // 000000002048: BF9F0000
	s_code_end                                                 // 00000000204C: BF9F0000
	s_code_end                                                 // 000000002050: BF9F0000
	s_code_end                                                 // 000000002054: BF9F0000
	s_code_end                                                 // 000000002058: BF9F0000
	s_code_end                                                 // 00000000205C: BF9F0000
	s_code_end                                                 // 000000002060: BF9F0000
	s_code_end                                                 // 000000002064: BF9F0000
	s_code_end                                                 // 000000002068: BF9F0000
	s_code_end                                                 // 00000000206C: BF9F0000
	s_code_end                                                 // 000000002070: BF9F0000
	s_code_end                                                 // 000000002074: BF9F0000
	s_code_end                                                 // 000000002078: BF9F0000
	s_code_end                                                 // 00000000207C: BF9F0000
