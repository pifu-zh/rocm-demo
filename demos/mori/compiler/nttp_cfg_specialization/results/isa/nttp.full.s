
/home/zhuo/workspace/src/rocm-demo/demos/mori/compiler/nttp_cfg_specialization/results/isa/gfx1030.co:	file format elf64-amdgpu
	.amdgcn_target "amdgcn-amd-amdhsa-unknown-gfx1030"

Disassembly of section .text:

0000000000003300 <_Z14copy_rt_kernelPKcPcmib>:
	s_load_dwordx8 s[8:15], s[4:5], null                       // 000000003300: F40C0202 FA000000
	s_waitcnt lgkmcnt(0)                                       // 000000003308: BF8CC07F
	s_ashr_i32 s3, s14, 31                                     // 00000000330C: 91039F0E
	s_mov_b32 s2, s14                                          // 000000003310: BE82030E
	s_or_b64 s[0:1], s[12:13], s[2:3]                          // 000000003314: 8880020C
	s_mov_b32 s0, 0                                            // 000000003318: BE800380
	s_cmp_lg_u32 s1, 0                                         // 00000000331C: BF078001
	s_cbranch_scc0 113                                         // 000000003320: BF840071 <_Z14copy_rt_kernelPKcPcmib+0x1e8>
	v_cvt_f32_u32_e32 v1, s2                                   // 000000003324: 7E020C02
	v_cvt_f32_u32_e32 v2, s3                                   // 000000003328: 7E040C03
	s_sub_u32 s14, 0, s2                                       // 00000000332C: 808E0280
	s_subb_u32 s16, 0, s3                                      // 000000003330: 82900380
	v_fmamk_f32 v1, v2, 0x4f800000, v1                         // 000000003334: 58020302 4F800000
	v_rcp_f32_e32 v1, v1                                       // 00000000333C: 7E025501
	v_mul_f32_e32 v1, 0x5f7ffffc, v1                           // 000000003340: 100202FF 5F7FFFFC
	v_mul_f32_e32 v2, 0x2f800000, v1                           // 000000003348: 100402FF 2F800000
	v_trunc_f32_e32 v2, v2                                     // 000000003350: 7E044302
	v_fmamk_f32 v1, v2, 0xcf800000, v1                         // 000000003354: 58020302 CF800000
	v_cvt_u32_f32_e32 v2, v2                                   // 00000000335C: 7E040F02
	v_cvt_u32_f32_e32 v1, v1                                   // 000000003360: 7E020F01
	v_readfirstlane_b32 s1, v2                                 // 000000003364: 7E020502
	v_readfirstlane_b32 s7, v1                                 // 000000003368: 7E0E0501
	s_mul_i32 s17, s14, s1                                     // 00000000336C: 9311010E
	s_mul_hi_u32 s19, s14, s7                                  // 000000003370: 9A93070E
	s_mul_i32 s18, s16, s7                                     // 000000003374: 93120710
	s_add_i32 s17, s19, s17                                    // 000000003378: 81111113
	s_mul_i32 s20, s14, s7                                     // 00000000337C: 9314070E
	s_add_i32 s17, s17, s18                                    // 000000003380: 81111211
	s_mul_hi_u32 s19, s7, s20                                  // 000000003384: 9A931407
	s_mul_i32 s22, s7, s17                                     // 000000003388: 93161107
	s_mul_hi_u32 s21, s1, s20                                  // 00000000338C: 9A951401
	s_mul_i32 s18, s1, s20                                     // 000000003390: 93121401
	s_mul_hi_u32 s20, s7, s17                                  // 000000003394: 9A941107
	s_add_u32 s19, s19, s22                                    // 000000003398: 80131613
	s_addc_u32 s20, 0, s20                                     // 00000000339C: 82141480
	s_mul_hi_u32 s23, s1, s17                                  // 0000000033A0: 9A971101
	s_add_u32 s18, s19, s18                                    // 0000000033A4: 80121213
	s_mul_i32 s17, s1, s17                                     // 0000000033A8: 93111101
	s_addc_u32 s18, s20, s21                                   // 0000000033AC: 82121514
	s_addc_u32 s19, s23, 0                                     // 0000000033B0: 82138017
	s_add_u32 s17, s18, s17                                    // 0000000033B4: 80111112
	s_addc_u32 s18, 0, s19                                     // 0000000033B8: 82121380
	s_add_u32 s7, s7, s17                                      // 0000000033BC: 80071107
	s_addc_u32 s1, s1, s18                                     // 0000000033C0: 82011201
	s_mul_i32 s17, s14, s7                                     // 0000000033C4: 9311070E
	s_mul_hi_u32 s18, s14, s7                                  // 0000000033C8: 9A92070E
	s_mul_i32 s14, s14, s1                                     // 0000000033CC: 930E010E
	s_mul_i32 s16, s16, s7                                     // 0000000033D0: 93100710
	s_add_i32 s14, s18, s14                                    // 0000000033D4: 810E0E12
	s_mul_hi_u32 s19, s1, s17                                  // 0000000033D8: 9A931101
	s_add_i32 s14, s14, s16                                    // 0000000033DC: 810E100E
	s_mul_hi_u32 s16, s7, s17                                  // 0000000033E0: 9A901107
	s_mul_i32 s20, s7, s14                                     // 0000000033E4: 93140E07
	s_mul_i32 s18, s1, s17                                     // 0000000033E8: 93121101
	s_mul_hi_u32 s17, s7, s14                                  // 0000000033EC: 9A910E07
	s_add_u32 s16, s16, s20                                    // 0000000033F0: 80101410
	s_addc_u32 s17, 0, s17                                     // 0000000033F4: 82111180
	s_mul_hi_u32 s21, s1, s14                                  // 0000000033F8: 9A950E01
	s_add_u32 s16, s16, s18                                    // 0000000033FC: 80101210
	s_mul_i32 s14, s1, s14                                     // 000000003400: 930E0E01
	s_addc_u32 s16, s17, s19                                   // 000000003404: 82101311
	s_addc_u32 s17, s21, 0                                     // 000000003408: 82118015
	s_add_u32 s14, s16, s14                                    // 00000000340C: 800E0E10
	s_addc_u32 s16, 0, s17                                     // 000000003410: 82101180
	s_add_u32 s7, s7, s14                                      // 000000003414: 80070E07
	s_addc_u32 s1, s1, s16                                     // 000000003418: 82011001
	s_mul_hi_u32 s14, s12, s7                                  // 00000000341C: 9A8E070C
	s_mul_i32 s18, s12, s1                                     // 000000003420: 9312010C
	s_mul_hi_u32 s17, s12, s1                                  // 000000003424: 9A91010C
	s_mul_hi_u32 s16, s13, s7                                  // 000000003428: 9A90070D
	s_mul_i32 s7, s13, s7                                      // 00000000342C: 9307070D
	s_add_u32 s14, s14, s18                                    // 000000003430: 800E120E
	s_addc_u32 s17, 0, s17                                     // 000000003434: 82111180
	s_mul_hi_u32 s19, s13, s1                                  // 000000003438: 9A93010D
	s_add_u32 s7, s14, s7                                      // 00000000343C: 8007070E
	s_mul_i32 s1, s13, s1                                      // 000000003440: 9301010D
	s_addc_u32 s7, s17, s16                                    // 000000003444: 82071011
	s_addc_u32 s14, s19, 0                                     // 000000003448: 820E8013
	s_add_u32 s1, s7, s1                                       // 00000000344C: 80010107
	s_addc_u32 s7, 0, s14                                      // 000000003450: 82070E80
	s_mul_hi_u32 s14, s2, s1                                   // 000000003454: 9A8E0102
	s_mul_i32 s16, s2, s7                                      // 000000003458: 93100702
	s_mul_i32 s17, s3, s1                                      // 00000000345C: 93110103
	s_add_i32 s14, s14, s16                                    // 000000003460: 810E100E
	s_mul_i32 s16, s2, s1                                      // 000000003464: 93100102
	s_add_i32 s14, s14, s17                                    // 000000003468: 810E110E
	s_sub_i32 s17, s13, s14                                    // 00000000346C: 81910E0D
	s_sub_u32 s16, s12, s16                                    // 000000003470: 8090100C
	s_cselect_b32 s18, -1, 0                                   // 000000003474: 851280C1
	s_subb_u32 s17, s17, s3                                    // 000000003478: 82910311
	s_sub_u32 s19, s16, s2                                     // 00000000347C: 80930210
	s_subb_u32 s17, s17, 0                                     // 000000003480: 82918011
	s_cmp_ge_u32 s17, s3                                       // 000000003484: BF090311
	s_cselect_b32 s20, -1, 0                                   // 000000003488: 851480C1
	s_cmp_ge_u32 s19, s2                                       // 00000000348C: BF090213
	s_cselect_b32 s19, -1, 0                                   // 000000003490: 851380C1
	s_cmp_eq_u32 s17, s3                                       // 000000003494: BF060311
	s_cselect_b32 s17, s19, s20                                // 000000003498: 85111413
	s_add_u32 s19, s1, 1                                       // 00000000349C: 80138101
	s_addc_u32 s20, s7, 0                                      // 0000000034A0: 82148007
	s_add_u32 s21, s1, 2                                       // 0000000034A4: 80158201
	s_addc_u32 s22, s7, 0                                      // 0000000034A8: 82168007
	s_cmp_lg_u32 s17, 0                                        // 0000000034AC: BF078011
	s_cselect_b32 s19, s21, s19                                // 0000000034B0: 85131315
	s_cselect_b32 s17, s22, s20                                // 0000000034B4: 85111416
	s_cmp_lg_u32 s18, 0                                        // 0000000034B8: BF078012
	s_subb_u32 s14, s13, s14                                   // 0000000034BC: 828E0E0D
	s_cmp_ge_u32 s14, s3                                       // 0000000034C0: BF09030E
	s_cselect_b32 s18, -1, 0                                   // 0000000034C4: 851280C1
	s_cmp_ge_u32 s16, s2                                       // 0000000034C8: BF090210
	s_cselect_b32 s16, -1, 0                                   // 0000000034CC: 851080C1
	s_cmp_eq_u32 s14, s3                                       // 0000000034D0: BF06030E
	s_cselect_b32 s14, s16, s18                                // 0000000034D4: 850E1210
	s_cmp_lg_u32 s14, 0                                        // 0000000034D8: BF07800E
	s_cselect_b32 s17, s17, s7                                 // 0000000034DC: 85110711
	s_cselect_b32 s16, s19, s1                                 // 0000000034E0: 85100113
	s_branch 1                                                 // 0000000034E4: BF820001 <_Z14copy_rt_kernelPKcPcmib+0x1ec>
	s_mov_b32 s0, -1                                           // 0000000034E8: BE8003C1
	s_and_b32 s0, s0, exec_lo                                  // 0000000034EC: 87007E00
	s_cselect_b32 s0, 1, 0                                     // 0000000034F0: 85008081
	s_cmp_lg_u32 s0, 1                                         // 0000000034F4: BF078100
	s_cbranch_scc1 22                                          // 0000000034F8: BF850016 <_Z14copy_rt_kernelPKcPcmib+0x254>
	v_cvt_f32_u32_e32 v1, s2                                   // 0000000034FC: 7E020C02
	s_sub_i32 s1, 0, s2                                        // 000000003500: 81810280
	s_mov_b32 s17, 0                                           // 000000003504: BE910380
	v_rcp_iflag_f32_e32 v1, v1                                 // 000000003508: 7E025701
	v_mul_f32_e32 v1, 0x4f7ffffe, v1                           // 00000000350C: 100202FF 4F7FFFFE
	v_cvt_u32_f32_e32 v1, v1                                   // 000000003514: 7E020F01
	v_readfirstlane_b32 s0, v1                                 // 000000003518: 7E000501
	s_mul_i32 s1, s1, s0                                       // 00000000351C: 93010001
	s_mul_hi_u32 s1, s0, s1                                    // 000000003520: 9A810100
	s_add_i32 s0, s0, s1                                       // 000000003524: 81000100
	s_mul_hi_u32 s0, s12, s0                                   // 000000003528: 9A80000C
	s_mul_i32 s1, s0, s2                                       // 00000000352C: 93010200
	s_add_i32 s7, s0, 1                                        // 000000003530: 81078100
	s_sub_i32 s1, s12, s1                                      // 000000003534: 8181010C
	s_sub_i32 s14, s1, s2                                      // 000000003538: 818E0201
	s_cmp_ge_u32 s1, s2                                        // 00000000353C: BF090201
	s_cselect_b32 s0, s7, s0                                   // 000000003540: 85000007
	s_cselect_b32 s1, s14, s1                                  // 000000003544: 8501010E
	s_add_i32 s7, s0, 1                                        // 000000003548: 81078100
	s_cmp_ge_u32 s1, s2                                        // 00000000354C: BF090201
	s_cselect_b32 s16, s7, s0                                  // 000000003550: 85100007
	s_clause 0x1                                               // 000000003554: BFA10001
	s_load_dword s0, s[4:5], 0x2c                              // 000000003558: F4000002 FA00002C
	s_load_dword s7, s[4:5], 0x20                              // 000000003560: F40001C2 FA000020
	v_mov_b32_e32 v1, 0                                        // 000000003568: 7E020280
	s_mov_b32 s5, exec_lo                                      // 00000000356C: BE85037E
	s_waitcnt lgkmcnt(0)                                       // 000000003570: BF8CC07F
	s_and_b32 s0, s0, 0xffff                                   // 000000003574: 8700FF00 0000FFFF
	v_mad_u64_u32 v[2:3], null, s0, s6, v[0:1]                 // 00000000357C: D5767D02 04000C00
	s_mul_hi_u32 s1, s7, s0                                    // 000000003584: 9A810007
	s_mul_i32 s4, s7, s0                                       // 000000003588: 93040007
	v_cmpx_gt_u64_e32 s[16:17], v[2:3]                         // 00000000358C: 7DE80410
	s_cbranch_execz 101                                        // 000000003590: BF880065 <_Z14copy_rt_kernelPKcPcmib+0x428>
	v_mul_lo_u32 v8, v2, s3                                    // 000000003594: D5690008 02000702
	v_mul_lo_u32 v9, v3, s2                                    // 00000000359C: D5690009 02000503
	v_mad_u64_u32 v[6:7], null, v2, s2, s[10:11]               // 0000000035A4: D5767D06 00280502
	v_mad_u64_u32 v[4:5], null, v2, s2, s[8:9]                 // 0000000035AC: D5767D04 00200502
	s_bitcmp1_b32 s15, 0                                       // 0000000035B4: BF0D800F
	s_mul_i32 s15, s3, s7                                      // 0000000035B8: 930F0703
	s_mul_hi_u32 s18, s2, s7                                   // 0000000035BC: 9A920702
	s_cselect_b32 s14, -1, 0                                   // 0000000035C0: 850E80C1
	s_add_i32 s15, s18, s15                                    // 0000000035C4: 810F0F12
	s_mul_i32 s18, s2, s7                                      // 0000000035C8: 93120702
	v_add3_u32 v7, v9, v7, v8                                  // 0000000035CC: D76D0007 04220F09
	v_add_co_u32 v6, vcc_lo, v6, 8                             // 0000000035D4: D70F6A06 02011106
	v_add3_u32 v5, v9, v5, v8                                  // 0000000035DC: D76D0005 04220B09
	s_mul_i32 s15, s15, s0                                     // 0000000035E4: 930F000F
	v_add_co_ci_u32_e64 v7, null, 0, v7, vcc_lo                // 0000000035E8: D5287D07 01AA0E80
	s_mul_hi_u32 s19, s18, s0                                  // 0000000035F0: 9A930012
	s_mov_b32 s6, 0                                            // 0000000035F4: BE860380
	s_xor_b32 s7, s14, -1                                      // 0000000035F8: 8907C10E
	s_add_i32 s14, s19, s15                                    // 0000000035FC: 810E0F13
	s_mul_i32 s15, s18, s0                                     // 000000003600: 930F0012
	s_branch 16                                                // 000000003604: BF820010 <_Z14copy_rt_kernelPKcPcmib+0x348>
	v_add_co_u32 v2, vcc_lo, v2, s4                            // 000000003608: D70F6A02 02000902
	v_add_co_ci_u32_e64 v3, null, s1, v3, vcc_lo               // 000000003610: D5287D03 01AA0601
	v_add_co_u32 v4, vcc_lo, v4, s15                           // 000000003618: D70F6A04 02001F04
	v_add_co_ci_u32_e64 v5, null, s14, v5, vcc_lo              // 000000003620: D5287D05 01AA0A0E
	v_cmp_le_u64_e32 vcc_lo, s[16:17], v[2:3]                  // 000000003628: 7DC60410
	v_add_co_u32 v6, s0, v6, s15                               // 00000000362C: D70F0006 02001F06
	v_add_co_ci_u32_e64 v7, null, s14, v7, s0                  // 000000003634: D5287D07 00020E0E
	s_or_b32 s6, vcc_lo, s6                                    // 00000000363C: 8806066A
	s_andn2_b32 exec_lo, exec_lo, s6                           // 000000003640: 8A7E067E
	s_cbranch_execz 56                                         // 000000003644: BF880038 <_Z14copy_rt_kernelPKcPcmib+0x428>
	v_add_co_u32 v8, vcc_lo, v6, -8                            // 000000003648: D70F6A08 02019106
	v_add_co_ci_u32_e64 v9, null, -1, v7, vcc_lo               // 000000003650: D5287D09 01AA0EC1
	s_mov_b32 s19, -1                                          // 000000003658: BE9303C1
	s_mov_b32 s0, 0                                            // 00000000365C: BE800380
	s_cmp_lt_i32 s2, 16                                        // 000000003660: BF049002
	s_mov_b32 s18, 0                                           // 000000003664: BE920380
	s_cbranch_scc1 22                                          // 000000003668: BF850016 <_Z14copy_rt_kernelPKcPcmib+0x3c4>
	s_cmp_eq_u32 s2, 16                                        // 00000000366C: BF069002
	s_mov_b32 s18, -1                                          // 000000003670: BE9203C1
	s_cbranch_scc0 18                                          // 000000003674: BF840012 <_Z14copy_rt_kernelPKcPcmib+0x3c0>
	s_and_b32 vcc_lo, exec_lo, s7                              // 000000003678: 876A077E
	s_cbranch_vccz 6                                           // 00000000367C: BF860006 <_Z14copy_rt_kernelPKcPcmib+0x398>
	global_load_dwordx4 v[10:13], v[4:5], off                  // 000000003680: DC388000 0A7D0004
	s_mov_b32 s18, 0                                           // 000000003688: BE920380
	s_waitcnt vmcnt(0)                                         // 00000000368C: BF8C3F70
	global_store_dwordx4 v[8:9], v[10:13], off                 // 000000003690: DC788000 007D0A08
	s_and_b32 s18, s18, exec_lo                                // 000000003698: 87127E12
	s_cselect_b32 s18, 1, 0                                    // 00000000369C: 85128081
	s_cmp_lg_u32 s18, 1                                        // 0000000036A0: BF078112
	s_cbranch_scc1 5                                           // 0000000036A4: BF850005 <_Z14copy_rt_kernelPKcPcmib+0x3bc>
	global_load_dwordx4 v[10:13], v[4:5], off slc              // 0000000036A8: DC3A8000 0A7D0004
	s_waitcnt vmcnt(0)                                         // 0000000036B0: BF8C3F70
	global_store_dwordx4 v[6:7], v[10:13], off offset:-8 glc slc// 0000000036B4: DC7B8FF8 007D0A06
	s_mov_b32 s18, 0                                           // 0000000036BC: BE920380
	s_mov_b32 s19, 0                                           // 0000000036C0: BE930380
	s_and_b32 vcc_lo, exec_lo, s19                             // 0000000036C4: 876A137E
	s_cbranch_vccz 3                                           // 0000000036C8: BF860003 <_Z14copy_rt_kernelPKcPcmib+0x3d8>
	s_cmp_lg_u32 s2, 8                                         // 0000000036CC: BF078802
	s_mov_b32 s0, -1                                           // 0000000036D0: BE8003C1
	s_cselect_b32 s18, -1, 0                                   // 0000000036D4: 851280C1
	s_and_b32 s18, s18, exec_lo                                // 0000000036D8: 87127E12
	s_cselect_b32 s18, 1, 0                                    // 0000000036DC: 85128081
	s_cmp_lg_u32 s18, 1                                        // 0000000036E0: BF078112
	s_cbranch_scc1 6                                           // 0000000036E4: BF850006 <_Z14copy_rt_kernelPKcPcmib+0x400>
	global_load_dword v10, v[4:5], off                         // 0000000036E8: DC308000 0A7D0004
	s_mov_b32 s0, 0                                            // 0000000036F0: BE800380
	s_waitcnt vmcnt(0)                                         // 0000000036F4: BF8C3F70
	global_store_dword v[8:9], v10, off                        // 0000000036F8: DC708000 007D0A08
	s_and_b32 s0, s0, exec_lo                                  // 000000003700: 87007E00
	s_cselect_b32 s0, 1, 0                                     // 000000003704: 85008081
	s_cmp_lg_u32 s0, 1                                         // 000000003708: BF078100
	s_cbranch_scc1 65470                                       // 00000000370C: BF85FFBE <_Z14copy_rt_kernelPKcPcmib+0x308>
	global_load_dwordx2 v[10:11], v[4:5], off                  // 000000003710: DC348000 0A7D0004
	s_waitcnt vmcnt(0)                                         // 000000003718: BF8C3F70
	global_store_dwordx2 v[8:9], v[10:11], off                 // 00000000371C: DC748000 007D0A08
	s_branch 65464                                             // 000000003724: BF82FFB8 <_Z14copy_rt_kernelPKcPcmib+0x308>
	s_or_b32 exec_lo, exec_lo, s5                              // 000000003728: 887E057E
	v_mad_u64_u32 v[0:1], null, s16, s2, v[0:1]                // 00000000372C: D5767D00 04000410
	s_mul_i32 s0, s17, s2                                      // 000000003734: 93000211
	s_mul_i32 s2, s16, s3                                      // 000000003738: 93020310
	v_add3_u32 v1, s2, s0, v1                                  // 00000000373C: D76D0001 04040002
	s_mov_b32 s0, exec_lo                                      // 000000003744: BE80037E
	v_cmpx_gt_u64_e32 s[12:13], v[0:1]                         // 000000003748: 7DE8000C
	s_cbranch_execz 33                                         // 00000000374C: BF880021 <_Z14copy_rt_kernelPKcPcmib+0x4d4>
	s_mov_b32 s0, 0                                            // 000000003750: BE800380
	s_nop 0                                                    // 000000003754: BF800000
	s_nop 0                                                    // 000000003758: BF800000
	s_nop 0                                                    // 00000000375C: BF800000
	s_nop 0                                                    // 000000003760: BF800000
	s_nop 0                                                    // 000000003764: BF800000
	s_nop 0                                                    // 000000003768: BF800000
	s_nop 0                                                    // 00000000376C: BF800000
	s_nop 0                                                    // 000000003770: BF800000
	s_nop 0                                                    // 000000003774: BF800000
	s_nop 0                                                    // 000000003778: BF800000
	s_nop 0                                                    // 00000000377C: BF800000
	v_add_co_u32 v2, vcc_lo, s8, v0                            // 000000003780: D70F6A02 02020008
	v_add_co_ci_u32_e64 v3, null, s9, v1, vcc_lo               // 000000003788: D5287D03 01AA0209
	global_load_ubyte v4, v[2:3], off                          // 000000003790: DC208000 047D0002
	v_add_co_u32 v2, vcc_lo, s10, v0                           // 000000003798: D70F6A02 0202000A
	v_add_co_ci_u32_e64 v3, null, s11, v1, vcc_lo              // 0000000037A0: D5287D03 01AA020B
	v_add_co_u32 v0, vcc_lo, v0, s4                            // 0000000037A8: D70F6A00 02000900
	v_add_co_ci_u32_e64 v1, null, s1, v1, vcc_lo               // 0000000037B0: D5287D01 01AA0201
	v_cmp_le_u64_e32 vcc_lo, s[12:13], v[0:1]                  // 0000000037B8: 7DC6000C
	s_or_b32 s0, vcc_lo, s0                                    // 0000000037BC: 8800006A
	s_waitcnt vmcnt(0)                                         // 0000000037C0: BF8C3F70
	global_store_byte v[2:3], v4, off                          // 0000000037C4: DC608000 007D0402
	s_andn2_b32 exec_lo, exec_lo, s0                           // 0000000037CC: 8A7E007E
	s_cbranch_execnz 65515                                     // 0000000037D0: BF89FFEB <_Z14copy_rt_kernelPKcPcmib+0x480>
	s_endpgm                                                   // 0000000037D4: BF810000
	s_code_end                                                 // 0000000037D8: BF9F0000
	s_code_end                                                 // 0000000037DC: BF9F0000
	s_code_end                                                 // 0000000037E0: BF9F0000
	s_code_end                                                 // 0000000037E4: BF9F0000
	s_code_end                                                 // 0000000037E8: BF9F0000
	s_code_end                                                 // 0000000037EC: BF9F0000
	s_code_end                                                 // 0000000037F0: BF9F0000
	s_code_end                                                 // 0000000037F4: BF9F0000
	s_code_end                                                 // 0000000037F8: BF9F0000
	s_code_end                                                 // 0000000037FC: BF9F0000
	s_code_end                                                 // 000000003800: BF9F0000
	s_code_end                                                 // 000000003804: BF9F0000
	s_code_end                                                 // 000000003808: BF9F0000
	s_code_end                                                 // 00000000380C: BF9F0000
	s_code_end                                                 // 000000003810: BF9F0000
	s_code_end                                                 // 000000003814: BF9F0000
	s_code_end                                                 // 000000003818: BF9F0000
	s_code_end                                                 // 00000000381C: BF9F0000
	s_code_end                                                 // 000000003820: BF9F0000
	s_code_end                                                 // 000000003824: BF9F0000
	s_code_end                                                 // 000000003828: BF9F0000
	s_code_end                                                 // 00000000382C: BF9F0000
	s_code_end                                                 // 000000003830: BF9F0000
	s_code_end                                                 // 000000003834: BF9F0000
	s_code_end                                                 // 000000003838: BF9F0000
	s_code_end                                                 // 00000000383C: BF9F0000
	s_code_end                                                 // 000000003840: BF9F0000
	s_code_end                                                 // 000000003844: BF9F0000
	s_code_end                                                 // 000000003848: BF9F0000
	s_code_end                                                 // 00000000384C: BF9F0000
	s_code_end                                                 // 000000003850: BF9F0000
	s_code_end                                                 // 000000003854: BF9F0000
	s_code_end                                                 // 000000003858: BF9F0000
	s_code_end                                                 // 00000000385C: BF9F0000
	s_code_end                                                 // 000000003860: BF9F0000
	s_code_end                                                 // 000000003864: BF9F0000
	s_code_end                                                 // 000000003868: BF9F0000
	s_code_end                                                 // 00000000386C: BF9F0000
	s_code_end                                                 // 000000003870: BF9F0000
	s_code_end                                                 // 000000003874: BF9F0000
	s_code_end                                                 // 000000003878: BF9F0000
	s_code_end                                                 // 00000000387C: BF9F0000
	s_code_end                                                 // 000000003880: BF9F0000
	s_code_end                                                 // 000000003884: BF9F0000
	s_code_end                                                 // 000000003888: BF9F0000
	s_code_end                                                 // 00000000388C: BF9F0000
	s_code_end                                                 // 000000003890: BF9F0000
	s_code_end                                                 // 000000003894: BF9F0000
	s_code_end                                                 // 000000003898: BF9F0000
	s_code_end                                                 // 00000000389C: BF9F0000
	s_code_end                                                 // 0000000038A0: BF9F0000
	s_code_end                                                 // 0000000038A4: BF9F0000
	s_code_end                                                 // 0000000038A8: BF9F0000
	s_code_end                                                 // 0000000038AC: BF9F0000
	s_code_end                                                 // 0000000038B0: BF9F0000
	s_code_end                                                 // 0000000038B4: BF9F0000
	s_code_end                                                 // 0000000038B8: BF9F0000
	s_code_end                                                 // 0000000038BC: BF9F0000
		...

0000000000003900 <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1EEEEvPKcPcm>:
	s_clause 0x1                                               // 000000003900: BFA10001
	s_load_dword s0, s[4:5], 0x24                              // 000000003904: F4000002 FA000024
	s_load_dword s7, s[4:5], 0x18                              // 00000000390C: F40001C2 FA000018
	v_mov_b32_e32 v1, 0                                        // 000000003914: 7E020280
	s_clause 0x1                                               // 000000003918: BFA10001
	s_load_dwordx2 s[2:3], s[4:5], 0x10                        // 00000000391C: F4040082 FA000010
	s_load_dwordx4 s[8:11], s[4:5], null                       // 000000003924: F4080202 FA000000
	s_mov_b32 s1, exec_lo                                      // 00000000392C: BE81037E
	s_waitcnt lgkmcnt(0)                                       // 000000003930: BF8CC07F
	s_and_b32 s0, s0, 0xffff                                   // 000000003934: 8700FF00 0000FFFF
	v_mad_u64_u32 v[5:6], null, s0, s6, v[0:1]                 // 00000000393C: D5767D05 04000C00
	s_mul_i32 s12, s7, s0                                      // 000000003944: 930C0007
	s_mul_hi_u32 s13, s7, s0                                   // 000000003948: 9A8D0007
	s_lshr_b64 s[4:5], s[2:3], 4                               // 00000000394C: 90848402
	v_mad_u64_u32 v[2:3], null, s12, 3, v[5:6]                 // 000000003950: D5767D02 0415060C
	v_mad_u64_u32 v[3:4], null, s13, 3, v[3:4]                 // 000000003958: D5767D03 040D060D
	v_cmpx_gt_u64_e32 s[4:5], v[2:3]                           // 000000003960: 7DE80404
	s_cbranch_execz 146                                        // 000000003964: BF880092 <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1EEEEvPKcPcm+0x2b0>
	s_lshl_b64 s[16:17], s[12:13], 5                           // 000000003968: 8F90850C
	s_lshl_b64 s[14:15], s[12:13], 6                           // 00000000396C: 8F8E860C
	s_add_u32 s18, s6, s7                                      // 000000003970: 80120706
	v_lshlrev_b64 v[15:16], 4, v[5:6]                          // 000000003974: D6FF000F 02020A84
	v_mad_u64_u32 v[9:10], null, s18, s0, v[0:1]               // 00000000397C: D5767D09 04000012
	s_addc_u32 s18, 0, 0                                       // 000000003984: 82128080
	v_add_co_u32 v12, vcc_lo, s16, v15                         // 000000003988: D70F6A0C 02021E10
	v_add_co_ci_u32_e64 v17, null, s17, v16, vcc_lo            // 000000003990: D5287D11 01AA2011
	v_mad_u64_u32 v[10:11], null, s18, s0, v[10:11]            // 000000003998: D5767D0A 04280012
	v_add_co_u32 v1, vcc_lo, s8, v15                           // 0000000039A0: D70F6A01 02021E08
	v_add_co_ci_u32_e64 v4, null, s9, v16, vcc_lo              // 0000000039A8: D5287D04 01AA2009
	v_add_co_u32 v7, vcc_lo, s8, v12                           // 0000000039B0: D70F6A07 02021808
	v_add_co_ci_u32_e64 v8, null, s9, v17, vcc_lo              // 0000000039B8: D5287D08 01AA2209
	v_lshlrev_b64 v[13:14], 4, v[9:10]                         // 0000000039C0: D6FF000D 02021284
	v_add_co_u32 v11, vcc_lo, s10, v12                         // 0000000039C8: D70F6A0B 0202180A
	v_add_co_ci_u32_e64 v12, null, s11, v17, vcc_lo            // 0000000039D0: D5287D0C 01AA220B
	s_mul_i32 s18, s7, 3                                       // 0000000039D8: 93128307
	v_add_co_u32 v9, vcc_lo, s8, v13                           // 0000000039DC: D70F6A09 02021A08
	v_add_co_ci_u32_e64 v10, null, s9, v14, vcc_lo             // 0000000039E4: D5287D0A 01AA1C09
	v_add_co_u32 v11, vcc_lo, v11, 8                           // 0000000039EC: D70F6A0B 0201110B
	s_lshl_b64 s[16:17], s[12:13], 2                           // 0000000039F4: 8F90820C
	s_mul_hi_u32 s7, s7, 3                                     // 0000000039F8: 9A878307
	v_add_co_ci_u32_e64 v12, null, 0, v12, vcc_lo              // 0000000039FC: D5287D0C 01AA1880
	s_add_u32 s6, s18, s6                                      // 000000003A04: 80060612
	v_add_co_u32 v13, vcc_lo, s10, v13                         // 000000003A08: D70F6A0D 02021A0A
	s_addc_u32 s7, s7, 0                                       // 000000003A10: 82078007
	v_add_co_ci_u32_e64 v14, null, s11, v14, vcc_lo            // 000000003A14: D5287D0E 01AA1C0B
	s_mul_i32 s7, s7, s0                                       // 000000003A1C: 93070007
	s_mul_hi_u32 s18, s6, s0                                   // 000000003A20: 9A920006
	v_lshlrev_b32_e32 v17, 4, v0                               // 000000003A24: 34220084
	v_add_co_u32 v13, vcc_lo, v13, 8                           // 000000003A28: D70F6A0D 0201110D
	s_add_i32 s7, s18, s7                                      // 000000003A30: 81070712
	s_mul_i32 s6, s6, s0                                       // 000000003A34: 93060006
	v_add_co_ci_u32_e64 v14, null, 0, v14, vcc_lo              // 000000003A38: D5287D0E 01AA1C80
	v_add_co_u32 v15, vcc_lo, s10, v15                         // 000000003A40: D70F6A0F 02021E0A
	s_lshl_b64 s[6:7], s[6:7], 4                               // 000000003A48: 8F868406
	v_add_co_ci_u32_e64 v16, null, s11, v16, vcc_lo            // 000000003A4C: D5287D10 01AA200B
	v_add_co_u32 v19, s0, s6, v17                              // 000000003A54: D70F0013 02022206
	v_add_co_ci_u32_e64 v20, null, s7, 0, s0                   // 000000003A5C: D5287D14 00010007
	v_add_co_u32 v15, vcc_lo, v15, 8                           // 000000003A64: D70F6A0F 0201110F
	v_add_co_ci_u32_e64 v16, null, 0, v16, vcc_lo              // 000000003A6C: D5287D10 01AA2080
	v_add_co_u32 v17, vcc_lo, s10, v19                         // 000000003A74: D70F6A11 0202260A
	v_add_co_ci_u32_e64 v18, null, s11, v20, vcc_lo            // 000000003A7C: D5287D12 01AA280B
	v_add_co_u32 v19, vcc_lo, s8, v19                          // 000000003A84: D70F6A13 02022608
	v_add_co_ci_u32_e64 v20, null, s9, v20, vcc_lo             // 000000003A8C: D5287D14 01AA2809
	s_mov_b32 s18, 0                                           // 000000003A94: BE920380
	s_mov_b64 s[6:7], 0                                        // 000000003A98: BE860480
	v_add_co_u32 v21, vcc_lo, v1, s6                           // 000000003A9C: D70F6A15 02000D01
	v_add_co_ci_u32_e64 v22, null, s7, v4, vcc_lo              // 000000003AA4: D5287D16 01AA0807
	v_add_co_u32 v25, vcc_lo, v9, s6                           // 000000003AAC: D70F6A19 02000D09
	v_add_co_ci_u32_e64 v26, null, s7, v10, vcc_lo             // 000000003AB4: D5287D1A 01AA1407
	v_add_co_u32 v29, vcc_lo, v7, s6                           // 000000003ABC: D70F6A1D 02000D07
	v_add_co_ci_u32_e64 v30, null, s7, v8, vcc_lo              // 000000003AC4: D5287D1E 01AA1007
	v_add_co_u32 v33, vcc_lo, v19, s6                          // 000000003ACC: D70F6A21 02000D13
	v_add_co_ci_u32_e64 v34, null, s7, v20, vcc_lo             // 000000003AD4: D5287D22 01AA2807
	s_clause 0x3                                               // 000000003ADC: BFA10003
	global_load_dwordx4 v[21:24], v[21:22], off slc            // 000000003AE0: DC3A8000 157D0015
	global_load_dwordx4 v[25:28], v[25:26], off slc            // 000000003AE8: DC3A8000 197D0019
	global_load_dwordx4 v[29:32], v[29:30], off slc            // 000000003AF0: DC3A8000 1D7D001D
	global_load_dwordx4 v[33:36], v[33:34], off slc            // 000000003AF8: DC3A8000 217D0021
	v_add_co_u32 v37, vcc_lo, v15, s6                          // 000000003B00: D70F6A25 02000D0F
	v_add_co_ci_u32_e64 v38, null, s7, v16, vcc_lo             // 000000003B08: D5287D26 01AA2007
	v_add_co_u32 v39, vcc_lo, v13, s6                          // 000000003B10: D70F6A27 02000D0D
	v_add_co_ci_u32_e64 v40, null, s7, v14, vcc_lo             // 000000003B18: D5287D28 01AA1C07
	v_add_co_u32 v41, vcc_lo, v11, s6                          // 000000003B20: D70F6A29 02000D0B
	v_add_co_ci_u32_e64 v42, null, s7, v12, vcc_lo             // 000000003B28: D5287D2A 01AA1807
	v_add_co_u32 v2, vcc_lo, v2, s16                           // 000000003B30: D70F6A02 02002102
	v_add_co_ci_u32_e64 v3, null, s17, v3, vcc_lo              // 000000003B38: D5287D03 01AA0611
	v_add_co_u32 v43, vcc_lo, v17, s6                          // 000000003B40: D70F6A2B 02000D11
	v_add_co_ci_u32_e64 v44, null, s7, v18, vcc_lo             // 000000003B48: D5287D2C 01AA2407
	v_cmp_le_u64_e64 s0, s[4:5], v[2:3]                        // 000000003B50: D4E30000 02020404
	v_add_co_u32 v5, vcc_lo, v5, s16                           // 000000003B58: D70F6A05 02002105
	v_add_co_ci_u32_e64 v6, null, s17, v6, vcc_lo              // 000000003B60: D5287D06 01AA0C11
	s_add_u32 s6, s6, s14                                      // 000000003B68: 80060E06
	s_addc_u32 s7, s7, s15                                     // 000000003B6C: 82070F07
	s_or_b32 s18, s0, s18                                      // 000000003B70: 88121200
	s_waitcnt vmcnt(3)                                         // 000000003B74: BF8C3F73
	global_store_dwordx4 v[37:38], v[21:24], off offset:-8 glc slc// 000000003B78: DC7B8FF8 007D1525
	s_waitcnt vmcnt(2)                                         // 000000003B80: BF8C3F72
	global_store_dwordx4 v[39:40], v[25:28], off offset:-8 glc slc// 000000003B84: DC7B8FF8 007D1927
	s_waitcnt vmcnt(1)                                         // 000000003B8C: BF8C3F71
	global_store_dwordx4 v[41:42], v[29:32], off offset:-8 glc slc// 000000003B90: DC7B8FF8 007D1D29
	s_waitcnt vmcnt(0)                                         // 000000003B98: BF8C3F70
	global_store_dwordx4 v[43:44], v[33:36], off glc slc       // 000000003B9C: DC7B8000 007D212B
	s_andn2_b32 exec_lo, exec_lo, s18                          // 000000003BA4: 8A7E127E
	s_cbranch_execnz 65468                                     // 000000003BA8: BF89FFBC <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1EEEEvPKcPcm+0x19c>
	s_or_b32 exec_lo, exec_lo, s18                             // 000000003BAC: 887E127E
	s_or_b32 exec_lo, exec_lo, s1                              // 000000003BB0: 887E017E
	s_mov_b32 s1, exec_lo                                      // 000000003BB4: BE81037E
	v_cmpx_gt_u64_e32 s[4:5], v[5:6]                           // 000000003BB8: 7DE80A04
	s_cbranch_execz 37                                         // 000000003BBC: BF880025 <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1EEEEvPKcPcm+0x354>
	v_lshlrev_b64 v[1:2], 4, v[5:6]                            // 000000003BC0: D6FF0001 02020A84
	s_lshl_b64 s[6:7], s[12:13], 4                             // 000000003BC8: 8F86840C
	s_mov_b32 s14, 0                                           // 000000003BCC: BE8E0380
	v_add_co_u32 v3, vcc_lo, s10, v1                           // 000000003BD0: D70F6A03 0202020A
	v_add_co_ci_u32_e64 v4, null, s11, v2, vcc_lo              // 000000003BD8: D5287D04 01AA040B
	v_add_co_u32 v1, vcc_lo, s8, v1                            // 000000003BE0: D70F6A01 02020208
	v_add_co_ci_u32_e64 v2, null, s9, v2, vcc_lo               // 000000003BE8: D5287D02 01AA0409
	v_add_co_u32 v3, vcc_lo, v3, 8                             // 000000003BF0: D70F6A03 02011103
	v_add_co_ci_u32_e64 v4, null, 0, v4, vcc_lo                // 000000003BF8: D5287D04 01AA0880
	global_load_dwordx4 v[7:10], v[1:2], off slc               // 000000003C00: DC3A8000 077D0001
	v_add_co_u32 v5, vcc_lo, v5, s12                           // 000000003C08: D70F6A05 02001905
	v_add_co_ci_u32_e64 v6, null, s13, v6, vcc_lo              // 000000003C10: D5287D06 01AA0C0D
	v_add_co_u32 v1, vcc_lo, v1, s6                            // 000000003C18: D70F6A01 02000D01
	v_add_co_ci_u32_e64 v2, null, s7, v2, vcc_lo               // 000000003C20: D5287D02 01AA0407
	v_cmp_le_u64_e32 vcc_lo, s[4:5], v[5:6]                    // 000000003C28: 7DC60A04
	s_or_b32 s14, vcc_lo, s14                                  // 000000003C2C: 880E0E6A
	s_waitcnt vmcnt(0)                                         // 000000003C30: BF8C3F70
	global_store_dwordx4 v[3:4], v[7:10], off offset:-8 glc slc// 000000003C34: DC7B8FF8 007D0703
	v_add_co_u32 v3, s0, v3, s6                                // 000000003C3C: D70F0003 02000D03
	v_add_co_ci_u32_e64 v4, null, s7, v4, s0                   // 000000003C44: D5287D04 00020807
	s_andn2_b32 exec_lo, exec_lo, s14                          // 000000003C4C: 8A7E0E7E
	s_cbranch_execnz 65515                                     // 000000003C50: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1EEEEvPKcPcm+0x300>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000003C54: 887E017E
	s_and_b32 s0, s2, -16                                      // 000000003C58: 8700D002
	v_add_co_u32 v0, s0, s0, v0                                // 000000003C5C: D70F0000 02020000
	v_add_co_ci_u32_e64 v1, null, s3, 0, s0                    // 000000003C64: D5287D01 00010003
	s_mov_b32 s0, exec_lo                                      // 000000003C6C: BE80037E
	v_cmpx_gt_u64_e32 s[2:3], v[0:1]                           // 000000003C70: 7DE80002
	s_cbranch_execz 23                                         // 000000003C74: BF880017 <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1EEEEvPKcPcm+0x3d4>
	s_mov_b32 s0, 0                                            // 000000003C78: BE800380
	s_nop 0                                                    // 000000003C7C: BF800000
	v_add_co_u32 v2, vcc_lo, s8, v0                            // 000000003C80: D70F6A02 02020008
	v_add_co_ci_u32_e64 v3, null, s9, v1, vcc_lo               // 000000003C88: D5287D03 01AA0209
	global_load_ubyte v4, v[2:3], off                          // 000000003C90: DC208000 047D0002
	v_add_co_u32 v2, vcc_lo, s10, v0                           // 000000003C98: D70F6A02 0202000A
	v_add_co_ci_u32_e64 v3, null, s11, v1, vcc_lo              // 000000003CA0: D5287D03 01AA020B
	v_add_co_u32 v0, vcc_lo, v0, s12                           // 000000003CA8: D70F6A00 02001900
	v_add_co_ci_u32_e64 v1, null, s13, v1, vcc_lo              // 000000003CB0: D5287D01 01AA020D
	v_cmp_le_u64_e32 vcc_lo, s[2:3], v[0:1]                    // 000000003CB8: 7DC60002
	s_or_b32 s0, vcc_lo, s0                                    // 000000003CBC: 8800006A
	s_waitcnt vmcnt(0)                                         // 000000003CC0: BF8C3F70
	global_store_byte v[2:3], v4, off                          // 000000003CC4: DC608000 007D0402
	s_andn2_b32 exec_lo, exec_lo, s0                           // 000000003CCC: 8A7E007E
	s_cbranch_execnz 65515                                     // 000000003CD0: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1EEEEvPKcPcm+0x380>
	s_endpgm                                                   // 000000003CD4: BF810000
		...

0000000000003d00 <_Z16copy_nttp_kernelIXtl7CopyCfgLi8ELi4ELb1EEEEvPKcPcm>:
	s_clause 0x1                                               // 000000003D00: BFA10001
	s_load_dword s0, s[4:5], 0x24                              // 000000003D04: F4000002 FA000024
	s_load_dword s7, s[4:5], 0x18                              // 000000003D0C: F40001C2 FA000018
	v_mov_b32_e32 v1, 0                                        // 000000003D14: 7E020280
	s_clause 0x1                                               // 000000003D18: BFA10001
	s_load_dwordx2 s[2:3], s[4:5], 0x10                        // 000000003D1C: F4040082 FA000010
	s_load_dwordx4 s[8:11], s[4:5], null                       // 000000003D24: F4080202 FA000000
	s_mov_b32 s1, exec_lo                                      // 000000003D2C: BE81037E
	s_waitcnt lgkmcnt(0)                                       // 000000003D30: BF8CC07F
	s_and_b32 s0, s0, 0xffff                                   // 000000003D34: 8700FF00 0000FFFF
	v_mad_u64_u32 v[5:6], null, s0, s6, v[0:1]                 // 000000003D3C: D5767D05 04000C00
	s_mul_i32 s12, s7, s0                                      // 000000003D44: 930C0007
	s_mul_hi_u32 s13, s7, s0                                   // 000000003D48: 9A8D0007
	s_lshr_b64 s[4:5], s[2:3], 3                               // 000000003D4C: 90848302
	v_mad_u64_u32 v[2:3], null, s12, 3, v[5:6]                 // 000000003D50: D5767D02 0415060C
	v_mad_u64_u32 v[3:4], null, s13, 3, v[3:4]                 // 000000003D58: D5767D03 040D060D
	v_cmpx_gt_u64_e32 s[4:5], v[2:3]                           // 000000003D60: 7DE80404
	s_cbranch_execz 134                                        // 000000003D64: BF880086 <_Z16copy_nttp_kernelIXtl7CopyCfgLi8ELi4ELb1EEEEvPKcPcm+0x280>
	v_lshlrev_b64 v[11:12], 3, v[5:6]                          // 000000003D68: D6FF000B 02020A83
	s_mul_i32 s18, s7, 3                                       // 000000003D70: 93128307
	s_lshl_b64 s[16:17], s[12:13], 4                           // 000000003D74: 8F90840C
	s_lshl_b64 s[14:15], s[12:13], 5                           // 000000003D78: 8F8E850C
	s_mul_hi_u32 s19, s7, 3                                    // 000000003D7C: 9A938307
	s_add_u32 s18, s18, s6                                     // 000000003D80: 80120612
	s_addc_u32 s19, s19, 0                                     // 000000003D84: 82138013
	v_add_co_u32 v10, vcc_lo, s16, v11                         // 000000003D88: D70F6A0A 02021610
	s_mul_i32 s19, s19, s0                                     // 000000003D90: 93130013
	s_mul_hi_u32 s16, s18, s0                                  // 000000003D94: 9A900012
	v_add_co_ci_u32_e64 v13, null, s17, v12, vcc_lo            // 000000003D98: D5287D0D 01AA1811
	s_add_i32 s17, s16, s19                                    // 000000003DA0: 81111310
	s_mul_i32 s16, s18, s0                                     // 000000003DA4: 93100012
	v_lshlrev_b32_e32 v14, 3, v0                               // 000000003DA8: 341C0083
	s_lshl_b64 s[18:19], s[16:17], 3                           // 000000003DAC: 8F928310
	s_lshl_b64 s[16:17], s[12:13], 2                           // 000000003DB0: 8F90820C
	s_add_u32 s6, s6, s7                                       // 000000003DB4: 80060706
	v_add_co_u32 v4, vcc_lo, s8, v10                           // 000000003DB8: D70F6A04 02021408
	v_mad_u64_u32 v[15:16], null, s6, s0, v[0:1]               // 000000003DC0: D5767D0F 04000006
	s_addc_u32 s6, 0, 0                                        // 000000003DC8: 82068080
	v_add_co_ci_u32_e64 v7, null, s9, v13, vcc_lo              // 000000003DCC: D5287D07 01AA1A09
	v_add_co_u32 v8, vcc_lo, s8, v11                           // 000000003DD4: D70F6A08 02021608
	v_add_co_u32 v18, s7, s18, v14                             // 000000003DDC: D70F0712 02021C12
	v_mad_u64_u32 v[16:17], null, s6, s0, v[16:17]             // 000000003DE4: D5767D10 04400006
	v_add_co_ci_u32_e64 v9, null, s9, v12, vcc_lo              // 000000003DEC: D5287D09 01AA1809
	v_add_co_u32 v1, vcc_lo, s10, v10                          // 000000003DF4: D70F6A01 0202140A
	v_add_co_ci_u32_e64 v21, null, s19, 0, s7                  // 000000003DFC: D5287D15 001D0013
	v_add_co_ci_u32_e64 v10, null, s11, v13, vcc_lo            // 000000003E04: D5287D0A 01AA1A0B
	v_add_co_u32 v11, vcc_lo, s10, v11                         // 000000003E0C: D70F6A0B 0202160A
	v_lshlrev_b64 v[19:20], 3, v[15:16]                        // 000000003E14: D6FF0013 02021E83
	v_add_co_ci_u32_e64 v12, null, s11, v12, vcc_lo            // 000000003E1C: D5287D0C 01AA180B
	v_add_co_u32 v13, vcc_lo, s10, v18                         // 000000003E24: D70F6A0D 0202240A
	v_add_co_ci_u32_e64 v14, null, s11, v21, vcc_lo            // 000000003E2C: D5287D0E 01AA2A0B
	v_add_co_u32 v15, vcc_lo, s8, v18                          // 000000003E34: D70F6A0F 02022408
	v_add_co_ci_u32_e64 v16, null, s9, v21, vcc_lo             // 000000003E3C: D5287D10 01AA2A09
	v_add_co_u32 v17, vcc_lo, s10, v19                         // 000000003E44: D70F6A11 0202260A
	v_add_co_ci_u32_e64 v18, null, s11, v20, vcc_lo            // 000000003E4C: D5287D12 01AA280B
	v_add_co_u32 v19, vcc_lo, s8, v19                          // 000000003E54: D70F6A13 02022608
	v_add_co_ci_u32_e64 v20, null, s9, v20, vcc_lo             // 000000003E5C: D5287D14 01AA2809
	s_mov_b32 s18, 0                                           // 000000003E64: BE920380
	s_mov_b64 s[6:7], 0                                        // 000000003E68: BE860480
	v_add_co_u32 v21, vcc_lo, v8, s6                           // 000000003E6C: D70F6A15 02000D08
	v_add_co_ci_u32_e64 v22, null, s7, v9, vcc_lo              // 000000003E74: D5287D16 01AA1207
	v_add_co_u32 v23, vcc_lo, v19, s6                          // 000000003E7C: D70F6A17 02000D13
	v_add_co_ci_u32_e64 v24, null, s7, v20, vcc_lo             // 000000003E84: D5287D18 01AA2807
	v_add_co_u32 v25, vcc_lo, v4, s6                           // 000000003E8C: D70F6A19 02000D04
	v_add_co_ci_u32_e64 v26, null, s7, v7, vcc_lo              // 000000003E94: D5287D1A 01AA0E07
	v_add_co_u32 v27, vcc_lo, v15, s6                          // 000000003E9C: D70F6A1B 02000D0F
	v_add_co_ci_u32_e64 v28, null, s7, v16, vcc_lo             // 000000003EA4: D5287D1C 01AA2007
	s_clause 0x3                                               // 000000003EAC: BFA10003
	global_load_dwordx2 v[21:22], v[21:22], off slc            // 000000003EB0: DC368000 157D0015
	global_load_dwordx2 v[23:24], v[23:24], off slc            // 000000003EB8: DC368000 177D0017
	global_load_dwordx2 v[25:26], v[25:26], off slc            // 000000003EC0: DC368000 197D0019
	global_load_dwordx2 v[27:28], v[27:28], off slc            // 000000003EC8: DC368000 1B7D001B
	v_add_co_u32 v29, vcc_lo, v11, s6                          // 000000003ED0: D70F6A1D 02000D0B
	v_add_co_ci_u32_e64 v30, null, s7, v12, vcc_lo             // 000000003ED8: D5287D1E 01AA1807
	v_add_co_u32 v31, vcc_lo, v17, s6                          // 000000003EE0: D70F6A1F 02000D11
	v_add_co_ci_u32_e64 v32, null, s7, v18, vcc_lo             // 000000003EE8: D5287D20 01AA2407
	v_add_co_u32 v33, vcc_lo, v1, s6                           // 000000003EF0: D70F6A21 02000D01
	v_add_co_ci_u32_e64 v34, null, s7, v10, vcc_lo             // 000000003EF8: D5287D22 01AA1407
	v_add_co_u32 v2, vcc_lo, v2, s16                           // 000000003F00: D70F6A02 02002102
	v_add_co_ci_u32_e64 v3, null, s17, v3, vcc_lo              // 000000003F08: D5287D03 01AA0611
	v_add_co_u32 v35, vcc_lo, v13, s6                          // 000000003F10: D70F6A23 02000D0D
	v_add_co_ci_u32_e64 v36, null, s7, v14, vcc_lo             // 000000003F18: D5287D24 01AA1C07
	v_cmp_le_u64_e64 s0, s[4:5], v[2:3]                        // 000000003F20: D4E30000 02020404
	v_add_co_u32 v5, vcc_lo, v5, s16                           // 000000003F28: D70F6A05 02002105
	v_add_co_ci_u32_e64 v6, null, s17, v6, vcc_lo              // 000000003F30: D5287D06 01AA0C11
	s_add_u32 s6, s6, s14                                      // 000000003F38: 80060E06
	s_addc_u32 s7, s7, s15                                     // 000000003F3C: 82070F07
	s_or_b32 s18, s0, s18                                      // 000000003F40: 88121200
	s_waitcnt vmcnt(3)                                         // 000000003F44: BF8C3F73
	global_store_dwordx2 v[29:30], v[21:22], off glc slc       // 000000003F48: DC778000 007D151D
	s_waitcnt vmcnt(2)                                         // 000000003F50: BF8C3F72
	global_store_dwordx2 v[31:32], v[23:24], off glc slc       // 000000003F54: DC778000 007D171F
	s_waitcnt vmcnt(1)                                         // 000000003F5C: BF8C3F71
	global_store_dwordx2 v[33:34], v[25:26], off glc slc       // 000000003F60: DC778000 007D1921
	s_waitcnt vmcnt(0)                                         // 000000003F68: BF8C3F70
	global_store_dwordx2 v[35:36], v[27:28], off glc slc       // 000000003F6C: DC778000 007D1B23
	s_andn2_b32 exec_lo, exec_lo, s18                          // 000000003F74: 8A7E127E
	s_cbranch_execnz 65468                                     // 000000003F78: BF89FFBC <_Z16copy_nttp_kernelIXtl7CopyCfgLi8ELi4ELb1EEEEvPKcPcm+0x16c>
	s_or_b32 exec_lo, exec_lo, s18                             // 000000003F7C: 887E127E
	s_or_b32 exec_lo, exec_lo, s1                              // 000000003F80: 887E017E
	s_mov_b32 s1, exec_lo                                      // 000000003F84: BE81037E
	v_cmpx_gt_u64_e32 s[4:5], v[5:6]                           // 000000003F88: 7DE80A04
	s_cbranch_execz 33                                         // 000000003F8C: BF880021 <_Z16copy_nttp_kernelIXtl7CopyCfgLi8ELi4ELb1EEEEvPKcPcm+0x314>
	v_lshlrev_b64 v[3:4], 3, v[5:6]                            // 000000003F90: D6FF0003 02020A83
	s_lshl_b64 s[6:7], s[12:13], 3                             // 000000003F98: 8F86830C
	s_mov_b32 s14, 0                                           // 000000003F9C: BE8E0380
	v_add_co_u32 v1, vcc_lo, s8, v3                            // 000000003FA0: D70F6A01 02020608
	v_add_co_ci_u32_e64 v2, null, s9, v4, vcc_lo               // 000000003FA8: D5287D02 01AA0809
	v_add_co_u32 v3, vcc_lo, s10, v3                           // 000000003FB0: D70F6A03 0202060A
	v_add_co_ci_u32_e64 v4, null, s11, v4, vcc_lo              // 000000003FB8: D5287D04 01AA080B
	global_load_dwordx2 v[7:8], v[1:2], off slc                // 000000003FC0: DC368000 077D0001
	v_add_co_u32 v5, vcc_lo, v5, s12                           // 000000003FC8: D70F6A05 02001905
	v_add_co_ci_u32_e64 v6, null, s13, v6, vcc_lo              // 000000003FD0: D5287D06 01AA0C0D
	v_add_co_u32 v1, vcc_lo, v1, s6                            // 000000003FD8: D70F6A01 02000D01
	v_add_co_ci_u32_e64 v2, null, s7, v2, vcc_lo               // 000000003FE0: D5287D02 01AA0407
	v_cmp_le_u64_e32 vcc_lo, s[4:5], v[5:6]                    // 000000003FE8: 7DC60A04
	s_or_b32 s14, vcc_lo, s14                                  // 000000003FEC: 880E0E6A
	s_waitcnt vmcnt(0)                                         // 000000003FF0: BF8C3F70
	global_store_dwordx2 v[3:4], v[7:8], off glc slc           // 000000003FF4: DC778000 007D0703
	v_add_co_u32 v3, s0, v3, s6                                // 000000003FFC: D70F0003 02000D03
	v_add_co_ci_u32_e64 v4, null, s7, v4, s0                   // 000000004004: D5287D04 00020807
	s_andn2_b32 exec_lo, exec_lo, s14                          // 00000000400C: 8A7E0E7E
	s_cbranch_execnz 65515                                     // 000000004010: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi8ELi4ELb1EEEEvPKcPcm+0x2c0>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000004014: 887E017E
	s_and_b32 s0, s2, -8                                       // 000000004018: 8700C802
	v_add_co_u32 v0, s0, s0, v0                                // 00000000401C: D70F0000 02020000
	v_add_co_ci_u32_e64 v1, null, s3, 0, s0                    // 000000004024: D5287D01 00010003
	s_mov_b32 s0, exec_lo                                      // 00000000402C: BE80037E
	v_cmpx_gt_u64_e32 s[2:3], v[0:1]                           // 000000004030: 7DE80002
	s_cbranch_execz 23                                         // 000000004034: BF880017 <_Z16copy_nttp_kernelIXtl7CopyCfgLi8ELi4ELb1EEEEvPKcPcm+0x394>
	s_mov_b32 s0, 0                                            // 000000004038: BE800380
	s_nop 0                                                    // 00000000403C: BF800000
	v_add_co_u32 v2, vcc_lo, s8, v0                            // 000000004040: D70F6A02 02020008
	v_add_co_ci_u32_e64 v3, null, s9, v1, vcc_lo               // 000000004048: D5287D03 01AA0209
	global_load_ubyte v4, v[2:3], off                          // 000000004050: DC208000 047D0002
	v_add_co_u32 v2, vcc_lo, s10, v0                           // 000000004058: D70F6A02 0202000A
	v_add_co_ci_u32_e64 v3, null, s11, v1, vcc_lo              // 000000004060: D5287D03 01AA020B
	v_add_co_u32 v0, vcc_lo, v0, s12                           // 000000004068: D70F6A00 02001900
	v_add_co_ci_u32_e64 v1, null, s13, v1, vcc_lo              // 000000004070: D5287D01 01AA020D
	v_cmp_le_u64_e32 vcc_lo, s[2:3], v[0:1]                    // 000000004078: 7DC60002
	s_or_b32 s0, vcc_lo, s0                                    // 00000000407C: 8800006A
	s_waitcnt vmcnt(0)                                         // 000000004080: BF8C3F70
	global_store_byte v[2:3], v4, off                          // 000000004084: DC608000 007D0402
	s_andn2_b32 exec_lo, exec_lo, s0                           // 00000000408C: 8A7E007E
	s_cbranch_execnz 65515                                     // 000000004090: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi8ELi4ELb1EEEEvPKcPcm+0x340>
	s_endpgm                                                   // 000000004094: BF810000
		...

0000000000004100 <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi1EEEEvPKcPcm>:
	s_clause 0x3                                               // 000000004100: BFA10003
	s_load_dword s0, s[4:5], 0x24                              // 000000004104: F4000002 FA000024
	s_load_dwordx2 s[2:3], s[4:5], 0x10                        // 00000000410C: F4040082 FA000010
	s_load_dword s1, s[4:5], 0x18                              // 000000004114: F4000042 FA000018
	s_load_dwordx4 s[8:11], s[4:5], null                       // 00000000411C: F4080202 FA000000
	v_mov_b32_e32 v1, 0                                        // 000000004124: 7E020280
	s_waitcnt lgkmcnt(0)                                       // 000000004128: BF8CC07F
	s_and_b32 s0, s0, 0xffff                                   // 00000000412C: 8700FF00 0000FFFF
	v_mad_u64_u32 v[1:2], null, s0, s6, v[0:1]                 // 000000004134: D5767D01 04000C00
	s_lshr_b64 s[6:7], s[2:3], 4                               // 00000000413C: 90868402
	s_mul_hi_u32 s5, s1, s0                                    // 000000004140: 9A850001
	s_mul_i32 s4, s1, s0                                       // 000000004144: 93040001
	s_mov_b32 s1, exec_lo                                      // 000000004148: BE81037E
	v_cmpx_gt_u64_e32 s[6:7], v[1:2]                           // 00000000414C: 7DE80206
	s_cbranch_execz 49                                         // 000000004150: BF880031 <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi1EEEEvPKcPcm+0x118>
	v_lshlrev_b64 v[5:6], 4, v[1:2]                            // 000000004154: D6FF0005 02020284
	s_lshl_b64 s[12:13], s[4:5], 4                             // 00000000415C: 8F8C8404
	s_mov_b32 s14, 0                                           // 000000004160: BE8E0380
	v_add_co_u32 v3, vcc_lo, s10, v5                           // 000000004164: D70F6A03 02020A0A
	v_add_co_ci_u32_e64 v4, null, s11, v6, vcc_lo              // 00000000416C: D5287D04 01AA0C0B
	v_add_co_u32 v5, vcc_lo, s8, v5                            // 000000004174: D70F6A05 02020A08
	v_add_co_ci_u32_e64 v6, null, s9, v6, vcc_lo               // 00000000417C: D5287D06 01AA0C09
	s_nop 0                                                    // 000000004184: BF800000
	s_nop 0                                                    // 000000004188: BF800000
	s_nop 0                                                    // 00000000418C: BF800000
	s_nop 0                                                    // 000000004190: BF800000
	s_nop 0                                                    // 000000004194: BF800000
	s_nop 0                                                    // 000000004198: BF800000
	s_nop 0                                                    // 00000000419C: BF800000
	s_nop 0                                                    // 0000000041A0: BF800000
	s_nop 0                                                    // 0000000041A4: BF800000
	s_nop 0                                                    // 0000000041A8: BF800000
	s_nop 0                                                    // 0000000041AC: BF800000
	s_nop 0                                                    // 0000000041B0: BF800000
	s_nop 0                                                    // 0000000041B4: BF800000
	s_nop 0                                                    // 0000000041B8: BF800000
	s_nop 0                                                    // 0000000041BC: BF800000
	global_load_dwordx4 v[7:10], v[5:6], off                   // 0000000041C0: DC388000 077D0005
	v_add_co_u32 v1, vcc_lo, v1, s4                            // 0000000041C8: D70F6A01 02000901
	v_add_co_ci_u32_e64 v2, null, s5, v2, vcc_lo               // 0000000041D0: D5287D02 01AA0405
	v_add_co_u32 v5, vcc_lo, v5, s12                           // 0000000041D8: D70F6A05 02001905
	v_add_co_ci_u32_e64 v6, null, s13, v6, vcc_lo              // 0000000041E0: D5287D06 01AA0C0D
	v_cmp_le_u64_e32 vcc_lo, s[6:7], v[1:2]                    // 0000000041E8: 7DC60206
	s_or_b32 s14, vcc_lo, s14                                  // 0000000041EC: 880E0E6A
	s_waitcnt vmcnt(0)                                         // 0000000041F0: BF8C3F70
	global_store_dwordx4 v[3:4], v[7:10], off                  // 0000000041F4: DC788000 007D0703
	v_add_co_u32 v3, s0, v3, s12                               // 0000000041FC: D70F0003 02001903
	v_add_co_ci_u32_e64 v4, null, s13, v4, s0                  // 000000004204: D5287D04 0002080D
	s_andn2_b32 exec_lo, exec_lo, s14                          // 00000000420C: 8A7E0E7E
	s_cbranch_execnz 65515                                     // 000000004210: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi1EEEEvPKcPcm+0xc0>
	s_or_b32 exec_lo, exec_lo, s14                             // 000000004214: 887E0E7E
	s_or_b32 exec_lo, exec_lo, s1                              // 000000004218: 887E017E
	s_mov_b32 s1, exec_lo                                      // 00000000421C: BE81037E
	v_cmpx_gt_u64_e32 s[6:7], v[1:2]                           // 000000004220: 7DE80206
	s_cbranch_execz 43                                         // 000000004224: BF88002B <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi1EEEEvPKcPcm+0x1d4>
	v_lshlrev_b64 v[5:6], 4, v[1:2]                            // 000000004228: D6FF0005 02020284
	s_lshl_b64 s[12:13], s[4:5], 4                             // 000000004230: 8F8C8404
	s_mov_b32 s14, 0                                           // 000000004234: BE8E0380
	v_add_co_u32 v3, vcc_lo, s10, v5                           // 000000004238: D70F6A03 02020A0A
	v_add_co_ci_u32_e64 v4, null, s11, v6, vcc_lo              // 000000004240: D5287D04 01AA0C0B
	v_add_co_u32 v5, vcc_lo, s8, v5                            // 000000004248: D70F6A05 02020A08
	v_add_co_ci_u32_e64 v6, null, s9, v6, vcc_lo               // 000000004250: D5287D06 01AA0C09
	s_nop 0                                                    // 000000004258: BF800000
	s_nop 0                                                    // 00000000425C: BF800000
	s_nop 0                                                    // 000000004260: BF800000
	s_nop 0                                                    // 000000004264: BF800000
	s_nop 0                                                    // 000000004268: BF800000
	s_nop 0                                                    // 00000000426C: BF800000
	s_nop 0                                                    // 000000004270: BF800000
	s_nop 0                                                    // 000000004274: BF800000
	s_nop 0                                                    // 000000004278: BF800000
	s_nop 0                                                    // 00000000427C: BF800000
	global_load_dwordx4 v[7:10], v[5:6], off                   // 000000004280: DC388000 077D0005
	v_add_co_u32 v1, vcc_lo, v1, s4                            // 000000004288: D70F6A01 02000901
	v_add_co_ci_u32_e64 v2, null, s5, v2, vcc_lo               // 000000004290: D5287D02 01AA0405
	v_add_co_u32 v5, vcc_lo, v5, s12                           // 000000004298: D70F6A05 02001905
	v_add_co_ci_u32_e64 v6, null, s13, v6, vcc_lo              // 0000000042A0: D5287D06 01AA0C0D
	v_cmp_le_u64_e32 vcc_lo, s[6:7], v[1:2]                    // 0000000042A8: 7DC60206
	s_or_b32 s14, vcc_lo, s14                                  // 0000000042AC: 880E0E6A
	s_waitcnt vmcnt(0)                                         // 0000000042B0: BF8C3F70
	global_store_dwordx4 v[3:4], v[7:10], off                  // 0000000042B4: DC788000 007D0703
	v_add_co_u32 v3, s0, v3, s12                               // 0000000042BC: D70F0003 02001903
	v_add_co_ci_u32_e64 v4, null, s13, v4, s0                  // 0000000042C4: D5287D04 0002080D
	s_andn2_b32 exec_lo, exec_lo, s14                          // 0000000042CC: 8A7E0E7E
	s_cbranch_execnz 65515                                     // 0000000042D0: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi1EEEEvPKcPcm+0x180>
	s_or_b32 exec_lo, exec_lo, s1                              // 0000000042D4: 887E017E
	s_and_b32 s0, s2, -16                                      // 0000000042D8: 8700D002
	v_add_co_u32 v0, s0, s0, v0                                // 0000000042DC: D70F0000 02020000
	v_add_co_ci_u32_e64 v1, null, s3, 0, s0                    // 0000000042E4: D5287D01 00010003
	s_mov_b32 s0, exec_lo                                      // 0000000042EC: BE80037E
	v_cmpx_gt_u64_e32 s[2:3], v[0:1]                           // 0000000042F0: 7DE80002
	s_cbranch_execz 23                                         // 0000000042F4: BF880017 <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi1EEEEvPKcPcm+0x254>
	s_mov_b32 s0, 0                                            // 0000000042F8: BE800380
	s_nop 0                                                    // 0000000042FC: BF800000
	v_add_co_u32 v2, vcc_lo, s8, v0                            // 000000004300: D70F6A02 02020008
	v_add_co_ci_u32_e64 v3, null, s9, v1, vcc_lo               // 000000004308: D5287D03 01AA0209
	global_load_ubyte v4, v[2:3], off                          // 000000004310: DC208000 047D0002
	v_add_co_u32 v2, vcc_lo, s10, v0                           // 000000004318: D70F6A02 0202000A
	v_add_co_ci_u32_e64 v3, null, s11, v1, vcc_lo              // 000000004320: D5287D03 01AA020B
	v_add_co_u32 v0, vcc_lo, v0, s4                            // 000000004328: D70F6A00 02000900
	v_add_co_ci_u32_e64 v1, null, s5, v1, vcc_lo               // 000000004330: D5287D01 01AA0205
	v_cmp_le_u64_e32 vcc_lo, s[2:3], v[0:1]                    // 000000004338: 7DC60002
	s_or_b32 s0, vcc_lo, s0                                    // 00000000433C: 8800006A
	s_waitcnt vmcnt(0)                                         // 000000004340: BF8C3F70
	global_store_byte v[2:3], v4, off                          // 000000004344: DC608000 007D0402
	s_andn2_b32 exec_lo, exec_lo, s0                           // 00000000434C: 8A7E007E
	s_cbranch_execnz 65515                                     // 000000004350: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi16ELi1EEEEvPKcPcm+0x200>
	s_endpgm                                                   // 000000004354: BF810000
		...

0000000000004400 <_Z16copy_nttp_kernelIXtl7CopyCfgLi4ELi2EEEEvPKcPcm>:
	s_clause 0x3                                               // 000000004400: BFA10003
	s_load_dword s0, s[4:5], 0x24                              // 000000004404: F4000002 FA000024
	s_load_dword s22, s[4:5], 0x18                             // 00000000440C: F4000582 FA000018
	s_load_dwordx2 s[2:3], s[4:5], 0x10                        // 000000004414: F4040082 FA000010
	s_load_dwordx4 s[8:11], s[4:5], null                       // 00000000441C: F4080202 FA000000
	v_mov_b32_e32 v5, 0                                        // 000000004424: 7E0A0280
	s_mov_b32 s7, exec_lo                                      // 000000004428: BE87037E
	s_waitcnt lgkmcnt(0)                                       // 00000000442C: BF8CC07F
	s_and_b32 s21, s0, 0xffff                                  // 000000004430: 8715FF00 0000FFFF
	s_mul_i32 s0, s21, s6                                      // 000000004438: 93000615
	s_mul_hi_u32 s1, s21, s6                                   // 00000000443C: 9A810615
	v_add_co_u32 v1, s4, s0, v0                                // 000000004440: D70F0401 02020000
	v_add_co_ci_u32_e64 v2, null, s1, 0, s4                    // 000000004448: D5287D02 00110001
	s_mul_i32 s4, s22, s21                                     // 000000004450: 93041516
	s_mul_hi_u32 s5, s22, s21                                  // 000000004454: 9A851516
	v_add_co_u32 v3, vcc_lo, v1, s4                            // 000000004458: D70F6A03 02000901
	v_add_co_ci_u32_e64 v4, null, s5, v2, vcc_lo               // 000000004460: D5287D04 01AA0405
	s_lshr_b64 s[12:13], s[2:3], 2                             // 000000004468: 908C8202
	v_cmpx_gt_u64_e32 s[12:13], v[3:4]                         // 00000000446C: 7DE8060C
	s_cbranch_execz 80                                         // 000000004470: BF880050 <_Z16copy_nttp_kernelIXtl7CopyCfgLi4ELi2EEEEvPKcPcm+0x1b4>
	s_lshl_b64 s[16:17], s[0:1], 2                             // 000000004474: 8F908200
	v_lshlrev_b32_e32 v6, 2, v0                                // 000000004478: 340C0082
	s_add_u32 s1, s8, s16                                      // 00000000447C: 80011008
	s_addc_u32 s18, s9, s17                                    // 000000004480: 82121109
	s_lshl_b64 s[14:15], s[4:5], 3                             // 000000004484: 8F8E8304
	s_add_u32 s19, s10, s16                                    // 000000004488: 8013100A
	s_addc_u32 s20, s11, s17                                   // 00000000448C: 8214110B
	s_lshl_b64 s[16:17], s[4:5], 1                             // 000000004490: 8F908104
	s_add_u32 s0, s6, s22                                      // 000000004494: 80001606
	s_addc_u32 s6, 0, 0                                        // 000000004498: 82068080
	s_mul_hi_u32 s22, s0, s21                                  // 00000000449C: 9A961500
	s_mul_i32 s6, s6, s21                                      // 0000000044A0: 93061506
	s_add_i32 s23, s22, s6                                     // 0000000044A4: 81170616
	s_mul_i32 s22, s0, s21                                     // 0000000044A8: 93161500
	s_mov_b32 s6, 0                                            // 0000000044AC: BE860380
	s_lshl_b64 s[24:25], s[22:23], 2                           // 0000000044B0: 8F988216
	s_add_u32 s21, s10, s24                                    // 0000000044B4: 8015180A
	s_addc_u32 s22, s11, s25                                   // 0000000044B8: 8216190B
	s_add_u32 s23, s8, s24                                     // 0000000044BC: 80171808
	s_addc_u32 s24, s9, s25                                    // 0000000044C0: 82181909
	s_inst_prefetch 0x1                                        // 0000000044C4: BFA00001
	s_nop 0                                                    // 0000000044C8: BF800000
	s_nop 0                                                    // 0000000044CC: BF800000
	s_nop 0                                                    // 0000000044D0: BF800000
	s_nop 0                                                    // 0000000044D4: BF800000
	s_nop 0                                                    // 0000000044D8: BF800000
	s_nop 0                                                    // 0000000044DC: BF800000
	s_nop 0                                                    // 0000000044E0: BF800000
	s_nop 0                                                    // 0000000044E4: BF800000
	s_nop 0                                                    // 0000000044E8: BF800000
	s_nop 0                                                    // 0000000044EC: BF800000
	s_nop 0                                                    // 0000000044F0: BF800000
	s_nop 0                                                    // 0000000044F4: BF800000
	s_nop 0                                                    // 0000000044F8: BF800000
	s_nop 0                                                    // 0000000044FC: BF800000
	v_add_co_u32 v7, vcc_lo, s1, v6                            // 000000004500: D70F6A07 02020C01
	v_add_co_ci_u32_e64 v8, null, s18, v5, vcc_lo              // 000000004508: D5287D08 01AA0A12
	v_add_co_u32 v9, vcc_lo, s23, v6                           // 000000004510: D70F6A09 02020C17
	v_add_co_ci_u32_e64 v10, null, s24, v5, vcc_lo             // 000000004518: D5287D0A 01AA0A18
	s_clause 0x1                                               // 000000004520: BFA10001
	global_load_dword v11, v[7:8], off                         // 000000004524: DC308000 0B7D0007
	global_load_dword v12, v[9:10], off                        // 00000000452C: DC308000 0C7D0009
	v_add_co_u32 v7, vcc_lo, s19, v6                           // 000000004534: D70F6A07 02020C13
	v_add_co_ci_u32_e64 v8, null, s20, v5, vcc_lo              // 00000000453C: D5287D08 01AA0A14
	v_add_co_u32 v9, vcc_lo, s21, v6                           // 000000004544: D70F6A09 02020C15
	v_add_co_ci_u32_e64 v10, null, s22, v5, vcc_lo             // 00000000454C: D5287D0A 01AA0A16
	v_add_co_u32 v3, vcc_lo, v3, s16                           // 000000004554: D70F6A03 02002103
	v_add_co_ci_u32_e64 v4, null, s17, v4, vcc_lo              // 00000000455C: D5287D04 01AA0811
	v_add_co_u32 v6, vcc_lo, v6, s14                           // 000000004564: D70F6A06 02001D06
	v_add_co_ci_u32_e64 v5, null, s15, v5, vcc_lo              // 00000000456C: D5287D05 01AA0A0F
	v_cmp_le_u64_e32 vcc_lo, s[12:13], v[3:4]                  // 000000004574: 7DC6060C
	v_add_co_u32 v1, s0, v1, s16                               // 000000004578: D70F0001 02002101
	v_add_co_ci_u32_e64 v2, null, s17, v2, s0                  // 000000004580: D5287D02 00020411
	s_waitcnt vmcnt(1)                                         // 000000004588: BF8C3F71
	global_store_dword v[7:8], v11, off                        // 00000000458C: DC708000 007D0B07
	s_waitcnt vmcnt(0)                                         // 000000004594: BF8C3F70
	global_store_dword v[9:10], v12, off                       // 000000004598: DC708000 007D0C09
	s_or_b32 s6, vcc_lo, s6                                    // 0000000045A0: 8806066A
	s_andn2_b32 exec_lo, exec_lo, s6                           // 0000000045A4: 8A7E067E
	s_cbranch_execnz 65493                                     // 0000000045A8: BF89FFD5 <_Z16copy_nttp_kernelIXtl7CopyCfgLi4ELi2EEEEvPKcPcm+0x100>
	s_inst_prefetch 0x2                                        // 0000000045AC: BFA00002
	s_or_b32 exec_lo, exec_lo, s6                              // 0000000045B0: 887E067E
	s_or_b32 exec_lo, exec_lo, s7                              // 0000000045B4: 887E077E
	s_mov_b32 s1, exec_lo                                      // 0000000045B8: BE81037E
	v_cmpx_gt_u64_e32 s[12:13], v[1:2]                         // 0000000045BC: 7DE8020C
	s_cbranch_execz 36                                         // 0000000045C0: BF880024 <_Z16copy_nttp_kernelIXtl7CopyCfgLi4ELi2EEEEvPKcPcm+0x254>
	v_lshlrev_b64 v[5:6], 2, v[1:2]                            // 0000000045C4: D6FF0005 02020282
	s_lshl_b64 s[6:7], s[4:5], 2                               // 0000000045CC: 8F868204
	s_mov_b32 s14, 0                                           // 0000000045D0: BE8E0380
	v_add_co_u32 v3, vcc_lo, s8, v5                            // 0000000045D4: D70F6A03 02020A08
	v_add_co_ci_u32_e64 v4, null, s9, v6, vcc_lo               // 0000000045DC: D5287D04 01AA0C09
	v_add_co_u32 v5, vcc_lo, s10, v5                           // 0000000045E4: D70F6A05 02020A0A
	v_add_co_ci_u32_e64 v6, null, s11, v6, vcc_lo              // 0000000045EC: D5287D06 01AA0C0B
	s_nop 0                                                    // 0000000045F4: BF800000
	s_nop 0                                                    // 0000000045F8: BF800000
	s_nop 0                                                    // 0000000045FC: BF800000
	global_load_dword v7, v[3:4], off                          // 000000004600: DC308000 077D0003
	v_add_co_u32 v1, vcc_lo, v1, s4                            // 000000004608: D70F6A01 02000901
	v_add_co_ci_u32_e64 v2, null, s5, v2, vcc_lo               // 000000004610: D5287D02 01AA0405
	v_add_co_u32 v3, vcc_lo, v3, s6                            // 000000004618: D70F6A03 02000D03
	v_add_co_ci_u32_e64 v4, null, s7, v4, vcc_lo               // 000000004620: D5287D04 01AA0807
	v_cmp_le_u64_e32 vcc_lo, s[12:13], v[1:2]                  // 000000004628: 7DC6020C
	s_or_b32 s14, vcc_lo, s14                                  // 00000000462C: 880E0E6A
	s_waitcnt vmcnt(0)                                         // 000000004630: BF8C3F70
	global_store_dword v[5:6], v7, off                         // 000000004634: DC708000 007D0705
	v_add_co_u32 v5, s0, v5, s6                                // 00000000463C: D70F0005 02000D05
	v_add_co_ci_u32_e64 v6, null, s7, v6, s0                   // 000000004644: D5287D06 00020C07
	s_andn2_b32 exec_lo, exec_lo, s14                          // 00000000464C: 8A7E0E7E
	s_cbranch_execnz 65515                                     // 000000004650: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi4ELi2EEEEvPKcPcm+0x200>
	s_or_b32 exec_lo, exec_lo, s1                              // 000000004654: 887E017E
	s_and_b32 s0, s2, -4                                       // 000000004658: 8700C402
	v_add_co_u32 v0, s0, s0, v0                                // 00000000465C: D70F0000 02020000
	v_add_co_ci_u32_e64 v1, null, s3, 0, s0                    // 000000004664: D5287D01 00010003
	s_mov_b32 s0, exec_lo                                      // 00000000466C: BE80037E
	v_cmpx_gt_u64_e32 s[2:3], v[0:1]                           // 000000004670: 7DE80002
	s_cbranch_execz 23                                         // 000000004674: BF880017 <_Z16copy_nttp_kernelIXtl7CopyCfgLi4ELi2EEEEvPKcPcm+0x2d4>
	s_mov_b32 s0, 0                                            // 000000004678: BE800380
	s_nop 0                                                    // 00000000467C: BF800000
	v_add_co_u32 v2, vcc_lo, s8, v0                            // 000000004680: D70F6A02 02020008
	v_add_co_ci_u32_e64 v3, null, s9, v1, vcc_lo               // 000000004688: D5287D03 01AA0209
	global_load_ubyte v4, v[2:3], off                          // 000000004690: DC208000 047D0002
	v_add_co_u32 v2, vcc_lo, s10, v0                           // 000000004698: D70F6A02 0202000A
	v_add_co_ci_u32_e64 v3, null, s11, v1, vcc_lo              // 0000000046A0: D5287D03 01AA020B
	v_add_co_u32 v0, vcc_lo, v0, s4                            // 0000000046A8: D70F6A00 02000900
	v_add_co_ci_u32_e64 v1, null, s5, v1, vcc_lo               // 0000000046B0: D5287D01 01AA0205
	v_cmp_le_u64_e32 vcc_lo, s[2:3], v[0:1]                    // 0000000046B8: 7DC60002
	s_or_b32 s0, vcc_lo, s0                                    // 0000000046BC: 8800006A
	s_waitcnt vmcnt(0)                                         // 0000000046C0: BF8C3F70
	global_store_byte v[2:3], v4, off                          // 0000000046C4: DC608000 007D0402
	s_andn2_b32 exec_lo, exec_lo, s0                           // 0000000046CC: 8A7E007E
	s_cbranch_execnz 65515                                     // 0000000046D0: BF89FFEB <_Z16copy_nttp_kernelIXtl7CopyCfgLi4ELi2EEEEvPKcPcm+0x280>
	s_endpgm                                                   // 0000000046D4: BF810000
