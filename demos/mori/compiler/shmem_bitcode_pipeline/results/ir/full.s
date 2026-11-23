
/home/zhuo/workspace/src/rocm-demo/demos/mori/compiler/shmem_bitcode_pipeline/results/ir/full.co:	file format elf64-amdgpu
	.amdgcn_target "amdgcn-amd-amdhsa-unknown-gfx1030"

Disassembly of section .text:

0000000000002300 <__cxa_pure_virtual>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000002300: BF8C0000
	s_trap 2                                                   // 000000002304: BF920002
	s_nop 0                                                    // 000000002308: BF800000
	s_nop 0                                                    // 00000000230C: BF800000
	s_nop 0                                                    // 000000002310: BF800000
	s_nop 0                                                    // 000000002314: BF800000
	s_nop 0                                                    // 000000002318: BF800000
	s_nop 0                                                    // 00000000231C: BF800000
	s_nop 0                                                    // 000000002320: BF800000
	s_nop 0                                                    // 000000002324: BF800000
	s_nop 0                                                    // 000000002328: BF800000
	s_nop 0                                                    // 00000000232C: BF800000
	s_nop 0                                                    // 000000002330: BF800000
	s_nop 0                                                    // 000000002334: BF800000
	s_nop 0                                                    // 000000002338: BF800000
	s_nop 0                                                    // 00000000233C: BF800000

0000000000002340 <__cxa_deleted_virtual>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000002340: BF8C0000
	s_trap 2                                                   // 000000002344: BF920002
	s_nop 0                                                    // 000000002348: BF800000
	s_nop 0                                                    // 00000000234C: BF800000
	s_nop 0                                                    // 000000002350: BF800000
	s_nop 0                                                    // 000000002354: BF800000
	s_nop 0                                                    // 000000002358: BF800000
	s_nop 0                                                    // 00000000235C: BF800000
	s_nop 0                                                    // 000000002360: BF800000
	s_nop 0                                                    // 000000002364: BF800000
	s_nop 0                                                    // 000000002368: BF800000
	s_nop 0                                                    // 00000000236C: BF800000
	s_nop 0                                                    // 000000002370: BF800000
	s_nop 0                                                    // 000000002374: BF800000
	s_nop 0                                                    // 000000002378: BF800000
	s_nop 0                                                    // 00000000237C: BF800000

0000000000002380 <__ockl_fprintf_append_string_n>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000002380: BF8C0000
	s_load_dwordx2 s[6:7], s[8:9], 0x50                        // 000000002384: F4040184 FA000050
	v_mov_b32_e32 v7, v3                                       // 00000000238C: 7E0E0303
	v_mov_b32_e32 v6, v2                                       // 000000002390: 7E0C0302
	v_mbcnt_lo_u32_b32 v30, -1, 0                              // 000000002394: D765001E 020100C1
	s_mov_b32 s13, 0                                           // 00000000239C: BE8D0380
	s_mov_b32 s4, exec_lo                                      // 0000000023A0: BE84037E
	v_cmpx_ne_u64_e32 0, v[6:7]                                // 0000000023A4: 7DEA0C80
	s_xor_b32 s12, exec_lo, s4                                 // 0000000023A8: 890C047E
	s_cbranch_execz 690                                        // 0000000023AC: BF8802B2 <__ockl_fprintf_append_string_n+0xaf8>
	v_and_b32_e32 v0, -3, v0                                   // 0000000023B0: 360000C3
	v_mov_b32_e32 v9, 0                                        // 0000000023B4: 7E120280
	v_lshlrev_b32_e32 v31, 6, v30                              // 0000000023B8: 343E3C86
	v_mov_b32_e32 v10, 2                                       // 0000000023BC: 7E140282
	v_mov_b32_e32 v11, 1                                       // 0000000023C0: 7E160281
	s_mov_b32 s14, 0                                           // 0000000023C4: BE8E0380
	s_branch 13                                                // 0000000023C8: BF82000D <__ockl_fprintf_append_string_n+0x80>
	s_or_b32 exec_lo, exec_lo, s10                             // 0000000023CC: 887E0A7E
	v_sub_co_u32 v4, vcc_lo, v4, v32                           // 0000000023D0: D7106A04 02024104
	v_sub_co_ci_u32_e64 v5, null, v5, v33, vcc_lo              // 0000000023D8: D5297D05 01AA4305
	v_add_co_u32 v6, s4, v6, v32                               // 0000000023E0: D70F0406 02024106
	v_add_co_ci_u32_e64 v7, null, v7, v33, s4                  // 0000000023E8: D5287D07 00124307
	v_cmp_eq_u64_e32 vcc_lo, 0, v[4:5]                         // 0000000023F0: 7DC40880
	s_or_b32 s14, vcc_lo, s14                                  // 0000000023F4: 880E0E6A
	s_andn2_b32 exec_lo, exec_lo, s14                          // 0000000023F8: 8A7E0E7E
	s_cbranch_execz 669                                        // 0000000023FC: BF88029D <__ockl_fprintf_append_string_n+0xaf4>
	v_cmp_gt_u64_e32 vcc_lo, 56, v[4:5]                        // 000000002400: 7DC808B8
	s_mov_b32 s5, exec_lo                                      // 000000002404: BE85037E
	v_cndmask_b32_e32 v32, 56, v4, vcc_lo                      // 000000002408: 024008B8
	v_cmpx_gt_u64_e32 8, v[4:5]                                // 00000000240C: 7DE80888
	s_xor_b32 s5, exec_lo, s5                                  // 000000002410: 8905057E
	s_cbranch_execz 33                                         // 000000002414: BF880021 <__ockl_fprintf_append_string_n+0x11c>
	s_waitcnt vmcnt(0)                                         // 000000002418: BF8C3F70
	v_mov_b32_e32 v2, 0                                        // 00000000241C: 7E040280
	v_mov_b32_e32 v3, 0                                        // 000000002420: 7E060280
	s_mov_b32 s8, exec_lo                                      // 000000002424: BE88037E
	v_cmpx_ne_u64_e32 0, v[4:5]                                // 000000002428: 7DEA0880
	s_cbranch_execz 26                                         // 00000000242C: BF88001A <__ockl_fprintf_append_string_n+0x118>
	v_mov_b32_e32 v2, 0                                        // 000000002430: 7E040280
	v_mov_b32_e32 v3, 0                                        // 000000002434: 7E060280
	s_mov_b32 s9, 0                                            // 000000002438: BE890380
	s_mov_b32 s10, 0                                           // 00000000243C: BE8A0380
	v_add_co_u32 v12, s4, v6, s10                              // 000000002440: D70F040C 02001506
	v_add_co_ci_u32_e64 v13, null, 0, v7, s4                   // 000000002448: D5287D0D 00120E80
	s_lshl_b32 s4, s10, 3                                      // 000000002450: 8F04830A
	s_add_i32 s10, s10, 1                                      // 000000002454: 810A810A
	flat_load_ubyte v8, v[12:13]                               // 000000002458: DC200000 087D000C
	v_mov_b32_e32 v13, s13                                     // 000000002460: 7E1A020D
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000002464: BF8C0070
	v_and_b32_e32 v12, 0xffff, v8                              // 000000002468: 361810FF 0000FFFF
	v_lshlrev_b64 v[12:13], s4, v[12:13]                       // 000000002470: D6FF000C 02021804
	v_cmp_eq_u32_e64 s4, s10, v32                              // 000000002478: D4C20004 0202400A
	s_or_b32 s9, s4, s9                                        // 000000002480: 88090904
	v_or_b32_e32 v3, v13, v3                                   // 000000002484: 3806070D
	v_or_b32_e32 v2, v12, v2                                   // 000000002488: 3804050C
	s_andn2_b32 exec_lo, exec_lo, s9                           // 00000000248C: 8A7E097E
	s_cbranch_execnz 65515                                     // 000000002490: BF89FFEB <__ockl_fprintf_append_string_n+0xc0>
	s_or_b32 exec_lo, exec_lo, s9                              // 000000002494: 887E097E
	s_or_b32 exec_lo, exec_lo, s8                              // 000000002498: 887E087E
	s_or_saveexec_b32 s5, s5                                   // 00000000249C: BE853D05
	v_mov_b32_e32 v8, 0                                        // 0000000024A0: 7E100280
	v_mov_b32_e32 v25, v7                                      // 0000000024A4: 7E320307
	v_mov_b32_e32 v24, v6                                      // 0000000024A8: 7E300306
	s_xor_b32 exec_lo, exec_lo, s5                             // 0000000024AC: 897E057E
	s_cbranch_execz 8                                          // 0000000024B0: BF880008 <__ockl_fprintf_append_string_n+0x154>
	s_waitcnt vmcnt(0)                                         // 0000000024B4: BF8C3F70
	flat_load_dwordx2 v[2:3], v[6:7]                           // 0000000024B8: DC340000 027D0006
	v_add_co_u32 v24, s4, v6, 8                                // 0000000024C0: D70F0418 02011106
	v_add_nc_u32_e32 v8, -8, v32                               // 0000000024C8: 4A1040C8
	v_add_co_ci_u32_e64 v25, null, 0, v7, s4                   // 0000000024CC: D5287D19 00120E80
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000024D4: 887E057E
	s_mov_b32 s5, exec_lo                                      // 0000000024D8: BE85037E
	v_cmpx_gt_u32_e32 8, v8                                    // 0000000024DC: 7DA81088
	s_xor_b32 s5, exec_lo, s5                                  // 0000000024E0: 8905057E
	s_cbranch_execz 45                                         // 0000000024E4: BF88002D <__ockl_fprintf_append_string_n+0x21c>
	v_mov_b32_e32 v12, 0                                       // 0000000024E8: 7E180280
	v_mov_b32_e32 v13, 0                                       // 0000000024EC: 7E1A0280
	s_mov_b32 s8, exec_lo                                      // 0000000024F0: BE88037E
	v_cmpx_ne_u32_e32 0, v8                                    // 0000000024F4: 7DAA1080
	s_cbranch_execz 39                                         // 0000000024F8: BF880027 <__ockl_fprintf_append_string_n+0x218>
	v_mov_b32_e32 v12, 0                                       // 0000000024FC: 7E180280
	v_mov_b32_e32 v13, 0                                       // 000000002500: 7E1A0280
	s_mov_b32 s9, 0                                            // 000000002504: BE890380
	s_mov_b32 s10, 0                                           // 000000002508: BE8A0380
	s_nop 0                                                    // 00000000250C: BF800000
	s_nop 0                                                    // 000000002510: BF800000
	s_nop 0                                                    // 000000002514: BF800000
	s_nop 0                                                    // 000000002518: BF800000
	s_nop 0                                                    // 00000000251C: BF800000
	s_nop 0                                                    // 000000002520: BF800000
	s_nop 0                                                    // 000000002524: BF800000
	s_nop 0                                                    // 000000002528: BF800000
	s_nop 0                                                    // 00000000252C: BF800000
	s_nop 0                                                    // 000000002530: BF800000
	s_nop 0                                                    // 000000002534: BF800000
	s_nop 0                                                    // 000000002538: BF800000
	s_nop 0                                                    // 00000000253C: BF800000
	v_add_co_u32 v14, s4, v24, s10                             // 000000002540: D70F040E 02001518
	v_add_co_ci_u32_e64 v15, null, 0, v25, s4                  // 000000002548: D5287D0F 00123280
	s_lshl_b32 s4, s10, 3                                      // 000000002550: 8F04830A
	s_add_i32 s10, s10, 1                                      // 000000002554: 810A810A
	flat_load_ubyte v14, v[14:15]                              // 000000002558: DC200000 0E7D000E
	v_mov_b32_e32 v15, s13                                     // 000000002560: 7E1E020D
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000002564: BF8C0070
	v_and_b32_e32 v14, 0xffff, v14                             // 000000002568: 361C1CFF 0000FFFF
	v_lshlrev_b64 v[14:15], s4, v[14:15]                       // 000000002570: D6FF000E 02021C04
	v_cmp_eq_u32_e64 s4, s10, v8                               // 000000002578: D4C20004 0202100A
	s_or_b32 s9, s4, s9                                        // 000000002580: 88090904
	v_or_b32_e32 v13, v15, v13                                 // 000000002584: 381A1B0F
	v_or_b32_e32 v12, v14, v12                                 // 000000002588: 3818190E
	s_andn2_b32 exec_lo, exec_lo, s9                           // 00000000258C: 8A7E097E
	s_cbranch_execnz 65515                                     // 000000002590: BF89FFEB <__ockl_fprintf_append_string_n+0x1c0>
	s_or_b32 exec_lo, exec_lo, s9                              // 000000002594: 887E097E
	s_or_b32 exec_lo, exec_lo, s8                              // 000000002598: 887E087E
	s_or_saveexec_b32 s5, s5                                   // 00000000259C: BE853D05
	v_mov_b32_e32 v16, 0                                       // 0000000025A0: 7E200280
	s_xor_b32 exec_lo, exec_lo, s5                             // 0000000025A4: 897E057E
	s_cbranch_execz 7                                          // 0000000025A8: BF880007 <__ockl_fprintf_append_string_n+0x248>
	flat_load_dwordx2 v[12:13], v[24:25]                       // 0000000025AC: DC340000 0C7D0018
	v_add_co_u32 v24, s4, v24, 8                               // 0000000025B4: D70F0418 02011118
	v_add_nc_u32_e32 v16, -8, v8                               // 0000000025BC: 4A2010C8
	v_add_co_ci_u32_e64 v25, null, 0, v25, s4                  // 0000000025C0: D5287D19 00123280
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000025C8: 887E057E
	s_mov_b32 s5, exec_lo                                      // 0000000025CC: BE85037E
	v_cmpx_gt_u32_e32 8, v16                                   // 0000000025D0: 7DA82088
	s_xor_b32 s5, exec_lo, s5                                  // 0000000025D4: 8905057E
	s_cbranch_execz 32                                         // 0000000025D8: BF880020 <__ockl_fprintf_append_string_n+0x2dc>
	v_mov_b32_e32 v14, 0                                       // 0000000025DC: 7E1C0280
	v_mov_b32_e32 v15, 0                                       // 0000000025E0: 7E1E0280
	s_mov_b32 s8, exec_lo                                      // 0000000025E4: BE88037E
	v_cmpx_ne_u32_e32 0, v16                                   // 0000000025E8: 7DAA2080
	s_cbranch_execz 26                                         // 0000000025EC: BF88001A <__ockl_fprintf_append_string_n+0x2d8>
	v_mov_b32_e32 v14, 0                                       // 0000000025F0: 7E1C0280
	v_mov_b32_e32 v15, 0                                       // 0000000025F4: 7E1E0280
	s_mov_b32 s9, 0                                            // 0000000025F8: BE890380
	s_mov_b32 s10, 0                                           // 0000000025FC: BE8A0380
	v_add_co_u32 v17, s4, v24, s10                             // 000000002600: D70F0411 02001518
	v_add_co_ci_u32_e64 v18, null, 0, v25, s4                  // 000000002608: D5287D12 00123280
	s_lshl_b32 s4, s10, 3                                      // 000000002610: 8F04830A
	s_add_i32 s10, s10, 1                                      // 000000002614: 810A810A
	flat_load_ubyte v8, v[17:18]                               // 000000002618: DC200000 087D0011
	v_mov_b32_e32 v18, s13                                     // 000000002620: 7E24020D
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000002624: BF8C0070
	v_and_b32_e32 v17, 0xffff, v8                              // 000000002628: 362210FF 0000FFFF
	v_lshlrev_b64 v[17:18], s4, v[17:18]                       // 000000002630: D6FF0011 02022204
	v_cmp_eq_u32_e64 s4, s10, v16                              // 000000002638: D4C20004 0202200A
	s_or_b32 s9, s4, s9                                        // 000000002640: 88090904
	v_or_b32_e32 v15, v18, v15                                 // 000000002644: 381E1F12
	v_or_b32_e32 v14, v17, v14                                 // 000000002648: 381C1D11
	s_andn2_b32 exec_lo, exec_lo, s9                           // 00000000264C: 8A7E097E
	s_cbranch_execnz 65515                                     // 000000002650: BF89FFEB <__ockl_fprintf_append_string_n+0x280>
	s_or_b32 exec_lo, exec_lo, s9                              // 000000002654: 887E097E
	s_or_b32 exec_lo, exec_lo, s8                              // 000000002658: 887E087E
	s_or_saveexec_b32 s5, s5                                   // 00000000265C: BE853D05
	v_mov_b32_e32 v8, 0                                        // 000000002660: 7E100280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000002664: 897E057E
	s_cbranch_execz 7                                          // 000000002668: BF880007 <__ockl_fprintf_append_string_n+0x308>
	flat_load_dwordx2 v[14:15], v[24:25]                       // 00000000266C: DC340000 0E7D0018
	v_add_co_u32 v24, s4, v24, 8                               // 000000002674: D70F0418 02011118
	v_add_nc_u32_e32 v8, -8, v16                               // 00000000267C: 4A1020C8
	v_add_co_ci_u32_e64 v25, null, 0, v25, s4                  // 000000002680: D5287D19 00123280
	s_or_b32 exec_lo, exec_lo, s5                              // 000000002688: 887E057E
	s_mov_b32 s5, exec_lo                                      // 00000000268C: BE85037E
	v_cmpx_gt_u32_e32 8, v8                                    // 000000002690: 7DA81088
	s_xor_b32 s5, exec_lo, s5                                  // 000000002694: 8905057E
	s_cbranch_execz 32                                         // 000000002698: BF880020 <__ockl_fprintf_append_string_n+0x39c>
	v_mov_b32_e32 v16, 0                                       // 00000000269C: 7E200280
	v_mov_b32_e32 v17, 0                                       // 0000000026A0: 7E220280
	s_mov_b32 s8, exec_lo                                      // 0000000026A4: BE88037E
	v_cmpx_ne_u32_e32 0, v8                                    // 0000000026A8: 7DAA1080
	s_cbranch_execz 26                                         // 0000000026AC: BF88001A <__ockl_fprintf_append_string_n+0x398>
	v_mov_b32_e32 v16, 0                                       // 0000000026B0: 7E200280
	v_mov_b32_e32 v17, 0                                       // 0000000026B4: 7E220280
	s_mov_b32 s9, 0                                            // 0000000026B8: BE890380
	s_mov_b32 s10, 0                                           // 0000000026BC: BE8A0380
	v_add_co_u32 v18, s4, v24, s10                             // 0000000026C0: D70F0412 02001518
	v_add_co_ci_u32_e64 v19, null, 0, v25, s4                  // 0000000026C8: D5287D13 00123280
	s_lshl_b32 s4, s10, 3                                      // 0000000026D0: 8F04830A
	s_add_i32 s10, s10, 1                                      // 0000000026D4: 810A810A
	flat_load_ubyte v18, v[18:19]                              // 0000000026D8: DC200000 127D0012
	v_mov_b32_e32 v19, s13                                     // 0000000026E0: 7E26020D
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000026E4: BF8C0070
	v_and_b32_e32 v18, 0xffff, v18                             // 0000000026E8: 362424FF 0000FFFF
	v_lshlrev_b64 v[18:19], s4, v[18:19]                       // 0000000026F0: D6FF0012 02022404
	v_cmp_eq_u32_e64 s4, s10, v8                               // 0000000026F8: D4C20004 0202100A
	s_or_b32 s9, s4, s9                                        // 000000002700: 88090904
	v_or_b32_e32 v17, v19, v17                                 // 000000002704: 38222313
	v_or_b32_e32 v16, v18, v16                                 // 000000002708: 38202112
	s_andn2_b32 exec_lo, exec_lo, s9                           // 00000000270C: 8A7E097E
	s_cbranch_execnz 65515                                     // 000000002710: BF89FFEB <__ockl_fprintf_append_string_n+0x340>
	s_or_b32 exec_lo, exec_lo, s9                              // 000000002714: 887E097E
	s_or_b32 exec_lo, exec_lo, s8                              // 000000002718: 887E087E
	s_or_saveexec_b32 s5, s5                                   // 00000000271C: BE853D05
	v_mov_b32_e32 v20, 0                                       // 000000002720: 7E280280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000002724: 897E057E
	s_cbranch_execz 7                                          // 000000002728: BF880007 <__ockl_fprintf_append_string_n+0x3c8>
	flat_load_dwordx2 v[16:17], v[24:25]                       // 00000000272C: DC340000 107D0018
	v_add_co_u32 v24, s4, v24, 8                               // 000000002734: D70F0418 02011118
	v_add_nc_u32_e32 v20, -8, v8                               // 00000000273C: 4A2810C8
	v_add_co_ci_u32_e64 v25, null, 0, v25, s4                  // 000000002740: D5287D19 00123280
	s_or_b32 exec_lo, exec_lo, s5                              // 000000002748: 887E057E
	s_mov_b32 s5, exec_lo                                      // 00000000274C: BE85037E
	v_cmpx_gt_u32_e32 8, v20                                   // 000000002750: 7DA82888
	s_xor_b32 s5, exec_lo, s5                                  // 000000002754: 8905057E
	s_cbranch_execz 32                                         // 000000002758: BF880020 <__ockl_fprintf_append_string_n+0x45c>
	v_mov_b32_e32 v18, 0                                       // 00000000275C: 7E240280
	v_mov_b32_e32 v19, 0                                       // 000000002760: 7E260280
	s_mov_b32 s8, exec_lo                                      // 000000002764: BE88037E
	v_cmpx_ne_u32_e32 0, v20                                   // 000000002768: 7DAA2880
	s_cbranch_execz 26                                         // 00000000276C: BF88001A <__ockl_fprintf_append_string_n+0x458>
	v_mov_b32_e32 v18, 0                                       // 000000002770: 7E240280
	v_mov_b32_e32 v19, 0                                       // 000000002774: 7E260280
	s_mov_b32 s9, 0                                            // 000000002778: BE890380
	s_mov_b32 s10, 0                                           // 00000000277C: BE8A0380
	v_add_co_u32 v21, s4, v24, s10                             // 000000002780: D70F0415 02001518
	v_add_co_ci_u32_e64 v22, null, 0, v25, s4                  // 000000002788: D5287D16 00123280
	s_lshl_b32 s4, s10, 3                                      // 000000002790: 8F04830A
	s_add_i32 s10, s10, 1                                      // 000000002794: 810A810A
	flat_load_ubyte v8, v[21:22]                               // 000000002798: DC200000 087D0015
	v_mov_b32_e32 v22, s13                                     // 0000000027A0: 7E2C020D
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000027A4: BF8C0070
	v_and_b32_e32 v21, 0xffff, v8                              // 0000000027A8: 362A10FF 0000FFFF
	v_lshlrev_b64 v[21:22], s4, v[21:22]                       // 0000000027B0: D6FF0015 02022A04
	v_cmp_eq_u32_e64 s4, s10, v20                              // 0000000027B8: D4C20004 0202280A
	s_or_b32 s9, s4, s9                                        // 0000000027C0: 88090904
	v_or_b32_e32 v19, v22, v19                                 // 0000000027C4: 38262716
	v_or_b32_e32 v18, v21, v18                                 // 0000000027C8: 38242515
	s_andn2_b32 exec_lo, exec_lo, s9                           // 0000000027CC: 8A7E097E
	s_cbranch_execnz 65515                                     // 0000000027D0: BF89FFEB <__ockl_fprintf_append_string_n+0x400>
	s_or_b32 exec_lo, exec_lo, s9                              // 0000000027D4: 887E097E
	s_or_b32 exec_lo, exec_lo, s8                              // 0000000027D8: 887E087E
	s_or_saveexec_b32 s5, s5                                   // 0000000027DC: BE853D05
	v_mov_b32_e32 v8, 0                                        // 0000000027E0: 7E100280
	s_xor_b32 exec_lo, exec_lo, s5                             // 0000000027E4: 897E057E
	s_cbranch_execz 7                                          // 0000000027E8: BF880007 <__ockl_fprintf_append_string_n+0x488>
	flat_load_dwordx2 v[18:19], v[24:25]                       // 0000000027EC: DC340000 127D0018
	v_add_co_u32 v24, s4, v24, 8                               // 0000000027F4: D70F0418 02011118
	v_add_nc_u32_e32 v8, -8, v20                               // 0000000027FC: 4A1028C8
	v_add_co_ci_u32_e64 v25, null, 0, v25, s4                  // 000000002800: D5287D19 00123280
	s_or_b32 exec_lo, exec_lo, s5                              // 000000002808: 887E057E
	s_mov_b32 s5, exec_lo                                      // 00000000280C: BE85037E
	v_cmpx_gt_u32_e32 8, v8                                    // 000000002810: 7DA81088
	s_xor_b32 s5, exec_lo, s5                                  // 000000002814: 8905057E
	s_cbranch_execz 32                                         // 000000002818: BF880020 <__ockl_fprintf_append_string_n+0x51c>
	v_mov_b32_e32 v20, 0                                       // 00000000281C: 7E280280
	v_mov_b32_e32 v21, 0                                       // 000000002820: 7E2A0280
	s_mov_b32 s8, exec_lo                                      // 000000002824: BE88037E
	v_cmpx_ne_u32_e32 0, v8                                    // 000000002828: 7DAA1080
	s_cbranch_execz 26                                         // 00000000282C: BF88001A <__ockl_fprintf_append_string_n+0x518>
	v_mov_b32_e32 v20, 0                                       // 000000002830: 7E280280
	v_mov_b32_e32 v21, 0                                       // 000000002834: 7E2A0280
	s_mov_b32 s9, 0                                            // 000000002838: BE890380
	s_mov_b32 s10, 0                                           // 00000000283C: BE8A0380
	v_add_co_u32 v22, s4, v24, s10                             // 000000002840: D70F0416 02001518
	v_add_co_ci_u32_e64 v23, null, 0, v25, s4                  // 000000002848: D5287D17 00123280
	s_lshl_b32 s4, s10, 3                                      // 000000002850: 8F04830A
	s_add_i32 s10, s10, 1                                      // 000000002854: 810A810A
	flat_load_ubyte v22, v[22:23]                              // 000000002858: DC200000 167D0016
	v_mov_b32_e32 v23, s13                                     // 000000002860: 7E2E020D
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000002864: BF8C0070
	v_and_b32_e32 v22, 0xffff, v22                             // 000000002868: 362C2CFF 0000FFFF
	v_lshlrev_b64 v[22:23], s4, v[22:23]                       // 000000002870: D6FF0016 02022C04
	v_cmp_eq_u32_e64 s4, s10, v8                               // 000000002878: D4C20004 0202100A
	s_or_b32 s9, s4, s9                                        // 000000002880: 88090904
	v_or_b32_e32 v21, v23, v21                                 // 000000002884: 382A2B17
	v_or_b32_e32 v20, v22, v20                                 // 000000002888: 38282916
	s_andn2_b32 exec_lo, exec_lo, s9                           // 00000000288C: 8A7E097E
	s_cbranch_execnz 65515                                     // 000000002890: BF89FFEB <__ockl_fprintf_append_string_n+0x4c0>
	s_or_b32 exec_lo, exec_lo, s9                              // 000000002894: 887E097E
	s_or_b32 exec_lo, exec_lo, s8                              // 000000002898: 887E087E
	s_or_saveexec_b32 s5, s5                                   // 00000000289C: BE853D05
	v_mov_b32_e32 v26, 0                                       // 0000000028A0: 7E340280
	s_xor_b32 exec_lo, exec_lo, s5                             // 0000000028A4: 897E057E
	s_cbranch_execz 7                                          // 0000000028A8: BF880007 <__ockl_fprintf_append_string_n+0x548>
	flat_load_dwordx2 v[20:21], v[24:25]                       // 0000000028AC: DC340000 147D0018
	v_add_co_u32 v24, s4, v24, 8                               // 0000000028B4: D70F0418 02011118
	v_add_nc_u32_e32 v26, -8, v8                               // 0000000028BC: 4A3410C8
	v_add_co_ci_u32_e64 v25, null, 0, v25, s4                  // 0000000028C0: D5287D19 00123280
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000028C8: 887E057E
	s_mov_b32 s5, exec_lo                                      // 0000000028CC: BE85037E
	v_cmpx_gt_u32_e32 8, v26                                   // 0000000028D0: 7DA83488
	s_xor_b32 s5, exec_lo, s5                                  // 0000000028D4: 8905057E
	s_cbranch_execz 33                                         // 0000000028D8: BF880021 <__ockl_fprintf_append_string_n+0x5e0>
	v_mov_b32_e32 v22, 0                                       // 0000000028DC: 7E2C0280
	v_mov_b32_e32 v23, 0                                       // 0000000028E0: 7E2E0280
	s_mov_b32 s10, exec_lo                                     // 0000000028E4: BE8A037E
	v_cmpx_ne_u32_e32 0, v26                                   // 0000000028E8: 7DAA3480
	s_cbranch_execz 27                                         // 0000000028EC: BF88001B <__ockl_fprintf_append_string_n+0x5dc>
	v_mov_b32_e32 v22, 0                                       // 0000000028F0: 7E2C0280
	v_mov_b32_e32 v23, 0                                       // 0000000028F4: 7E2E0280
	s_mov_b64 s[8:9], 0                                        // 0000000028F8: BE880480
	s_mov_b32 s11, 0                                           // 0000000028FC: BE8B0380
	flat_load_ubyte v8, v[24:25]                               // 000000002900: DC200000 087D0018
	v_mov_b32_e32 v28, s13                                     // 000000002908: 7E38020D
	v_add_nc_u32_e32 v26, -1, v26                              // 00000000290C: 4A3434C1
	v_add_co_u32 v24, s4, v24, 1                               // 000000002910: D70F0418 02010318
	v_add_co_ci_u32_e64 v25, null, 0, v25, s4                  // 000000002918: D5287D19 00123280
	v_cmp_eq_u32_e64 s4, 0, v26                                // 000000002920: D4C20004 02023480
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000002928: BF8C0070
	v_and_b32_e32 v27, 0xffff, v8                              // 00000000292C: 363610FF 0000FFFF
	v_lshlrev_b64 v[27:28], s8, v[27:28]                       // 000000002934: D6FF001B 02023608
	s_add_u32 s8, s8, 8                                        // 00000000293C: 80088808
	s_addc_u32 s9, s9, 0                                       // 000000002940: 82098009
	s_or_b32 s11, s4, s11                                      // 000000002944: 880B0B04
	v_or_b32_e32 v23, v28, v23                                 // 000000002948: 382E2F1C
	v_or_b32_e32 v22, v27, v22                                 // 00000000294C: 382C2D1B
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000002950: 8A7E0B7E
	s_cbranch_execnz 65514                                     // 000000002954: BF89FFEA <__ockl_fprintf_append_string_n+0x580>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000002958: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 00000000295C: 887E0A7E
	s_andn2_saveexec_b32 s4, s5                                // 000000002960: BE843F05
	s_cbranch_execz 2                                          // 000000002964: BF880002 <__ockl_fprintf_append_string_n+0x5f0>
	flat_load_dwordx2 v[22:23], v[24:25]                       // 000000002968: DC340000 167D0018
	s_or_b32 exec_lo, exec_lo, s4                              // 000000002970: 887E047E
	v_readfirstlane_b32 s4, v30                                // 000000002974: 7E08051E
	v_mov_b32_e32 v28, 0                                       // 000000002978: 7E380280
	v_mov_b32_e32 v29, 0                                       // 00000000297C: 7E3A0280
	v_cmp_eq_u32_e64 s4, s4, v30                               // 000000002980: D4C20004 02023C04
	s_and_saveexec_b32 s8, s4                                  // 000000002988: BE883C04
	s_cbranch_execz 77                                         // 00000000298C: BF88004D <__ockl_fprintf_append_string_n+0x744>
	s_waitcnt lgkmcnt(0)                                       // 000000002990: BF8CC07F
	global_load_dwordx2 v[26:27], v9, s[6:7] offset:24 glc dlc // 000000002994: DC359018 1A060009
	s_waitcnt vmcnt(0)                                         // 00000000299C: BF8C3F70
	buffer_gl1_inv                                             // 0000000029A0: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000029A8: E1C40000 00000000
	s_clause 0x1                                               // 0000000029B0: BFA10001
	global_load_dwordx2 v[24:25], v9, s[6:7] offset:40         // 0000000029B4: DC348028 18060009
	global_load_dwordx2 v[28:29], v9, s[6:7]                   // 0000000029BC: DC348000 1C060009
	s_mov_b32 s9, exec_lo                                      // 0000000029C4: BE89037E
	s_waitcnt vmcnt(1)                                         // 0000000029C8: BF8C3F71
	v_and_b32_e32 v8, v25, v27                                 // 0000000029CC: 36103719
	v_and_b32_e32 v24, v24, v26                                // 0000000029D0: 36303518
	v_mul_lo_u32 v8, v8, 24                                    // 0000000029D4: D5690008 02013108
	v_mul_hi_u32 v25, v24, 24                                  // 0000000029DC: D56A0019 02013118
	v_mul_lo_u32 v24, v24, 24                                  // 0000000029E4: D5690018 02013118
	v_add_nc_u32_e32 v8, v25, v8                               // 0000000029EC: 4A101119
	s_waitcnt vmcnt(0)                                         // 0000000029F0: BF8C3F70
	v_add_co_u32 v24, s5, v28, v24                             // 0000000029F4: D70F0518 0202311C
	v_add_co_ci_u32_e64 v25, null, v29, v8, s5                 // 0000000029FC: D5287D19 0016111D
	global_load_dwordx2 v[24:25], v[24:25], off glc dlc        // 000000002A04: DC359000 187D0018
	s_waitcnt vmcnt(0)                                         // 000000002A0C: BF8C3F70
	global_atomic_cmpswap_x2 v[28:29], v9, v[24:27], s[6:7] offset:24 glc// 000000002A10: DD458018 1C061809
	s_waitcnt vmcnt(0)                                         // 000000002A18: BF8C3F70
	buffer_gl1_inv                                             // 000000002A1C: E1C80000 00000000
	buffer_gl0_inv                                             // 000000002A24: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[28:29], v[26:27]                       // 000000002A2C: 7DEA351C
	s_cbranch_execz 35                                         // 000000002A30: BF880023 <__ockl_fprintf_append_string_n+0x740>
	s_mov_b32 s10, 0                                           // 000000002A34: BE8A0380
	s_nop 0                                                    // 000000002A38: BF800000
	s_nop 0                                                    // 000000002A3C: BF800000
	s_sleep 1                                                  // 000000002A40: BF8E0001
	s_clause 0x1                                               // 000000002A44: BFA10001
	global_load_dwordx2 v[24:25], v9, s[6:7] offset:40         // 000000002A48: DC348028 18060009
	global_load_dwordx2 v[33:34], v9, s[6:7]                   // 000000002A50: DC348000 21060009
	v_mov_b32_e32 v26, v28                                     // 000000002A58: 7E34031C
	v_mov_b32_e32 v27, v29                                     // 000000002A5C: 7E36031D
	s_waitcnt vmcnt(1)                                         // 000000002A60: BF8C3F71
	v_and_b32_e32 v8, v24, v26                                 // 000000002A64: 36103518
	s_waitcnt vmcnt(0)                                         // 000000002A68: BF8C3F70
	v_mad_u64_u32 v[33:34], null, v8, 24, v[33:34]             // 000000002A6C: D5767D21 04853108
	v_and_b32_e32 v8, v25, v27                                 // 000000002A74: 36103719
	v_mad_u64_u32 v[34:35], null, v8, 24, v[34:35]             // 000000002A78: D5767D22 04893108
	global_load_dwordx2 v[24:25], v[33:34], off glc dlc        // 000000002A80: DC359000 187D0021
	s_waitcnt vmcnt(0)                                         // 000000002A88: BF8C3F70
	global_atomic_cmpswap_x2 v[28:29], v9, v[24:27], s[6:7] offset:24 glc// 000000002A8C: DD458018 1C061809
	s_waitcnt vmcnt(0)                                         // 000000002A94: BF8C3F70
	buffer_gl1_inv                                             // 000000002A98: E1C80000 00000000
	buffer_gl0_inv                                             // 000000002AA0: E1C40000 00000000
	v_cmp_eq_u64_e64 s5, v[28:29], v[26:27]                    // 000000002AA8: D4E20005 0202351C
	s_or_b32 s10, s5, s10                                      // 000000002AB0: 880A0A05
	s_andn2_b32 exec_lo, exec_lo, s10                          // 000000002AB4: 8A7E0A7E
	s_cbranch_execnz 65505                                     // 000000002AB8: BF89FFE1 <__ockl_fprintf_append_string_n+0x6c0>
	s_or_b32 exec_lo, exec_lo, s10                             // 000000002ABC: 887E0A7E
	s_or_b32 exec_lo, exec_lo, s9                              // 000000002AC0: 887E097E
	s_or_b32 exec_lo, exec_lo, s8                              // 000000002AC4: 887E087E
	s_waitcnt lgkmcnt(0)                                       // 000000002AC8: BF8CC07F
	s_clause 0x1                                               // 000000002ACC: BFA10001
	global_load_dwordx2 v[33:34], v9, s[6:7] offset:40         // 000000002AD0: DC348028 21060009
	global_load_dwordx4 v[24:27], v9, s[6:7]                   // 000000002AD8: DC388000 18060009
	v_readfirstlane_b32 s9, v29                                // 000000002AE0: 7E12051D
	v_readfirstlane_b32 s8, v28                                // 000000002AE4: 7E10051C
	s_mov_b32 s15, exec_lo                                     // 000000002AE8: BE8F037E
	s_waitcnt vmcnt(1)                                         // 000000002AEC: BF8C3F71
	v_readfirstlane_b32 s10, v33                               // 000000002AF0: 7E140521
	v_readfirstlane_b32 s11, v34                               // 000000002AF4: 7E160522
	s_and_b64 s[10:11], s[10:11], s[8:9]                       // 000000002AF8: 878A080A
	s_mul_i32 s5, s11, 24                                      // 000000002AFC: 9305980B
	s_mul_hi_u32 s16, s10, 24                                  // 000000002B00: 9A90980A
	s_mul_i32 s17, s10, 24                                     // 000000002B04: 9311980A
	s_add_i32 s16, s16, s5                                     // 000000002B08: 81100510
	s_waitcnt vmcnt(0)                                         // 000000002B0C: BF8C3F70
	v_add_co_u32 v28, s5, v24, s17                             // 000000002B10: D70F051C 02002318
	v_add_co_ci_u32_e64 v29, null, s16, v25, s5                // 000000002B18: D5287D1D 00163210
	s_and_saveexec_b32 s5, s4                                  // 000000002B20: BE853C04
	s_cbranch_execz 3                                          // 000000002B24: BF880003 <__ockl_fprintf_append_string_n+0x7b4>
	v_mov_b32_e32 v8, s15                                      // 000000002B28: 7E10020F
	global_store_dwordx4 v[28:29], v[8:11], off offset:8       // 000000002B2C: DC788008 007D081C
	s_or_b32 exec_lo, exec_lo, s5                              // 000000002B34: 887E057E
	v_cmp_lt_u64_e64 s5, 56, v[4:5]                            // 000000002B38: D4E10005 020208B8
	v_and_b32_e32 v0, 0xffffff1f, v0                           // 000000002B40: 360000FF FFFFFF1F
	s_lshl_b64 s[10:11], s[10:11], 12                          // 000000002B48: 8F8A8C0A
	v_lshl_add_u32 v34, v32, 2, 28                             // 000000002B4C: D7460022 02710520
	v_cndmask_b32_e32 v33, 0, v5, vcc_lo                       // 000000002B54: 02420A80
	v_cndmask_b32_e64 v8, 2, 0, s5                             // 000000002B58: D5010008 00150082
	v_or_b32_e32 v0, v0, v8                                    // 000000002B60: 38001100
	v_add_co_u32 v8, s5, v26, s10                              // 000000002B64: D70F0508 0200151A
	v_add_co_ci_u32_e64 v27, null, s11, v27, s5                // 000000002B6C: D5287D1B 0016360B
	v_and_or_b32 v0, 0x1e0, v34, v0                            // 000000002B74: D7710000 040244FF 000001E0
	v_add_co_u32 v26, vcc_lo, v8, v31                          // 000000002B80: D70F6A1A 02023F08
	v_readfirstlane_b32 s10, v8                                // 000000002B88: 7E140508
	v_readfirstlane_b32 s11, v27                               // 000000002B8C: 7E16051B
	v_add_co_ci_u32_e64 v27, null, 0, v27, vcc_lo              // 000000002B90: D5287D1B 01AA3680
	global_store_dwordx4 v31, v[0:3], s[10:11]                 // 000000002B98: DC788000 000A001F
	global_store_dwordx4 v31, v[12:15], s[10:11] offset:16     // 000000002BA0: DC788010 000A0C1F
	global_store_dwordx4 v31, v[16:19], s[10:11] offset:32     // 000000002BA8: DC788020 000A101F
	global_store_dwordx4 v31, v[20:23], s[10:11] offset:48     // 000000002BB0: DC788030 000A141F
	s_and_saveexec_b32 s5, s4                                  // 000000002BB8: BE853C04
	s_cbranch_execz 75                                         // 000000002BBC: BF88004B <__ockl_fprintf_append_string_n+0x96c>
	s_clause 0x1                                               // 000000002BC0: BFA10001
	global_load_dwordx2 v[16:17], v9, s[6:7] offset:32 glc dlc // 000000002BC4: DC359020 10060009
	global_load_dwordx2 v[0:1], v9, s[6:7] offset:40           // 000000002BCC: DC348028 00060009
	v_mov_b32_e32 v14, s8                                      // 000000002BD4: 7E1C0208
	v_mov_b32_e32 v15, s9                                      // 000000002BD8: 7E1E0209
	s_waitcnt vmcnt(0)                                         // 000000002BDC: BF8C3F70
	v_readfirstlane_b32 s10, v0                                // 000000002BE0: 7E140500
	v_readfirstlane_b32 s11, v1                                // 000000002BE4: 7E160501
	s_and_b64 s[10:11], s[10:11], s[8:9]                       // 000000002BE8: 878A080A
	s_mul_i32 s11, s11, 24                                     // 000000002BEC: 930B980B
	s_mul_hi_u32 s15, s10, 24                                  // 000000002BF0: 9A8F980A
	s_mul_i32 s10, s10, 24                                     // 000000002BF4: 930A980A
	s_add_i32 s15, s15, s11                                    // 000000002BF8: 810F0B0F
	v_add_co_u32 v12, vcc_lo, v24, s10                         // 000000002BFC: D70F6A0C 02001518
	v_add_co_ci_u32_e64 v13, null, s15, v25, vcc_lo            // 000000002C04: D5287D0D 01AA320F
	s_mov_b32 s10, exec_lo                                     // 000000002C0C: BE8A037E
	global_store_dwordx2 v[12:13], v[16:17], off               // 000000002C10: DC748000 007D100C
	s_waitcnt_vscnt null, 0x0                                  // 000000002C18: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v9, v[14:17], s[6:7] offset:32 glc// 000000002C1C: DD458020 02060E09
	s_waitcnt vmcnt(0)                                         // 000000002C24: BF8C3F70
	v_cmpx_ne_u64_e32 v[2:3], v[16:17]                         // 000000002C28: 7DEA2102
	s_cbranch_execz 16                                         // 000000002C2C: BF880010 <__ockl_fprintf_append_string_n+0x8f0>
	s_mov_b32 s11, 0                                           // 000000002C30: BE8B0380
	v_mov_b32_e32 v0, s8                                       // 000000002C34: 7E000208
	v_mov_b32_e32 v1, s9                                       // 000000002C38: 7E020209
	s_sleep 1                                                  // 000000002C3C: BF8E0001
	global_store_dwordx2 v[12:13], v[2:3], off                 // 000000002C40: DC748000 007D020C
	s_waitcnt_vscnt null, 0x0                                  // 000000002C48: BBFD0000
	global_atomic_cmpswap_x2 v[0:1], v9, v[0:3], s[6:7] offset:32 glc// 000000002C4C: DD458020 00060009
	s_waitcnt vmcnt(0)                                         // 000000002C54: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]                    // 000000002C58: 7DC40500
	v_mov_b32_e32 v3, v1                                       // 000000002C5C: 7E060301
	v_mov_b32_e32 v2, v0                                       // 000000002C60: 7E040300
	s_or_b32 s11, vcc_lo, s11                                  // 000000002C64: 880B0B6A
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000002C68: 8A7E0B7E
	s_cbranch_execnz 65521                                     // 000000002C6C: BF89FFF1 <__ockl_fprintf_append_string_n+0x8b4>
	s_or_b32 exec_lo, exec_lo, s10                             // 000000002C70: 887E0A7E
	global_load_dwordx2 v[0:1], v9, s[6:7] offset:16           // 000000002C74: DC348010 00060009
	s_mov_b32 s11, exec_lo                                     // 000000002C7C: BE8B037E
	s_mov_b32 s10, exec_lo                                     // 000000002C80: BE8A037E
	v_mbcnt_lo_u32_b32 v2, s11, 0                              // 000000002C84: D7650002 0201000B
	v_cmpx_eq_u32_e32 0, v2                                    // 000000002C8C: 7DA40480
	s_cbranch_execz 5                                          // 000000002C90: BF880005 <__ockl_fprintf_append_string_n+0x928>
	s_bcnt1_i32_b32 s11, s11                                   // 000000002C94: BE8B0F0B
	v_mov_b32_e32 v8, s11                                      // 000000002C98: 7E10020B
	s_waitcnt vmcnt(0)                                         // 000000002C9C: BF8C3F70
	global_atomic_add_x2 v[0:1], v[8:9], off offset:8          // 000000002CA0: DD488008 007D0800
	s_or_b32 exec_lo, exec_lo, s10                             // 000000002CA8: 887E0A7E
	s_waitcnt vmcnt(0)                                         // 000000002CAC: BF8C3F70
	global_load_dwordx2 v[2:3], v[0:1], off offset:16          // 000000002CB0: DC348010 027D0000
	s_waitcnt vmcnt(0)                                         // 000000002CB8: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[2:3]                         // 000000002CBC: 7DC40480
	s_cbranch_vccnz 10                                         // 000000002CC0: BF87000A <__ockl_fprintf_append_string_n+0x96c>
	global_load_dword v8, v[0:1], off offset:24                // 000000002CC4: DC308018 087D0000
	s_waitcnt vmcnt(0)                                         // 000000002CCC: BF8C3F70
	v_readfirstlane_b32 s10, v8                                // 000000002CD0: 7E140508
	s_waitcnt_vscnt null, 0x0                                  // 000000002CD4: BBFD0000
	global_store_dwordx2 v[2:3], v[8:9], off                   // 000000002CD8: DC748000 007D0802
	s_and_b32 m0, s10, 0x7fffff                                // 000000002CE0: 877CFF0A 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 000000002CE8: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 000000002CEC: 887E057E
	s_branch 13                                                // 000000002CF0: BF82000D <__ockl_fprintf_append_string_n+0x9a8>
	s_nop 0                                                    // 000000002CF4: BF800000
	s_nop 0                                                    // 000000002CF8: BF800000
	s_nop 0                                                    // 000000002CFC: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000002D00: 887E057E
	v_readfirstlane_b32 s5, v0                                 // 000000002D04: 7E0A0500
	s_cmp_eq_u32 s5, 0                                         // 000000002D08: BF068005
	s_cbranch_scc1 28                                          // 000000002D0C: BF85001C <__ockl_fprintf_append_string_n+0xa00>
	s_mov_b32 s5, 0                                            // 000000002D10: BE850380
	s_sleep 1                                                  // 000000002D14: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000002D18: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 000000002D1C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 000000002D20: BF078105
	s_cbranch_scc0 24                                          // 000000002D24: BF840018 <__ockl_fprintf_append_string_n+0xa08>
	v_mov_b32_e32 v0, 1                                        // 000000002D28: 7E000281
	s_and_saveexec_b32 s5, s4                                  // 000000002D2C: BE853C04
	s_cbranch_execz 65523                                      // 000000002D30: BF88FFF3 <__ockl_fprintf_append_string_n+0x980>
	global_load_dword v0, v[28:29], off offset:20 glc dlc      // 000000002D34: DC319014 007D001C
	s_waitcnt vmcnt(0)                                         // 000000002D3C: BF8C3F70
	buffer_gl1_inv                                             // 000000002D40: E1C80000 00000000
	buffer_gl0_inv                                             // 000000002D48: E1C40000 00000000
	v_and_b32_e32 v0, 1, v0                                    // 000000002D50: 36000081
	s_branch 65514                                             // 000000002D54: BF82FFEA <__ockl_fprintf_append_string_n+0x980>
	s_nop 0                                                    // 000000002D58: BF800000
	s_nop 0                                                    // 000000002D5C: BF800000
	s_nop 0                                                    // 000000002D60: BF800000
	s_nop 0                                                    // 000000002D64: BF800000
	s_nop 0                                                    // 000000002D68: BF800000
	s_nop 0                                                    // 000000002D6C: BF800000
	s_nop 0                                                    // 000000002D70: BF800000
	s_nop 0                                                    // 000000002D74: BF800000
	s_nop 0                                                    // 000000002D78: BF800000
	s_nop 0                                                    // 000000002D7C: BF800000
	s_mov_b32 s5, -1                                           // 000000002D80: BE8503C1
	s_branch 65508                                             // 000000002D84: BF82FFE4 <__ockl_fprintf_append_string_n+0x998>
	global_load_dwordx4 v[0:3], v[26:27], off                  // 000000002D88: DC388000 007D001A
	s_and_saveexec_b32 s10, s4                                 // 000000002D90: BE8A3C04
	s_cbranch_execz 64909                                      // 000000002D94: BF88FD8D <__ockl_fprintf_append_string_n+0x4c>
	s_clause 0x2                                               // 000000002D98: BFA10002
	global_load_dwordx2 v[2:3], v9, s[6:7] offset:40           // 000000002D9C: DC348028 02060009
	global_load_dwordx2 v[16:17], v9, s[6:7] offset:24 glc dlc // 000000002DA4: DC359018 10060009
	global_load_dwordx2 v[12:13], v9, s[6:7]                   // 000000002DAC: DC348000 0C060009
	s_waitcnt vmcnt(2)                                         // 000000002DB4: BF8C3F72
	v_readfirstlane_b32 s16, v2                                // 000000002DB8: 7E200502
	v_readfirstlane_b32 s17, v3                                // 000000002DBC: 7E220503
	s_add_u32 s11, s16, 1                                      // 000000002DC0: 800B8110
	s_addc_u32 s15, s17, 0                                     // 000000002DC4: 820F8011
	s_add_u32 s4, s11, s8                                      // 000000002DC8: 8004080B
	s_addc_u32 s5, s15, s9                                     // 000000002DCC: 8205090F
	s_cmp_eq_u64 s[4:5], 0                                     // 000000002DD0: BF128004
	s_cselect_b32 s5, s15, s5                                  // 000000002DD4: 8505050F
	s_cselect_b32 s4, s11, s4                                  // 000000002DD8: 8504040B
	v_mov_b32_e32 v15, s5                                      // 000000002DDC: 7E1E0205
	s_and_b64 s[8:9], s[4:5], s[16:17]                         // 000000002DE0: 87881004
	v_mov_b32_e32 v14, s4                                      // 000000002DE4: 7E1C0204
	s_mul_i32 s9, s9, 24                                       // 000000002DE8: 93099809
	s_mul_hi_u32 s11, s8, 24                                   // 000000002DEC: 9A8B9808
	s_mul_i32 s8, s8, 24                                       // 000000002DF0: 93089808
	s_add_i32 s11, s11, s9                                     // 000000002DF4: 810B090B
	s_waitcnt vmcnt(0)                                         // 000000002DF8: BF8C3F70
	v_add_co_u32 v2, vcc_lo, v12, s8                           // 000000002DFC: D70F6A02 0200110C
	v_add_co_ci_u32_e64 v3, null, s11, v13, vcc_lo             // 000000002E04: D5287D03 01AA1A0B
	global_store_dwordx2 v[2:3], v[16:17], off                 // 000000002E0C: DC748000 007D1002
	s_waitcnt_vscnt null, 0x0                                  // 000000002E14: BBFD0000
	global_atomic_cmpswap_x2 v[14:15], v9, v[14:17], s[6:7] offset:24 glc// 000000002E18: DD458018 0E060E09
	s_waitcnt vmcnt(0)                                         // 000000002E20: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[14:15], v[16:17]                // 000000002E24: 7DCA210E
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000002E28: 877E6A7E
	s_cbranch_execz 64871                                      // 000000002E2C: BF88FD67 <__ockl_fprintf_append_string_n+0x4c>
	s_mov_b32 s8, 0                                            // 000000002E30: BE880380
	v_mov_b32_e32 v12, s4                                      // 000000002E34: 7E180204
	v_mov_b32_e32 v13, s5                                      // 000000002E38: 7E1A0205
	s_sleep 1                                                  // 000000002E3C: BF8E0001
	global_store_dwordx2 v[2:3], v[14:15], off                 // 000000002E40: DC748000 007D0E02
	s_waitcnt_vscnt null, 0x0                                  // 000000002E48: BBFD0000
	global_atomic_cmpswap_x2 v[12:13], v9, v[12:15], s[6:7] offset:24 glc// 000000002E4C: DD458018 0C060C09
	s_waitcnt vmcnt(0)                                         // 000000002E54: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[12:13], v[14:15]                // 000000002E58: 7DC41D0C
	v_mov_b32_e32 v15, v13                                     // 000000002E5C: 7E1E030D
	v_mov_b32_e32 v14, v12                                     // 000000002E60: 7E1C030C
	s_or_b32 s8, vcc_lo, s8                                    // 000000002E64: 8808086A
	s_andn2_b32 exec_lo, exec_lo, s8                           // 000000002E68: 8A7E087E
	s_cbranch_execnz 65521                                     // 000000002E6C: BF89FFF1 <__ockl_fprintf_append_string_n+0xab4>
	s_branch 64854                                             // 000000002E70: BF82FD56 <__ockl_fprintf_append_string_n+0x4c>
	s_or_b32 exec_lo, exec_lo, s14                             // 000000002E74: 887E0E7E
	s_andn2_saveexec_b32 s12, s12                              // 000000002E78: BE8C3F0C
	s_cbranch_execz 290                                        // 000000002E7C: BF880122 <__ockl_fprintf_append_string_n+0xf88>
	v_readfirstlane_b32 s4, v30                                // 000000002E80: 7E08051E
	s_waitcnt vmcnt(0)                                         // 000000002E84: BF8C3F70
	v_mov_b32_e32 v2, 0                                        // 000000002E88: 7E040280
	v_mov_b32_e32 v3, 0                                        // 000000002E8C: 7E060280
	v_cmp_eq_u32_e64 s4, s4, v30                               // 000000002E90: D4C20004 02023C04
	s_and_saveexec_b32 s5, s4                                  // 000000002E98: BE853C04
	s_cbranch_execz 88                                         // 000000002E9C: BF880058 <__ockl_fprintf_append_string_n+0xc80>
	v_mov_b32_e32 v4, 0                                        // 000000002EA0: 7E080280
	s_mov_b32 s8, exec_lo                                      // 000000002EA4: BE88037E
	s_waitcnt lgkmcnt(0)                                       // 000000002EA8: BF8CC07F
	global_load_dwordx2 v[7:8], v4, s[6:7] offset:24 glc dlc   // 000000002EAC: DC359018 07060004
	s_waitcnt vmcnt(0)                                         // 000000002EB4: BF8C3F70
	buffer_gl1_inv                                             // 000000002EB8: E1C80000 00000000
	buffer_gl0_inv                                             // 000000002EC0: E1C40000 00000000
	s_clause 0x1                                               // 000000002EC8: BFA10001
	global_load_dwordx2 v[2:3], v4, s[6:7] offset:40           // 000000002ECC: DC348028 02060004
	global_load_dwordx2 v[5:6], v4, s[6:7]                     // 000000002ED4: DC348000 05060004
	s_waitcnt vmcnt(1)                                         // 000000002EDC: BF8C3F71
	v_and_b32_e32 v3, v3, v8                                   // 000000002EE0: 36061103
	v_and_b32_e32 v2, v2, v7                                   // 000000002EE4: 36040F02
	v_mul_lo_u32 v3, v3, 24                                    // 000000002EE8: D5690003 02013103
	v_mul_hi_u32 v9, v2, 24                                    // 000000002EF0: D56A0009 02013102
	v_mul_lo_u32 v2, v2, 24                                    // 000000002EF8: D5690002 02013102
	v_add_nc_u32_e32 v3, v9, v3                                // 000000002F00: 4A060709
	s_waitcnt vmcnt(0)                                         // 000000002F04: BF8C3F70
	v_add_co_u32 v2, vcc_lo, v5, v2                            // 000000002F08: D70F6A02 02020505
	v_add_co_ci_u32_e64 v3, null, v6, v3, vcc_lo               // 000000002F10: D5287D03 01AA0706
	global_load_dwordx2 v[5:6], v[2:3], off glc dlc            // 000000002F18: DC359000 057D0002
	s_waitcnt vmcnt(0)                                         // 000000002F20: BF8C3F70
	global_atomic_cmpswap_x2 v[2:3], v4, v[5:8], s[6:7] offset:24 glc// 000000002F24: DD458018 02060504
	s_waitcnt vmcnt(0)                                         // 000000002F2C: BF8C3F70
	buffer_gl1_inv                                             // 000000002F30: E1C80000 00000000
	buffer_gl0_inv                                             // 000000002F38: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[2:3], v[7:8]                           // 000000002F40: 7DEA0F02
	s_cbranch_execz 45                                         // 000000002F44: BF88002D <__ockl_fprintf_append_string_n+0xc7c>
	s_mov_b32 s9, 0                                            // 000000002F48: BE890380
	s_nop 0                                                    // 000000002F4C: BF800000
	s_nop 0                                                    // 000000002F50: BF800000
	s_nop 0                                                    // 000000002F54: BF800000
	s_nop 0                                                    // 000000002F58: BF800000
	s_nop 0                                                    // 000000002F5C: BF800000
	s_nop 0                                                    // 000000002F60: BF800000
	s_nop 0                                                    // 000000002F64: BF800000
	s_nop 0                                                    // 000000002F68: BF800000
	s_nop 0                                                    // 000000002F6C: BF800000
	s_nop 0                                                    // 000000002F70: BF800000
	s_nop 0                                                    // 000000002F74: BF800000
	s_nop 0                                                    // 000000002F78: BF800000
	s_nop 0                                                    // 000000002F7C: BF800000
	s_sleep 1                                                  // 000000002F80: BF8E0001
	s_clause 0x1                                               // 000000002F84: BFA10001
	global_load_dwordx2 v[5:6], v4, s[6:7] offset:40           // 000000002F88: DC348028 05060004
	global_load_dwordx2 v[9:10], v4, s[6:7]                    // 000000002F90: DC348000 09060004
	v_mov_b32_e32 v7, v2                                       // 000000002F98: 7E0E0302
	v_mov_b32_e32 v8, v3                                       // 000000002F9C: 7E100303
	s_waitcnt vmcnt(1)                                         // 000000002FA0: BF8C3F71
	v_and_b32_e32 v2, v5, v7                                   // 000000002FA4: 36040F05
	s_waitcnt vmcnt(0)                                         // 000000002FA8: BF8C3F70
	v_mad_u64_u32 v[9:10], null, v2, 24, v[9:10]               // 000000002FAC: D5767D09 04253102
	v_and_b32_e32 v2, v6, v8                                   // 000000002FB4: 36041106
	v_mad_u64_u32 v[10:11], null, v2, 24, v[10:11]             // 000000002FB8: D5767D0A 04293102
	global_load_dwordx2 v[5:6], v[9:10], off glc dlc           // 000000002FC0: DC359000 057D0009
	s_waitcnt vmcnt(0)                                         // 000000002FC8: BF8C3F70
	global_atomic_cmpswap_x2 v[2:3], v4, v[5:8], s[6:7] offset:24 glc// 000000002FCC: DD458018 02060504
	s_waitcnt vmcnt(0)                                         // 000000002FD4: BF8C3F70
	buffer_gl1_inv                                             // 000000002FD8: E1C80000 00000000
	buffer_gl0_inv                                             // 000000002FE0: E1C40000 00000000
	v_cmp_eq_u64_e32 vcc_lo, v[2:3], v[7:8]                    // 000000002FE8: 7DC40F02
	s_or_b32 s9, vcc_lo, s9                                    // 000000002FEC: 8809096A
	s_andn2_b32 exec_lo, exec_lo, s9                           // 000000002FF0: 8A7E097E
	s_cbranch_execnz 65506                                     // 000000002FF4: BF89FFE2 <__ockl_fprintf_append_string_n+0xc00>
	s_or_b32 exec_lo, exec_lo, s9                              // 000000002FF8: 887E097E
	s_or_b32 exec_lo, exec_lo, s8                              // 000000002FFC: 887E087E
	s_or_b32 exec_lo, exec_lo, s5                              // 000000003000: 887E057E
	v_mov_b32_e32 v9, 0                                        // 000000003004: 7E120280
	v_readfirstlane_b32 s9, v3                                 // 000000003008: 7E120503
	v_readfirstlane_b32 s8, v2                                 // 00000000300C: 7E100502
	s_mov_b32 s5, exec_lo                                      // 000000003010: BE85037E
	s_waitcnt lgkmcnt(0)                                       // 000000003014: BF8CC07F
	s_clause 0x1                                               // 000000003018: BFA10001
	global_load_dwordx2 v[10:11], v9, s[6:7] offset:40         // 00000000301C: DC348028 0A060009
	global_load_dwordx4 v[4:7], v9, s[6:7]                     // 000000003024: DC388000 04060009
	s_waitcnt vmcnt(1)                                         // 00000000302C: BF8C3F71
	v_readfirstlane_b32 s10, v10                               // 000000003030: 7E14050A
	v_readfirstlane_b32 s11, v11                               // 000000003034: 7E16050B
	s_and_b64 s[10:11], s[10:11], s[8:9]                       // 000000003038: 878A080A
	s_mul_i32 s13, s11, 24                                     // 00000000303C: 930D980B
	s_mul_hi_u32 s14, s10, 24                                  // 000000003040: 9A8E980A
	s_mul_i32 s15, s10, 24                                     // 000000003044: 930F980A
	s_add_i32 s14, s14, s13                                    // 000000003048: 810E0D0E
	s_waitcnt vmcnt(0)                                         // 00000000304C: BF8C3F70
	v_add_co_u32 v12, vcc_lo, v4, s15                          // 000000003050: D70F6A0C 02001F04
	v_add_co_ci_u32_e64 v13, null, s14, v5, vcc_lo             // 000000003058: D5287D0D 01AA0A0E
	s_and_saveexec_b32 s13, s4                                 // 000000003060: BE8D3C04
	s_cbranch_execz 5                                          // 000000003064: BF880005 <__ockl_fprintf_append_string_n+0xcfc>
	v_mov_b32_e32 v8, s5                                       // 000000003068: 7E100205
	v_mov_b32_e32 v10, 2                                       // 00000000306C: 7E140282
	v_mov_b32_e32 v11, 1                                       // 000000003070: 7E160281
	global_store_dwordx4 v[12:13], v[8:11], off offset:8       // 000000003074: DC788008 007D080C
	s_or_b32 exec_lo, exec_lo, s13                             // 00000000307C: 887E0D7E
	s_lshl_b64 s[10:11], s[10:11], 12                          // 000000003080: 8F8A8C0A
	s_mov_b32 s16, 0                                           // 000000003084: BE900380
	v_add_co_u32 v6, vcc_lo, v6, s10                           // 000000003088: D70F6A06 02001506
	v_add_co_ci_u32_e64 v7, null, s11, v7, vcc_lo              // 000000003090: D5287D07 01AA0E0B
	s_mov_b32 s17, s16                                         // 000000003098: BE910310
	s_mov_b32 s18, s16                                         // 00000000309C: BE920310
	s_mov_b32 s19, s16                                         // 0000000030A0: BE930310
	v_and_or_b32 v0, 0xffffff1d, v0, 34                        // 0000000030A4: D7710000 028A00FF FFFFFF1D
	v_lshlrev_b32_e32 v10, 6, v30                              // 0000000030B0: 34143C86
	v_mov_b32_e32 v2, s16                                      // 0000000030B4: 7E040210
	v_mov_b32_e32 v3, s16                                      // 0000000030B8: 7E060210
	v_readfirstlane_b32 s10, v6                                // 0000000030BC: 7E140506
	v_readfirstlane_b32 s11, v7                                // 0000000030C0: 7E160507
	v_mov_b32_e32 v6, s16                                      // 0000000030C4: 7E0C0210
	v_mov_b32_e32 v7, s17                                      // 0000000030C8: 7E0E0211
	v_mov_b32_e32 v8, s18                                      // 0000000030CC: 7E100212
	v_mov_b32_e32 v9, s19                                      // 0000000030D0: 7E120213
	global_store_dwordx4 v10, v[0:3], s[10:11]                 // 0000000030D4: DC788000 000A000A
	global_store_dwordx4 v10, v[6:9], s[10:11] offset:16       // 0000000030DC: DC788010 000A060A
	global_store_dwordx4 v10, v[6:9], s[10:11] offset:32       // 0000000030E4: DC788020 000A060A
	global_store_dwordx4 v10, v[6:9], s[10:11] offset:48       // 0000000030EC: DC788030 000A060A
	s_and_saveexec_b32 s5, s4                                  // 0000000030F4: BE853C04
	s_cbranch_execz 80                                         // 0000000030F8: BF880050 <__ockl_fprintf_append_string_n+0xebc>
	v_mov_b32_e32 v6, 0                                        // 0000000030FC: 7E0C0280
	v_mov_b32_e32 v7, s8                                       // 000000003100: 7E0E0208
	v_mov_b32_e32 v8, s9                                       // 000000003104: 7E100209
	s_mov_b32 s10, exec_lo                                     // 000000003108: BE8A037E
	s_clause 0x1                                               // 00000000310C: BFA10001
	global_load_dwordx2 v[9:10], v6, s[6:7] offset:32 glc dlc  // 000000003110: DC359020 09060006
	global_load_dwordx2 v[0:1], v6, s[6:7] offset:40           // 000000003118: DC348028 00060006
	s_waitcnt vmcnt(0)                                         // 000000003120: BF8C3F70
	v_and_b32_e32 v1, s9, v1                                   // 000000003124: 36020209
	v_and_b32_e32 v0, s8, v0                                   // 000000003128: 36000008
	v_mul_lo_u32 v1, v1, 24                                    // 00000000312C: D5690001 02013101
	v_mul_hi_u32 v2, v0, 24                                    // 000000003134: D56A0002 02013100
	v_mul_lo_u32 v0, v0, 24                                    // 00000000313C: D5690000 02013100
	v_add_nc_u32_e32 v1, v2, v1                                // 000000003144: 4A020302
	v_add_co_u32 v4, vcc_lo, v4, v0                            // 000000003148: D70F6A04 02020104
	v_add_co_ci_u32_e64 v5, null, v5, v1, vcc_lo               // 000000003150: D5287D05 01AA0305
	global_store_dwordx2 v[4:5], v[9:10], off                  // 000000003158: DC748000 007D0904
	s_waitcnt_vscnt null, 0x0                                  // 000000003160: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v6, v[7:10], s[6:7] offset:32 glc// 000000003164: DD458020 02060706
	s_waitcnt vmcnt(0)                                         // 00000000316C: BF8C3F70
	v_cmpx_ne_u64_e32 v[2:3], v[9:10]                          // 000000003170: 7DEA1302
	s_cbranch_execz 16                                         // 000000003174: BF880010 <__ockl_fprintf_append_string_n+0xe38>
	s_mov_b32 s11, 0                                           // 000000003178: BE8B0380
	v_mov_b32_e32 v0, s8                                       // 00000000317C: 7E000208
	v_mov_b32_e32 v1, s9                                       // 000000003180: 7E020209
	s_sleep 1                                                  // 000000003184: BF8E0001
	global_store_dwordx2 v[4:5], v[2:3], off                   // 000000003188: DC748000 007D0204
	s_waitcnt_vscnt null, 0x0                                  // 000000003190: BBFD0000
	global_atomic_cmpswap_x2 v[0:1], v6, v[0:3], s[6:7] offset:32 glc// 000000003194: DD458020 00060006
	s_waitcnt vmcnt(0)                                         // 00000000319C: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]                    // 0000000031A0: 7DC40500
	v_mov_b32_e32 v3, v1                                       // 0000000031A4: 7E060301
	v_mov_b32_e32 v2, v0                                       // 0000000031A8: 7E040300
	s_or_b32 s11, vcc_lo, s11                                  // 0000000031AC: 880B0B6A
	s_andn2_b32 exec_lo, exec_lo, s11                          // 0000000031B0: 8A7E0B7E
	s_cbranch_execnz 65521                                     // 0000000031B4: BF89FFF1 <__ockl_fprintf_append_string_n+0xdfc>
	s_or_b32 exec_lo, exec_lo, s10                             // 0000000031B8: 887E0A7E
	v_mov_b32_e32 v3, 0                                        // 0000000031BC: 7E060280
	s_mov_b32 s11, exec_lo                                     // 0000000031C0: BE8B037E
	s_mov_b32 s10, exec_lo                                     // 0000000031C4: BE8A037E
	v_mbcnt_lo_u32_b32 v2, s11, 0                              // 0000000031C8: D7650002 0201000B
	global_load_dwordx2 v[0:1], v3, s[6:7] offset:16           // 0000000031D0: DC348010 00060003
	v_cmpx_eq_u32_e32 0, v2                                    // 0000000031D8: 7DA40480
	s_cbranch_execz 5                                          // 0000000031DC: BF880005 <__ockl_fprintf_append_string_n+0xe74>
	s_bcnt1_i32_b32 s11, s11                                   // 0000000031E0: BE8B0F0B
	v_mov_b32_e32 v2, s11                                      // 0000000031E4: 7E04020B
	s_waitcnt vmcnt(0)                                         // 0000000031E8: BF8C3F70
	global_atomic_add_x2 v[0:1], v[2:3], off offset:8          // 0000000031EC: DD488008 007D0200
	s_or_b32 exec_lo, exec_lo, s10                             // 0000000031F4: 887E0A7E
	s_waitcnt vmcnt(0)                                         // 0000000031F8: BF8C3F70
	global_load_dwordx2 v[2:3], v[0:1], off offset:16          // 0000000031FC: DC348010 027D0000
	s_waitcnt vmcnt(0)                                         // 000000003204: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[2:3]                         // 000000003208: 7DC40480
	s_cbranch_vccnz 11                                         // 00000000320C: BF87000B <__ockl_fprintf_append_string_n+0xebc>
	global_load_dword v0, v[0:1], off offset:24                // 000000003210: DC308018 007D0000
	v_mov_b32_e32 v1, 0                                        // 000000003218: 7E020280
	s_waitcnt vmcnt(0)                                         // 00000000321C: BF8C3F70
	v_readfirstlane_b32 s10, v0                                // 000000003220: 7E140500
	s_waitcnt_vscnt null, 0x0                                  // 000000003224: BBFD0000
	global_store_dwordx2 v[2:3], v[0:1], off                   // 000000003228: DC748000 007D0002
	s_and_b32 m0, s10, 0x7fffff                                // 000000003230: 877CFF0A 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 000000003238: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 00000000323C: 887E057E
	s_branch 25                                                // 000000003240: BF820019 <__ockl_fprintf_append_string_n+0xf28>
	s_nop 0                                                    // 000000003244: BF800000
	s_nop 0                                                    // 000000003248: BF800000
	s_nop 0                                                    // 00000000324C: BF800000
	s_nop 0                                                    // 000000003250: BF800000
	s_nop 0                                                    // 000000003254: BF800000
	s_nop 0                                                    // 000000003258: BF800000
	s_nop 0                                                    // 00000000325C: BF800000
	s_nop 0                                                    // 000000003260: BF800000
	s_nop 0                                                    // 000000003264: BF800000
	s_nop 0                                                    // 000000003268: BF800000
	s_nop 0                                                    // 00000000326C: BF800000
	s_nop 0                                                    // 000000003270: BF800000
	s_nop 0                                                    // 000000003274: BF800000
	s_nop 0                                                    // 000000003278: BF800000
	s_nop 0                                                    // 00000000327C: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000003280: 887E057E
	v_readfirstlane_b32 s5, v0                                 // 000000003284: 7E0A0500
	s_cmp_eq_u32 s5, 0                                         // 000000003288: BF068005
	s_cbranch_scc1 28                                          // 00000000328C: BF85001C <__ockl_fprintf_append_string_n+0xf80>
	s_mov_b32 s5, 0                                            // 000000003290: BE850380
	s_sleep 1                                                  // 000000003294: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000003298: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 00000000329C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 0000000032A0: BF078105
	s_cbranch_scc0 27                                          // 0000000032A4: BF84001B <__ockl_fprintf_append_string_n+0xf94>
	v_mov_b32_e32 v0, 1                                        // 0000000032A8: 7E000281
	s_and_saveexec_b32 s5, s4                                  // 0000000032AC: BE853C04
	s_cbranch_execz 65523                                      // 0000000032B0: BF88FFF3 <__ockl_fprintf_append_string_n+0xf00>
	global_load_dword v0, v[12:13], off offset:20 glc dlc      // 0000000032B4: DC319014 007D000C
	s_waitcnt vmcnt(0)                                         // 0000000032BC: BF8C3F70
	buffer_gl1_inv                                             // 0000000032C0: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000032C8: E1C40000 00000000
	v_and_b32_e32 v0, 1, v0                                    // 0000000032D0: 36000081
	s_branch 65514                                             // 0000000032D4: BF82FFEA <__ockl_fprintf_append_string_n+0xf00>
	s_nop 0                                                    // 0000000032D8: BF800000
	s_nop 0                                                    // 0000000032DC: BF800000
	s_nop 0                                                    // 0000000032E0: BF800000
	s_nop 0                                                    // 0000000032E4: BF800000
	s_nop 0                                                    // 0000000032E8: BF800000
	s_nop 0                                                    // 0000000032EC: BF800000
	s_nop 0                                                    // 0000000032F0: BF800000
	s_nop 0                                                    // 0000000032F4: BF800000
	s_nop 0                                                    // 0000000032F8: BF800000
	s_nop 0                                                    // 0000000032FC: BF800000
	s_mov_b32 s5, -1                                           // 000000003300: BE8503C1
	s_branch 65508                                             // 000000003304: BF82FFE4 <__ockl_fprintf_append_string_n+0xf18>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000003308: 887E0C7E
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 00000000330C: BF8C0070
	s_setpc_b64 s[30:31]                                       // 000000003310: BE80201E
	s_and_saveexec_b32 s10, s4                                 // 000000003314: BE8A3C04
	s_cbranch_execz 55                                         // 000000003318: BF880037 <__ockl_fprintf_append_string_n+0x1078>
	v_mov_b32_e32 v6, 0                                        // 00000000331C: 7E0C0280
	s_clause 0x2                                               // 000000003320: BFA10002
	global_load_dwordx2 v[0:1], v6, s[6:7] offset:40           // 000000003324: DC348028 00060006
	global_load_dwordx2 v[9:10], v6, s[6:7] offset:24 glc dlc  // 00000000332C: DC359018 09060006
	global_load_dwordx2 v[2:3], v6, s[6:7]                     // 000000003334: DC348000 02060006
	s_waitcnt vmcnt(2)                                         // 00000000333C: BF8C3F72
	v_readfirstlane_b32 s14, v0                                // 000000003340: 7E1C0500
	v_readfirstlane_b32 s15, v1                                // 000000003344: 7E1E0501
	s_add_u32 s11, s14, 1                                      // 000000003348: 800B810E
	s_addc_u32 s13, s15, 0                                     // 00000000334C: 820D800F
	s_add_u32 s4, s11, s8                                      // 000000003350: 8004080B
	s_addc_u32 s5, s13, s9                                     // 000000003354: 8205090D
	s_cmp_eq_u64 s[4:5], 0                                     // 000000003358: BF128004
	s_cselect_b32 s5, s13, s5                                  // 00000000335C: 8505050D
	s_cselect_b32 s4, s11, s4                                  // 000000003360: 8504040B
	v_mov_b32_e32 v8, s5                                       // 000000003364: 7E100205
	s_and_b64 s[8:9], s[4:5], s[14:15]                         // 000000003368: 87880E04
	v_mov_b32_e32 v7, s4                                       // 00000000336C: 7E0E0204
	s_mul_i32 s9, s9, 24                                       // 000000003370: 93099809
	s_mul_hi_u32 s11, s8, 24                                   // 000000003374: 9A8B9808
	s_mul_i32 s8, s8, 24                                       // 000000003378: 93089808
	s_add_i32 s11, s11, s9                                     // 00000000337C: 810B090B
	s_waitcnt vmcnt(0)                                         // 000000003380: BF8C3F70
	v_add_co_u32 v4, vcc_lo, v2, s8                            // 000000003384: D70F6A04 02001102
	v_add_co_ci_u32_e64 v5, null, s11, v3, vcc_lo              // 00000000338C: D5287D05 01AA060B
	global_store_dwordx2 v[4:5], v[9:10], off                  // 000000003394: DC748000 007D0904
	s_waitcnt_vscnt null, 0x0                                  // 00000000339C: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v6, v[7:10], s[6:7] offset:24 glc// 0000000033A0: DD458018 02060706
	s_waitcnt vmcnt(0)                                         // 0000000033A8: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[2:3], v[9:10]                   // 0000000033AC: 7DCA1302
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 0000000033B0: 877E6A7E
	s_cbranch_execz 16                                         // 0000000033B4: BF880010 <__ockl_fprintf_append_string_n+0x1078>
	s_mov_b32 s8, 0                                            // 0000000033B8: BE880380
	v_mov_b32_e32 v0, s4                                       // 0000000033BC: 7E000204
	v_mov_b32_e32 v1, s5                                       // 0000000033C0: 7E020205
	s_sleep 1                                                  // 0000000033C4: BF8E0001
	global_store_dwordx2 v[4:5], v[2:3], off                   // 0000000033C8: DC748000 007D0204
	s_waitcnt_vscnt null, 0x0                                  // 0000000033D0: BBFD0000
	global_atomic_cmpswap_x2 v[0:1], v6, v[0:3], s[6:7] offset:24 glc// 0000000033D4: DD458018 00060006
	s_waitcnt vmcnt(0)                                         // 0000000033DC: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]                    // 0000000033E0: 7DC40500
	v_mov_b32_e32 v3, v1                                       // 0000000033E4: 7E060301
	v_mov_b32_e32 v2, v0                                       // 0000000033E8: 7E040300
	s_or_b32 s8, vcc_lo, s8                                    // 0000000033EC: 8808086A
	s_andn2_b32 exec_lo, exec_lo, s8                           // 0000000033F0: 8A7E087E
	s_cbranch_execnz 65521                                     // 0000000033F4: BF89FFF1 <__ockl_fprintf_append_string_n+0x103c>
	s_or_b32 exec_lo, exec_lo, s10                             // 0000000033F8: 887E0A7E
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000033FC: 887E0C7E
	s_waitcnt lgkmcnt(0)                                       // 000000003400: BF8CC07F
	s_setpc_b64 s[30:31]                                       // 000000003404: BE80201E
	s_nop 0                                                    // 000000003408: BF800000
	s_nop 0                                                    // 00000000340C: BF800000
	s_nop 0                                                    // 000000003410: BF800000
	s_nop 0                                                    // 000000003414: BF800000
	s_nop 0                                                    // 000000003418: BF800000
	s_nop 0                                                    // 00000000341C: BF800000
	s_nop 0                                                    // 000000003420: BF800000
	s_nop 0                                                    // 000000003424: BF800000
	s_nop 0                                                    // 000000003428: BF800000
	s_nop 0                                                    // 00000000342C: BF800000
	s_nop 0                                                    // 000000003430: BF800000
	s_nop 0                                                    // 000000003434: BF800000
	s_nop 0                                                    // 000000003438: BF800000
	s_nop 0                                                    // 00000000343C: BF800000

0000000000003440 <__assert_fail>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000003440: BF8C0000
	s_mov_b32 s23, s33                                         // 000000003444: BE970321
	s_mov_b32 s33, s32                                         // 000000003448: BEA10320
	s_or_saveexec_b32 s4, -1                                   // 00000000344C: BE843DC1
	buffer_store_dword v40, off, s[0:3], s33                   // 000000003450: E0700000 21002800
	s_mov_b32 exec_lo, s4                                      // 000000003458: BEFE0304
	v_writelane_b32 v40, s30, 0                                // 00000000345C: D7610028 0201001E
	s_addk_i32 s32, 0x200                                      // 000000003464: B7A00200
	v_writelane_b32 v40, s31, 1                                // 000000003468: D7610028 0201021F
	s_load_dwordx2 s[6:7], s[8:9], 0x50                        // 000000003470: F4040184 FA000050
	v_mbcnt_lo_u32_b32 v36, -1, 0                              // 000000003478: D7650024 020100C1
	v_mov_b32_e32 v8, v1                                       // 000000003480: 7E100301
	v_mov_b32_e32 v7, v0                                       // 000000003484: 7E0E0300
	v_mov_b32_e32 v0, 0                                        // 000000003488: 7E000280
	v_mov_b32_e32 v1, 0                                        // 00000000348C: 7E020280
	v_readfirstlane_b32 s4, v36                                // 000000003490: 7E080524
	v_cmp_eq_u32_e64 s4, s4, v36                               // 000000003494: D4C20004 02024804
	s_and_saveexec_b32 s5, s4                                  // 00000000349C: BE853C04
	s_cbranch_execz 87                                         // 0000000034A0: BF880057 <__assert_fail+0x1c0>
	v_mov_b32_e32 v9, 0                                        // 0000000034A4: 7E120280
	s_mov_b32 s10, exec_lo                                     // 0000000034A8: BE8A037E
	s_waitcnt lgkmcnt(0)                                       // 0000000034AC: BF8CC07F
	global_load_dwordx2 v[12:13], v9, s[6:7] offset:24 glc dlc // 0000000034B0: DC359018 0C060009
	s_waitcnt vmcnt(0)                                         // 0000000034B8: BF8C3F70
	buffer_gl1_inv                                             // 0000000034BC: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000034C4: E1C40000 00000000
	s_clause 0x1                                               // 0000000034CC: BFA10001
	global_load_dwordx2 v[0:1], v9, s[6:7] offset:40           // 0000000034D0: DC348028 00060009
	global_load_dwordx2 v[10:11], v9, s[6:7]                   // 0000000034D8: DC348000 0A060009
	s_waitcnt vmcnt(1)                                         // 0000000034E0: BF8C3F71
	v_and_b32_e32 v1, v1, v13                                  // 0000000034E4: 36021B01
	v_and_b32_e32 v0, v0, v12                                  // 0000000034E8: 36001900
	v_mul_lo_u32 v1, v1, 24                                    // 0000000034EC: D5690001 02013101
	v_mul_hi_u32 v14, v0, 24                                   // 0000000034F4: D56A000E 02013100
	v_mul_lo_u32 v0, v0, 24                                    // 0000000034FC: D5690000 02013100
	v_add_nc_u32_e32 v1, v14, v1                               // 000000003504: 4A02030E
	s_waitcnt vmcnt(0)                                         // 000000003508: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v10, v0                           // 00000000350C: D70F6A00 0202010A
	v_add_co_ci_u32_e64 v1, null, v11, v1, vcc_lo              // 000000003514: D5287D01 01AA030B
	global_load_dwordx2 v[10:11], v[0:1], off glc dlc          // 00000000351C: DC359000 0A7D0000
	s_waitcnt vmcnt(0)                                         // 000000003524: BF8C3F70
	global_atomic_cmpswap_x2 v[0:1], v9, v[10:13], s[6:7] offset:24 glc// 000000003528: DD458018 00060A09
	s_waitcnt vmcnt(0)                                         // 000000003530: BF8C3F70
	buffer_gl1_inv                                             // 000000003534: E1C80000 00000000
	buffer_gl0_inv                                             // 00000000353C: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[0:1], v[12:13]                         // 000000003544: 7DEA1900
	s_cbranch_execz 44                                         // 000000003548: BF88002C <__assert_fail+0x1bc>
	s_mov_b32 s11, 0                                           // 00000000354C: BE8B0380
	s_nop 0                                                    // 000000003550: BF800000
	s_nop 0                                                    // 000000003554: BF800000
	s_nop 0                                                    // 000000003558: BF800000
	s_nop 0                                                    // 00000000355C: BF800000
	s_nop 0                                                    // 000000003560: BF800000
	s_nop 0                                                    // 000000003564: BF800000
	s_nop 0                                                    // 000000003568: BF800000
	s_nop 0                                                    // 00000000356C: BF800000
	s_nop 0                                                    // 000000003570: BF800000
	s_nop 0                                                    // 000000003574: BF800000
	s_nop 0                                                    // 000000003578: BF800000
	s_nop 0                                                    // 00000000357C: BF800000
	s_sleep 1                                                  // 000000003580: BF8E0001
	s_clause 0x1                                               // 000000003584: BFA10001
	global_load_dwordx2 v[10:11], v9, s[6:7] offset:40         // 000000003588: DC348028 0A060009
	global_load_dwordx2 v[14:15], v9, s[6:7]                   // 000000003590: DC348000 0E060009
	v_mov_b32_e32 v12, v0                                      // 000000003598: 7E180300
	v_mov_b32_e32 v13, v1                                      // 00000000359C: 7E1A0301
	s_waitcnt vmcnt(1)                                         // 0000000035A0: BF8C3F71
	v_and_b32_e32 v0, v10, v12                                 // 0000000035A4: 3600190A
	s_waitcnt vmcnt(0)                                         // 0000000035A8: BF8C3F70
	v_mad_u64_u32 v[14:15], null, v0, 24, v[14:15]             // 0000000035AC: D5767D0E 04393100
	v_and_b32_e32 v0, v11, v13                                 // 0000000035B4: 36001B0B
	v_mad_u64_u32 v[15:16], null, v0, 24, v[15:16]             // 0000000035B8: D5767D0F 043D3100
	global_load_dwordx2 v[10:11], v[14:15], off glc dlc        // 0000000035C0: DC359000 0A7D000E
	s_waitcnt vmcnt(0)                                         // 0000000035C8: BF8C3F70
	global_atomic_cmpswap_x2 v[0:1], v9, v[10:13], s[6:7] offset:24 glc// 0000000035CC: DD458018 00060A09
	s_waitcnt vmcnt(0)                                         // 0000000035D4: BF8C3F70
	buffer_gl1_inv                                             // 0000000035D8: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000035E0: E1C40000 00000000
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[12:13]                  // 0000000035E8: 7DC41900
	s_or_b32 s11, vcc_lo, s11                                  // 0000000035EC: 880B0B6A
	s_andn2_b32 exec_lo, exec_lo, s11                          // 0000000035F0: 8A7E0B7E
	s_cbranch_execnz 65506                                     // 0000000035F4: BF89FFE2 <__assert_fail+0x140>
	s_or_b32 exec_lo, exec_lo, s11                             // 0000000035F8: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 0000000035FC: 887E0A7E
	s_or_b32 exec_lo, exec_lo, s5                              // 000000003600: 887E057E
	v_mov_b32_e32 v14, 0                                       // 000000003604: 7E1C0280
	v_readfirstlane_b32 s11, v1                                // 000000003608: 7E160501
	v_readfirstlane_b32 s10, v0                                // 00000000360C: 7E140500
	s_mov_b32 s5, exec_lo                                      // 000000003610: BE85037E
	s_waitcnt lgkmcnt(0)                                       // 000000003614: BF8CC07F
	s_clause 0x1                                               // 000000003618: BFA10001
	global_load_dwordx2 v[15:16], v14, s[6:7] offset:40        // 00000000361C: DC348028 0F06000E
	global_load_dwordx4 v[9:12], v14, s[6:7]                   // 000000003624: DC388000 0906000E
	s_waitcnt vmcnt(1)                                         // 00000000362C: BF8C3F71
	v_readfirstlane_b32 s12, v15                               // 000000003630: 7E18050F
	v_readfirstlane_b32 s13, v16                               // 000000003634: 7E1A0510
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000003638: 878C0A0C
	s_mul_i32 s14, s13, 24                                     // 00000000363C: 930E980D
	s_mul_hi_u32 s15, s12, 24                                  // 000000003640: 9A8F980C
	s_mul_i32 s16, s12, 24                                     // 000000003644: 9310980C
	s_add_i32 s15, s15, s14                                    // 000000003648: 810F0E0F
	s_waitcnt vmcnt(0)                                         // 00000000364C: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v9, s16                           // 000000003650: D70F6A00 02002109
	v_add_co_ci_u32_e64 v1, null, s15, v10, vcc_lo             // 000000003658: D5287D01 01AA140F
	s_and_saveexec_b32 s14, s4                                 // 000000003660: BE8E3C04
	s_cbranch_execz 5                                          // 000000003664: BF880005 <__assert_fail+0x23c>
	v_mov_b32_e32 v13, s5                                      // 000000003668: 7E1A0205
	v_mov_b32_e32 v15, 2                                       // 00000000366C: 7E1E0282
	v_mov_b32_e32 v16, 1                                       // 000000003670: 7E200281
	global_store_dwordx4 v[0:1], v[13:16], off offset:8        // 000000003674: DC788008 007D0D00
	s_or_b32 exec_lo, exec_lo, s14                             // 00000000367C: 887E0E7E
	s_lshl_b64 s[12:13], s[12:13], 12                          // 000000003680: 8F8C8C0C
	v_lshlrev_b32_e32 v35, 6, v36                              // 000000003684: 34464886
	v_add_co_u32 v11, vcc_lo, v11, s12                         // 000000003688: D70F6A0B 0200190B
	v_add_co_ci_u32_e64 v12, null, s13, v12, vcc_lo            // 000000003690: D5287D0C 01AA180D
	s_mov_b32 s12, 0                                           // 000000003698: BE8C0380
	v_add_co_u32 v17, vcc_lo, v11, v35                         // 00000000369C: D70F6A11 0202470B
	s_mov_b32 s13, s12                                         // 0000000036A4: BE8D030C
	s_mov_b32 s14, s12                                         // 0000000036A8: BE8E030C
	s_mov_b32 s15, s12                                         // 0000000036AC: BE8F030C
	v_mov_b32_e32 v13, 33                                      // 0000000036B0: 7E1A02A1
	v_mov_b32_e32 v15, 1                                       // 0000000036B4: 7E1E0281
	v_mov_b32_e32 v16, v14                                     // 0000000036B8: 7E20030E
	v_readfirstlane_b32 s16, v11                               // 0000000036BC: 7E20050B
	v_readfirstlane_b32 s17, v12                               // 0000000036C0: 7E22050C
	v_add_co_ci_u32_e64 v18, null, 0, v12, vcc_lo              // 0000000036C4: D5287D12 01AA1880
	v_mov_b32_e32 v22, s15                                     // 0000000036CC: 7E2C020F
	v_mov_b32_e32 v21, s14                                     // 0000000036D0: 7E2A020E
	v_mov_b32_e32 v20, s13                                     // 0000000036D4: 7E28020D
	v_mov_b32_e32 v19, s12                                     // 0000000036D8: 7E26020C
	global_store_dwordx4 v35, v[13:16], s[16:17]               // 0000000036DC: DC788000 00100D23
	global_store_dwordx4 v35, v[19:22], s[16:17] offset:16     // 0000000036E4: DC788010 00101323
	global_store_dwordx4 v35, v[19:22], s[16:17] offset:32     // 0000000036EC: DC788020 00101323
	global_store_dwordx4 v35, v[19:22], s[16:17] offset:48     // 0000000036F4: DC788030 00101323
	s_and_saveexec_b32 s5, s4                                  // 0000000036FC: BE853C04
	s_cbranch_execz 80                                         // 000000003700: BF880050 <__assert_fail+0x404>
	v_mov_b32_e32 v15, 0                                       // 000000003704: 7E1E0280
	v_mov_b32_e32 v19, s10                                     // 000000003708: 7E26020A
	v_mov_b32_e32 v20, s11                                     // 00000000370C: 7E28020B
	s_mov_b32 s12, exec_lo                                     // 000000003710: BE8C037E
	s_clause 0x1                                               // 000000003714: BFA10001
	global_load_dwordx2 v[21:22], v15, s[6:7] offset:32 glc dlc// 000000003718: DC359020 1506000F
	global_load_dwordx2 v[11:12], v15, s[6:7] offset:40        // 000000003720: DC348028 0B06000F
	s_waitcnt vmcnt(0)                                         // 000000003728: BF8C3F70
	v_and_b32_e32 v12, s11, v12                                // 00000000372C: 3618180B
	v_and_b32_e32 v11, s10, v11                                // 000000003730: 3616160A
	v_mul_lo_u32 v12, v12, 24                                  // 000000003734: D569000C 0201310C
	v_mul_hi_u32 v13, v11, 24                                  // 00000000373C: D56A000D 0201310B
	v_mul_lo_u32 v11, v11, 24                                  // 000000003744: D569000B 0201310B
	v_add_nc_u32_e32 v12, v13, v12                             // 00000000374C: 4A18190D
	v_add_co_u32 v13, vcc_lo, v9, v11                          // 000000003750: D70F6A0D 02021709
	v_add_co_ci_u32_e64 v14, null, v10, v12, vcc_lo            // 000000003758: D5287D0E 01AA190A
	global_store_dwordx2 v[13:14], v[21:22], off               // 000000003760: DC748000 007D150D
	s_waitcnt_vscnt null, 0x0                                  // 000000003768: BBFD0000
	global_atomic_cmpswap_x2 v[11:12], v15, v[19:22], s[6:7] offset:32 glc// 00000000376C: DD458020 0B06130F
	s_waitcnt vmcnt(0)                                         // 000000003774: BF8C3F70
	v_cmpx_ne_u64_e32 v[11:12], v[21:22]                       // 000000003778: 7DEA2B0B
	s_cbranch_execz 16                                         // 00000000377C: BF880010 <__assert_fail+0x380>
	s_mov_b32 s13, 0                                           // 000000003780: BE8D0380
	v_mov_b32_e32 v9, s10                                      // 000000003784: 7E12020A
	v_mov_b32_e32 v10, s11                                     // 000000003788: 7E14020B
	s_sleep 1                                                  // 00000000378C: BF8E0001
	global_store_dwordx2 v[13:14], v[11:12], off               // 000000003790: DC748000 007D0B0D
	s_waitcnt_vscnt null, 0x0                                  // 000000003798: BBFD0000
	global_atomic_cmpswap_x2 v[9:10], v15, v[9:12], s[6:7] offset:32 glc// 00000000379C: DD458020 0906090F
	s_waitcnt vmcnt(0)                                         // 0000000037A4: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[9:10], v[11:12]                 // 0000000037A8: 7DC41709
	v_mov_b32_e32 v12, v10                                     // 0000000037AC: 7E18030A
	v_mov_b32_e32 v11, v9                                      // 0000000037B0: 7E160309
	s_or_b32 s13, vcc_lo, s13                                  // 0000000037B4: 880D0D6A
	s_andn2_b32 exec_lo, exec_lo, s13                          // 0000000037B8: 8A7E0D7E
	s_cbranch_execnz 65521                                     // 0000000037BC: BF89FFF1 <__assert_fail+0x344>
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000037C0: 887E0C7E
	v_mov_b32_e32 v12, 0                                       // 0000000037C4: 7E180280
	s_mov_b32 s13, exec_lo                                     // 0000000037C8: BE8D037E
	s_mov_b32 s12, exec_lo                                     // 0000000037CC: BE8C037E
	v_mbcnt_lo_u32_b32 v11, s13, 0                             // 0000000037D0: D765000B 0201000D
	global_load_dwordx2 v[9:10], v12, s[6:7] offset:16         // 0000000037D8: DC348010 0906000C
	v_cmpx_eq_u32_e32 0, v11                                   // 0000000037E0: 7DA41680
	s_cbranch_execz 5                                          // 0000000037E4: BF880005 <__assert_fail+0x3bc>
	s_bcnt1_i32_b32 s13, s13                                   // 0000000037E8: BE8D0F0D
	v_mov_b32_e32 v11, s13                                     // 0000000037EC: 7E16020D
	s_waitcnt vmcnt(0)                                         // 0000000037F0: BF8C3F70
	global_atomic_add_x2 v[9:10], v[11:12], off offset:8       // 0000000037F4: DD488008 007D0B09
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000037FC: 887E0C7E
	s_waitcnt vmcnt(0)                                         // 000000003800: BF8C3F70
	global_load_dwordx2 v[11:12], v[9:10], off offset:16       // 000000003804: DC348010 0B7D0009
	s_waitcnt vmcnt(0)                                         // 00000000380C: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[11:12]                       // 000000003810: 7DC41680
	s_cbranch_vccnz 11                                         // 000000003814: BF87000B <__assert_fail+0x404>
	global_load_dword v9, v[9:10], off offset:24               // 000000003818: DC308018 097D0009
	v_mov_b32_e32 v10, 0                                       // 000000003820: 7E140280
	s_waitcnt vmcnt(0)                                         // 000000003824: BF8C3F70
	v_readfirstlane_b32 s12, v9                                // 000000003828: 7E180509
	s_waitcnt_vscnt null, 0x0                                  // 00000000382C: BBFD0000
	global_store_dwordx2 v[11:12], v[9:10], off                // 000000003830: DC748000 007D090B
	s_and_b32 m0, s12, 0x7fffff                                // 000000003838: 877CFF0C 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 000000003840: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 000000003844: 887E057E
	s_branch 23                                                // 000000003848: BF820017 <__assert_fail+0x468>
	s_nop 0                                                    // 00000000384C: BF800000
	s_nop 0                                                    // 000000003850: BF800000
	s_nop 0                                                    // 000000003854: BF800000
	s_nop 0                                                    // 000000003858: BF800000
	s_nop 0                                                    // 00000000385C: BF800000
	s_nop 0                                                    // 000000003860: BF800000
	s_nop 0                                                    // 000000003864: BF800000
	s_nop 0                                                    // 000000003868: BF800000
	s_nop 0                                                    // 00000000386C: BF800000
	s_nop 0                                                    // 000000003870: BF800000
	s_nop 0                                                    // 000000003874: BF800000
	s_nop 0                                                    // 000000003878: BF800000
	s_nop 0                                                    // 00000000387C: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000003880: 887E057E
	v_readfirstlane_b32 s5, v9                                 // 000000003884: 7E0A0509
	s_cmp_eq_u32 s5, 0                                         // 000000003888: BF068005
	s_cbranch_scc1 28                                          // 00000000388C: BF85001C <__assert_fail+0x4c0>
	s_mov_b32 s5, 0                                            // 000000003890: BE850380
	s_sleep 1                                                  // 000000003894: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000003898: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 00000000389C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 0000000038A0: BF078105
	s_cbranch_scc0 24                                          // 0000000038A4: BF840018 <__assert_fail+0x4c8>
	v_mov_b32_e32 v9, 1                                        // 0000000038A8: 7E120281
	s_and_saveexec_b32 s5, s4                                  // 0000000038AC: BE853C04
	s_cbranch_execz 65523                                      // 0000000038B0: BF88FFF3 <__assert_fail+0x440>
	global_load_dword v9, v[0:1], off offset:20 glc dlc        // 0000000038B4: DC319014 097D0000
	s_waitcnt vmcnt(0)                                         // 0000000038BC: BF8C3F70
	buffer_gl1_inv                                             // 0000000038C0: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000038C8: E1C40000 00000000
	v_and_b32_e32 v9, 1, v9                                    // 0000000038D0: 36121281
	s_branch 65514                                             // 0000000038D4: BF82FFEA <__assert_fail+0x440>
	s_nop 0                                                    // 0000000038D8: BF800000
	s_nop 0                                                    // 0000000038DC: BF800000
	s_nop 0                                                    // 0000000038E0: BF800000
	s_nop 0                                                    // 0000000038E4: BF800000
	s_nop 0                                                    // 0000000038E8: BF800000
	s_nop 0                                                    // 0000000038EC: BF800000
	s_nop 0                                                    // 0000000038F0: BF800000
	s_nop 0                                                    // 0000000038F4: BF800000
	s_nop 0                                                    // 0000000038F8: BF800000
	s_nop 0                                                    // 0000000038FC: BF800000
	s_mov_b32 s5, -1                                           // 000000003900: BE8503C1
	s_branch 65508                                             // 000000003904: BF82FFE4 <__assert_fail+0x458>
	global_load_dwordx2 v[13:14], v[17:18], off                // 000000003908: DC348000 0D7D0011
	s_and_saveexec_b32 s12, s4                                 // 000000003910: BE8C3C04
	s_cbranch_execz 55                                         // 000000003914: BF880037 <__assert_fail+0x5b4>
	v_mov_b32_e32 v15, 0                                       // 000000003918: 7E1E0280
	s_clause 0x2                                               // 00000000391C: BFA10002
	global_load_dwordx2 v[0:1], v15, s[6:7] offset:40          // 000000003920: DC348028 0006000F
	global_load_dwordx2 v[18:19], v15, s[6:7] offset:24 glc dlc// 000000003928: DC359018 1206000F
	global_load_dwordx2 v[9:10], v15, s[6:7]                   // 000000003930: DC348000 0906000F
	s_waitcnt vmcnt(2)                                         // 000000003938: BF8C3F72
	v_readfirstlane_b32 s14, v0                                // 00000000393C: 7E1C0500
	v_readfirstlane_b32 s15, v1                                // 000000003940: 7E1E0501
	s_add_u32 s13, s14, 1                                      // 000000003944: 800D810E
	s_addc_u32 s16, s15, 0                                     // 000000003948: 8210800F
	s_add_u32 s4, s13, s10                                     // 00000000394C: 80040A0D
	s_addc_u32 s5, s16, s11                                    // 000000003950: 82050B10
	s_cmp_eq_u64 s[4:5], 0                                     // 000000003954: BF128004
	s_cselect_b32 s5, s16, s5                                  // 000000003958: 85050510
	s_cselect_b32 s4, s13, s4                                  // 00000000395C: 8504040D
	v_mov_b32_e32 v17, s5                                      // 000000003960: 7E220205
	s_and_b64 s[10:11], s[4:5], s[14:15]                       // 000000003964: 878A0E04
	v_mov_b32_e32 v16, s4                                      // 000000003968: 7E200204
	s_mul_i32 s11, s11, 24                                     // 00000000396C: 930B980B
	s_mul_hi_u32 s13, s10, 24                                  // 000000003970: 9A8D980A
	s_mul_i32 s10, s10, 24                                     // 000000003974: 930A980A
	s_add_i32 s13, s13, s11                                    // 000000003978: 810D0B0D
	s_waitcnt vmcnt(0)                                         // 00000000397C: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v9, s10                           // 000000003980: D70F6A00 02001509
	v_add_co_ci_u32_e64 v1, null, s13, v10, vcc_lo             // 000000003988: D5287D01 01AA140D
	global_store_dwordx2 v[0:1], v[18:19], off                 // 000000003990: DC748000 007D1200
	s_waitcnt_vscnt null, 0x0                                  // 000000003998: BBFD0000
	global_atomic_cmpswap_x2 v[11:12], v15, v[16:19], s[6:7] offset:24 glc// 00000000399C: DD458018 0B06100F
	s_waitcnt vmcnt(0)                                         // 0000000039A4: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[11:12], v[18:19]                // 0000000039A8: 7DCA250B
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 0000000039AC: 877E6A7E
	s_cbranch_execz 16                                         // 0000000039B0: BF880010 <__assert_fail+0x5b4>
	s_mov_b32 s10, 0                                           // 0000000039B4: BE8A0380
	v_mov_b32_e32 v9, s4                                       // 0000000039B8: 7E120204
	v_mov_b32_e32 v10, s5                                      // 0000000039BC: 7E140205
	s_sleep 1                                                  // 0000000039C0: BF8E0001
	global_store_dwordx2 v[0:1], v[11:12], off                 // 0000000039C4: DC748000 007D0B00
	s_waitcnt_vscnt null, 0x0                                  // 0000000039CC: BBFD0000
	global_atomic_cmpswap_x2 v[9:10], v15, v[9:12], s[6:7] offset:24 glc// 0000000039D0: DD458018 0906090F
	s_waitcnt vmcnt(0)                                         // 0000000039D8: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[9:10], v[11:12]                 // 0000000039DC: 7DC41709
	v_mov_b32_e32 v12, v10                                     // 0000000039E0: 7E18030A
	v_mov_b32_e32 v11, v9                                      // 0000000039E4: 7E160309
	s_or_b32 s10, vcc_lo, s10                                  // 0000000039E8: 880A0A6A
	s_andn2_b32 exec_lo, exec_lo, s10                          // 0000000039EC: 8A7E0A7E
	s_cbranch_execnz 65521                                     // 0000000039F0: BF89FFF1 <__assert_fail+0x578>
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000039F4: 887E0C7E
	s_getpc_b64 s[10:11]                                       // 0000000039F8: BE8A1F00
	s_add_u32 s10, s10, 0xffffd584                             // 0000000039FC: 800AFF0A FFFFD584
	s_addc_u32 s11, s11, lit(0xffffffff)                       // 000000003A04: 820BFF0B FFFFFFFF
	s_cmp_lg_u64 s[10:11], 0                                   // 000000003A0C: BF13800A
	s_cbranch_scc0 584                                         // 000000003A10: BF840248 <__assert_fail+0xef4>
	s_getpc_b64 s[4:5]                                         // 000000003A14: BE841F00
	s_add_u32 s4, s4, 0xffffd597                               // 000000003A18: 8004FF04 FFFFD597
	s_addc_u32 s5, s5, lit(0xffffffff)                         // 000000003A20: 8205FF05 FFFFFFFF
	s_waitcnt vmcnt(0)                                         // 000000003A28: BF8C3F70
	v_and_b32_e32 v37, 2, v13                                  // 000000003A2C: 364A1A82
	v_mov_b32_e32 v16, 0                                       // 000000003A30: 7E200280
	v_and_b32_e32 v9, -3, v13                                  // 000000003A34: 36121AC3
	v_mov_b32_e32 v10, v14                                     // 000000003A38: 7E14030E
	v_mov_b32_e32 v17, 2                                       // 000000003A3C: 7E220282
	v_mov_b32_e32 v18, 1                                       // 000000003A40: 7E240281
	s_sub_i32 s12, s4, s10                                     // 000000003A44: 818C0A04
	s_ashr_i32 s13, s12, 31                                    // 000000003A48: 910D9F0C
	s_branch 7                                                 // 000000003A4C: BF820007 <__assert_fail+0x62c>
	s_or_b32 exec_lo, exec_lo, s16                             // 000000003A50: 887E107E
	s_sub_u32 s12, s12, s19                                    // 000000003A54: 808C130C
	s_subb_u32 s13, s13, s18                                   // 000000003A58: 828D120D
	s_add_u32 s10, s10, s19                                    // 000000003A5C: 800A130A
	s_addc_u32 s11, s11, s18                                   // 000000003A60: 820B120B
	s_cmp_lg_u64 s[12:13], 0                                   // 000000003A64: BF13800C
	s_cbranch_scc0 564                                         // 000000003A68: BF840234 <__assert_fail+0xefc>
	v_cmp_lt_u64_e64 s4, s[12:13], 56                          // 000000003A6C: D4E10004 0201700C
	v_cmp_gt_u64_e64 s5, s[12:13], 7                           // 000000003A74: D4E40005 02010E0C
	s_and_b32 s4, s4, exec_lo                                  // 000000003A7C: 87047E04
	s_cselect_b32 s18, s13, 0                                  // 000000003A80: 8512800D
	s_cselect_b32 s19, s12, 56                                 // 000000003A84: 8513B80C
	s_and_b32 vcc_lo, exec_lo, s5                              // 000000003A88: 876A057E
	s_mov_b32 s4, -1                                           // 000000003A8C: BE8403C1
	s_cbranch_vccnz 21                                         // 000000003A90: BF870015 <__assert_fail+0x6a8>
	s_waitcnt vmcnt(0)                                         // 000000003A94: BF8C3F70
	v_mov_b32_e32 v11, 0                                       // 000000003A98: 7E160280
	v_mov_b32_e32 v12, 0                                       // 000000003A9C: 7E180280
	s_cmp_eq_u64 s[12:13], 0                                   // 000000003AA0: BF12800C
	s_cbranch_scc1 15                                          // 000000003AA4: BF85000F <__assert_fail+0x6a4>
	s_mov_b32 s4, 0                                            // 000000003AA8: BE840380
	v_mov_b32_e32 v0, s4                                       // 000000003AAC: 7E000204
	s_lshl_b32 s5, s4, 3                                       // 000000003AB0: 8F058304
	s_add_i32 s4, s4, 1                                        // 000000003AB4: 81048104
	s_cmp_lg_u32 s4, s19                                       // 000000003AB8: BF071304
	global_load_ubyte v0, v0, s[10:11]                         // 000000003ABC: DC208000 000A0000
	s_waitcnt vmcnt(0)                                         // 000000003AC4: BF8C3F70
	v_and_b32_e32 v15, 0xffff, v0                              // 000000003AC8: 361E00FF 0000FFFF
	v_lshlrev_b64 v[0:1], s5, v[15:16]                         // 000000003AD0: D6FF0000 02021E05
	v_or_b32_e32 v11, v0, v11                                  // 000000003AD8: 38161700
	v_or_b32_e32 v12, v1, v12                                  // 000000003ADC: 38181901
	s_cbranch_scc1 65522                                       // 000000003AE0: BF85FFF2 <__assert_fail+0x66c>
	s_mov_b32 s4, 0                                            // 000000003AE4: BE840380
	s_and_b32 s4, s4, exec_lo                                  // 000000003AE8: 87047E04
	s_cselect_b32 s4, 1, 0                                     // 000000003AEC: 85048081
	s_mov_b32 s14, 0                                           // 000000003AF0: BE8E0380
	s_cmp_lg_u32 s4, 1                                         // 000000003AF4: BF078104
	s_mov_b64 s[4:5], s[10:11]                                 // 000000003AF8: BE84040A
	s_cbranch_scc1 5                                           // 000000003AFC: BF850005 <__assert_fail+0x6d4>
	global_load_dwordx2 v[11:12], v16, s[10:11]                // 000000003B00: DC348000 0B0A0010
	s_add_i32 s14, s19, -8                                     // 000000003B08: 810EC813
	s_add_u32 s4, s10, 8                                       // 000000003B0C: 8004880A
	s_addc_u32 s5, s11, 0                                      // 000000003B10: 8205800B
	s_cmp_gt_u32 s14, 7                                        // 000000003B14: BF08870E
	s_cbranch_scc1 21                                          // 000000003B18: BF850015 <__assert_fail+0x730>
	v_mov_b32_e32 v19, 0                                       // 000000003B1C: 7E260280
	v_mov_b32_e32 v20, 0                                       // 000000003B20: 7E280280
	s_cmp_eq_u32 s14, 0                                        // 000000003B24: BF06800E
	s_cbranch_scc1 15                                          // 000000003B28: BF85000F <__assert_fail+0x728>
	s_mov_b32 s15, 0                                           // 000000003B2C: BE8F0380
	v_mov_b32_e32 v0, s15                                      // 000000003B30: 7E00020F
	s_lshl_b32 s16, s15, 3                                     // 000000003B34: 8F10830F
	s_add_i32 s15, s15, 1                                      // 000000003B38: 810F810F
	s_cmp_lg_u32 s15, s14                                      // 000000003B3C: BF070E0F
	global_load_ubyte v0, v0, s[4:5]                           // 000000003B40: DC208000 00040000
	s_waitcnt vmcnt(0)                                         // 000000003B48: BF8C3F70
	v_and_b32_e32 v15, 0xffff, v0                              // 000000003B4C: 361E00FF 0000FFFF
	v_lshlrev_b64 v[0:1], s16, v[15:16]                        // 000000003B54: D6FF0000 02021E10
	v_or_b32_e32 v19, v0, v19                                  // 000000003B5C: 38262700
	v_or_b32_e32 v20, v1, v20                                  // 000000003B60: 38282901
	s_cbranch_scc1 65522                                       // 000000003B64: BF85FFF2 <__assert_fail+0x6f0>
	s_mov_b32 s15, 0                                           // 000000003B68: BE8F0380
	s_branch 1                                                 // 000000003B6C: BF820001 <__assert_fail+0x734>
	s_mov_b32 s15, -1                                          // 000000003B70: BE8F03C1
	s_and_b32 s15, s15, exec_lo                                // 000000003B74: 870F7E0F
	s_cselect_b32 s15, 1, 0                                    // 000000003B78: 850F8081
	s_cmp_lg_u32 s15, 1                                        // 000000003B7C: BF07810F
	s_mov_b32 s15, 0                                           // 000000003B80: BE8F0380
	s_cbranch_scc1 5                                           // 000000003B84: BF850005 <__assert_fail+0x75c>
	global_load_dwordx2 v[19:20], v16, s[4:5]                  // 000000003B88: DC348000 13040010
	s_add_i32 s15, s14, -8                                     // 000000003B90: 810FC80E
	s_add_u32 s4, s4, 8                                        // 000000003B94: 80048804
	s_addc_u32 s5, s5, 0                                       // 000000003B98: 82058005
	s_cmp_gt_u32 s15, 7                                        // 000000003B9C: BF08870F
	s_cbranch_scc1 21                                          // 000000003BA0: BF850015 <__assert_fail+0x7b8>
	v_mov_b32_e32 v21, 0                                       // 000000003BA4: 7E2A0280
	v_mov_b32_e32 v22, 0                                       // 000000003BA8: 7E2C0280
	s_cmp_eq_u32 s15, 0                                        // 000000003BAC: BF06800F
	s_cbranch_scc1 15                                          // 000000003BB0: BF85000F <__assert_fail+0x7b0>
	s_mov_b32 s14, 0                                           // 000000003BB4: BE8E0380
	v_mov_b32_e32 v0, s14                                      // 000000003BB8: 7E00020E
	s_lshl_b32 s16, s14, 3                                     // 000000003BBC: 8F10830E
	s_add_i32 s14, s14, 1                                      // 000000003BC0: 810E810E
	s_cmp_lg_u32 s14, s15                                      // 000000003BC4: BF070F0E
	global_load_ubyte v0, v0, s[4:5]                           // 000000003BC8: DC208000 00040000
	s_waitcnt vmcnt(0)                                         // 000000003BD0: BF8C3F70
	v_and_b32_e32 v15, 0xffff, v0                              // 000000003BD4: 361E00FF 0000FFFF
	v_lshlrev_b64 v[0:1], s16, v[15:16]                        // 000000003BDC: D6FF0000 02021E10
	v_or_b32_e32 v21, v0, v21                                  // 000000003BE4: 382A2B00
	v_or_b32_e32 v22, v1, v22                                  // 000000003BE8: 382C2D01
	s_cbranch_scc1 65522                                       // 000000003BEC: BF85FFF2 <__assert_fail+0x778>
	s_mov_b32 s14, 0                                           // 000000003BF0: BE8E0380
	s_branch 1                                                 // 000000003BF4: BF820001 <__assert_fail+0x7bc>
	s_mov_b32 s14, -1                                          // 000000003BF8: BE8E03C1
	s_and_b32 s14, s14, exec_lo                                // 000000003BFC: 870E7E0E
	s_cselect_b32 s14, 1, 0                                    // 000000003C00: 850E8081
	s_cmp_lg_u32 s14, 1                                        // 000000003C04: BF07810E
	s_mov_b32 s14, 0                                           // 000000003C08: BE8E0380
	s_cbranch_scc1 5                                           // 000000003C0C: BF850005 <__assert_fail+0x7e4>
	global_load_dwordx2 v[21:22], v16, s[4:5]                  // 000000003C10: DC348000 15040010
	s_add_i32 s14, s15, -8                                     // 000000003C18: 810EC80F
	s_add_u32 s4, s4, 8                                        // 000000003C1C: 80048804
	s_addc_u32 s5, s5, 0                                       // 000000003C20: 82058005
	s_cmp_gt_u32 s14, 7                                        // 000000003C24: BF08870E
	s_cbranch_scc1 21                                          // 000000003C28: BF850015 <__assert_fail+0x840>
	v_mov_b32_e32 v23, 0                                       // 000000003C2C: 7E2E0280
	v_mov_b32_e32 v24, 0                                       // 000000003C30: 7E300280
	s_cmp_eq_u32 s14, 0                                        // 000000003C34: BF06800E
	s_cbranch_scc1 15                                          // 000000003C38: BF85000F <__assert_fail+0x838>
	s_mov_b32 s15, 0                                           // 000000003C3C: BE8F0380
	v_mov_b32_e32 v0, s15                                      // 000000003C40: 7E00020F
	s_lshl_b32 s16, s15, 3                                     // 000000003C44: 8F10830F
	s_add_i32 s15, s15, 1                                      // 000000003C48: 810F810F
	s_cmp_lg_u32 s15, s14                                      // 000000003C4C: BF070E0F
	global_load_ubyte v0, v0, s[4:5]                           // 000000003C50: DC208000 00040000
	s_waitcnt vmcnt(0)                                         // 000000003C58: BF8C3F70
	v_and_b32_e32 v15, 0xffff, v0                              // 000000003C5C: 361E00FF 0000FFFF
	v_lshlrev_b64 v[0:1], s16, v[15:16]                        // 000000003C64: D6FF0000 02021E10
	v_or_b32_e32 v23, v0, v23                                  // 000000003C6C: 382E2F00
	v_or_b32_e32 v24, v1, v24                                  // 000000003C70: 38303101
	s_cbranch_scc1 65522                                       // 000000003C74: BF85FFF2 <__assert_fail+0x800>
	s_mov_b32 s15, 0                                           // 000000003C78: BE8F0380
	s_branch 1                                                 // 000000003C7C: BF820001 <__assert_fail+0x844>
	s_mov_b32 s15, -1                                          // 000000003C80: BE8F03C1
	s_and_b32 s15, s15, exec_lo                                // 000000003C84: 870F7E0F
	s_cselect_b32 s15, 1, 0                                    // 000000003C88: 850F8081
	s_cmp_lg_u32 s15, 1                                        // 000000003C8C: BF07810F
	s_mov_b32 s15, 0                                           // 000000003C90: BE8F0380
	s_cbranch_scc1 5                                           // 000000003C94: BF850005 <__assert_fail+0x86c>
	global_load_dwordx2 v[23:24], v16, s[4:5]                  // 000000003C98: DC348000 17040010
	s_add_i32 s15, s14, -8                                     // 000000003CA0: 810FC80E
	s_add_u32 s4, s4, 8                                        // 000000003CA4: 80048804
	s_addc_u32 s5, s5, 0                                       // 000000003CA8: 82058005
	s_cmp_gt_u32 s15, 7                                        // 000000003CAC: BF08870F
	s_cbranch_scc1 21                                          // 000000003CB0: BF850015 <__assert_fail+0x8c8>
	v_mov_b32_e32 v25, 0                                       // 000000003CB4: 7E320280
	v_mov_b32_e32 v26, 0                                       // 000000003CB8: 7E340280
	s_cmp_eq_u32 s15, 0                                        // 000000003CBC: BF06800F
	s_cbranch_scc1 15                                          // 000000003CC0: BF85000F <__assert_fail+0x8c0>
	s_mov_b32 s14, 0                                           // 000000003CC4: BE8E0380
	v_mov_b32_e32 v0, s14                                      // 000000003CC8: 7E00020E
	s_lshl_b32 s16, s14, 3                                     // 000000003CCC: 8F10830E
	s_add_i32 s14, s14, 1                                      // 000000003CD0: 810E810E
	s_cmp_lg_u32 s14, s15                                      // 000000003CD4: BF070F0E
	global_load_ubyte v0, v0, s[4:5]                           // 000000003CD8: DC208000 00040000
	s_waitcnt vmcnt(0)                                         // 000000003CE0: BF8C3F70
	v_and_b32_e32 v15, 0xffff, v0                              // 000000003CE4: 361E00FF 0000FFFF
	v_lshlrev_b64 v[0:1], s16, v[15:16]                        // 000000003CEC: D6FF0000 02021E10
	v_or_b32_e32 v25, v0, v25                                  // 000000003CF4: 38323300
	v_or_b32_e32 v26, v1, v26                                  // 000000003CF8: 38343501
	s_cbranch_scc1 65522                                       // 000000003CFC: BF85FFF2 <__assert_fail+0x888>
	s_mov_b32 s14, 0                                           // 000000003D00: BE8E0380
	s_branch 1                                                 // 000000003D04: BF820001 <__assert_fail+0x8cc>
	s_mov_b32 s14, -1                                          // 000000003D08: BE8E03C1
	s_and_b32 s14, s14, exec_lo                                // 000000003D0C: 870E7E0E
	s_cselect_b32 s14, 1, 0                                    // 000000003D10: 850E8081
	s_cmp_lg_u32 s14, 1                                        // 000000003D14: BF07810E
	s_mov_b32 s14, 0                                           // 000000003D18: BE8E0380
	s_cbranch_scc1 5                                           // 000000003D1C: BF850005 <__assert_fail+0x8f4>
	global_load_dwordx2 v[25:26], v16, s[4:5]                  // 000000003D20: DC348000 19040010
	s_add_i32 s14, s15, -8                                     // 000000003D28: 810EC80F
	s_add_u32 s4, s4, 8                                        // 000000003D2C: 80048804
	s_addc_u32 s5, s5, 0                                       // 000000003D30: 82058005
	s_cmp_gt_u32 s14, 7                                        // 000000003D34: BF08870E
	s_cbranch_scc1 21                                          // 000000003D38: BF850015 <__assert_fail+0x950>
	v_mov_b32_e32 v27, 0                                       // 000000003D3C: 7E360280
	v_mov_b32_e32 v28, 0                                       // 000000003D40: 7E380280
	s_cmp_eq_u32 s14, 0                                        // 000000003D44: BF06800E
	s_cbranch_scc1 15                                          // 000000003D48: BF85000F <__assert_fail+0x948>
	s_mov_b32 s15, 0                                           // 000000003D4C: BE8F0380
	v_mov_b32_e32 v0, s15                                      // 000000003D50: 7E00020F
	s_lshl_b32 s16, s15, 3                                     // 000000003D54: 8F10830F
	s_add_i32 s15, s15, 1                                      // 000000003D58: 810F810F
	s_cmp_lg_u32 s15, s14                                      // 000000003D5C: BF070E0F
	global_load_ubyte v0, v0, s[4:5]                           // 000000003D60: DC208000 00040000
	s_waitcnt vmcnt(0)                                         // 000000003D68: BF8C3F70
	v_and_b32_e32 v15, 0xffff, v0                              // 000000003D6C: 361E00FF 0000FFFF
	v_lshlrev_b64 v[0:1], s16, v[15:16]                        // 000000003D74: D6FF0000 02021E10
	v_or_b32_e32 v27, v0, v27                                  // 000000003D7C: 38363700
	v_or_b32_e32 v28, v1, v28                                  // 000000003D80: 38383901
	s_cbranch_scc1 65522                                       // 000000003D84: BF85FFF2 <__assert_fail+0x910>
	s_mov_b32 s15, 0                                           // 000000003D88: BE8F0380
	s_branch 1                                                 // 000000003D8C: BF820001 <__assert_fail+0x954>
	s_mov_b32 s15, -1                                          // 000000003D90: BE8F03C1
	s_and_b32 s15, s15, exec_lo                                // 000000003D94: 870F7E0F
	s_cselect_b32 s15, 1, 0                                    // 000000003D98: 850F8081
	s_mov_b32 s20, 0                                           // 000000003D9C: BE940380
	s_cmp_lg_u32 s15, 1                                        // 000000003DA0: BF07810F
	s_cbranch_scc1 5                                           // 000000003DA4: BF850005 <__assert_fail+0x97c>
	global_load_dwordx2 v[27:28], v16, s[4:5]                  // 000000003DA8: DC348000 1B040010
	s_add_i32 s20, s14, -8                                     // 000000003DB0: 8114C80E
	s_add_u32 s4, s4, 8                                        // 000000003DB4: 80048804
	s_addc_u32 s5, s5, 0                                       // 000000003DB8: 82058005
	s_cmp_gt_u32 s20, 7                                        // 000000003DBC: BF088714
	s_cbranch_scc1 24                                          // 000000003DC0: BF850018 <__assert_fail+0x9e4>
	v_mov_b32_e32 v29, 0                                       // 000000003DC4: 7E3A0280
	v_mov_b32_e32 v30, 0                                       // 000000003DC8: 7E3C0280
	s_cmp_eq_u32 s20, 0                                        // 000000003DCC: BF068014
	s_cbranch_scc1 18                                          // 000000003DD0: BF850012 <__assert_fail+0x9dc>
	s_mov_b64 s[14:15], 0                                      // 000000003DD4: BE8E0480
	s_mov_b64 s[16:17], s[4:5]                                 // 000000003DD8: BE900404
	global_load_ubyte v0, v16, s[16:17]                        // 000000003DDC: DC208000 00100010
	s_add_i32 s20, s20, -1                                     // 000000003DE4: 8114C114
	s_waitcnt vmcnt(0)                                         // 000000003DE8: BF8C3F70
	v_and_b32_e32 v15, 0xffff, v0                              // 000000003DEC: 361E00FF 0000FFFF
	v_lshlrev_b64 v[0:1], s14, v[15:16]                        // 000000003DF4: D6FF0000 02021E0E
	s_add_u32 s14, s14, 8                                      // 000000003DFC: 800E880E
	s_addc_u32 s15, s15, 0                                     // 000000003E00: 820F800F
	s_add_u32 s16, s16, 1                                      // 000000003E04: 80108110
	s_addc_u32 s17, s17, 0                                     // 000000003E08: 82118011
	s_cmp_lg_u32 s20, 0                                        // 000000003E0C: BF078014
	v_or_b32_e32 v29, v0, v29                                  // 000000003E10: 383A3B00
	v_or_b32_e32 v30, v1, v30                                  // 000000003E14: 383C3D01
	s_cbranch_scc1 65520                                       // 000000003E18: BF85FFF0 <__assert_fail+0x99c>
	s_mov_b32 s14, 0                                           // 000000003E1C: BE8E0380
	s_branch 1                                                 // 000000003E20: BF820001 <__assert_fail+0x9e8>
	s_mov_b32 s14, -1                                          // 000000003E24: BE8E03C1
	s_and_b32 s14, s14, exec_lo                                // 000000003E28: 870E7E0E
	s_cselect_b32 s14, 1, 0                                    // 000000003E2C: 850E8081
	s_cmp_lg_u32 s14, 1                                        // 000000003E30: BF07810E
	s_cbranch_scc1 2                                           // 000000003E34: BF850002 <__assert_fail+0xa00>
	global_load_dwordx2 v[29:30], v16, s[4:5]                  // 000000003E38: DC348000 1D040010
	v_readfirstlane_b32 s4, v36                                // 000000003E40: 7E080524
	v_mov_b32_e32 v0, 0                                        // 000000003E44: 7E000280
	v_mov_b32_e32 v1, 0                                        // 000000003E48: 7E020280
	v_cmp_eq_u32_e64 s4, s4, v36                               // 000000003E4C: D4C20004 02024804
	s_and_saveexec_b32 s5, s4                                  // 000000003E54: BE853C04
	s_cbranch_execz 73                                         // 000000003E58: BF880049 <__assert_fail+0xb40>
	global_load_dwordx2 v[33:34], v16, s[6:7] offset:24 glc dlc// 000000003E5C: DC359018 21060010
	s_waitcnt vmcnt(0)                                         // 000000003E64: BF8C3F70
	buffer_gl1_inv                                             // 000000003E68: E1C80000 00000000
	buffer_gl0_inv                                             // 000000003E70: E1C40000 00000000
	s_clause 0x1                                               // 000000003E78: BFA10001
	global_load_dwordx2 v[0:1], v16, s[6:7] offset:40          // 000000003E7C: DC348028 00060010
	global_load_dwordx2 v[31:32], v16, s[6:7]                  // 000000003E84: DC348000 1F060010
	s_mov_b32 s14, exec_lo                                     // 000000003E8C: BE8E037E
	s_waitcnt vmcnt(1)                                         // 000000003E90: BF8C3F71
	v_and_b32_e32 v1, v1, v34                                  // 000000003E94: 36024501
	v_and_b32_e32 v0, v0, v33                                  // 000000003E98: 36004300
	v_mul_lo_u32 v1, v1, 24                                    // 000000003E9C: D5690001 02013101
	v_mul_hi_u32 v15, v0, 24                                   // 000000003EA4: D56A000F 02013100
	v_mul_lo_u32 v0, v0, 24                                    // 000000003EAC: D5690000 02013100
	v_add_nc_u32_e32 v1, v15, v1                               // 000000003EB4: 4A02030F
	s_waitcnt vmcnt(0)                                         // 000000003EB8: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v31, v0                           // 000000003EBC: D70F6A00 0202011F
	v_add_co_ci_u32_e64 v1, null, v32, v1, vcc_lo              // 000000003EC4: D5287D01 01AA0320
	global_load_dwordx2 v[31:32], v[0:1], off glc dlc          // 000000003ECC: DC359000 1F7D0000
	s_waitcnt vmcnt(0)                                         // 000000003ED4: BF8C3F70
	global_atomic_cmpswap_x2 v[0:1], v16, v[31:34], s[6:7] offset:24 glc// 000000003ED8: DD458018 00061F10
	s_waitcnt vmcnt(0)                                         // 000000003EE0: BF8C3F70
	buffer_gl1_inv                                             // 000000003EE4: E1C80000 00000000
	buffer_gl0_inv                                             // 000000003EEC: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[0:1], v[33:34]                         // 000000003EF4: 7DEA4300
	s_cbranch_execz 32                                         // 000000003EF8: BF880020 <__assert_fail+0xb3c>
	s_mov_b32 s15, 0                                           // 000000003EFC: BE8F0380
	s_sleep 1                                                  // 000000003F00: BF8E0001
	s_clause 0x1                                               // 000000003F04: BFA10001
	global_load_dwordx2 v[31:32], v16, s[6:7] offset:40        // 000000003F08: DC348028 1F060010
	global_load_dwordx2 v[38:39], v16, s[6:7]                  // 000000003F10: DC348000 26060010
	v_mov_b32_e32 v33, v0                                      // 000000003F18: 7E420300
	v_mov_b32_e32 v34, v1                                      // 000000003F1C: 7E440301
	s_waitcnt vmcnt(1)                                         // 000000003F20: BF8C3F71
	v_and_b32_e32 v0, v31, v33                                 // 000000003F24: 3600431F
	s_waitcnt vmcnt(0)                                         // 000000003F28: BF8C3F70
	v_mad_u64_u32 v[48:49], null, v0, 24, v[38:39]             // 000000003F2C: D5767D30 04993100
	v_and_b32_e32 v0, v32, v34                                 // 000000003F34: 36004520
	v_mad_u64_u32 v[49:50], null, v0, 24, v[49:50]             // 000000003F38: D5767D31 04C53100
	global_load_dwordx2 v[31:32], v[48:49], off glc dlc        // 000000003F40: DC359000 1F7D0030
	s_waitcnt vmcnt(0)                                         // 000000003F48: BF8C3F70
	global_atomic_cmpswap_x2 v[0:1], v16, v[31:34], s[6:7] offset:24 glc// 000000003F4C: DD458018 00061F10
	s_waitcnt vmcnt(0)                                         // 000000003F54: BF8C3F70
	buffer_gl1_inv                                             // 000000003F58: E1C80000 00000000
	buffer_gl0_inv                                             // 000000003F60: E1C40000 00000000
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[33:34]                  // 000000003F68: 7DC44300
	s_or_b32 s15, vcc_lo, s15                                  // 000000003F6C: 880F0F6A
	s_andn2_b32 exec_lo, exec_lo, s15                          // 000000003F70: 8A7E0F7E
	s_cbranch_execnz 65506                                     // 000000003F74: BF89FFE2 <__assert_fail+0xac0>
	s_or_b32 exec_lo, exec_lo, s15                             // 000000003F78: 887E0F7E
	s_or_b32 exec_lo, exec_lo, s14                             // 000000003F7C: 887E0E7E
	s_or_b32 exec_lo, exec_lo, s5                              // 000000003F80: 887E057E
	s_clause 0x1                                               // 000000003F84: BFA10001
	global_load_dwordx2 v[38:39], v16, s[6:7] offset:40        // 000000003F88: DC348028 26060010
	global_load_dwordx4 v[31:34], v16, s[6:7]                  // 000000003F90: DC388000 1F060010
	v_readfirstlane_b32 s15, v1                                // 000000003F98: 7E1E0501
	v_readfirstlane_b32 s14, v0                                // 000000003F9C: 7E1C0500
	s_mov_b32 s5, exec_lo                                      // 000000003FA0: BE85037E
	s_waitcnt vmcnt(1)                                         // 000000003FA4: BF8C3F71
	v_readfirstlane_b32 s16, v38                               // 000000003FA8: 7E200526
	v_readfirstlane_b32 s17, v39                               // 000000003FAC: 7E220527
	s_and_b64 s[16:17], s[16:17], s[14:15]                     // 000000003FB0: 87900E10
	s_mul_i32 s20, s17, 24                                     // 000000003FB4: 93149811
	s_mul_hi_u32 s21, s16, 24                                  // 000000003FB8: 9A959810
	s_mul_i32 s22, s16, 24                                     // 000000003FBC: 93169810
	s_add_i32 s21, s21, s20                                    // 000000003FC0: 81151415
	s_waitcnt vmcnt(0)                                         // 000000003FC4: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v31, s22                          // 000000003FC8: D70F6A00 02002D1F
	v_add_co_ci_u32_e64 v1, null, s21, v32, vcc_lo             // 000000003FD0: D5287D01 01AA4015
	s_and_saveexec_b32 s20, s4                                 // 000000003FD8: BE943C04
	s_cbranch_execz 3                                          // 000000003FDC: BF880003 <__assert_fail+0xbac>
	v_mov_b32_e32 v15, s5                                      // 000000003FE0: 7E1E0205
	global_store_dwordx4 v[0:1], v[15:18], off offset:8        // 000000003FE4: DC788008 007D0F00
	s_or_b32 exec_lo, exec_lo, s20                             // 000000003FEC: 887E147E
	v_cmp_lt_u64_e64 vcc_lo, s[12:13], 57                      // 000000003FF0: D4E1006A 0201720C
	s_lshl_b64 s[16:17], s[16:17], 12                          // 000000003FF8: 8F908C10
	s_lshl2_add_u32 s5, s19, 28                                // 000000003FFC: 97859C13
	v_and_b32_e32 v9, 0xffffff1f, v9                           // 000000004000: 361212FF FFFFFF1F
	v_cndmask_b32_e32 v15, 0, v37, vcc_lo                      // 000000004008: 021E4A80
	v_add_co_u32 v33, vcc_lo, v33, s16                         // 00000000400C: D70F6A21 02002121
	v_add_co_ci_u32_e64 v34, null, s17, v34, vcc_lo            // 000000004014: D5287D22 01AA4411
	v_and_or_b32 v15, 0x1e0, s5, v15                           // 00000000401C: D771000F 043C0AFF 000001E0
	v_readfirstlane_b32 s16, v33                               // 000000004028: 7E200521
	v_add_co_u32 v33, vcc_lo, v33, v35                         // 00000000402C: D70F6A21 02024721
	v_readfirstlane_b32 s17, v34                               // 000000004034: 7E220522
	v_or_b32_e32 v9, v15, v9                                   // 000000004038: 3812130F
	v_add_co_ci_u32_e64 v34, null, 0, v34, vcc_lo              // 00000000403C: D5287D22 01AA4480
	global_store_dwordx4 v35, v[9:12], s[16:17]                // 000000004044: DC788000 00100923
	global_store_dwordx4 v35, v[19:22], s[16:17] offset:16     // 00000000404C: DC788010 00101323
	global_store_dwordx4 v35, v[23:26], s[16:17] offset:32     // 000000004054: DC788020 00101723
	global_store_dwordx4 v35, v[27:30], s[16:17] offset:48     // 00000000405C: DC788030 00101B23
	s_and_saveexec_b32 s5, s4                                  // 000000004064: BE853C04
	s_cbranch_execz 75                                         // 000000004068: BF88004B <__assert_fail+0xd58>
	s_clause 0x1                                               // 00000000406C: BFA10001
	global_load_dwordx2 v[23:24], v16, s[6:7] offset:32 glc dlc// 000000004070: DC359020 17060010
	global_load_dwordx2 v[9:10], v16, s[6:7] offset:40         // 000000004078: DC348028 09060010
	v_mov_b32_e32 v21, s14                                     // 000000004080: 7E2A020E
	v_mov_b32_e32 v22, s15                                     // 000000004084: 7E2C020F
	s_waitcnt vmcnt(0)                                         // 000000004088: BF8C3F70
	v_readfirstlane_b32 s16, v9                                // 00000000408C: 7E200509
	v_readfirstlane_b32 s17, v10                               // 000000004090: 7E22050A
	s_and_b64 s[16:17], s[16:17], s[14:15]                     // 000000004094: 87900E10
	s_mul_i32 s17, s17, 24                                     // 000000004098: 93119811
	s_mul_hi_u32 s20, s16, 24                                  // 00000000409C: 9A949810
	s_mul_i32 s16, s16, 24                                     // 0000000040A0: 93109810
	s_add_i32 s20, s20, s17                                    // 0000000040A4: 81141114
	v_add_co_u32 v19, vcc_lo, v31, s16                         // 0000000040A8: D70F6A13 0200211F
	v_add_co_ci_u32_e64 v20, null, s20, v32, vcc_lo            // 0000000040B0: D5287D14 01AA4014
	s_mov_b32 s16, exec_lo                                     // 0000000040B8: BE90037E
	global_store_dwordx2 v[19:20], v[23:24], off               // 0000000040BC: DC748000 007D1713
	s_waitcnt_vscnt null, 0x0                                  // 0000000040C4: BBFD0000
	global_atomic_cmpswap_x2 v[11:12], v16, v[21:24], s[6:7] offset:32 glc// 0000000040C8: DD458020 0B061510
	s_waitcnt vmcnt(0)                                         // 0000000040D0: BF8C3F70
	v_cmpx_ne_u64_e32 v[11:12], v[23:24]                       // 0000000040D4: 7DEA2F0B
	s_cbranch_execz 16                                         // 0000000040D8: BF880010 <__assert_fail+0xcdc>
	s_mov_b32 s17, 0                                           // 0000000040DC: BE910380
	v_mov_b32_e32 v9, s14                                      // 0000000040E0: 7E12020E
	v_mov_b32_e32 v10, s15                                     // 0000000040E4: 7E14020F
	s_sleep 1                                                  // 0000000040E8: BF8E0001
	global_store_dwordx2 v[19:20], v[11:12], off               // 0000000040EC: DC748000 007D0B13
	s_waitcnt_vscnt null, 0x0                                  // 0000000040F4: BBFD0000
	global_atomic_cmpswap_x2 v[9:10], v16, v[9:12], s[6:7] offset:32 glc// 0000000040F8: DD458020 09060910
	s_waitcnt vmcnt(0)                                         // 000000004100: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[9:10], v[11:12]                 // 000000004104: 7DC41709
	v_mov_b32_e32 v12, v10                                     // 000000004108: 7E18030A
	v_mov_b32_e32 v11, v9                                      // 00000000410C: 7E160309
	s_or_b32 s17, vcc_lo, s17                                  // 000000004110: 8811116A
	s_andn2_b32 exec_lo, exec_lo, s17                          // 000000004114: 8A7E117E
	s_cbranch_execnz 65521                                     // 000000004118: BF89FFF1 <__assert_fail+0xca0>
	s_or_b32 exec_lo, exec_lo, s16                             // 00000000411C: 887E107E
	global_load_dwordx2 v[9:10], v16, s[6:7] offset:16         // 000000004120: DC348010 09060010
	s_mov_b32 s17, exec_lo                                     // 000000004128: BE91037E
	s_mov_b32 s16, exec_lo                                     // 00000000412C: BE90037E
	v_mbcnt_lo_u32_b32 v11, s17, 0                             // 000000004130: D765000B 02010011
	v_cmpx_eq_u32_e32 0, v11                                   // 000000004138: 7DA41680
	s_cbranch_execz 5                                          // 00000000413C: BF880005 <__assert_fail+0xd14>
	s_bcnt1_i32_b32 s17, s17                                   // 000000004140: BE910F11
	v_mov_b32_e32 v15, s17                                     // 000000004144: 7E1E0211
	s_waitcnt vmcnt(0)                                         // 000000004148: BF8C3F70
	global_atomic_add_x2 v[9:10], v[15:16], off offset:8       // 00000000414C: DD488008 007D0F09
	s_or_b32 exec_lo, exec_lo, s16                             // 000000004154: 887E107E
	s_waitcnt vmcnt(0)                                         // 000000004158: BF8C3F70
	global_load_dwordx2 v[11:12], v[9:10], off offset:16       // 00000000415C: DC348010 0B7D0009
	s_waitcnt vmcnt(0)                                         // 000000004164: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[11:12]                       // 000000004168: 7DC41680
	s_cbranch_vccnz 10                                         // 00000000416C: BF87000A <__assert_fail+0xd58>
	global_load_dword v15, v[9:10], off offset:24              // 000000004170: DC308018 0F7D0009
	s_waitcnt vmcnt(0)                                         // 000000004178: BF8C3F70
	v_readfirstlane_b32 s16, v15                               // 00000000417C: 7E20050F
	s_waitcnt_vscnt null, 0x0                                  // 000000004180: BBFD0000
	global_store_dwordx2 v[11:12], v[15:16], off               // 000000004184: DC748000 007D0F0B
	s_and_b32 m0, s16, 0x7fffff                                // 00000000418C: 877CFF10 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 000000004194: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 000000004198: 887E057E
	s_branch 18                                                // 00000000419C: BF820012 <__assert_fail+0xda8>
	s_nop 0                                                    // 0000000041A0: BF800000
	s_nop 0                                                    // 0000000041A4: BF800000
	s_nop 0                                                    // 0000000041A8: BF800000
	s_nop 0                                                    // 0000000041AC: BF800000
	s_nop 0                                                    // 0000000041B0: BF800000
	s_nop 0                                                    // 0000000041B4: BF800000
	s_nop 0                                                    // 0000000041B8: BF800000
	s_nop 0                                                    // 0000000041BC: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000041C0: 887E057E
	v_readfirstlane_b32 s5, v9                                 // 0000000041C4: 7E0A0509
	s_cmp_eq_u32 s5, 0                                         // 0000000041C8: BF068005
	s_cbranch_scc1 28                                          // 0000000041CC: BF85001C <__assert_fail+0xe00>
	s_mov_b32 s5, 0                                            // 0000000041D0: BE850380
	s_sleep 1                                                  // 0000000041D4: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 0000000041D8: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 0000000041DC: 85058081
	s_cmp_lg_u32 s5, 1                                         // 0000000041E0: BF078105
	s_cbranch_scc0 24                                          // 0000000041E4: BF840018 <__assert_fail+0xe08>
	v_mov_b32_e32 v9, 1                                        // 0000000041E8: 7E120281
	s_and_saveexec_b32 s5, s4                                  // 0000000041EC: BE853C04
	s_cbranch_execz 65523                                      // 0000000041F0: BF88FFF3 <__assert_fail+0xd80>
	global_load_dword v9, v[0:1], off offset:20 glc dlc        // 0000000041F4: DC319014 097D0000
	s_waitcnt vmcnt(0)                                         // 0000000041FC: BF8C3F70
	buffer_gl1_inv                                             // 000000004200: E1C80000 00000000
	buffer_gl0_inv                                             // 000000004208: E1C40000 00000000
	v_and_b32_e32 v9, 1, v9                                    // 000000004210: 36121281
	s_branch 65514                                             // 000000004214: BF82FFEA <__assert_fail+0xd80>
	s_nop 0                                                    // 000000004218: BF800000
	s_nop 0                                                    // 00000000421C: BF800000
	s_nop 0                                                    // 000000004220: BF800000
	s_nop 0                                                    // 000000004224: BF800000
	s_nop 0                                                    // 000000004228: BF800000
	s_nop 0                                                    // 00000000422C: BF800000
	s_nop 0                                                    // 000000004230: BF800000
	s_nop 0                                                    // 000000004234: BF800000
	s_nop 0                                                    // 000000004238: BF800000
	s_nop 0                                                    // 00000000423C: BF800000
	s_mov_b32 s5, -1                                           // 000000004240: BE8503C1
	s_branch 65508                                             // 000000004244: BF82FFE4 <__assert_fail+0xd98>
	global_load_dwordx4 v[9:12], v[33:34], off                 // 000000004248: DC388000 097D0021
	s_and_saveexec_b32 s16, s4                                 // 000000004250: BE903C04
	s_cbranch_execz 65022                                      // 000000004254: BF88FDFE <__assert_fail+0x610>
	s_clause 0x2                                               // 000000004258: BFA10002
	global_load_dwordx2 v[0:1], v16, s[6:7] offset:40          // 00000000425C: DC348028 00060010
	global_load_dwordx2 v[23:24], v16, s[6:7] offset:24 glc dlc// 000000004264: DC359018 17060010
	global_load_dwordx2 v[11:12], v16, s[6:7]                  // 00000000426C: DC348000 0B060010
	s_waitcnt vmcnt(2)                                         // 000000004274: BF8C3F72
	v_readfirstlane_b32 s20, v0                                // 000000004278: 7E280500
	v_readfirstlane_b32 s21, v1                                // 00000000427C: 7E2A0501
	s_add_u32 s17, s20, 1                                      // 000000004280: 80118114
	s_addc_u32 s22, s21, 0                                     // 000000004284: 82168015
	s_add_u32 s4, s17, s14                                     // 000000004288: 80040E11
	s_addc_u32 s5, s22, s15                                    // 00000000428C: 82050F16
	s_cmp_eq_u64 s[4:5], 0                                     // 000000004290: BF128004
	s_cselect_b32 s5, s22, s5                                  // 000000004294: 85050516
	s_cselect_b32 s4, s17, s4                                  // 000000004298: 85040411
	v_mov_b32_e32 v22, s5                                      // 00000000429C: 7E2C0205
	s_and_b64 s[14:15], s[4:5], s[20:21]                       // 0000000042A0: 878E1404
	v_mov_b32_e32 v21, s4                                      // 0000000042A4: 7E2A0204
	s_mul_i32 s15, s15, 24                                     // 0000000042A8: 930F980F
	s_mul_hi_u32 s17, s14, 24                                  // 0000000042AC: 9A91980E
	s_mul_i32 s14, s14, 24                                     // 0000000042B0: 930E980E
	s_add_i32 s17, s17, s15                                    // 0000000042B4: 81110F11
	s_waitcnt vmcnt(0)                                         // 0000000042B8: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v11, s14                          // 0000000042BC: D70F6A00 02001D0B
	v_add_co_ci_u32_e64 v1, null, s17, v12, vcc_lo             // 0000000042C4: D5287D01 01AA1811
	global_store_dwordx2 v[0:1], v[23:24], off                 // 0000000042CC: DC748000 007D1700
	s_waitcnt_vscnt null, 0x0                                  // 0000000042D4: BBFD0000
	global_atomic_cmpswap_x2 v[21:22], v16, v[21:24], s[6:7] offset:24 glc// 0000000042D8: DD458018 15061510
	s_waitcnt vmcnt(0)                                         // 0000000042E0: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[21:22], v[23:24]                // 0000000042E4: 7DCA2F15
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 0000000042E8: 877E6A7E
	s_cbranch_execz 64984                                      // 0000000042EC: BF88FDD8 <__assert_fail+0x610>
	s_mov_b32 s14, 0                                           // 0000000042F0: BE8E0380
	v_mov_b32_e32 v19, s4                                      // 0000000042F4: 7E260204
	v_mov_b32_e32 v20, s5                                      // 0000000042F8: 7E280205
	s_sleep 1                                                  // 0000000042FC: BF8E0001
	global_store_dwordx2 v[0:1], v[21:22], off                 // 000000004300: DC748000 007D1500
	s_waitcnt_vscnt null, 0x0                                  // 000000004308: BBFD0000
	global_atomic_cmpswap_x2 v[11:12], v16, v[19:22], s[6:7] offset:24 glc// 00000000430C: DD458018 0B061310
	s_waitcnt vmcnt(0)                                         // 000000004314: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[11:12], v[21:22]                // 000000004318: 7DC42B0B
	v_mov_b32_e32 v22, v12                                     // 00000000431C: 7E2C030C
	v_mov_b32_e32 v21, v11                                     // 000000004320: 7E2A030B
	s_or_b32 s14, vcc_lo, s14                                  // 000000004324: 880E0E6A
	s_andn2_b32 exec_lo, exec_lo, s14                          // 000000004328: 8A7E0E7E
	s_cbranch_execnz 65521                                     // 00000000432C: BF89FFF1 <__assert_fail+0xeb4>
	s_branch 64967                                             // 000000004330: BF82FDC7 <__assert_fail+0x610>
	s_cbranch_execnz 2                                         // 000000004334: BF890002 <__assert_fail+0xf00>
	s_branch 351                                               // 000000004338: BF82015F <__assert_fail+0x1478>
	s_branch 350                                               // 00000000433C: BF82015E <__assert_fail+0x1478>
	v_readfirstlane_b32 s4, v36                                // 000000004340: 7E080524
	v_mov_b32_e32 v0, 0                                        // 000000004344: 7E000280
	v_mov_b32_e32 v1, 0                                        // 000000004348: 7E020280
	v_cmp_eq_u32_e64 s4, s4, v36                               // 00000000434C: D4C20004 02024804
	s_and_saveexec_b32 s5, s4                                  // 000000004354: BE853C04
	s_cbranch_execz 89                                         // 000000004358: BF880059 <__assert_fail+0x1080>
	s_waitcnt vmcnt(0)                                         // 00000000435C: BF8C3F70
	v_mov_b32_e32 v9, 0                                        // 000000004360: 7E120280
	s_mov_b32 s10, exec_lo                                     // 000000004364: BE8A037E
	global_load_dwordx2 v[17:18], v9, s[6:7] offset:24 glc dlc // 000000004368: DC359018 11060009
	s_waitcnt vmcnt(0)                                         // 000000004370: BF8C3F70
	buffer_gl1_inv                                             // 000000004374: E1C80000 00000000
	buffer_gl0_inv                                             // 00000000437C: E1C40000 00000000
	s_clause 0x1                                               // 000000004384: BFA10001
	global_load_dwordx2 v[0:1], v9, s[6:7] offset:40           // 000000004388: DC348028 00060009
	global_load_dwordx2 v[10:11], v9, s[6:7]                   // 000000004390: DC348000 0A060009
	s_waitcnt vmcnt(1)                                         // 000000004398: BF8C3F71
	v_and_b32_e32 v1, v1, v18                                  // 00000000439C: 36022501
	v_and_b32_e32 v0, v0, v17                                  // 0000000043A0: 36002300
	v_mul_lo_u32 v1, v1, 24                                    // 0000000043A4: D5690001 02013101
	v_mul_hi_u32 v12, v0, 24                                   // 0000000043AC: D56A000C 02013100
	v_mul_lo_u32 v0, v0, 24                                    // 0000000043B4: D5690000 02013100
	v_add_nc_u32_e32 v1, v12, v1                               // 0000000043BC: 4A02030C
	s_waitcnt vmcnt(0)                                         // 0000000043C0: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v10, v0                           // 0000000043C4: D70F6A00 0202010A
	v_add_co_ci_u32_e64 v1, null, v11, v1, vcc_lo              // 0000000043CC: D5287D01 01AA030B
	global_load_dwordx2 v[15:16], v[0:1], off glc dlc          // 0000000043D4: DC359000 0F7D0000
	s_waitcnt vmcnt(0)                                         // 0000000043DC: BF8C3F70
	global_atomic_cmpswap_x2 v[0:1], v9, v[15:18], s[6:7] offset:24 glc// 0000000043E0: DD458018 00060F09
	s_waitcnt vmcnt(0)                                         // 0000000043E8: BF8C3F70
	buffer_gl1_inv                                             // 0000000043EC: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000043F4: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[0:1], v[17:18]                         // 0000000043FC: 7DEA2300
	s_cbranch_execz 46                                         // 000000004400: BF88002E <__assert_fail+0x107c>
	s_mov_b32 s11, 0                                           // 000000004404: BE8B0380
	s_nop 0                                                    // 000000004408: BF800000
	s_nop 0                                                    // 00000000440C: BF800000
	s_nop 0                                                    // 000000004410: BF800000
	s_nop 0                                                    // 000000004414: BF800000
	s_nop 0                                                    // 000000004418: BF800000
	s_nop 0                                                    // 00000000441C: BF800000
	s_nop 0                                                    // 000000004420: BF800000
	s_nop 0                                                    // 000000004424: BF800000
	s_nop 0                                                    // 000000004428: BF800000
	s_nop 0                                                    // 00000000442C: BF800000
	s_nop 0                                                    // 000000004430: BF800000
	s_nop 0                                                    // 000000004434: BF800000
	s_nop 0                                                    // 000000004438: BF800000
	s_nop 0                                                    // 00000000443C: BF800000
	s_sleep 1                                                  // 000000004440: BF8E0001
	s_clause 0x1                                               // 000000004444: BFA10001
	global_load_dwordx2 v[11:12], v9, s[6:7] offset:40         // 000000004448: DC348028 0B060009
	global_load_dwordx2 v[15:16], v9, s[6:7]                   // 000000004450: DC348000 0F060009
	v_mov_b32_e32 v17, v0                                      // 000000004458: 7E220300
	v_mov_b32_e32 v18, v1                                      // 00000000445C: 7E240301
	s_waitcnt vmcnt(1)                                         // 000000004460: BF8C3F71
	v_and_b32_e32 v0, v11, v17                                 // 000000004464: 3600230B
	s_waitcnt vmcnt(0)                                         // 000000004468: BF8C3F70
	v_mad_u64_u32 v[10:11], null, v0, 24, v[15:16]             // 00000000446C: D5767D0A 043D3100
	v_and_b32_e32 v0, v12, v18                                 // 000000004474: 3600250C
	v_mad_u64_u32 v[11:12], null, v0, 24, v[11:12]             // 000000004478: D5767D0B 042D3100
	global_load_dwordx2 v[15:16], v[10:11], off glc dlc        // 000000004480: DC359000 0F7D000A
	s_waitcnt vmcnt(0)                                         // 000000004488: BF8C3F70
	global_atomic_cmpswap_x2 v[0:1], v9, v[15:18], s[6:7] offset:24 glc// 00000000448C: DD458018 00060F09
	s_waitcnt vmcnt(0)                                         // 000000004494: BF8C3F70
	buffer_gl1_inv                                             // 000000004498: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000044A0: E1C40000 00000000
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[17:18]                  // 0000000044A8: 7DC42300
	s_or_b32 s11, vcc_lo, s11                                  // 0000000044AC: 880B0B6A
	s_andn2_b32 exec_lo, exec_lo, s11                          // 0000000044B0: 8A7E0B7E
	s_cbranch_execnz 65506                                     // 0000000044B4: BF89FFE2 <__assert_fail+0x1000>
	s_or_b32 exec_lo, exec_lo, s11                             // 0000000044B8: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 0000000044BC: 887E0A7E
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000044C0: 887E057E
	v_mov_b32_e32 v16, 0                                       // 0000000044C4: 7E200280
	v_readfirstlane_b32 s11, v1                                // 0000000044C8: 7E160501
	v_readfirstlane_b32 s10, v0                                // 0000000044CC: 7E140500
	s_mov_b32 s5, exec_lo                                      // 0000000044D0: BE85037E
	s_clause 0x1                                               // 0000000044D4: BFA10001
	global_load_dwordx2 v[17:18], v16, s[6:7] offset:40        // 0000000044D8: DC348028 11060010
	global_load_dwordx4 v[9:12], v16, s[6:7]                   // 0000000044E0: DC388000 09060010
	s_waitcnt vmcnt(1)                                         // 0000000044E8: BF8C3F71
	v_readfirstlane_b32 s12, v17                               // 0000000044EC: 7E180511
	v_readfirstlane_b32 s13, v18                               // 0000000044F0: 7E1A0512
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 0000000044F4: 878C0A0C
	s_mul_i32 s14, s13, 24                                     // 0000000044F8: 930E980D
	s_mul_hi_u32 s15, s12, 24                                  // 0000000044FC: 9A8F980C
	s_mul_i32 s16, s12, 24                                     // 000000004500: 9310980C
	s_add_i32 s15, s15, s14                                    // 000000004504: 810F0E0F
	s_waitcnt vmcnt(0)                                         // 000000004508: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v9, s16                           // 00000000450C: D70F6A00 02002109
	v_add_co_ci_u32_e64 v1, null, s15, v10, vcc_lo             // 000000004514: D5287D01 01AA140F
	s_and_saveexec_b32 s14, s4                                 // 00000000451C: BE8E3C04
	s_cbranch_execz 5                                          // 000000004520: BF880005 <__assert_fail+0x10f8>
	v_mov_b32_e32 v15, s5                                      // 000000004524: 7E1E0205
	v_mov_b32_e32 v17, 2                                       // 000000004528: 7E220282
	v_mov_b32_e32 v18, 1                                       // 00000000452C: 7E240281
	global_store_dwordx4 v[0:1], v[15:18], off offset:8        // 000000004530: DC788008 007D0F00
	s_or_b32 exec_lo, exec_lo, s14                             // 000000004538: 887E0E7E
	s_lshl_b64 s[12:13], s[12:13], 12                          // 00000000453C: 8F8C8C0C
	v_and_or_b32 v13, 0xffffff1f, v13, 32                      // 000000004540: D771000D 02821AFF FFFFFF1F
	v_add_co_u32 v11, vcc_lo, v11, s12                         // 00000000454C: D70F6A0B 0200190B
	v_add_co_ci_u32_e64 v12, null, s13, v12, vcc_lo            // 000000004554: D5287D0C 01AA180D
	s_mov_b32 s12, 0                                           // 00000000455C: BE8C0380
	v_add_co_u32 v17, vcc_lo, v11, v35                         // 000000004560: D70F6A11 0202470B
	s_mov_b32 s13, s12                                         // 000000004568: BE8D030C
	s_mov_b32 s14, s12                                         // 00000000456C: BE8E030C
	s_mov_b32 s15, s12                                         // 000000004570: BE8F030C
	v_mov_b32_e32 v15, s12                                     // 000000004574: 7E1E020C
	v_mov_b32_e32 v16, s12                                     // 000000004578: 7E20020C
	v_readfirstlane_b32 s16, v11                               // 00000000457C: 7E20050B
	v_readfirstlane_b32 s17, v12                               // 000000004580: 7E22050C
	v_add_co_ci_u32_e64 v18, null, 0, v12, vcc_lo              // 000000004584: D5287D12 01AA1880
	v_mov_b32_e32 v22, s15                                     // 00000000458C: 7E2C020F
	v_mov_b32_e32 v21, s14                                     // 000000004590: 7E2A020E
	v_mov_b32_e32 v20, s13                                     // 000000004594: 7E28020D
	v_mov_b32_e32 v19, s12                                     // 000000004598: 7E26020C
	global_store_dwordx4 v35, v[13:16], s[16:17]               // 00000000459C: DC788000 00100D23
	global_store_dwordx4 v35, v[19:22], s[16:17] offset:16     // 0000000045A4: DC788010 00101323
	global_store_dwordx4 v35, v[19:22], s[16:17] offset:32     // 0000000045AC: DC788020 00101323
	global_store_dwordx4 v35, v[19:22], s[16:17] offset:48     // 0000000045B4: DC788030 00101323
	s_and_saveexec_b32 s5, s4                                  // 0000000045BC: BE853C04
	s_cbranch_execz 78                                         // 0000000045C0: BF88004E <__assert_fail+0x12bc>
	v_mov_b32_e32 v15, 0                                       // 0000000045C4: 7E1E0280
	v_mov_b32_e32 v19, s10                                     // 0000000045C8: 7E26020A
	v_mov_b32_e32 v20, s11                                     // 0000000045CC: 7E28020B
	s_clause 0x1                                               // 0000000045D0: BFA10001
	global_load_dwordx2 v[21:22], v15, s[6:7] offset:32 glc dlc// 0000000045D4: DC359020 1506000F
	global_load_dwordx2 v[11:12], v15, s[6:7] offset:40        // 0000000045DC: DC348028 0B06000F
	s_waitcnt vmcnt(0)                                         // 0000000045E4: BF8C3F70
	v_readfirstlane_b32 s12, v11                               // 0000000045E8: 7E18050B
	v_readfirstlane_b32 s13, v12                               // 0000000045EC: 7E1A050C
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 0000000045F0: 878C0A0C
	s_mul_i32 s13, s13, 24                                     // 0000000045F4: 930D980D
	s_mul_hi_u32 s14, s12, 24                                  // 0000000045F8: 9A8E980C
	s_mul_i32 s12, s12, 24                                     // 0000000045FC: 930C980C
	s_add_i32 s14, s14, s13                                    // 000000004600: 810E0D0E
	v_add_co_u32 v13, vcc_lo, v9, s12                          // 000000004604: D70F6A0D 02001909
	v_add_co_ci_u32_e64 v14, null, s14, v10, vcc_lo            // 00000000460C: D5287D0E 01AA140E
	s_mov_b32 s12, exec_lo                                     // 000000004614: BE8C037E
	global_store_dwordx2 v[13:14], v[21:22], off               // 000000004618: DC748000 007D150D
	s_waitcnt_vscnt null, 0x0                                  // 000000004620: BBFD0000
	global_atomic_cmpswap_x2 v[11:12], v15, v[19:22], s[6:7] offset:32 glc// 000000004624: DD458020 0B06130F
	s_waitcnt vmcnt(0)                                         // 00000000462C: BF8C3F70
	v_cmpx_ne_u64_e32 v[11:12], v[21:22]                       // 000000004630: 7DEA2B0B
	s_cbranch_execz 16                                         // 000000004634: BF880010 <__assert_fail+0x1238>
	s_mov_b32 s13, 0                                           // 000000004638: BE8D0380
	v_mov_b32_e32 v9, s10                                      // 00000000463C: 7E12020A
	v_mov_b32_e32 v10, s11                                     // 000000004640: 7E14020B
	s_sleep 1                                                  // 000000004644: BF8E0001
	global_store_dwordx2 v[13:14], v[11:12], off               // 000000004648: DC748000 007D0B0D
	s_waitcnt_vscnt null, 0x0                                  // 000000004650: BBFD0000
	global_atomic_cmpswap_x2 v[9:10], v15, v[9:12], s[6:7] offset:32 glc// 000000004654: DD458020 0906090F
	s_waitcnt vmcnt(0)                                         // 00000000465C: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[9:10], v[11:12]                 // 000000004660: 7DC41709
	v_mov_b32_e32 v12, v10                                     // 000000004664: 7E18030A
	v_mov_b32_e32 v11, v9                                      // 000000004668: 7E160309
	s_or_b32 s13, vcc_lo, s13                                  // 00000000466C: 880D0D6A
	s_andn2_b32 exec_lo, exec_lo, s13                          // 000000004670: 8A7E0D7E
	s_cbranch_execnz 65521                                     // 000000004674: BF89FFF1 <__assert_fail+0x11fc>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000004678: 887E0C7E
	v_mov_b32_e32 v12, 0                                       // 00000000467C: 7E180280
	s_mov_b32 s13, exec_lo                                     // 000000004680: BE8D037E
	s_mov_b32 s12, exec_lo                                     // 000000004684: BE8C037E
	v_mbcnt_lo_u32_b32 v11, s13, 0                             // 000000004688: D765000B 0201000D
	global_load_dwordx2 v[9:10], v12, s[6:7] offset:16         // 000000004690: DC348010 0906000C
	v_cmpx_eq_u32_e32 0, v11                                   // 000000004698: 7DA41680
	s_cbranch_execz 5                                          // 00000000469C: BF880005 <__assert_fail+0x1274>
	s_bcnt1_i32_b32 s13, s13                                   // 0000000046A0: BE8D0F0D
	v_mov_b32_e32 v11, s13                                     // 0000000046A4: 7E16020D
	s_waitcnt vmcnt(0)                                         // 0000000046A8: BF8C3F70
	global_atomic_add_x2 v[9:10], v[11:12], off offset:8       // 0000000046AC: DD488008 007D0B09
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000046B4: 887E0C7E
	s_waitcnt vmcnt(0)                                         // 0000000046B8: BF8C3F70
	global_load_dwordx2 v[11:12], v[9:10], off offset:16       // 0000000046BC: DC348010 0B7D0009
	s_waitcnt vmcnt(0)                                         // 0000000046C4: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[11:12]                       // 0000000046C8: 7DC41680
	s_cbranch_vccnz 11                                         // 0000000046CC: BF87000B <__assert_fail+0x12bc>
	global_load_dword v9, v[9:10], off offset:24               // 0000000046D0: DC308018 097D0009
	v_mov_b32_e32 v10, 0                                       // 0000000046D8: 7E140280
	s_waitcnt vmcnt(0)                                         // 0000000046DC: BF8C3F70
	v_readfirstlane_b32 s12, v9                                // 0000000046E0: 7E180509
	s_waitcnt_vscnt null, 0x0                                  // 0000000046E4: BBFD0000
	global_store_dwordx2 v[11:12], v[9:10], off                // 0000000046E8: DC748000 007D090B
	s_and_b32 m0, s12, 0x7fffff                                // 0000000046F0: 877CFF0C 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 0000000046F8: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000046FC: 887E057E
	s_branch 25                                                // 000000004700: BF820019 <__assert_fail+0x1328>
	s_nop 0                                                    // 000000004704: BF800000
	s_nop 0                                                    // 000000004708: BF800000
	s_nop 0                                                    // 00000000470C: BF800000
	s_nop 0                                                    // 000000004710: BF800000
	s_nop 0                                                    // 000000004714: BF800000
	s_nop 0                                                    // 000000004718: BF800000
	s_nop 0                                                    // 00000000471C: BF800000
	s_nop 0                                                    // 000000004720: BF800000
	s_nop 0                                                    // 000000004724: BF800000
	s_nop 0                                                    // 000000004728: BF800000
	s_nop 0                                                    // 00000000472C: BF800000
	s_nop 0                                                    // 000000004730: BF800000
	s_nop 0                                                    // 000000004734: BF800000
	s_nop 0                                                    // 000000004738: BF800000
	s_nop 0                                                    // 00000000473C: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000004740: 887E057E
	v_readfirstlane_b32 s5, v9                                 // 000000004744: 7E0A0509
	s_cmp_eq_u32 s5, 0                                         // 000000004748: BF068005
	s_cbranch_scc1 28                                          // 00000000474C: BF85001C <__assert_fail+0x1380>
	s_mov_b32 s5, 0                                            // 000000004750: BE850380
	s_sleep 1                                                  // 000000004754: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000004758: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 00000000475C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 000000004760: BF078105
	s_cbranch_scc0 24                                          // 000000004764: BF840018 <__assert_fail+0x1388>
	v_mov_b32_e32 v9, 1                                        // 000000004768: 7E120281
	s_and_saveexec_b32 s5, s4                                  // 00000000476C: BE853C04
	s_cbranch_execz 65523                                      // 000000004770: BF88FFF3 <__assert_fail+0x1300>
	global_load_dword v9, v[0:1], off offset:20 glc dlc        // 000000004774: DC319014 097D0000
	s_waitcnt vmcnt(0)                                         // 00000000477C: BF8C3F70
	buffer_gl1_inv                                             // 000000004780: E1C80000 00000000
	buffer_gl0_inv                                             // 000000004788: E1C40000 00000000
	v_and_b32_e32 v9, 1, v9                                    // 000000004790: 36121281
	s_branch 65514                                             // 000000004794: BF82FFEA <__assert_fail+0x1300>
	s_nop 0                                                    // 000000004798: BF800000
	s_nop 0                                                    // 00000000479C: BF800000
	s_nop 0                                                    // 0000000047A0: BF800000
	s_nop 0                                                    // 0000000047A4: BF800000
	s_nop 0                                                    // 0000000047A8: BF800000
	s_nop 0                                                    // 0000000047AC: BF800000
	s_nop 0                                                    // 0000000047B0: BF800000
	s_nop 0                                                    // 0000000047B4: BF800000
	s_nop 0                                                    // 0000000047B8: BF800000
	s_nop 0                                                    // 0000000047BC: BF800000
	s_mov_b32 s5, -1                                           // 0000000047C0: BE8503C1
	s_branch 65508                                             // 0000000047C4: BF82FFE4 <__assert_fail+0x1318>
	global_load_dwordx4 v[9:12], v[17:18], off                 // 0000000047C8: DC388000 097D0011
	s_and_saveexec_b32 s12, s4                                 // 0000000047D0: BE8C3C04
	s_cbranch_execz 55                                         // 0000000047D4: BF880037 <__assert_fail+0x1474>
	v_mov_b32_e32 v15, 0                                       // 0000000047D8: 7E1E0280
	s_clause 0x2                                               // 0000000047DC: BFA10002
	global_load_dwordx2 v[0:1], v15, s[6:7] offset:40          // 0000000047E0: DC348028 0006000F
	global_load_dwordx2 v[18:19], v15, s[6:7] offset:24 glc dlc// 0000000047E8: DC359018 1206000F
	global_load_dwordx2 v[11:12], v15, s[6:7]                  // 0000000047F0: DC348000 0B06000F
	s_waitcnt vmcnt(2)                                         // 0000000047F8: BF8C3F72
	v_readfirstlane_b32 s14, v0                                // 0000000047FC: 7E1C0500
	v_readfirstlane_b32 s15, v1                                // 000000004800: 7E1E0501
	s_add_u32 s13, s14, 1                                      // 000000004804: 800D810E
	s_addc_u32 s16, s15, 0                                     // 000000004808: 8210800F
	s_add_u32 s4, s13, s10                                     // 00000000480C: 80040A0D
	s_addc_u32 s5, s16, s11                                    // 000000004810: 82050B10
	s_cmp_eq_u64 s[4:5], 0                                     // 000000004814: BF128004
	s_cselect_b32 s5, s16, s5                                  // 000000004818: 85050510
	s_cselect_b32 s4, s13, s4                                  // 00000000481C: 8504040D
	v_mov_b32_e32 v17, s5                                      // 000000004820: 7E220205
	s_and_b64 s[10:11], s[4:5], s[14:15]                       // 000000004824: 878A0E04
	v_mov_b32_e32 v16, s4                                      // 000000004828: 7E200204
	s_mul_i32 s11, s11, 24                                     // 00000000482C: 930B980B
	s_mul_hi_u32 s13, s10, 24                                  // 000000004830: 9A8D980A
	s_mul_i32 s10, s10, 24                                     // 000000004834: 930A980A
	s_add_i32 s13, s13, s11                                    // 000000004838: 810D0B0D
	s_waitcnt vmcnt(0)                                         // 00000000483C: BF8C3F70
	v_add_co_u32 v0, vcc_lo, v11, s10                          // 000000004840: D70F6A00 0200150B
	v_add_co_ci_u32_e64 v1, null, s13, v12, vcc_lo             // 000000004848: D5287D01 01AA180D
	global_store_dwordx2 v[0:1], v[18:19], off                 // 000000004850: DC748000 007D1200
	s_waitcnt_vscnt null, 0x0                                  // 000000004858: BBFD0000
	global_atomic_cmpswap_x2 v[13:14], v15, v[16:19], s[6:7] offset:24 glc// 00000000485C: DD458018 0D06100F
	s_waitcnt vmcnt(0)                                         // 000000004864: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[13:14], v[18:19]                // 000000004868: 7DCA250D
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 00000000486C: 877E6A7E
	s_cbranch_execz 16                                         // 000000004870: BF880010 <__assert_fail+0x1474>
	s_mov_b32 s10, 0                                           // 000000004874: BE8A0380
	v_mov_b32_e32 v11, s4                                      // 000000004878: 7E160204
	v_mov_b32_e32 v12, s5                                      // 00000000487C: 7E180205
	s_sleep 1                                                  // 000000004880: BF8E0001
	global_store_dwordx2 v[0:1], v[13:14], off                 // 000000004884: DC748000 007D0D00
	s_waitcnt_vscnt null, 0x0                                  // 00000000488C: BBFD0000
	global_atomic_cmpswap_x2 v[11:12], v15, v[11:14], s[6:7] offset:24 glc// 000000004890: DD458018 0B060B0F
	s_waitcnt vmcnt(0)                                         // 000000004898: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[11:12], v[13:14]                // 00000000489C: 7DC41B0B
	v_mov_b32_e32 v14, v12                                     // 0000000048A0: 7E1C030C
	v_mov_b32_e32 v13, v11                                     // 0000000048A4: 7E1A030B
	s_or_b32 s10, vcc_lo, s10                                  // 0000000048A8: 880A0A6A
	s_andn2_b32 exec_lo, exec_lo, s10                          // 0000000048AC: 8A7E0A7E
	s_cbranch_execnz 65521                                     // 0000000048B0: BF89FFF1 <__assert_fail+0x1438>
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000048B4: 887E0C7E
	v_mov_b32_e32 v0, v2                                       // 0000000048B8: 7E000302
	v_mov_b32_e32 v1, v3                                       // 0000000048BC: 7E020303
	s_mov_b32 s5, 0                                            // 0000000048C0: BE850380
	s_waitcnt vmcnt(0)                                         // 0000000048C4: BF8C3F70
	flat_load_ubyte v11, v[0:1]                                // 0000000048C8: DC200000 0B7D0000
	v_add_co_u32 v0, s4, v0, 1                                 // 0000000048D0: D70F0400 02010300
	v_add_co_ci_u32_e64 v1, null, 0, v1, s4                    // 0000000048D8: D5287D01 00120280
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000048E0: BF8C0070
	v_cmp_eq_u16_e32 vcc_lo, 0, v11                            // 0000000048E4: 7D541680
	s_or_b32 s5, vcc_lo, s5                                    // 0000000048E8: 8805056A
	s_andn2_b32 exec_lo, exec_lo, s5                           // 0000000048EC: 8A7E057E
	s_cbranch_execnz 65524                                     // 0000000048F0: BF89FFF4 <__assert_fail+0x1484>
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000048F4: 887E057E
	s_mov_b32 s4, exec_lo                                      // 0000000048F8: BE84037E
	v_cmpx_ne_u64_e32 0, v[2:3]                                // 0000000048FC: 7DEA0480
	s_xor_b32 s14, exec_lo, s4                                 // 000000004900: 890E047E
	s_cbranch_execz 700                                        // 000000004904: BF8802BC <__assert_fail+0x1fb8>
	v_sub_nc_u32_e32 v0, v0, v2                                // 000000004908: 4C000500
	v_and_b32_e32 v37, 2, v9                                   // 00000000490C: 364A1282
	v_mov_b32_e32 v14, 0                                       // 000000004910: 7E1C0280
	v_and_b32_e32 v9, -3, v9                                   // 000000004914: 361212C3
	v_mov_b32_e32 v15, 2                                       // 000000004918: 7E1E0282
	v_ashrrev_i32_e32 v1, 31, v0                               // 00000000491C: 3002009F
	v_mov_b32_e32 v16, 1                                       // 000000004920: 7E200281
	s_mov_b32 s16, 0                                           // 000000004924: BE900380
	s_mov_b32 s15, 0                                           // 000000004928: BE8F0380
	s_branch 13                                                // 00000000492C: BF82000D <__assert_fail+0x1524>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000004930: 887E0C7E
	v_sub_co_u32 v0, vcc_lo, v0, v38                           // 000000004934: D7106A00 02024D00
	v_sub_co_ci_u32_e64 v1, null, v1, v39, vcc_lo              // 00000000493C: D5297D01 01AA4F01
	v_add_co_u32 v2, s4, v2, v38                               // 000000004944: D70F0402 02024D02
	v_add_co_ci_u32_e64 v3, null, v3, v39, s4                  // 00000000494C: D5287D03 00124F03
	v_cmp_eq_u64_e32 vcc_lo, 0, v[0:1]                         // 000000004954: 7DC40080
	s_or_b32 s15, vcc_lo, s15                                  // 000000004958: 880F0F6A
	s_andn2_b32 exec_lo, exec_lo, s15                          // 00000000495C: 8A7E0F7E
	s_cbranch_execz 676                                        // 000000004960: BF8802A4 <__assert_fail+0x1fb4>
	v_cmp_gt_u64_e32 vcc_lo, 56, v[0:1]                        // 000000004964: 7DC800B8
	s_mov_b32 s5, exec_lo                                      // 000000004968: BE85037E
	v_cndmask_b32_e32 v38, 56, v0, vcc_lo                      // 00000000496C: 024C00B8
	v_cmpx_gt_u64_e32 8, v[0:1]                                // 000000004970: 7DE80088
	s_xor_b32 s5, exec_lo, s5                                  // 000000004974: 8905057E
	s_cbranch_execz 40                                         // 000000004978: BF880028 <__assert_fail+0x15dc>
	s_waitcnt vmcnt(0)                                         // 00000000497C: BF8C3F70
	v_mov_b32_e32 v11, 0                                       // 000000004980: 7E160280
	v_mov_b32_e32 v12, 0                                       // 000000004984: 7E180280
	s_mov_b32 s10, exec_lo                                     // 000000004988: BE8A037E
	v_cmpx_ne_u64_e32 0, v[0:1]                                // 00000000498C: 7DEA0080
	s_cbranch_execz 33                                         // 000000004990: BF880021 <__assert_fail+0x15d8>
	v_mov_b32_e32 v11, 0                                       // 000000004994: 7E160280
	v_mov_b32_e32 v12, 0                                       // 000000004998: 7E180280
	s_mov_b32 s11, 0                                           // 00000000499C: BE8B0380
	s_mov_b32 s12, 0                                           // 0000000049A0: BE8C0380
	s_nop 0                                                    // 0000000049A4: BF800000
	s_nop 0                                                    // 0000000049A8: BF800000
	s_nop 0                                                    // 0000000049AC: BF800000
	s_nop 0                                                    // 0000000049B0: BF800000
	s_nop 0                                                    // 0000000049B4: BF800000
	s_nop 0                                                    // 0000000049B8: BF800000
	s_nop 0                                                    // 0000000049BC: BF800000
	v_add_co_u32 v17, s4, v2, s12                              // 0000000049C0: D70F0411 02001902
	v_add_co_ci_u32_e64 v18, null, 0, v3, s4                   // 0000000049C8: D5287D12 00120680
	s_lshl_b32 s4, s12, 3                                      // 0000000049D0: 8F04830C
	s_add_i32 s12, s12, 1                                      // 0000000049D4: 810C810C
	flat_load_ubyte v13, v[17:18]                              // 0000000049D8: DC200000 0D7D0011
	v_mov_b32_e32 v18, s16                                     // 0000000049E0: 7E240210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000049E4: BF8C0070
	v_and_b32_e32 v17, 0xffff, v13                             // 0000000049E8: 36221AFF 0000FFFF
	v_lshlrev_b64 v[17:18], s4, v[17:18]                       // 0000000049F0: D6FF0011 02022204
	v_cmp_eq_u32_e64 s4, s12, v38                              // 0000000049F8: D4C20004 02024C0C
	s_or_b32 s11, s4, s11                                      // 000000004A00: 880B0B04
	v_or_b32_e32 v12, v18, v12                                 // 000000004A04: 38181912
	v_or_b32_e32 v11, v17, v11                                 // 000000004A08: 38161711
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000004A0C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000004A10: BF89FFEB <__assert_fail+0x1580>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000004A14: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000004A18: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 000000004A1C: BE853D05
	v_mov_b32_e32 v13, 0                                       // 000000004A20: 7E1A0280
	v_mov_b32_e32 v30, v3                                      // 000000004A24: 7E3C0303
	v_mov_b32_e32 v29, v2                                      // 000000004A28: 7E3A0302
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000004A2C: 897E057E
	s_cbranch_execz 8                                          // 000000004A30: BF880008 <__assert_fail+0x1614>
	s_waitcnt vmcnt(0)                                         // 000000004A34: BF8C3F70
	flat_load_dwordx2 v[11:12], v[2:3]                         // 000000004A38: DC340000 0B7D0002
	v_add_co_u32 v29, s4, v2, 8                                // 000000004A40: D70F041D 02011102
	v_add_nc_u32_e32 v13, -8, v38                              // 000000004A48: 4A1A4CC8
	v_add_co_ci_u32_e64 v30, null, 0, v3, s4                   // 000000004A4C: D5287D1E 00120680
	s_or_b32 exec_lo, exec_lo, s5                              // 000000004A54: 887E057E
	s_mov_b32 s5, exec_lo                                      // 000000004A58: BE85037E
	v_cmpx_gt_u32_e32 8, v13                                   // 000000004A5C: 7DA81A88
	s_xor_b32 s5, exec_lo, s5                                  // 000000004A60: 8905057E
	s_cbranch_execz 45                                         // 000000004A64: BF88002D <__assert_fail+0x16dc>
	v_mov_b32_e32 v17, 0                                       // 000000004A68: 7E220280
	v_mov_b32_e32 v18, 0                                       // 000000004A6C: 7E240280
	s_mov_b32 s10, exec_lo                                     // 000000004A70: BE8A037E
	v_cmpx_ne_u32_e32 0, v13                                   // 000000004A74: 7DAA1A80
	s_cbranch_execz 39                                         // 000000004A78: BF880027 <__assert_fail+0x16d8>
	v_mov_b32_e32 v17, 0                                       // 000000004A7C: 7E220280
	v_mov_b32_e32 v18, 0                                       // 000000004A80: 7E240280
	s_mov_b32 s11, 0                                           // 000000004A84: BE8B0380
	s_mov_b32 s12, 0                                           // 000000004A88: BE8C0380
	s_nop 0                                                    // 000000004A8C: BF800000
	s_nop 0                                                    // 000000004A90: BF800000
	s_nop 0                                                    // 000000004A94: BF800000
	s_nop 0                                                    // 000000004A98: BF800000
	s_nop 0                                                    // 000000004A9C: BF800000
	s_nop 0                                                    // 000000004AA0: BF800000
	s_nop 0                                                    // 000000004AA4: BF800000
	s_nop 0                                                    // 000000004AA8: BF800000
	s_nop 0                                                    // 000000004AAC: BF800000
	s_nop 0                                                    // 000000004AB0: BF800000
	s_nop 0                                                    // 000000004AB4: BF800000
	s_nop 0                                                    // 000000004AB8: BF800000
	s_nop 0                                                    // 000000004ABC: BF800000
	v_add_co_u32 v19, s4, v29, s12                             // 000000004AC0: D70F0413 0200191D
	v_add_co_ci_u32_e64 v20, null, 0, v30, s4                  // 000000004AC8: D5287D14 00123C80
	s_lshl_b32 s4, s12, 3                                      // 000000004AD0: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000004AD4: 810C810C
	flat_load_ubyte v19, v[19:20]                              // 000000004AD8: DC200000 137D0013
	v_mov_b32_e32 v20, s16                                     // 000000004AE0: 7E280210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000004AE4: BF8C0070
	v_and_b32_e32 v19, 0xffff, v19                             // 000000004AE8: 362626FF 0000FFFF
	v_lshlrev_b64 v[19:20], s4, v[19:20]                       // 000000004AF0: D6FF0013 02022604
	v_cmp_eq_u32_e64 s4, s12, v13                              // 000000004AF8: D4C20004 02021A0C
	s_or_b32 s11, s4, s11                                      // 000000004B00: 880B0B04
	v_or_b32_e32 v18, v20, v18                                 // 000000004B04: 38242514
	v_or_b32_e32 v17, v19, v17                                 // 000000004B08: 38222313
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000004B0C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000004B10: BF89FFEB <__assert_fail+0x1680>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000004B14: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000004B18: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 000000004B1C: BE853D05
	v_mov_b32_e32 v21, 0                                       // 000000004B20: 7E2A0280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000004B24: 897E057E
	s_cbranch_execz 7                                          // 000000004B28: BF880007 <__assert_fail+0x1708>
	flat_load_dwordx2 v[17:18], v[29:30]                       // 000000004B2C: DC340000 117D001D
	v_add_co_u32 v29, s4, v29, 8                               // 000000004B34: D70F041D 0201111D
	v_add_nc_u32_e32 v21, -8, v13                              // 000000004B3C: 4A2A1AC8
	v_add_co_ci_u32_e64 v30, null, 0, v30, s4                  // 000000004B40: D5287D1E 00123C80
	s_or_b32 exec_lo, exec_lo, s5                              // 000000004B48: 887E057E
	s_mov_b32 s5, exec_lo                                      // 000000004B4C: BE85037E
	v_cmpx_gt_u32_e32 8, v21                                   // 000000004B50: 7DA82A88
	s_xor_b32 s5, exec_lo, s5                                  // 000000004B54: 8905057E
	s_cbranch_execz 32                                         // 000000004B58: BF880020 <__assert_fail+0x179c>
	v_mov_b32_e32 v19, 0                                       // 000000004B5C: 7E260280
	v_mov_b32_e32 v20, 0                                       // 000000004B60: 7E280280
	s_mov_b32 s10, exec_lo                                     // 000000004B64: BE8A037E
	v_cmpx_ne_u32_e32 0, v21                                   // 000000004B68: 7DAA2A80
	s_cbranch_execz 26                                         // 000000004B6C: BF88001A <__assert_fail+0x1798>
	v_mov_b32_e32 v19, 0                                       // 000000004B70: 7E260280
	v_mov_b32_e32 v20, 0                                       // 000000004B74: 7E280280
	s_mov_b32 s11, 0                                           // 000000004B78: BE8B0380
	s_mov_b32 s12, 0                                           // 000000004B7C: BE8C0380
	v_add_co_u32 v22, s4, v29, s12                             // 000000004B80: D70F0416 0200191D
	v_add_co_ci_u32_e64 v23, null, 0, v30, s4                  // 000000004B88: D5287D17 00123C80
	s_lshl_b32 s4, s12, 3                                      // 000000004B90: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000004B94: 810C810C
	flat_load_ubyte v13, v[22:23]                              // 000000004B98: DC200000 0D7D0016
	v_mov_b32_e32 v23, s16                                     // 000000004BA0: 7E2E0210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000004BA4: BF8C0070
	v_and_b32_e32 v22, 0xffff, v13                             // 000000004BA8: 362C1AFF 0000FFFF
	v_lshlrev_b64 v[22:23], s4, v[22:23]                       // 000000004BB0: D6FF0016 02022C04
	v_cmp_eq_u32_e64 s4, s12, v21                              // 000000004BB8: D4C20004 02022A0C
	s_or_b32 s11, s4, s11                                      // 000000004BC0: 880B0B04
	v_or_b32_e32 v20, v23, v20                                 // 000000004BC4: 38282917
	v_or_b32_e32 v19, v22, v19                                 // 000000004BC8: 38262716
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000004BCC: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000004BD0: BF89FFEB <__assert_fail+0x1740>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000004BD4: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000004BD8: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 000000004BDC: BE853D05
	v_mov_b32_e32 v13, 0                                       // 000000004BE0: 7E1A0280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000004BE4: 897E057E
	s_cbranch_execz 7                                          // 000000004BE8: BF880007 <__assert_fail+0x17c8>
	flat_load_dwordx2 v[19:20], v[29:30]                       // 000000004BEC: DC340000 137D001D
	v_add_co_u32 v29, s4, v29, 8                               // 000000004BF4: D70F041D 0201111D
	v_add_nc_u32_e32 v13, -8, v21                              // 000000004BFC: 4A1A2AC8
	v_add_co_ci_u32_e64 v30, null, 0, v30, s4                  // 000000004C00: D5287D1E 00123C80
	s_or_b32 exec_lo, exec_lo, s5                              // 000000004C08: 887E057E
	s_mov_b32 s5, exec_lo                                      // 000000004C0C: BE85037E
	v_cmpx_gt_u32_e32 8, v13                                   // 000000004C10: 7DA81A88
	s_xor_b32 s5, exec_lo, s5                                  // 000000004C14: 8905057E
	s_cbranch_execz 32                                         // 000000004C18: BF880020 <__assert_fail+0x185c>
	v_mov_b32_e32 v21, 0                                       // 000000004C1C: 7E2A0280
	v_mov_b32_e32 v22, 0                                       // 000000004C20: 7E2C0280
	s_mov_b32 s10, exec_lo                                     // 000000004C24: BE8A037E
	v_cmpx_ne_u32_e32 0, v13                                   // 000000004C28: 7DAA1A80
	s_cbranch_execz 26                                         // 000000004C2C: BF88001A <__assert_fail+0x1858>
	v_mov_b32_e32 v21, 0                                       // 000000004C30: 7E2A0280
	v_mov_b32_e32 v22, 0                                       // 000000004C34: 7E2C0280
	s_mov_b32 s11, 0                                           // 000000004C38: BE8B0380
	s_mov_b32 s12, 0                                           // 000000004C3C: BE8C0380
	v_add_co_u32 v23, s4, v29, s12                             // 000000004C40: D70F0417 0200191D
	v_add_co_ci_u32_e64 v24, null, 0, v30, s4                  // 000000004C48: D5287D18 00123C80
	s_lshl_b32 s4, s12, 3                                      // 000000004C50: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000004C54: 810C810C
	flat_load_ubyte v23, v[23:24]                              // 000000004C58: DC200000 177D0017
	v_mov_b32_e32 v24, s16                                     // 000000004C60: 7E300210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000004C64: BF8C0070
	v_and_b32_e32 v23, 0xffff, v23                             // 000000004C68: 362E2EFF 0000FFFF
	v_lshlrev_b64 v[23:24], s4, v[23:24]                       // 000000004C70: D6FF0017 02022E04
	v_cmp_eq_u32_e64 s4, s12, v13                              // 000000004C78: D4C20004 02021A0C
	s_or_b32 s11, s4, s11                                      // 000000004C80: 880B0B04
	v_or_b32_e32 v22, v24, v22                                 // 000000004C84: 382C2D18
	v_or_b32_e32 v21, v23, v21                                 // 000000004C88: 382A2B17
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000004C8C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000004C90: BF89FFEB <__assert_fail+0x1800>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000004C94: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000004C98: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 000000004C9C: BE853D05
	v_mov_b32_e32 v25, 0                                       // 000000004CA0: 7E320280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000004CA4: 897E057E
	s_cbranch_execz 7                                          // 000000004CA8: BF880007 <__assert_fail+0x1888>
	flat_load_dwordx2 v[21:22], v[29:30]                       // 000000004CAC: DC340000 157D001D
	v_add_co_u32 v29, s4, v29, 8                               // 000000004CB4: D70F041D 0201111D
	v_add_nc_u32_e32 v25, -8, v13                              // 000000004CBC: 4A321AC8
	v_add_co_ci_u32_e64 v30, null, 0, v30, s4                  // 000000004CC0: D5287D1E 00123C80
	s_or_b32 exec_lo, exec_lo, s5                              // 000000004CC8: 887E057E
	s_mov_b32 s5, exec_lo                                      // 000000004CCC: BE85037E
	v_cmpx_gt_u32_e32 8, v25                                   // 000000004CD0: 7DA83288
	s_xor_b32 s5, exec_lo, s5                                  // 000000004CD4: 8905057E
	s_cbranch_execz 32                                         // 000000004CD8: BF880020 <__assert_fail+0x191c>
	v_mov_b32_e32 v23, 0                                       // 000000004CDC: 7E2E0280
	v_mov_b32_e32 v24, 0                                       // 000000004CE0: 7E300280
	s_mov_b32 s10, exec_lo                                     // 000000004CE4: BE8A037E
	v_cmpx_ne_u32_e32 0, v25                                   // 000000004CE8: 7DAA3280
	s_cbranch_execz 26                                         // 000000004CEC: BF88001A <__assert_fail+0x1918>
	v_mov_b32_e32 v23, 0                                       // 000000004CF0: 7E2E0280
	v_mov_b32_e32 v24, 0                                       // 000000004CF4: 7E300280
	s_mov_b32 s11, 0                                           // 000000004CF8: BE8B0380
	s_mov_b32 s12, 0                                           // 000000004CFC: BE8C0380
	v_add_co_u32 v26, s4, v29, s12                             // 000000004D00: D70F041A 0200191D
	v_add_co_ci_u32_e64 v27, null, 0, v30, s4                  // 000000004D08: D5287D1B 00123C80
	s_lshl_b32 s4, s12, 3                                      // 000000004D10: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000004D14: 810C810C
	flat_load_ubyte v13, v[26:27]                              // 000000004D18: DC200000 0D7D001A
	v_mov_b32_e32 v27, s16                                     // 000000004D20: 7E360210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000004D24: BF8C0070
	v_and_b32_e32 v26, 0xffff, v13                             // 000000004D28: 36341AFF 0000FFFF
	v_lshlrev_b64 v[26:27], s4, v[26:27]                       // 000000004D30: D6FF001A 02023404
	v_cmp_eq_u32_e64 s4, s12, v25                              // 000000004D38: D4C20004 0202320C
	s_or_b32 s11, s4, s11                                      // 000000004D40: 880B0B04
	v_or_b32_e32 v24, v27, v24                                 // 000000004D44: 3830311B
	v_or_b32_e32 v23, v26, v23                                 // 000000004D48: 382E2F1A
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000004D4C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000004D50: BF89FFEB <__assert_fail+0x18c0>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000004D54: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000004D58: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 000000004D5C: BE853D05
	v_mov_b32_e32 v13, 0                                       // 000000004D60: 7E1A0280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000004D64: 897E057E
	s_cbranch_execz 7                                          // 000000004D68: BF880007 <__assert_fail+0x1948>
	flat_load_dwordx2 v[23:24], v[29:30]                       // 000000004D6C: DC340000 177D001D
	v_add_co_u32 v29, s4, v29, 8                               // 000000004D74: D70F041D 0201111D
	v_add_nc_u32_e32 v13, -8, v25                              // 000000004D7C: 4A1A32C8
	v_add_co_ci_u32_e64 v30, null, 0, v30, s4                  // 000000004D80: D5287D1E 00123C80
	s_or_b32 exec_lo, exec_lo, s5                              // 000000004D88: 887E057E
	s_mov_b32 s5, exec_lo                                      // 000000004D8C: BE85037E
	v_cmpx_gt_u32_e32 8, v13                                   // 000000004D90: 7DA81A88
	s_xor_b32 s5, exec_lo, s5                                  // 000000004D94: 8905057E
	s_cbranch_execz 32                                         // 000000004D98: BF880020 <__assert_fail+0x19dc>
	v_mov_b32_e32 v25, 0                                       // 000000004D9C: 7E320280
	v_mov_b32_e32 v26, 0                                       // 000000004DA0: 7E340280
	s_mov_b32 s10, exec_lo                                     // 000000004DA4: BE8A037E
	v_cmpx_ne_u32_e32 0, v13                                   // 000000004DA8: 7DAA1A80
	s_cbranch_execz 26                                         // 000000004DAC: BF88001A <__assert_fail+0x19d8>
	v_mov_b32_e32 v25, 0                                       // 000000004DB0: 7E320280
	v_mov_b32_e32 v26, 0                                       // 000000004DB4: 7E340280
	s_mov_b32 s11, 0                                           // 000000004DB8: BE8B0380
	s_mov_b32 s12, 0                                           // 000000004DBC: BE8C0380
	v_add_co_u32 v27, s4, v29, s12                             // 000000004DC0: D70F041B 0200191D
	v_add_co_ci_u32_e64 v28, null, 0, v30, s4                  // 000000004DC8: D5287D1C 00123C80
	s_lshl_b32 s4, s12, 3                                      // 000000004DD0: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000004DD4: 810C810C
	flat_load_ubyte v27, v[27:28]                              // 000000004DD8: DC200000 1B7D001B
	v_mov_b32_e32 v28, s16                                     // 000000004DE0: 7E380210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000004DE4: BF8C0070
	v_and_b32_e32 v27, 0xffff, v27                             // 000000004DE8: 363636FF 0000FFFF
	v_lshlrev_b64 v[27:28], s4, v[27:28]                       // 000000004DF0: D6FF001B 02023604
	v_cmp_eq_u32_e64 s4, s12, v13                              // 000000004DF8: D4C20004 02021A0C
	s_or_b32 s11, s4, s11                                      // 000000004E00: 880B0B04
	v_or_b32_e32 v26, v28, v26                                 // 000000004E04: 3834351C
	v_or_b32_e32 v25, v27, v25                                 // 000000004E08: 3832331B
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000004E0C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000004E10: BF89FFEB <__assert_fail+0x1980>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000004E14: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000004E18: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 000000004E1C: BE853D05
	v_mov_b32_e32 v31, 0                                       // 000000004E20: 7E3E0280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000004E24: 897E057E
	s_cbranch_execz 7                                          // 000000004E28: BF880007 <__assert_fail+0x1a08>
	flat_load_dwordx2 v[25:26], v[29:30]                       // 000000004E2C: DC340000 197D001D
	v_add_co_u32 v29, s4, v29, 8                               // 000000004E34: D70F041D 0201111D
	v_add_nc_u32_e32 v31, -8, v13                              // 000000004E3C: 4A3E1AC8
	v_add_co_ci_u32_e64 v30, null, 0, v30, s4                  // 000000004E40: D5287D1E 00123C80
	s_or_b32 exec_lo, exec_lo, s5                              // 000000004E48: 887E057E
	s_mov_b32 s5, exec_lo                                      // 000000004E4C: BE85037E
	v_cmpx_gt_u32_e32 8, v31                                   // 000000004E50: 7DA83E88
	s_xor_b32 s5, exec_lo, s5                                  // 000000004E54: 8905057E
	s_cbranch_execz 33                                         // 000000004E58: BF880021 <__assert_fail+0x1aa0>
	v_mov_b32_e32 v27, 0                                       // 000000004E5C: 7E360280
	v_mov_b32_e32 v28, 0                                       // 000000004E60: 7E380280
	s_mov_b32 s12, exec_lo                                     // 000000004E64: BE8C037E
	v_cmpx_ne_u32_e32 0, v31                                   // 000000004E68: 7DAA3E80
	s_cbranch_execz 27                                         // 000000004E6C: BF88001B <__assert_fail+0x1a9c>
	v_mov_b32_e32 v27, 0                                       // 000000004E70: 7E360280
	v_mov_b32_e32 v28, 0                                       // 000000004E74: 7E380280
	s_mov_b64 s[10:11], 0                                      // 000000004E78: BE8A0480
	s_mov_b32 s13, 0                                           // 000000004E7C: BE8D0380
	flat_load_ubyte v13, v[29:30]                              // 000000004E80: DC200000 0D7D001D
	v_mov_b32_e32 v33, s16                                     // 000000004E88: 7E420210
	v_add_nc_u32_e32 v31, -1, v31                              // 000000004E8C: 4A3E3EC1
	v_add_co_u32 v29, s4, v29, 1                               // 000000004E90: D70F041D 0201031D
	v_add_co_ci_u32_e64 v30, null, 0, v30, s4                  // 000000004E98: D5287D1E 00123C80
	v_cmp_eq_u32_e64 s4, 0, v31                                // 000000004EA0: D4C20004 02023E80
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000004EA8: BF8C0070
	v_and_b32_e32 v32, 0xffff, v13                             // 000000004EAC: 36401AFF 0000FFFF
	v_lshlrev_b64 v[32:33], s10, v[32:33]                      // 000000004EB4: D6FF0020 0202400A
	s_add_u32 s10, s10, 8                                      // 000000004EBC: 800A880A
	s_addc_u32 s11, s11, 0                                     // 000000004EC0: 820B800B
	s_or_b32 s13, s4, s13                                      // 000000004EC4: 880D0D04
	v_or_b32_e32 v28, v33, v28                                 // 000000004EC8: 38383921
	v_or_b32_e32 v27, v32, v27                                 // 000000004ECC: 38363720
	s_andn2_b32 exec_lo, exec_lo, s13                          // 000000004ED0: 8A7E0D7E
	s_cbranch_execnz 65514                                     // 000000004ED4: BF89FFEA <__assert_fail+0x1a40>
	s_or_b32 exec_lo, exec_lo, s13                             // 000000004ED8: 887E0D7E
	s_or_b32 exec_lo, exec_lo, s12                             // 000000004EDC: 887E0C7E
	s_andn2_saveexec_b32 s4, s5                                // 000000004EE0: BE843F05
	s_cbranch_execz 2                                          // 000000004EE4: BF880002 <__assert_fail+0x1ab0>
	flat_load_dwordx2 v[27:28], v[29:30]                       // 000000004EE8: DC340000 1B7D001D
	s_or_b32 exec_lo, exec_lo, s4                              // 000000004EF0: 887E047E
	v_readfirstlane_b32 s4, v36                                // 000000004EF4: 7E080524
	v_mov_b32_e32 v33, 0                                       // 000000004EF8: 7E420280
	v_mov_b32_e32 v34, 0                                       // 000000004EFC: 7E440280
	v_cmp_eq_u32_e64 s4, s4, v36                               // 000000004F00: D4C20004 02024804
	s_and_saveexec_b32 s10, s4                                 // 000000004F08: BE8A3C04
	s_cbranch_execz 77                                         // 000000004F0C: BF88004D <__assert_fail+0x1c04>
	global_load_dwordx2 v[31:32], v14, s[6:7] offset:24 glc dlc// 000000004F10: DC359018 1F06000E
	s_waitcnt vmcnt(0)                                         // 000000004F18: BF8C3F70
	buffer_gl1_inv                                             // 000000004F1C: E1C80000 00000000
	buffer_gl0_inv                                             // 000000004F24: E1C40000 00000000
	s_clause 0x1                                               // 000000004F2C: BFA10001
	global_load_dwordx2 v[29:30], v14, s[6:7] offset:40        // 000000004F30: DC348028 1D06000E
	global_load_dwordx2 v[33:34], v14, s[6:7]                  // 000000004F38: DC348000 2106000E
	s_mov_b32 s11, exec_lo                                     // 000000004F40: BE8B037E
	s_waitcnt vmcnt(1)                                         // 000000004F44: BF8C3F71
	v_and_b32_e32 v13, v30, v32                                // 000000004F48: 361A411E
	v_and_b32_e32 v29, v29, v31                                // 000000004F4C: 363A3F1D
	v_mul_lo_u32 v13, v13, 24                                  // 000000004F50: D569000D 0201310D
	v_mul_hi_u32 v30, v29, 24                                  // 000000004F58: D56A001E 0201311D
	v_mul_lo_u32 v29, v29, 24                                  // 000000004F60: D569001D 0201311D
	v_add_nc_u32_e32 v13, v30, v13                             // 000000004F68: 4A1A1B1E
	s_waitcnt vmcnt(0)                                         // 000000004F6C: BF8C3F70
	v_add_co_u32 v29, s5, v33, v29                             // 000000004F70: D70F051D 02023B21
	v_add_co_ci_u32_e64 v30, null, v34, v13, s5                // 000000004F78: D5287D1E 00161B22
	global_load_dwordx2 v[29:30], v[29:30], off glc dlc        // 000000004F80: DC359000 1D7D001D
	s_waitcnt vmcnt(0)                                         // 000000004F88: BF8C3F70
	global_atomic_cmpswap_x2 v[33:34], v14, v[29:32], s[6:7] offset:24 glc// 000000004F8C: DD458018 21061D0E
	s_waitcnt vmcnt(0)                                         // 000000004F94: BF8C3F70
	buffer_gl1_inv                                             // 000000004F98: E1C80000 00000000
	buffer_gl0_inv                                             // 000000004FA0: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[33:34], v[31:32]                       // 000000004FA8: 7DEA3F21
	s_cbranch_execz 36                                         // 000000004FAC: BF880024 <__assert_fail+0x1c00>
	s_mov_b32 s12, 0                                           // 000000004FB0: BE8C0380
	s_nop 0                                                    // 000000004FB4: BF800000
	s_nop 0                                                    // 000000004FB8: BF800000
	s_nop 0                                                    // 000000004FBC: BF800000
	s_sleep 1                                                  // 000000004FC0: BF8E0001
	s_clause 0x1                                               // 000000004FC4: BFA10001
	global_load_dwordx2 v[29:30], v14, s[6:7] offset:40        // 000000004FC8: DC348028 1D06000E
	global_load_dwordx2 v[48:49], v14, s[6:7]                  // 000000004FD0: DC348000 3006000E
	v_mov_b32_e32 v31, v33                                     // 000000004FD8: 7E3E0321
	v_mov_b32_e32 v32, v34                                     // 000000004FDC: 7E400322
	s_waitcnt vmcnt(1)                                         // 000000004FE0: BF8C3F71
	v_and_b32_e32 v13, v29, v31                                // 000000004FE4: 361A3F1D
	s_waitcnt vmcnt(0)                                         // 000000004FE8: BF8C3F70
	v_mad_u64_u32 v[48:49], null, v13, 24, v[48:49]            // 000000004FEC: D5767D30 04C1310D
	v_and_b32_e32 v13, v30, v32                                // 000000004FF4: 361A411E
	v_mad_u64_u32 v[49:50], null, v13, 24, v[49:50]            // 000000004FF8: D5767D31 04C5310D
	global_load_dwordx2 v[29:30], v[48:49], off glc dlc        // 000000005000: DC359000 1D7D0030
	s_waitcnt vmcnt(0)                                         // 000000005008: BF8C3F70
	global_atomic_cmpswap_x2 v[33:34], v14, v[29:32], s[6:7] offset:24 glc// 00000000500C: DD458018 21061D0E
	s_waitcnt vmcnt(0)                                         // 000000005014: BF8C3F70
	buffer_gl1_inv                                             // 000000005018: E1C80000 00000000
	buffer_gl0_inv                                             // 000000005020: E1C40000 00000000
	v_cmp_eq_u64_e64 s5, v[33:34], v[31:32]                    // 000000005028: D4E20005 02023F21
	s_or_b32 s12, s5, s12                                      // 000000005030: 880C0C05
	s_andn2_b32 exec_lo, exec_lo, s12                          // 000000005034: 8A7E0C7E
	s_cbranch_execnz 65505                                     // 000000005038: BF89FFE1 <__assert_fail+0x1b80>
	s_or_b32 exec_lo, exec_lo, s12                             // 00000000503C: 887E0C7E
	s_or_b32 exec_lo, exec_lo, s11                             // 000000005040: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000005044: 887E0A7E
	s_clause 0x1                                               // 000000005048: BFA10001
	global_load_dwordx2 v[48:49], v14, s[6:7] offset:40        // 00000000504C: DC348028 3006000E
	global_load_dwordx4 v[29:32], v14, s[6:7]                  // 000000005054: DC388000 1D06000E
	v_readfirstlane_b32 s11, v34                               // 00000000505C: 7E160522
	v_readfirstlane_b32 s10, v33                               // 000000005060: 7E140521
	s_mov_b32 s17, exec_lo                                     // 000000005064: BE91037E
	s_waitcnt vmcnt(1)                                         // 000000005068: BF8C3F71
	v_readfirstlane_b32 s12, v48                               // 00000000506C: 7E180530
	v_readfirstlane_b32 s13, v49                               // 000000005070: 7E1A0531
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000005074: 878C0A0C
	s_mul_i32 s5, s13, 24                                      // 000000005078: 9305980D
	s_mul_hi_u32 s18, s12, 24                                  // 00000000507C: 9A92980C
	s_mul_i32 s19, s12, 24                                     // 000000005080: 9313980C
	s_add_i32 s18, s18, s5                                     // 000000005084: 81120512
	s_waitcnt vmcnt(0)                                         // 000000005088: BF8C3F70
	v_add_co_u32 v33, s5, v29, s19                             // 00000000508C: D70F0521 0200271D
	v_add_co_ci_u32_e64 v34, null, s18, v30, s5                // 000000005094: D5287D22 00163C12
	s_and_saveexec_b32 s5, s4                                  // 00000000509C: BE853C04
	s_cbranch_execz 3                                          // 0000000050A0: BF880003 <__assert_fail+0x1c70>
	v_mov_b32_e32 v13, s17                                     // 0000000050A4: 7E1A0211
	global_store_dwordx4 v[33:34], v[13:16], off offset:8      // 0000000050A8: DC788008 007D0D21
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000050B0: 887E057E
	v_cmp_gt_u64_e64 s5, 57, v[0:1]                            // 0000000050B4: D4E40005 020200B9
	v_and_b32_e32 v9, 0xffffff1f, v9                           // 0000000050BC: 361212FF FFFFFF1F
	s_lshl_b64 s[12:13], s[12:13], 12                          // 0000000050C4: 8F8C8C0C
	v_lshl_add_u32 v48, v38, 2, 28                             // 0000000050C8: D7460030 02710526
	v_cndmask_b32_e32 v39, 0, v1, vcc_lo                       // 0000000050D0: 024E0280
	v_cndmask_b32_e64 v13, 0, v37, s5                          // 0000000050D4: D501000D 00164A80
	v_or_b32_e32 v9, v9, v13                                   // 0000000050DC: 38121B09
	v_add_co_u32 v13, s5, v31, s12                             // 0000000050E0: D70F050D 0200191F
	v_add_co_ci_u32_e64 v32, null, s13, v32, s5                // 0000000050E8: D5287D20 0016400D
	v_and_or_b32 v9, 0x1e0, v48, v9                            // 0000000050F0: D7710009 042660FF 000001E0
	v_add_co_u32 v31, vcc_lo, v13, v35                         // 0000000050FC: D70F6A1F 0202470D
	v_readfirstlane_b32 s12, v13                               // 000000005104: 7E18050D
	v_readfirstlane_b32 s13, v32                               // 000000005108: 7E1A0520
	v_add_co_ci_u32_e64 v32, null, 0, v32, vcc_lo              // 00000000510C: D5287D20 01AA4080
	s_waitcnt lgkmcnt(0)                                       // 000000005114: BF8CC07F
	global_store_dwordx4 v35, v[9:12], s[12:13]                // 000000005118: DC788000 000C0923
	global_store_dwordx4 v35, v[17:20], s[12:13] offset:16     // 000000005120: DC788010 000C1123
	global_store_dwordx4 v35, v[21:24], s[12:13] offset:32     // 000000005128: DC788020 000C1523
	global_store_dwordx4 v35, v[25:28], s[12:13] offset:48     // 000000005130: DC788030 000C1923
	s_and_saveexec_b32 s5, s4                                  // 000000005138: BE853C04
	s_cbranch_execz 75                                         // 00000000513C: BF88004B <__assert_fail+0x1e2c>
	s_clause 0x1                                               // 000000005140: BFA10001
	global_load_dwordx2 v[21:22], v14, s[6:7] offset:32 glc dlc// 000000005144: DC359020 1506000E
	global_load_dwordx2 v[9:10], v14, s[6:7] offset:40         // 00000000514C: DC348028 0906000E
	v_mov_b32_e32 v19, s10                                     // 000000005154: 7E26020A
	v_mov_b32_e32 v20, s11                                     // 000000005158: 7E28020B
	s_waitcnt vmcnt(0)                                         // 00000000515C: BF8C3F70
	v_readfirstlane_b32 s12, v9                                // 000000005160: 7E180509
	v_readfirstlane_b32 s13, v10                               // 000000005164: 7E1A050A
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000005168: 878C0A0C
	s_mul_i32 s13, s13, 24                                     // 00000000516C: 930D980D
	s_mul_hi_u32 s17, s12, 24                                  // 000000005170: 9A91980C
	s_mul_i32 s12, s12, 24                                     // 000000005174: 930C980C
	s_add_i32 s17, s17, s13                                    // 000000005178: 81110D11
	v_add_co_u32 v17, vcc_lo, v29, s12                         // 00000000517C: D70F6A11 0200191D
	v_add_co_ci_u32_e64 v18, null, s17, v30, vcc_lo            // 000000005184: D5287D12 01AA3C11
	s_mov_b32 s12, exec_lo                                     // 00000000518C: BE8C037E
	global_store_dwordx2 v[17:18], v[21:22], off               // 000000005190: DC748000 007D1511
	s_waitcnt_vscnt null, 0x0                                  // 000000005198: BBFD0000
	global_atomic_cmpswap_x2 v[11:12], v14, v[19:22], s[6:7] offset:32 glc// 00000000519C: DD458020 0B06130E
	s_waitcnt vmcnt(0)                                         // 0000000051A4: BF8C3F70
	v_cmpx_ne_u64_e32 v[11:12], v[21:22]                       // 0000000051A8: 7DEA2B0B
	s_cbranch_execz 16                                         // 0000000051AC: BF880010 <__assert_fail+0x1db0>
	s_mov_b32 s13, 0                                           // 0000000051B0: BE8D0380
	v_mov_b32_e32 v9, s10                                      // 0000000051B4: 7E12020A
	v_mov_b32_e32 v10, s11                                     // 0000000051B8: 7E14020B
	s_sleep 1                                                  // 0000000051BC: BF8E0001
	global_store_dwordx2 v[17:18], v[11:12], off               // 0000000051C0: DC748000 007D0B11
	s_waitcnt_vscnt null, 0x0                                  // 0000000051C8: BBFD0000
	global_atomic_cmpswap_x2 v[9:10], v14, v[9:12], s[6:7] offset:32 glc// 0000000051CC: DD458020 0906090E
	s_waitcnt vmcnt(0)                                         // 0000000051D4: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[9:10], v[11:12]                 // 0000000051D8: 7DC41709
	v_mov_b32_e32 v12, v10                                     // 0000000051DC: 7E18030A
	v_mov_b32_e32 v11, v9                                      // 0000000051E0: 7E160309
	s_or_b32 s13, vcc_lo, s13                                  // 0000000051E4: 880D0D6A
	s_andn2_b32 exec_lo, exec_lo, s13                          // 0000000051E8: 8A7E0D7E
	s_cbranch_execnz 65521                                     // 0000000051EC: BF89FFF1 <__assert_fail+0x1d74>
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000051F0: 887E0C7E
	global_load_dwordx2 v[9:10], v14, s[6:7] offset:16         // 0000000051F4: DC348010 0906000E
	s_mov_b32 s13, exec_lo                                     // 0000000051FC: BE8D037E
	s_mov_b32 s12, exec_lo                                     // 000000005200: BE8C037E
	v_mbcnt_lo_u32_b32 v11, s13, 0                             // 000000005204: D765000B 0201000D
	v_cmpx_eq_u32_e32 0, v11                                   // 00000000520C: 7DA41680
	s_cbranch_execz 5                                          // 000000005210: BF880005 <__assert_fail+0x1de8>
	s_bcnt1_i32_b32 s13, s13                                   // 000000005214: BE8D0F0D
	v_mov_b32_e32 v13, s13                                     // 000000005218: 7E1A020D
	s_waitcnt vmcnt(0)                                         // 00000000521C: BF8C3F70
	global_atomic_add_x2 v[9:10], v[13:14], off offset:8       // 000000005220: DD488008 007D0D09
	s_or_b32 exec_lo, exec_lo, s12                             // 000000005228: 887E0C7E
	s_waitcnt vmcnt(0)                                         // 00000000522C: BF8C3F70
	global_load_dwordx2 v[11:12], v[9:10], off offset:16       // 000000005230: DC348010 0B7D0009
	s_waitcnt vmcnt(0)                                         // 000000005238: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[11:12]                       // 00000000523C: 7DC41680
	s_cbranch_vccnz 10                                         // 000000005240: BF87000A <__assert_fail+0x1e2c>
	global_load_dword v13, v[9:10], off offset:24              // 000000005244: DC308018 0D7D0009
	s_waitcnt vmcnt(0)                                         // 00000000524C: BF8C3F70
	v_readfirstlane_b32 s12, v13                               // 000000005250: 7E18050D
	s_waitcnt_vscnt null, 0x0                                  // 000000005254: BBFD0000
	global_store_dwordx2 v[11:12], v[13:14], off               // 000000005258: DC748000 007D0D0B
	s_and_b32 m0, s12, 0x7fffff                                // 000000005260: 877CFF0C 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 000000005268: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 00000000526C: 887E057E
	s_branch 13                                                // 000000005270: BF82000D <__assert_fail+0x1e68>
	s_nop 0                                                    // 000000005274: BF800000
	s_nop 0                                                    // 000000005278: BF800000
	s_nop 0                                                    // 00000000527C: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000005280: 887E057E
	v_readfirstlane_b32 s5, v9                                 // 000000005284: 7E0A0509
	s_cmp_eq_u32 s5, 0                                         // 000000005288: BF068005
	s_cbranch_scc1 28                                          // 00000000528C: BF85001C <__assert_fail+0x1ec0>
	s_mov_b32 s5, 0                                            // 000000005290: BE850380
	s_sleep 1                                                  // 000000005294: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000005298: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 00000000529C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 0000000052A0: BF078105
	s_cbranch_scc0 24                                          // 0000000052A4: BF840018 <__assert_fail+0x1ec8>
	v_mov_b32_e32 v9, 1                                        // 0000000052A8: 7E120281
	s_and_saveexec_b32 s5, s4                                  // 0000000052AC: BE853C04
	s_cbranch_execz 65523                                      // 0000000052B0: BF88FFF3 <__assert_fail+0x1e40>
	global_load_dword v9, v[33:34], off offset:20 glc dlc      // 0000000052B4: DC319014 097D0021
	s_waitcnt vmcnt(0)                                         // 0000000052BC: BF8C3F70
	buffer_gl1_inv                                             // 0000000052C0: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000052C8: E1C40000 00000000
	v_and_b32_e32 v9, 1, v9                                    // 0000000052D0: 36121281
	s_branch 65514                                             // 0000000052D4: BF82FFEA <__assert_fail+0x1e40>
	s_nop 0                                                    // 0000000052D8: BF800000
	s_nop 0                                                    // 0000000052DC: BF800000
	s_nop 0                                                    // 0000000052E0: BF800000
	s_nop 0                                                    // 0000000052E4: BF800000
	s_nop 0                                                    // 0000000052E8: BF800000
	s_nop 0                                                    // 0000000052EC: BF800000
	s_nop 0                                                    // 0000000052F0: BF800000
	s_nop 0                                                    // 0000000052F4: BF800000
	s_nop 0                                                    // 0000000052F8: BF800000
	s_nop 0                                                    // 0000000052FC: BF800000
	s_mov_b32 s5, -1                                           // 000000005300: BE8503C1
	s_branch 65508                                             // 000000005304: BF82FFE4 <__assert_fail+0x1e58>
	global_load_dwordx4 v[9:12], v[31:32], off                 // 000000005308: DC388000 097D001F
	s_and_saveexec_b32 s12, s4                                 // 000000005310: BE8C3C04
	s_cbranch_execz 64902                                      // 000000005314: BF88FD86 <__assert_fail+0x14f0>
	s_clause 0x2                                               // 000000005318: BFA10002
	global_load_dwordx2 v[11:12], v14, s[6:7] offset:40        // 00000000531C: DC348028 0B06000E
	global_load_dwordx2 v[21:22], v14, s[6:7] offset:24 glc dlc// 000000005324: DC359018 1506000E
	global_load_dwordx2 v[17:18], v14, s[6:7]                  // 00000000532C: DC348000 1106000E
	s_waitcnt vmcnt(2)                                         // 000000005334: BF8C3F72
	v_readfirstlane_b32 s18, v11                               // 000000005338: 7E24050B
	v_readfirstlane_b32 s19, v12                               // 00000000533C: 7E26050C
	s_add_u32 s13, s18, 1                                      // 000000005340: 800D8112
	s_addc_u32 s17, s19, 0                                     // 000000005344: 82118013
	s_add_u32 s4, s13, s10                                     // 000000005348: 80040A0D
	s_addc_u32 s5, s17, s11                                    // 00000000534C: 82050B11
	s_cmp_eq_u64 s[4:5], 0                                     // 000000005350: BF128004
	s_cselect_b32 s5, s17, s5                                  // 000000005354: 85050511
	s_cselect_b32 s4, s13, s4                                  // 000000005358: 8504040D
	v_mov_b32_e32 v20, s5                                      // 00000000535C: 7E280205
	s_and_b64 s[10:11], s[4:5], s[18:19]                       // 000000005360: 878A1204
	v_mov_b32_e32 v19, s4                                      // 000000005364: 7E260204
	s_mul_i32 s11, s11, 24                                     // 000000005368: 930B980B
	s_mul_hi_u32 s13, s10, 24                                  // 00000000536C: 9A8D980A
	s_mul_i32 s10, s10, 24                                     // 000000005370: 930A980A
	s_add_i32 s13, s13, s11                                    // 000000005374: 810D0B0D
	s_waitcnt vmcnt(0)                                         // 000000005378: BF8C3F70
	v_add_co_u32 v11, vcc_lo, v17, s10                         // 00000000537C: D70F6A0B 02001511
	v_add_co_ci_u32_e64 v12, null, s13, v18, vcc_lo            // 000000005384: D5287D0C 01AA240D
	global_store_dwordx2 v[11:12], v[21:22], off               // 00000000538C: DC748000 007D150B
	s_waitcnt_vscnt null, 0x0                                  // 000000005394: BBFD0000
	global_atomic_cmpswap_x2 v[19:20], v14, v[19:22], s[6:7] offset:24 glc// 000000005398: DD458018 1306130E
	s_waitcnt vmcnt(0)                                         // 0000000053A0: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[19:20], v[21:22]                // 0000000053A4: 7DCA2B13
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 0000000053A8: 877E6A7E
	s_cbranch_execz 64864                                      // 0000000053AC: BF88FD60 <__assert_fail+0x14f0>
	s_mov_b32 s10, 0                                           // 0000000053B0: BE8A0380
	v_mov_b32_e32 v17, s4                                      // 0000000053B4: 7E220204
	v_mov_b32_e32 v18, s5                                      // 0000000053B8: 7E240205
	s_sleep 1                                                  // 0000000053BC: BF8E0001
	global_store_dwordx2 v[11:12], v[19:20], off               // 0000000053C0: DC748000 007D130B
	s_waitcnt_vscnt null, 0x0                                  // 0000000053C8: BBFD0000
	global_atomic_cmpswap_x2 v[17:18], v14, v[17:20], s[6:7] offset:24 glc// 0000000053CC: DD458018 1106110E
	s_waitcnt vmcnt(0)                                         // 0000000053D4: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[17:18], v[19:20]                // 0000000053D8: 7DC42711
	v_mov_b32_e32 v20, v18                                     // 0000000053DC: 7E280312
	v_mov_b32_e32 v19, v17                                     // 0000000053E0: 7E260311
	s_or_b32 s10, vcc_lo, s10                                  // 0000000053E4: 880A0A6A
	s_andn2_b32 exec_lo, exec_lo, s10                          // 0000000053E8: 8A7E0A7E
	s_cbranch_execnz 65521                                     // 0000000053EC: BF89FFF1 <__assert_fail+0x1f74>
	s_branch 64847                                             // 0000000053F0: BF82FD4F <__assert_fail+0x14f0>
	s_or_b32 exec_lo, exec_lo, s15                             // 0000000053F4: 887E0F7E
	s_andn2_saveexec_b32 s14, s14                              // 0000000053F8: BE8E3F0E
	s_cbranch_execz 350                                        // 0000000053FC: BF88015E <__assert_fail+0x2538>
	v_readfirstlane_b32 s4, v36                                // 000000005400: 7E080524
	v_mov_b32_e32 v13, 0                                       // 000000005404: 7E1A0280
	v_mov_b32_e32 v14, 0                                       // 000000005408: 7E1C0280
	v_cmp_eq_u32_e64 s4, s4, v36                               // 00000000540C: D4C20004 02024804
	s_and_saveexec_b32 s5, s4                                  // 000000005414: BE853C04
	s_cbranch_execz 89                                         // 000000005418: BF880059 <__assert_fail+0x2140>
	v_mov_b32_e32 v0, 0                                        // 00000000541C: 7E000280
	s_mov_b32 s10, exec_lo                                     // 000000005420: BE8A037E
	global_load_dwordx2 v[15:16], v0, s[6:7] offset:24 glc dlc // 000000005424: DC359018 0F060000
	s_waitcnt vmcnt(0)                                         // 00000000542C: BF8C3F70
	buffer_gl1_inv                                             // 000000005430: E1C80000 00000000
	buffer_gl0_inv                                             // 000000005438: E1C40000 00000000
	s_clause 0x1                                               // 000000005440: BFA10001
	global_load_dwordx2 v[1:2], v0, s[6:7] offset:40           // 000000005444: DC348028 01060000
	global_load_dwordx2 v[11:12], v0, s[6:7]                   // 00000000544C: DC348000 0B060000
	s_waitcnt vmcnt(1)                                         // 000000005454: BF8C3F71
	v_and_b32_e32 v2, v2, v16                                  // 000000005458: 36042102
	v_and_b32_e32 v1, v1, v15                                  // 00000000545C: 36021F01
	v_mul_lo_u32 v2, v2, 24                                    // 000000005460: D5690002 02013102
	v_mul_hi_u32 v3, v1, 24                                    // 000000005468: D56A0003 02013101
	v_mul_lo_u32 v1, v1, 24                                    // 000000005470: D5690001 02013101
	v_add_nc_u32_e32 v2, v3, v2                                // 000000005478: 4A040503
	s_waitcnt vmcnt(0)                                         // 00000000547C: BF8C3F70
	v_add_co_u32 v1, vcc_lo, v11, v1                           // 000000005480: D70F6A01 0202030B
	v_add_co_ci_u32_e64 v2, null, v12, v2, vcc_lo              // 000000005488: D5287D02 01AA050C
	global_load_dwordx2 v[13:14], v[1:2], off glc dlc          // 000000005490: DC359000 0D7D0001
	s_waitcnt vmcnt(0)                                         // 000000005498: BF8C3F70
	global_atomic_cmpswap_x2 v[13:14], v0, v[13:16], s[6:7] offset:24 glc// 00000000549C: DD458018 0D060D00
	s_waitcnt vmcnt(0)                                         // 0000000054A4: BF8C3F70
	buffer_gl1_inv                                             // 0000000054A8: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000054B0: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[13:14], v[15:16]                       // 0000000054B8: 7DEA1F0D
	s_cbranch_execz 47                                         // 0000000054BC: BF88002F <__assert_fail+0x213c>
	s_mov_b32 s11, 0                                           // 0000000054C0: BE8B0380
	s_nop 0                                                    // 0000000054C4: BF800000
	s_nop 0                                                    // 0000000054C8: BF800000
	s_nop 0                                                    // 0000000054CC: BF800000
	s_nop 0                                                    // 0000000054D0: BF800000
	s_nop 0                                                    // 0000000054D4: BF800000
	s_nop 0                                                    // 0000000054D8: BF800000
	s_nop 0                                                    // 0000000054DC: BF800000
	s_nop 0                                                    // 0000000054E0: BF800000
	s_nop 0                                                    // 0000000054E4: BF800000
	s_nop 0                                                    // 0000000054E8: BF800000
	s_nop 0                                                    // 0000000054EC: BF800000
	s_nop 0                                                    // 0000000054F0: BF800000
	s_nop 0                                                    // 0000000054F4: BF800000
	s_nop 0                                                    // 0000000054F8: BF800000
	s_nop 0                                                    // 0000000054FC: BF800000
	s_sleep 1                                                  // 000000005500: BF8E0001
	s_clause 0x1                                               // 000000005504: BFA10001
	global_load_dwordx2 v[2:3], v0, s[6:7] offset:40           // 000000005508: DC348028 02060000
	global_load_dwordx2 v[11:12], v0, s[6:7]                   // 000000005510: DC348000 0B060000
	v_mov_b32_e32 v15, v13                                     // 000000005518: 7E1E030D
	v_mov_b32_e32 v16, v14                                     // 00000000551C: 7E20030E
	s_waitcnt vmcnt(1)                                         // 000000005520: BF8C3F71
	v_and_b32_e32 v1, v2, v15                                  // 000000005524: 36021F02
	v_and_b32_e32 v3, v3, v16                                  // 000000005528: 36062103
	s_waitcnt vmcnt(0)                                         // 00000000552C: BF8C3F70
	v_mad_u64_u32 v[1:2], null, v1, 24, v[11:12]               // 000000005530: D5767D01 042D3101
	v_mad_u64_u32 v[2:3], null, v3, 24, v[2:3]                 // 000000005538: D5767D02 04093103
	global_load_dwordx2 v[13:14], v[1:2], off glc dlc          // 000000005540: DC359000 0D7D0001
	s_waitcnt vmcnt(0)                                         // 000000005548: BF8C3F70
	global_atomic_cmpswap_x2 v[13:14], v0, v[13:16], s[6:7] offset:24 glc// 00000000554C: DD458018 0D060D00
	s_waitcnt vmcnt(0)                                         // 000000005554: BF8C3F70
	buffer_gl1_inv                                             // 000000005558: E1C80000 00000000
	buffer_gl0_inv                                             // 000000005560: E1C40000 00000000
	v_cmp_eq_u64_e32 vcc_lo, v[13:14], v[15:16]                // 000000005568: 7DC41F0D
	s_or_b32 s11, vcc_lo, s11                                  // 00000000556C: 880B0B6A
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000005570: 8A7E0B7E
	s_cbranch_execnz 65506                                     // 000000005574: BF89FFE2 <__assert_fail+0x20c0>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000005578: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 00000000557C: 887E0A7E
	s_or_b32 exec_lo, exec_lo, s5                              // 000000005580: 887E057E
	s_waitcnt vmcnt(0)                                         // 000000005584: BF8C3F70
	v_mov_b32_e32 v12, 0                                       // 000000005588: 7E180280
	v_readfirstlane_b32 s11, v14                               // 00000000558C: 7E16050E
	v_readfirstlane_b32 s10, v13                               // 000000005590: 7E14050D
	s_mov_b32 s5, exec_lo                                      // 000000005594: BE85037E
	s_clause 0x1                                               // 000000005598: BFA10001
	global_load_dwordx2 v[15:16], v12, s[6:7] offset:40        // 00000000559C: DC348028 0F06000C
	global_load_dwordx4 v[0:3], v12, s[6:7]                    // 0000000055A4: DC388000 0006000C
	s_waitcnt vmcnt(1)                                         // 0000000055AC: BF8C3F71
	v_readfirstlane_b32 s12, v15                               // 0000000055B0: 7E18050F
	v_readfirstlane_b32 s13, v16                               // 0000000055B4: 7E1A0510
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 0000000055B8: 878C0A0C
	s_mul_i32 s15, s13, 24                                     // 0000000055BC: 930F980D
	s_mul_hi_u32 s16, s12, 24                                  // 0000000055C0: 9A90980C
	s_mul_i32 s17, s12, 24                                     // 0000000055C4: 9311980C
	s_add_i32 s16, s16, s15                                    // 0000000055C8: 81100F10
	s_waitcnt vmcnt(0)                                         // 0000000055CC: BF8C3F70
	v_add_co_u32 v15, vcc_lo, v0, s17                          // 0000000055D0: D70F6A0F 02002300
	v_add_co_ci_u32_e64 v16, null, s16, v1, vcc_lo             // 0000000055D8: D5287D10 01AA0210
	s_and_saveexec_b32 s15, s4                                 // 0000000055E0: BE8F3C04
	s_cbranch_execz 5                                          // 0000000055E4: BF880005 <__assert_fail+0x21bc>
	v_mov_b32_e32 v11, s5                                      // 0000000055E8: 7E160205
	v_mov_b32_e32 v13, 2                                       // 0000000055EC: 7E1A0282
	v_mov_b32_e32 v14, 1                                       // 0000000055F0: 7E1C0281
	global_store_dwordx4 v[15:16], v[11:14], off offset:8      // 0000000055F4: DC788008 007D0B0F
	s_or_b32 exec_lo, exec_lo, s15                             // 0000000055FC: 887E0F7E
	s_lshl_b64 s[12:13], s[12:13], 12                          // 000000005600: 8F8C8C0C
	s_mov_b32 s16, 0                                           // 000000005604: BE900380
	v_add_co_u32 v2, vcc_lo, v2, s12                           // 000000005608: D70F6A02 02001902
	v_add_co_ci_u32_e64 v3, null, s13, v3, vcc_lo              // 000000005610: D5287D03 01AA060D
	s_mov_b32 s17, s16                                         // 000000005618: BE910310
	v_add_co_u32 v13, vcc_lo, v2, v35                          // 00000000561C: D70F6A0D 02024702
	s_mov_b32 s18, s16                                         // 000000005624: BE920310
	s_mov_b32 s19, s16                                         // 000000005628: BE930310
	v_and_or_b32 v9, 0xffffff1f, v9, 32                        // 00000000562C: D7710009 028212FF FFFFFF1F
	v_mov_b32_e32 v11, s16                                     // 000000005638: 7E160210
	v_mov_b32_e32 v12, s16                                     // 00000000563C: 7E180210
	v_readfirstlane_b32 s12, v2                                // 000000005640: 7E180502
	v_readfirstlane_b32 s13, v3                                // 000000005644: 7E1A0503
	v_add_co_ci_u32_e64 v14, null, 0, v3, vcc_lo               // 000000005648: D5287D0E 01AA0680
	v_mov_b32_e32 v20, s19                                     // 000000005650: 7E280213
	v_mov_b32_e32 v19, s18                                     // 000000005654: 7E260212
	v_mov_b32_e32 v18, s17                                     // 000000005658: 7E240211
	v_mov_b32_e32 v17, s16                                     // 00000000565C: 7E220210
	global_store_dwordx4 v35, v[9:12], s[12:13]                // 000000005660: DC788000 000C0923
	global_store_dwordx4 v35, v[17:20], s[12:13] offset:16     // 000000005668: DC788010 000C1123
	global_store_dwordx4 v35, v[17:20], s[12:13] offset:32     // 000000005670: DC788020 000C1123
	global_store_dwordx4 v35, v[17:20], s[12:13] offset:48     // 000000005678: DC788030 000C1123
	s_and_saveexec_b32 s5, s4                                  // 000000005680: BE853C04
	s_cbranch_execz 78                                         // 000000005684: BF88004E <__assert_fail+0x2380>
	v_mov_b32_e32 v11, 0                                       // 000000005688: 7E160280
	v_mov_b32_e32 v17, s10                                     // 00000000568C: 7E22020A
	v_mov_b32_e32 v18, s11                                     // 000000005690: 7E24020B
	s_clause 0x1                                               // 000000005694: BFA10001
	global_load_dwordx2 v[19:20], v11, s[6:7] offset:32 glc dlc// 000000005698: DC359020 1306000B
	global_load_dwordx2 v[2:3], v11, s[6:7] offset:40          // 0000000056A0: DC348028 0206000B
	s_waitcnt vmcnt(0)                                         // 0000000056A8: BF8C3F70
	v_readfirstlane_b32 s12, v2                                // 0000000056AC: 7E180502
	v_readfirstlane_b32 s13, v3                                // 0000000056B0: 7E1A0503
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 0000000056B4: 878C0A0C
	s_mul_i32 s13, s13, 24                                     // 0000000056B8: 930D980D
	s_mul_hi_u32 s15, s12, 24                                  // 0000000056BC: 9A8F980C
	s_mul_i32 s12, s12, 24                                     // 0000000056C0: 930C980C
	s_add_i32 s15, s15, s13                                    // 0000000056C4: 810F0D0F
	v_add_co_u32 v9, vcc_lo, v0, s12                           // 0000000056C8: D70F6A09 02001900
	v_add_co_ci_u32_e64 v10, null, s15, v1, vcc_lo             // 0000000056D0: D5287D0A 01AA020F
	s_mov_b32 s12, exec_lo                                     // 0000000056D8: BE8C037E
	global_store_dwordx2 v[9:10], v[19:20], off                // 0000000056DC: DC748000 007D1309
	s_waitcnt_vscnt null, 0x0                                  // 0000000056E4: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v11, v[17:20], s[6:7] offset:32 glc// 0000000056E8: DD458020 0206110B
	s_waitcnt vmcnt(0)                                         // 0000000056F0: BF8C3F70
	v_cmpx_ne_u64_e32 v[2:3], v[19:20]                         // 0000000056F4: 7DEA2702
	s_cbranch_execz 16                                         // 0000000056F8: BF880010 <__assert_fail+0x22fc>
	s_mov_b32 s13, 0                                           // 0000000056FC: BE8D0380
	v_mov_b32_e32 v0, s10                                      // 000000005700: 7E00020A
	v_mov_b32_e32 v1, s11                                      // 000000005704: 7E02020B
	s_sleep 1                                                  // 000000005708: BF8E0001
	global_store_dwordx2 v[9:10], v[2:3], off                  // 00000000570C: DC748000 007D0209
	s_waitcnt_vscnt null, 0x0                                  // 000000005714: BBFD0000
	global_atomic_cmpswap_x2 v[0:1], v11, v[0:3], s[6:7] offset:32 glc// 000000005718: DD458020 0006000B
	s_waitcnt vmcnt(0)                                         // 000000005720: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]                    // 000000005724: 7DC40500
	v_mov_b32_e32 v3, v1                                       // 000000005728: 7E060301
	v_mov_b32_e32 v2, v0                                       // 00000000572C: 7E040300
	s_or_b32 s13, vcc_lo, s13                                  // 000000005730: 880D0D6A
	s_andn2_b32 exec_lo, exec_lo, s13                          // 000000005734: 8A7E0D7E
	s_cbranch_execnz 65521                                     // 000000005738: BF89FFF1 <__assert_fail+0x22c0>
	s_or_b32 exec_lo, exec_lo, s12                             // 00000000573C: 887E0C7E
	v_mov_b32_e32 v3, 0                                        // 000000005740: 7E060280
	s_mov_b32 s13, exec_lo                                     // 000000005744: BE8D037E
	s_mov_b32 s12, exec_lo                                     // 000000005748: BE8C037E
	v_mbcnt_lo_u32_b32 v2, s13, 0                              // 00000000574C: D7650002 0201000D
	global_load_dwordx2 v[0:1], v3, s[6:7] offset:16           // 000000005754: DC348010 00060003
	v_cmpx_eq_u32_e32 0, v2                                    // 00000000575C: 7DA40480
	s_cbranch_execz 5                                          // 000000005760: BF880005 <__assert_fail+0x2338>
	s_bcnt1_i32_b32 s13, s13                                   // 000000005764: BE8D0F0D
	v_mov_b32_e32 v2, s13                                      // 000000005768: 7E04020D
	s_waitcnt vmcnt(0)                                         // 00000000576C: BF8C3F70
	global_atomic_add_x2 v[0:1], v[2:3], off offset:8          // 000000005770: DD488008 007D0200
	s_or_b32 exec_lo, exec_lo, s12                             // 000000005778: 887E0C7E
	s_waitcnt vmcnt(0)                                         // 00000000577C: BF8C3F70
	global_load_dwordx2 v[2:3], v[0:1], off offset:16          // 000000005780: DC348010 027D0000
	s_waitcnt vmcnt(0)                                         // 000000005788: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[2:3]                         // 00000000578C: 7DC40480
	s_cbranch_vccnz 11                                         // 000000005790: BF87000B <__assert_fail+0x2380>
	global_load_dword v0, v[0:1], off offset:24                // 000000005794: DC308018 007D0000
	v_mov_b32_e32 v1, 0                                        // 00000000579C: 7E020280
	s_waitcnt vmcnt(0)                                         // 0000000057A0: BF8C3F70
	v_readfirstlane_b32 s12, v0                                // 0000000057A4: 7E180500
	s_waitcnt_vscnt null, 0x0                                  // 0000000057A8: BBFD0000
	global_store_dwordx2 v[2:3], v[0:1], off                   // 0000000057AC: DC748000 007D0002
	s_and_b32 m0, s12, 0x7fffff                                // 0000000057B4: 877CFF0C 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 0000000057BC: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000057C0: 887E057E
	s_branch 24                                                // 0000000057C4: BF820018 <__assert_fail+0x23e8>
	s_nop 0                                                    // 0000000057C8: BF800000
	s_nop 0                                                    // 0000000057CC: BF800000
	s_nop 0                                                    // 0000000057D0: BF800000
	s_nop 0                                                    // 0000000057D4: BF800000
	s_nop 0                                                    // 0000000057D8: BF800000
	s_nop 0                                                    // 0000000057DC: BF800000
	s_nop 0                                                    // 0000000057E0: BF800000
	s_nop 0                                                    // 0000000057E4: BF800000
	s_nop 0                                                    // 0000000057E8: BF800000
	s_nop 0                                                    // 0000000057EC: BF800000
	s_nop 0                                                    // 0000000057F0: BF800000
	s_nop 0                                                    // 0000000057F4: BF800000
	s_nop 0                                                    // 0000000057F8: BF800000
	s_nop 0                                                    // 0000000057FC: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000005800: 887E057E
	v_readfirstlane_b32 s5, v0                                 // 000000005804: 7E0A0500
	s_cmp_eq_u32 s5, 0                                         // 000000005808: BF068005
	s_cbranch_scc1 28                                          // 00000000580C: BF85001C <__assert_fail+0x2440>
	s_mov_b32 s5, 0                                            // 000000005810: BE850380
	s_sleep 1                                                  // 000000005814: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000005818: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 00000000581C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 000000005820: BF078105
	s_cbranch_scc0 24                                          // 000000005824: BF840018 <__assert_fail+0x2448>
	v_mov_b32_e32 v0, 1                                        // 000000005828: 7E000281
	s_and_saveexec_b32 s5, s4                                  // 00000000582C: BE853C04
	s_cbranch_execz 65523                                      // 000000005830: BF88FFF3 <__assert_fail+0x23c0>
	global_load_dword v0, v[15:16], off offset:20 glc dlc      // 000000005834: DC319014 007D000F
	s_waitcnt vmcnt(0)                                         // 00000000583C: BF8C3F70
	buffer_gl1_inv                                             // 000000005840: E1C80000 00000000
	buffer_gl0_inv                                             // 000000005848: E1C40000 00000000
	v_and_b32_e32 v0, 1, v0                                    // 000000005850: 36000081
	s_branch 65514                                             // 000000005854: BF82FFEA <__assert_fail+0x23c0>
	s_nop 0                                                    // 000000005858: BF800000
	s_nop 0                                                    // 00000000585C: BF800000
	s_nop 0                                                    // 000000005860: BF800000
	s_nop 0                                                    // 000000005864: BF800000
	s_nop 0                                                    // 000000005868: BF800000
	s_nop 0                                                    // 00000000586C: BF800000
	s_nop 0                                                    // 000000005870: BF800000
	s_nop 0                                                    // 000000005874: BF800000
	s_nop 0                                                    // 000000005878: BF800000
	s_nop 0                                                    // 00000000587C: BF800000
	s_mov_b32 s5, -1                                           // 000000005880: BE8503C1
	s_branch 65508                                             // 000000005884: BF82FFE4 <__assert_fail+0x23d8>
	global_load_dwordx4 v[9:12], v[13:14], off                 // 000000005888: DC388000 097D000D
	s_and_saveexec_b32 s12, s4                                 // 000000005890: BE8C3C04
	s_cbranch_execz 55                                         // 000000005894: BF880037 <__assert_fail+0x2534>
	v_mov_b32_e32 v13, 0                                       // 000000005898: 7E1A0280
	s_clause 0x2                                               // 00000000589C: BFA10002
	global_load_dwordx2 v[0:1], v13, s[6:7] offset:40          // 0000000058A0: DC348028 0006000D
	global_load_dwordx2 v[16:17], v13, s[6:7] offset:24 glc dlc// 0000000058A8: DC359018 1006000D
	global_load_dwordx2 v[2:3], v13, s[6:7]                    // 0000000058B0: DC348000 0206000D
	s_waitcnt vmcnt(2)                                         // 0000000058B8: BF8C3F72
	v_readfirstlane_b32 s16, v0                                // 0000000058BC: 7E200500
	v_readfirstlane_b32 s17, v1                                // 0000000058C0: 7E220501
	s_add_u32 s13, s16, 1                                      // 0000000058C4: 800D8110
	s_addc_u32 s15, s17, 0                                     // 0000000058C8: 820F8011
	s_add_u32 s4, s13, s10                                     // 0000000058CC: 80040A0D
	s_addc_u32 s5, s15, s11                                    // 0000000058D0: 82050B0F
	s_cmp_eq_u64 s[4:5], 0                                     // 0000000058D4: BF128004
	s_cselect_b32 s5, s15, s5                                  // 0000000058D8: 8505050F
	s_cselect_b32 s4, s13, s4                                  // 0000000058DC: 8504040D
	v_mov_b32_e32 v15, s5                                      // 0000000058E0: 7E1E0205
	s_and_b64 s[10:11], s[4:5], s[16:17]                       // 0000000058E4: 878A1004
	v_mov_b32_e32 v14, s4                                      // 0000000058E8: 7E1C0204
	s_mul_i32 s11, s11, 24                                     // 0000000058EC: 930B980B
	s_mul_hi_u32 s13, s10, 24                                  // 0000000058F0: 9A8D980A
	s_mul_i32 s10, s10, 24                                     // 0000000058F4: 930A980A
	s_add_i32 s13, s13, s11                                    // 0000000058F8: 810D0B0D
	s_waitcnt vmcnt(0)                                         // 0000000058FC: BF8C3F70
	v_add_co_u32 v11, vcc_lo, v2, s10                          // 000000005900: D70F6A0B 02001502
	v_add_co_ci_u32_e64 v12, null, s13, v3, vcc_lo             // 000000005908: D5287D0C 01AA060D
	global_store_dwordx2 v[11:12], v[16:17], off               // 000000005910: DC748000 007D100B
	s_waitcnt_vscnt null, 0x0                                  // 000000005918: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v13, v[14:17], s[6:7] offset:24 glc// 00000000591C: DD458018 02060E0D
	s_waitcnt vmcnt(0)                                         // 000000005924: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[2:3], v[16:17]                  // 000000005928: 7DCA2102
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 00000000592C: 877E6A7E
	s_cbranch_execz 16                                         // 000000005930: BF880010 <__assert_fail+0x2534>
	s_mov_b32 s10, 0                                           // 000000005934: BE8A0380
	v_mov_b32_e32 v0, s4                                       // 000000005938: 7E000204
	v_mov_b32_e32 v1, s5                                       // 00000000593C: 7E020205
	s_sleep 1                                                  // 000000005940: BF8E0001
	global_store_dwordx2 v[11:12], v[2:3], off                 // 000000005944: DC748000 007D020B
	s_waitcnt_vscnt null, 0x0                                  // 00000000594C: BBFD0000
	global_atomic_cmpswap_x2 v[0:1], v13, v[0:3], s[6:7] offset:24 glc// 000000005950: DD458018 0006000D
	s_waitcnt vmcnt(0)                                         // 000000005958: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]                    // 00000000595C: 7DC40500
	v_mov_b32_e32 v3, v1                                       // 000000005960: 7E060301
	v_mov_b32_e32 v2, v0                                       // 000000005964: 7E040300
	s_or_b32 s10, vcc_lo, s10                                  // 000000005968: 880A0A6A
	s_andn2_b32 exec_lo, exec_lo, s10                          // 00000000596C: 8A7E0A7E
	s_cbranch_execnz 65521                                     // 000000005970: BF89FFF1 <__assert_fail+0x24f8>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000005974: 887E0C7E
	s_or_b32 exec_lo, exec_lo, s14                             // 000000005978: 887E0E7E
	v_readfirstlane_b32 s4, v36                                // 00000000597C: 7E080524
	v_mov_b32_e32 v13, 0                                       // 000000005980: 7E1A0280
	v_mov_b32_e32 v14, 0                                       // 000000005984: 7E1C0280
	v_cmp_eq_u32_e64 s4, s4, v36                               // 000000005988: D4C20004 02024804
	s_and_saveexec_b32 s5, s4                                  // 000000005990: BE853C04
	s_cbranch_execz 74                                         // 000000005994: BF88004A <__assert_fail+0x2680>
	v_mov_b32_e32 v0, 0                                        // 000000005998: 7E000280
	s_mov_b32 s10, exec_lo                                     // 00000000599C: BE8A037E
	global_load_dwordx2 v[15:16], v0, s[6:7] offset:24 glc dlc // 0000000059A0: DC359018 0F060000
	s_waitcnt vmcnt(0)                                         // 0000000059A8: BF8C3F70
	buffer_gl1_inv                                             // 0000000059AC: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000059B4: E1C40000 00000000
	s_clause 0x1                                               // 0000000059BC: BFA10001
	global_load_dwordx2 v[1:2], v0, s[6:7] offset:40           // 0000000059C0: DC348028 01060000
	global_load_dwordx2 v[11:12], v0, s[6:7]                   // 0000000059C8: DC348000 0B060000
	s_waitcnt vmcnt(1)                                         // 0000000059D0: BF8C3F71
	v_and_b32_e32 v2, v2, v16                                  // 0000000059D4: 36042102
	v_and_b32_e32 v1, v1, v15                                  // 0000000059D8: 36021F01
	v_mul_lo_u32 v2, v2, 24                                    // 0000000059DC: D5690002 02013102
	v_mul_hi_u32 v3, v1, 24                                    // 0000000059E4: D56A0003 02013101
	v_mul_lo_u32 v1, v1, 24                                    // 0000000059EC: D5690001 02013101
	v_add_nc_u32_e32 v2, v3, v2                                // 0000000059F4: 4A040503
	s_waitcnt vmcnt(0)                                         // 0000000059F8: BF8C3F70
	v_add_co_u32 v1, vcc_lo, v11, v1                           // 0000000059FC: D70F6A01 0202030B
	v_add_co_ci_u32_e64 v2, null, v12, v2, vcc_lo              // 000000005A04: D5287D02 01AA050C
	global_load_dwordx2 v[13:14], v[1:2], off glc dlc          // 000000005A0C: DC359000 0D7D0001
	s_waitcnt vmcnt(0)                                         // 000000005A14: BF8C3F70
	global_atomic_cmpswap_x2 v[13:14], v0, v[13:16], s[6:7] offset:24 glc// 000000005A18: DD458018 0D060D00
	s_waitcnt vmcnt(0)                                         // 000000005A20: BF8C3F70
	buffer_gl1_inv                                             // 000000005A24: E1C80000 00000000
	buffer_gl0_inv                                             // 000000005A2C: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[13:14], v[15:16]                       // 000000005A34: 7DEA1F0D
	s_cbranch_execz 32                                         // 000000005A38: BF880020 <__assert_fail+0x267c>
	s_mov_b32 s11, 0                                           // 000000005A3C: BE8B0380
	s_sleep 1                                                  // 000000005A40: BF8E0001
	s_clause 0x1                                               // 000000005A44: BFA10001
	global_load_dwordx2 v[2:3], v0, s[6:7] offset:40           // 000000005A48: DC348028 02060000
	global_load_dwordx2 v[11:12], v0, s[6:7]                   // 000000005A50: DC348000 0B060000
	v_mov_b32_e32 v15, v13                                     // 000000005A58: 7E1E030D
	v_mov_b32_e32 v16, v14                                     // 000000005A5C: 7E20030E
	s_waitcnt vmcnt(1)                                         // 000000005A60: BF8C3F71
	v_and_b32_e32 v1, v2, v15                                  // 000000005A64: 36021F02
	v_and_b32_e32 v3, v3, v16                                  // 000000005A68: 36062103
	s_waitcnt vmcnt(0)                                         // 000000005A6C: BF8C3F70
	v_mad_u64_u32 v[1:2], null, v1, 24, v[11:12]               // 000000005A70: D5767D01 042D3101
	v_mad_u64_u32 v[2:3], null, v3, 24, v[2:3]                 // 000000005A78: D5767D02 04093103
	global_load_dwordx2 v[13:14], v[1:2], off glc dlc          // 000000005A80: DC359000 0D7D0001
	s_waitcnt vmcnt(0)                                         // 000000005A88: BF8C3F70
	global_atomic_cmpswap_x2 v[13:14], v0, v[13:16], s[6:7] offset:24 glc// 000000005A8C: DD458018 0D060D00
	s_waitcnt vmcnt(0)                                         // 000000005A94: BF8C3F70
	buffer_gl1_inv                                             // 000000005A98: E1C80000 00000000
	buffer_gl0_inv                                             // 000000005AA0: E1C40000 00000000
	v_cmp_eq_u64_e32 vcc_lo, v[13:14], v[15:16]                // 000000005AA8: 7DC41F0D
	s_or_b32 s11, vcc_lo, s11                                  // 000000005AAC: 880B0B6A
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000005AB0: 8A7E0B7E
	s_cbranch_execnz 65506                                     // 000000005AB4: BF89FFE2 <__assert_fail+0x2600>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000005AB8: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000005ABC: 887E0A7E
	s_or_b32 exec_lo, exec_lo, s5                              // 000000005AC0: 887E057E
	s_waitcnt vmcnt(0)                                         // 000000005AC4: BF8C3F70
	v_mov_b32_e32 v12, 0                                       // 000000005AC8: 7E180280
	v_readfirstlane_b32 s11, v14                               // 000000005ACC: 7E16050E
	v_readfirstlane_b32 s10, v13                               // 000000005AD0: 7E14050D
	s_mov_b32 s5, exec_lo                                      // 000000005AD4: BE85037E
	s_clause 0x1                                               // 000000005AD8: BFA10001
	global_load_dwordx2 v[15:16], v12, s[6:7] offset:40        // 000000005ADC: DC348028 0F06000C
	global_load_dwordx4 v[0:3], v12, s[6:7]                    // 000000005AE4: DC388000 0006000C
	s_waitcnt vmcnt(1)                                         // 000000005AEC: BF8C3F71
	v_readfirstlane_b32 s12, v15                               // 000000005AF0: 7E18050F
	v_readfirstlane_b32 s13, v16                               // 000000005AF4: 7E1A0510
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000005AF8: 878C0A0C
	s_mul_i32 s14, s13, 24                                     // 000000005AFC: 930E980D
	s_mul_hi_u32 s15, s12, 24                                  // 000000005B00: 9A8F980C
	s_mul_i32 s16, s12, 24                                     // 000000005B04: 9310980C
	s_add_i32 s15, s15, s14                                    // 000000005B08: 810F0E0F
	s_waitcnt vmcnt(0)                                         // 000000005B0C: BF8C3F70
	v_add_co_u32 v15, vcc_lo, v0, s16                          // 000000005B10: D70F6A0F 02002100
	v_add_co_ci_u32_e64 v16, null, s15, v1, vcc_lo             // 000000005B18: D5287D10 01AA020F
	s_and_saveexec_b32 s14, s4                                 // 000000005B20: BE8E3C04
	s_cbranch_execz 5                                          // 000000005B24: BF880005 <__assert_fail+0x26fc>
	v_mov_b32_e32 v11, s5                                      // 000000005B28: 7E160205
	v_mov_b32_e32 v13, 2                                       // 000000005B2C: 7E1A0282
	v_mov_b32_e32 v14, 1                                       // 000000005B30: 7E1C0281
	global_store_dwordx4 v[15:16], v[11:14], off offset:8      // 000000005B34: DC788008 007D0B0F
	s_or_b32 exec_lo, exec_lo, s14                             // 000000005B3C: 887E0E7E
	s_lshl_b64 s[12:13], s[12:13], 12                          // 000000005B40: 8F8C8C0C
	v_and_or_b32 v9, 0xffffff1f, v9, 32                        // 000000005B44: D7710009 028212FF FFFFFF1F
	v_add_co_u32 v2, vcc_lo, v2, s12                           // 000000005B50: D70F6A02 02001902
	v_add_co_ci_u32_e64 v3, null, s13, v3, vcc_lo              // 000000005B58: D5287D03 01AA060D
	s_mov_b32 s12, 0                                           // 000000005B60: BE8C0380
	v_add_co_u32 v13, vcc_lo, v2, v35                          // 000000005B64: D70F6A0D 02024702
	s_mov_b32 s13, s12                                         // 000000005B6C: BE8D030C
	s_mov_b32 s14, s12                                         // 000000005B70: BE8E030C
	s_mov_b32 s15, s12                                         // 000000005B74: BE8F030C
	v_mov_b32_e32 v11, v4                                      // 000000005B78: 7E160304
	v_readfirstlane_b32 s16, v2                                // 000000005B7C: 7E200502
	v_readfirstlane_b32 s17, v3                                // 000000005B80: 7E220503
	v_add_co_ci_u32_e64 v14, null, 0, v3, vcc_lo               // 000000005B84: D5287D0E 01AA0680
	v_mov_b32_e32 v20, s15                                     // 000000005B8C: 7E28020F
	v_mov_b32_e32 v19, s14                                     // 000000005B90: 7E26020E
	v_mov_b32_e32 v18, s13                                     // 000000005B94: 7E24020D
	v_mov_b32_e32 v17, s12                                     // 000000005B98: 7E22020C
	global_store_dwordx4 v35, v[9:12], s[16:17]                // 000000005B9C: DC788000 00100923
	global_store_dwordx4 v35, v[17:20], s[16:17] offset:16     // 000000005BA4: DC788010 00101123
	global_store_dwordx4 v35, v[17:20], s[16:17] offset:32     // 000000005BAC: DC788020 00101123
	global_store_dwordx4 v35, v[17:20], s[16:17] offset:48     // 000000005BB4: DC788030 00101123
	s_and_saveexec_b32 s5, s4                                  // 000000005BBC: BE853C04
	s_cbranch_execz 78                                         // 000000005BC0: BF88004E <__assert_fail+0x28bc>
	v_mov_b32_e32 v4, 0                                        // 000000005BC4: 7E080280
	v_mov_b32_e32 v17, s10                                     // 000000005BC8: 7E22020A
	v_mov_b32_e32 v18, s11                                     // 000000005BCC: 7E24020B
	s_clause 0x1                                               // 000000005BD0: BFA10001
	global_load_dwordx2 v[19:20], v4, s[6:7] offset:32 glc dlc // 000000005BD4: DC359020 13060004
	global_load_dwordx2 v[2:3], v4, s[6:7] offset:40           // 000000005BDC: DC348028 02060004
	s_waitcnt vmcnt(0)                                         // 000000005BE4: BF8C3F70
	v_readfirstlane_b32 s12, v2                                // 000000005BE8: 7E180502
	v_readfirstlane_b32 s13, v3                                // 000000005BEC: 7E1A0503
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000005BF0: 878C0A0C
	s_mul_i32 s13, s13, 24                                     // 000000005BF4: 930D980D
	s_mul_hi_u32 s14, s12, 24                                  // 000000005BF8: 9A8E980C
	s_mul_i32 s12, s12, 24                                     // 000000005BFC: 930C980C
	s_add_i32 s14, s14, s13                                    // 000000005C00: 810E0D0E
	v_add_co_u32 v9, vcc_lo, v0, s12                           // 000000005C04: D70F6A09 02001900
	v_add_co_ci_u32_e64 v10, null, s14, v1, vcc_lo             // 000000005C0C: D5287D0A 01AA020E
	s_mov_b32 s12, exec_lo                                     // 000000005C14: BE8C037E
	global_store_dwordx2 v[9:10], v[19:20], off                // 000000005C18: DC748000 007D1309
	s_waitcnt_vscnt null, 0x0                                  // 000000005C20: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v4, v[17:20], s[6:7] offset:32 glc// 000000005C24: DD458020 02061104
	s_waitcnt vmcnt(0)                                         // 000000005C2C: BF8C3F70
	v_cmpx_ne_u64_e32 v[2:3], v[19:20]                         // 000000005C30: 7DEA2702
	s_cbranch_execz 16                                         // 000000005C34: BF880010 <__assert_fail+0x2838>
	s_mov_b32 s13, 0                                           // 000000005C38: BE8D0380
	v_mov_b32_e32 v0, s10                                      // 000000005C3C: 7E00020A
	v_mov_b32_e32 v1, s11                                      // 000000005C40: 7E02020B
	s_sleep 1                                                  // 000000005C44: BF8E0001
	global_store_dwordx2 v[9:10], v[2:3], off                  // 000000005C48: DC748000 007D0209
	s_waitcnt_vscnt null, 0x0                                  // 000000005C50: BBFD0000
	global_atomic_cmpswap_x2 v[0:1], v4, v[0:3], s[6:7] offset:32 glc// 000000005C54: DD458020 00060004
	s_waitcnt vmcnt(0)                                         // 000000005C5C: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]                    // 000000005C60: 7DC40500
	v_mov_b32_e32 v3, v1                                       // 000000005C64: 7E060301
	v_mov_b32_e32 v2, v0                                       // 000000005C68: 7E040300
	s_or_b32 s13, vcc_lo, s13                                  // 000000005C6C: 880D0D6A
	s_andn2_b32 exec_lo, exec_lo, s13                          // 000000005C70: 8A7E0D7E
	s_cbranch_execnz 65521                                     // 000000005C74: BF89FFF1 <__assert_fail+0x27fc>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000005C78: 887E0C7E
	v_mov_b32_e32 v3, 0                                        // 000000005C7C: 7E060280
	s_mov_b32 s13, exec_lo                                     // 000000005C80: BE8D037E
	s_mov_b32 s12, exec_lo                                     // 000000005C84: BE8C037E
	v_mbcnt_lo_u32_b32 v2, s13, 0                              // 000000005C88: D7650002 0201000D
	global_load_dwordx2 v[0:1], v3, s[6:7] offset:16           // 000000005C90: DC348010 00060003
	v_cmpx_eq_u32_e32 0, v2                                    // 000000005C98: 7DA40480
	s_cbranch_execz 5                                          // 000000005C9C: BF880005 <__assert_fail+0x2874>
	s_bcnt1_i32_b32 s13, s13                                   // 000000005CA0: BE8D0F0D
	v_mov_b32_e32 v2, s13                                      // 000000005CA4: 7E04020D
	s_waitcnt vmcnt(0)                                         // 000000005CA8: BF8C3F70
	global_atomic_add_x2 v[0:1], v[2:3], off offset:8          // 000000005CAC: DD488008 007D0200
	s_or_b32 exec_lo, exec_lo, s12                             // 000000005CB4: 887E0C7E
	s_waitcnt vmcnt(0)                                         // 000000005CB8: BF8C3F70
	global_load_dwordx2 v[2:3], v[0:1], off offset:16          // 000000005CBC: DC348010 027D0000
	s_waitcnt vmcnt(0)                                         // 000000005CC4: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[2:3]                         // 000000005CC8: 7DC40480
	s_cbranch_vccnz 11                                         // 000000005CCC: BF87000B <__assert_fail+0x28bc>
	global_load_dword v0, v[0:1], off offset:24                // 000000005CD0: DC308018 007D0000
	v_mov_b32_e32 v1, 0                                        // 000000005CD8: 7E020280
	s_waitcnt vmcnt(0)                                         // 000000005CDC: BF8C3F70
	v_readfirstlane_b32 s12, v0                                // 000000005CE0: 7E180500
	s_waitcnt_vscnt null, 0x0                                  // 000000005CE4: BBFD0000
	global_store_dwordx2 v[2:3], v[0:1], off                   // 000000005CE8: DC748000 007D0002
	s_and_b32 m0, s12, 0x7fffff                                // 000000005CF0: 877CFF0C 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 000000005CF8: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 000000005CFC: 887E057E
	s_branch 25                                                // 000000005D00: BF820019 <__assert_fail+0x2928>
	s_nop 0                                                    // 000000005D04: BF800000
	s_nop 0                                                    // 000000005D08: BF800000
	s_nop 0                                                    // 000000005D0C: BF800000
	s_nop 0                                                    // 000000005D10: BF800000
	s_nop 0                                                    // 000000005D14: BF800000
	s_nop 0                                                    // 000000005D18: BF800000
	s_nop 0                                                    // 000000005D1C: BF800000
	s_nop 0                                                    // 000000005D20: BF800000
	s_nop 0                                                    // 000000005D24: BF800000
	s_nop 0                                                    // 000000005D28: BF800000
	s_nop 0                                                    // 000000005D2C: BF800000
	s_nop 0                                                    // 000000005D30: BF800000
	s_nop 0                                                    // 000000005D34: BF800000
	s_nop 0                                                    // 000000005D38: BF800000
	s_nop 0                                                    // 000000005D3C: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000005D40: 887E057E
	v_readfirstlane_b32 s5, v0                                 // 000000005D44: 7E0A0500
	s_cmp_eq_u32 s5, 0                                         // 000000005D48: BF068005
	s_cbranch_scc1 28                                          // 000000005D4C: BF85001C <__assert_fail+0x2980>
	s_mov_b32 s5, 0                                            // 000000005D50: BE850380
	s_sleep 1                                                  // 000000005D54: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000005D58: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 000000005D5C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 000000005D60: BF078105
	s_cbranch_scc0 24                                          // 000000005D64: BF840018 <__assert_fail+0x2988>
	v_mov_b32_e32 v0, 1                                        // 000000005D68: 7E000281
	s_and_saveexec_b32 s5, s4                                  // 000000005D6C: BE853C04
	s_cbranch_execz 65523                                      // 000000005D70: BF88FFF3 <__assert_fail+0x2900>
	global_load_dword v0, v[15:16], off offset:20 glc dlc      // 000000005D74: DC319014 007D000F
	s_waitcnt vmcnt(0)                                         // 000000005D7C: BF8C3F70
	buffer_gl1_inv                                             // 000000005D80: E1C80000 00000000
	buffer_gl0_inv                                             // 000000005D88: E1C40000 00000000
	v_and_b32_e32 v0, 1, v0                                    // 000000005D90: 36000081
	s_branch 65514                                             // 000000005D94: BF82FFEA <__assert_fail+0x2900>
	s_nop 0                                                    // 000000005D98: BF800000
	s_nop 0                                                    // 000000005D9C: BF800000
	s_nop 0                                                    // 000000005DA0: BF800000
	s_nop 0                                                    // 000000005DA4: BF800000
	s_nop 0                                                    // 000000005DA8: BF800000
	s_nop 0                                                    // 000000005DAC: BF800000
	s_nop 0                                                    // 000000005DB0: BF800000
	s_nop 0                                                    // 000000005DB4: BF800000
	s_nop 0                                                    // 000000005DB8: BF800000
	s_nop 0                                                    // 000000005DBC: BF800000
	s_mov_b32 s5, -1                                           // 000000005DC0: BE8503C1
	s_branch 65508                                             // 000000005DC4: BF82FFE4 <__assert_fail+0x2918>
	global_load_dwordx2 v[0:1], v[13:14], off                  // 000000005DC8: DC348000 007D000D
	s_and_saveexec_b32 s12, s4                                 // 000000005DD0: BE8C3C04
	s_cbranch_execz 55                                         // 000000005DD4: BF880037 <__assert_fail+0x2a74>
	v_mov_b32_e32 v4, 0                                        // 000000005DD8: 7E080280
	s_clause 0x2                                               // 000000005DDC: BFA10002
	global_load_dwordx2 v[2:3], v4, s[6:7] offset:40           // 000000005DE0: DC348028 02060004
	global_load_dwordx2 v[13:14], v4, s[6:7] offset:24 glc dlc // 000000005DE8: DC359018 0D060004
	global_load_dwordx2 v[9:10], v4, s[6:7]                    // 000000005DF0: DC348000 09060004
	s_waitcnt vmcnt(2)                                         // 000000005DF8: BF8C3F72
	v_readfirstlane_b32 s14, v2                                // 000000005DFC: 7E1C0502
	v_readfirstlane_b32 s15, v3                                // 000000005E00: 7E1E0503
	s_add_u32 s13, s14, 1                                      // 000000005E04: 800D810E
	s_addc_u32 s16, s15, 0                                     // 000000005E08: 8210800F
	s_add_u32 s4, s13, s10                                     // 000000005E0C: 80040A0D
	s_addc_u32 s5, s16, s11                                    // 000000005E10: 82050B10
	s_cmp_eq_u64 s[4:5], 0                                     // 000000005E14: BF128004
	s_cselect_b32 s5, s16, s5                                  // 000000005E18: 85050510
	s_cselect_b32 s4, s13, s4                                  // 000000005E1C: 8504040D
	v_mov_b32_e32 v12, s5                                      // 000000005E20: 7E180205
	s_and_b64 s[10:11], s[4:5], s[14:15]                       // 000000005E24: 878A0E04
	v_mov_b32_e32 v11, s4                                      // 000000005E28: 7E160204
	s_mul_i32 s11, s11, 24                                     // 000000005E2C: 930B980B
	s_mul_hi_u32 s13, s10, 24                                  // 000000005E30: 9A8D980A
	s_mul_i32 s10, s10, 24                                     // 000000005E34: 930A980A
	s_add_i32 s13, s13, s11                                    // 000000005E38: 810D0B0D
	s_waitcnt vmcnt(0)                                         // 000000005E3C: BF8C3F70
	v_add_co_u32 v2, vcc_lo, v9, s10                           // 000000005E40: D70F6A02 02001509
	v_add_co_ci_u32_e64 v3, null, s13, v10, vcc_lo             // 000000005E48: D5287D03 01AA140D
	global_store_dwordx2 v[2:3], v[13:14], off                 // 000000005E50: DC748000 007D0D02
	s_waitcnt_vscnt null, 0x0                                  // 000000005E58: BBFD0000
	global_atomic_cmpswap_x2 v[11:12], v4, v[11:14], s[6:7] offset:24 glc// 000000005E5C: DD458018 0B060B04
	s_waitcnt vmcnt(0)                                         // 000000005E64: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[11:12], v[13:14]                // 000000005E68: 7DCA1B0B
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000005E6C: 877E6A7E
	s_cbranch_execz 16                                         // 000000005E70: BF880010 <__assert_fail+0x2a74>
	s_mov_b32 s10, 0                                           // 000000005E74: BE8A0380
	v_mov_b32_e32 v9, s4                                       // 000000005E78: 7E120204
	v_mov_b32_e32 v10, s5                                      // 000000005E7C: 7E140205
	s_sleep 1                                                  // 000000005E80: BF8E0001
	global_store_dwordx2 v[2:3], v[11:12], off                 // 000000005E84: DC748000 007D0B02
	s_waitcnt_vscnt null, 0x0                                  // 000000005E8C: BBFD0000
	global_atomic_cmpswap_x2 v[9:10], v4, v[9:12], s[6:7] offset:24 glc// 000000005E90: DD458018 09060904
	s_waitcnt vmcnt(0)                                         // 000000005E98: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[9:10], v[11:12]                 // 000000005E9C: 7DC41709
	v_mov_b32_e32 v12, v10                                     // 000000005EA0: 7E18030A
	v_mov_b32_e32 v11, v9                                      // 000000005EA4: 7E160309
	s_or_b32 s10, vcc_lo, s10                                  // 000000005EA8: 880A0A6A
	s_andn2_b32 exec_lo, exec_lo, s10                          // 000000005EAC: 8A7E0A7E
	s_cbranch_execnz 65521                                     // 000000005EB0: BF89FFF1 <__assert_fail+0x2a38>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000005EB4: 887E0C7E
	v_mov_b32_e32 v2, v5                                       // 000000005EB8: 7E040305
	v_mov_b32_e32 v3, v6                                       // 000000005EBC: 7E060306
	s_mov_b32 s5, 0                                            // 000000005EC0: BE850380
	flat_load_ubyte v4, v[2:3]                                 // 000000005EC4: DC200000 047D0002
	v_add_co_u32 v2, s4, v2, 1                                 // 000000005ECC: D70F0402 02010302
	v_add_co_ci_u32_e64 v3, null, 0, v3, s4                    // 000000005ED4: D5287D03 00120680
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000005EDC: BF8C0070
	v_cmp_eq_u16_e32 vcc_lo, 0, v4                             // 000000005EE0: 7D540880
	s_or_b32 s5, vcc_lo, s5                                    // 000000005EE4: 8805056A
	s_andn2_b32 exec_lo, exec_lo, s5                           // 000000005EE8: 8A7E057E
	s_cbranch_execnz 65525                                     // 000000005EEC: BF89FFF5 <__assert_fail+0x2a84>
	s_or_b32 exec_lo, exec_lo, s5                              // 000000005EF0: 887E057E
	s_mov_b32 s4, exec_lo                                      // 000000005EF4: BE84037E
	v_cmpx_ne_u64_e32 0, v[5:6]                                // 000000005EF8: 7DEA0A80
	s_xor_b32 s14, exec_lo, s4                                 // 000000005EFC: 890E047E
	s_cbranch_execz 701                                        // 000000005F00: BF8802BD <__assert_fail+0x35b8>
	v_sub_nc_u32_e32 v29, v2, v5                               // 000000005F04: 4C3A0B02
	v_and_b32_e32 v4, 2, v0                                    // 000000005F08: 36080082
	v_mov_b32_e32 v10, 0                                       // 000000005F0C: 7E140280
	v_and_b32_e32 v0, -3, v0                                   // 000000005F10: 360000C3
	v_mov_b32_e32 v11, 2                                       // 000000005F14: 7E160282
	v_ashrrev_i32_e32 v30, 31, v29                             // 000000005F18: 303C3A9F
	v_mov_b32_e32 v12, 1                                       // 000000005F1C: 7E180281
	s_mov_b32 s16, 0                                           // 000000005F20: BE900380
	s_mov_b32 s15, 0                                           // 000000005F24: BE8F0380
	s_branch 13                                                // 000000005F28: BF82000D <__assert_fail+0x2b20>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000005F2C: 887E0C7E
	v_sub_co_u32 v29, vcc_lo, v29, v33                         // 000000005F30: D7106A1D 0202431D
	v_sub_co_ci_u32_e64 v30, null, v30, v34, vcc_lo            // 000000005F38: D5297D1E 01AA451E
	v_add_co_u32 v5, s4, v5, v33                               // 000000005F40: D70F0405 02024305
	v_add_co_ci_u32_e64 v6, null, v6, v34, s4                  // 000000005F48: D5287D06 00124506
	v_cmp_eq_u64_e32 vcc_lo, 0, v[29:30]                       // 000000005F50: 7DC43A80
	s_or_b32 s15, vcc_lo, s15                                  // 000000005F54: 880F0F6A
	s_andn2_b32 exec_lo, exec_lo, s15                          // 000000005F58: 8A7E0F7E
	s_cbranch_execz 677                                        // 000000005F5C: BF8802A5 <__assert_fail+0x35b4>
	v_cmp_gt_u64_e32 vcc_lo, 56, v[29:30]                      // 000000005F60: 7DC83AB8
	s_mov_b32 s5, exec_lo                                      // 000000005F64: BE85037E
	v_cndmask_b32_e32 v33, 56, v29, vcc_lo                     // 000000005F68: 02423AB8
	v_cmpx_gt_u64_e32 8, v[29:30]                              // 000000005F6C: 7DE83A88
	s_xor_b32 s5, exec_lo, s5                                  // 000000005F70: 8905057E
	s_cbranch_execz 41                                         // 000000005F74: BF880029 <__assert_fail+0x2bdc>
	s_waitcnt vmcnt(0)                                         // 000000005F78: BF8C3F70
	v_mov_b32_e32 v2, 0                                        // 000000005F7C: 7E040280
	v_mov_b32_e32 v3, 0                                        // 000000005F80: 7E060280
	s_mov_b32 s10, exec_lo                                     // 000000005F84: BE8A037E
	v_cmpx_ne_u64_e32 0, v[29:30]                              // 000000005F88: 7DEA3A80
	s_cbranch_execz 34                                         // 000000005F8C: BF880022 <__assert_fail+0x2bd8>
	v_mov_b32_e32 v2, 0                                        // 000000005F90: 7E040280
	v_mov_b32_e32 v3, 0                                        // 000000005F94: 7E060280
	s_mov_b32 s11, 0                                           // 000000005F98: BE8B0380
	s_mov_b32 s12, 0                                           // 000000005F9C: BE8C0380
	s_nop 0                                                    // 000000005FA0: BF800000
	s_nop 0                                                    // 000000005FA4: BF800000
	s_nop 0                                                    // 000000005FA8: BF800000
	s_nop 0                                                    // 000000005FAC: BF800000
	s_nop 0                                                    // 000000005FB0: BF800000
	s_nop 0                                                    // 000000005FB4: BF800000
	s_nop 0                                                    // 000000005FB8: BF800000
	s_nop 0                                                    // 000000005FBC: BF800000
	v_add_co_u32 v13, s4, v5, s12                              // 000000005FC0: D70F040D 02001905
	v_add_co_ci_u32_e64 v14, null, 0, v6, s4                   // 000000005FC8: D5287D0E 00120C80
	s_lshl_b32 s4, s12, 3                                      // 000000005FD0: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000005FD4: 810C810C
	flat_load_ubyte v9, v[13:14]                               // 000000005FD8: DC200000 097D000D
	v_mov_b32_e32 v14, s16                                     // 000000005FE0: 7E1C0210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000005FE4: BF8C0070
	v_and_b32_e32 v13, 0xffff, v9                              // 000000005FE8: 361A12FF 0000FFFF
	v_lshlrev_b64 v[13:14], s4, v[13:14]                       // 000000005FF0: D6FF000D 02021A04
	v_cmp_eq_u32_e64 s4, s12, v33                              // 000000005FF8: D4C20004 0202420C
	s_or_b32 s11, s4, s11                                      // 000000006000: 880B0B04
	v_or_b32_e32 v3, v14, v3                                   // 000000006004: 3806070E
	v_or_b32_e32 v2, v13, v2                                   // 000000006008: 3804050D
	s_andn2_b32 exec_lo, exec_lo, s11                          // 00000000600C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000006010: BF89FFEB <__assert_fail+0x2b80>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000006014: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000006018: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 00000000601C: BE853D05
	v_mov_b32_e32 v9, 0                                        // 000000006020: 7E120280
	v_mov_b32_e32 v26, v6                                      // 000000006024: 7E340306
	v_mov_b32_e32 v25, v5                                      // 000000006028: 7E320305
	s_xor_b32 exec_lo, exec_lo, s5                             // 00000000602C: 897E057E
	s_cbranch_execz 8                                          // 000000006030: BF880008 <__assert_fail+0x2c14>
	s_waitcnt vmcnt(0)                                         // 000000006034: BF8C3F70
	flat_load_dwordx2 v[2:3], v[5:6]                           // 000000006038: DC340000 027D0005
	v_add_co_u32 v25, s4, v5, 8                                // 000000006040: D70F0419 02011105
	v_add_nc_u32_e32 v9, -8, v33                               // 000000006048: 4A1242C8
	v_add_co_ci_u32_e64 v26, null, 0, v6, s4                   // 00000000604C: D5287D1A 00120C80
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006054: 887E057E
	s_mov_b32 s5, exec_lo                                      // 000000006058: BE85037E
	v_cmpx_gt_u32_e32 8, v9                                    // 00000000605C: 7DA81288
	s_xor_b32 s5, exec_lo, s5                                  // 000000006060: 8905057E
	s_cbranch_execz 45                                         // 000000006064: BF88002D <__assert_fail+0x2cdc>
	v_mov_b32_e32 v13, 0                                       // 000000006068: 7E1A0280
	v_mov_b32_e32 v14, 0                                       // 00000000606C: 7E1C0280
	s_mov_b32 s10, exec_lo                                     // 000000006070: BE8A037E
	v_cmpx_ne_u32_e32 0, v9                                    // 000000006074: 7DAA1280
	s_cbranch_execz 39                                         // 000000006078: BF880027 <__assert_fail+0x2cd8>
	v_mov_b32_e32 v13, 0                                       // 00000000607C: 7E1A0280
	v_mov_b32_e32 v14, 0                                       // 000000006080: 7E1C0280
	s_mov_b32 s11, 0                                           // 000000006084: BE8B0380
	s_mov_b32 s12, 0                                           // 000000006088: BE8C0380
	s_nop 0                                                    // 00000000608C: BF800000
	s_nop 0                                                    // 000000006090: BF800000
	s_nop 0                                                    // 000000006094: BF800000
	s_nop 0                                                    // 000000006098: BF800000
	s_nop 0                                                    // 00000000609C: BF800000
	s_nop 0                                                    // 0000000060A0: BF800000
	s_nop 0                                                    // 0000000060A4: BF800000
	s_nop 0                                                    // 0000000060A8: BF800000
	s_nop 0                                                    // 0000000060AC: BF800000
	s_nop 0                                                    // 0000000060B0: BF800000
	s_nop 0                                                    // 0000000060B4: BF800000
	s_nop 0                                                    // 0000000060B8: BF800000
	s_nop 0                                                    // 0000000060BC: BF800000
	v_add_co_u32 v15, s4, v25, s12                             // 0000000060C0: D70F040F 02001919
	v_add_co_ci_u32_e64 v16, null, 0, v26, s4                  // 0000000060C8: D5287D10 00123480
	s_lshl_b32 s4, s12, 3                                      // 0000000060D0: 8F04830C
	s_add_i32 s12, s12, 1                                      // 0000000060D4: 810C810C
	flat_load_ubyte v15, v[15:16]                              // 0000000060D8: DC200000 0F7D000F
	v_mov_b32_e32 v16, s16                                     // 0000000060E0: 7E200210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000060E4: BF8C0070
	v_and_b32_e32 v15, 0xffff, v15                             // 0000000060E8: 361E1EFF 0000FFFF
	v_lshlrev_b64 v[15:16], s4, v[15:16]                       // 0000000060F0: D6FF000F 02021E04
	v_cmp_eq_u32_e64 s4, s12, v9                               // 0000000060F8: D4C20004 0202120C
	s_or_b32 s11, s4, s11                                      // 000000006100: 880B0B04
	v_or_b32_e32 v14, v16, v14                                 // 000000006104: 381C1D10
	v_or_b32_e32 v13, v15, v13                                 // 000000006108: 381A1B0F
	s_andn2_b32 exec_lo, exec_lo, s11                          // 00000000610C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000006110: BF89FFEB <__assert_fail+0x2c80>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000006114: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000006118: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 00000000611C: BE853D05
	v_mov_b32_e32 v17, 0                                       // 000000006120: 7E220280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000006124: 897E057E
	s_cbranch_execz 7                                          // 000000006128: BF880007 <__assert_fail+0x2d08>
	flat_load_dwordx2 v[13:14], v[25:26]                       // 00000000612C: DC340000 0D7D0019
	v_add_co_u32 v25, s4, v25, 8                               // 000000006134: D70F0419 02011119
	v_add_nc_u32_e32 v17, -8, v9                               // 00000000613C: 4A2212C8
	v_add_co_ci_u32_e64 v26, null, 0, v26, s4                  // 000000006140: D5287D1A 00123480
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006148: 887E057E
	s_mov_b32 s5, exec_lo                                      // 00000000614C: BE85037E
	v_cmpx_gt_u32_e32 8, v17                                   // 000000006150: 7DA82288
	s_xor_b32 s5, exec_lo, s5                                  // 000000006154: 8905057E
	s_cbranch_execz 32                                         // 000000006158: BF880020 <__assert_fail+0x2d9c>
	v_mov_b32_e32 v15, 0                                       // 00000000615C: 7E1E0280
	v_mov_b32_e32 v16, 0                                       // 000000006160: 7E200280
	s_mov_b32 s10, exec_lo                                     // 000000006164: BE8A037E
	v_cmpx_ne_u32_e32 0, v17                                   // 000000006168: 7DAA2280
	s_cbranch_execz 26                                         // 00000000616C: BF88001A <__assert_fail+0x2d98>
	v_mov_b32_e32 v15, 0                                       // 000000006170: 7E1E0280
	v_mov_b32_e32 v16, 0                                       // 000000006174: 7E200280
	s_mov_b32 s11, 0                                           // 000000006178: BE8B0380
	s_mov_b32 s12, 0                                           // 00000000617C: BE8C0380
	v_add_co_u32 v18, s4, v25, s12                             // 000000006180: D70F0412 02001919
	v_add_co_ci_u32_e64 v19, null, 0, v26, s4                  // 000000006188: D5287D13 00123480
	s_lshl_b32 s4, s12, 3                                      // 000000006190: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000006194: 810C810C
	flat_load_ubyte v9, v[18:19]                               // 000000006198: DC200000 097D0012
	v_mov_b32_e32 v19, s16                                     // 0000000061A0: 7E260210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000061A4: BF8C0070
	v_and_b32_e32 v18, 0xffff, v9                              // 0000000061A8: 362412FF 0000FFFF
	v_lshlrev_b64 v[18:19], s4, v[18:19]                       // 0000000061B0: D6FF0012 02022404
	v_cmp_eq_u32_e64 s4, s12, v17                              // 0000000061B8: D4C20004 0202220C
	s_or_b32 s11, s4, s11                                      // 0000000061C0: 880B0B04
	v_or_b32_e32 v16, v19, v16                                 // 0000000061C4: 38202113
	v_or_b32_e32 v15, v18, v15                                 // 0000000061C8: 381E1F12
	s_andn2_b32 exec_lo, exec_lo, s11                          // 0000000061CC: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 0000000061D0: BF89FFEB <__assert_fail+0x2d40>
	s_or_b32 exec_lo, exec_lo, s11                             // 0000000061D4: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 0000000061D8: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 0000000061DC: BE853D05
	v_mov_b32_e32 v9, 0                                        // 0000000061E0: 7E120280
	s_xor_b32 exec_lo, exec_lo, s5                             // 0000000061E4: 897E057E
	s_cbranch_execz 7                                          // 0000000061E8: BF880007 <__assert_fail+0x2dc8>
	flat_load_dwordx2 v[15:16], v[25:26]                       // 0000000061EC: DC340000 0F7D0019
	v_add_co_u32 v25, s4, v25, 8                               // 0000000061F4: D70F0419 02011119
	v_add_nc_u32_e32 v9, -8, v17                               // 0000000061FC: 4A1222C8
	v_add_co_ci_u32_e64 v26, null, 0, v26, s4                  // 000000006200: D5287D1A 00123480
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006208: 887E057E
	s_mov_b32 s5, exec_lo                                      // 00000000620C: BE85037E
	v_cmpx_gt_u32_e32 8, v9                                    // 000000006210: 7DA81288
	s_xor_b32 s5, exec_lo, s5                                  // 000000006214: 8905057E
	s_cbranch_execz 32                                         // 000000006218: BF880020 <__assert_fail+0x2e5c>
	v_mov_b32_e32 v17, 0                                       // 00000000621C: 7E220280
	v_mov_b32_e32 v18, 0                                       // 000000006220: 7E240280
	s_mov_b32 s10, exec_lo                                     // 000000006224: BE8A037E
	v_cmpx_ne_u32_e32 0, v9                                    // 000000006228: 7DAA1280
	s_cbranch_execz 26                                         // 00000000622C: BF88001A <__assert_fail+0x2e58>
	v_mov_b32_e32 v17, 0                                       // 000000006230: 7E220280
	v_mov_b32_e32 v18, 0                                       // 000000006234: 7E240280
	s_mov_b32 s11, 0                                           // 000000006238: BE8B0380
	s_mov_b32 s12, 0                                           // 00000000623C: BE8C0380
	v_add_co_u32 v19, s4, v25, s12                             // 000000006240: D70F0413 02001919
	v_add_co_ci_u32_e64 v20, null, 0, v26, s4                  // 000000006248: D5287D14 00123480
	s_lshl_b32 s4, s12, 3                                      // 000000006250: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000006254: 810C810C
	flat_load_ubyte v19, v[19:20]                              // 000000006258: DC200000 137D0013
	v_mov_b32_e32 v20, s16                                     // 000000006260: 7E280210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000006264: BF8C0070
	v_and_b32_e32 v19, 0xffff, v19                             // 000000006268: 362626FF 0000FFFF
	v_lshlrev_b64 v[19:20], s4, v[19:20]                       // 000000006270: D6FF0013 02022604
	v_cmp_eq_u32_e64 s4, s12, v9                               // 000000006278: D4C20004 0202120C
	s_or_b32 s11, s4, s11                                      // 000000006280: 880B0B04
	v_or_b32_e32 v18, v20, v18                                 // 000000006284: 38242514
	v_or_b32_e32 v17, v19, v17                                 // 000000006288: 38222313
	s_andn2_b32 exec_lo, exec_lo, s11                          // 00000000628C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000006290: BF89FFEB <__assert_fail+0x2e00>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000006294: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000006298: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 00000000629C: BE853D05
	v_mov_b32_e32 v21, 0                                       // 0000000062A0: 7E2A0280
	s_xor_b32 exec_lo, exec_lo, s5                             // 0000000062A4: 897E057E
	s_cbranch_execz 7                                          // 0000000062A8: BF880007 <__assert_fail+0x2e88>
	flat_load_dwordx2 v[17:18], v[25:26]                       // 0000000062AC: DC340000 117D0019
	v_add_co_u32 v25, s4, v25, 8                               // 0000000062B4: D70F0419 02011119
	v_add_nc_u32_e32 v21, -8, v9                               // 0000000062BC: 4A2A12C8
	v_add_co_ci_u32_e64 v26, null, 0, v26, s4                  // 0000000062C0: D5287D1A 00123480
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000062C8: 887E057E
	s_mov_b32 s5, exec_lo                                      // 0000000062CC: BE85037E
	v_cmpx_gt_u32_e32 8, v21                                   // 0000000062D0: 7DA82A88
	s_xor_b32 s5, exec_lo, s5                                  // 0000000062D4: 8905057E
	s_cbranch_execz 32                                         // 0000000062D8: BF880020 <__assert_fail+0x2f1c>
	v_mov_b32_e32 v19, 0                                       // 0000000062DC: 7E260280
	v_mov_b32_e32 v20, 0                                       // 0000000062E0: 7E280280
	s_mov_b32 s10, exec_lo                                     // 0000000062E4: BE8A037E
	v_cmpx_ne_u32_e32 0, v21                                   // 0000000062E8: 7DAA2A80
	s_cbranch_execz 26                                         // 0000000062EC: BF88001A <__assert_fail+0x2f18>
	v_mov_b32_e32 v19, 0                                       // 0000000062F0: 7E260280
	v_mov_b32_e32 v20, 0                                       // 0000000062F4: 7E280280
	s_mov_b32 s11, 0                                           // 0000000062F8: BE8B0380
	s_mov_b32 s12, 0                                           // 0000000062FC: BE8C0380
	v_add_co_u32 v22, s4, v25, s12                             // 000000006300: D70F0416 02001919
	v_add_co_ci_u32_e64 v23, null, 0, v26, s4                  // 000000006308: D5287D17 00123480
	s_lshl_b32 s4, s12, 3                                      // 000000006310: 8F04830C
	s_add_i32 s12, s12, 1                                      // 000000006314: 810C810C
	flat_load_ubyte v9, v[22:23]                               // 000000006318: DC200000 097D0016
	v_mov_b32_e32 v23, s16                                     // 000000006320: 7E2E0210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000006324: BF8C0070
	v_and_b32_e32 v22, 0xffff, v9                              // 000000006328: 362C12FF 0000FFFF
	v_lshlrev_b64 v[22:23], s4, v[22:23]                       // 000000006330: D6FF0016 02022C04
	v_cmp_eq_u32_e64 s4, s12, v21                              // 000000006338: D4C20004 02022A0C
	s_or_b32 s11, s4, s11                                      // 000000006340: 880B0B04
	v_or_b32_e32 v20, v23, v20                                 // 000000006344: 38282917
	v_or_b32_e32 v19, v22, v19                                 // 000000006348: 38262716
	s_andn2_b32 exec_lo, exec_lo, s11                          // 00000000634C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000006350: BF89FFEB <__assert_fail+0x2ec0>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000006354: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000006358: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 00000000635C: BE853D05
	v_mov_b32_e32 v9, 0                                        // 000000006360: 7E120280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000006364: 897E057E
	s_cbranch_execz 7                                          // 000000006368: BF880007 <__assert_fail+0x2f48>
	flat_load_dwordx2 v[19:20], v[25:26]                       // 00000000636C: DC340000 137D0019
	v_add_co_u32 v25, s4, v25, 8                               // 000000006374: D70F0419 02011119
	v_add_nc_u32_e32 v9, -8, v21                               // 00000000637C: 4A122AC8
	v_add_co_ci_u32_e64 v26, null, 0, v26, s4                  // 000000006380: D5287D1A 00123480
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006388: 887E057E
	s_mov_b32 s5, exec_lo                                      // 00000000638C: BE85037E
	v_cmpx_gt_u32_e32 8, v9                                    // 000000006390: 7DA81288
	s_xor_b32 s5, exec_lo, s5                                  // 000000006394: 8905057E
	s_cbranch_execz 32                                         // 000000006398: BF880020 <__assert_fail+0x2fdc>
	v_mov_b32_e32 v21, 0                                       // 00000000639C: 7E2A0280
	v_mov_b32_e32 v22, 0                                       // 0000000063A0: 7E2C0280
	s_mov_b32 s10, exec_lo                                     // 0000000063A4: BE8A037E
	v_cmpx_ne_u32_e32 0, v9                                    // 0000000063A8: 7DAA1280
	s_cbranch_execz 26                                         // 0000000063AC: BF88001A <__assert_fail+0x2fd8>
	v_mov_b32_e32 v21, 0                                       // 0000000063B0: 7E2A0280
	v_mov_b32_e32 v22, 0                                       // 0000000063B4: 7E2C0280
	s_mov_b32 s11, 0                                           // 0000000063B8: BE8B0380
	s_mov_b32 s12, 0                                           // 0000000063BC: BE8C0380
	v_add_co_u32 v23, s4, v25, s12                             // 0000000063C0: D70F0417 02001919
	v_add_co_ci_u32_e64 v24, null, 0, v26, s4                  // 0000000063C8: D5287D18 00123480
	s_lshl_b32 s4, s12, 3                                      // 0000000063D0: 8F04830C
	s_add_i32 s12, s12, 1                                      // 0000000063D4: 810C810C
	flat_load_ubyte v23, v[23:24]                              // 0000000063D8: DC200000 177D0017
	v_mov_b32_e32 v24, s16                                     // 0000000063E0: 7E300210
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000063E4: BF8C0070
	v_and_b32_e32 v23, 0xffff, v23                             // 0000000063E8: 362E2EFF 0000FFFF
	v_lshlrev_b64 v[23:24], s4, v[23:24]                       // 0000000063F0: D6FF0017 02022E04
	v_cmp_eq_u32_e64 s4, s12, v9                               // 0000000063F8: D4C20004 0202120C
	s_or_b32 s11, s4, s11                                      // 000000006400: 880B0B04
	v_or_b32_e32 v22, v24, v22                                 // 000000006404: 382C2D18
	v_or_b32_e32 v21, v23, v21                                 // 000000006408: 382A2B17
	s_andn2_b32 exec_lo, exec_lo, s11                          // 00000000640C: 8A7E0B7E
	s_cbranch_execnz 65515                                     // 000000006410: BF89FFEB <__assert_fail+0x2f80>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000006414: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000006418: 887E0A7E
	s_or_saveexec_b32 s5, s5                                   // 00000000641C: BE853D05
	v_mov_b32_e32 v27, 0                                       // 000000006420: 7E360280
	s_xor_b32 exec_lo, exec_lo, s5                             // 000000006424: 897E057E
	s_cbranch_execz 7                                          // 000000006428: BF880007 <__assert_fail+0x3008>
	flat_load_dwordx2 v[21:22], v[25:26]                       // 00000000642C: DC340000 157D0019
	v_add_co_u32 v25, s4, v25, 8                               // 000000006434: D70F0419 02011119
	v_add_nc_u32_e32 v27, -8, v9                               // 00000000643C: 4A3612C8
	v_add_co_ci_u32_e64 v26, null, 0, v26, s4                  // 000000006440: D5287D1A 00123480
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006448: 887E057E
	s_mov_b32 s5, exec_lo                                      // 00000000644C: BE85037E
	v_cmpx_gt_u32_e32 8, v27                                   // 000000006450: 7DA83688
	s_xor_b32 s5, exec_lo, s5                                  // 000000006454: 8905057E
	s_cbranch_execz 33                                         // 000000006458: BF880021 <__assert_fail+0x30a0>
	v_mov_b32_e32 v23, 0                                       // 00000000645C: 7E2E0280
	v_mov_b32_e32 v24, 0                                       // 000000006460: 7E300280
	s_mov_b32 s12, exec_lo                                     // 000000006464: BE8C037E
	v_cmpx_ne_u32_e32 0, v27                                   // 000000006468: 7DAA3680
	s_cbranch_execz 27                                         // 00000000646C: BF88001B <__assert_fail+0x309c>
	v_mov_b32_e32 v23, 0                                       // 000000006470: 7E2E0280
	v_mov_b32_e32 v24, 0                                       // 000000006474: 7E300280
	s_mov_b64 s[10:11], 0                                      // 000000006478: BE8A0480
	s_mov_b32 s13, 0                                           // 00000000647C: BE8D0380
	flat_load_ubyte v9, v[25:26]                               // 000000006480: DC200000 097D0019
	v_mov_b32_e32 v32, s16                                     // 000000006488: 7E400210
	v_add_nc_u32_e32 v27, -1, v27                              // 00000000648C: 4A3636C1
	v_add_co_u32 v25, s4, v25, 1                               // 000000006490: D70F0419 02010319
	v_add_co_ci_u32_e64 v26, null, 0, v26, s4                  // 000000006498: D5287D1A 00123480
	v_cmp_eq_u32_e64 s4, 0, v27                                // 0000000064A0: D4C20004 02023680
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000064A8: BF8C0070
	v_and_b32_e32 v31, 0xffff, v9                              // 0000000064AC: 363E12FF 0000FFFF
	v_lshlrev_b64 v[31:32], s10, v[31:32]                      // 0000000064B4: D6FF001F 02023E0A
	s_add_u32 s10, s10, 8                                      // 0000000064BC: 800A880A
	s_addc_u32 s11, s11, 0                                     // 0000000064C0: 820B800B
	s_or_b32 s13, s4, s13                                      // 0000000064C4: 880D0D04
	v_or_b32_e32 v24, v32, v24                                 // 0000000064C8: 38303120
	v_or_b32_e32 v23, v31, v23                                 // 0000000064CC: 382E2F1F
	s_andn2_b32 exec_lo, exec_lo, s13                          // 0000000064D0: 8A7E0D7E
	s_cbranch_execnz 65514                                     // 0000000064D4: BF89FFEA <__assert_fail+0x3040>
	s_or_b32 exec_lo, exec_lo, s13                             // 0000000064D8: 887E0D7E
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000064DC: 887E0C7E
	s_andn2_saveexec_b32 s4, s5                                // 0000000064E0: BE843F05
	s_cbranch_execz 2                                          // 0000000064E4: BF880002 <__assert_fail+0x30b0>
	flat_load_dwordx2 v[23:24], v[25:26]                       // 0000000064E8: DC340000 177D0019
	s_or_b32 exec_lo, exec_lo, s4                              // 0000000064F0: 887E047E
	v_readfirstlane_b32 s4, v36                                // 0000000064F4: 7E080524
	v_mov_b32_e32 v31, 0                                       // 0000000064F8: 7E3E0280
	v_mov_b32_e32 v32, 0                                       // 0000000064FC: 7E400280
	v_cmp_eq_u32_e64 s4, s4, v36                               // 000000006500: D4C20004 02024804
	s_and_saveexec_b32 s10, s4                                 // 000000006508: BE8A3C04
	s_cbranch_execz 77                                         // 00000000650C: BF88004D <__assert_fail+0x3204>
	global_load_dwordx2 v[27:28], v10, s[6:7] offset:24 glc dlc// 000000006510: DC359018 1B06000A
	s_waitcnt vmcnt(0)                                         // 000000006518: BF8C3F70
	buffer_gl1_inv                                             // 00000000651C: E1C80000 00000000
	buffer_gl0_inv                                             // 000000006524: E1C40000 00000000
	s_clause 0x1                                               // 00000000652C: BFA10001
	global_load_dwordx2 v[25:26], v10, s[6:7] offset:40        // 000000006530: DC348028 1906000A
	global_load_dwordx2 v[31:32], v10, s[6:7]                  // 000000006538: DC348000 1F06000A
	s_mov_b32 s11, exec_lo                                     // 000000006540: BE8B037E
	s_waitcnt vmcnt(1)                                         // 000000006544: BF8C3F71
	v_and_b32_e32 v9, v26, v28                                 // 000000006548: 3612391A
	v_and_b32_e32 v25, v25, v27                                // 00000000654C: 36323719
	v_mul_lo_u32 v9, v9, 24                                    // 000000006550: D5690009 02013109
	v_mul_hi_u32 v26, v25, 24                                  // 000000006558: D56A001A 02013119
	v_mul_lo_u32 v25, v25, 24                                  // 000000006560: D5690019 02013119
	v_add_nc_u32_e32 v9, v26, v9                               // 000000006568: 4A12131A
	s_waitcnt vmcnt(0)                                         // 00000000656C: BF8C3F70
	v_add_co_u32 v25, s5, v31, v25                             // 000000006570: D70F0519 0202331F
	v_add_co_ci_u32_e64 v26, null, v32, v9, s5                 // 000000006578: D5287D1A 00161320
	global_load_dwordx2 v[25:26], v[25:26], off glc dlc        // 000000006580: DC359000 197D0019
	s_waitcnt vmcnt(0)                                         // 000000006588: BF8C3F70
	global_atomic_cmpswap_x2 v[31:32], v10, v[25:28], s[6:7] offset:24 glc// 00000000658C: DD458018 1F06190A
	s_waitcnt vmcnt(0)                                         // 000000006594: BF8C3F70
	buffer_gl1_inv                                             // 000000006598: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000065A0: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[31:32], v[27:28]                       // 0000000065A8: 7DEA371F
	s_cbranch_execz 36                                         // 0000000065AC: BF880024 <__assert_fail+0x3200>
	s_mov_b32 s12, 0                                           // 0000000065B0: BE8C0380
	s_nop 0                                                    // 0000000065B4: BF800000
	s_nop 0                                                    // 0000000065B8: BF800000
	s_nop 0                                                    // 0000000065BC: BF800000
	s_sleep 1                                                  // 0000000065C0: BF8E0001
	s_clause 0x1                                               // 0000000065C4: BFA10001
	global_load_dwordx2 v[25:26], v10, s[6:7] offset:40        // 0000000065C8: DC348028 1906000A
	global_load_dwordx2 v[37:38], v10, s[6:7]                  // 0000000065D0: DC348000 2506000A
	v_mov_b32_e32 v27, v31                                     // 0000000065D8: 7E36031F
	v_mov_b32_e32 v28, v32                                     // 0000000065DC: 7E380320
	s_waitcnt vmcnt(1)                                         // 0000000065E0: BF8C3F71
	v_and_b32_e32 v9, v25, v27                                 // 0000000065E4: 36123719
	s_waitcnt vmcnt(0)                                         // 0000000065E8: BF8C3F70
	v_mad_u64_u32 v[37:38], null, v9, 24, v[37:38]             // 0000000065EC: D5767D25 04953109
	v_and_b32_e32 v9, v26, v28                                 // 0000000065F4: 3612391A
	v_mad_u64_u32 v[38:39], null, v9, 24, v[38:39]             // 0000000065F8: D5767D26 04993109
	global_load_dwordx2 v[25:26], v[37:38], off glc dlc        // 000000006600: DC359000 197D0025
	s_waitcnt vmcnt(0)                                         // 000000006608: BF8C3F70
	global_atomic_cmpswap_x2 v[31:32], v10, v[25:28], s[6:7] offset:24 glc// 00000000660C: DD458018 1F06190A
	s_waitcnt vmcnt(0)                                         // 000000006614: BF8C3F70
	buffer_gl1_inv                                             // 000000006618: E1C80000 00000000
	buffer_gl0_inv                                             // 000000006620: E1C40000 00000000
	v_cmp_eq_u64_e64 s5, v[31:32], v[27:28]                    // 000000006628: D4E20005 0202371F
	s_or_b32 s12, s5, s12                                      // 000000006630: 880C0C05
	s_andn2_b32 exec_lo, exec_lo, s12                          // 000000006634: 8A7E0C7E
	s_cbranch_execnz 65505                                     // 000000006638: BF89FFE1 <__assert_fail+0x3180>
	s_or_b32 exec_lo, exec_lo, s12                             // 00000000663C: 887E0C7E
	s_or_b32 exec_lo, exec_lo, s11                             // 000000006640: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000006644: 887E0A7E
	s_clause 0x1                                               // 000000006648: BFA10001
	global_load_dwordx2 v[37:38], v10, s[6:7] offset:40        // 00000000664C: DC348028 2506000A
	global_load_dwordx4 v[25:28], v10, s[6:7]                  // 000000006654: DC388000 1906000A
	v_readfirstlane_b32 s11, v32                               // 00000000665C: 7E160520
	v_readfirstlane_b32 s10, v31                               // 000000006660: 7E14051F
	s_mov_b32 s17, exec_lo                                     // 000000006664: BE91037E
	s_waitcnt vmcnt(1)                                         // 000000006668: BF8C3F71
	v_readfirstlane_b32 s12, v37                               // 00000000666C: 7E180525
	v_readfirstlane_b32 s13, v38                               // 000000006670: 7E1A0526
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000006674: 878C0A0C
	s_mul_i32 s5, s13, 24                                      // 000000006678: 9305980D
	s_mul_hi_u32 s18, s12, 24                                  // 00000000667C: 9A92980C
	s_mul_i32 s19, s12, 24                                     // 000000006680: 9313980C
	s_add_i32 s18, s18, s5                                     // 000000006684: 81120512
	s_waitcnt vmcnt(0)                                         // 000000006688: BF8C3F70
	v_add_co_u32 v31, s5, v25, s19                             // 00000000668C: D70F051F 02002719
	v_add_co_ci_u32_e64 v32, null, s18, v26, s5                // 000000006694: D5287D20 00163412
	s_and_saveexec_b32 s5, s4                                  // 00000000669C: BE853C04
	s_cbranch_execz 3                                          // 0000000066A0: BF880003 <__assert_fail+0x3270>
	v_mov_b32_e32 v9, s17                                      // 0000000066A4: 7E120211
	global_store_dwordx4 v[31:32], v[9:12], off offset:8       // 0000000066A8: DC788008 007D091F
	s_or_b32 exec_lo, exec_lo, s5                              // 0000000066B0: 887E057E
	v_cmp_gt_u64_e64 s5, 57, v[29:30]                          // 0000000066B4: D4E40005 02023AB9
	v_and_b32_e32 v0, 0xffffff1f, v0                           // 0000000066BC: 360000FF FFFFFF1F
	s_lshl_b64 s[12:13], s[12:13], 12                          // 0000000066C4: 8F8C8C0C
	v_lshl_add_u32 v37, v33, 2, 28                             // 0000000066C8: D7460025 02710521
	v_cndmask_b32_e32 v34, 0, v30, vcc_lo                      // 0000000066D0: 02443C80
	v_cndmask_b32_e64 v9, 0, v4, s5                            // 0000000066D4: D5010009 00160880
	v_or_b32_e32 v0, v0, v9                                    // 0000000066DC: 38001300
	v_add_co_u32 v9, s5, v27, s12                              // 0000000066E0: D70F0509 0200191B
	v_add_co_ci_u32_e64 v28, null, s13, v28, s5                // 0000000066E8: D5287D1C 0016380D
	v_and_or_b32 v0, 0x1e0, v37, v0                            // 0000000066F0: D7710000 04024AFF 000001E0
	v_add_co_u32 v27, vcc_lo, v9, v35                          // 0000000066FC: D70F6A1B 02024709
	v_readfirstlane_b32 s12, v9                                // 000000006704: 7E180509
	v_readfirstlane_b32 s13, v28                               // 000000006708: 7E1A051C
	v_add_co_ci_u32_e64 v28, null, 0, v28, vcc_lo              // 00000000670C: D5287D1C 01AA3880
	s_waitcnt lgkmcnt(0)                                       // 000000006714: BF8CC07F
	global_store_dwordx4 v35, v[0:3], s[12:13]                 // 000000006718: DC788000 000C0023
	global_store_dwordx4 v35, v[13:16], s[12:13] offset:16     // 000000006720: DC788010 000C0D23
	global_store_dwordx4 v35, v[17:20], s[12:13] offset:32     // 000000006728: DC788020 000C1123
	global_store_dwordx4 v35, v[21:24], s[12:13] offset:48     // 000000006730: DC788030 000C1523
	s_and_saveexec_b32 s5, s4                                  // 000000006738: BE853C04
	s_cbranch_execz 75                                         // 00000000673C: BF88004B <__assert_fail+0x342c>
	s_clause 0x1                                               // 000000006740: BFA10001
	global_load_dwordx2 v[17:18], v10, s[6:7] offset:32 glc dlc// 000000006744: DC359020 1106000A
	global_load_dwordx2 v[0:1], v10, s[6:7] offset:40          // 00000000674C: DC348028 0006000A
	v_mov_b32_e32 v15, s10                                     // 000000006754: 7E1E020A
	v_mov_b32_e32 v16, s11                                     // 000000006758: 7E20020B
	s_waitcnt vmcnt(0)                                         // 00000000675C: BF8C3F70
	v_readfirstlane_b32 s12, v0                                // 000000006760: 7E180500
	v_readfirstlane_b32 s13, v1                                // 000000006764: 7E1A0501
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000006768: 878C0A0C
	s_mul_i32 s13, s13, 24                                     // 00000000676C: 930D980D
	s_mul_hi_u32 s17, s12, 24                                  // 000000006770: 9A91980C
	s_mul_i32 s12, s12, 24                                     // 000000006774: 930C980C
	s_add_i32 s17, s17, s13                                    // 000000006778: 81110D11
	v_add_co_u32 v13, vcc_lo, v25, s12                         // 00000000677C: D70F6A0D 02001919
	v_add_co_ci_u32_e64 v14, null, s17, v26, vcc_lo            // 000000006784: D5287D0E 01AA3411
	s_mov_b32 s12, exec_lo                                     // 00000000678C: BE8C037E
	global_store_dwordx2 v[13:14], v[17:18], off               // 000000006790: DC748000 007D110D
	s_waitcnt_vscnt null, 0x0                                  // 000000006798: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v10, v[15:18], s[6:7] offset:32 glc// 00000000679C: DD458020 02060F0A
	s_waitcnt vmcnt(0)                                         // 0000000067A4: BF8C3F70
	v_cmpx_ne_u64_e32 v[2:3], v[17:18]                         // 0000000067A8: 7DEA2302
	s_cbranch_execz 16                                         // 0000000067AC: BF880010 <__assert_fail+0x33b0>
	s_mov_b32 s13, 0                                           // 0000000067B0: BE8D0380
	v_mov_b32_e32 v0, s10                                      // 0000000067B4: 7E00020A
	v_mov_b32_e32 v1, s11                                      // 0000000067B8: 7E02020B
	s_sleep 1                                                  // 0000000067BC: BF8E0001
	global_store_dwordx2 v[13:14], v[2:3], off                 // 0000000067C0: DC748000 007D020D
	s_waitcnt_vscnt null, 0x0                                  // 0000000067C8: BBFD0000
	global_atomic_cmpswap_x2 v[0:1], v10, v[0:3], s[6:7] offset:32 glc// 0000000067CC: DD458020 0006000A
	s_waitcnt vmcnt(0)                                         // 0000000067D4: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]                    // 0000000067D8: 7DC40500
	v_mov_b32_e32 v3, v1                                       // 0000000067DC: 7E060301
	v_mov_b32_e32 v2, v0                                       // 0000000067E0: 7E040300
	s_or_b32 s13, vcc_lo, s13                                  // 0000000067E4: 880D0D6A
	s_andn2_b32 exec_lo, exec_lo, s13                          // 0000000067E8: 8A7E0D7E
	s_cbranch_execnz 65521                                     // 0000000067EC: BF89FFF1 <__assert_fail+0x3374>
	s_or_b32 exec_lo, exec_lo, s12                             // 0000000067F0: 887E0C7E
	global_load_dwordx2 v[0:1], v10, s[6:7] offset:16          // 0000000067F4: DC348010 0006000A
	s_mov_b32 s13, exec_lo                                     // 0000000067FC: BE8D037E
	s_mov_b32 s12, exec_lo                                     // 000000006800: BE8C037E
	v_mbcnt_lo_u32_b32 v2, s13, 0                              // 000000006804: D7650002 0201000D
	v_cmpx_eq_u32_e32 0, v2                                    // 00000000680C: 7DA40480
	s_cbranch_execz 5                                          // 000000006810: BF880005 <__assert_fail+0x33e8>
	s_bcnt1_i32_b32 s13, s13                                   // 000000006814: BE8D0F0D
	v_mov_b32_e32 v9, s13                                      // 000000006818: 7E12020D
	s_waitcnt vmcnt(0)                                         // 00000000681C: BF8C3F70
	global_atomic_add_x2 v[0:1], v[9:10], off offset:8         // 000000006820: DD488008 007D0900
	s_or_b32 exec_lo, exec_lo, s12                             // 000000006828: 887E0C7E
	s_waitcnt vmcnt(0)                                         // 00000000682C: BF8C3F70
	global_load_dwordx2 v[2:3], v[0:1], off offset:16          // 000000006830: DC348010 027D0000
	s_waitcnt vmcnt(0)                                         // 000000006838: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[2:3]                         // 00000000683C: 7DC40480
	s_cbranch_vccnz 10                                         // 000000006840: BF87000A <__assert_fail+0x342c>
	global_load_dword v9, v[0:1], off offset:24                // 000000006844: DC308018 097D0000
	s_waitcnt vmcnt(0)                                         // 00000000684C: BF8C3F70
	v_readfirstlane_b32 s12, v9                                // 000000006850: 7E180509
	s_waitcnt_vscnt null, 0x0                                  // 000000006854: BBFD0000
	global_store_dwordx2 v[2:3], v[9:10], off                  // 000000006858: DC748000 007D0902
	s_and_b32 m0, s12, 0x7fffff                                // 000000006860: 877CFF0C 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 000000006868: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 00000000686C: 887E057E
	s_branch 13                                                // 000000006870: BF82000D <__assert_fail+0x3468>
	s_nop 0                                                    // 000000006874: BF800000
	s_nop 0                                                    // 000000006878: BF800000
	s_nop 0                                                    // 00000000687C: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006880: 887E057E
	v_readfirstlane_b32 s5, v0                                 // 000000006884: 7E0A0500
	s_cmp_eq_u32 s5, 0                                         // 000000006888: BF068005
	s_cbranch_scc1 28                                          // 00000000688C: BF85001C <__assert_fail+0x34c0>
	s_mov_b32 s5, 0                                            // 000000006890: BE850380
	s_sleep 1                                                  // 000000006894: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000006898: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 00000000689C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 0000000068A0: BF078105
	s_cbranch_scc0 24                                          // 0000000068A4: BF840018 <__assert_fail+0x34c8>
	v_mov_b32_e32 v0, 1                                        // 0000000068A8: 7E000281
	s_and_saveexec_b32 s5, s4                                  // 0000000068AC: BE853C04
	s_cbranch_execz 65523                                      // 0000000068B0: BF88FFF3 <__assert_fail+0x3440>
	global_load_dword v0, v[31:32], off offset:20 glc dlc      // 0000000068B4: DC319014 007D001F
	s_waitcnt vmcnt(0)                                         // 0000000068BC: BF8C3F70
	buffer_gl1_inv                                             // 0000000068C0: E1C80000 00000000
	buffer_gl0_inv                                             // 0000000068C8: E1C40000 00000000
	v_and_b32_e32 v0, 1, v0                                    // 0000000068D0: 36000081
	s_branch 65514                                             // 0000000068D4: BF82FFEA <__assert_fail+0x3440>
	s_nop 0                                                    // 0000000068D8: BF800000
	s_nop 0                                                    // 0000000068DC: BF800000
	s_nop 0                                                    // 0000000068E0: BF800000
	s_nop 0                                                    // 0000000068E4: BF800000
	s_nop 0                                                    // 0000000068E8: BF800000
	s_nop 0                                                    // 0000000068EC: BF800000
	s_nop 0                                                    // 0000000068F0: BF800000
	s_nop 0                                                    // 0000000068F4: BF800000
	s_nop 0                                                    // 0000000068F8: BF800000
	s_nop 0                                                    // 0000000068FC: BF800000
	s_mov_b32 s5, -1                                           // 000000006900: BE8503C1
	s_branch 65508                                             // 000000006904: BF82FFE4 <__assert_fail+0x3458>
	global_load_dwordx4 v[0:3], v[27:28], off                  // 000000006908: DC388000 007D001B
	s_and_saveexec_b32 s12, s4                                 // 000000006910: BE8C3C04
	s_cbranch_execz 64901                                      // 000000006914: BF88FD85 <__assert_fail+0x2aec>
	s_clause 0x2                                               // 000000006918: BFA10002
	global_load_dwordx2 v[2:3], v10, s[6:7] offset:40          // 00000000691C: DC348028 0206000A
	global_load_dwordx2 v[17:18], v10, s[6:7] offset:24 glc dlc// 000000006924: DC359018 1106000A
	global_load_dwordx2 v[13:14], v10, s[6:7]                  // 00000000692C: DC348000 0D06000A
	s_waitcnt vmcnt(2)                                         // 000000006934: BF8C3F72
	v_readfirstlane_b32 s18, v2                                // 000000006938: 7E240502
	v_readfirstlane_b32 s19, v3                                // 00000000693C: 7E260503
	s_add_u32 s13, s18, 1                                      // 000000006940: 800D8112
	s_addc_u32 s17, s19, 0                                     // 000000006944: 82118013
	s_add_u32 s4, s13, s10                                     // 000000006948: 80040A0D
	s_addc_u32 s5, s17, s11                                    // 00000000694C: 82050B11
	s_cmp_eq_u64 s[4:5], 0                                     // 000000006950: BF128004
	s_cselect_b32 s5, s17, s5                                  // 000000006954: 85050511
	s_cselect_b32 s4, s13, s4                                  // 000000006958: 8504040D
	v_mov_b32_e32 v16, s5                                      // 00000000695C: 7E200205
	s_and_b64 s[10:11], s[4:5], s[18:19]                       // 000000006960: 878A1204
	v_mov_b32_e32 v15, s4                                      // 000000006964: 7E1E0204
	s_mul_i32 s11, s11, 24                                     // 000000006968: 930B980B
	s_mul_hi_u32 s13, s10, 24                                  // 00000000696C: 9A8D980A
	s_mul_i32 s10, s10, 24                                     // 000000006970: 930A980A
	s_add_i32 s13, s13, s11                                    // 000000006974: 810D0B0D
	s_waitcnt vmcnt(0)                                         // 000000006978: BF8C3F70
	v_add_co_u32 v2, vcc_lo, v13, s10                          // 00000000697C: D70F6A02 0200150D
	v_add_co_ci_u32_e64 v3, null, s13, v14, vcc_lo             // 000000006984: D5287D03 01AA1C0D
	global_store_dwordx2 v[2:3], v[17:18], off                 // 00000000698C: DC748000 007D1102
	s_waitcnt_vscnt null, 0x0                                  // 000000006994: BBFD0000
	global_atomic_cmpswap_x2 v[15:16], v10, v[15:18], s[6:7] offset:24 glc// 000000006998: DD458018 0F060F0A
	s_waitcnt vmcnt(0)                                         // 0000000069A0: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[15:16], v[17:18]                // 0000000069A4: 7DCA230F
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 0000000069A8: 877E6A7E
	s_cbranch_execz 64863                                      // 0000000069AC: BF88FD5F <__assert_fail+0x2aec>
	s_mov_b32 s10, 0                                           // 0000000069B0: BE8A0380
	v_mov_b32_e32 v13, s4                                      // 0000000069B4: 7E1A0204
	v_mov_b32_e32 v14, s5                                      // 0000000069B8: 7E1C0205
	s_sleep 1                                                  // 0000000069BC: BF8E0001
	global_store_dwordx2 v[2:3], v[15:16], off                 // 0000000069C0: DC748000 007D0F02
	s_waitcnt_vscnt null, 0x0                                  // 0000000069C8: BBFD0000
	global_atomic_cmpswap_x2 v[13:14], v10, v[13:16], s[6:7] offset:24 glc// 0000000069CC: DD458018 0D060D0A
	s_waitcnt vmcnt(0)                                         // 0000000069D4: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[13:14], v[15:16]                // 0000000069D8: 7DC41F0D
	v_mov_b32_e32 v16, v14                                     // 0000000069DC: 7E20030E
	v_mov_b32_e32 v15, v13                                     // 0000000069E0: 7E1E030D
	s_or_b32 s10, vcc_lo, s10                                  // 0000000069E4: 880A0A6A
	s_andn2_b32 exec_lo, exec_lo, s10                          // 0000000069E8: 8A7E0A7E
	s_cbranch_execnz 65521                                     // 0000000069EC: BF89FFF1 <__assert_fail+0x3574>
	s_branch 64846                                             // 0000000069F0: BF82FD4E <__assert_fail+0x2aec>
	s_or_b32 exec_lo, exec_lo, s15                             // 0000000069F4: 887E0F7E
	s_andn2_saveexec_b32 s14, s14                              // 0000000069F8: BE8E3F0E
	s_cbranch_execz 350                                        // 0000000069FC: BF88015E <__assert_fail+0x3b38>
	v_readfirstlane_b32 s4, v36                                // 000000006A00: 7E080524
	v_mov_b32_e32 v4, 0                                        // 000000006A04: 7E080280
	v_mov_b32_e32 v5, 0                                        // 000000006A08: 7E0A0280
	v_cmp_eq_u32_e64 s4, s4, v36                               // 000000006A0C: D4C20004 02024804
	s_and_saveexec_b32 s5, s4                                  // 000000006A14: BE853C04
	s_cbranch_execz 89                                         // 000000006A18: BF880059 <__assert_fail+0x3740>
	s_waitcnt vmcnt(0)                                         // 000000006A1C: BF8C3F70
	v_mov_b32_e32 v2, 0                                        // 000000006A20: 7E040280
	s_mov_b32 s10, exec_lo                                     // 000000006A24: BE8A037E
	global_load_dwordx2 v[11:12], v2, s[6:7] offset:24 glc dlc // 000000006A28: DC359018 0B060002
	s_waitcnt vmcnt(0)                                         // 000000006A30: BF8C3F70
	buffer_gl1_inv                                             // 000000006A34: E1C80000 00000000
	buffer_gl0_inv                                             // 000000006A3C: E1C40000 00000000
	s_clause 0x1                                               // 000000006A44: BFA10001
	global_load_dwordx2 v[3:4], v2, s[6:7] offset:40           // 000000006A48: DC348028 03060002
	global_load_dwordx2 v[5:6], v2, s[6:7]                     // 000000006A50: DC348000 05060002
	s_waitcnt vmcnt(1)                                         // 000000006A58: BF8C3F71
	v_and_b32_e32 v4, v4, v12                                  // 000000006A5C: 36081904
	v_and_b32_e32 v3, v3, v11                                  // 000000006A60: 36061703
	v_mul_lo_u32 v4, v4, 24                                    // 000000006A64: D5690004 02013104
	v_mul_hi_u32 v9, v3, 24                                    // 000000006A6C: D56A0009 02013103
	v_mul_lo_u32 v3, v3, 24                                    // 000000006A74: D5690003 02013103
	v_add_nc_u32_e32 v4, v9, v4                                // 000000006A7C: 4A080909
	s_waitcnt vmcnt(0)                                         // 000000006A80: BF8C3F70
	v_add_co_u32 v3, vcc_lo, v5, v3                            // 000000006A84: D70F6A03 02020705
	v_add_co_ci_u32_e64 v4, null, v6, v4, vcc_lo               // 000000006A8C: D5287D04 01AA0906
	global_load_dwordx2 v[9:10], v[3:4], off glc dlc           // 000000006A94: DC359000 097D0003
	s_waitcnt vmcnt(0)                                         // 000000006A9C: BF8C3F70
	global_atomic_cmpswap_x2 v[4:5], v2, v[9:12], s[6:7] offset:24 glc// 000000006AA0: DD458018 04060902
	s_waitcnt vmcnt(0)                                         // 000000006AA8: BF8C3F70
	buffer_gl1_inv                                             // 000000006AAC: E1C80000 00000000
	buffer_gl0_inv                                             // 000000006AB4: E1C40000 00000000
	v_cmpx_ne_u64_e32 v[4:5], v[11:12]                         // 000000006ABC: 7DEA1704
	s_cbranch_execz 46                                         // 000000006AC0: BF88002E <__assert_fail+0x373c>
	s_mov_b32 s11, 0                                           // 000000006AC4: BE8B0380
	s_nop 0                                                    // 000000006AC8: BF800000
	s_nop 0                                                    // 000000006ACC: BF800000
	s_nop 0                                                    // 000000006AD0: BF800000
	s_nop 0                                                    // 000000006AD4: BF800000
	s_nop 0                                                    // 000000006AD8: BF800000
	s_nop 0                                                    // 000000006ADC: BF800000
	s_nop 0                                                    // 000000006AE0: BF800000
	s_nop 0                                                    // 000000006AE4: BF800000
	s_nop 0                                                    // 000000006AE8: BF800000
	s_nop 0                                                    // 000000006AEC: BF800000
	s_nop 0                                                    // 000000006AF0: BF800000
	s_nop 0                                                    // 000000006AF4: BF800000
	s_nop 0                                                    // 000000006AF8: BF800000
	s_nop 0                                                    // 000000006AFC: BF800000
	s_sleep 1                                                  // 000000006B00: BF8E0001
	s_clause 0x1                                               // 000000006B04: BFA10001
	global_load_dwordx2 v[9:10], v2, s[6:7] offset:40          // 000000006B08: DC348028 09060002
	global_load_dwordx2 v[13:14], v2, s[6:7]                   // 000000006B10: DC348000 0D060002
	v_mov_b32_e32 v11, v4                                      // 000000006B18: 7E160304
	v_mov_b32_e32 v12, v5                                      // 000000006B1C: 7E180305
	s_waitcnt vmcnt(1)                                         // 000000006B20: BF8C3F71
	v_and_b32_e32 v3, v9, v11                                  // 000000006B24: 36061709
	v_and_b32_e32 v5, v10, v12                                 // 000000006B28: 360A190A
	s_waitcnt vmcnt(0)                                         // 000000006B2C: BF8C3F70
	v_mad_u64_u32 v[3:4], null, v3, 24, v[13:14]               // 000000006B30: D5767D03 04353103
	v_mad_u64_u32 v[4:5], null, v5, 24, v[4:5]                 // 000000006B38: D5767D04 04113105
	global_load_dwordx2 v[9:10], v[3:4], off glc dlc           // 000000006B40: DC359000 097D0003
	s_waitcnt vmcnt(0)                                         // 000000006B48: BF8C3F70
	global_atomic_cmpswap_x2 v[4:5], v2, v[9:12], s[6:7] offset:24 glc// 000000006B4C: DD458018 04060902
	s_waitcnt vmcnt(0)                                         // 000000006B54: BF8C3F70
	buffer_gl1_inv                                             // 000000006B58: E1C80000 00000000
	buffer_gl0_inv                                             // 000000006B60: E1C40000 00000000
	v_cmp_eq_u64_e32 vcc_lo, v[4:5], v[11:12]                  // 000000006B68: 7DC41704
	s_or_b32 s11, vcc_lo, s11                                  // 000000006B6C: 880B0B6A
	s_andn2_b32 exec_lo, exec_lo, s11                          // 000000006B70: 8A7E0B7E
	s_cbranch_execnz 65506                                     // 000000006B74: BF89FFE2 <__assert_fail+0x36c0>
	s_or_b32 exec_lo, exec_lo, s11                             // 000000006B78: 887E0B7E
	s_or_b32 exec_lo, exec_lo, s10                             // 000000006B7C: 887E0A7E
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006B80: 887E057E
	s_waitcnt vmcnt(0)                                         // 000000006B84: BF8C3F70
	v_mov_b32_e32 v3, 0                                        // 000000006B88: 7E060280
	v_readfirstlane_b32 s11, v5                                // 000000006B8C: 7E160505
	v_readfirstlane_b32 s10, v4                                // 000000006B90: 7E140504
	s_mov_b32 s5, exec_lo                                      // 000000006B94: BE85037E
	s_clause 0x1                                               // 000000006B98: BFA10001
	global_load_dwordx2 v[13:14], v3, s[6:7] offset:40         // 000000006B9C: DC348028 0D060003
	global_load_dwordx4 v[9:12], v3, s[6:7]                    // 000000006BA4: DC388000 09060003
	s_waitcnt vmcnt(1)                                         // 000000006BAC: BF8C3F71
	v_readfirstlane_b32 s12, v13                               // 000000006BB0: 7E18050D
	v_readfirstlane_b32 s13, v14                               // 000000006BB4: 7E1A050E
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000006BB8: 878C0A0C
	s_mul_i32 s15, s13, 24                                     // 000000006BBC: 930F980D
	s_mul_hi_u32 s16, s12, 24                                  // 000000006BC0: 9A90980C
	s_mul_i32 s17, s12, 24                                     // 000000006BC4: 9311980C
	s_add_i32 s16, s16, s15                                    // 000000006BC8: 81100F10
	s_waitcnt vmcnt(0)                                         // 000000006BCC: BF8C3F70
	v_add_co_u32 v13, vcc_lo, v9, s17                          // 000000006BD0: D70F6A0D 02002309
	v_add_co_ci_u32_e64 v14, null, s16, v10, vcc_lo            // 000000006BD8: D5287D0E 01AA1410
	s_and_saveexec_b32 s15, s4                                 // 000000006BE0: BE8F3C04
	s_cbranch_execz 5                                          // 000000006BE4: BF880005 <__assert_fail+0x37bc>
	v_mov_b32_e32 v2, s5                                       // 000000006BE8: 7E040205
	v_mov_b32_e32 v4, 2                                        // 000000006BEC: 7E080282
	v_mov_b32_e32 v5, 1                                        // 000000006BF0: 7E0A0281
	global_store_dwordx4 v[13:14], v[2:5], off offset:8        // 000000006BF4: DC788008 007D020D
	s_or_b32 exec_lo, exec_lo, s15                             // 000000006BFC: 887E0F7E
	s_lshl_b64 s[12:13], s[12:13], 12                          // 000000006C00: 8F8C8C0C
	s_mov_b32 s16, 0                                           // 000000006C04: BE900380
	v_add_co_u32 v4, vcc_lo, v11, s12                          // 000000006C08: D70F6A04 0200190B
	v_add_co_ci_u32_e64 v5, null, s13, v12, vcc_lo             // 000000006C10: D5287D05 01AA180D
	s_mov_b32 s17, s16                                         // 000000006C18: BE910310
	v_readfirstlane_b32 s12, v4                                // 000000006C1C: 7E180504
	v_add_co_u32 v4, vcc_lo, v4, v35                           // 000000006C20: D70F6A04 02024704
	s_mov_b32 s18, s16                                         // 000000006C28: BE920310
	s_mov_b32 s19, s16                                         // 000000006C2C: BE930310
	v_and_or_b32 v0, 0xffffff1f, v0, 32                        // 000000006C30: D7710000 028200FF FFFFFF1F
	v_mov_b32_e32 v2, s16                                      // 000000006C3C: 7E040210
	v_mov_b32_e32 v3, s16                                      // 000000006C40: 7E060210
	v_readfirstlane_b32 s13, v5                                // 000000006C44: 7E1A0505
	v_add_co_ci_u32_e64 v5, null, 0, v5, vcc_lo                // 000000006C48: D5287D05 01AA0A80
	v_mov_b32_e32 v15, s16                                     // 000000006C50: 7E1E0210
	v_mov_b32_e32 v16, s17                                     // 000000006C54: 7E200211
	v_mov_b32_e32 v17, s18                                     // 000000006C58: 7E220212
	v_mov_b32_e32 v18, s19                                     // 000000006C5C: 7E240213
	global_store_dwordx4 v35, v[0:3], s[12:13]                 // 000000006C60: DC788000 000C0023
	global_store_dwordx4 v35, v[15:18], s[12:13] offset:16     // 000000006C68: DC788010 000C0F23
	global_store_dwordx4 v35, v[15:18], s[12:13] offset:32     // 000000006C70: DC788020 000C0F23
	global_store_dwordx4 v35, v[15:18], s[12:13] offset:48     // 000000006C78: DC788030 000C0F23
	s_and_saveexec_b32 s5, s4                                  // 000000006C80: BE853C04
	s_cbranch_execz 78                                         // 000000006C84: BF88004E <__assert_fail+0x3980>
	v_mov_b32_e32 v6, 0                                        // 000000006C88: 7E0C0280
	v_mov_b32_e32 v15, s10                                     // 000000006C8C: 7E1E020A
	v_mov_b32_e32 v16, s11                                     // 000000006C90: 7E20020B
	s_clause 0x1                                               // 000000006C94: BFA10001
	global_load_dwordx2 v[17:18], v6, s[6:7] offset:32 glc dlc // 000000006C98: DC359020 11060006
	global_load_dwordx2 v[0:1], v6, s[6:7] offset:40           // 000000006CA0: DC348028 00060006
	s_waitcnt vmcnt(0)                                         // 000000006CA8: BF8C3F70
	v_readfirstlane_b32 s12, v0                                // 000000006CAC: 7E180500
	v_readfirstlane_b32 s13, v1                                // 000000006CB0: 7E1A0501
	s_and_b64 s[12:13], s[12:13], s[10:11]                     // 000000006CB4: 878C0A0C
	s_mul_i32 s13, s13, 24                                     // 000000006CB8: 930D980D
	s_mul_hi_u32 s15, s12, 24                                  // 000000006CBC: 9A8F980C
	s_mul_i32 s12, s12, 24                                     // 000000006CC0: 930C980C
	s_add_i32 s15, s15, s13                                    // 000000006CC4: 810F0D0F
	v_add_co_u32 v9, vcc_lo, v9, s12                           // 000000006CC8: D70F6A09 02001909
	v_add_co_ci_u32_e64 v10, null, s15, v10, vcc_lo            // 000000006CD0: D5287D0A 01AA140F
	s_mov_b32 s12, exec_lo                                     // 000000006CD8: BE8C037E
	global_store_dwordx2 v[9:10], v[17:18], off                // 000000006CDC: DC748000 007D1109
	s_waitcnt_vscnt null, 0x0                                  // 000000006CE4: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v6, v[15:18], s[6:7] offset:32 glc// 000000006CE8: DD458020 02060F06
	s_waitcnt vmcnt(0)                                         // 000000006CF0: BF8C3F70
	v_cmpx_ne_u64_e32 v[2:3], v[17:18]                         // 000000006CF4: 7DEA2302
	s_cbranch_execz 16                                         // 000000006CF8: BF880010 <__assert_fail+0x38fc>
	s_mov_b32 s13, 0                                           // 000000006CFC: BE8D0380
	v_mov_b32_e32 v0, s10                                      // 000000006D00: 7E00020A
	v_mov_b32_e32 v1, s11                                      // 000000006D04: 7E02020B
	s_sleep 1                                                  // 000000006D08: BF8E0001
	global_store_dwordx2 v[9:10], v[2:3], off                  // 000000006D0C: DC748000 007D0209
	s_waitcnt_vscnt null, 0x0                                  // 000000006D14: BBFD0000
	global_atomic_cmpswap_x2 v[0:1], v6, v[0:3], s[6:7] offset:32 glc// 000000006D18: DD458020 00060006
	s_waitcnt vmcnt(0)                                         // 000000006D20: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[0:1], v[2:3]                    // 000000006D24: 7DC40500
	v_mov_b32_e32 v3, v1                                       // 000000006D28: 7E060301
	v_mov_b32_e32 v2, v0                                       // 000000006D2C: 7E040300
	s_or_b32 s13, vcc_lo, s13                                  // 000000006D30: 880D0D6A
	s_andn2_b32 exec_lo, exec_lo, s13                          // 000000006D34: 8A7E0D7E
	s_cbranch_execnz 65521                                     // 000000006D38: BF89FFF1 <__assert_fail+0x38c0>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000006D3C: 887E0C7E
	v_mov_b32_e32 v3, 0                                        // 000000006D40: 7E060280
	s_mov_b32 s13, exec_lo                                     // 000000006D44: BE8D037E
	s_mov_b32 s12, exec_lo                                     // 000000006D48: BE8C037E
	v_mbcnt_lo_u32_b32 v2, s13, 0                              // 000000006D4C: D7650002 0201000D
	global_load_dwordx2 v[0:1], v3, s[6:7] offset:16           // 000000006D54: DC348010 00060003
	v_cmpx_eq_u32_e32 0, v2                                    // 000000006D5C: 7DA40480
	s_cbranch_execz 5                                          // 000000006D60: BF880005 <__assert_fail+0x3938>
	s_bcnt1_i32_b32 s13, s13                                   // 000000006D64: BE8D0F0D
	v_mov_b32_e32 v2, s13                                      // 000000006D68: 7E04020D
	s_waitcnt vmcnt(0)                                         // 000000006D6C: BF8C3F70
	global_atomic_add_x2 v[0:1], v[2:3], off offset:8          // 000000006D70: DD488008 007D0200
	s_or_b32 exec_lo, exec_lo, s12                             // 000000006D78: 887E0C7E
	s_waitcnt vmcnt(0)                                         // 000000006D7C: BF8C3F70
	global_load_dwordx2 v[2:3], v[0:1], off offset:16          // 000000006D80: DC348010 027D0000
	s_waitcnt vmcnt(0)                                         // 000000006D88: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, 0, v[2:3]                         // 000000006D8C: 7DC40480
	s_cbranch_vccnz 11                                         // 000000006D90: BF87000B <__assert_fail+0x3980>
	global_load_dword v0, v[0:1], off offset:24                // 000000006D94: DC308018 007D0000
	v_mov_b32_e32 v1, 0                                        // 000000006D9C: 7E020280
	s_waitcnt vmcnt(0)                                         // 000000006DA0: BF8C3F70
	v_readfirstlane_b32 s12, v0                                // 000000006DA4: 7E180500
	s_waitcnt_vscnt null, 0x0                                  // 000000006DA8: BBFD0000
	global_store_dwordx2 v[2:3], v[0:1], off                   // 000000006DAC: DC748000 007D0002
	s_and_b32 m0, s12, 0x7fffff                                // 000000006DB4: 877CFF0C 007FFFFF
	s_sendmsg sendmsg(MSG_INTERRUPT)                           // 000000006DBC: BF900001
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006DC0: 887E057E
	s_branch 24                                                // 000000006DC4: BF820018 <__assert_fail+0x39e8>
	s_nop 0                                                    // 000000006DC8: BF800000
	s_nop 0                                                    // 000000006DCC: BF800000
	s_nop 0                                                    // 000000006DD0: BF800000
	s_nop 0                                                    // 000000006DD4: BF800000
	s_nop 0                                                    // 000000006DD8: BF800000
	s_nop 0                                                    // 000000006DDC: BF800000
	s_nop 0                                                    // 000000006DE0: BF800000
	s_nop 0                                                    // 000000006DE4: BF800000
	s_nop 0                                                    // 000000006DE8: BF800000
	s_nop 0                                                    // 000000006DEC: BF800000
	s_nop 0                                                    // 000000006DF0: BF800000
	s_nop 0                                                    // 000000006DF4: BF800000
	s_nop 0                                                    // 000000006DF8: BF800000
	s_nop 0                                                    // 000000006DFC: BF800000
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006E00: 887E057E
	v_readfirstlane_b32 s5, v0                                 // 000000006E04: 7E0A0500
	s_cmp_eq_u32 s5, 0                                         // 000000006E08: BF068005
	s_cbranch_scc1 28                                          // 000000006E0C: BF85001C <__assert_fail+0x3a40>
	s_mov_b32 s5, 0                                            // 000000006E10: BE850380
	s_sleep 1                                                  // 000000006E14: BF8E0001
	s_and_b32 s5, s5, exec_lo                                  // 000000006E18: 87057E05
	s_cselect_b32 s5, 1, 0                                     // 000000006E1C: 85058081
	s_cmp_lg_u32 s5, 1                                         // 000000006E20: BF078105
	s_cbranch_scc0 24                                          // 000000006E24: BF840018 <__assert_fail+0x3a48>
	v_mov_b32_e32 v0, 1                                        // 000000006E28: 7E000281
	s_and_saveexec_b32 s5, s4                                  // 000000006E2C: BE853C04
	s_cbranch_execz 65523                                      // 000000006E30: BF88FFF3 <__assert_fail+0x39c0>
	global_load_dword v0, v[13:14], off offset:20 glc dlc      // 000000006E34: DC319014 007D000D
	s_waitcnt vmcnt(0)                                         // 000000006E3C: BF8C3F70
	buffer_gl1_inv                                             // 000000006E40: E1C80000 00000000
	buffer_gl0_inv                                             // 000000006E48: E1C40000 00000000
	v_and_b32_e32 v0, 1, v0                                    // 000000006E50: 36000081
	s_branch 65514                                             // 000000006E54: BF82FFEA <__assert_fail+0x39c0>
	s_nop 0                                                    // 000000006E58: BF800000
	s_nop 0                                                    // 000000006E5C: BF800000
	s_nop 0                                                    // 000000006E60: BF800000
	s_nop 0                                                    // 000000006E64: BF800000
	s_nop 0                                                    // 000000006E68: BF800000
	s_nop 0                                                    // 000000006E6C: BF800000
	s_nop 0                                                    // 000000006E70: BF800000
	s_nop 0                                                    // 000000006E74: BF800000
	s_nop 0                                                    // 000000006E78: BF800000
	s_nop 0                                                    // 000000006E7C: BF800000
	s_mov_b32 s5, -1                                           // 000000006E80: BE8503C1
	s_branch 65508                                             // 000000006E84: BF82FFE4 <__assert_fail+0x39d8>
	global_load_dwordx4 v[0:3], v[4:5], off                    // 000000006E88: DC388000 007D0004
	s_and_saveexec_b32 s12, s4                                 // 000000006E90: BE8C3C04
	s_cbranch_execz 55                                         // 000000006E94: BF880037 <__assert_fail+0x3b34>
	v_mov_b32_e32 v6, 0                                        // 000000006E98: 7E0C0280
	s_clause 0x2                                               // 000000006E9C: BFA10002
	global_load_dwordx2 v[2:3], v6, s[6:7] offset:40           // 000000006EA0: DC348028 02060006
	global_load_dwordx2 v[13:14], v6, s[6:7] offset:24 glc dlc // 000000006EA8: DC359018 0D060006
	global_load_dwordx2 v[4:5], v6, s[6:7]                     // 000000006EB0: DC348000 04060006
	s_waitcnt vmcnt(2)                                         // 000000006EB8: BF8C3F72
	v_readfirstlane_b32 s16, v2                                // 000000006EBC: 7E200502
	v_readfirstlane_b32 s17, v3                                // 000000006EC0: 7E220503
	s_add_u32 s13, s16, 1                                      // 000000006EC4: 800D8110
	s_addc_u32 s15, s17, 0                                     // 000000006EC8: 820F8011
	s_add_u32 s4, s13, s10                                     // 000000006ECC: 80040A0D
	s_addc_u32 s5, s15, s11                                    // 000000006ED0: 82050B0F
	s_cmp_eq_u64 s[4:5], 0                                     // 000000006ED4: BF128004
	s_cselect_b32 s5, s15, s5                                  // 000000006ED8: 8505050F
	s_cselect_b32 s4, s13, s4                                  // 000000006EDC: 8504040D
	v_mov_b32_e32 v12, s5                                      // 000000006EE0: 7E180205
	s_and_b64 s[10:11], s[4:5], s[16:17]                       // 000000006EE4: 878A1004
	v_mov_b32_e32 v11, s4                                      // 000000006EE8: 7E160204
	s_mul_i32 s11, s11, 24                                     // 000000006EEC: 930B980B
	s_mul_hi_u32 s13, s10, 24                                  // 000000006EF0: 9A8D980A
	s_mul_i32 s10, s10, 24                                     // 000000006EF4: 930A980A
	s_add_i32 s13, s13, s11                                    // 000000006EF8: 810D0B0D
	s_waitcnt vmcnt(0)                                         // 000000006EFC: BF8C3F70
	v_add_co_u32 v9, vcc_lo, v4, s10                           // 000000006F00: D70F6A09 02001504
	v_add_co_ci_u32_e64 v10, null, s13, v5, vcc_lo             // 000000006F08: D5287D0A 01AA0A0D
	global_store_dwordx2 v[9:10], v[13:14], off                // 000000006F10: DC748000 007D0D09
	s_waitcnt_vscnt null, 0x0                                  // 000000006F18: BBFD0000
	global_atomic_cmpswap_x2 v[4:5], v6, v[11:14], s[6:7] offset:24 glc// 000000006F1C: DD458018 04060B06
	s_waitcnt vmcnt(0)                                         // 000000006F24: BF8C3F70
	v_cmp_ne_u64_e32 vcc_lo, v[4:5], v[13:14]                  // 000000006F28: 7DCA1B04
	s_and_b32 exec_lo, exec_lo, vcc_lo                         // 000000006F2C: 877E6A7E
	s_cbranch_execz 16                                         // 000000006F30: BF880010 <__assert_fail+0x3b34>
	s_mov_b32 s10, 0                                           // 000000006F34: BE8A0380
	v_mov_b32_e32 v2, s4                                       // 000000006F38: 7E040204
	v_mov_b32_e32 v3, s5                                       // 000000006F3C: 7E060205
	s_sleep 1                                                  // 000000006F40: BF8E0001
	global_store_dwordx2 v[9:10], v[4:5], off                  // 000000006F44: DC748000 007D0409
	s_waitcnt_vscnt null, 0x0                                  // 000000006F4C: BBFD0000
	global_atomic_cmpswap_x2 v[2:3], v6, v[2:5], s[6:7] offset:24 glc// 000000006F50: DD458018 02060206
	s_waitcnt vmcnt(0)                                         // 000000006F58: BF8C3F70
	v_cmp_eq_u64_e32 vcc_lo, v[2:3], v[4:5]                    // 000000006F5C: 7DC40902
	v_mov_b32_e32 v5, v3                                       // 000000006F60: 7E0A0303
	v_mov_b32_e32 v4, v2                                       // 000000006F64: 7E080302
	s_or_b32 s10, vcc_lo, s10                                  // 000000006F68: 880A0A6A
	s_andn2_b32 exec_lo, exec_lo, s10                          // 000000006F6C: 8A7E0A7E
	s_cbranch_execnz 65521                                     // 000000006F70: BF89FFF1 <__assert_fail+0x3af8>
	s_or_b32 exec_lo, exec_lo, s12                             // 000000006F74: 887E0C7E
	s_or_b32 exec_lo, exec_lo, s14                             // 000000006F78: 887E0E7E
	s_waitcnt vmcnt(0)                                         // 000000006F7C: BF8C3F70
	v_mov_b32_e32 v2, v7                                       // 000000006F80: 7E040307
	v_mov_b32_e32 v3, v8                                       // 000000006F84: 7E060308
	s_mov_b32 s5, 0                                            // 000000006F88: BE850380
	flat_load_ubyte v4, v[2:3]                                 // 000000006F8C: DC200000 047D0002
	v_add_co_u32 v2, s4, v2, 1                                 // 000000006F94: D70F0402 02010302
	v_add_co_ci_u32_e64 v3, null, 0, v3, s4                    // 000000006F9C: D5287D03 00120680
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000006FA4: BF8C0070
	v_cmp_eq_u16_e32 vcc_lo, 0, v4                             // 000000006FA8: 7D540880
	s_or_b32 s5, vcc_lo, s5                                    // 000000006FAC: 8805056A
	s_andn2_b32 exec_lo, exec_lo, s5                           // 000000006FB0: 8A7E057E
	s_cbranch_execnz 65525                                     // 000000006FB4: BF89FFF5 <__assert_fail+0x3b4c>
	s_or_b32 exec_lo, exec_lo, s5                              // 000000006FB8: 887E057E
	v_sub_nc_u32_e32 v4, v2, v7                                // 000000006FBC: 4C080F02
	v_mov_b32_e32 v2, v7                                       // 000000006FC0: 7E040307
	v_mov_b32_e32 v3, v8                                       // 000000006FC4: 7E060308
	s_getpc_b64 s[4:5]                                         // 000000006FC8: BE841F00
	s_add_u32 s4, s4, 0xffffb3b4                               // 000000006FCC: 8004FF04 FFFFB3B4
	s_addc_u32 s5, s5, lit(0xffffffff)                         // 000000006FD4: 8205FF05 FFFFFFFF
	v_ashrrev_i32_e32 v5, 31, v4                               // 000000006FDC: 300A089F
	s_swappc_b64 s[30:31], s[4:5]                              // 000000006FE0: BE9E2104
	s_trap 2                                                   // 000000006FE4: BF920002
	s_nop 0                                                    // 000000006FE8: BF800000
	s_nop 0                                                    // 000000006FEC: BF800000
	s_nop 0                                                    // 000000006FF0: BF800000
	s_nop 0                                                    // 000000006FF4: BF800000
	s_nop 0                                                    // 000000006FF8: BF800000
	s_nop 0                                                    // 000000006FFC: BF800000

0000000000007000 <__assertfail>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000007000: BF8C0000
	s_trap 2                                                   // 000000007004: BF920002
	s_nop 0                                                    // 000000007008: BF800000
	s_nop 0                                                    // 00000000700C: BF800000
	s_nop 0                                                    // 000000007010: BF800000
	s_nop 0                                                    // 000000007014: BF800000
	s_nop 0                                                    // 000000007018: BF800000
	s_nop 0                                                    // 00000000701C: BF800000
	s_nop 0                                                    // 000000007020: BF800000
	s_nop 0                                                    // 000000007024: BF800000
	s_nop 0                                                    // 000000007028: BF800000
	s_nop 0                                                    // 00000000702C: BF800000
	s_nop 0                                                    // 000000007030: BF800000
	s_nop 0                                                    // 000000007034: BF800000
	s_nop 0                                                    // 000000007038: BF800000
	s_nop 0                                                    // 00000000703C: BF800000

0000000000007040 <_ZN4mori5shmem14device_add_oneEPjPKji>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000007040: BF8C0000
	v_and_b32_e32 v5, 0x3ff, v31                               // 000000007044: 360A3EFF 000003FF
	s_mov_b32 s5, exec_lo                                      // 00000000704C: BE85037E
	v_cmpx_lt_i32_e32 v5, v4                                   // 000000007050: 7D220905
	s_cbranch_execz 48                                         // 000000007054: BF880030 <_ZN4mori5shmem14device_add_oneEPjPKji+0xd8>
	v_mov_b32_e32 v6, 0                                        // 000000007058: 7E0C0280
	s_getpc_b64 s[6:7]                                         // 00000000705C: BE861F00
	s_add_u32 s6, s6, 0x2458                                   // 000000007060: 8006FF06 00002458
	s_addc_u32 s7, s7, lit(0x0)                                // 000000007068: 8207FF07 00000000
	s_load_dword s4, s[8:9], 0xc                               // 000000007070: F4000104 FA00000C
	global_load_dword v7, v6, s[6:7]                           // 000000007078: DC308000 07060006
	s_mov_b32 s7, 0                                            // 000000007080: BE870380
	s_waitcnt lgkmcnt(0)                                       // 000000007084: BF8CC07F
	s_and_b32 s6, s4, 0xffff                                   // 000000007088: 8706FF04 0000FFFF
	s_nop 0                                                    // 000000007090: BF800000
	s_nop 0                                                    // 000000007094: BF800000
	s_nop 0                                                    // 000000007098: BF800000
	s_nop 0                                                    // 00000000709C: BF800000
	s_nop 0                                                    // 0000000070A0: BF800000
	s_nop 0                                                    // 0000000070A4: BF800000
	s_nop 0                                                    // 0000000070A8: BF800000
	s_nop 0                                                    // 0000000070AC: BF800000
	s_nop 0                                                    // 0000000070B0: BF800000
	s_nop 0                                                    // 0000000070B4: BF800000
	s_nop 0                                                    // 0000000070B8: BF800000
	s_nop 0                                                    // 0000000070BC: BF800000
	v_ashrrev_i32_e32 v6, 31, v5                               // 0000000070C0: 300C0A9F
	v_lshlrev_b64 v[8:9], 2, v[5:6]                            // 0000000070C4: D6FF0008 02020A82
	v_add_nc_u32_e32 v5, s6, v5                                // 0000000070CC: 4A0A0A06
	v_add_co_u32 v10, vcc_lo, v2, v8                           // 0000000070D0: D70F6A0A 02021102
	v_add_co_ci_u32_e64 v11, null, v3, v9, vcc_lo              // 0000000070D8: D5287D0B 01AA1303
	v_cmp_ge_i32_e32 vcc_lo, v5, v4                            // 0000000070E0: 7D0C0905
	v_add_co_u32 v8, s4, v0, v8                                // 0000000070E4: D70F0408 02021100
	flat_load_dword v6, v[10:11]                               // 0000000070EC: DC300000 067D000A
	v_add_co_ci_u32_e64 v9, null, v1, v9, s4                   // 0000000070F4: D5287D09 00121301
	s_or_b32 s7, vcc_lo, s7                                    // 0000000070FC: 8807076A
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 000000007100: BF8C0070
	v_add_nc_u32_e32 v6, v6, v7                                // 000000007104: 4A0C0F06
	flat_store_dword v[8:9], v6                                // 000000007108: DC700000 007D0608
	s_andn2_b32 exec_lo, exec_lo, s7                           // 000000007110: 8A7E077E
	s_cbranch_execnz 65514                                     // 000000007114: BF89FFEA <_ZN4mori5shmem14device_add_oneEPjPKji+0x80>
	s_or_b32 exec_lo, exec_lo, s5                              // 000000007118: 887E057E
	s_waitcnt lgkmcnt(0)                                       // 00000000711C: BF8CC07F
	s_setpc_b64 s[30:31]                                       // 000000007120: BE80201E
	s_nop 0                                                    // 000000007124: BF800000
	s_nop 0                                                    // 000000007128: BF800000
	s_nop 0                                                    // 00000000712C: BF800000
	s_nop 0                                                    // 000000007130: BF800000
	s_nop 0                                                    // 000000007134: BF800000
	s_nop 0                                                    // 000000007138: BF800000
	s_nop 0                                                    // 00000000713C: BF800000
	s_nop 0                                                    // 000000007140: BF800000
	s_nop 0                                                    // 000000007144: BF800000
	s_nop 0                                                    // 000000007148: BF800000
	s_nop 0                                                    // 00000000714C: BF800000
	s_nop 0                                                    // 000000007150: BF800000
	s_nop 0                                                    // 000000007154: BF800000
	s_nop 0                                                    // 000000007158: BF800000
	s_nop 0                                                    // 00000000715C: BF800000
	s_nop 0                                                    // 000000007160: BF800000
	s_nop 0                                                    // 000000007164: BF800000
	s_nop 0                                                    // 000000007168: BF800000
	s_nop 0                                                    // 00000000716C: BF800000
	s_nop 0                                                    // 000000007170: BF800000
	s_nop 0                                                    // 000000007174: BF800000
	s_nop 0                                                    // 000000007178: BF800000
	s_nop 0                                                    // 00000000717C: BF800000
	s_nop 0                                                    // 000000007180: BF800000
	s_nop 0                                                    // 000000007184: BF800000
	s_nop 0                                                    // 000000007188: BF800000
	s_nop 0                                                    // 00000000718C: BF800000
	s_nop 0                                                    // 000000007190: BF800000
	s_nop 0                                                    // 000000007194: BF800000
	s_nop 0                                                    // 000000007198: BF800000
	s_nop 0                                                    // 00000000719C: BF800000
	s_nop 0                                                    // 0000000071A0: BF800000
	s_nop 0                                                    // 0000000071A4: BF800000
	s_nop 0                                                    // 0000000071A8: BF800000
	s_nop 0                                                    // 0000000071AC: BF800000
	s_nop 0                                                    // 0000000071B0: BF800000
	s_nop 0                                                    // 0000000071B4: BF800000
	s_nop 0                                                    // 0000000071B8: BF800000
	s_nop 0                                                    // 0000000071BC: BF800000
	s_nop 0                                                    // 0000000071C0: BF800000
	s_nop 0                                                    // 0000000071C4: BF800000
	s_nop 0                                                    // 0000000071C8: BF800000
	s_nop 0                                                    // 0000000071CC: BF800000
	s_nop 0                                                    // 0000000071D0: BF800000
	s_nop 0                                                    // 0000000071D4: BF800000
	s_nop 0                                                    // 0000000071D8: BF800000
	s_nop 0                                                    // 0000000071DC: BF800000
	s_nop 0                                                    // 0000000071E0: BF800000
	s_nop 0                                                    // 0000000071E4: BF800000
	s_nop 0                                                    // 0000000071E8: BF800000
	s_nop 0                                                    // 0000000071EC: BF800000
	s_nop 0                                                    // 0000000071F0: BF800000
	s_nop 0                                                    // 0000000071F4: BF800000
	s_nop 0                                                    // 0000000071F8: BF800000
	s_nop 0                                                    // 0000000071FC: BF800000

0000000000007200 <consumer_kernel>:
	s_clause 0x1                                               // 000000007200: BFA10001
	s_load_dwordx4 s[12:15], s[4:5], null                      // 000000007204: F4080302 FA000000
	s_load_dword s6, s[4:5], 0x10                              // 00000000720C: F4000182 FA000010
	s_add_u32 s0, s0, s7                                       // 000000007214: 80000700
	s_addc_u32 s1, s1, 0                                       // 000000007218: 82018001
	v_mov_b32_e32 v31, v0                                      // 00000000721C: 7E3E0300
	s_add_u32 s8, s4, 24                                       // 000000007220: 80089804
	s_addc_u32 s9, s5, 0                                       // 000000007224: 82098005
	s_getpc_b64 s[4:5]                                         // 000000007228: BE841F00
	s_add_u32 s4, s4, 0xfffffe14                               // 00000000722C: 8004FF04 FFFFFE14
	s_addc_u32 s5, s5, lit(0xffffffff)                         // 000000007234: 8205FF05 FFFFFFFF
	s_mov_b32 s32, 0                                           // 00000000723C: BEA00380
	s_waitcnt lgkmcnt(0)                                       // 000000007240: BF8CC07F
	v_mov_b32_e32 v0, s12                                      // 000000007244: 7E00020C
	v_mov_b32_e32 v1, s13                                      // 000000007248: 7E02020D
	v_mov_b32_e32 v2, s14                                      // 00000000724C: 7E04020E
	v_mov_b32_e32 v3, s15                                      // 000000007250: 7E06020F
	v_mov_b32_e32 v4, s6                                       // 000000007254: 7E080206
	s_swappc_b64 s[30:31], s[4:5]                              // 000000007258: BE9E2104
	s_endpgm                                                   // 00000000725C: BF810000
	s_nop 0                                                    // 000000007260: BF800000
	s_nop 0                                                    // 000000007264: BF800000
	s_nop 0                                                    // 000000007268: BF800000
	s_nop 0                                                    // 00000000726C: BF800000
	s_nop 0                                                    // 000000007270: BF800000
	s_nop 0                                                    // 000000007274: BF800000
	s_nop 0                                                    // 000000007278: BF800000
	s_nop 0                                                    // 00000000727C: BF800000

0000000000007280 <_ZN4mori5shmem11device_pickEPKji>:
	s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)                    // 000000007280: BF8C0000
	v_ashrrev_i32_e32 v3, 31, v2                               // 000000007284: 3006049F
	v_mov_b32_e32 v4, 0                                        // 000000007288: 7E080280
	s_getpc_b64 s[4:5]                                         // 00000000728C: BE841F00
	s_add_u32 s4, s4, 0x2228                                   // 000000007290: 8004FF04 00002228
	s_addc_u32 s5, s5, lit(0x0)                                // 000000007298: 8205FF05 00000000
	v_lshlrev_b64 v[2:3], 2, v[2:3]                            // 0000000072A0: D6FF0002 02020482
	v_add_co_u32 v0, vcc_lo, v0, v2                            // 0000000072A8: D70F6A00 02020500
	v_add_co_ci_u32_e64 v1, null, v1, v3, vcc_lo               // 0000000072B0: D5287D01 01AA0701
	flat_load_dword v0, v[0:1]                                 // 0000000072B8: DC300000 007D0000
	global_load_dword v1, v4, s[4:5]                           // 0000000072C0: DC308000 01040004
	s_waitcnt vmcnt(0) lgkmcnt(0)                              // 0000000072C8: BF8C0070
	v_add_nc_u32_e32 v0, v0, v1                                // 0000000072CC: 4A000300
	s_setpc_b64 s[30:31]                                       // 0000000072D0: BE80201E
	s_nop 0                                                    // 0000000072D4: BF800000
	s_nop 0                                                    // 0000000072D8: BF800000
	s_nop 0                                                    // 0000000072DC: BF800000
	s_nop 0                                                    // 0000000072E0: BF800000
	s_nop 0                                                    // 0000000072E4: BF800000
	s_nop 0                                                    // 0000000072E8: BF800000
	s_nop 0                                                    // 0000000072EC: BF800000
	s_nop 0                                                    // 0000000072F0: BF800000
	s_nop 0                                                    // 0000000072F4: BF800000
	s_nop 0                                                    // 0000000072F8: BF800000
	s_nop 0                                                    // 0000000072FC: BF800000

0000000000007300 <shmem_internal_test_kernel>:
	s_clause 0x1                                               // 000000007300: BFA10001
	s_load_dwordx4 s[12:15], s[4:5], null                      // 000000007304: F4080302 FA000000
	s_load_dword s6, s[4:5], 0x10                              // 00000000730C: F4000182 FA000010
	s_add_u32 s0, s0, s7                                       // 000000007314: 80000700
	s_addc_u32 s1, s1, 0                                       // 000000007318: 82018001
	v_mov_b32_e32 v31, v0                                      // 00000000731C: 7E3E0300
	s_add_u32 s8, s4, 24                                       // 000000007320: 80089804
	s_addc_u32 s9, s5, 0                                       // 000000007324: 82098005
	s_getpc_b64 s[4:5]                                         // 000000007328: BE841F00
	s_add_u32 s4, s4, 0xfffffd14                               // 00000000732C: 8004FF04 FFFFFD14
	s_addc_u32 s5, s5, lit(0xffffffff)                         // 000000007334: 8205FF05 FFFFFFFF
	s_mov_b32 s32, 0                                           // 00000000733C: BEA00380
	s_waitcnt lgkmcnt(0)                                       // 000000007340: BF8CC07F
	v_mov_b32_e32 v0, s12                                      // 000000007344: 7E00020C
	v_mov_b32_e32 v1, s13                                      // 000000007348: 7E02020D
	v_mov_b32_e32 v2, s14                                      // 00000000734C: 7E04020E
	v_mov_b32_e32 v3, s15                                      // 000000007350: 7E06020F
	v_mov_b32_e32 v4, s6                                       // 000000007354: 7E080206
	s_swappc_b64 s[30:31], s[4:5]                              // 000000007358: BE9E2104
	s_endpgm                                                   // 00000000735C: BF810000
	s_code_end                                                 // 000000007360: BF9F0000
	s_code_end                                                 // 000000007364: BF9F0000
	s_code_end                                                 // 000000007368: BF9F0000
	s_code_end                                                 // 00000000736C: BF9F0000
	s_code_end                                                 // 000000007370: BF9F0000
	s_code_end                                                 // 000000007374: BF9F0000
	s_code_end                                                 // 000000007378: BF9F0000
	s_code_end                                                 // 00000000737C: BF9F0000
	s_code_end                                                 // 000000007380: BF9F0000
	s_code_end                                                 // 000000007384: BF9F0000
	s_code_end                                                 // 000000007388: BF9F0000
	s_code_end                                                 // 00000000738C: BF9F0000
	s_code_end                                                 // 000000007390: BF9F0000
	s_code_end                                                 // 000000007394: BF9F0000
	s_code_end                                                 // 000000007398: BF9F0000
	s_code_end                                                 // 00000000739C: BF9F0000
	s_code_end                                                 // 0000000073A0: BF9F0000
	s_code_end                                                 // 0000000073A4: BF9F0000
	s_code_end                                                 // 0000000073A8: BF9F0000
	s_code_end                                                 // 0000000073AC: BF9F0000
	s_code_end                                                 // 0000000073B0: BF9F0000
	s_code_end                                                 // 0000000073B4: BF9F0000
	s_code_end                                                 // 0000000073B8: BF9F0000
	s_code_end                                                 // 0000000073BC: BF9F0000
	s_code_end                                                 // 0000000073C0: BF9F0000
	s_code_end                                                 // 0000000073C4: BF9F0000
	s_code_end                                                 // 0000000073C8: BF9F0000
	s_code_end                                                 // 0000000073CC: BF9F0000
	s_code_end                                                 // 0000000073D0: BF9F0000
	s_code_end                                                 // 0000000073D4: BF9F0000
	s_code_end                                                 // 0000000073D8: BF9F0000
	s_code_end                                                 // 0000000073DC: BF9F0000
	s_code_end                                                 // 0000000073E0: BF9F0000
	s_code_end                                                 // 0000000073E4: BF9F0000
	s_code_end                                                 // 0000000073E8: BF9F0000
	s_code_end                                                 // 0000000073EC: BF9F0000
	s_code_end                                                 // 0000000073F0: BF9F0000
	s_code_end                                                 // 0000000073F4: BF9F0000
	s_code_end                                                 // 0000000073F8: BF9F0000
	s_code_end                                                 // 0000000073FC: BF9F0000
	s_code_end                                                 // 000000007400: BF9F0000
	s_code_end                                                 // 000000007404: BF9F0000
	s_code_end                                                 // 000000007408: BF9F0000
	s_code_end                                                 // 00000000740C: BF9F0000
	s_code_end                                                 // 000000007410: BF9F0000
	s_code_end                                                 // 000000007414: BF9F0000
	s_code_end                                                 // 000000007418: BF9F0000
	s_code_end                                                 // 00000000741C: BF9F0000
	s_code_end                                                 // 000000007420: BF9F0000
	s_code_end                                                 // 000000007424: BF9F0000
	s_code_end                                                 // 000000007428: BF9F0000
	s_code_end                                                 // 00000000742C: BF9F0000
	s_code_end                                                 // 000000007430: BF9F0000
	s_code_end                                                 // 000000007434: BF9F0000
	s_code_end                                                 // 000000007438: BF9F0000
	s_code_end                                                 // 00000000743C: BF9F0000
