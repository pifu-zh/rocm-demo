; ModuleID = '/home/zhuo/workspace/src/rocm-demo/demos/mori/compiler/shmem_bitcode_pipeline/results/ir/api_O0.bc'
source_filename = "/home/zhuo/workspace/src/rocm-demo/demos/mori/compiler/shmem_bitcode_pipeline/src/shmem_api.hip"
target datalayout = "e-m:e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128:128:48-p9:192:256:256:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
target triple = "amdgcn-amd-amdhsa"

%struct.__hip_builtin_threadIdx_t = type { i8 }
%"struct.mori::shmem::GpuStates" = type { i64, i32, i32 }
%struct.__hip_builtin_blockDim_t = type { i8 }

@_ZZ13__assert_failE3fmt = internal addrspace(4) constant [47 x i8] c"%s:%u: %s: Device-side assertion `%s' failed.\0A\00", align 16, !guid !0
@threadIdx = extern_weak protected addrspace(1) global %struct.__hip_builtin_threadIdx_t, align 1
@_ZN4mori5shmem15globalGpuStatesE = external protected addrspace(1) global %"struct.mori::shmem::GpuStates", align 8
@blockDim = extern_weak protected addrspace(1) global %struct.__hip_builtin_blockDim_t, align 1
@__hip_cuid_ba1d321b695b6efc = addrspace(1) global i8 0, !guid !1
@llvm.compiler.used = appending addrspace(1) global [2 x ptr] [ptr @_ZN4mori5shmem14device_add_oneEPjPKji, ptr addrspacecast (ptr addrspace(1) @__hip_cuid_ba1d321b695b6efc to ptr)], section "llvm.metadata", !guid !2
@__oclc_ISA_version = internal local_unnamed_addr addrspace(4) constant i32 10300, align 4, !guid !3
@__oclc_ABI_version = internal local_unnamed_addr addrspace(4) constant i32 500, align 4, !guid !4

; Function Attrs: convergent mustprogress noinline noreturn nounwind optnone uwtable
define weak void @__cxa_pure_virtual() #0 !guid !19 {
  call void @llvm.trap() #13
  unreachable
}

; Function Attrs: cold noreturn nounwind memory(inaccessiblemem: write)
declare void @llvm.trap() #1

; Function Attrs: convergent mustprogress noinline noreturn nounwind optnone uwtable
define weak void @__cxa_deleted_virtual() #0 !guid !20 {
  call void @llvm.trap() #13
  unreachable
}

; Function Attrs: convergent mustprogress noinline nounwind optnone uwtable
define weak hidden void @__assert_fail(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3) #2 !guid !21 {
  %5 = alloca ptr, align 8, addrspace(5)
  %6 = alloca ptr, align 8, addrspace(5)
  %7 = alloca i32, align 4, addrspace(5)
  %8 = alloca ptr, align 8, addrspace(5)
  %9 = alloca i64, align 8, addrspace(5)
  %10 = alloca i32, align 4, addrspace(5)
  %11 = alloca ptr, align 8, addrspace(5)
  %12 = alloca ptr, align 8, addrspace(5)
  %13 = alloca ptr, align 8, addrspace(5)
  %14 = alloca ptr, align 8, addrspace(5)
  %15 = addrspacecast ptr addrspace(5) %5 to ptr
  %16 = addrspacecast ptr addrspace(5) %6 to ptr
  %17 = addrspacecast ptr addrspace(5) %7 to ptr
  %18 = addrspacecast ptr addrspace(5) %8 to ptr
  %19 = addrspacecast ptr addrspace(5) %9 to ptr
  %20 = addrspacecast ptr addrspace(5) %10 to ptr
  %21 = addrspacecast ptr addrspace(5) %11 to ptr
  %22 = addrspacecast ptr addrspace(5) %12 to ptr
  %23 = addrspacecast ptr addrspace(5) %13 to ptr
  %24 = addrspacecast ptr addrspace(5) %14 to ptr
  store ptr %0, ptr %15, align 8
  store ptr %1, ptr %16, align 8
  store i32 %2, ptr %17, align 4
  store ptr %3, ptr %18, align 8
  %25 = call i64 @__ockl_fprintf_stderr_begin() #14
  store i64 %25, ptr %19, align 8
  store i32 0, ptr %20, align 4
  br label %26

26:                                               ; preds = %4
  store ptr addrspacecast (ptr addrspace(4) @_ZZ13__assert_failE3fmt to ptr), ptr %21, align 8
  br label %27

27:                                               ; preds = %32, %26
  %28 = load ptr, ptr %21, align 8
  %29 = getelementptr inbounds nuw i8, ptr %28, i32 1
  store ptr %29, ptr %21, align 8
  %30 = load i8, ptr %28, align 1
  %31 = icmp ne i8 %30, 0
  br i1 %31, label %32, label %33

32:                                               ; preds = %27
  br label %27, !llvm.loop !22

33:                                               ; preds = %27
  %34 = load ptr, ptr %21, align 8
  %35 = ptrtoint ptr %34 to i64
  %36 = sub i64 %35, ptrtoint (ptr addrspacecast (ptr addrspace(4) @_ZZ13__assert_failE3fmt to ptr) to i64)
  %37 = trunc i64 %36 to i32
  store i32 %37, ptr %20, align 4
  br label %38

38:                                               ; preds = %33
  %39 = load i64, ptr %19, align 8
  %40 = load i32, ptr %20, align 4
  %41 = sext i32 %40 to i64
  %42 = call i64 @__ockl_fprintf_append_string_n(i64 noundef %39, ptr noundef addrspacecast (ptr addrspace(4) @_ZZ13__assert_failE3fmt to ptr), i64 noundef %41, i32 noundef 0) #14
  store i64 %42, ptr %19, align 8
  br label %43

43:                                               ; preds = %38
  %44 = load ptr, ptr %16, align 8
  store ptr %44, ptr %22, align 8
  br label %45

45:                                               ; preds = %50, %43
  %46 = load ptr, ptr %22, align 8
  %47 = getelementptr inbounds nuw i8, ptr %46, i32 1
  store ptr %47, ptr %22, align 8
  %48 = load i8, ptr %46, align 1
  %49 = icmp ne i8 %48, 0
  br i1 %49, label %50, label %51

50:                                               ; preds = %45
  br label %45, !llvm.loop !24

51:                                               ; preds = %45
  %52 = load ptr, ptr %22, align 8
  %53 = load ptr, ptr %16, align 8
  %54 = ptrtoint ptr %52 to i64
  %55 = ptrtoint ptr %53 to i64
  %56 = sub i64 %54, %55
  %57 = trunc i64 %56 to i32
  store i32 %57, ptr %20, align 4
  br label %58

58:                                               ; preds = %51
  %59 = load i64, ptr %19, align 8
  %60 = load ptr, ptr %16, align 8
  %61 = load i32, ptr %20, align 4
  %62 = sext i32 %61 to i64
  %63 = call i64 @__ockl_fprintf_append_string_n(i64 noundef %59, ptr noundef %60, i64 noundef %62, i32 noundef 0) #14
  store i64 %63, ptr %19, align 8
  %64 = load i64, ptr %19, align 8
  %65 = load i32, ptr %17, align 4
  %66 = zext i32 %65 to i64
  %67 = call i64 @__ockl_fprintf_append_args(i64 noundef %64, i32 noundef 1, i64 noundef %66, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i32 noundef 0) #14
  store i64 %67, ptr %19, align 8
  br label %68

68:                                               ; preds = %58
  %69 = load ptr, ptr %18, align 8
  store ptr %69, ptr %23, align 8
  br label %70

70:                                               ; preds = %75, %68
  %71 = load ptr, ptr %23, align 8
  %72 = getelementptr inbounds nuw i8, ptr %71, i32 1
  store ptr %72, ptr %23, align 8
  %73 = load i8, ptr %71, align 1
  %74 = icmp ne i8 %73, 0
  br i1 %74, label %75, label %76

75:                                               ; preds = %70
  br label %70, !llvm.loop !25

76:                                               ; preds = %70
  %77 = load ptr, ptr %23, align 8
  %78 = load ptr, ptr %18, align 8
  %79 = ptrtoint ptr %77 to i64
  %80 = ptrtoint ptr %78 to i64
  %81 = sub i64 %79, %80
  %82 = trunc i64 %81 to i32
  store i32 %82, ptr %20, align 4
  br label %83

83:                                               ; preds = %76
  %84 = load i64, ptr %19, align 8
  %85 = load ptr, ptr %18, align 8
  %86 = load i32, ptr %20, align 4
  %87 = sext i32 %86 to i64
  %88 = call i64 @__ockl_fprintf_append_string_n(i64 noundef %84, ptr noundef %85, i64 noundef %87, i32 noundef 0) #14
  store i64 %88, ptr %19, align 8
  br label %89

89:                                               ; preds = %83
  %90 = load ptr, ptr %15, align 8
  store ptr %90, ptr %24, align 8
  br label %91

91:                                               ; preds = %96, %89
  %92 = load ptr, ptr %24, align 8
  %93 = getelementptr inbounds nuw i8, ptr %92, i32 1
  store ptr %93, ptr %24, align 8
  %94 = load i8, ptr %92, align 1
  %95 = icmp ne i8 %94, 0
  br i1 %95, label %96, label %97

96:                                               ; preds = %91
  br label %91, !llvm.loop !26

97:                                               ; preds = %91
  %98 = load ptr, ptr %24, align 8
  %99 = load ptr, ptr %15, align 8
  %100 = ptrtoint ptr %98 to i64
  %101 = ptrtoint ptr %99 to i64
  %102 = sub i64 %100, %101
  %103 = trunc i64 %102 to i32
  store i32 %103, ptr %20, align 4
  br label %104

104:                                              ; preds = %97
  %105 = load i64, ptr %19, align 8
  %106 = load ptr, ptr %15, align 8
  %107 = load i32, ptr %20, align 4
  %108 = sext i32 %107 to i64
  %109 = call i64 @__ockl_fprintf_append_string_n(i64 noundef %105, ptr noundef %106, i64 noundef %108, i32 noundef 1) #14
  call void @llvm.trap() #13
  unreachable
}

; Function Attrs: convergent mustprogress noinline nounwind optnone uwtable
define weak hidden void @__assertfail() #2 !guid !27 {
  call void @llvm.trap() #13
  unreachable
}

; Function Attrs: convergent mustprogress noinline nounwind optnone uwtable
define hidden void @_ZN4mori5shmem14device_add_oneEPjPKji(ptr noundef %0, ptr noundef %1, i32 noundef %2) #2 !guid !28 {
  %4 = alloca ptr, align 8, addrspace(5)
  %5 = alloca ptr, align 8, addrspace(5)
  %6 = alloca i32, align 4, addrspace(5)
  %7 = alloca i32, align 4, addrspace(5)
  %8 = addrspacecast ptr addrspace(5) %4 to ptr
  %9 = addrspacecast ptr addrspace(5) %5 to ptr
  %10 = addrspacecast ptr addrspace(5) %6 to ptr
  %11 = addrspacecast ptr addrspace(5) %7 to ptr
  store ptr %0, ptr %8, align 8
  store ptr %1, ptr %9, align 8
  store i32 %2, ptr %10, align 4
  %12 = call noundef i32 @llvm.amdgcn.workitem.id.x()
  store i32 %12, ptr %11, align 4
  br label %13

13:                                               ; preds = %30, %3
  %14 = load i32, ptr %11, align 4
  %15 = load i32, ptr %10, align 4
  %16 = icmp slt i32 %14, %15
  br i1 %16, label %17, label %37

17:                                               ; preds = %13
  %18 = load ptr, ptr %9, align 8
  %19 = load i32, ptr %11, align 4
  %20 = sext i32 %19 to i64
  %21 = getelementptr inbounds i32, ptr %18, i64 %20
  %22 = load i32, ptr %21, align 4
  %23 = load i64, ptr addrspacecast (ptr addrspace(1) @_ZN4mori5shmem15globalGpuStatesE to ptr), align 8
  %24 = trunc i64 %23 to i32
  %25 = add i32 %22, %24
  %26 = load ptr, ptr %8, align 8
  %27 = load i32, ptr %11, align 4
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds i32, ptr %26, i64 %28
  store i32 %25, ptr %29, align 4
  br label %30

30:                                               ; preds = %17
  %31 = call align 8 dereferenceable(256) ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %32 = getelementptr inbounds i8, ptr addrspace(4) %31, i64 12
  %33 = load i16, ptr addrspace(4) %32, align 2, !range !29, !invariant.load !30, !noundef !30
  %34 = zext i16 %33 to i32
  %35 = load i32, ptr %11, align 4
  %36 = add i32 %35, %34
  store i32 %36, ptr %11, align 4
  br label %13, !llvm.loop !31

37:                                               ; preds = %13
  ret void
}

; Function Attrs: convergent mustprogress noinline nounwind optnone uwtable
define hidden noundef i32 @_ZN4mori5shmem11device_pickEPKji(ptr noundef %0, i32 noundef %1) #2 !guid !32 {
  %3 = alloca ptr, align 8, addrspace(5)
  %4 = alloca i32, align 4, addrspace(5)
  %5 = alloca i32, align 4, addrspace(5)
  %6 = alloca i32, align 4, addrspace(5)
  %7 = addrspacecast ptr addrspace(5) %3 to ptr
  %8 = addrspacecast ptr addrspace(5) %4 to ptr
  %9 = addrspacecast ptr addrspace(5) %5 to ptr
  %10 = addrspacecast ptr addrspace(5) %6 to ptr
  store ptr %0, ptr %7, align 8
  store i32 %1, ptr %8, align 4
  %11 = load ptr, ptr %7, align 8
  %12 = load i32, ptr %8, align 4
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds i32, ptr %11, i64 %13
  %15 = load i32, ptr %14, align 4
  store i32 %15, ptr %9, align 4
  %16 = load i32, ptr %9, align 4
  %17 = load i64, ptr addrspacecast (ptr addrspace(1) @_ZN4mori5shmem15globalGpuStatesE to ptr), align 8
  %18 = trunc i64 %17 to i32
  %19 = add i32 %16, %18
  store i32 %19, ptr %10, align 4
  %20 = load i32, ptr %10, align 4
  store i32 %20, ptr %9, align 4
  %21 = load i32, ptr %9, align 4
  ret i32 %21
}

; Function Attrs: convergent mustprogress noinline norecurse nounwind optnone uwtable
define protected amdgpu_kernel void @shmem_internal_test_kernel(ptr addrspace(1) noundef %0, ptr addrspace(1) noundef %1, i32 noundef %2) #3 !guid !33 {
  %4 = alloca ptr, align 8, addrspace(5)
  %5 = alloca ptr, align 8, addrspace(5)
  %6 = alloca ptr, align 8, addrspace(5)
  %7 = alloca ptr, align 8, addrspace(5)
  %8 = alloca i32, align 4, addrspace(5)
  %9 = addrspacecast ptr addrspace(5) %6 to ptr
  %10 = addrspacecast ptr addrspace(5) %7 to ptr
  %11 = addrspacecast ptr addrspace(5) %8 to ptr
  store ptr addrspace(1) %0, ptr addrspace(5) %4, align 8
  %12 = load ptr, ptr addrspace(5) %4, align 8
  store ptr addrspace(1) %1, ptr addrspace(5) %5, align 8
  %13 = load ptr, ptr addrspace(5) %5, align 8
  store ptr %12, ptr %9, align 8
  store ptr %13, ptr %10, align 8
  store i32 %2, ptr %11, align 4
  %14 = load ptr, ptr %9, align 8
  %15 = load ptr, ptr %10, align 8
  %16 = load i32, ptr %11, align 4
  call void @_ZN4mori5shmem14device_add_oneEPjPKji(ptr noundef %14, ptr noundef %15, i32 noundef %16) #14
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 1024) i32 @llvm.amdgcn.workitem.id.x() #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef align 4 ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr() #4

; Function Attrs: convergent norecurse nounwind uwtable
define internal i64 @__ockl_fprintf_stderr_begin() #5 !guid !34 {
  %1 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef 33, i64 noundef 1, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0) #15
  %2 = extractelement <2 x i64> %1, i64 0
  ret i64 %2
}

; Function Attrs: cold convergent norecurse nounwind uwtable
define internal <2 x i64> @__ockl_hostcall_preview(i32 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) local_unnamed_addr #6 !guid !35 {
  %10 = load i32, ptr addrspace(4) @__oclc_ABI_version, align 4, !tbaa !36
  %11 = icmp slt i32 %10, 500
  %12 = tail call dereferenceable(256) ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %13 = select i1 %11, i64 24, i64 80
  %14 = getelementptr inbounds nuw i8, ptr addrspace(4) %12, i64 %13
  %15 = load i64, ptr addrspace(4) %14, align 8, !tbaa !37
  %16 = inttoptr i64 %15 to ptr addrspace(1)
  %17 = addrspacecast ptr addrspace(1) %16 to ptr
  %18 = tail call <2 x i64> @__ockl_hostcall_internal(ptr noundef %17, i32 noundef %0, i64 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) #16
  ret <2 x i64> %18
}

; Function Attrs: convergent norecurse nounwind uwtable
define internal <2 x i64> @__ockl_hostcall_internal(ptr nofree noundef captures(none) %0, i32 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, i64 noundef %9) local_unnamed_addr #5 !guid !39 {
  %11 = tail call range(i32 0, 33) i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0)
  %12 = tail call range(i32 0, 65) i32 @llvm.amdgcn.mbcnt.hi(i32 -1, i32 %11)
  %13 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %12)
  %14 = addrspacecast ptr %0 to ptr addrspace(1)
  %15 = icmp eq i32 %12, %13
  br i1 %15, label %16, label %38

16:                                               ; preds = %10
  %17 = getelementptr inbounds nuw i8, ptr addrspace(1) %14, i64 24
  %18 = load atomic i64, ptr addrspace(1) %17 syncscope("one-as") acquire, align 8
  %19 = getelementptr i8, ptr addrspace(1) %14, i64 40
  %20 = load ptr addrspace(1), ptr addrspace(1) %14, align 8, !tbaa !40
  %21 = load i64, ptr addrspace(1) %19, align 8, !tbaa !44
  %22 = and i64 %21, %18
  %23 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %20, i64 %22
  %24 = load atomic i64, ptr addrspace(1) %23 syncscope("one-as") monotonic, align 8
  %25 = cmpxchg ptr addrspace(1) %17, i64 %18, i64 %24 syncscope("one-as") acquire monotonic, align 8
  %26 = extractvalue { i64, i1 } %25, 1
  %27 = extractvalue { i64, i1 } %25, 0
  br i1 %26, label %38, label %28

28:                                               ; preds = %28, %16
  %29 = phi i64 [ %37, %28 ], [ %27, %16 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %30 = load ptr addrspace(1), ptr addrspace(1) %14, align 8, !tbaa !40
  %31 = load i64, ptr addrspace(1) %19, align 8, !tbaa !44
  %32 = and i64 %31, %29
  %33 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %30, i64 %32
  %34 = load atomic i64, ptr addrspace(1) %33 syncscope("one-as") monotonic, align 8
  %35 = cmpxchg ptr addrspace(1) %17, i64 %29, i64 %34 syncscope("one-as") acquire monotonic, align 8
  %36 = extractvalue { i64, i1 } %35, 1
  %37 = extractvalue { i64, i1 } %35, 0
  br i1 %36, label %38, label %28

38:                                               ; preds = %28, %16, %10
  %39 = phi i64 [ 0, %10 ], [ %27, %16 ], [ %37, %28 ]
  %40 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %39)
  %41 = load ptr addrspace(1), ptr addrspace(1) %14, align 8, !tbaa !40
  %42 = getelementptr i8, ptr addrspace(1) %14, i64 40
  %43 = load i64, ptr addrspace(1) %42, align 8, !tbaa !44
  %44 = and i64 %43, %40
  %45 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %41, i64 %44
  %46 = getelementptr i8, ptr addrspace(1) %14, i64 8
  %47 = load ptr addrspace(1), ptr addrspace(1) %46, align 8, !tbaa !45
  %48 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %47, i64 %44
  %49 = tail call i64 @llvm.amdgcn.ballot.i64(i1 true)
  br i1 %15, label %50, label %54

50:                                               ; preds = %38
  %51 = getelementptr inbounds nuw i8, ptr addrspace(1) %45, i64 16
  %52 = getelementptr inbounds nuw i8, ptr addrspace(1) %45, i64 8
  %53 = getelementptr inbounds nuw i8, ptr addrspace(1) %45, i64 20
  store i32 %1, ptr addrspace(1) %51, align 8, !tbaa !46
  store i64 %49, ptr addrspace(1) %52, align 8, !tbaa !48
  store i32 1, ptr addrspace(1) %53, align 4, !tbaa !49
  br label %54

54:                                               ; preds = %50, %38
  %55 = zext i32 %12 to i64
  %56 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %48, i64 %55
  store i64 %2, ptr addrspace(1) %56, align 8, !tbaa !37
  %57 = getelementptr inbounds nuw i8, ptr addrspace(1) %56, i64 8
  store i64 %3, ptr addrspace(1) %57, align 8, !tbaa !37
  %58 = getelementptr inbounds nuw i8, ptr addrspace(1) %56, i64 16
  store i64 %4, ptr addrspace(1) %58, align 8, !tbaa !37
  %59 = getelementptr inbounds nuw i8, ptr addrspace(1) %56, i64 24
  store i64 %5, ptr addrspace(1) %59, align 8, !tbaa !37
  %60 = getelementptr inbounds nuw i8, ptr addrspace(1) %56, i64 32
  store i64 %6, ptr addrspace(1) %60, align 8, !tbaa !37
  %61 = getelementptr inbounds nuw i8, ptr addrspace(1) %56, i64 40
  store i64 %7, ptr addrspace(1) %61, align 8, !tbaa !37
  %62 = getelementptr inbounds nuw i8, ptr addrspace(1) %56, i64 48
  store i64 %8, ptr addrspace(1) %62, align 8, !tbaa !37
  %63 = getelementptr inbounds nuw i8, ptr addrspace(1) %56, i64 56
  store i64 %9, ptr addrspace(1) %63, align 8, !tbaa !37
  br i1 %15, label %64, label %80

64:                                               ; preds = %54
  %65 = getelementptr inbounds nuw i8, ptr addrspace(1) %14, i64 32
  %66 = load atomic i64, ptr addrspace(1) %65 syncscope("one-as") monotonic, align 8
  %67 = load i64, ptr addrspace(1) %42, align 8, !tbaa !44
  %68 = and i64 %67, %40
  %69 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %41, i64 %68
  store i64 %66, ptr addrspace(1) %69, align 8, !tbaa !50
  %70 = cmpxchg ptr addrspace(1) %65, i64 %66, i64 %40 syncscope("one-as") release monotonic, align 8
  %71 = extractvalue { i64, i1 } %70, 1
  br i1 %71, label %77, label %72

72:                                               ; preds = %72, %64
  %73 = phi { i64, i1 } [ %75, %72 ], [ %70, %64 ]
  %74 = extractvalue { i64, i1 } %73, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %74, ptr addrspace(1) %69, align 8, !tbaa !50
  %75 = cmpxchg ptr addrspace(1) %65, i64 %74, i64 %40 syncscope("one-as") release monotonic, align 8
  %76 = extractvalue { i64, i1 } %75, 1
  br i1 %76, label %77, label %72

77:                                               ; preds = %72, %64
  %78 = getelementptr inbounds nuw i8, ptr addrspace(1) %14, i64 16
  %79 = load i64, ptr addrspace(1) %78, align 8
  tail call void @__ockl_hsa_signal_add(i64 %79, i64 noundef 1, i32 noundef 3) #15
  br label %80

80:                                               ; preds = %77, %54
  %81 = getelementptr inbounds nuw i8, ptr addrspace(1) %45, i64 20
  br label %82

82:                                               ; preds = %90, %80
  br i1 %15, label %83, label %86

83:                                               ; preds = %82
  %84 = load atomic i32, ptr addrspace(1) %81 syncscope("one-as") acquire, align 4
  %85 = and i32 %84, 1
  br label %86

86:                                               ; preds = %83, %82
  %87 = phi i32 [ %85, %83 ], [ 1, %82 ]
  %88 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %87)
  %89 = icmp eq i32 %88, 0
  br i1 %89, label %91, label %90

90:                                               ; preds = %86
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %82

91:                                               ; preds = %86
  %92 = load i64, ptr addrspace(1) %56, align 8, !tbaa !37
  %93 = load i64, ptr addrspace(1) %57, align 8, !tbaa !37
  br i1 %15, label %94, label %112

94:                                               ; preds = %91
  %95 = load i64, ptr addrspace(1) %42, align 8, !tbaa !44
  %96 = add i64 %95, 1
  %97 = add i64 %96, %40
  %98 = icmp eq i64 %97, 0
  %99 = select i1 %98, i64 %96, i64 %97
  %100 = getelementptr inbounds nuw i8, ptr addrspace(1) %14, i64 24
  %101 = load atomic i64, ptr addrspace(1) %100 syncscope("one-as") monotonic, align 8
  %102 = load ptr addrspace(1), ptr addrspace(1) %14, align 8, !tbaa !40
  %103 = and i64 %99, %95
  %104 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %102, i64 %103
  store i64 %101, ptr addrspace(1) %104, align 8, !tbaa !50
  %105 = cmpxchg ptr addrspace(1) %100, i64 %101, i64 %99 syncscope("one-as") release monotonic, align 8
  %106 = extractvalue { i64, i1 } %105, 1
  br i1 %106, label %112, label %107

107:                                              ; preds = %107, %94
  %108 = phi { i64, i1 } [ %110, %107 ], [ %105, %94 ]
  %109 = extractvalue { i64, i1 } %108, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %109, ptr addrspace(1) %104, align 8, !tbaa !50
  %110 = cmpxchg ptr addrspace(1) %100, i64 %109, i64 %99 syncscope("one-as") release monotonic, align 8
  %111 = extractvalue { i64, i1 } %110, 1
  br i1 %111, label %112, label %107

112:                                              ; preds = %107, %94, %91
  %113 = insertelement <2 x i64> poison, i64 %92, i64 0
  %114 = insertelement <2 x i64> %113, i64 %93, i64 1
  ret <2 x i64> %114
}

; Function Attrs: convergent nocallback nocreateundeforpoison nofree nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.readfirstlane.i32(i32) #7

; Function Attrs: nocallback nofree nosync nounwind willreturn
declare void @llvm.amdgcn.s.sleep(i32 immarg) #8

; Function Attrs: convergent nocallback nocreateundeforpoison nofree nounwind willreturn memory(none)
declare i64 @llvm.amdgcn.readfirstlane.i64(i64) #7

; Function Attrs: convergent nocallback nocreateundeforpoison nofree nounwind willreturn memory(none)
declare i64 @llvm.amdgcn.ballot.i64(i1) #7

; Function Attrs: convergent mustprogress norecurse nounwind willreturn uwtable
define internal void @__ockl_hsa_signal_add(i64 %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #9 !guid !51 {
  %4 = inttoptr i64 %0 to ptr addrspace(1)
  %5 = getelementptr inbounds nuw i8, ptr addrspace(1) %4, i64 8
  switch i32 %2, label %6 [
    i32 1, label %8
    i32 2, label %8
    i32 3, label %10
    i32 4, label %12
    i32 5, label %14
  ]

6:                                                ; preds = %3
  %7 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") monotonic, align 8, !amdgpu.no.fine.grained.memory !30, !amdgpu.no.remote.memory !30
  br label %16

8:                                                ; preds = %3, %3
  %9 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") acquire, align 8, !amdgpu.no.fine.grained.memory !30, !amdgpu.no.remote.memory !30
  br label %16

10:                                               ; preds = %3
  %11 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !30, !amdgpu.no.remote.memory !30
  br label %16

12:                                               ; preds = %3
  %13 = atomicrmw add ptr addrspace(1) %5, i64 %1 syncscope("one-as") acq_rel, align 8, !amdgpu.no.fine.grained.memory !30, !amdgpu.no.remote.memory !30
  br label %16

14:                                               ; preds = %3
  %15 = atomicrmw add ptr addrspace(1) %5, i64 %1 seq_cst, align 8, !amdgpu.no.fine.grained.memory !30, !amdgpu.no.remote.memory !30
  br label %16

16:                                               ; preds = %14, %12, %10, %8, %6
  %17 = getelementptr inbounds nuw i8, ptr addrspace(1) %4, i64 16
  %18 = load i64, ptr addrspace(1) %17, align 16, !tbaa !52
  %19 = icmp eq i64 %18, 0
  br i1 %19, label %33, label %20

20:                                               ; preds = %16
  %21 = inttoptr i64 %18 to ptr addrspace(1)
  %22 = getelementptr inbounds nuw i8, ptr addrspace(1) %4, i64 24
  %23 = load i32, ptr addrspace(1) %22, align 8, !tbaa !54
  %24 = zext i32 %23 to i64
  store atomic i64 %24, ptr addrspace(1) %21 syncscope("one-as") release, align 8
  %25 = load i32, ptr addrspace(4) @__oclc_ISA_version, align 4, !tbaa !36
  %26 = icmp slt i32 %25, 9000
  %27 = add i32 %25, -11000
  %28 = icmp ult i32 %27, -1000
  %29 = select i1 %28, i32 16777215, i32 8388607
  %30 = select i1 %26, i32 255, i32 %29
  %31 = and i32 %30, %23
  %32 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %31)
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %32)
  br label %33

33:                                               ; preds = %20, %16
  ret void
}

; Function Attrs: nocallback nounwind willreturn
declare void @llvm.amdgcn.s.sendmsg(i32 immarg, i32) #10

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.mbcnt.lo(i32, i32) #11

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.mbcnt.hi(i32, i32) #11

; Function Attrs: convergent norecurse nounwind uwtable
define internal i64 @__ockl_fprintf_append_args(i64 noundef %0, i32 noundef %1, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8, i32 noundef %9) #5 !guid !55 {
  %11 = icmp eq i32 %9, 0
  %12 = or i64 %0, 2
  %13 = select i1 %11, i64 %0, i64 %12
  %14 = and i64 %13, -225
  %15 = zext i32 %1 to i64
  %16 = shl nuw nsw i64 %15, 5
  %17 = or i64 %14, %16
  %18 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %17, i64 noundef %2, i64 noundef %3, i64 noundef %4, i64 noundef %5, i64 noundef %6, i64 noundef %7, i64 noundef %8) #15
  %19 = extractelement <2 x i64> %18, i64 0
  ret i64 %19
}

; Function Attrs: convergent norecurse nounwind uwtable
define internal i64 @__ockl_fprintf_append_string_n(i64 noundef %0, ptr nofree noundef readonly %1, i64 noundef %2, i32 noundef %3) #5 !guid !56 {
  %5 = icmp eq i32 %3, 0
  %6 = or i64 %0, 2
  %7 = select i1 %5, i64 %0, i64 %6
  %8 = icmp eq ptr %1, null
  br i1 %8, label %9, label %13

9:                                                ; preds = %4
  %10 = and i64 %7, -225
  %11 = or disjoint i64 %10, 32
  %12 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %11, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0, i64 noundef 0) #15
  br label %452

13:                                               ; preds = %4
  %14 = and i64 %7, 2
  %15 = and i64 %7, -3
  %16 = insertelement <2 x i64> <i64 poison, i64 0>, i64 %15, i64 0
  br label %17

17:                                               ; preds = %440, %13
  %18 = phi i64 [ %2, %13 ], [ %449, %440 ]
  %19 = phi ptr [ %1, %13 ], [ %450, %440 ]
  %20 = phi <2 x i64> [ %16, %13 ], [ %448, %440 ]
  %21 = icmp ugt i64 %18, 56
  %22 = extractelement <2 x i64> %20, i64 0
  %23 = tail call i64 @llvm.umin.i64(i64 %18, i64 56)
  %24 = trunc nuw nsw i64 %23 to i32
  %25 = select i1 %21, i64 0, i64 %14
  %26 = icmp ugt i64 %18, 7
  br i1 %26, label %29, label %27

27:                                               ; preds = %17
  %28 = icmp eq i64 %18, 0
  br i1 %28, label %82, label %69

29:                                               ; preds = %17
  %30 = load i8, ptr %19, align 1, !tbaa !57
  %31 = zext i8 %30 to i64
  %32 = getelementptr inbounds nuw i8, ptr %19, i64 1
  %33 = load i8, ptr %32, align 1, !tbaa !57
  %34 = zext i8 %33 to i64
  %35 = shl nuw nsw i64 %34, 8
  %36 = or disjoint i64 %35, %31
  %37 = getelementptr inbounds nuw i8, ptr %19, i64 2
  %38 = load i8, ptr %37, align 1, !tbaa !57
  %39 = zext i8 %38 to i64
  %40 = shl nuw nsw i64 %39, 16
  %41 = or disjoint i64 %36, %40
  %42 = getelementptr inbounds nuw i8, ptr %19, i64 3
  %43 = load i8, ptr %42, align 1, !tbaa !57
  %44 = zext i8 %43 to i64
  %45 = shl nuw nsw i64 %44, 24
  %46 = or disjoint i64 %41, %45
  %47 = getelementptr inbounds nuw i8, ptr %19, i64 4
  %48 = load i8, ptr %47, align 1, !tbaa !57
  %49 = zext i8 %48 to i64
  %50 = shl nuw nsw i64 %49, 32
  %51 = or disjoint i64 %46, %50
  %52 = getelementptr inbounds nuw i8, ptr %19, i64 5
  %53 = load i8, ptr %52, align 1, !tbaa !57
  %54 = zext i8 %53 to i64
  %55 = shl nuw nsw i64 %54, 40
  %56 = or i64 %51, %55
  %57 = getelementptr inbounds nuw i8, ptr %19, i64 6
  %58 = load i8, ptr %57, align 1, !tbaa !57
  %59 = zext i8 %58 to i64
  %60 = shl nuw nsw i64 %59, 48
  %61 = or i64 %56, %60
  %62 = getelementptr inbounds nuw i8, ptr %19, i64 7
  %63 = load i8, ptr %62, align 1, !tbaa !57
  %64 = zext i8 %63 to i64
  %65 = shl nuw i64 %64, 56
  %66 = or i64 %61, %65
  %67 = add nsw i32 %24, -8
  %68 = getelementptr inbounds nuw i8, ptr %19, i64 8
  br label %82

69:                                               ; preds = %69, %27
  %70 = phi i32 [ %80, %69 ], [ 0, %27 ]
  %71 = phi i64 [ %79, %69 ], [ 0, %27 ]
  %72 = zext nneg i32 %70 to i64
  %73 = getelementptr inbounds nuw i8, ptr %19, i64 %72
  %74 = load i8, ptr %73, align 1, !tbaa !57
  %75 = zext i8 %74 to i64
  %76 = shl nuw nsw i32 %70, 3
  %77 = zext nneg i32 %76 to i64
  %78 = shl nuw i64 %75, %77
  %79 = or i64 %78, %71
  %80 = add nuw nsw i32 %70, 1
  %81 = icmp eq i32 %80, %24
  br i1 %81, label %82, label %69

82:                                               ; preds = %69, %29, %27
  %83 = phi ptr [ %68, %29 ], [ %19, %27 ], [ %19, %69 ]
  %84 = phi i32 [ %67, %29 ], [ 0, %27 ], [ 0, %69 ]
  %85 = phi i64 [ %66, %29 ], [ 0, %27 ], [ %79, %69 ]
  %86 = icmp ugt i32 %84, 7
  br i1 %86, label %89, label %87

87:                                               ; preds = %82
  %88 = icmp eq i32 %84, 0
  br i1 %88, label %142, label %129

89:                                               ; preds = %82
  %90 = load i8, ptr %83, align 1, !tbaa !57
  %91 = zext i8 %90 to i64
  %92 = getelementptr inbounds nuw i8, ptr %83, i64 1
  %93 = load i8, ptr %92, align 1, !tbaa !57
  %94 = zext i8 %93 to i64
  %95 = shl nuw nsw i64 %94, 8
  %96 = or disjoint i64 %95, %91
  %97 = getelementptr inbounds nuw i8, ptr %83, i64 2
  %98 = load i8, ptr %97, align 1, !tbaa !57
  %99 = zext i8 %98 to i64
  %100 = shl nuw nsw i64 %99, 16
  %101 = or disjoint i64 %96, %100
  %102 = getelementptr inbounds nuw i8, ptr %83, i64 3
  %103 = load i8, ptr %102, align 1, !tbaa !57
  %104 = zext i8 %103 to i64
  %105 = shl nuw nsw i64 %104, 24
  %106 = or disjoint i64 %101, %105
  %107 = getelementptr inbounds nuw i8, ptr %83, i64 4
  %108 = load i8, ptr %107, align 1, !tbaa !57
  %109 = zext i8 %108 to i64
  %110 = shl nuw nsw i64 %109, 32
  %111 = or disjoint i64 %106, %110
  %112 = getelementptr inbounds nuw i8, ptr %83, i64 5
  %113 = load i8, ptr %112, align 1, !tbaa !57
  %114 = zext i8 %113 to i64
  %115 = shl nuw nsw i64 %114, 40
  %116 = or i64 %111, %115
  %117 = getelementptr inbounds nuw i8, ptr %83, i64 6
  %118 = load i8, ptr %117, align 1, !tbaa !57
  %119 = zext i8 %118 to i64
  %120 = shl nuw nsw i64 %119, 48
  %121 = or i64 %116, %120
  %122 = getelementptr inbounds nuw i8, ptr %83, i64 7
  %123 = load i8, ptr %122, align 1, !tbaa !57
  %124 = zext i8 %123 to i64
  %125 = shl nuw i64 %124, 56
  %126 = or i64 %121, %125
  %127 = add nsw i32 %84, -8
  %128 = getelementptr inbounds nuw i8, ptr %83, i64 8
  br label %142

129:                                              ; preds = %129, %87
  %130 = phi i32 [ %140, %129 ], [ 0, %87 ]
  %131 = phi i64 [ %139, %129 ], [ 0, %87 ]
  %132 = zext nneg i32 %130 to i64
  %133 = getelementptr inbounds nuw i8, ptr %83, i64 %132
  %134 = load i8, ptr %133, align 1, !tbaa !57
  %135 = zext i8 %134 to i64
  %136 = shl nuw nsw i32 %130, 3
  %137 = zext nneg i32 %136 to i64
  %138 = shl nuw i64 %135, %137
  %139 = or i64 %138, %131
  %140 = add nuw nsw i32 %130, 1
  %141 = icmp eq i32 %140, %84
  br i1 %141, label %142, label %129

142:                                              ; preds = %129, %89, %87
  %143 = phi ptr [ %128, %89 ], [ %83, %87 ], [ %83, %129 ]
  %144 = phi i32 [ %127, %89 ], [ 0, %87 ], [ 0, %129 ]
  %145 = phi i64 [ %126, %89 ], [ 0, %87 ], [ %139, %129 ]
  %146 = icmp ugt i32 %144, 7
  br i1 %146, label %149, label %147

147:                                              ; preds = %142
  %148 = icmp eq i32 %144, 0
  br i1 %148, label %202, label %189

149:                                              ; preds = %142
  %150 = load i8, ptr %143, align 1, !tbaa !57
  %151 = zext i8 %150 to i64
  %152 = getelementptr inbounds nuw i8, ptr %143, i64 1
  %153 = load i8, ptr %152, align 1, !tbaa !57
  %154 = zext i8 %153 to i64
  %155 = shl nuw nsw i64 %154, 8
  %156 = or disjoint i64 %155, %151
  %157 = getelementptr inbounds nuw i8, ptr %143, i64 2
  %158 = load i8, ptr %157, align 1, !tbaa !57
  %159 = zext i8 %158 to i64
  %160 = shl nuw nsw i64 %159, 16
  %161 = or disjoint i64 %156, %160
  %162 = getelementptr inbounds nuw i8, ptr %143, i64 3
  %163 = load i8, ptr %162, align 1, !tbaa !57
  %164 = zext i8 %163 to i64
  %165 = shl nuw nsw i64 %164, 24
  %166 = or disjoint i64 %161, %165
  %167 = getelementptr inbounds nuw i8, ptr %143, i64 4
  %168 = load i8, ptr %167, align 1, !tbaa !57
  %169 = zext i8 %168 to i64
  %170 = shl nuw nsw i64 %169, 32
  %171 = or disjoint i64 %166, %170
  %172 = getelementptr inbounds nuw i8, ptr %143, i64 5
  %173 = load i8, ptr %172, align 1, !tbaa !57
  %174 = zext i8 %173 to i64
  %175 = shl nuw nsw i64 %174, 40
  %176 = or i64 %171, %175
  %177 = getelementptr inbounds nuw i8, ptr %143, i64 6
  %178 = load i8, ptr %177, align 1, !tbaa !57
  %179 = zext i8 %178 to i64
  %180 = shl nuw nsw i64 %179, 48
  %181 = or i64 %176, %180
  %182 = getelementptr inbounds nuw i8, ptr %143, i64 7
  %183 = load i8, ptr %182, align 1, !tbaa !57
  %184 = zext i8 %183 to i64
  %185 = shl nuw i64 %184, 56
  %186 = or i64 %181, %185
  %187 = add nsw i32 %144, -8
  %188 = getelementptr inbounds nuw i8, ptr %143, i64 8
  br label %202

189:                                              ; preds = %189, %147
  %190 = phi i32 [ %200, %189 ], [ 0, %147 ]
  %191 = phi i64 [ %199, %189 ], [ 0, %147 ]
  %192 = zext nneg i32 %190 to i64
  %193 = getelementptr inbounds nuw i8, ptr %143, i64 %192
  %194 = load i8, ptr %193, align 1, !tbaa !57
  %195 = zext i8 %194 to i64
  %196 = shl nuw nsw i32 %190, 3
  %197 = zext nneg i32 %196 to i64
  %198 = shl nuw i64 %195, %197
  %199 = or i64 %198, %191
  %200 = add nuw nsw i32 %190, 1
  %201 = icmp eq i32 %200, %144
  br i1 %201, label %202, label %189

202:                                              ; preds = %189, %149, %147
  %203 = phi ptr [ %188, %149 ], [ %143, %147 ], [ %143, %189 ]
  %204 = phi i32 [ %187, %149 ], [ 0, %147 ], [ 0, %189 ]
  %205 = phi i64 [ %186, %149 ], [ 0, %147 ], [ %199, %189 ]
  %206 = icmp ugt i32 %204, 7
  br i1 %206, label %209, label %207

207:                                              ; preds = %202
  %208 = icmp eq i32 %204, 0
  br i1 %208, label %262, label %249

209:                                              ; preds = %202
  %210 = load i8, ptr %203, align 1, !tbaa !57
  %211 = zext i8 %210 to i64
  %212 = getelementptr inbounds nuw i8, ptr %203, i64 1
  %213 = load i8, ptr %212, align 1, !tbaa !57
  %214 = zext i8 %213 to i64
  %215 = shl nuw nsw i64 %214, 8
  %216 = or disjoint i64 %215, %211
  %217 = getelementptr inbounds nuw i8, ptr %203, i64 2
  %218 = load i8, ptr %217, align 1, !tbaa !57
  %219 = zext i8 %218 to i64
  %220 = shl nuw nsw i64 %219, 16
  %221 = or disjoint i64 %216, %220
  %222 = getelementptr inbounds nuw i8, ptr %203, i64 3
  %223 = load i8, ptr %222, align 1, !tbaa !57
  %224 = zext i8 %223 to i64
  %225 = shl nuw nsw i64 %224, 24
  %226 = or disjoint i64 %221, %225
  %227 = getelementptr inbounds nuw i8, ptr %203, i64 4
  %228 = load i8, ptr %227, align 1, !tbaa !57
  %229 = zext i8 %228 to i64
  %230 = shl nuw nsw i64 %229, 32
  %231 = or disjoint i64 %226, %230
  %232 = getelementptr inbounds nuw i8, ptr %203, i64 5
  %233 = load i8, ptr %232, align 1, !tbaa !57
  %234 = zext i8 %233 to i64
  %235 = shl nuw nsw i64 %234, 40
  %236 = or i64 %231, %235
  %237 = getelementptr inbounds nuw i8, ptr %203, i64 6
  %238 = load i8, ptr %237, align 1, !tbaa !57
  %239 = zext i8 %238 to i64
  %240 = shl nuw nsw i64 %239, 48
  %241 = or i64 %236, %240
  %242 = getelementptr inbounds nuw i8, ptr %203, i64 7
  %243 = load i8, ptr %242, align 1, !tbaa !57
  %244 = zext i8 %243 to i64
  %245 = shl nuw i64 %244, 56
  %246 = or i64 %241, %245
  %247 = add nsw i32 %204, -8
  %248 = getelementptr inbounds nuw i8, ptr %203, i64 8
  br label %262

249:                                              ; preds = %249, %207
  %250 = phi i32 [ %260, %249 ], [ 0, %207 ]
  %251 = phi i64 [ %259, %249 ], [ 0, %207 ]
  %252 = zext nneg i32 %250 to i64
  %253 = getelementptr inbounds nuw i8, ptr %203, i64 %252
  %254 = load i8, ptr %253, align 1, !tbaa !57
  %255 = zext i8 %254 to i64
  %256 = shl nuw nsw i32 %250, 3
  %257 = zext nneg i32 %256 to i64
  %258 = shl nuw i64 %255, %257
  %259 = or i64 %258, %251
  %260 = add nuw nsw i32 %250, 1
  %261 = icmp eq i32 %260, %204
  br i1 %261, label %262, label %249

262:                                              ; preds = %249, %209, %207
  %263 = phi ptr [ %248, %209 ], [ %203, %207 ], [ %203, %249 ]
  %264 = phi i32 [ %247, %209 ], [ 0, %207 ], [ 0, %249 ]
  %265 = phi i64 [ %246, %209 ], [ 0, %207 ], [ %259, %249 ]
  %266 = icmp ugt i32 %264, 7
  br i1 %266, label %269, label %267

267:                                              ; preds = %262
  %268 = icmp eq i32 %264, 0
  br i1 %268, label %322, label %309

269:                                              ; preds = %262
  %270 = load i8, ptr %263, align 1, !tbaa !57
  %271 = zext i8 %270 to i64
  %272 = getelementptr inbounds nuw i8, ptr %263, i64 1
  %273 = load i8, ptr %272, align 1, !tbaa !57
  %274 = zext i8 %273 to i64
  %275 = shl nuw nsw i64 %274, 8
  %276 = or disjoint i64 %275, %271
  %277 = getelementptr inbounds nuw i8, ptr %263, i64 2
  %278 = load i8, ptr %277, align 1, !tbaa !57
  %279 = zext i8 %278 to i64
  %280 = shl nuw nsw i64 %279, 16
  %281 = or disjoint i64 %276, %280
  %282 = getelementptr inbounds nuw i8, ptr %263, i64 3
  %283 = load i8, ptr %282, align 1, !tbaa !57
  %284 = zext i8 %283 to i64
  %285 = shl nuw nsw i64 %284, 24
  %286 = or disjoint i64 %281, %285
  %287 = getelementptr inbounds nuw i8, ptr %263, i64 4
  %288 = load i8, ptr %287, align 1, !tbaa !57
  %289 = zext i8 %288 to i64
  %290 = shl nuw nsw i64 %289, 32
  %291 = or disjoint i64 %286, %290
  %292 = getelementptr inbounds nuw i8, ptr %263, i64 5
  %293 = load i8, ptr %292, align 1, !tbaa !57
  %294 = zext i8 %293 to i64
  %295 = shl nuw nsw i64 %294, 40
  %296 = or i64 %291, %295
  %297 = getelementptr inbounds nuw i8, ptr %263, i64 6
  %298 = load i8, ptr %297, align 1, !tbaa !57
  %299 = zext i8 %298 to i64
  %300 = shl nuw nsw i64 %299, 48
  %301 = or i64 %296, %300
  %302 = getelementptr inbounds nuw i8, ptr %263, i64 7
  %303 = load i8, ptr %302, align 1, !tbaa !57
  %304 = zext i8 %303 to i64
  %305 = shl nuw i64 %304, 56
  %306 = or i64 %301, %305
  %307 = add nsw i32 %264, -8
  %308 = getelementptr inbounds nuw i8, ptr %263, i64 8
  br label %322

309:                                              ; preds = %309, %267
  %310 = phi i32 [ %320, %309 ], [ 0, %267 ]
  %311 = phi i64 [ %319, %309 ], [ 0, %267 ]
  %312 = zext nneg i32 %310 to i64
  %313 = getelementptr inbounds nuw i8, ptr %263, i64 %312
  %314 = load i8, ptr %313, align 1, !tbaa !57
  %315 = zext i8 %314 to i64
  %316 = shl nuw nsw i32 %310, 3
  %317 = zext nneg i32 %316 to i64
  %318 = shl nuw i64 %315, %317
  %319 = or i64 %318, %311
  %320 = add nuw nsw i32 %310, 1
  %321 = icmp eq i32 %320, %264
  br i1 %321, label %322, label %309

322:                                              ; preds = %309, %269, %267
  %323 = phi ptr [ %308, %269 ], [ %263, %267 ], [ %263, %309 ]
  %324 = phi i32 [ %307, %269 ], [ 0, %267 ], [ 0, %309 ]
  %325 = phi i64 [ %306, %269 ], [ 0, %267 ], [ %319, %309 ]
  %326 = icmp ugt i32 %324, 7
  br i1 %326, label %329, label %327

327:                                              ; preds = %322
  %328 = icmp eq i32 %324, 0
  br i1 %328, label %382, label %369

329:                                              ; preds = %322
  %330 = load i8, ptr %323, align 1, !tbaa !57
  %331 = zext i8 %330 to i64
  %332 = getelementptr inbounds nuw i8, ptr %323, i64 1
  %333 = load i8, ptr %332, align 1, !tbaa !57
  %334 = zext i8 %333 to i64
  %335 = shl nuw nsw i64 %334, 8
  %336 = or disjoint i64 %335, %331
  %337 = getelementptr inbounds nuw i8, ptr %323, i64 2
  %338 = load i8, ptr %337, align 1, !tbaa !57
  %339 = zext i8 %338 to i64
  %340 = shl nuw nsw i64 %339, 16
  %341 = or disjoint i64 %336, %340
  %342 = getelementptr inbounds nuw i8, ptr %323, i64 3
  %343 = load i8, ptr %342, align 1, !tbaa !57
  %344 = zext i8 %343 to i64
  %345 = shl nuw nsw i64 %344, 24
  %346 = or disjoint i64 %341, %345
  %347 = getelementptr inbounds nuw i8, ptr %323, i64 4
  %348 = load i8, ptr %347, align 1, !tbaa !57
  %349 = zext i8 %348 to i64
  %350 = shl nuw nsw i64 %349, 32
  %351 = or disjoint i64 %346, %350
  %352 = getelementptr inbounds nuw i8, ptr %323, i64 5
  %353 = load i8, ptr %352, align 1, !tbaa !57
  %354 = zext i8 %353 to i64
  %355 = shl nuw nsw i64 %354, 40
  %356 = or i64 %351, %355
  %357 = getelementptr inbounds nuw i8, ptr %323, i64 6
  %358 = load i8, ptr %357, align 1, !tbaa !57
  %359 = zext i8 %358 to i64
  %360 = shl nuw nsw i64 %359, 48
  %361 = or i64 %356, %360
  %362 = getelementptr inbounds nuw i8, ptr %323, i64 7
  %363 = load i8, ptr %362, align 1, !tbaa !57
  %364 = zext i8 %363 to i64
  %365 = shl nuw i64 %364, 56
  %366 = or i64 %361, %365
  %367 = add nsw i32 %324, -8
  %368 = getelementptr inbounds nuw i8, ptr %323, i64 8
  br label %382

369:                                              ; preds = %369, %327
  %370 = phi i32 [ %380, %369 ], [ 0, %327 ]
  %371 = phi i64 [ %379, %369 ], [ 0, %327 ]
  %372 = zext nneg i32 %370 to i64
  %373 = getelementptr inbounds nuw i8, ptr %323, i64 %372
  %374 = load i8, ptr %373, align 1, !tbaa !57
  %375 = zext i8 %374 to i64
  %376 = shl nuw nsw i32 %370, 3
  %377 = zext nneg i32 %376 to i64
  %378 = shl nuw i64 %375, %377
  %379 = or i64 %378, %371
  %380 = add nuw nsw i32 %370, 1
  %381 = icmp eq i32 %380, %324
  br i1 %381, label %382, label %369

382:                                              ; preds = %369, %329, %327
  %383 = phi ptr [ %368, %329 ], [ %323, %327 ], [ %323, %369 ]
  %384 = phi i32 [ %367, %329 ], [ 0, %327 ], [ 0, %369 ]
  %385 = phi i64 [ %366, %329 ], [ 0, %327 ], [ %379, %369 ]
  %386 = icmp ugt i32 %384, 7
  br i1 %386, label %389, label %387

387:                                              ; preds = %382
  %388 = icmp eq i32 %384, 0
  br i1 %388, label %440, label %427

389:                                              ; preds = %382
  %390 = load i8, ptr %383, align 1, !tbaa !57
  %391 = zext i8 %390 to i64
  %392 = getelementptr inbounds nuw i8, ptr %383, i64 1
  %393 = load i8, ptr %392, align 1, !tbaa !57
  %394 = zext i8 %393 to i64
  %395 = shl nuw nsw i64 %394, 8
  %396 = or disjoint i64 %395, %391
  %397 = getelementptr inbounds nuw i8, ptr %383, i64 2
  %398 = load i8, ptr %397, align 1, !tbaa !57
  %399 = zext i8 %398 to i64
  %400 = shl nuw nsw i64 %399, 16
  %401 = or disjoint i64 %396, %400
  %402 = getelementptr inbounds nuw i8, ptr %383, i64 3
  %403 = load i8, ptr %402, align 1, !tbaa !57
  %404 = zext i8 %403 to i64
  %405 = shl nuw nsw i64 %404, 24
  %406 = or disjoint i64 %401, %405
  %407 = getelementptr inbounds nuw i8, ptr %383, i64 4
  %408 = load i8, ptr %407, align 1, !tbaa !57
  %409 = zext i8 %408 to i64
  %410 = shl nuw nsw i64 %409, 32
  %411 = or disjoint i64 %406, %410
  %412 = getelementptr inbounds nuw i8, ptr %383, i64 5
  %413 = load i8, ptr %412, align 1, !tbaa !57
  %414 = zext i8 %413 to i64
  %415 = shl nuw nsw i64 %414, 40
  %416 = or i64 %411, %415
  %417 = getelementptr inbounds nuw i8, ptr %383, i64 6
  %418 = load i8, ptr %417, align 1, !tbaa !57
  %419 = zext i8 %418 to i64
  %420 = shl nuw nsw i64 %419, 48
  %421 = or i64 %416, %420
  %422 = getelementptr inbounds nuw i8, ptr %383, i64 7
  %423 = load i8, ptr %422, align 1, !tbaa !57
  %424 = zext i8 %423 to i64
  %425 = shl nuw i64 %424, 56
  %426 = or i64 %421, %425
  br label %440

427:                                              ; preds = %427, %387
  %428 = phi i32 [ %438, %427 ], [ 0, %387 ]
  %429 = phi i64 [ %437, %427 ], [ 0, %387 ]
  %430 = zext nneg i32 %428 to i64
  %431 = getelementptr inbounds nuw i8, ptr %383, i64 %430
  %432 = load i8, ptr %431, align 1, !tbaa !57
  %433 = zext i8 %432 to i64
  %434 = shl nuw nsw i32 %428, 3
  %435 = zext nneg i32 %434 to i64
  %436 = shl nuw i64 %433, %435
  %437 = or i64 %436, %429
  %438 = add nuw nsw i32 %428, 1
  %439 = icmp eq i32 %438, %384
  br i1 %439, label %440, label %427

440:                                              ; preds = %427, %389, %387
  %441 = phi i64 [ %426, %389 ], [ 0, %387 ], [ %437, %427 ]
  %442 = shl nuw nsw i64 %23, 2
  %443 = add nuw nsw i64 %442, 28
  %444 = and i64 %443, 480
  %445 = and i64 %22, -225
  %446 = or i64 %445, %25
  %447 = or i64 %446, %444
  %448 = tail call <2 x i64> @__ockl_hostcall_preview(i32 noundef 2, i64 noundef %447, i64 noundef %85, i64 noundef %145, i64 noundef %205, i64 noundef %265, i64 noundef %325, i64 noundef %385, i64 noundef %441) #15
  %449 = sub i64 %18, %23
  %450 = getelementptr inbounds nuw i8, ptr %19, i64 %23
  %451 = icmp eq i64 %449, 0
  br i1 %451, label %452, label %17

452:                                              ; preds = %440, %9
  %453 = phi <2 x i64> [ %12, %9 ], [ %448, %440 ]
  %454 = extractelement <2 x i64> %453, i64 0
  ret i64 %454
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #12

attributes #0 = { convergent mustprogress noinline noreturn nounwind optnone uwtable "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "uniform-work-group-size" }
attributes #1 = { cold noreturn nounwind memory(inaccessiblemem: write) }
attributes #2 = { convergent mustprogress noinline nounwind optnone uwtable "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "uniform-work-group-size" }
attributes #3 = { convergent mustprogress noinline norecurse nounwind optnone uwtable "amdgpu-flat-work-group-size"="1,1024" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "uniform-work-group-size" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { convergent norecurse nounwind uwtable "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "target-features"="+16-bit-insts,+atomic-fmin-fmax-global-f32,+atomic-fmin-fmax-global-f64,+bvh-ray-tracing-insts,+ci-insts,+cube-insts,+cvt-pknorm-vop2-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+extended-image-insts,+flat-global-insts,+gfx10-3-insts,+gfx10-insts,+gfx8-insts,+gfx9-insts,+gws,+image-insts,+lerp-inst,+mqsad-insts,+mqsad-pk-insts,+msad-insts,+qsad-insts,+s-memrealtime,+s-memtime-inst,+sad-insts,+vmem-to-lds-load-insts,+wavefrontsize32" }
attributes #6 = { cold convergent norecurse nounwind uwtable "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "target-features"="+16-bit-insts,+atomic-fmin-fmax-global-f32,+atomic-fmin-fmax-global-f64,+bvh-ray-tracing-insts,+ci-insts,+cube-insts,+cvt-pknorm-vop2-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+extended-image-insts,+flat-global-insts,+gfx10-3-insts,+gfx10-insts,+gfx8-insts,+gfx9-insts,+gws,+image-insts,+lerp-inst,+mqsad-insts,+mqsad-pk-insts,+msad-insts,+qsad-insts,+s-memrealtime,+s-memtime-inst,+sad-insts,+vmem-to-lds-load-insts,+wavefrontsize32" }
attributes #7 = { convergent nocallback nocreateundeforpoison nofree nounwind willreturn memory(none) }
attributes #8 = { nocallback nofree nosync nounwind willreturn }
attributes #9 = { convergent mustprogress norecurse nounwind willreturn uwtable "amdgpu-no-cluster-id-x" "amdgpu-no-cluster-id-y" "amdgpu-no-cluster-id-z" "amdgpu-no-completion-action" "amdgpu-no-default-queue" "amdgpu-no-dispatch-id" "amdgpu-no-dispatch-ptr" "amdgpu-no-flat-scratch-init" "amdgpu-no-heap-ptr" "amdgpu-no-hostcall-ptr" "amdgpu-no-implicitarg-ptr" "amdgpu-no-lds-kernel-id" "amdgpu-no-multigrid-sync-arg" "amdgpu-no-queue-ptr" "amdgpu-no-workgroup-id-x" "amdgpu-no-workgroup-id-y" "amdgpu-no-workgroup-id-z" "amdgpu-no-workitem-id-x" "amdgpu-no-workitem-id-y" "amdgpu-no-workitem-id-z" "amdgpu-no-wwm" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "target-features"="+16-bit-insts,+atomic-fmin-fmax-global-f32,+atomic-fmin-fmax-global-f64,+bvh-ray-tracing-insts,+ci-insts,+cube-insts,+cvt-pknorm-vop2-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+extended-image-insts,+flat-global-insts,+gfx10-3-insts,+gfx10-insts,+gfx8-insts,+gfx9-insts,+gws,+image-insts,+lerp-inst,+mqsad-insts,+mqsad-pk-insts,+msad-insts,+qsad-insts,+s-memrealtime,+s-memtime-inst,+sad-insts,+vmem-to-lds-load-insts,+wavefrontsize32" }
attributes #10 = { nocallback nounwind willreturn }
attributes #11 = { nocallback nocreateundeforpoison nofree nosync nounwind willreturn memory(none) }
attributes #12 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #13 = { noreturn nounwind }
attributes #14 = { convergent nounwind "uniform-work-group-size" }
attributes #15 = { convergent nounwind }
attributes #16 = { cold convergent nounwind }

!llvm.module.flags = !{!5, !6, !7, !8, !9, !10, !11}
!llvm.ident = !{!12}
!opencl.ocl.version = !{!13}
!llvm.errno.tbaa = !{!14}

!0 = !{i64 7725209934930268629}
!1 = !{i64 9061685364171503215}
!2 = !{i64 -8836116302723813610}
!3 = !{i64 3168077570041682319}
!4 = !{i64 -3107796754942658234}
!5 = !{i32 1, !"amdhsa_code_object_version", i32 500}
!6 = !{i32 1, !"amdgpu_printf_kind", !"hostcall"}
!7 = !{i32 8, !"PIC Level", i32 2}
!8 = !{i32 7, !"uwtable", i32 2}
!9 = !{i32 7, !"frame-pointer", i32 2}
!10 = !{i32 1, !"ThinLTO", i32 0}
!11 = !{i32 1, !"EnableSplitLTOUnit", i32 1}
!12 = !{!"AMD clang version 24.0.0git (https://github.com/ROCm/llvm-project.git d6f6cb691863e9258034ab48c1dfce21689d5606)"}
!13 = !{i32 2, i32 0}
!14 = !{!15, !16, i64 0}
!15 = !{!"__libc_errno", !16, i64 0}
!16 = !{!"int", !17, i64 0}
!17 = !{!"omnipotent char", !18, i64 0}
!18 = !{!"Simple C/C++ TBAA"}
!19 = !{i64 -3001543976016564777}
!20 = !{i64 345206151970188238}
!21 = !{i64 -7271410508389881159}
!22 = distinct !{!22, !23}
!23 = !{!"llvm.loop.mustprogress"}
!24 = distinct !{!24, !23}
!25 = distinct !{!25, !23}
!26 = distinct !{!26, !23}
!27 = !{i64 -3422857216240862605}
!28 = !{i64 -3877445503859601424}
!29 = !{i16 1, i16 1025}
!30 = !{}
!31 = distinct !{!31, !23}
!32 = !{i64 -956664750800209193}
!33 = !{i64 -6433168583875815568}
!34 = !{i64 -4600918723914829367}
!35 = !{i64 5969615473218333203}
!36 = !{!16, !16, i64 0}
!37 = !{!38, !38, i64 0}
!38 = !{!"long", !17, i64 0}
!39 = !{i64 2952934718871851087}
!40 = !{!41, !42, i64 0}
!41 = !{!"", !42, i64 0, !42, i64 8, !43, i64 16, !38, i64 24, !38, i64 32, !38, i64 40}
!42 = !{!"any pointer", !17, i64 0}
!43 = !{!"hsa_signal_s", !38, i64 0}
!44 = !{!41, !38, i64 40}
!45 = !{!41, !42, i64 8}
!46 = !{!47, !16, i64 16}
!47 = !{!"", !38, i64 0, !38, i64 8, !16, i64 16, !16, i64 20}
!48 = !{!47, !38, i64 8}
!49 = !{!47, !16, i64 20}
!50 = !{!47, !38, i64 0}
!51 = !{i64 9013353737802032401}
!52 = !{!53, !38, i64 16}
!53 = !{!"amd_signal_s", !38, i64 0, !17, i64 8, !38, i64 16, !16, i64 24, !16, i64 28, !38, i64 32, !38, i64 40, !17, i64 48, !17, i64 56}
!54 = !{!53, !16, i64 24}
!55 = !{i64 5526949447773002895}
!56 = !{i64 2114776280960723381}
!57 = !{!17, !17, i64 0}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture)
