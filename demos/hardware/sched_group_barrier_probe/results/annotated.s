
# __CLANG_OFFLOAD_BUNDLE____START__ hip-amdgcn-amd-amdhsa--gfx1030
; ModuleID = '/home/zhuo/workspace/src/rocm-demo/demos/hardware/sched_group_barrier_probe/src/main.hip'
source_filename = "/home/zhuo/workspace/src/rocm-demo/demos/hardware/sched_group_barrier_probe/src/main.hip"
target datalayout = "e-m:e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128:128:48-p9:192:256:256:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
target triple = "amdgcn-amd-amdhsa"

@_ZZ13__assert_failE3fmt = internal addrspace(4) constant [47 x i8] c"%s:%u: %s: Device-side assertion `%s' failed.\0A\00", align 16, !guid !0
@__hip_cuid_39c5098bf0f908ee = addrspace(1) global i8 0, !guid !1
@llvm.compiler.used = appending addrspace(1) global [1 x ptr] [ptr addrspacecast (ptr addrspace(1) @__hip_cuid_39c5098bf0f908ee to ptr)], section "llvm.metadata", !guid !2

; Function Attrs: mustprogress noreturn nounwind uwtable
define weak void @__cxa_pure_virtual() local_unnamed_addr #0 !guid !21 {
  tail call void @llvm.trap() #15
  unreachable
}

; Function Attrs: cold noreturn nounwind memory(inaccessiblemem: write)
declare void @llvm.trap() #1

; Function Attrs: mustprogress noreturn nounwind uwtable
define weak void @__cxa_deleted_virtual() local_unnamed_addr #0 !guid !22 {
  tail call void @llvm.trap() #15
  unreachable
}

; Function Attrs: convergent noinline nounwind uwtable
define weak hidden void @__assert_fail(ptr noundef %0, ptr noundef %1, i32 noundef %2, ptr noundef %3) local_unnamed_addr #2 !guid !23 {
  %5 = tail call dereferenceable(256) ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %6 = getelementptr inbounds nuw i8, ptr addrspace(4) %5, i64 80
  %7 = load i64, ptr addrspace(4) %6, align 8, !tbaa !24
  %8 = inttoptr i64 %7 to ptr addrspace(1)
  %9 = tail call range(i32 0, 33) i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0)
  %10 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %9)
  %11 = icmp eq i32 %9, %10
  br i1 %11, label %12, label %34

12:                                               ; preds = %4
  %13 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %14 = load atomic i64, ptr addrspace(1) %13 syncscope("one-as") acquire, align 8
  %15 = getelementptr i8, ptr addrspace(1) %8, i64 40
  %16 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %17 = load i64, ptr addrspace(1) %15, align 8, !tbaa !30
  %18 = and i64 %17, %14
  %19 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %16, i64 %18
  %20 = load atomic i64, ptr addrspace(1) %19 syncscope("one-as") monotonic, align 8
  %21 = cmpxchg ptr addrspace(1) %13, i64 %14, i64 %20 syncscope("one-as") acquire monotonic, align 8
  %22 = extractvalue { i64, i1 } %21, 1
  %23 = extractvalue { i64, i1 } %21, 0
  br i1 %22, label %34, label %24

24:                                               ; preds = %12, %24
  %25 = phi i64 [ %33, %24 ], [ %23, %12 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %26 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %27 = load i64, ptr addrspace(1) %15, align 8, !tbaa !30
  %28 = and i64 %27, %25
  %29 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %26, i64 %28
  %30 = load atomic i64, ptr addrspace(1) %29 syncscope("one-as") monotonic, align 8
  %31 = cmpxchg ptr addrspace(1) %13, i64 %25, i64 %30 syncscope("one-as") acquire monotonic, align 8
  %32 = extractvalue { i64, i1 } %31, 1
  %33 = extractvalue { i64, i1 } %31, 0
  br i1 %32, label %34, label %24

34:                                               ; preds = %24, %12, %4
  %35 = phi i64 [ 0, %4 ], [ %23, %12 ], [ %33, %24 ]
  %36 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %35)
  %37 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %38 = getelementptr i8, ptr addrspace(1) %8, i64 40
  %39 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %40 = and i64 %39, %36
  %41 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %37, i64 %40
  %42 = getelementptr i8, ptr addrspace(1) %8, i64 8
  %43 = load ptr addrspace(1), ptr addrspace(1) %42, align 8, !tbaa !31
  %44 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %43, i64 %40
  %45 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %11, label %46, label %51

46:                                               ; preds = %34
  %47 = zext i32 %45 to i64
  %48 = getelementptr inbounds nuw i8, ptr addrspace(1) %41, i64 16
  %49 = getelementptr inbounds nuw i8, ptr addrspace(1) %41, i64 8
  %50 = getelementptr inbounds nuw i8, ptr addrspace(1) %41, i64 20
  store i32 2, ptr addrspace(1) %48, align 8, !tbaa !32
  store i64 %47, ptr addrspace(1) %49, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %50, align 4, !tbaa !35
  br label %51

51:                                               ; preds = %46, %34
  %52 = zext nneg i32 %9 to i64
  %53 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %44, i64 %52
  store i64 33, ptr addrspace(1) %53, align 8, !tbaa !24
  %54 = getelementptr inbounds nuw i8, ptr addrspace(1) %53, i64 8
  store i64 1, ptr addrspace(1) %54, align 8, !tbaa !24
  %55 = getelementptr inbounds nuw i8, ptr addrspace(1) %53, i64 16
  store i64 0, ptr addrspace(1) %55, align 8, !tbaa !24
  %56 = getelementptr inbounds nuw i8, ptr addrspace(1) %53, i64 24
  store i64 0, ptr addrspace(1) %56, align 8, !tbaa !24
  %57 = getelementptr inbounds nuw i8, ptr addrspace(1) %53, i64 32
  store i64 0, ptr addrspace(1) %57, align 8, !tbaa !24
  %58 = getelementptr inbounds nuw i8, ptr addrspace(1) %53, i64 40
  store i64 0, ptr addrspace(1) %58, align 8, !tbaa !24
  %59 = getelementptr inbounds nuw i8, ptr addrspace(1) %53, i64 48
  store i64 0, ptr addrspace(1) %59, align 8, !tbaa !24
  %60 = getelementptr inbounds nuw i8, ptr addrspace(1) %53, i64 56
  store i64 0, ptr addrspace(1) %60, align 8, !tbaa !24
  br i1 %11, label %61, label %90

61:                                               ; preds = %51
  %62 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 32
  %63 = load atomic i64, ptr addrspace(1) %62 syncscope("one-as") monotonic, align 8
  %64 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %65 = and i64 %64, %36
  %66 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %37, i64 %65
  store i64 %63, ptr addrspace(1) %66, align 8, !tbaa !36
  %67 = cmpxchg ptr addrspace(1) %62, i64 %63, i64 %36 syncscope("one-as") release monotonic, align 8
  %68 = extractvalue { i64, i1 } %67, 1
  br i1 %68, label %74, label %69

69:                                               ; preds = %61, %69
  %70 = phi { i64, i1 } [ %72, %69 ], [ %67, %61 ]
  %71 = extractvalue { i64, i1 } %70, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %71, ptr addrspace(1) %66, align 8, !tbaa !36
  %72 = cmpxchg ptr addrspace(1) %62, i64 %71, i64 %36 syncscope("one-as") release monotonic, align 8
  %73 = extractvalue { i64, i1 } %72, 1
  br i1 %73, label %74, label %69

74:                                               ; preds = %69, %61
  %75 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 16
  %76 = load i64, ptr addrspace(1) %75, align 8
  %77 = inttoptr i64 %76 to ptr addrspace(1)
  %78 = getelementptr inbounds nuw i8, ptr addrspace(1) %77, i64 8
  %79 = atomicrmw add ptr addrspace(1) %78, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %80 = getelementptr inbounds nuw i8, ptr addrspace(1) %77, i64 16
  %81 = load i64, ptr addrspace(1) %80, align 16, !tbaa !38
  %82 = icmp eq i64 %81, 0
  br i1 %82, label %90, label %83

83:                                               ; preds = %74
  %84 = inttoptr i64 %81 to ptr addrspace(1)
  %85 = getelementptr inbounds nuw i8, ptr addrspace(1) %77, i64 24
  %86 = load i32, ptr addrspace(1) %85, align 8, !tbaa !40
  %87 = zext i32 %86 to i64
  store atomic i64 %87, ptr addrspace(1) %84 syncscope("one-as") release, align 8
  %88 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %86)
  %89 = and i32 %88, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %89)
  br label %90

90:                                               ; preds = %83, %74, %51
  %91 = getelementptr inbounds nuw i8, ptr addrspace(1) %41, i64 20
  br label %92

92:                                               ; preds = %100, %90
  br i1 %11, label %93, label %96

93:                                               ; preds = %92
  %94 = load atomic i32, ptr addrspace(1) %91 syncscope("one-as") acquire, align 4
  %95 = and i32 %94, 1
  br label %96

96:                                               ; preds = %93, %92
  %97 = phi i32 [ %95, %93 ], [ 1, %92 ]
  %98 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %97)
  %99 = icmp eq i32 %98, 0
  br i1 %99, label %101, label %100

100:                                              ; preds = %96
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %92

101:                                              ; preds = %96
  %102 = load i64, ptr addrspace(1) %53, align 8, !tbaa !24
  br i1 %11, label %103, label %121

103:                                              ; preds = %101
  %104 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %105 = add i64 %104, 1
  %106 = add i64 %105, %36
  %107 = icmp eq i64 %106, 0
  %108 = select i1 %107, i64 %105, i64 %106
  %109 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %110 = load atomic i64, ptr addrspace(1) %109 syncscope("one-as") monotonic, align 8
  %111 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %112 = and i64 %108, %104
  %113 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %111, i64 %112
  store i64 %110, ptr addrspace(1) %113, align 8, !tbaa !36
  %114 = cmpxchg ptr addrspace(1) %109, i64 %110, i64 %108 syncscope("one-as") release monotonic, align 8
  %115 = extractvalue { i64, i1 } %114, 1
  br i1 %115, label %121, label %116

116:                                              ; preds = %103, %116
  %117 = phi { i64, i1 } [ %119, %116 ], [ %114, %103 ]
  %118 = extractvalue { i64, i1 } %117, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %118, ptr addrspace(1) %113, align 8, !tbaa !36
  %119 = cmpxchg ptr addrspace(1) %109, i64 %118, i64 %108 syncscope("one-as") release monotonic, align 8
  %120 = extractvalue { i64, i1 } %119, 1
  br i1 %120, label %121, label %116

121:                                              ; preds = %116, %101, %103
  %122 = icmp eq ptr addrspace(4) @_ZZ13__assert_failE3fmt, addrspacecast (ptr null to ptr addrspace(4))
  br i1 %122, label %123, label %237

123:                                              ; preds = %121
  %124 = and i64 %102, -225
  %125 = or disjoint i64 %124, 32
  %126 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %9)
  %127 = icmp eq i32 %9, %126
  br i1 %127, label %128, label %149

128:                                              ; preds = %123
  %129 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %130 = load atomic i64, ptr addrspace(1) %129 syncscope("one-as") acquire, align 8
  %131 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %132 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %133 = and i64 %132, %130
  %134 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %131, i64 %133
  %135 = load atomic i64, ptr addrspace(1) %134 syncscope("one-as") monotonic, align 8
  %136 = cmpxchg ptr addrspace(1) %129, i64 %130, i64 %135 syncscope("one-as") acquire monotonic, align 8
  %137 = extractvalue { i64, i1 } %136, 1
  %138 = extractvalue { i64, i1 } %136, 0
  br i1 %137, label %149, label %139

139:                                              ; preds = %128, %139
  %140 = phi i64 [ %148, %139 ], [ %138, %128 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %141 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %142 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %143 = and i64 %142, %140
  %144 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %141, i64 %143
  %145 = load atomic i64, ptr addrspace(1) %144 syncscope("one-as") monotonic, align 8
  %146 = cmpxchg ptr addrspace(1) %129, i64 %140, i64 %145 syncscope("one-as") acquire monotonic, align 8
  %147 = extractvalue { i64, i1 } %146, 1
  %148 = extractvalue { i64, i1 } %146, 0
  br i1 %147, label %149, label %139

149:                                              ; preds = %139, %128, %123
  %150 = phi i64 [ 0, %123 ], [ %138, %128 ], [ %148, %139 ]
  %151 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %150)
  %152 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %153 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %154 = and i64 %153, %151
  %155 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %152, i64 %154
  %156 = load ptr addrspace(1), ptr addrspace(1) %42, align 8, !tbaa !31
  %157 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %156, i64 %154
  %158 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %127, label %159, label %164

159:                                              ; preds = %149
  %160 = zext i32 %158 to i64
  %161 = getelementptr inbounds nuw i8, ptr addrspace(1) %155, i64 16
  %162 = getelementptr inbounds nuw i8, ptr addrspace(1) %155, i64 8
  %163 = getelementptr inbounds nuw i8, ptr addrspace(1) %155, i64 20
  store i32 2, ptr addrspace(1) %161, align 8, !tbaa !32
  store i64 %160, ptr addrspace(1) %162, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %163, align 4, !tbaa !35
  br label %164

164:                                              ; preds = %159, %149
  %165 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %157, i64 %52
  store i64 %125, ptr addrspace(1) %165, align 8, !tbaa !24
  %166 = getelementptr inbounds nuw i8, ptr addrspace(1) %165, i64 8
  store i64 0, ptr addrspace(1) %166, align 8, !tbaa !24
  %167 = getelementptr inbounds nuw i8, ptr addrspace(1) %165, i64 16
  store i64 0, ptr addrspace(1) %167, align 8, !tbaa !24
  %168 = getelementptr inbounds nuw i8, ptr addrspace(1) %165, i64 24
  store i64 0, ptr addrspace(1) %168, align 8, !tbaa !24
  %169 = getelementptr inbounds nuw i8, ptr addrspace(1) %165, i64 32
  store i64 0, ptr addrspace(1) %169, align 8, !tbaa !24
  %170 = getelementptr inbounds nuw i8, ptr addrspace(1) %165, i64 40
  store i64 0, ptr addrspace(1) %170, align 8, !tbaa !24
  %171 = getelementptr inbounds nuw i8, ptr addrspace(1) %165, i64 48
  store i64 0, ptr addrspace(1) %171, align 8, !tbaa !24
  %172 = getelementptr inbounds nuw i8, ptr addrspace(1) %165, i64 56
  store i64 0, ptr addrspace(1) %172, align 8, !tbaa !24
  br i1 %127, label %173, label %202

173:                                              ; preds = %164
  %174 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 32
  %175 = load atomic i64, ptr addrspace(1) %174 syncscope("one-as") monotonic, align 8
  %176 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %177 = and i64 %176, %151
  %178 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %152, i64 %177
  store i64 %175, ptr addrspace(1) %178, align 8, !tbaa !36
  %179 = cmpxchg ptr addrspace(1) %174, i64 %175, i64 %151 syncscope("one-as") release monotonic, align 8
  %180 = extractvalue { i64, i1 } %179, 1
  br i1 %180, label %186, label %181

181:                                              ; preds = %173, %181
  %182 = phi { i64, i1 } [ %184, %181 ], [ %179, %173 ]
  %183 = extractvalue { i64, i1 } %182, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %183, ptr addrspace(1) %178, align 8, !tbaa !36
  %184 = cmpxchg ptr addrspace(1) %174, i64 %183, i64 %151 syncscope("one-as") release monotonic, align 8
  %185 = extractvalue { i64, i1 } %184, 1
  br i1 %185, label %186, label %181

186:                                              ; preds = %181, %173
  %187 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 16
  %188 = load i64, ptr addrspace(1) %187, align 8
  %189 = inttoptr i64 %188 to ptr addrspace(1)
  %190 = getelementptr inbounds nuw i8, ptr addrspace(1) %189, i64 8
  %191 = atomicrmw add ptr addrspace(1) %190, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %192 = getelementptr inbounds nuw i8, ptr addrspace(1) %189, i64 16
  %193 = load i64, ptr addrspace(1) %192, align 16, !tbaa !38
  %194 = icmp eq i64 %193, 0
  br i1 %194, label %202, label %195

195:                                              ; preds = %186
  %196 = inttoptr i64 %193 to ptr addrspace(1)
  %197 = getelementptr inbounds nuw i8, ptr addrspace(1) %189, i64 24
  %198 = load i32, ptr addrspace(1) %197, align 8, !tbaa !40
  %199 = zext i32 %198 to i64
  store atomic i64 %199, ptr addrspace(1) %196 syncscope("one-as") release, align 8
  %200 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %198)
  %201 = and i32 %200, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %201)
  br label %202

202:                                              ; preds = %195, %186, %164
  %203 = getelementptr inbounds nuw i8, ptr addrspace(1) %155, i64 20
  br label %204

204:                                              ; preds = %212, %202
  br i1 %127, label %205, label %208

205:                                              ; preds = %204
  %206 = load atomic i32, ptr addrspace(1) %203 syncscope("one-as") acquire, align 4
  %207 = and i32 %206, 1
  br label %208

208:                                              ; preds = %205, %204
  %209 = phi i32 [ %207, %205 ], [ 1, %204 ]
  %210 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %209)
  %211 = icmp eq i32 %210, 0
  br i1 %211, label %213, label %212

212:                                              ; preds = %208
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %204

213:                                              ; preds = %208
  %214 = load i64, ptr addrspace(1) %165, align 8, !tbaa !24
  %215 = load i64, ptr addrspace(1) %166, align 8, !tbaa !24
  br i1 %127, label %216, label %234

216:                                              ; preds = %213
  %217 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %218 = add i64 %217, 1
  %219 = add i64 %218, %151
  %220 = icmp eq i64 %219, 0
  %221 = select i1 %220, i64 %218, i64 %219
  %222 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %223 = load atomic i64, ptr addrspace(1) %222 syncscope("one-as") monotonic, align 8
  %224 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %225 = and i64 %221, %217
  %226 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %224, i64 %225
  store i64 %223, ptr addrspace(1) %226, align 8, !tbaa !36
  %227 = cmpxchg ptr addrspace(1) %222, i64 %223, i64 %221 syncscope("one-as") release monotonic, align 8
  %228 = extractvalue { i64, i1 } %227, 1
  br i1 %228, label %234, label %229

229:                                              ; preds = %216, %229
  %230 = phi { i64, i1 } [ %232, %229 ], [ %227, %216 ]
  %231 = extractvalue { i64, i1 } %230, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %231, ptr addrspace(1) %226, align 8, !tbaa !36
  %232 = cmpxchg ptr addrspace(1) %222, i64 %231, i64 %221 syncscope("one-as") release monotonic, align 8
  %233 = extractvalue { i64, i1 } %232, 1
  br i1 %233, label %234, label %229

234:                                              ; preds = %229, %216, %213
  %235 = insertelement <2 x i64> poison, i64 %214, i64 0
  %236 = insertelement <2 x i64> %235, i64 %215, i64 1
  br label %534

237:                                              ; preds = %121
  %238 = sext i32 sub (i32 ptrtoint (ptr addrspacecast (ptr addrspace(4) getelementptr inbounds nuw (i8, ptr addrspace(4) @_ZZ13__assert_failE3fmt, i64 47) to ptr) to i32), i32 ptrtoint (ptr addrspacecast (ptr addrspace(4) @_ZZ13__assert_failE3fmt to ptr) to i32)) to i64
  %239 = and i64 %102, 2
  %240 = and i64 %102, -3
  %241 = insertelement <2 x i64> <i64 poison, i64 0>, i64 %240, i64 0
  %242 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %243 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 32
  %244 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 16
  br label %245

245:                                              ; preds = %528, %237
  %246 = phi i64 [ %238, %237 ], [ %531, %528 ]
  %247 = phi ptr addrspace(4) [ @_ZZ13__assert_failE3fmt, %237 ], [ %532, %528 ]
  %248 = phi <2 x i64> [ %241, %237 ], [ %530, %528 ]
  %249 = icmp ugt i64 %246, 56
  %250 = extractelement <2 x i64> %248, i64 0
  %251 = tail call i64 @llvm.umin.i64(i64 %246, i64 56)
  %252 = trunc nuw nsw i64 %251 to i32
  %253 = select i1 %249, i64 0, i64 %239
  %254 = icmp ugt i64 %246, 7
  br i1 %254, label %257, label %255

255:                                              ; preds = %245
  %256 = icmp eq i64 %246, 0
  br i1 %256, label %274, label %261

257:                                              ; preds = %245
  %258 = load i64, ptr addrspace(4) %247, align 1
  %259 = add nsw i32 %252, -8
  %260 = getelementptr inbounds nuw i8, ptr addrspace(4) %247, i64 8
  br label %274

261:                                              ; preds = %255, %261
  %262 = phi i32 [ %272, %261 ], [ 0, %255 ]
  %263 = phi i64 [ %271, %261 ], [ 0, %255 ]
  %264 = zext nneg i32 %262 to i64
  %265 = getelementptr inbounds nuw i8, ptr addrspace(4) %247, i64 %264
  %266 = load i8, ptr addrspace(4) %265, align 1, !tbaa !41
  %267 = zext i8 %266 to i64
  %268 = shl nuw nsw i32 %262, 3
  %269 = zext nneg i32 %268 to i64
  %270 = shl nuw i64 %267, %269
  %271 = or i64 %270, %263
  %272 = add nuw nsw i32 %262, 1
  %273 = icmp eq i32 %272, %252
  br i1 %273, label %274, label %261

274:                                              ; preds = %261, %257, %255
  %275 = phi ptr addrspace(4) [ %260, %257 ], [ %247, %255 ], [ %247, %261 ]
  %276 = phi i32 [ %259, %257 ], [ 0, %255 ], [ 0, %261 ]
  %277 = phi i64 [ %258, %257 ], [ 0, %255 ], [ %271, %261 ]
  %278 = icmp ugt i32 %276, 7
  br i1 %278, label %281, label %279

279:                                              ; preds = %274
  %280 = icmp eq i32 %276, 0
  br i1 %280, label %298, label %285

281:                                              ; preds = %274
  %282 = load i64, ptr addrspace(4) %275, align 1
  %283 = add nsw i32 %276, -8
  %284 = getelementptr inbounds nuw i8, ptr addrspace(4) %275, i64 8
  br label %298

285:                                              ; preds = %279, %285
  %286 = phi i32 [ %296, %285 ], [ 0, %279 ]
  %287 = phi i64 [ %295, %285 ], [ 0, %279 ]
  %288 = zext nneg i32 %286 to i64
  %289 = getelementptr inbounds nuw i8, ptr addrspace(4) %275, i64 %288
  %290 = load i8, ptr addrspace(4) %289, align 1, !tbaa !41
  %291 = zext i8 %290 to i64
  %292 = shl nuw nsw i32 %286, 3
  %293 = zext nneg i32 %292 to i64
  %294 = shl nuw i64 %291, %293
  %295 = or i64 %294, %287
  %296 = add nuw nsw i32 %286, 1
  %297 = icmp eq i32 %296, %276
  br i1 %297, label %298, label %285

298:                                              ; preds = %285, %281, %279
  %299 = phi ptr addrspace(4) [ %284, %281 ], [ %275, %279 ], [ %275, %285 ]
  %300 = phi i32 [ %283, %281 ], [ 0, %279 ], [ 0, %285 ]
  %301 = phi i64 [ %282, %281 ], [ 0, %279 ], [ %295, %285 ]
  %302 = icmp ugt i32 %300, 7
  br i1 %302, label %305, label %303

303:                                              ; preds = %298
  %304 = icmp eq i32 %300, 0
  br i1 %304, label %322, label %309

305:                                              ; preds = %298
  %306 = load i64, ptr addrspace(4) %299, align 1
  %307 = add nsw i32 %300, -8
  %308 = getelementptr inbounds nuw i8, ptr addrspace(4) %299, i64 8
  br label %322

309:                                              ; preds = %303, %309
  %310 = phi i32 [ %320, %309 ], [ 0, %303 ]
  %311 = phi i64 [ %319, %309 ], [ 0, %303 ]
  %312 = zext nneg i32 %310 to i64
  %313 = getelementptr inbounds nuw i8, ptr addrspace(4) %299, i64 %312
  %314 = load i8, ptr addrspace(4) %313, align 1, !tbaa !41
  %315 = zext i8 %314 to i64
  %316 = shl nuw nsw i32 %310, 3
  %317 = zext nneg i32 %316 to i64
  %318 = shl nuw i64 %315, %317
  %319 = or i64 %318, %311
  %320 = add nuw nsw i32 %310, 1
  %321 = icmp eq i32 %320, %300
  br i1 %321, label %322, label %309

322:                                              ; preds = %309, %305, %303
  %323 = phi ptr addrspace(4) [ %308, %305 ], [ %299, %303 ], [ %299, %309 ]
  %324 = phi i32 [ %307, %305 ], [ 0, %303 ], [ 0, %309 ]
  %325 = phi i64 [ %306, %305 ], [ 0, %303 ], [ %319, %309 ]
  %326 = icmp ugt i32 %324, 7
  br i1 %326, label %329, label %327

327:                                              ; preds = %322
  %328 = icmp eq i32 %324, 0
  br i1 %328, label %346, label %333

329:                                              ; preds = %322
  %330 = load i64, ptr addrspace(4) %323, align 1
  %331 = add nsw i32 %324, -8
  %332 = getelementptr inbounds nuw i8, ptr addrspace(4) %323, i64 8
  br label %346

333:                                              ; preds = %327, %333
  %334 = phi i32 [ %344, %333 ], [ 0, %327 ]
  %335 = phi i64 [ %343, %333 ], [ 0, %327 ]
  %336 = zext nneg i32 %334 to i64
  %337 = getelementptr inbounds nuw i8, ptr addrspace(4) %323, i64 %336
  %338 = load i8, ptr addrspace(4) %337, align 1, !tbaa !41
  %339 = zext i8 %338 to i64
  %340 = shl nuw nsw i32 %334, 3
  %341 = zext nneg i32 %340 to i64
  %342 = shl nuw i64 %339, %341
  %343 = or i64 %342, %335
  %344 = add nuw nsw i32 %334, 1
  %345 = icmp eq i32 %344, %324
  br i1 %345, label %346, label %333

346:                                              ; preds = %333, %329, %327
  %347 = phi ptr addrspace(4) [ %332, %329 ], [ %323, %327 ], [ %323, %333 ]
  %348 = phi i32 [ %331, %329 ], [ 0, %327 ], [ 0, %333 ]
  %349 = phi i64 [ %330, %329 ], [ 0, %327 ], [ %343, %333 ]
  %350 = icmp ugt i32 %348, 7
  br i1 %350, label %353, label %351

351:                                              ; preds = %346
  %352 = icmp eq i32 %348, 0
  br i1 %352, label %370, label %357

353:                                              ; preds = %346
  %354 = load i64, ptr addrspace(4) %347, align 1
  %355 = add nsw i32 %348, -8
  %356 = getelementptr inbounds nuw i8, ptr addrspace(4) %347, i64 8
  br label %370

357:                                              ; preds = %351, %357
  %358 = phi i32 [ %368, %357 ], [ 0, %351 ]
  %359 = phi i64 [ %367, %357 ], [ 0, %351 ]
  %360 = zext nneg i32 %358 to i64
  %361 = getelementptr inbounds nuw i8, ptr addrspace(4) %347, i64 %360
  %362 = load i8, ptr addrspace(4) %361, align 1, !tbaa !41
  %363 = zext i8 %362 to i64
  %364 = shl nuw nsw i32 %358, 3
  %365 = zext nneg i32 %364 to i64
  %366 = shl nuw i64 %363, %365
  %367 = or i64 %366, %359
  %368 = add nuw nsw i32 %358, 1
  %369 = icmp eq i32 %368, %348
  br i1 %369, label %370, label %357

370:                                              ; preds = %357, %353, %351
  %371 = phi ptr addrspace(4) [ %356, %353 ], [ %347, %351 ], [ %347, %357 ]
  %372 = phi i32 [ %355, %353 ], [ 0, %351 ], [ 0, %357 ]
  %373 = phi i64 [ %354, %353 ], [ 0, %351 ], [ %367, %357 ]
  %374 = icmp ugt i32 %372, 7
  br i1 %374, label %377, label %375

375:                                              ; preds = %370
  %376 = icmp eq i32 %372, 0
  br i1 %376, label %394, label %381

377:                                              ; preds = %370
  %378 = load i64, ptr addrspace(4) %371, align 1
  %379 = add nsw i32 %372, -8
  %380 = getelementptr inbounds nuw i8, ptr addrspace(4) %371, i64 8
  br label %394

381:                                              ; preds = %375, %381
  %382 = phi i32 [ %392, %381 ], [ 0, %375 ]
  %383 = phi i64 [ %391, %381 ], [ 0, %375 ]
  %384 = zext nneg i32 %382 to i64
  %385 = getelementptr inbounds nuw i8, ptr addrspace(4) %371, i64 %384
  %386 = load i8, ptr addrspace(4) %385, align 1, !tbaa !41
  %387 = zext i8 %386 to i64
  %388 = shl nuw nsw i32 %382, 3
  %389 = zext nneg i32 %388 to i64
  %390 = shl nuw i64 %387, %389
  %391 = or i64 %390, %383
  %392 = add nuw nsw i32 %382, 1
  %393 = icmp eq i32 %392, %372
  br i1 %393, label %394, label %381

394:                                              ; preds = %381, %377, %375
  %395 = phi ptr addrspace(4) [ %380, %377 ], [ %371, %375 ], [ %371, %381 ]
  %396 = phi i32 [ %379, %377 ], [ 0, %375 ], [ 0, %381 ]
  %397 = phi i64 [ %378, %377 ], [ 0, %375 ], [ %391, %381 ]
  %398 = icmp ugt i32 %396, 7
  br i1 %398, label %401, label %399

399:                                              ; preds = %394
  %400 = icmp eq i32 %396, 0
  br i1 %400, label %416, label %403

401:                                              ; preds = %394
  %402 = load i64, ptr addrspace(4) %395, align 1
  br label %416

403:                                              ; preds = %399, %403
  %404 = phi i32 [ %414, %403 ], [ 0, %399 ]
  %405 = phi i64 [ %413, %403 ], [ 0, %399 ]
  %406 = zext nneg i32 %404 to i64
  %407 = getelementptr inbounds nuw i8, ptr addrspace(4) %395, i64 %406
  %408 = load i8, ptr addrspace(4) %407, align 1, !tbaa !41
  %409 = zext i8 %408 to i64
  %410 = shl nuw nsw i32 %404, 3
  %411 = zext nneg i32 %410 to i64
  %412 = shl nuw i64 %409, %411
  %413 = or i64 %412, %405
  %414 = add nuw nsw i32 %404, 1
  %415 = icmp eq i32 %414, %396
  br i1 %415, label %416, label %403

416:                                              ; preds = %403, %401, %399
  %417 = phi i64 [ %402, %401 ], [ 0, %399 ], [ %413, %403 ]
  %418 = shl nuw nsw i64 %251, 2
  %419 = add nuw nsw i64 %418, 28
  %420 = and i64 %419, 480
  %421 = and i64 %250, -225
  %422 = or disjoint i64 %253, %420
  %423 = or i64 %422, %421
  %424 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %9)
  %425 = icmp eq i32 %9, %424
  br i1 %425, label %426, label %446

426:                                              ; preds = %416
  %427 = load atomic i64, ptr addrspace(1) %242 syncscope("one-as") acquire, align 8
  %428 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %429 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %430 = and i64 %429, %427
  %431 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %428, i64 %430
  %432 = load atomic i64, ptr addrspace(1) %431 syncscope("one-as") monotonic, align 8
  %433 = cmpxchg ptr addrspace(1) %242, i64 %427, i64 %432 syncscope("one-as") acquire monotonic, align 8
  %434 = extractvalue { i64, i1 } %433, 1
  %435 = extractvalue { i64, i1 } %433, 0
  br i1 %434, label %446, label %436

436:                                              ; preds = %426, %436
  %437 = phi i64 [ %445, %436 ], [ %435, %426 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %438 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %439 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %440 = and i64 %439, %437
  %441 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %438, i64 %440
  %442 = load atomic i64, ptr addrspace(1) %441 syncscope("one-as") monotonic, align 8
  %443 = cmpxchg ptr addrspace(1) %242, i64 %437, i64 %442 syncscope("one-as") acquire monotonic, align 8
  %444 = extractvalue { i64, i1 } %443, 1
  %445 = extractvalue { i64, i1 } %443, 0
  br i1 %444, label %446, label %436

446:                                              ; preds = %436, %426, %416
  %447 = phi i64 [ 0, %416 ], [ %435, %426 ], [ %445, %436 ]
  %448 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %447)
  %449 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %450 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %451 = and i64 %450, %448
  %452 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %449, i64 %451
  %453 = load ptr addrspace(1), ptr addrspace(1) %42, align 8, !tbaa !31
  %454 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %453, i64 %451
  %455 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %425, label %456, label %461

456:                                              ; preds = %446
  %457 = zext i32 %455 to i64
  %458 = getelementptr inbounds nuw i8, ptr addrspace(1) %452, i64 16
  %459 = getelementptr inbounds nuw i8, ptr addrspace(1) %452, i64 8
  %460 = getelementptr inbounds nuw i8, ptr addrspace(1) %452, i64 20
  store i32 2, ptr addrspace(1) %458, align 8, !tbaa !32
  store i64 %457, ptr addrspace(1) %459, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %460, align 4, !tbaa !35
  br label %461

461:                                              ; preds = %456, %446
  %462 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %454, i64 %52
  store i64 %423, ptr addrspace(1) %462, align 8, !tbaa !24
  %463 = getelementptr inbounds nuw i8, ptr addrspace(1) %462, i64 8
  store i64 %277, ptr addrspace(1) %463, align 8, !tbaa !24
  %464 = getelementptr inbounds nuw i8, ptr addrspace(1) %462, i64 16
  store i64 %301, ptr addrspace(1) %464, align 8, !tbaa !24
  %465 = getelementptr inbounds nuw i8, ptr addrspace(1) %462, i64 24
  store i64 %325, ptr addrspace(1) %465, align 8, !tbaa !24
  %466 = getelementptr inbounds nuw i8, ptr addrspace(1) %462, i64 32
  store i64 %349, ptr addrspace(1) %466, align 8, !tbaa !24
  %467 = getelementptr inbounds nuw i8, ptr addrspace(1) %462, i64 40
  store i64 %373, ptr addrspace(1) %467, align 8, !tbaa !24
  %468 = getelementptr inbounds nuw i8, ptr addrspace(1) %462, i64 48
  store i64 %397, ptr addrspace(1) %468, align 8, !tbaa !24
  %469 = getelementptr inbounds nuw i8, ptr addrspace(1) %462, i64 56
  store i64 %417, ptr addrspace(1) %469, align 8, !tbaa !24
  br i1 %425, label %470, label %497

470:                                              ; preds = %461
  %471 = load atomic i64, ptr addrspace(1) %243 syncscope("one-as") monotonic, align 8
  %472 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %473 = and i64 %472, %448
  %474 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %449, i64 %473
  store i64 %471, ptr addrspace(1) %474, align 8, !tbaa !36
  %475 = cmpxchg ptr addrspace(1) %243, i64 %471, i64 %448 syncscope("one-as") release monotonic, align 8
  %476 = extractvalue { i64, i1 } %475, 1
  br i1 %476, label %482, label %477

477:                                              ; preds = %470, %477
  %478 = phi { i64, i1 } [ %480, %477 ], [ %475, %470 ]
  %479 = extractvalue { i64, i1 } %478, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %479, ptr addrspace(1) %474, align 8, !tbaa !36
  %480 = cmpxchg ptr addrspace(1) %243, i64 %479, i64 %448 syncscope("one-as") release monotonic, align 8
  %481 = extractvalue { i64, i1 } %480, 1
  br i1 %481, label %482, label %477

482:                                              ; preds = %477, %470
  %483 = load i64, ptr addrspace(1) %244, align 8
  %484 = inttoptr i64 %483 to ptr addrspace(1)
  %485 = getelementptr inbounds nuw i8, ptr addrspace(1) %484, i64 8
  %486 = atomicrmw add ptr addrspace(1) %485, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %487 = getelementptr inbounds nuw i8, ptr addrspace(1) %484, i64 16
  %488 = load i64, ptr addrspace(1) %487, align 16, !tbaa !38
  %489 = icmp eq i64 %488, 0
  br i1 %489, label %497, label %490

490:                                              ; preds = %482
  %491 = inttoptr i64 %488 to ptr addrspace(1)
  %492 = getelementptr inbounds nuw i8, ptr addrspace(1) %484, i64 24
  %493 = load i32, ptr addrspace(1) %492, align 8, !tbaa !40
  %494 = zext i32 %493 to i64
  store atomic i64 %494, ptr addrspace(1) %491 syncscope("one-as") release, align 8
  %495 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %493)
  %496 = and i32 %495, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %496)
  br label %497

497:                                              ; preds = %490, %482, %461
  %498 = getelementptr inbounds nuw i8, ptr addrspace(1) %452, i64 20
  br label %499

499:                                              ; preds = %507, %497
  br i1 %425, label %500, label %503

500:                                              ; preds = %499
  %501 = load atomic i32, ptr addrspace(1) %498 syncscope("one-as") acquire, align 4
  %502 = and i32 %501, 1
  br label %503

503:                                              ; preds = %500, %499
  %504 = phi i32 [ %502, %500 ], [ 1, %499 ]
  %505 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %504)
  %506 = icmp eq i32 %505, 0
  br i1 %506, label %508, label %507

507:                                              ; preds = %503
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %499

508:                                              ; preds = %503
  %509 = load i64, ptr addrspace(1) %462, align 8, !tbaa !24
  %510 = load i64, ptr addrspace(1) %463, align 8, !tbaa !24
  br i1 %425, label %511, label %528

511:                                              ; preds = %508
  %512 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %513 = add i64 %512, 1
  %514 = add i64 %513, %448
  %515 = icmp eq i64 %514, 0
  %516 = select i1 %515, i64 %513, i64 %514
  %517 = load atomic i64, ptr addrspace(1) %242 syncscope("one-as") monotonic, align 8
  %518 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %519 = and i64 %516, %512
  %520 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %518, i64 %519
  store i64 %517, ptr addrspace(1) %520, align 8, !tbaa !36
  %521 = cmpxchg ptr addrspace(1) %242, i64 %517, i64 %516 syncscope("one-as") release monotonic, align 8
  %522 = extractvalue { i64, i1 } %521, 1
  br i1 %522, label %528, label %523

523:                                              ; preds = %511, %523
  %524 = phi { i64, i1 } [ %526, %523 ], [ %521, %511 ]
  %525 = extractvalue { i64, i1 } %524, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %525, ptr addrspace(1) %520, align 8, !tbaa !36
  %526 = cmpxchg ptr addrspace(1) %242, i64 %525, i64 %516 syncscope("one-as") release monotonic, align 8
  %527 = extractvalue { i64, i1 } %526, 1
  br i1 %527, label %528, label %523

528:                                              ; preds = %523, %511, %508
  %529 = insertelement <2 x i64> poison, i64 %509, i64 0
  %530 = insertelement <2 x i64> %529, i64 %510, i64 1
  %531 = sub i64 %246, %251
  %532 = getelementptr inbounds nuw i8, ptr addrspace(4) %247, i64 %251
  %533 = icmp eq i64 %531, 0
  br i1 %533, label %534, label %245

534:                                              ; preds = %528, %234
  %535 = phi <2 x i64> [ %236, %234 ], [ %530, %528 ]
  br label %536

536:                                              ; preds = %536, %534
  %537 = phi ptr [ %1, %534 ], [ %538, %536 ]
  %538 = getelementptr inbounds nuw i8, ptr %537, i64 1
  %539 = load i8, ptr %537, align 1, !tbaa !42
  %540 = icmp eq i8 %539, 0
  br i1 %540, label %541, label %536, !llvm.loop !43

541:                                              ; preds = %536
  %542 = extractelement <2 x i64> %535, i64 0
  %543 = icmp eq ptr %1, null
  br i1 %543, label %544, label %658

544:                                              ; preds = %541
  %545 = and i64 %542, -225
  %546 = or disjoint i64 %545, 32
  %547 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %9)
  %548 = icmp eq i32 %9, %547
  br i1 %548, label %549, label %570

549:                                              ; preds = %544
  %550 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %551 = load atomic i64, ptr addrspace(1) %550 syncscope("one-as") acquire, align 8
  %552 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %553 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %554 = and i64 %553, %551
  %555 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %552, i64 %554
  %556 = load atomic i64, ptr addrspace(1) %555 syncscope("one-as") monotonic, align 8
  %557 = cmpxchg ptr addrspace(1) %550, i64 %551, i64 %556 syncscope("one-as") acquire monotonic, align 8
  %558 = extractvalue { i64, i1 } %557, 1
  %559 = extractvalue { i64, i1 } %557, 0
  br i1 %558, label %570, label %560

560:                                              ; preds = %549, %560
  %561 = phi i64 [ %569, %560 ], [ %559, %549 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %562 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %563 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %564 = and i64 %563, %561
  %565 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %562, i64 %564
  %566 = load atomic i64, ptr addrspace(1) %565 syncscope("one-as") monotonic, align 8
  %567 = cmpxchg ptr addrspace(1) %550, i64 %561, i64 %566 syncscope("one-as") acquire monotonic, align 8
  %568 = extractvalue { i64, i1 } %567, 1
  %569 = extractvalue { i64, i1 } %567, 0
  br i1 %568, label %570, label %560

570:                                              ; preds = %560, %549, %544
  %571 = phi i64 [ 0, %544 ], [ %559, %549 ], [ %569, %560 ]
  %572 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %571)
  %573 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %574 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %575 = and i64 %574, %572
  %576 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %573, i64 %575
  %577 = load ptr addrspace(1), ptr addrspace(1) %42, align 8, !tbaa !31
  %578 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %577, i64 %575
  %579 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %548, label %580, label %585

580:                                              ; preds = %570
  %581 = zext i32 %579 to i64
  %582 = getelementptr inbounds nuw i8, ptr addrspace(1) %576, i64 16
  %583 = getelementptr inbounds nuw i8, ptr addrspace(1) %576, i64 8
  %584 = getelementptr inbounds nuw i8, ptr addrspace(1) %576, i64 20
  store i32 2, ptr addrspace(1) %582, align 8, !tbaa !32
  store i64 %581, ptr addrspace(1) %583, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %584, align 4, !tbaa !35
  br label %585

585:                                              ; preds = %580, %570
  %586 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %578, i64 %52
  store i64 %546, ptr addrspace(1) %586, align 8, !tbaa !24
  %587 = getelementptr inbounds nuw i8, ptr addrspace(1) %586, i64 8
  store i64 0, ptr addrspace(1) %587, align 8, !tbaa !24
  %588 = getelementptr inbounds nuw i8, ptr addrspace(1) %586, i64 16
  store i64 0, ptr addrspace(1) %588, align 8, !tbaa !24
  %589 = getelementptr inbounds nuw i8, ptr addrspace(1) %586, i64 24
  store i64 0, ptr addrspace(1) %589, align 8, !tbaa !24
  %590 = getelementptr inbounds nuw i8, ptr addrspace(1) %586, i64 32
  store i64 0, ptr addrspace(1) %590, align 8, !tbaa !24
  %591 = getelementptr inbounds nuw i8, ptr addrspace(1) %586, i64 40
  store i64 0, ptr addrspace(1) %591, align 8, !tbaa !24
  %592 = getelementptr inbounds nuw i8, ptr addrspace(1) %586, i64 48
  store i64 0, ptr addrspace(1) %592, align 8, !tbaa !24
  %593 = getelementptr inbounds nuw i8, ptr addrspace(1) %586, i64 56
  store i64 0, ptr addrspace(1) %593, align 8, !tbaa !24
  br i1 %548, label %594, label %623

594:                                              ; preds = %585
  %595 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 32
  %596 = load atomic i64, ptr addrspace(1) %595 syncscope("one-as") monotonic, align 8
  %597 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %598 = and i64 %597, %572
  %599 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %573, i64 %598
  store i64 %596, ptr addrspace(1) %599, align 8, !tbaa !36
  %600 = cmpxchg ptr addrspace(1) %595, i64 %596, i64 %572 syncscope("one-as") release monotonic, align 8
  %601 = extractvalue { i64, i1 } %600, 1
  br i1 %601, label %607, label %602

602:                                              ; preds = %594, %602
  %603 = phi { i64, i1 } [ %605, %602 ], [ %600, %594 ]
  %604 = extractvalue { i64, i1 } %603, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %604, ptr addrspace(1) %599, align 8, !tbaa !36
  %605 = cmpxchg ptr addrspace(1) %595, i64 %604, i64 %572 syncscope("one-as") release monotonic, align 8
  %606 = extractvalue { i64, i1 } %605, 1
  br i1 %606, label %607, label %602

607:                                              ; preds = %602, %594
  %608 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 16
  %609 = load i64, ptr addrspace(1) %608, align 8
  %610 = inttoptr i64 %609 to ptr addrspace(1)
  %611 = getelementptr inbounds nuw i8, ptr addrspace(1) %610, i64 8
  %612 = atomicrmw add ptr addrspace(1) %611, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %613 = getelementptr inbounds nuw i8, ptr addrspace(1) %610, i64 16
  %614 = load i64, ptr addrspace(1) %613, align 16, !tbaa !38
  %615 = icmp eq i64 %614, 0
  br i1 %615, label %623, label %616

616:                                              ; preds = %607
  %617 = inttoptr i64 %614 to ptr addrspace(1)
  %618 = getelementptr inbounds nuw i8, ptr addrspace(1) %610, i64 24
  %619 = load i32, ptr addrspace(1) %618, align 8, !tbaa !40
  %620 = zext i32 %619 to i64
  store atomic i64 %620, ptr addrspace(1) %617 syncscope("one-as") release, align 8
  %621 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %619)
  %622 = and i32 %621, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %622)
  br label %623

623:                                              ; preds = %616, %607, %585
  %624 = getelementptr inbounds nuw i8, ptr addrspace(1) %576, i64 20
  br label %625

625:                                              ; preds = %633, %623
  br i1 %548, label %626, label %629

626:                                              ; preds = %625
  %627 = load atomic i32, ptr addrspace(1) %624 syncscope("one-as") acquire, align 4
  %628 = and i32 %627, 1
  br label %629

629:                                              ; preds = %626, %625
  %630 = phi i32 [ %628, %626 ], [ 1, %625 ]
  %631 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %630)
  %632 = icmp eq i32 %631, 0
  br i1 %632, label %634, label %633

633:                                              ; preds = %629
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %625

634:                                              ; preds = %629
  %635 = load i64, ptr addrspace(1) %586, align 8, !tbaa !24
  %636 = load i64, ptr addrspace(1) %587, align 8, !tbaa !24
  br i1 %548, label %637, label %655

637:                                              ; preds = %634
  %638 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %639 = add i64 %638, 1
  %640 = add i64 %639, %572
  %641 = icmp eq i64 %640, 0
  %642 = select i1 %641, i64 %639, i64 %640
  %643 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %644 = load atomic i64, ptr addrspace(1) %643 syncscope("one-as") monotonic, align 8
  %645 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %646 = and i64 %642, %638
  %647 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %645, i64 %646
  store i64 %644, ptr addrspace(1) %647, align 8, !tbaa !36
  %648 = cmpxchg ptr addrspace(1) %643, i64 %644, i64 %642 syncscope("one-as") release monotonic, align 8
  %649 = extractvalue { i64, i1 } %648, 1
  br i1 %649, label %655, label %650

650:                                              ; preds = %637, %650
  %651 = phi { i64, i1 } [ %653, %650 ], [ %648, %637 ]
  %652 = extractvalue { i64, i1 } %651, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %652, ptr addrspace(1) %647, align 8, !tbaa !36
  %653 = cmpxchg ptr addrspace(1) %643, i64 %652, i64 %642 syncscope("one-as") release monotonic, align 8
  %654 = extractvalue { i64, i1 } %653, 1
  br i1 %654, label %655, label %650

655:                                              ; preds = %650, %637, %634
  %656 = insertelement <2 x i64> poison, i64 %635, i64 0
  %657 = insertelement <2 x i64> %656, i64 %636, i64 1
  br label %959

658:                                              ; preds = %541
  %659 = ptrtoint ptr %538 to i64
  %660 = ptrtoint ptr %1 to i64
  %661 = sub i64 %659, %660
  %662 = shl i64 %661, 32
  %663 = ashr exact i64 %662, 32
  %664 = and i64 %542, 2
  %665 = and i64 %542, -3
  %666 = insertelement <2 x i64> <i64 poison, i64 0>, i64 %665, i64 0
  %667 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %668 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 32
  %669 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 16
  br label %670

670:                                              ; preds = %953, %658
  %671 = phi i64 [ %663, %658 ], [ %956, %953 ]
  %672 = phi ptr [ %1, %658 ], [ %957, %953 ]
  %673 = phi <2 x i64> [ %666, %658 ], [ %955, %953 ]
  %674 = icmp ugt i64 %671, 56
  %675 = extractelement <2 x i64> %673, i64 0
  %676 = tail call i64 @llvm.umin.i64(i64 %671, i64 56)
  %677 = trunc nuw nsw i64 %676 to i32
  %678 = select i1 %674, i64 0, i64 %664
  %679 = icmp ugt i64 %671, 7
  br i1 %679, label %682, label %680

680:                                              ; preds = %670
  %681 = icmp eq i64 %671, 0
  br i1 %681, label %699, label %686

682:                                              ; preds = %670
  %683 = load i64, ptr %672, align 1
  %684 = add nsw i32 %677, -8
  %685 = getelementptr inbounds nuw i8, ptr %672, i64 8
  br label %699

686:                                              ; preds = %680, %686
  %687 = phi i32 [ %697, %686 ], [ 0, %680 ]
  %688 = phi i64 [ %696, %686 ], [ 0, %680 ]
  %689 = zext nneg i32 %687 to i64
  %690 = getelementptr inbounds nuw i8, ptr %672, i64 %689
  %691 = load i8, ptr %690, align 1, !tbaa !41
  %692 = zext i8 %691 to i64
  %693 = shl nuw nsw i32 %687, 3
  %694 = zext nneg i32 %693 to i64
  %695 = shl nuw i64 %692, %694
  %696 = or i64 %695, %688
  %697 = add nuw nsw i32 %687, 1
  %698 = icmp eq i32 %697, %677
  br i1 %698, label %699, label %686

699:                                              ; preds = %686, %682, %680
  %700 = phi ptr [ %685, %682 ], [ %672, %680 ], [ %672, %686 ]
  %701 = phi i32 [ %684, %682 ], [ 0, %680 ], [ 0, %686 ]
  %702 = phi i64 [ %683, %682 ], [ 0, %680 ], [ %696, %686 ]
  %703 = icmp ugt i32 %701, 7
  br i1 %703, label %706, label %704

704:                                              ; preds = %699
  %705 = icmp eq i32 %701, 0
  br i1 %705, label %723, label %710

706:                                              ; preds = %699
  %707 = load i64, ptr %700, align 1
  %708 = add nsw i32 %701, -8
  %709 = getelementptr inbounds nuw i8, ptr %700, i64 8
  br label %723

710:                                              ; preds = %704, %710
  %711 = phi i32 [ %721, %710 ], [ 0, %704 ]
  %712 = phi i64 [ %720, %710 ], [ 0, %704 ]
  %713 = zext nneg i32 %711 to i64
  %714 = getelementptr inbounds nuw i8, ptr %700, i64 %713
  %715 = load i8, ptr %714, align 1, !tbaa !41
  %716 = zext i8 %715 to i64
  %717 = shl nuw nsw i32 %711, 3
  %718 = zext nneg i32 %717 to i64
  %719 = shl nuw i64 %716, %718
  %720 = or i64 %719, %712
  %721 = add nuw nsw i32 %711, 1
  %722 = icmp eq i32 %721, %701
  br i1 %722, label %723, label %710

723:                                              ; preds = %710, %706, %704
  %724 = phi ptr [ %709, %706 ], [ %700, %704 ], [ %700, %710 ]
  %725 = phi i32 [ %708, %706 ], [ 0, %704 ], [ 0, %710 ]
  %726 = phi i64 [ %707, %706 ], [ 0, %704 ], [ %720, %710 ]
  %727 = icmp ugt i32 %725, 7
  br i1 %727, label %730, label %728

728:                                              ; preds = %723
  %729 = icmp eq i32 %725, 0
  br i1 %729, label %747, label %734

730:                                              ; preds = %723
  %731 = load i64, ptr %724, align 1
  %732 = add nsw i32 %725, -8
  %733 = getelementptr inbounds nuw i8, ptr %724, i64 8
  br label %747

734:                                              ; preds = %728, %734
  %735 = phi i32 [ %745, %734 ], [ 0, %728 ]
  %736 = phi i64 [ %744, %734 ], [ 0, %728 ]
  %737 = zext nneg i32 %735 to i64
  %738 = getelementptr inbounds nuw i8, ptr %724, i64 %737
  %739 = load i8, ptr %738, align 1, !tbaa !41
  %740 = zext i8 %739 to i64
  %741 = shl nuw nsw i32 %735, 3
  %742 = zext nneg i32 %741 to i64
  %743 = shl nuw i64 %740, %742
  %744 = or i64 %743, %736
  %745 = add nuw nsw i32 %735, 1
  %746 = icmp eq i32 %745, %725
  br i1 %746, label %747, label %734

747:                                              ; preds = %734, %730, %728
  %748 = phi ptr [ %733, %730 ], [ %724, %728 ], [ %724, %734 ]
  %749 = phi i32 [ %732, %730 ], [ 0, %728 ], [ 0, %734 ]
  %750 = phi i64 [ %731, %730 ], [ 0, %728 ], [ %744, %734 ]
  %751 = icmp ugt i32 %749, 7
  br i1 %751, label %754, label %752

752:                                              ; preds = %747
  %753 = icmp eq i32 %749, 0
  br i1 %753, label %771, label %758

754:                                              ; preds = %747
  %755 = load i64, ptr %748, align 1
  %756 = add nsw i32 %749, -8
  %757 = getelementptr inbounds nuw i8, ptr %748, i64 8
  br label %771

758:                                              ; preds = %752, %758
  %759 = phi i32 [ %769, %758 ], [ 0, %752 ]
  %760 = phi i64 [ %768, %758 ], [ 0, %752 ]
  %761 = zext nneg i32 %759 to i64
  %762 = getelementptr inbounds nuw i8, ptr %748, i64 %761
  %763 = load i8, ptr %762, align 1, !tbaa !41
  %764 = zext i8 %763 to i64
  %765 = shl nuw nsw i32 %759, 3
  %766 = zext nneg i32 %765 to i64
  %767 = shl nuw i64 %764, %766
  %768 = or i64 %767, %760
  %769 = add nuw nsw i32 %759, 1
  %770 = icmp eq i32 %769, %749
  br i1 %770, label %771, label %758

771:                                              ; preds = %758, %754, %752
  %772 = phi ptr [ %757, %754 ], [ %748, %752 ], [ %748, %758 ]
  %773 = phi i32 [ %756, %754 ], [ 0, %752 ], [ 0, %758 ]
  %774 = phi i64 [ %755, %754 ], [ 0, %752 ], [ %768, %758 ]
  %775 = icmp ugt i32 %773, 7
  br i1 %775, label %778, label %776

776:                                              ; preds = %771
  %777 = icmp eq i32 %773, 0
  br i1 %777, label %795, label %782

778:                                              ; preds = %771
  %779 = load i64, ptr %772, align 1
  %780 = add nsw i32 %773, -8
  %781 = getelementptr inbounds nuw i8, ptr %772, i64 8
  br label %795

782:                                              ; preds = %776, %782
  %783 = phi i32 [ %793, %782 ], [ 0, %776 ]
  %784 = phi i64 [ %792, %782 ], [ 0, %776 ]
  %785 = zext nneg i32 %783 to i64
  %786 = getelementptr inbounds nuw i8, ptr %772, i64 %785
  %787 = load i8, ptr %786, align 1, !tbaa !41
  %788 = zext i8 %787 to i64
  %789 = shl nuw nsw i32 %783, 3
  %790 = zext nneg i32 %789 to i64
  %791 = shl nuw i64 %788, %790
  %792 = or i64 %791, %784
  %793 = add nuw nsw i32 %783, 1
  %794 = icmp eq i32 %793, %773
  br i1 %794, label %795, label %782

795:                                              ; preds = %782, %778, %776
  %796 = phi ptr [ %781, %778 ], [ %772, %776 ], [ %772, %782 ]
  %797 = phi i32 [ %780, %778 ], [ 0, %776 ], [ 0, %782 ]
  %798 = phi i64 [ %779, %778 ], [ 0, %776 ], [ %792, %782 ]
  %799 = icmp ugt i32 %797, 7
  br i1 %799, label %802, label %800

800:                                              ; preds = %795
  %801 = icmp eq i32 %797, 0
  br i1 %801, label %819, label %806

802:                                              ; preds = %795
  %803 = load i64, ptr %796, align 1
  %804 = add nsw i32 %797, -8
  %805 = getelementptr inbounds nuw i8, ptr %796, i64 8
  br label %819

806:                                              ; preds = %800, %806
  %807 = phi i32 [ %817, %806 ], [ 0, %800 ]
  %808 = phi i64 [ %816, %806 ], [ 0, %800 ]
  %809 = zext nneg i32 %807 to i64
  %810 = getelementptr inbounds nuw i8, ptr %796, i64 %809
  %811 = load i8, ptr %810, align 1, !tbaa !41
  %812 = zext i8 %811 to i64
  %813 = shl nuw nsw i32 %807, 3
  %814 = zext nneg i32 %813 to i64
  %815 = shl nuw i64 %812, %814
  %816 = or i64 %815, %808
  %817 = add nuw nsw i32 %807, 1
  %818 = icmp eq i32 %817, %797
  br i1 %818, label %819, label %806

819:                                              ; preds = %806, %802, %800
  %820 = phi ptr [ %805, %802 ], [ %796, %800 ], [ %796, %806 ]
  %821 = phi i32 [ %804, %802 ], [ 0, %800 ], [ 0, %806 ]
  %822 = phi i64 [ %803, %802 ], [ 0, %800 ], [ %816, %806 ]
  %823 = icmp ugt i32 %821, 7
  br i1 %823, label %826, label %824

824:                                              ; preds = %819
  %825 = icmp eq i32 %821, 0
  br i1 %825, label %841, label %828

826:                                              ; preds = %819
  %827 = load i64, ptr %820, align 1
  br label %841

828:                                              ; preds = %824, %828
  %829 = phi i32 [ %839, %828 ], [ 0, %824 ]
  %830 = phi i64 [ %838, %828 ], [ 0, %824 ]
  %831 = zext nneg i32 %829 to i64
  %832 = getelementptr inbounds nuw i8, ptr %820, i64 %831
  %833 = load i8, ptr %832, align 1, !tbaa !41
  %834 = zext i8 %833 to i64
  %835 = shl nuw nsw i32 %829, 3
  %836 = zext nneg i32 %835 to i64
  %837 = shl nuw i64 %834, %836
  %838 = or i64 %837, %830
  %839 = add nuw nsw i32 %829, 1
  %840 = icmp eq i32 %839, %821
  br i1 %840, label %841, label %828

841:                                              ; preds = %828, %826, %824
  %842 = phi i64 [ %827, %826 ], [ 0, %824 ], [ %838, %828 ]
  %843 = shl nuw nsw i64 %676, 2
  %844 = add nuw nsw i64 %843, 28
  %845 = and i64 %844, 480
  %846 = and i64 %675, -225
  %847 = or i64 %846, %678
  %848 = or i64 %847, %845
  %849 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %9)
  %850 = icmp eq i32 %9, %849
  br i1 %850, label %851, label %871

851:                                              ; preds = %841
  %852 = load atomic i64, ptr addrspace(1) %667 syncscope("one-as") acquire, align 8
  %853 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %854 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %855 = and i64 %854, %852
  %856 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %853, i64 %855
  %857 = load atomic i64, ptr addrspace(1) %856 syncscope("one-as") monotonic, align 8
  %858 = cmpxchg ptr addrspace(1) %667, i64 %852, i64 %857 syncscope("one-as") acquire monotonic, align 8
  %859 = extractvalue { i64, i1 } %858, 1
  %860 = extractvalue { i64, i1 } %858, 0
  br i1 %859, label %871, label %861

861:                                              ; preds = %851, %861
  %862 = phi i64 [ %870, %861 ], [ %860, %851 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %863 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %864 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %865 = and i64 %864, %862
  %866 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %863, i64 %865
  %867 = load atomic i64, ptr addrspace(1) %866 syncscope("one-as") monotonic, align 8
  %868 = cmpxchg ptr addrspace(1) %667, i64 %862, i64 %867 syncscope("one-as") acquire monotonic, align 8
  %869 = extractvalue { i64, i1 } %868, 1
  %870 = extractvalue { i64, i1 } %868, 0
  br i1 %869, label %871, label %861

871:                                              ; preds = %861, %851, %841
  %872 = phi i64 [ 0, %841 ], [ %860, %851 ], [ %870, %861 ]
  %873 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %872)
  %874 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %875 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %876 = and i64 %875, %873
  %877 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %874, i64 %876
  %878 = load ptr addrspace(1), ptr addrspace(1) %42, align 8, !tbaa !31
  %879 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %878, i64 %876
  %880 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %850, label %881, label %886

881:                                              ; preds = %871
  %882 = zext i32 %880 to i64
  %883 = getelementptr inbounds nuw i8, ptr addrspace(1) %877, i64 16
  %884 = getelementptr inbounds nuw i8, ptr addrspace(1) %877, i64 8
  %885 = getelementptr inbounds nuw i8, ptr addrspace(1) %877, i64 20
  store i32 2, ptr addrspace(1) %883, align 8, !tbaa !32
  store i64 %882, ptr addrspace(1) %884, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %885, align 4, !tbaa !35
  br label %886

886:                                              ; preds = %881, %871
  %887 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %879, i64 %52
  store i64 %848, ptr addrspace(1) %887, align 8, !tbaa !24
  %888 = getelementptr inbounds nuw i8, ptr addrspace(1) %887, i64 8
  store i64 %702, ptr addrspace(1) %888, align 8, !tbaa !24
  %889 = getelementptr inbounds nuw i8, ptr addrspace(1) %887, i64 16
  store i64 %726, ptr addrspace(1) %889, align 8, !tbaa !24
  %890 = getelementptr inbounds nuw i8, ptr addrspace(1) %887, i64 24
  store i64 %750, ptr addrspace(1) %890, align 8, !tbaa !24
  %891 = getelementptr inbounds nuw i8, ptr addrspace(1) %887, i64 32
  store i64 %774, ptr addrspace(1) %891, align 8, !tbaa !24
  %892 = getelementptr inbounds nuw i8, ptr addrspace(1) %887, i64 40
  store i64 %798, ptr addrspace(1) %892, align 8, !tbaa !24
  %893 = getelementptr inbounds nuw i8, ptr addrspace(1) %887, i64 48
  store i64 %822, ptr addrspace(1) %893, align 8, !tbaa !24
  %894 = getelementptr inbounds nuw i8, ptr addrspace(1) %887, i64 56
  store i64 %842, ptr addrspace(1) %894, align 8, !tbaa !24
  br i1 %850, label %895, label %922

895:                                              ; preds = %886
  %896 = load atomic i64, ptr addrspace(1) %668 syncscope("one-as") monotonic, align 8
  %897 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %898 = and i64 %897, %873
  %899 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %874, i64 %898
  store i64 %896, ptr addrspace(1) %899, align 8, !tbaa !36
  %900 = cmpxchg ptr addrspace(1) %668, i64 %896, i64 %873 syncscope("one-as") release monotonic, align 8
  %901 = extractvalue { i64, i1 } %900, 1
  br i1 %901, label %907, label %902

902:                                              ; preds = %895, %902
  %903 = phi { i64, i1 } [ %905, %902 ], [ %900, %895 ]
  %904 = extractvalue { i64, i1 } %903, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %904, ptr addrspace(1) %899, align 8, !tbaa !36
  %905 = cmpxchg ptr addrspace(1) %668, i64 %904, i64 %873 syncscope("one-as") release monotonic, align 8
  %906 = extractvalue { i64, i1 } %905, 1
  br i1 %906, label %907, label %902

907:                                              ; preds = %902, %895
  %908 = load i64, ptr addrspace(1) %669, align 8
  %909 = inttoptr i64 %908 to ptr addrspace(1)
  %910 = getelementptr inbounds nuw i8, ptr addrspace(1) %909, i64 8
  %911 = atomicrmw add ptr addrspace(1) %910, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %912 = getelementptr inbounds nuw i8, ptr addrspace(1) %909, i64 16
  %913 = load i64, ptr addrspace(1) %912, align 16, !tbaa !38
  %914 = icmp eq i64 %913, 0
  br i1 %914, label %922, label %915

915:                                              ; preds = %907
  %916 = inttoptr i64 %913 to ptr addrspace(1)
  %917 = getelementptr inbounds nuw i8, ptr addrspace(1) %909, i64 24
  %918 = load i32, ptr addrspace(1) %917, align 8, !tbaa !40
  %919 = zext i32 %918 to i64
  store atomic i64 %919, ptr addrspace(1) %916 syncscope("one-as") release, align 8
  %920 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %918)
  %921 = and i32 %920, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %921)
  br label %922

922:                                              ; preds = %915, %907, %886
  %923 = getelementptr inbounds nuw i8, ptr addrspace(1) %877, i64 20
  br label %924

924:                                              ; preds = %932, %922
  br i1 %850, label %925, label %928

925:                                              ; preds = %924
  %926 = load atomic i32, ptr addrspace(1) %923 syncscope("one-as") acquire, align 4
  %927 = and i32 %926, 1
  br label %928

928:                                              ; preds = %925, %924
  %929 = phi i32 [ %927, %925 ], [ 1, %924 ]
  %930 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %929)
  %931 = icmp eq i32 %930, 0
  br i1 %931, label %933, label %932

932:                                              ; preds = %928
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %924

933:                                              ; preds = %928
  %934 = load i64, ptr addrspace(1) %887, align 8, !tbaa !24
  %935 = load i64, ptr addrspace(1) %888, align 8, !tbaa !24
  br i1 %850, label %936, label %953

936:                                              ; preds = %933
  %937 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %938 = add i64 %937, 1
  %939 = add i64 %938, %873
  %940 = icmp eq i64 %939, 0
  %941 = select i1 %940, i64 %938, i64 %939
  %942 = load atomic i64, ptr addrspace(1) %667 syncscope("one-as") monotonic, align 8
  %943 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %944 = and i64 %941, %937
  %945 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %943, i64 %944
  store i64 %942, ptr addrspace(1) %945, align 8, !tbaa !36
  %946 = cmpxchg ptr addrspace(1) %667, i64 %942, i64 %941 syncscope("one-as") release monotonic, align 8
  %947 = extractvalue { i64, i1 } %946, 1
  br i1 %947, label %953, label %948

948:                                              ; preds = %936, %948
  %949 = phi { i64, i1 } [ %951, %948 ], [ %946, %936 ]
  %950 = extractvalue { i64, i1 } %949, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %950, ptr addrspace(1) %945, align 8, !tbaa !36
  %951 = cmpxchg ptr addrspace(1) %667, i64 %950, i64 %941 syncscope("one-as") release monotonic, align 8
  %952 = extractvalue { i64, i1 } %951, 1
  br i1 %952, label %953, label %948

953:                                              ; preds = %948, %936, %933
  %954 = insertelement <2 x i64> poison, i64 %934, i64 0
  %955 = insertelement <2 x i64> %954, i64 %935, i64 1
  %956 = sub i64 %671, %676
  %957 = getelementptr inbounds nuw i8, ptr %672, i64 %676
  %958 = icmp eq i64 %956, 0
  br i1 %958, label %959, label %670

959:                                              ; preds = %953, %655
  %960 = phi <2 x i64> [ %657, %655 ], [ %955, %953 ]
  %961 = extractelement <2 x i64> %960, i64 0
  %962 = zext i32 %2 to i64
  %963 = and i64 %961, -225
  %964 = or disjoint i64 %963, 32
  %965 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %9)
  %966 = icmp eq i32 %9, %965
  br i1 %966, label %967, label %988

967:                                              ; preds = %959
  %968 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %969 = load atomic i64, ptr addrspace(1) %968 syncscope("one-as") acquire, align 8
  %970 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %971 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %972 = and i64 %971, %969
  %973 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %970, i64 %972
  %974 = load atomic i64, ptr addrspace(1) %973 syncscope("one-as") monotonic, align 8
  %975 = cmpxchg ptr addrspace(1) %968, i64 %969, i64 %974 syncscope("one-as") acquire monotonic, align 8
  %976 = extractvalue { i64, i1 } %975, 1
  %977 = extractvalue { i64, i1 } %975, 0
  br i1 %976, label %988, label %978

978:                                              ; preds = %967, %978
  %979 = phi i64 [ %987, %978 ], [ %977, %967 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %980 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %981 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %982 = and i64 %981, %979
  %983 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %980, i64 %982
  %984 = load atomic i64, ptr addrspace(1) %983 syncscope("one-as") monotonic, align 8
  %985 = cmpxchg ptr addrspace(1) %968, i64 %979, i64 %984 syncscope("one-as") acquire monotonic, align 8
  %986 = extractvalue { i64, i1 } %985, 1
  %987 = extractvalue { i64, i1 } %985, 0
  br i1 %986, label %988, label %978

988:                                              ; preds = %978, %967, %959
  %989 = phi i64 [ 0, %959 ], [ %977, %967 ], [ %987, %978 ]
  %990 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %989)
  %991 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %992 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %993 = and i64 %992, %990
  %994 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %991, i64 %993
  %995 = load ptr addrspace(1), ptr addrspace(1) %42, align 8, !tbaa !31
  %996 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %995, i64 %993
  %997 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %966, label %998, label %1003

998:                                              ; preds = %988
  %999 = zext i32 %997 to i64
  %1000 = getelementptr inbounds nuw i8, ptr addrspace(1) %994, i64 16
  %1001 = getelementptr inbounds nuw i8, ptr addrspace(1) %994, i64 8
  %1002 = getelementptr inbounds nuw i8, ptr addrspace(1) %994, i64 20
  store i32 2, ptr addrspace(1) %1000, align 8, !tbaa !32
  store i64 %999, ptr addrspace(1) %1001, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %1002, align 4, !tbaa !35
  br label %1003

1003:                                             ; preds = %998, %988
  %1004 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %996, i64 %52
  store i64 %964, ptr addrspace(1) %1004, align 8, !tbaa !24
  %1005 = getelementptr inbounds nuw i8, ptr addrspace(1) %1004, i64 8
  store i64 %962, ptr addrspace(1) %1005, align 8, !tbaa !24
  %1006 = getelementptr inbounds nuw i8, ptr addrspace(1) %1004, i64 16
  store i64 0, ptr addrspace(1) %1006, align 8, !tbaa !24
  %1007 = getelementptr inbounds nuw i8, ptr addrspace(1) %1004, i64 24
  store i64 0, ptr addrspace(1) %1007, align 8, !tbaa !24
  %1008 = getelementptr inbounds nuw i8, ptr addrspace(1) %1004, i64 32
  store i64 0, ptr addrspace(1) %1008, align 8, !tbaa !24
  %1009 = getelementptr inbounds nuw i8, ptr addrspace(1) %1004, i64 40
  store i64 0, ptr addrspace(1) %1009, align 8, !tbaa !24
  %1010 = getelementptr inbounds nuw i8, ptr addrspace(1) %1004, i64 48
  store i64 0, ptr addrspace(1) %1010, align 8, !tbaa !24
  %1011 = getelementptr inbounds nuw i8, ptr addrspace(1) %1004, i64 56
  store i64 0, ptr addrspace(1) %1011, align 8, !tbaa !24
  br i1 %966, label %1012, label %1041

1012:                                             ; preds = %1003
  %1013 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 32
  %1014 = load atomic i64, ptr addrspace(1) %1013 syncscope("one-as") monotonic, align 8
  %1015 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1016 = and i64 %1015, %990
  %1017 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %991, i64 %1016
  store i64 %1014, ptr addrspace(1) %1017, align 8, !tbaa !36
  %1018 = cmpxchg ptr addrspace(1) %1013, i64 %1014, i64 %990 syncscope("one-as") release monotonic, align 8
  %1019 = extractvalue { i64, i1 } %1018, 1
  br i1 %1019, label %1025, label %1020

1020:                                             ; preds = %1012, %1020
  %1021 = phi { i64, i1 } [ %1023, %1020 ], [ %1018, %1012 ]
  %1022 = extractvalue { i64, i1 } %1021, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %1022, ptr addrspace(1) %1017, align 8, !tbaa !36
  %1023 = cmpxchg ptr addrspace(1) %1013, i64 %1022, i64 %990 syncscope("one-as") release monotonic, align 8
  %1024 = extractvalue { i64, i1 } %1023, 1
  br i1 %1024, label %1025, label %1020

1025:                                             ; preds = %1020, %1012
  %1026 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 16
  %1027 = load i64, ptr addrspace(1) %1026, align 8
  %1028 = inttoptr i64 %1027 to ptr addrspace(1)
  %1029 = getelementptr inbounds nuw i8, ptr addrspace(1) %1028, i64 8
  %1030 = atomicrmw add ptr addrspace(1) %1029, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %1031 = getelementptr inbounds nuw i8, ptr addrspace(1) %1028, i64 16
  %1032 = load i64, ptr addrspace(1) %1031, align 16, !tbaa !38
  %1033 = icmp eq i64 %1032, 0
  br i1 %1033, label %1041, label %1034

1034:                                             ; preds = %1025
  %1035 = inttoptr i64 %1032 to ptr addrspace(1)
  %1036 = getelementptr inbounds nuw i8, ptr addrspace(1) %1028, i64 24
  %1037 = load i32, ptr addrspace(1) %1036, align 8, !tbaa !40
  %1038 = zext i32 %1037 to i64
  store atomic i64 %1038, ptr addrspace(1) %1035 syncscope("one-as") release, align 8
  %1039 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %1037)
  %1040 = and i32 %1039, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %1040)
  br label %1041

1041:                                             ; preds = %1034, %1025, %1003
  %1042 = getelementptr inbounds nuw i8, ptr addrspace(1) %994, i64 20
  br label %1043

1043:                                             ; preds = %1051, %1041
  br i1 %966, label %1044, label %1047

1044:                                             ; preds = %1043
  %1045 = load atomic i32, ptr addrspace(1) %1042 syncscope("one-as") acquire, align 4
  %1046 = and i32 %1045, 1
  br label %1047

1047:                                             ; preds = %1044, %1043
  %1048 = phi i32 [ %1046, %1044 ], [ 1, %1043 ]
  %1049 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %1048)
  %1050 = icmp eq i32 %1049, 0
  br i1 %1050, label %1052, label %1051

1051:                                             ; preds = %1047
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %1043

1052:                                             ; preds = %1047
  %1053 = load i64, ptr addrspace(1) %1004, align 8, !tbaa !24
  br i1 %966, label %1054, label %1072

1054:                                             ; preds = %1052
  %1055 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1056 = add i64 %1055, 1
  %1057 = add i64 %1056, %990
  %1058 = icmp eq i64 %1057, 0
  %1059 = select i1 %1058, i64 %1056, i64 %1057
  %1060 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %1061 = load atomic i64, ptr addrspace(1) %1060 syncscope("one-as") monotonic, align 8
  %1062 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1063 = and i64 %1059, %1055
  %1064 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1062, i64 %1063
  store i64 %1061, ptr addrspace(1) %1064, align 8, !tbaa !36
  %1065 = cmpxchg ptr addrspace(1) %1060, i64 %1061, i64 %1059 syncscope("one-as") release monotonic, align 8
  %1066 = extractvalue { i64, i1 } %1065, 1
  br i1 %1066, label %1072, label %1067

1067:                                             ; preds = %1054, %1067
  %1068 = phi { i64, i1 } [ %1070, %1067 ], [ %1065, %1054 ]
  %1069 = extractvalue { i64, i1 } %1068, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %1069, ptr addrspace(1) %1064, align 8, !tbaa !36
  %1070 = cmpxchg ptr addrspace(1) %1060, i64 %1069, i64 %1059 syncscope("one-as") release monotonic, align 8
  %1071 = extractvalue { i64, i1 } %1070, 1
  br i1 %1071, label %1072, label %1067

1072:                                             ; preds = %1067, %1052, %1054
  br label %1073

1073:                                             ; preds = %1072, %1073
  %1074 = phi ptr [ %1075, %1073 ], [ %3, %1072 ]
  %1075 = getelementptr inbounds nuw i8, ptr %1074, i64 1
  %1076 = load i8, ptr %1074, align 1, !tbaa !42
  %1077 = icmp eq i8 %1076, 0
  br i1 %1077, label %1078, label %1073, !llvm.loop !45

1078:                                             ; preds = %1073
  %1079 = icmp eq ptr %3, null
  br i1 %1079, label %1080, label %1194

1080:                                             ; preds = %1078
  %1081 = and i64 %1053, -225
  %1082 = or disjoint i64 %1081, 32
  %1083 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %9)
  %1084 = icmp eq i32 %9, %1083
  br i1 %1084, label %1085, label %1106

1085:                                             ; preds = %1080
  %1086 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %1087 = load atomic i64, ptr addrspace(1) %1086 syncscope("one-as") acquire, align 8
  %1088 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1089 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1090 = and i64 %1089, %1087
  %1091 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1088, i64 %1090
  %1092 = load atomic i64, ptr addrspace(1) %1091 syncscope("one-as") monotonic, align 8
  %1093 = cmpxchg ptr addrspace(1) %1086, i64 %1087, i64 %1092 syncscope("one-as") acquire monotonic, align 8
  %1094 = extractvalue { i64, i1 } %1093, 1
  %1095 = extractvalue { i64, i1 } %1093, 0
  br i1 %1094, label %1106, label %1096

1096:                                             ; preds = %1085, %1096
  %1097 = phi i64 [ %1105, %1096 ], [ %1095, %1085 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %1098 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1099 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1100 = and i64 %1099, %1097
  %1101 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1098, i64 %1100
  %1102 = load atomic i64, ptr addrspace(1) %1101 syncscope("one-as") monotonic, align 8
  %1103 = cmpxchg ptr addrspace(1) %1086, i64 %1097, i64 %1102 syncscope("one-as") acquire monotonic, align 8
  %1104 = extractvalue { i64, i1 } %1103, 1
  %1105 = extractvalue { i64, i1 } %1103, 0
  br i1 %1104, label %1106, label %1096

1106:                                             ; preds = %1096, %1085, %1080
  %1107 = phi i64 [ 0, %1080 ], [ %1095, %1085 ], [ %1105, %1096 ]
  %1108 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %1107)
  %1109 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1110 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1111 = and i64 %1110, %1108
  %1112 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1109, i64 %1111
  %1113 = load ptr addrspace(1), ptr addrspace(1) %42, align 8, !tbaa !31
  %1114 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %1113, i64 %1111
  %1115 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %1084, label %1116, label %1121

1116:                                             ; preds = %1106
  %1117 = zext i32 %1115 to i64
  %1118 = getelementptr inbounds nuw i8, ptr addrspace(1) %1112, i64 16
  %1119 = getelementptr inbounds nuw i8, ptr addrspace(1) %1112, i64 8
  %1120 = getelementptr inbounds nuw i8, ptr addrspace(1) %1112, i64 20
  store i32 2, ptr addrspace(1) %1118, align 8, !tbaa !32
  store i64 %1117, ptr addrspace(1) %1119, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %1120, align 4, !tbaa !35
  br label %1121

1121:                                             ; preds = %1116, %1106
  %1122 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %1114, i64 %52
  store i64 %1082, ptr addrspace(1) %1122, align 8, !tbaa !24
  %1123 = getelementptr inbounds nuw i8, ptr addrspace(1) %1122, i64 8
  store i64 0, ptr addrspace(1) %1123, align 8, !tbaa !24
  %1124 = getelementptr inbounds nuw i8, ptr addrspace(1) %1122, i64 16
  store i64 0, ptr addrspace(1) %1124, align 8, !tbaa !24
  %1125 = getelementptr inbounds nuw i8, ptr addrspace(1) %1122, i64 24
  store i64 0, ptr addrspace(1) %1125, align 8, !tbaa !24
  %1126 = getelementptr inbounds nuw i8, ptr addrspace(1) %1122, i64 32
  store i64 0, ptr addrspace(1) %1126, align 8, !tbaa !24
  %1127 = getelementptr inbounds nuw i8, ptr addrspace(1) %1122, i64 40
  store i64 0, ptr addrspace(1) %1127, align 8, !tbaa !24
  %1128 = getelementptr inbounds nuw i8, ptr addrspace(1) %1122, i64 48
  store i64 0, ptr addrspace(1) %1128, align 8, !tbaa !24
  %1129 = getelementptr inbounds nuw i8, ptr addrspace(1) %1122, i64 56
  store i64 0, ptr addrspace(1) %1129, align 8, !tbaa !24
  br i1 %1084, label %1130, label %1159

1130:                                             ; preds = %1121
  %1131 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 32
  %1132 = load atomic i64, ptr addrspace(1) %1131 syncscope("one-as") monotonic, align 8
  %1133 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1134 = and i64 %1133, %1108
  %1135 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1109, i64 %1134
  store i64 %1132, ptr addrspace(1) %1135, align 8, !tbaa !36
  %1136 = cmpxchg ptr addrspace(1) %1131, i64 %1132, i64 %1108 syncscope("one-as") release monotonic, align 8
  %1137 = extractvalue { i64, i1 } %1136, 1
  br i1 %1137, label %1143, label %1138

1138:                                             ; preds = %1130, %1138
  %1139 = phi { i64, i1 } [ %1141, %1138 ], [ %1136, %1130 ]
  %1140 = extractvalue { i64, i1 } %1139, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %1140, ptr addrspace(1) %1135, align 8, !tbaa !36
  %1141 = cmpxchg ptr addrspace(1) %1131, i64 %1140, i64 %1108 syncscope("one-as") release monotonic, align 8
  %1142 = extractvalue { i64, i1 } %1141, 1
  br i1 %1142, label %1143, label %1138

1143:                                             ; preds = %1138, %1130
  %1144 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 16
  %1145 = load i64, ptr addrspace(1) %1144, align 8
  %1146 = inttoptr i64 %1145 to ptr addrspace(1)
  %1147 = getelementptr inbounds nuw i8, ptr addrspace(1) %1146, i64 8
  %1148 = atomicrmw add ptr addrspace(1) %1147, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %1149 = getelementptr inbounds nuw i8, ptr addrspace(1) %1146, i64 16
  %1150 = load i64, ptr addrspace(1) %1149, align 16, !tbaa !38
  %1151 = icmp eq i64 %1150, 0
  br i1 %1151, label %1159, label %1152

1152:                                             ; preds = %1143
  %1153 = inttoptr i64 %1150 to ptr addrspace(1)
  %1154 = getelementptr inbounds nuw i8, ptr addrspace(1) %1146, i64 24
  %1155 = load i32, ptr addrspace(1) %1154, align 8, !tbaa !40
  %1156 = zext i32 %1155 to i64
  store atomic i64 %1156, ptr addrspace(1) %1153 syncscope("one-as") release, align 8
  %1157 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %1155)
  %1158 = and i32 %1157, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %1158)
  br label %1159

1159:                                             ; preds = %1152, %1143, %1121
  %1160 = getelementptr inbounds nuw i8, ptr addrspace(1) %1112, i64 20
  br label %1161

1161:                                             ; preds = %1169, %1159
  br i1 %1084, label %1162, label %1165

1162:                                             ; preds = %1161
  %1163 = load atomic i32, ptr addrspace(1) %1160 syncscope("one-as") acquire, align 4
  %1164 = and i32 %1163, 1
  br label %1165

1165:                                             ; preds = %1162, %1161
  %1166 = phi i32 [ %1164, %1162 ], [ 1, %1161 ]
  %1167 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %1166)
  %1168 = icmp eq i32 %1167, 0
  br i1 %1168, label %1170, label %1169

1169:                                             ; preds = %1165
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %1161

1170:                                             ; preds = %1165
  %1171 = load i64, ptr addrspace(1) %1122, align 8, !tbaa !24
  %1172 = load i64, ptr addrspace(1) %1123, align 8, !tbaa !24
  br i1 %1084, label %1173, label %1191

1173:                                             ; preds = %1170
  %1174 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1175 = add i64 %1174, 1
  %1176 = add i64 %1175, %1108
  %1177 = icmp eq i64 %1176, 0
  %1178 = select i1 %1177, i64 %1175, i64 %1176
  %1179 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %1180 = load atomic i64, ptr addrspace(1) %1179 syncscope("one-as") monotonic, align 8
  %1181 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1182 = and i64 %1178, %1174
  %1183 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1181, i64 %1182
  store i64 %1180, ptr addrspace(1) %1183, align 8, !tbaa !36
  %1184 = cmpxchg ptr addrspace(1) %1179, i64 %1180, i64 %1178 syncscope("one-as") release monotonic, align 8
  %1185 = extractvalue { i64, i1 } %1184, 1
  br i1 %1185, label %1191, label %1186

1186:                                             ; preds = %1173, %1186
  %1187 = phi { i64, i1 } [ %1189, %1186 ], [ %1184, %1173 ]
  %1188 = extractvalue { i64, i1 } %1187, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %1188, ptr addrspace(1) %1183, align 8, !tbaa !36
  %1189 = cmpxchg ptr addrspace(1) %1179, i64 %1188, i64 %1178 syncscope("one-as") release monotonic, align 8
  %1190 = extractvalue { i64, i1 } %1189, 1
  br i1 %1190, label %1191, label %1186

1191:                                             ; preds = %1186, %1173, %1170
  %1192 = insertelement <2 x i64> poison, i64 %1171, i64 0
  %1193 = insertelement <2 x i64> %1192, i64 %1172, i64 1
  br label %1495

1194:                                             ; preds = %1078
  %1195 = ptrtoint ptr %1075 to i64
  %1196 = ptrtoint ptr %3 to i64
  %1197 = sub i64 %1195, %1196
  %1198 = shl i64 %1197, 32
  %1199 = ashr exact i64 %1198, 32
  %1200 = and i64 %1053, 2
  %1201 = and i64 %1053, -3
  %1202 = insertelement <2 x i64> <i64 poison, i64 0>, i64 %1201, i64 0
  %1203 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 24
  %1204 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 32
  %1205 = getelementptr inbounds nuw i8, ptr addrspace(1) %8, i64 16
  br label %1206

1206:                                             ; preds = %1489, %1194
  %1207 = phi i64 [ %1199, %1194 ], [ %1492, %1489 ]
  %1208 = phi ptr [ %3, %1194 ], [ %1493, %1489 ]
  %1209 = phi <2 x i64> [ %1202, %1194 ], [ %1491, %1489 ]
  %1210 = icmp ugt i64 %1207, 56
  %1211 = extractelement <2 x i64> %1209, i64 0
  %1212 = tail call i64 @llvm.umin.i64(i64 %1207, i64 56)
  %1213 = trunc nuw nsw i64 %1212 to i32
  %1214 = select i1 %1210, i64 0, i64 %1200
  %1215 = icmp ugt i64 %1207, 7
  br i1 %1215, label %1218, label %1216

1216:                                             ; preds = %1206
  %1217 = icmp eq i64 %1207, 0
  br i1 %1217, label %1235, label %1222

1218:                                             ; preds = %1206
  %1219 = load i64, ptr %1208, align 1
  %1220 = add nsw i32 %1213, -8
  %1221 = getelementptr inbounds nuw i8, ptr %1208, i64 8
  br label %1235

1222:                                             ; preds = %1216, %1222
  %1223 = phi i32 [ %1233, %1222 ], [ 0, %1216 ]
  %1224 = phi i64 [ %1232, %1222 ], [ 0, %1216 ]
  %1225 = zext nneg i32 %1223 to i64
  %1226 = getelementptr inbounds nuw i8, ptr %1208, i64 %1225
  %1227 = load i8, ptr %1226, align 1, !tbaa !41
  %1228 = zext i8 %1227 to i64
  %1229 = shl nuw nsw i32 %1223, 3
  %1230 = zext nneg i32 %1229 to i64
  %1231 = shl nuw i64 %1228, %1230
  %1232 = or i64 %1231, %1224
  %1233 = add nuw nsw i32 %1223, 1
  %1234 = icmp eq i32 %1233, %1213
  br i1 %1234, label %1235, label %1222

1235:                                             ; preds = %1222, %1218, %1216
  %1236 = phi ptr [ %1221, %1218 ], [ %1208, %1216 ], [ %1208, %1222 ]
  %1237 = phi i32 [ %1220, %1218 ], [ 0, %1216 ], [ 0, %1222 ]
  %1238 = phi i64 [ %1219, %1218 ], [ 0, %1216 ], [ %1232, %1222 ]
  %1239 = icmp ugt i32 %1237, 7
  br i1 %1239, label %1242, label %1240

1240:                                             ; preds = %1235
  %1241 = icmp eq i32 %1237, 0
  br i1 %1241, label %1259, label %1246

1242:                                             ; preds = %1235
  %1243 = load i64, ptr %1236, align 1
  %1244 = add nsw i32 %1237, -8
  %1245 = getelementptr inbounds nuw i8, ptr %1236, i64 8
  br label %1259

1246:                                             ; preds = %1240, %1246
  %1247 = phi i32 [ %1257, %1246 ], [ 0, %1240 ]
  %1248 = phi i64 [ %1256, %1246 ], [ 0, %1240 ]
  %1249 = zext nneg i32 %1247 to i64
  %1250 = getelementptr inbounds nuw i8, ptr %1236, i64 %1249
  %1251 = load i8, ptr %1250, align 1, !tbaa !41
  %1252 = zext i8 %1251 to i64
  %1253 = shl nuw nsw i32 %1247, 3
  %1254 = zext nneg i32 %1253 to i64
  %1255 = shl nuw i64 %1252, %1254
  %1256 = or i64 %1255, %1248
  %1257 = add nuw nsw i32 %1247, 1
  %1258 = icmp eq i32 %1257, %1237
  br i1 %1258, label %1259, label %1246

1259:                                             ; preds = %1246, %1242, %1240
  %1260 = phi ptr [ %1245, %1242 ], [ %1236, %1240 ], [ %1236, %1246 ]
  %1261 = phi i32 [ %1244, %1242 ], [ 0, %1240 ], [ 0, %1246 ]
  %1262 = phi i64 [ %1243, %1242 ], [ 0, %1240 ], [ %1256, %1246 ]
  %1263 = icmp ugt i32 %1261, 7
  br i1 %1263, label %1266, label %1264

1264:                                             ; preds = %1259
  %1265 = icmp eq i32 %1261, 0
  br i1 %1265, label %1283, label %1270

1266:                                             ; preds = %1259
  %1267 = load i64, ptr %1260, align 1
  %1268 = add nsw i32 %1261, -8
  %1269 = getelementptr inbounds nuw i8, ptr %1260, i64 8
  br label %1283

1270:                                             ; preds = %1264, %1270
  %1271 = phi i32 [ %1281, %1270 ], [ 0, %1264 ]
  %1272 = phi i64 [ %1280, %1270 ], [ 0, %1264 ]
  %1273 = zext nneg i32 %1271 to i64
  %1274 = getelementptr inbounds nuw i8, ptr %1260, i64 %1273
  %1275 = load i8, ptr %1274, align 1, !tbaa !41
  %1276 = zext i8 %1275 to i64
  %1277 = shl nuw nsw i32 %1271, 3
  %1278 = zext nneg i32 %1277 to i64
  %1279 = shl nuw i64 %1276, %1278
  %1280 = or i64 %1279, %1272
  %1281 = add nuw nsw i32 %1271, 1
  %1282 = icmp eq i32 %1281, %1261
  br i1 %1282, label %1283, label %1270

1283:                                             ; preds = %1270, %1266, %1264
  %1284 = phi ptr [ %1269, %1266 ], [ %1260, %1264 ], [ %1260, %1270 ]
  %1285 = phi i32 [ %1268, %1266 ], [ 0, %1264 ], [ 0, %1270 ]
  %1286 = phi i64 [ %1267, %1266 ], [ 0, %1264 ], [ %1280, %1270 ]
  %1287 = icmp ugt i32 %1285, 7
  br i1 %1287, label %1290, label %1288

1288:                                             ; preds = %1283
  %1289 = icmp eq i32 %1285, 0
  br i1 %1289, label %1307, label %1294

1290:                                             ; preds = %1283
  %1291 = load i64, ptr %1284, align 1
  %1292 = add nsw i32 %1285, -8
  %1293 = getelementptr inbounds nuw i8, ptr %1284, i64 8
  br label %1307

1294:                                             ; preds = %1288, %1294
  %1295 = phi i32 [ %1305, %1294 ], [ 0, %1288 ]
  %1296 = phi i64 [ %1304, %1294 ], [ 0, %1288 ]
  %1297 = zext nneg i32 %1295 to i64
  %1298 = getelementptr inbounds nuw i8, ptr %1284, i64 %1297
  %1299 = load i8, ptr %1298, align 1, !tbaa !41
  %1300 = zext i8 %1299 to i64
  %1301 = shl nuw nsw i32 %1295, 3
  %1302 = zext nneg i32 %1301 to i64
  %1303 = shl nuw i64 %1300, %1302
  %1304 = or i64 %1303, %1296
  %1305 = add nuw nsw i32 %1295, 1
  %1306 = icmp eq i32 %1305, %1285
  br i1 %1306, label %1307, label %1294

1307:                                             ; preds = %1294, %1290, %1288
  %1308 = phi ptr [ %1293, %1290 ], [ %1284, %1288 ], [ %1284, %1294 ]
  %1309 = phi i32 [ %1292, %1290 ], [ 0, %1288 ], [ 0, %1294 ]
  %1310 = phi i64 [ %1291, %1290 ], [ 0, %1288 ], [ %1304, %1294 ]
  %1311 = icmp ugt i32 %1309, 7
  br i1 %1311, label %1314, label %1312

1312:                                             ; preds = %1307
  %1313 = icmp eq i32 %1309, 0
  br i1 %1313, label %1331, label %1318

1314:                                             ; preds = %1307
  %1315 = load i64, ptr %1308, align 1
  %1316 = add nsw i32 %1309, -8
  %1317 = getelementptr inbounds nuw i8, ptr %1308, i64 8
  br label %1331

1318:                                             ; preds = %1312, %1318
  %1319 = phi i32 [ %1329, %1318 ], [ 0, %1312 ]
  %1320 = phi i64 [ %1328, %1318 ], [ 0, %1312 ]
  %1321 = zext nneg i32 %1319 to i64
  %1322 = getelementptr inbounds nuw i8, ptr %1308, i64 %1321
  %1323 = load i8, ptr %1322, align 1, !tbaa !41
  %1324 = zext i8 %1323 to i64
  %1325 = shl nuw nsw i32 %1319, 3
  %1326 = zext nneg i32 %1325 to i64
  %1327 = shl nuw i64 %1324, %1326
  %1328 = or i64 %1327, %1320
  %1329 = add nuw nsw i32 %1319, 1
  %1330 = icmp eq i32 %1329, %1309
  br i1 %1330, label %1331, label %1318

1331:                                             ; preds = %1318, %1314, %1312
  %1332 = phi ptr [ %1317, %1314 ], [ %1308, %1312 ], [ %1308, %1318 ]
  %1333 = phi i32 [ %1316, %1314 ], [ 0, %1312 ], [ 0, %1318 ]
  %1334 = phi i64 [ %1315, %1314 ], [ 0, %1312 ], [ %1328, %1318 ]
  %1335 = icmp ugt i32 %1333, 7
  br i1 %1335, label %1338, label %1336

1336:                                             ; preds = %1331
  %1337 = icmp eq i32 %1333, 0
  br i1 %1337, label %1355, label %1342

1338:                                             ; preds = %1331
  %1339 = load i64, ptr %1332, align 1
  %1340 = add nsw i32 %1333, -8
  %1341 = getelementptr inbounds nuw i8, ptr %1332, i64 8
  br label %1355

1342:                                             ; preds = %1336, %1342
  %1343 = phi i32 [ %1353, %1342 ], [ 0, %1336 ]
  %1344 = phi i64 [ %1352, %1342 ], [ 0, %1336 ]
  %1345 = zext nneg i32 %1343 to i64
  %1346 = getelementptr inbounds nuw i8, ptr %1332, i64 %1345
  %1347 = load i8, ptr %1346, align 1, !tbaa !41
  %1348 = zext i8 %1347 to i64
  %1349 = shl nuw nsw i32 %1343, 3
  %1350 = zext nneg i32 %1349 to i64
  %1351 = shl nuw i64 %1348, %1350
  %1352 = or i64 %1351, %1344
  %1353 = add nuw nsw i32 %1343, 1
  %1354 = icmp eq i32 %1353, %1333
  br i1 %1354, label %1355, label %1342

1355:                                             ; preds = %1342, %1338, %1336
  %1356 = phi ptr [ %1341, %1338 ], [ %1332, %1336 ], [ %1332, %1342 ]
  %1357 = phi i32 [ %1340, %1338 ], [ 0, %1336 ], [ 0, %1342 ]
  %1358 = phi i64 [ %1339, %1338 ], [ 0, %1336 ], [ %1352, %1342 ]
  %1359 = icmp ugt i32 %1357, 7
  br i1 %1359, label %1362, label %1360

1360:                                             ; preds = %1355
  %1361 = icmp eq i32 %1357, 0
  br i1 %1361, label %1377, label %1364

1362:                                             ; preds = %1355
  %1363 = load i64, ptr %1356, align 1
  br label %1377

1364:                                             ; preds = %1360, %1364
  %1365 = phi i32 [ %1375, %1364 ], [ 0, %1360 ]
  %1366 = phi i64 [ %1374, %1364 ], [ 0, %1360 ]
  %1367 = zext nneg i32 %1365 to i64
  %1368 = getelementptr inbounds nuw i8, ptr %1356, i64 %1367
  %1369 = load i8, ptr %1368, align 1, !tbaa !41
  %1370 = zext i8 %1369 to i64
  %1371 = shl nuw nsw i32 %1365, 3
  %1372 = zext nneg i32 %1371 to i64
  %1373 = shl nuw i64 %1370, %1372
  %1374 = or i64 %1373, %1366
  %1375 = add nuw nsw i32 %1365, 1
  %1376 = icmp eq i32 %1375, %1357
  br i1 %1376, label %1377, label %1364

1377:                                             ; preds = %1364, %1362, %1360
  %1378 = phi i64 [ %1363, %1362 ], [ 0, %1360 ], [ %1374, %1364 ]
  %1379 = shl nuw nsw i64 %1212, 2
  %1380 = add nuw nsw i64 %1379, 28
  %1381 = and i64 %1380, 480
  %1382 = and i64 %1211, -225
  %1383 = or i64 %1382, %1214
  %1384 = or i64 %1383, %1381
  %1385 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %9)
  %1386 = icmp eq i32 %9, %1385
  br i1 %1386, label %1387, label %1407

1387:                                             ; preds = %1377
  %1388 = load atomic i64, ptr addrspace(1) %1203 syncscope("one-as") acquire, align 8
  %1389 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1390 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1391 = and i64 %1390, %1388
  %1392 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1389, i64 %1391
  %1393 = load atomic i64, ptr addrspace(1) %1392 syncscope("one-as") monotonic, align 8
  %1394 = cmpxchg ptr addrspace(1) %1203, i64 %1388, i64 %1393 syncscope("one-as") acquire monotonic, align 8
  %1395 = extractvalue { i64, i1 } %1394, 1
  %1396 = extractvalue { i64, i1 } %1394, 0
  br i1 %1395, label %1407, label %1397

1397:                                             ; preds = %1387, %1397
  %1398 = phi i64 [ %1406, %1397 ], [ %1396, %1387 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %1399 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1400 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1401 = and i64 %1400, %1398
  %1402 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1399, i64 %1401
  %1403 = load atomic i64, ptr addrspace(1) %1402 syncscope("one-as") monotonic, align 8
  %1404 = cmpxchg ptr addrspace(1) %1203, i64 %1398, i64 %1403 syncscope("one-as") acquire monotonic, align 8
  %1405 = extractvalue { i64, i1 } %1404, 1
  %1406 = extractvalue { i64, i1 } %1404, 0
  br i1 %1405, label %1407, label %1397

1407:                                             ; preds = %1397, %1387, %1377
  %1408 = phi i64 [ 0, %1377 ], [ %1396, %1387 ], [ %1406, %1397 ]
  %1409 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %1408)
  %1410 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1411 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1412 = and i64 %1411, %1409
  %1413 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1410, i64 %1412
  %1414 = load ptr addrspace(1), ptr addrspace(1) %42, align 8, !tbaa !31
  %1415 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %1414, i64 %1412
  %1416 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %1386, label %1417, label %1422

1417:                                             ; preds = %1407
  %1418 = zext i32 %1416 to i64
  %1419 = getelementptr inbounds nuw i8, ptr addrspace(1) %1413, i64 16
  %1420 = getelementptr inbounds nuw i8, ptr addrspace(1) %1413, i64 8
  %1421 = getelementptr inbounds nuw i8, ptr addrspace(1) %1413, i64 20
  store i32 2, ptr addrspace(1) %1419, align 8, !tbaa !32
  store i64 %1418, ptr addrspace(1) %1420, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %1421, align 4, !tbaa !35
  br label %1422

1422:                                             ; preds = %1417, %1407
  %1423 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %1415, i64 %52
  store i64 %1384, ptr addrspace(1) %1423, align 8, !tbaa !24
  %1424 = getelementptr inbounds nuw i8, ptr addrspace(1) %1423, i64 8
  store i64 %1238, ptr addrspace(1) %1424, align 8, !tbaa !24
  %1425 = getelementptr inbounds nuw i8, ptr addrspace(1) %1423, i64 16
  store i64 %1262, ptr addrspace(1) %1425, align 8, !tbaa !24
  %1426 = getelementptr inbounds nuw i8, ptr addrspace(1) %1423, i64 24
  store i64 %1286, ptr addrspace(1) %1426, align 8, !tbaa !24
  %1427 = getelementptr inbounds nuw i8, ptr addrspace(1) %1423, i64 32
  store i64 %1310, ptr addrspace(1) %1427, align 8, !tbaa !24
  %1428 = getelementptr inbounds nuw i8, ptr addrspace(1) %1423, i64 40
  store i64 %1334, ptr addrspace(1) %1428, align 8, !tbaa !24
  %1429 = getelementptr inbounds nuw i8, ptr addrspace(1) %1423, i64 48
  store i64 %1358, ptr addrspace(1) %1429, align 8, !tbaa !24
  %1430 = getelementptr inbounds nuw i8, ptr addrspace(1) %1423, i64 56
  store i64 %1378, ptr addrspace(1) %1430, align 8, !tbaa !24
  br i1 %1386, label %1431, label %1458

1431:                                             ; preds = %1422
  %1432 = load atomic i64, ptr addrspace(1) %1204 syncscope("one-as") monotonic, align 8
  %1433 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1434 = and i64 %1433, %1409
  %1435 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1410, i64 %1434
  store i64 %1432, ptr addrspace(1) %1435, align 8, !tbaa !36
  %1436 = cmpxchg ptr addrspace(1) %1204, i64 %1432, i64 %1409 syncscope("one-as") release monotonic, align 8
  %1437 = extractvalue { i64, i1 } %1436, 1
  br i1 %1437, label %1443, label %1438

1438:                                             ; preds = %1431, %1438
  %1439 = phi { i64, i1 } [ %1441, %1438 ], [ %1436, %1431 ]
  %1440 = extractvalue { i64, i1 } %1439, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %1440, ptr addrspace(1) %1435, align 8, !tbaa !36
  %1441 = cmpxchg ptr addrspace(1) %1204, i64 %1440, i64 %1409 syncscope("one-as") release monotonic, align 8
  %1442 = extractvalue { i64, i1 } %1441, 1
  br i1 %1442, label %1443, label %1438

1443:                                             ; preds = %1438, %1431
  %1444 = load i64, ptr addrspace(1) %1205, align 8
  %1445 = inttoptr i64 %1444 to ptr addrspace(1)
  %1446 = getelementptr inbounds nuw i8, ptr addrspace(1) %1445, i64 8
  %1447 = atomicrmw add ptr addrspace(1) %1446, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %1448 = getelementptr inbounds nuw i8, ptr addrspace(1) %1445, i64 16
  %1449 = load i64, ptr addrspace(1) %1448, align 16, !tbaa !38
  %1450 = icmp eq i64 %1449, 0
  br i1 %1450, label %1458, label %1451

1451:                                             ; preds = %1443
  %1452 = inttoptr i64 %1449 to ptr addrspace(1)
  %1453 = getelementptr inbounds nuw i8, ptr addrspace(1) %1445, i64 24
  %1454 = load i32, ptr addrspace(1) %1453, align 8, !tbaa !40
  %1455 = zext i32 %1454 to i64
  store atomic i64 %1455, ptr addrspace(1) %1452 syncscope("one-as") release, align 8
  %1456 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %1454)
  %1457 = and i32 %1456, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %1457)
  br label %1458

1458:                                             ; preds = %1451, %1443, %1422
  %1459 = getelementptr inbounds nuw i8, ptr addrspace(1) %1413, i64 20
  br label %1460

1460:                                             ; preds = %1468, %1458
  br i1 %1386, label %1461, label %1464

1461:                                             ; preds = %1460
  %1462 = load atomic i32, ptr addrspace(1) %1459 syncscope("one-as") acquire, align 4
  %1463 = and i32 %1462, 1
  br label %1464

1464:                                             ; preds = %1461, %1460
  %1465 = phi i32 [ %1463, %1461 ], [ 1, %1460 ]
  %1466 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %1465)
  %1467 = icmp eq i32 %1466, 0
  br i1 %1467, label %1469, label %1468

1468:                                             ; preds = %1464
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %1460

1469:                                             ; preds = %1464
  %1470 = load i64, ptr addrspace(1) %1423, align 8, !tbaa !24
  %1471 = load i64, ptr addrspace(1) %1424, align 8, !tbaa !24
  br i1 %1386, label %1472, label %1489

1472:                                             ; preds = %1469
  %1473 = load i64, ptr addrspace(1) %38, align 8, !tbaa !30
  %1474 = add i64 %1473, 1
  %1475 = add i64 %1474, %1409
  %1476 = icmp eq i64 %1475, 0
  %1477 = select i1 %1476, i64 %1474, i64 %1475
  %1478 = load atomic i64, ptr addrspace(1) %1203 syncscope("one-as") monotonic, align 8
  %1479 = load ptr addrspace(1), ptr addrspace(1) %8, align 8, !tbaa !26
  %1480 = and i64 %1477, %1473
  %1481 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %1479, i64 %1480
  store i64 %1478, ptr addrspace(1) %1481, align 8, !tbaa !36
  %1482 = cmpxchg ptr addrspace(1) %1203, i64 %1478, i64 %1477 syncscope("one-as") release monotonic, align 8
  %1483 = extractvalue { i64, i1 } %1482, 1
  br i1 %1483, label %1489, label %1484

1484:                                             ; preds = %1472, %1484
  %1485 = phi { i64, i1 } [ %1487, %1484 ], [ %1482, %1472 ]
  %1486 = extractvalue { i64, i1 } %1485, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %1486, ptr addrspace(1) %1481, align 8, !tbaa !36
  %1487 = cmpxchg ptr addrspace(1) %1203, i64 %1486, i64 %1477 syncscope("one-as") release monotonic, align 8
  %1488 = extractvalue { i64, i1 } %1487, 1
  br i1 %1488, label %1489, label %1484

1489:                                             ; preds = %1484, %1472, %1469
  %1490 = insertelement <2 x i64> poison, i64 %1470, i64 0
  %1491 = insertelement <2 x i64> %1490, i64 %1471, i64 1
  %1492 = sub i64 %1207, %1212
  %1493 = getelementptr inbounds nuw i8, ptr %1208, i64 %1212
  %1494 = icmp eq i64 %1492, 0
  br i1 %1494, label %1495, label %1206

1495:                                             ; preds = %1489, %1191
  %1496 = phi <2 x i64> [ %1193, %1191 ], [ %1491, %1489 ]
  br label %1497

1497:                                             ; preds = %1497, %1495
  %1498 = phi ptr [ %0, %1495 ], [ %1499, %1497 ]
  %1499 = getelementptr inbounds nuw i8, ptr %1498, i64 1
  %1500 = load i8, ptr %1498, align 1, !tbaa !42
  %1501 = icmp eq i8 %1500, 0
  br i1 %1501, label %1502, label %1497, !llvm.loop !46

1502:                                             ; preds = %1497
  %1503 = extractelement <2 x i64> %1496, i64 0
  %1504 = ptrtoint ptr %1499 to i64
  %1505 = ptrtoint ptr %0 to i64
  %1506 = sub i64 %1504, %1505
  %1507 = shl i64 %1506, 32
  %1508 = ashr exact i64 %1507, 32
  tail call fastcc void @__ockl_fprintf_append_string_n(i64 noundef %1503, ptr noundef %0, i64 noundef %1508, i32 noundef 1) #16
  tail call void @llvm.trap() #15
  unreachable
}

; Function Attrs: mustprogress noinline nounwind uwtable
define weak hidden void @__assertfail() local_unnamed_addr #3 !guid !47 {
  tail call void @llvm.trap() #15
  unreachable
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
define protected amdgpu_kernel void @_Z9dot_plainPKfS0_Pfi(ptr addrspace(1) nofree noundef readonly captures(none) %0, ptr addrspace(1) nofree noundef readonly captures(none) %1, ptr addrspace(1) nofree noundef writeonly captures(none) %2, i32 noundef %3) local_unnamed_addr #4 !guid !48 {
  %5 = tail call noundef range(i32 0, 1024) i32 @llvm.amdgcn.workitem.id.x()
  %6 = tail call noundef i32 @llvm.amdgcn.workgroup.id.x()
  %7 = tail call align 8 dereferenceable(256) ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %8 = getelementptr inbounds nuw i8, ptr addrspace(4) %7, i64 12
  %9 = load i16, ptr addrspace(4) %8, align 4, !range !49, !invariant.load !37, !noundef !37
  %10 = zext nneg i16 %9 to i32
  %11 = mul i32 %6, %10
  %12 = add i32 %11, %5
  %13 = icmp slt i32 %12, %3
  br i1 %13, label %14, label %56

14:                                               ; preds = %4
  %15 = shl nsw i32 %12, 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds [4 x i8], ptr addrspace(1) %0, i64 %16
  %18 = getelementptr inbounds [4 x i8], ptr addrspace(1) %1, i64 %16
  %19 = load <16 x float>, ptr addrspace(1) %17, align 4, !tbaa !50
  %20 = load <16 x float>, ptr addrspace(1) %18, align 4, !tbaa !50
  %21 = fmul contract <16 x float> %19, %20
  %22 = extractelement <16 x float> %21, i64 0
  %23 = fadd contract float %22, 0.000000e+00
  %24 = extractelement <16 x float> %21, i64 1
  %25 = fadd contract float %23, %24
  %26 = extractelement <16 x float> %21, i64 2
  %27 = fadd contract float %25, %26
  %28 = extractelement <16 x float> %21, i64 3
  %29 = fadd contract float %27, %28
  %30 = extractelement <16 x float> %21, i64 4
  %31 = fadd contract float %29, %30
  %32 = extractelement <16 x float> %21, i64 5
  %33 = fadd contract float %31, %32
  %34 = extractelement <16 x float> %21, i64 6
  %35 = fadd contract float %33, %34
  %36 = extractelement <16 x float> %21, i64 7
  %37 = fadd contract float %35, %36
  %38 = extractelement <16 x float> %21, i64 8
  %39 = fadd contract float %37, %38
  %40 = extractelement <16 x float> %21, i64 9
  %41 = fadd contract float %39, %40
  %42 = extractelement <16 x float> %21, i64 10
  %43 = fadd contract float %41, %42
  %44 = extractelement <16 x float> %21, i64 11
  %45 = fadd contract float %43, %44
  %46 = extractelement <16 x float> %21, i64 12
  %47 = fadd contract float %45, %46
  %48 = extractelement <16 x float> %21, i64 13
  %49 = fadd contract float %47, %48
  %50 = extractelement <16 x float> %21, i64 14
  %51 = fadd contract float %49, %50
  %52 = extractelement <16 x float> %21, i64 15
  %53 = fadd contract float %51, %52
  %54 = sext i32 %12 to i64
  %55 = getelementptr inbounds [4 x i8], ptr addrspace(1) %2, i64 %54
  store float %53, ptr addrspace(1) %55, align 4, !tbaa !50
  br label %56

56:                                               ; preds = %4, %14
  ret void
}

; Function Attrs: convergent mustprogress nofree norecurse nounwind uwtable
define protected amdgpu_kernel void @_Z13dot_annotatedPKfS0_Pfi(ptr addrspace(1) nofree noundef readonly captures(none) %0, ptr addrspace(1) nofree noundef readonly captures(none) %1, ptr addrspace(1) nofree noundef writeonly captures(none) %2, i32 noundef %3) local_unnamed_addr #5 !guid !52 {
  %5 = tail call noundef range(i32 0, 1024) i32 @llvm.amdgcn.workitem.id.x()
  %6 = tail call noundef i32 @llvm.amdgcn.workgroup.id.x()
  %7 = tail call align 8 dereferenceable(256) ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %8 = getelementptr inbounds nuw i8, ptr addrspace(4) %7, i64 12
  %9 = load i16, ptr addrspace(4) %8, align 4, !range !49, !invariant.load !37, !noundef !37
  %10 = zext nneg i16 %9 to i32
  %11 = mul i32 %6, %10
  %12 = add i32 %11, %5
  %13 = icmp slt i32 %12, %3
  br i1 %13, label %14, label %32

14:                                               ; preds = %4
  %15 = shl nsw i32 %12, 4
  br label %19

16:                                               ; preds = %19
  %17 = sext i32 %12 to i64
  %18 = getelementptr inbounds [4 x i8], ptr addrspace(1) %2, i64 %17
  store float %29, ptr addrspace(1) %18, align 4, !tbaa !50
  br label %32

19:                                               ; preds = %14, %19
  %20 = phi float [ 0.000000e+00, %14 ], [ %29, %19 ]
  %21 = phi i32 [ 0, %14 ], [ %30, %19 ]
  tail call void @llvm.amdgcn.sched.group.barrier(i32 8, i32 2, i32 0)
  %22 = add nuw nsw i32 %21, %15
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds [4 x i8], ptr addrspace(1) %0, i64 %23
  %25 = load float, ptr addrspace(1) %24, align 4, !tbaa !50
  %26 = getelementptr inbounds [4 x i8], ptr addrspace(1) %1, i64 %23
  %27 = load float, ptr addrspace(1) %26, align 4, !tbaa !50
  tail call void @llvm.amdgcn.sched.group.barrier(i32 17, i32 4, i32 0)
  %28 = fmul contract float %25, %27
  %29 = fadd contract float %20, %28
  %30 = add nuw nsw i32 %21, 1
  %31 = icmp eq i32 %30, 16
  br i1 %31, label %16, label %19, !llvm.loop !53

32:                                               ; preds = %4, %16
  ret void
}

; Function Attrs: convergent mustprogress nocallback nofree nounwind willreturn
declare void @llvm.amdgcn.sched.group.barrier(i32 immarg, i32 immarg, i32 immarg) #6

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef range(i32 0, 1024) i32 @llvm.amdgcn.workitem.id.x() #7

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef i32 @llvm.amdgcn.workgroup.id.x() #7

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare noundef align 4 ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr() #7

; Function Attrs: convergent mustprogress nocallback nocreateundeforpoison nofree nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.readfirstlane.i32(i32) #8

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.amdgcn.s.sleep(i32 immarg) #9

; Function Attrs: convergent mustprogress nocallback nocreateundeforpoison nofree nounwind willreturn memory(none)
declare i64 @llvm.amdgcn.readfirstlane.i64(i64) #8

; Function Attrs: mustprogress nocallback nounwind willreturn
declare void @llvm.amdgcn.s.sendmsg(i32 immarg, i32) #10

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.mbcnt.lo(i32, i32) #11

; Function Attrs: convergent norecurse nounwind uwtable
define internal fastcc void @__ockl_fprintf_append_string_n(i64 noundef %0, ptr nofree noundef readonly captures(address_is_null) %1, i64 noundef range(i64 -2147483648, 2147483648) %2, i32 noundef range(i32 0, 2) %3) unnamed_addr #12 !guid !55 {
  %5 = icmp eq i32 %3, 0
  %6 = or i64 %0, 2
  %7 = select i1 %5, i64 %0, i64 %6
  %8 = icmp eq ptr %1, null
  br i1 %8, label %9, label %127

9:                                                ; preds = %4
  %10 = and i64 %7, -225
  %11 = or disjoint i64 %10, 32
  %12 = tail call dereferenceable(256) ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %13 = getelementptr inbounds nuw i8, ptr addrspace(4) %12, i64 80
  %14 = load i64, ptr addrspace(4) %13, align 8, !tbaa !24
  %15 = inttoptr i64 %14 to ptr addrspace(1)
  %16 = tail call range(i32 0, 33) i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0)
  %17 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %16)
  %18 = icmp eq i32 %16, %17
  br i1 %18, label %19, label %41

19:                                               ; preds = %9
  %20 = getelementptr inbounds nuw i8, ptr addrspace(1) %15, i64 24
  %21 = load atomic i64, ptr addrspace(1) %20 syncscope("one-as") acquire, align 8
  %22 = getelementptr i8, ptr addrspace(1) %15, i64 40
  %23 = load ptr addrspace(1), ptr addrspace(1) %15, align 8, !tbaa !26
  %24 = load i64, ptr addrspace(1) %22, align 8, !tbaa !30
  %25 = and i64 %24, %21
  %26 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %23, i64 %25
  %27 = load atomic i64, ptr addrspace(1) %26 syncscope("one-as") monotonic, align 8
  %28 = cmpxchg ptr addrspace(1) %20, i64 %21, i64 %27 syncscope("one-as") acquire monotonic, align 8
  %29 = extractvalue { i64, i1 } %28, 1
  %30 = extractvalue { i64, i1 } %28, 0
  br i1 %29, label %41, label %31

31:                                               ; preds = %19, %31
  %32 = phi i64 [ %40, %31 ], [ %30, %19 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %33 = load ptr addrspace(1), ptr addrspace(1) %15, align 8, !tbaa !26
  %34 = load i64, ptr addrspace(1) %22, align 8, !tbaa !30
  %35 = and i64 %34, %32
  %36 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %33, i64 %35
  %37 = load atomic i64, ptr addrspace(1) %36 syncscope("one-as") monotonic, align 8
  %38 = cmpxchg ptr addrspace(1) %20, i64 %32, i64 %37 syncscope("one-as") acquire monotonic, align 8
  %39 = extractvalue { i64, i1 } %38, 1
  %40 = extractvalue { i64, i1 } %38, 0
  br i1 %39, label %41, label %31

41:                                               ; preds = %31, %19, %9
  %42 = phi i64 [ 0, %9 ], [ %30, %19 ], [ %40, %31 ]
  %43 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %42)
  %44 = load ptr addrspace(1), ptr addrspace(1) %15, align 8, !tbaa !26
  %45 = getelementptr i8, ptr addrspace(1) %15, i64 40
  %46 = load i64, ptr addrspace(1) %45, align 8, !tbaa !30
  %47 = and i64 %46, %43
  %48 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %44, i64 %47
  %49 = getelementptr i8, ptr addrspace(1) %15, i64 8
  %50 = load ptr addrspace(1), ptr addrspace(1) %49, align 8, !tbaa !31
  %51 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %50, i64 %47
  %52 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %18, label %53, label %58

53:                                               ; preds = %41
  %54 = getelementptr inbounds nuw i8, ptr addrspace(1) %48, i64 20
  %55 = getelementptr inbounds nuw i8, ptr addrspace(1) %48, i64 8
  %56 = getelementptr inbounds nuw i8, ptr addrspace(1) %48, i64 16
  %57 = zext i32 %52 to i64
  store i32 2, ptr addrspace(1) %56, align 8, !tbaa !32
  store i64 %57, ptr addrspace(1) %55, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %54, align 4, !tbaa !35
  br label %58

58:                                               ; preds = %53, %41
  %59 = zext nneg i32 %16 to i64
  %60 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %51, i64 %59
  store i64 %11, ptr addrspace(1) %60, align 8, !tbaa !24
  %61 = getelementptr inbounds nuw i8, ptr addrspace(1) %60, i64 8
  store i64 0, ptr addrspace(1) %61, align 8, !tbaa !24
  %62 = getelementptr inbounds nuw i8, ptr addrspace(1) %60, i64 16
  store i64 0, ptr addrspace(1) %62, align 8, !tbaa !24
  %63 = getelementptr inbounds nuw i8, ptr addrspace(1) %60, i64 24
  store i64 0, ptr addrspace(1) %63, align 8, !tbaa !24
  %64 = getelementptr inbounds nuw i8, ptr addrspace(1) %60, i64 32
  store i64 0, ptr addrspace(1) %64, align 8, !tbaa !24
  %65 = getelementptr inbounds nuw i8, ptr addrspace(1) %60, i64 40
  store i64 0, ptr addrspace(1) %65, align 8, !tbaa !24
  %66 = getelementptr inbounds nuw i8, ptr addrspace(1) %60, i64 48
  store i64 0, ptr addrspace(1) %66, align 8, !tbaa !24
  %67 = getelementptr inbounds nuw i8, ptr addrspace(1) %60, i64 56
  store i64 0, ptr addrspace(1) %67, align 8, !tbaa !24
  br i1 %18, label %68, label %97

68:                                               ; preds = %58
  %69 = getelementptr inbounds nuw i8, ptr addrspace(1) %15, i64 32
  %70 = load atomic i64, ptr addrspace(1) %69 syncscope("one-as") monotonic, align 8
  %71 = load i64, ptr addrspace(1) %45, align 8, !tbaa !30
  %72 = and i64 %71, %43
  %73 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %44, i64 %72
  store i64 %70, ptr addrspace(1) %73, align 8, !tbaa !36
  %74 = cmpxchg ptr addrspace(1) %69, i64 %70, i64 %43 syncscope("one-as") release monotonic, align 8
  %75 = extractvalue { i64, i1 } %74, 1
  br i1 %75, label %81, label %76

76:                                               ; preds = %68, %76
  %77 = phi { i64, i1 } [ %79, %76 ], [ %74, %68 ]
  %78 = extractvalue { i64, i1 } %77, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %78, ptr addrspace(1) %73, align 8, !tbaa !36
  %79 = cmpxchg ptr addrspace(1) %69, i64 %78, i64 %43 syncscope("one-as") release monotonic, align 8
  %80 = extractvalue { i64, i1 } %79, 1
  br i1 %80, label %81, label %76

81:                                               ; preds = %76, %68
  %82 = getelementptr inbounds nuw i8, ptr addrspace(1) %15, i64 16
  %83 = load i64, ptr addrspace(1) %82, align 8
  %84 = inttoptr i64 %83 to ptr addrspace(1)
  %85 = getelementptr inbounds nuw i8, ptr addrspace(1) %84, i64 8
  %86 = atomicrmw add ptr addrspace(1) %85, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %87 = getelementptr inbounds nuw i8, ptr addrspace(1) %84, i64 16
  %88 = load i64, ptr addrspace(1) %87, align 16, !tbaa !38
  %89 = icmp eq i64 %88, 0
  br i1 %89, label %97, label %90

90:                                               ; preds = %81
  %91 = inttoptr i64 %88 to ptr addrspace(1)
  %92 = getelementptr inbounds nuw i8, ptr addrspace(1) %84, i64 24
  %93 = load i32, ptr addrspace(1) %92, align 8, !tbaa !40
  %94 = zext i32 %93 to i64
  store atomic i64 %94, ptr addrspace(1) %91 syncscope("one-as") release, align 8
  %95 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %93)
  %96 = and i32 %95, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %96)
  br label %97

97:                                               ; preds = %90, %81, %58
  %98 = getelementptr inbounds nuw i8, ptr addrspace(1) %48, i64 20
  br label %99

99:                                               ; preds = %107, %97
  br i1 %18, label %100, label %103

100:                                              ; preds = %99
  %101 = load atomic i32, ptr addrspace(1) %98 syncscope("one-as") acquire, align 4
  %102 = and i32 %101, 1
  br label %103

103:                                              ; preds = %100, %99
  %104 = phi i32 [ %102, %100 ], [ 1, %99 ]
  %105 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %104)
  %106 = icmp eq i32 %105, 0
  br i1 %106, label %108, label %107

107:                                              ; preds = %103
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %99

108:                                              ; preds = %103
  br i1 %18, label %109, label %431

109:                                              ; preds = %108
  %110 = load i64, ptr addrspace(1) %45, align 8, !tbaa !30
  %111 = add i64 %110, 1
  %112 = add i64 %111, %43
  %113 = icmp eq i64 %112, 0
  %114 = select i1 %113, i64 %111, i64 %112
  %115 = getelementptr inbounds nuw i8, ptr addrspace(1) %15, i64 24
  %116 = load atomic i64, ptr addrspace(1) %115 syncscope("one-as") monotonic, align 8
  %117 = load ptr addrspace(1), ptr addrspace(1) %15, align 8, !tbaa !26
  %118 = and i64 %114, %110
  %119 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %117, i64 %118
  store i64 %116, ptr addrspace(1) %119, align 8, !tbaa !36
  %120 = cmpxchg ptr addrspace(1) %115, i64 %116, i64 %114 syncscope("one-as") release monotonic, align 8
  %121 = extractvalue { i64, i1 } %120, 1
  br i1 %121, label %431, label %122

122:                                              ; preds = %109, %122
  %123 = phi { i64, i1 } [ %125, %122 ], [ %120, %109 ]
  %124 = extractvalue { i64, i1 } %123, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %124, ptr addrspace(1) %119, align 8, !tbaa !36
  %125 = cmpxchg ptr addrspace(1) %115, i64 %124, i64 %114 syncscope("one-as") release monotonic, align 8
  %126 = extractvalue { i64, i1 } %125, 1
  br i1 %126, label %431, label %122

127:                                              ; preds = %4
  %128 = and i64 %7, 2
  %129 = and i64 %7, -3
  %130 = insertelement <2 x i64> <i64 poison, i64 0>, i64 %129, i64 0
  %131 = tail call dereferenceable(256) ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %132 = getelementptr inbounds nuw i8, ptr addrspace(4) %131, i64 80
  %133 = load i64, ptr addrspace(4) %132, align 8, !tbaa !24
  %134 = inttoptr i64 %133 to ptr addrspace(1)
  %135 = tail call range(i32 0, 33) i32 @llvm.amdgcn.mbcnt.lo(i32 -1, i32 0)
  %136 = getelementptr i8, ptr addrspace(1) %134, i64 40
  %137 = getelementptr i8, ptr addrspace(1) %134, i64 8
  %138 = zext nneg i32 %135 to i64
  %139 = getelementptr inbounds nuw i8, ptr addrspace(1) %134, i64 24
  %140 = getelementptr inbounds nuw i8, ptr addrspace(1) %134, i64 32
  %141 = getelementptr inbounds nuw i8, ptr addrspace(1) %134, i64 16
  br label %142

142:                                              ; preds = %425, %127
  %143 = phi i64 [ %2, %127 ], [ %428, %425 ]
  %144 = phi ptr [ %1, %127 ], [ %429, %425 ]
  %145 = phi <2 x i64> [ %130, %127 ], [ %427, %425 ]
  %146 = icmp ugt i64 %143, 56
  %147 = extractelement <2 x i64> %145, i64 0
  %148 = tail call i64 @llvm.umin.i64(i64 %143, i64 56)
  %149 = trunc nuw nsw i64 %148 to i32
  %150 = select i1 %146, i64 0, i64 %128
  %151 = icmp ugt i64 %143, 7
  br i1 %151, label %154, label %152

152:                                              ; preds = %142
  %153 = icmp eq i64 %143, 0
  br i1 %153, label %171, label %158

154:                                              ; preds = %142
  %155 = load i64, ptr %144, align 1
  %156 = add nsw i32 %149, -8
  %157 = getelementptr inbounds nuw i8, ptr %144, i64 8
  br label %171

158:                                              ; preds = %152, %158
  %159 = phi i32 [ %169, %158 ], [ 0, %152 ]
  %160 = phi i64 [ %168, %158 ], [ 0, %152 ]
  %161 = zext nneg i32 %159 to i64
  %162 = getelementptr inbounds nuw i8, ptr %144, i64 %161
  %163 = load i8, ptr %162, align 1, !tbaa !41
  %164 = zext i8 %163 to i64
  %165 = shl nuw nsw i32 %159, 3
  %166 = zext nneg i32 %165 to i64
  %167 = shl nuw i64 %164, %166
  %168 = or i64 %167, %160
  %169 = add nuw nsw i32 %159, 1
  %170 = icmp eq i32 %169, %149
  br i1 %170, label %171, label %158

171:                                              ; preds = %158, %154, %152
  %172 = phi ptr [ %157, %154 ], [ %144, %152 ], [ %144, %158 ]
  %173 = phi i32 [ %156, %154 ], [ 0, %152 ], [ 0, %158 ]
  %174 = phi i64 [ %155, %154 ], [ 0, %152 ], [ %168, %158 ]
  %175 = icmp ugt i32 %173, 7
  br i1 %175, label %178, label %176

176:                                              ; preds = %171
  %177 = icmp eq i32 %173, 0
  br i1 %177, label %195, label %182

178:                                              ; preds = %171
  %179 = load i64, ptr %172, align 1
  %180 = add nsw i32 %173, -8
  %181 = getelementptr inbounds nuw i8, ptr %172, i64 8
  br label %195

182:                                              ; preds = %176, %182
  %183 = phi i32 [ %193, %182 ], [ 0, %176 ]
  %184 = phi i64 [ %192, %182 ], [ 0, %176 ]
  %185 = zext nneg i32 %183 to i64
  %186 = getelementptr inbounds nuw i8, ptr %172, i64 %185
  %187 = load i8, ptr %186, align 1, !tbaa !41
  %188 = zext i8 %187 to i64
  %189 = shl nuw nsw i32 %183, 3
  %190 = zext nneg i32 %189 to i64
  %191 = shl nuw i64 %188, %190
  %192 = or i64 %191, %184
  %193 = add nuw nsw i32 %183, 1
  %194 = icmp eq i32 %193, %173
  br i1 %194, label %195, label %182

195:                                              ; preds = %182, %178, %176
  %196 = phi ptr [ %181, %178 ], [ %172, %176 ], [ %172, %182 ]
  %197 = phi i32 [ %180, %178 ], [ 0, %176 ], [ 0, %182 ]
  %198 = phi i64 [ %179, %178 ], [ 0, %176 ], [ %192, %182 ]
  %199 = icmp ugt i32 %197, 7
  br i1 %199, label %202, label %200

200:                                              ; preds = %195
  %201 = icmp eq i32 %197, 0
  br i1 %201, label %219, label %206

202:                                              ; preds = %195
  %203 = load i64, ptr %196, align 1
  %204 = add nsw i32 %197, -8
  %205 = getelementptr inbounds nuw i8, ptr %196, i64 8
  br label %219

206:                                              ; preds = %200, %206
  %207 = phi i32 [ %217, %206 ], [ 0, %200 ]
  %208 = phi i64 [ %216, %206 ], [ 0, %200 ]
  %209 = zext nneg i32 %207 to i64
  %210 = getelementptr inbounds nuw i8, ptr %196, i64 %209
  %211 = load i8, ptr %210, align 1, !tbaa !41
  %212 = zext i8 %211 to i64
  %213 = shl nuw nsw i32 %207, 3
  %214 = zext nneg i32 %213 to i64
  %215 = shl nuw i64 %212, %214
  %216 = or i64 %215, %208
  %217 = add nuw nsw i32 %207, 1
  %218 = icmp eq i32 %217, %197
  br i1 %218, label %219, label %206

219:                                              ; preds = %206, %202, %200
  %220 = phi ptr [ %205, %202 ], [ %196, %200 ], [ %196, %206 ]
  %221 = phi i32 [ %204, %202 ], [ 0, %200 ], [ 0, %206 ]
  %222 = phi i64 [ %203, %202 ], [ 0, %200 ], [ %216, %206 ]
  %223 = icmp ugt i32 %221, 7
  br i1 %223, label %226, label %224

224:                                              ; preds = %219
  %225 = icmp eq i32 %221, 0
  br i1 %225, label %243, label %230

226:                                              ; preds = %219
  %227 = load i64, ptr %220, align 1
  %228 = add nsw i32 %221, -8
  %229 = getelementptr inbounds nuw i8, ptr %220, i64 8
  br label %243

230:                                              ; preds = %224, %230
  %231 = phi i32 [ %241, %230 ], [ 0, %224 ]
  %232 = phi i64 [ %240, %230 ], [ 0, %224 ]
  %233 = zext nneg i32 %231 to i64
  %234 = getelementptr inbounds nuw i8, ptr %220, i64 %233
  %235 = load i8, ptr %234, align 1, !tbaa !41
  %236 = zext i8 %235 to i64
  %237 = shl nuw nsw i32 %231, 3
  %238 = zext nneg i32 %237 to i64
  %239 = shl nuw i64 %236, %238
  %240 = or i64 %239, %232
  %241 = add nuw nsw i32 %231, 1
  %242 = icmp eq i32 %241, %221
  br i1 %242, label %243, label %230

243:                                              ; preds = %230, %226, %224
  %244 = phi ptr [ %229, %226 ], [ %220, %224 ], [ %220, %230 ]
  %245 = phi i32 [ %228, %226 ], [ 0, %224 ], [ 0, %230 ]
  %246 = phi i64 [ %227, %226 ], [ 0, %224 ], [ %240, %230 ]
  %247 = icmp ugt i32 %245, 7
  br i1 %247, label %250, label %248

248:                                              ; preds = %243
  %249 = icmp eq i32 %245, 0
  br i1 %249, label %267, label %254

250:                                              ; preds = %243
  %251 = load i64, ptr %244, align 1
  %252 = add nsw i32 %245, -8
  %253 = getelementptr inbounds nuw i8, ptr %244, i64 8
  br label %267

254:                                              ; preds = %248, %254
  %255 = phi i32 [ %265, %254 ], [ 0, %248 ]
  %256 = phi i64 [ %264, %254 ], [ 0, %248 ]
  %257 = zext nneg i32 %255 to i64
  %258 = getelementptr inbounds nuw i8, ptr %244, i64 %257
  %259 = load i8, ptr %258, align 1, !tbaa !41
  %260 = zext i8 %259 to i64
  %261 = shl nuw nsw i32 %255, 3
  %262 = zext nneg i32 %261 to i64
  %263 = shl nuw i64 %260, %262
  %264 = or i64 %263, %256
  %265 = add nuw nsw i32 %255, 1
  %266 = icmp eq i32 %265, %245
  br i1 %266, label %267, label %254

267:                                              ; preds = %254, %250, %248
  %268 = phi ptr [ %253, %250 ], [ %244, %248 ], [ %244, %254 ]
  %269 = phi i32 [ %252, %250 ], [ 0, %248 ], [ 0, %254 ]
  %270 = phi i64 [ %251, %250 ], [ 0, %248 ], [ %264, %254 ]
  %271 = icmp ugt i32 %269, 7
  br i1 %271, label %274, label %272

272:                                              ; preds = %267
  %273 = icmp eq i32 %269, 0
  br i1 %273, label %291, label %278

274:                                              ; preds = %267
  %275 = load i64, ptr %268, align 1
  %276 = add nsw i32 %269, -8
  %277 = getelementptr inbounds nuw i8, ptr %268, i64 8
  br label %291

278:                                              ; preds = %272, %278
  %279 = phi i32 [ %289, %278 ], [ 0, %272 ]
  %280 = phi i64 [ %288, %278 ], [ 0, %272 ]
  %281 = zext nneg i32 %279 to i64
  %282 = getelementptr inbounds nuw i8, ptr %268, i64 %281
  %283 = load i8, ptr %282, align 1, !tbaa !41
  %284 = zext i8 %283 to i64
  %285 = shl nuw nsw i32 %279, 3
  %286 = zext nneg i32 %285 to i64
  %287 = shl nuw i64 %284, %286
  %288 = or i64 %287, %280
  %289 = add nuw nsw i32 %279, 1
  %290 = icmp eq i32 %289, %269
  br i1 %290, label %291, label %278

291:                                              ; preds = %278, %274, %272
  %292 = phi ptr [ %277, %274 ], [ %268, %272 ], [ %268, %278 ]
  %293 = phi i32 [ %276, %274 ], [ 0, %272 ], [ 0, %278 ]
  %294 = phi i64 [ %275, %274 ], [ 0, %272 ], [ %288, %278 ]
  %295 = icmp ugt i32 %293, 7
  br i1 %295, label %298, label %296

296:                                              ; preds = %291
  %297 = icmp eq i32 %293, 0
  br i1 %297, label %313, label %300

298:                                              ; preds = %291
  %299 = load i64, ptr %292, align 1
  br label %313

300:                                              ; preds = %296, %300
  %301 = phi i32 [ %311, %300 ], [ 0, %296 ]
  %302 = phi i64 [ %310, %300 ], [ 0, %296 ]
  %303 = zext nneg i32 %301 to i64
  %304 = getelementptr inbounds nuw i8, ptr %292, i64 %303
  %305 = load i8, ptr %304, align 1, !tbaa !41
  %306 = zext i8 %305 to i64
  %307 = shl nuw nsw i32 %301, 3
  %308 = zext nneg i32 %307 to i64
  %309 = shl nuw i64 %306, %308
  %310 = or i64 %309, %302
  %311 = add nuw nsw i32 %301, 1
  %312 = icmp eq i32 %311, %293
  br i1 %312, label %313, label %300

313:                                              ; preds = %300, %298, %296
  %314 = phi i64 [ %299, %298 ], [ 0, %296 ], [ %310, %300 ]
  %315 = shl nuw nsw i64 %148, 2
  %316 = add nuw nsw i64 %315, 28
  %317 = and i64 %316, 480
  %318 = and i64 %147, -225
  %319 = or i64 %318, %150
  %320 = or i64 %319, %317
  %321 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %135)
  %322 = icmp eq i32 %135, %321
  br i1 %322, label %323, label %343

323:                                              ; preds = %313
  %324 = load atomic i64, ptr addrspace(1) %139 syncscope("one-as") acquire, align 8
  %325 = load ptr addrspace(1), ptr addrspace(1) %134, align 8, !tbaa !26
  %326 = load i64, ptr addrspace(1) %136, align 8, !tbaa !30
  %327 = and i64 %326, %324
  %328 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %325, i64 %327
  %329 = load atomic i64, ptr addrspace(1) %328 syncscope("one-as") monotonic, align 8
  %330 = cmpxchg ptr addrspace(1) %139, i64 %324, i64 %329 syncscope("one-as") acquire monotonic, align 8
  %331 = extractvalue { i64, i1 } %330, 1
  %332 = extractvalue { i64, i1 } %330, 0
  br i1 %331, label %343, label %333

333:                                              ; preds = %323, %333
  %334 = phi i64 [ %342, %333 ], [ %332, %323 ]
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  %335 = load ptr addrspace(1), ptr addrspace(1) %134, align 8, !tbaa !26
  %336 = load i64, ptr addrspace(1) %136, align 8, !tbaa !30
  %337 = and i64 %336, %334
  %338 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %335, i64 %337
  %339 = load atomic i64, ptr addrspace(1) %338 syncscope("one-as") monotonic, align 8
  %340 = cmpxchg ptr addrspace(1) %139, i64 %334, i64 %339 syncscope("one-as") acquire monotonic, align 8
  %341 = extractvalue { i64, i1 } %340, 1
  %342 = extractvalue { i64, i1 } %340, 0
  br i1 %341, label %343, label %333

343:                                              ; preds = %333, %323, %313
  %344 = phi i64 [ 0, %313 ], [ %332, %323 ], [ %342, %333 ]
  %345 = tail call i64 @llvm.amdgcn.readfirstlane.i64(i64 %344)
  %346 = load ptr addrspace(1), ptr addrspace(1) %134, align 8, !tbaa !26
  %347 = load i64, ptr addrspace(1) %136, align 8, !tbaa !30
  %348 = and i64 %347, %345
  %349 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %346, i64 %348
  %350 = load ptr addrspace(1), ptr addrspace(1) %137, align 8, !tbaa !31
  %351 = getelementptr inbounds nuw [4096 x i8], ptr addrspace(1) %350, i64 %348
  %352 = tail call i32 @llvm.amdgcn.ballot.i32(i1 true)
  br i1 %322, label %353, label %358

353:                                              ; preds = %343
  %354 = getelementptr inbounds nuw i8, ptr addrspace(1) %349, i64 20
  %355 = getelementptr inbounds nuw i8, ptr addrspace(1) %349, i64 8
  %356 = getelementptr inbounds nuw i8, ptr addrspace(1) %349, i64 16
  %357 = zext i32 %352 to i64
  store i32 2, ptr addrspace(1) %356, align 8, !tbaa !32
  store i64 %357, ptr addrspace(1) %355, align 8, !tbaa !34
  store i32 1, ptr addrspace(1) %354, align 4, !tbaa !35
  br label %358

358:                                              ; preds = %353, %343
  %359 = getelementptr inbounds nuw [64 x i8], ptr addrspace(1) %351, i64 %138
  store i64 %320, ptr addrspace(1) %359, align 8, !tbaa !24
  %360 = getelementptr inbounds nuw i8, ptr addrspace(1) %359, i64 8
  store i64 %174, ptr addrspace(1) %360, align 8, !tbaa !24
  %361 = getelementptr inbounds nuw i8, ptr addrspace(1) %359, i64 16
  store i64 %198, ptr addrspace(1) %361, align 8, !tbaa !24
  %362 = getelementptr inbounds nuw i8, ptr addrspace(1) %359, i64 24
  store i64 %222, ptr addrspace(1) %362, align 8, !tbaa !24
  %363 = getelementptr inbounds nuw i8, ptr addrspace(1) %359, i64 32
  store i64 %246, ptr addrspace(1) %363, align 8, !tbaa !24
  %364 = getelementptr inbounds nuw i8, ptr addrspace(1) %359, i64 40
  store i64 %270, ptr addrspace(1) %364, align 8, !tbaa !24
  %365 = getelementptr inbounds nuw i8, ptr addrspace(1) %359, i64 48
  store i64 %294, ptr addrspace(1) %365, align 8, !tbaa !24
  %366 = getelementptr inbounds nuw i8, ptr addrspace(1) %359, i64 56
  store i64 %314, ptr addrspace(1) %366, align 8, !tbaa !24
  br i1 %322, label %367, label %394

367:                                              ; preds = %358
  %368 = load atomic i64, ptr addrspace(1) %140 syncscope("one-as") monotonic, align 8
  %369 = load i64, ptr addrspace(1) %136, align 8, !tbaa !30
  %370 = and i64 %369, %345
  %371 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %346, i64 %370
  store i64 %368, ptr addrspace(1) %371, align 8, !tbaa !36
  %372 = cmpxchg ptr addrspace(1) %140, i64 %368, i64 %345 syncscope("one-as") release monotonic, align 8
  %373 = extractvalue { i64, i1 } %372, 1
  br i1 %373, label %379, label %374

374:                                              ; preds = %367, %374
  %375 = phi { i64, i1 } [ %377, %374 ], [ %372, %367 ]
  %376 = extractvalue { i64, i1 } %375, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %376, ptr addrspace(1) %371, align 8, !tbaa !36
  %377 = cmpxchg ptr addrspace(1) %140, i64 %376, i64 %345 syncscope("one-as") release monotonic, align 8
  %378 = extractvalue { i64, i1 } %377, 1
  br i1 %378, label %379, label %374

379:                                              ; preds = %374, %367
  %380 = load i64, ptr addrspace(1) %141, align 8
  %381 = inttoptr i64 %380 to ptr addrspace(1)
  %382 = getelementptr inbounds nuw i8, ptr addrspace(1) %381, i64 8
  %383 = atomicrmw add ptr addrspace(1) %382, i64 1 syncscope("one-as") release, align 8, !amdgpu.no.fine.grained.memory !37, !amdgpu.no.remote.memory !37
  %384 = getelementptr inbounds nuw i8, ptr addrspace(1) %381, i64 16
  %385 = load i64, ptr addrspace(1) %384, align 16, !tbaa !38
  %386 = icmp eq i64 %385, 0
  br i1 %386, label %394, label %387

387:                                              ; preds = %379
  %388 = inttoptr i64 %385 to ptr addrspace(1)
  %389 = getelementptr inbounds nuw i8, ptr addrspace(1) %381, i64 24
  %390 = load i32, ptr addrspace(1) %389, align 8, !tbaa !40
  %391 = zext i32 %390 to i64
  store atomic i64 %391, ptr addrspace(1) %388 syncscope("one-as") release, align 8
  %392 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %390)
  %393 = and i32 %392, 8388607
  tail call void @llvm.amdgcn.s.sendmsg(i32 1, i32 %393)
  br label %394

394:                                              ; preds = %387, %379, %358
  %395 = getelementptr inbounds nuw i8, ptr addrspace(1) %349, i64 20
  br label %396

396:                                              ; preds = %404, %394
  br i1 %322, label %397, label %400

397:                                              ; preds = %396
  %398 = load atomic i32, ptr addrspace(1) %395 syncscope("one-as") acquire, align 4
  %399 = and i32 %398, 1
  br label %400

400:                                              ; preds = %397, %396
  %401 = phi i32 [ %399, %397 ], [ 1, %396 ]
  %402 = tail call i32 @llvm.amdgcn.readfirstlane.i32(i32 %401)
  %403 = icmp eq i32 %402, 0
  br i1 %403, label %405, label %404

404:                                              ; preds = %400
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  br label %396

405:                                              ; preds = %400
  %406 = load i64, ptr addrspace(1) %359, align 8, !tbaa !24
  %407 = load i64, ptr addrspace(1) %360, align 8, !tbaa !24
  br i1 %322, label %408, label %425

408:                                              ; preds = %405
  %409 = load i64, ptr addrspace(1) %136, align 8, !tbaa !30
  %410 = add i64 %409, 1
  %411 = add i64 %410, %345
  %412 = icmp eq i64 %411, 0
  %413 = select i1 %412, i64 %410, i64 %411
  %414 = load atomic i64, ptr addrspace(1) %139 syncscope("one-as") monotonic, align 8
  %415 = load ptr addrspace(1), ptr addrspace(1) %134, align 8, !tbaa !26
  %416 = and i64 %413, %409
  %417 = getelementptr inbounds nuw [24 x i8], ptr addrspace(1) %415, i64 %416
  store i64 %414, ptr addrspace(1) %417, align 8, !tbaa !36
  %418 = cmpxchg ptr addrspace(1) %139, i64 %414, i64 %413 syncscope("one-as") release monotonic, align 8
  %419 = extractvalue { i64, i1 } %418, 1
  br i1 %419, label %425, label %420

420:                                              ; preds = %408, %420
  %421 = phi { i64, i1 } [ %423, %420 ], [ %418, %408 ]
  %422 = extractvalue { i64, i1 } %421, 0
  tail call void @llvm.amdgcn.s.sleep(i32 1)
  store i64 %422, ptr addrspace(1) %417, align 8, !tbaa !36
  %423 = cmpxchg ptr addrspace(1) %139, i64 %422, i64 %413 syncscope("one-as") release monotonic, align 8
  %424 = extractvalue { i64, i1 } %423, 1
  br i1 %424, label %425, label %420

425:                                              ; preds = %420, %405, %408
  %426 = insertelement <2 x i64> poison, i64 %406, i64 0
  %427 = insertelement <2 x i64> %426, i64 %407, i64 1
  %428 = sub i64 %143, %148
  %429 = getelementptr inbounds nuw i8, ptr %144, i64 %148
  %430 = icmp eq i64 %428, 0
  br i1 %430, label %431, label %142

431:                                              ; preds = %425, %122, %109, %108
  ret void
}

; Function Attrs: mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #13

; Function Attrs: convergent nocallback nocreateundeforpoison nofree nounwind willreturn memory(none)
declare i32 @llvm.amdgcn.ballot.i32(i1) #14

attributes #0 = { mustprogress noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "uniform-work-group-size" }
attributes #1 = { cold noreturn nounwind memory(inaccessiblemem: write) }
attributes #2 = { convergent noinline nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "uniform-work-group-size" }
attributes #3 = { mustprogress noinline nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "uniform-work-group-size" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "amdgpu-flat-work-group-size"="1,1024" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "uniform-work-group-size" }
attributes #5 = { convergent mustprogress nofree norecurse nounwind uwtable "amdgpu-flat-work-group-size"="1,1024" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "uniform-work-group-size" }
attributes #6 = { convergent mustprogress nocallback nofree nounwind willreturn }
attributes #7 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { convergent mustprogress nocallback nocreateundeforpoison nofree nounwind willreturn memory(none) }
attributes #9 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #10 = { mustprogress nocallback nounwind willreturn }
attributes #11 = { mustprogress nocallback nocreateundeforpoison nofree nosync nounwind willreturn memory(none) }
attributes #12 = { convergent norecurse nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="gfx1030" "target-features"="+16-bit-insts,+atomic-fmin-fmax-global-f32,+atomic-fmin-fmax-global-f64,+bvh-ray-tracing-insts,+ci-insts,+cube-insts,+cvt-pknorm-vop2-insts,+dl-insts,+dot1-insts,+dot10-insts,+dot2-insts,+dot5-insts,+dot6-insts,+dot7-insts,+dpp,+extended-image-insts,+flat-global-insts,+gfx10-3-insts,+gfx10-insts,+gfx8-insts,+gfx9-insts,+gws,+image-insts,+lerp-inst,+mqsad-insts,+mqsad-pk-insts,+msad-insts,+qsad-insts,+s-memrealtime,+s-memtime-inst,+sad-insts,+vmem-to-lds-load-insts,+wavefrontsize32" }
attributes #13 = { mustprogress nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #14 = { convergent nocallback nocreateundeforpoison nofree nounwind willreturn memory(none) }
attributes #15 = { noreturn nounwind }
attributes #16 = { convergent nounwind "uniform-work-group-size" }

!llvm.module.flags = !{!3, !4, !5, !6, !7, !8}
!llvm.ident = !{!9}
!llvm.errno.tbaa = !{!10, !15}
!opencl.ocl.version = !{!20}

!0 = !{i64 3388937655762648909}
!1 = !{i64 -8345607669594902141}
!2 = !{i64 -8836116302723813610}
!3 = !{i32 1, !"amdhsa_code_object_version", i32 600}
!4 = !{i32 1, !"amdgpu_printf_kind", !"hostcall"}
!5 = !{i32 8, !"PIC Level", i32 2}
!6 = !{i32 7, !"uwtable", i32 2}
!7 = !{i32 1, !"ThinLTO", i32 0}
!8 = !{i32 1, !"EnableSplitLTOUnit", i32 1}
!9 = !{!"AMD clang version 24.0.0git (https://github.com/ROCm/llvm-project.git d6f6cb691863e9258034ab48c1dfce21689d5606)"}
!10 = !{!11, !12, i64 0}
!11 = !{!"__libc_errno", !12, i64 0}
!12 = !{!"int", !13, i64 0}
!13 = !{!"omnipotent char", !14, i64 0}
!14 = !{!"Simple C++ TBAA"}
!15 = !{!16, !17, i64 0}
!16 = !{!"__libc_errno", !17, i64 0}
!17 = !{!"int", !18, i64 0}
!18 = !{!"omnipotent char", !19, i64 0}
!19 = !{!"Simple C/C++ TBAA"}
!20 = !{i32 2, i32 0}
!21 = !{i64 -3001543976016564777}
!22 = !{i64 345206151970188238}
!23 = !{i64 -7271410508389881159}
!24 = !{!25, !25, i64 0}
!25 = !{!"long", !18, i64 0}
!26 = !{!27, !28, i64 0}
!27 = !{!"", !28, i64 0, !28, i64 8, !29, i64 16, !25, i64 24, !25, i64 32, !25, i64 40}
!28 = !{!"any pointer", !18, i64 0}
!29 = !{!"hsa_signal_s", !25, i64 0}
!30 = !{!27, !25, i64 40}
!31 = !{!27, !28, i64 8}
!32 = !{!33, !17, i64 16}
!33 = !{!"", !25, i64 0, !25, i64 8, !17, i64 16, !17, i64 20}
!34 = !{!33, !25, i64 8}
!35 = !{!33, !17, i64 20}
!36 = !{!33, !25, i64 0}
!37 = !{}
!38 = !{!39, !25, i64 16}
!39 = !{!"amd_signal_s", !25, i64 0, !18, i64 8, !25, i64 16, !17, i64 24, !17, i64 28, !25, i64 32, !25, i64 40, !18, i64 48, !18, i64 56}
!40 = !{!39, !17, i64 24}
!41 = !{!18, !18, i64 0}
!42 = !{!13, !13, i64 0}
!43 = distinct !{!43, !44}
!44 = !{!"llvm.loop.mustprogress"}
!45 = distinct !{!45, !44}
!46 = distinct !{!46, !44}
!47 = !{i64 -3422857216240862605}
!48 = !{i64 -8680235329138498961}
!49 = !{i16 1, i16 1025}
!50 = !{!51, !51, i64 0}
!51 = !{!"float", !13, i64 0}
!52 = !{i64 -4254857584847074693}
!53 = distinct !{!53, !44, !54}
!54 = !{!"llvm.loop.unroll.disable"}
!55 = !{i64 -3966167914141935826}

^0 = module: (path: "[Regular LTO]", hash: (0, 0, 0, 0, 0))
^1 = gv: (name: "__cxa_deleted_virtual", summaries: (function: (module: ^0, flags: (linkage: weak, visibility: default, notEligibleToImport: 1, live: 0, dsoLocal: 0, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), insts: 2, funcFlags: (readNone: 0, readOnly: 0, noRecurse: 0, returnDoesNotAlias: 0, noInline: 0, alwaysInline: 0, noUnwind: 1, mayThrow: 0, hasUnknownCall: 0, mustBeUnreachable: 1)))) ; guid = 345206151970188238
^2 = gv: (name: "_ZZ13__assert_failE3fmt", summaries: (variable: (module: ^0, flags: (linkage: internal, visibility: default, notEligibleToImport: 1, live: 0, dsoLocal: 1, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), varFlags: (readonly: 1, writeonly: 0, constant: 1)))) ; guid = 3388937655762648909
^3 = gv: (name: "llvm.compiler.used", summaries: (variable: (module: ^0, flags: (linkage: appending, visibility: default, notEligibleToImport: 1, live: 1, dsoLocal: 0, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), varFlags: (readonly: 0, writeonly: 0, constant: 0), refs: (^5)))) ; guid = 9610627770985738006
^4 = gv: (name: "_Z9dot_plainPKfS0_Pfi", summaries: (function: (module: ^0, flags: (linkage: external, visibility: protected, notEligibleToImport: 1, live: 0, dsoLocal: 1, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), insts: 54, funcFlags: (readNone: 0, readOnly: 0, noRecurse: 1, returnDoesNotAlias: 0, noInline: 0, alwaysInline: 0, noUnwind: 1, mayThrow: 0, hasUnknownCall: 0, mustBeUnreachable: 0)))) ; guid = 9766508744571052655
^5 = gv: (name: "__hip_cuid_39c5098bf0f908ee", summaries: (variable: (module: ^0, flags: (linkage: external, visibility: default, notEligibleToImport: 1, live: 0, dsoLocal: 0, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), varFlags: (readonly: 1, writeonly: 1, constant: 0)))) ; guid = 10101136404114649475
^6 = gv: (name: "__assert_fail", summaries: (function: (module: ^0, flags: (linkage: weak, visibility: hidden, notEligibleToImport: 1, live: 0, dsoLocal: 1, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), insts: 1675, funcFlags: (readNone: 0, readOnly: 0, noRecurse: 0, returnDoesNotAlias: 0, noInline: 1, alwaysInline: 0, noUnwind: 1, mayThrow: 0, hasUnknownCall: 0, mustBeUnreachable: 0), calls: ((callee: ^8, tail: 1)), refs: (^2)))) ; guid = 11175333565319670457
^7 = gv: (name: "_Z13dot_annotatedPKfS0_Pfi", summaries: (function: (module: ^0, flags: (linkage: external, visibility: protected, notEligibleToImport: 1, live: 0, dsoLocal: 1, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), insts: 32, funcFlags: (readNone: 0, readOnly: 0, noRecurse: 1, returnDoesNotAlias: 0, noInline: 0, alwaysInline: 0, noUnwind: 1, mayThrow: 0, hasUnknownCall: 0, mustBeUnreachable: 0)))) ; guid = 14191886488862476923
^8 = gv: (name: "__ockl_fprintf_append_string_n", summaries: (function: (module: ^0, flags: (linkage: internal, visibility: default, notEligibleToImport: 1, live: 0, dsoLocal: 1, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), insts: 470, funcFlags: (readNone: 0, readOnly: 0, noRecurse: 1, returnDoesNotAlias: 0, noInline: 0, alwaysInline: 0, noUnwind: 1, mayThrow: 0, hasUnknownCall: 0, mustBeUnreachable: 0)))) ; guid = 14480576159567615790
^9 = gv: (name: "__assertfail", summaries: (function: (module: ^0, flags: (linkage: weak, visibility: hidden, notEligibleToImport: 1, live: 0, dsoLocal: 1, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), insts: 2, funcFlags: (readNone: 0, readOnly: 0, noRecurse: 0, returnDoesNotAlias: 0, noInline: 1, alwaysInline: 0, noUnwind: 1, mayThrow: 0, hasUnknownCall: 0, mustBeUnreachable: 1)))) ; guid = 15023886857468689011
^10 = gv: (name: "__cxa_pure_virtual", summaries: (function: (module: ^0, flags: (linkage: weak, visibility: default, notEligibleToImport: 1, live: 0, dsoLocal: 0, canAutoHide: 0, importType: definition, noRenameOnPromotion: 0), insts: 2, funcFlags: (readNone: 0, readOnly: 0, noRecurse: 0, returnDoesNotAlias: 0, noInline: 0, alwaysInline: 0, noUnwind: 1, mayThrow: 0, hasUnknownCall: 0, mustBeUnreachable: 1)))) ; guid = 15445200097692986839
^11 = flags: 8
^12 = blockcount: 0

# __CLANG_OFFLOAD_BUNDLE____END__ hip-amdgcn-amd-amdhsa--gfx1030

# __CLANG_OFFLOAD_BUNDLE____START__ host-x86_64-unknown-linux-gnu-
	.att_syntax
	.file	"main.hip"
	.text
	.globl	_Z24__device_stub__dot_plainPKfS0_Pfi # -- Begin function _Z24__device_stub__dot_plainPKfS0_Pfi
	.prefalign	4, .Lfunc_end0, nop
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
	callq	__hipPopCallConfiguration@PLT
	movq	40(%rsp), %rsi
	movl	48(%rsp), %edx
	movq	24(%rsp), %rcx
	movl	32(%rsp), %r8d
	movq	_Z9dot_plainPKfS0_Pfi@GOTPCREL(%rip), %rdi
	leaq	80(%rsp), %r9
	pushq	8(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	24(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel@PLT
	addq	$136, %rsp
	.cfi_adjust_cfa_offset -136
	retq
.Lfunc_end0:
	.size	_Z24__device_stub__dot_plainPKfS0_Pfi, .Lfunc_end0-_Z24__device_stub__dot_plainPKfS0_Pfi
	.cfi_endproc
                                        # -- End function
	.globl	_Z28__device_stub__dot_annotatedPKfS0_Pfi # -- Begin function _Z28__device_stub__dot_annotatedPKfS0_Pfi
	.prefalign	4, .Lfunc_end1, nop
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
	callq	__hipPopCallConfiguration@PLT
	movq	40(%rsp), %rsi
	movl	48(%rsp), %edx
	movq	24(%rsp), %rcx
	movl	32(%rsp), %r8d
	movq	_Z13dot_annotatedPKfS0_Pfi@GOTPCREL(%rip), %rdi
	leaq	80(%rsp), %r9
	pushq	8(%rsp)
	.cfi_adjust_cfa_offset 8
	pushq	24(%rsp)
	.cfi_adjust_cfa_offset 8
	callq	hipLaunchKernel@PLT
	addq	$136, %rsp
	.cfi_adjust_cfa_offset -136
	retq
.Lfunc_end1:
	.size	_Z28__device_stub__dot_annotatedPKfS0_Pfi, .Lfunc_end1-_Z28__device_stub__dot_annotatedPKfS0_Pfi
	.cfi_endproc
                                        # -- End function
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2, 0x0                          # -- Begin function main
	.type	.LCPI2_0,@object
.LCPI2_0:
	.long	0x3a83126f                      # float 0.00100000005
	.size	.LCPI2_0, 4
	.type	.LCPI2_1,@object
.LCPI2_1:
	.long	0x3b03126f                      # float 0.00200000009
	.size	.LCPI2_1, 4
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0
	.type	.LCPI2_2,@object
.LCPI2_2:
	.long	2                               # 0x2
	.long	2                               # 0x2
	.long	2                               # 0x2
	.long	2                               # 0x2
	.size	.LCPI2_2, 16
	.text
	.globl	main
	.prefalign	4, .Lfunc_end2, nop
	.type	main,@function
main:                                   # @main
.Lfunc_begin0:
	.cfi_startproc
	.cfi_personality 155, DW.ref.__gxx_personality_v0
	.cfi_lsda 27, .Lexception0
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
	callq	_Znwm@PLT
	movq	%rax, %rbx
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
.Ltmp0:                                 # EH_LABEL
	movl	$4194304, %edi                  # imm = 0x400000
	callq	_Znwm@PLT
.Ltmp1:                                 # EH_LABEL
# %bb.1:
	movq	%rax, %r14
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
.Ltmp3:                                 # EH_LABEL
	movl	$1024, %edi                     # imm = 0x400
	callq	_Znwm@PLT
.Ltmp4:                                 # EH_LABEL
# %bb.2:
	movq	%rax, %r15
	movl	$1024, %edx                     # imm = 0x400
	movq	%rax, %rdi
	xorl	%esi, %esi
	callq	memset@PLT
.Ltmp6:                                 # EH_LABEL
	movl	$1024, %edi                     # imm = 0x400
	callq	_Znwm@PLT
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
	callq	sinf@PLT
	movss	%xmm0, (%rbx,%r13,4)
	movss	.LCPI2_1(%rip), %xmm0           # xmm0 = [2.00000009E-3,0.0E+0,0.0E+0,0.0E+0]
	movss	4(%rsp), %xmm1                  # 4-byte Reload
                                        # xmm1 = mem[0],zero,zero,zero
	mulss	%xmm0, %xmm1
	movaps	%xmm1, %xmm0
	callq	cosf@PLT
	leal	1(%r13), %eax
	xorps	%xmm1, %xmm1
	cvtsi2ss	%eax, %xmm1
	movss	%xmm1, 4(%rsp)                  # 4-byte Spill
	movss	%xmm0, (%r14,%r13,4)
	movaps	%xmm1, %xmm0
	mulss	.LCPI2_0(%rip), %xmm0
	callq	sinf@PLT
	movss	%xmm0, 4(%rbx,%r13,4)
	movss	4(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	mulss	.LCPI2_1(%rip), %xmm0
	callq	cosf@PLT
	movss	%xmm0, 4(%r14,%r13,4)
	addq	$2, %r13
	cmpq	$1048576, %r13                  # imm = 0x100000
	jne	.LBB2_4
# %bb.5:
.Ltmp9:                                 # EH_LABEL
	leaq	16(%rsp), %rdi
	movl	$4194304, %esi                  # imm = 0x400000
	callq	hipMalloc@PLT
.Ltmp10:                                # EH_LABEL
# %bb.6:
	testl	%eax, %eax
	je	.LBB2_13
# %bb.7:
.Ltmp11:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp12:                                # EH_LABEL
# %bb.8:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$83, %edx
	jmp	.LBB2_9
.LBB2_13:
.Ltmp14:                                # EH_LABEL
	leaq	8(%rsp), %rdi
	movl	$4194304, %esi                  # imm = 0x400000
	callq	hipMalloc@PLT
.Ltmp15:                                # EH_LABEL
# %bb.14:
	testl	%eax, %eax
	je	.LBB2_17
# %bb.15:
.Ltmp16:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp17:                                # EH_LABEL
# %bb.16:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$84, %edx
	jmp	.LBB2_9
.LBB2_17:
.Ltmp19:                                # EH_LABEL
	leaq	32(%rsp), %rdi
	movl	$1024, %esi                     # imm = 0x400
	callq	hipMalloc@PLT
.Ltmp20:                                # EH_LABEL
# %bb.18:
	testl	%eax, %eax
	je	.LBB2_21
# %bb.19:
.Ltmp21:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp22:                                # EH_LABEL
# %bb.20:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$85, %edx
	jmp	.LBB2_9
.LBB2_21:
.Ltmp24:                                # EH_LABEL
	leaq	24(%rsp), %rdi
	movl	$1024, %esi                     # imm = 0x400
	callq	hipMalloc@PLT
.Ltmp25:                                # EH_LABEL
# %bb.22:
	testl	%eax, %eax
	je	.LBB2_25
# %bb.23:
.Ltmp26:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp27:                                # EH_LABEL
# %bb.24:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$86, %edx
	jmp	.LBB2_9
.LBB2_25:
	movq	16(%rsp), %rdi
.Ltmp29:                                # EH_LABEL
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%rbx, %rsi
	movl	$1, %ecx
	callq	hipMemcpy@PLT
.Ltmp30:                                # EH_LABEL
# %bb.26:
	testl	%eax, %eax
	je	.LBB2_29
# %bb.27:
.Ltmp31:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp32:                                # EH_LABEL
# %bb.28:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$87, %edx
	jmp	.LBB2_9
.LBB2_29:
	movq	8(%rsp), %rdi
.Ltmp34:                                # EH_LABEL
	movl	$4194304, %edx                  # imm = 0x400000
	movq	%r14, %rsi
	movl	$1, %ecx
	callq	hipMemcpy@PLT
.Ltmp35:                                # EH_LABEL
# %bb.30:
	testl	%eax, %eax
	je	.LBB2_33
# %bb.31:
.Ltmp36:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp37:                                # EH_LABEL
# %bb.32:
	leaq	.L.str(%rip), %rdi
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
	callq	__hipPushCallConfiguration@PLT
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
	callq	__hipPushCallConfiguration@PLT
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
	callq	hipDeviceSynchronize@PLT
.Ltmp49:                                # EH_LABEL
# %bb.40:
	testl	%eax, %eax
	je	.LBB2_43
# %bb.41:
.Ltmp50:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp51:                                # EH_LABEL
# %bb.42:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$92, %edx
	jmp	.LBB2_9
.LBB2_43:
	movq	32(%rsp), %rsi
.Ltmp53:                                # EH_LABEL
	movl	$1024, %edx                     # imm = 0x400
	movq	%r15, %rdi
	movl	$2, %ecx
	callq	hipMemcpy@PLT
.Ltmp54:                                # EH_LABEL
# %bb.44:
	testl	%eax, %eax
	je	.LBB2_47
# %bb.45:
.Ltmp55:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp56:                                # EH_LABEL
# %bb.46:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$93, %edx
	jmp	.LBB2_9
.LBB2_47:
	movq	24(%rsp), %rsi
.Ltmp58:                                # EH_LABEL
	movl	$1024, %edx                     # imm = 0x400
	movq	%r12, %rdi
	movl	$2, %ecx
	callq	hipMemcpy@PLT
.Ltmp59:                                # EH_LABEL
# %bb.48:
	testl	%eax, %eax
	je	.LBB2_51
# %bb.49:
.Ltmp60:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp61:                                # EH_LABEL
# %bb.50:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$94, %edx
	jmp	.LBB2_9
.LBB2_51:
	movq	16(%rsp), %rdi
.Ltmp63:                                # EH_LABEL
	callq	hipFree@PLT
.Ltmp64:                                # EH_LABEL
# %bb.52:
	testl	%eax, %eax
	je	.LBB2_55
# %bb.53:
.Ltmp65:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp66:                                # EH_LABEL
# %bb.54:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$95, %edx
	jmp	.LBB2_9
.LBB2_55:
	movq	8(%rsp), %rdi
.Ltmp68:                                # EH_LABEL
	callq	hipFree@PLT
.Ltmp69:                                # EH_LABEL
# %bb.56:
	testl	%eax, %eax
	je	.LBB2_59
# %bb.57:
.Ltmp70:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp71:                                # EH_LABEL
# %bb.58:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$96, %edx
	jmp	.LBB2_9
.LBB2_59:
	movq	32(%rsp), %rdi
.Ltmp73:                                # EH_LABEL
	callq	hipFree@PLT
.Ltmp74:                                # EH_LABEL
# %bb.60:
	testl	%eax, %eax
	je	.LBB2_63
# %bb.61:
.Ltmp75:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp76:                                # EH_LABEL
# %bb.62:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$97, %edx
	jmp	.LBB2_9
.LBB2_63:
	movq	24(%rsp), %rdi
.Ltmp78:                                # EH_LABEL
	callq	hipFree@PLT
.Ltmp79:                                # EH_LABEL
# %bb.64:
	testl	%eax, %eax
	je	.LBB2_65
# %bb.69:
.Ltmp80:                                # EH_LABEL
	movl	%eax, %edi
	callq	hipGetErrorString@PLT
.Ltmp81:                                # EH_LABEL
# %bb.70:
	leaq	.L.str(%rip), %rdi
	movq	%rax, %rsi
	movl	$98, %edx
.LBB2_9:
	xorl	%eax, %eax
	callq	printf@PLT
	movl	$1, %ebp
.LBB2_68:
	movl	$1024, %esi                     # imm = 0x400
	movq	%r12, %rdi
	callq	_ZdlPvm@PLT
	movl	$1024, %esi                     # imm = 0x400
	movq	%r15, %rdi
	callq	_ZdlPvm@PLT
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%r14, %rdi
	callq	_ZdlPvm@PLT
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%rbx, %rdi
	callq	_ZdlPvm@PLT
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
	movaps	%xmm1, %xmm3
	paddd	%xmm7, %xmm3
	movdqu	16(%r12,%rax,4), %xmm1
	pcmpeqd	%xmm4, %xmm1
	movdqa	%xmm2, %xmm4
	paddd	%xmm1, %xmm4
	movdqu	32(%r12,%rax,4), %xmm1
	pcmpeqd	%xmm5, %xmm1
	movdqu	48(%r12,%rax,4), %xmm2
	pcmpeqd	%xmm6, %xmm2
	paddd	%xmm0, %xmm1
	paddd	%xmm3, %xmm1
	paddd	%xmm0, %xmm2
	paddd	%xmm4, %xmm2
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
	leaq	.L.str.2(%rip), %rax
	leaq	.L.str.3(%rip), %rsi
	cmovneq	%rax, %rsi
	leaq	.L.str.1(%rip), %rdi
	movl	$256, %ecx                      # imm = 0x100
	xorl	%eax, %eax
	callq	printf@PLT
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
	callq	_ZdlPvm@PLT
.LBB2_74:
	movl	$1024, %esi                     # imm = 0x400
	movq	%r15, %rdi
	callq	_ZdlPvm@PLT
.LBB2_75:
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%r14, %rdi
	callq	_ZdlPvm@PLT
.LBB2_76:
	movl	$4194304, %esi                  # imm = 0x400000
	movq	%rbx, %rdi
	callq	_ZdlPvm@PLT
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
	.prefalign	4, .Lfunc_end3, nop     # -- Begin function __hip_module_ctor
	.type	__hip_module_ctor,@function
__hip_module_ctor:                      # @__hip_module_ctor
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	subq	$32, %rsp
	.cfi_def_cfa_offset 48
	.cfi_offset %rbx, -16
	movq	__hip_gpubin_handle_39c5098bf0f908ee(%rip), %rbx
	testq	%rbx, %rbx
	jne	.LBB3_2
# %bb.1:
	leaq	__hip_fatbin_wrapper(%rip), %rdi
	callq	__hipRegisterFatBinary@PLT
	movq	%rax, %rbx
	movq	%rax, __hip_gpubin_handle_39c5098bf0f908ee(%rip)
.LBB3_2:
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movq	_Z9dot_plainPKfS0_Pfi@GOTPCREL(%rip), %rsi
	leaq	.L__unnamed_1(%rip), %rcx
	movq	%rbx, %rdi
	movq	%rcx, %rdx
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction@PLT
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)
	movups	%xmm0, (%rsp)
	movq	_Z13dot_annotatedPKfS0_Pfi@GOTPCREL(%rip), %rsi
	leaq	.L__unnamed_2(%rip), %rcx
	movq	%rbx, %rdi
	movq	%rcx, %rdx
	movl	$-1, %r8d
	xorl	%r9d, %r9d
	callq	__hipRegisterFunction@PLT
	leaq	__hip_module_dtor(%rip), %rdi
	addq	$32, %rsp
	.cfi_def_cfa_offset 16
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	atexit@PLT                      # TAILCALL
.Lfunc_end3:
	.size	__hip_module_ctor, .Lfunc_end3-__hip_module_ctor
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end4, nop     # -- Begin function __hip_module_dtor
	.type	__hip_module_dtor,@function
__hip_module_dtor:                      # @__hip_module_dtor
	.cfi_startproc
# %bb.0:
	movq	__hip_gpubin_handle_39c5098bf0f908ee(%rip), %rdi
	testq	%rdi, %rdi
	je	.LBB4_2
# %bb.1:
	pushq	%rax
	.cfi_def_cfa_offset 16
	callq	__hipUnregisterFatBinary@PLT
	movq	$0, __hip_gpubin_handle_39c5098bf0f908ee(%rip)
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
.LBB4_2:
	retq
.Lfunc_end4:
	.size	__hip_module_dtor, .Lfunc_end4-__hip_module_dtor
	.cfi_endproc
                                        # -- End function
	.type	_Z9dot_plainPKfS0_Pfi,@object   # @_Z9dot_plainPKfS0_Pfi
	.section	.data.rel.ro,"aw",@progbits
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
	.section	.hipFatBinSegment,"aw",@progbits
	.p2align	3, 0x0
__hip_fatbin_wrapper:
	.long	1212764230                      # 0x48495046
	.long	1                               # 0x1
	.quad	__hip_fatbin_39c5098bf0f908ee
	.quad	0
	.size	__hip_fatbin_wrapper, 24

	.type	__hip_gpubin_handle_39c5098bf0f908ee,@object # @__hip_gpubin_handle_39c5098bf0f908ee
	.local	__hip_gpubin_handle_39c5098bf0f908ee
	.comm	__hip_gpubin_handle_39c5098bf0f908ee,8,8
	.section	.init_array,"aw",@init_array
	.p2align	3, 0x0
	.quad	__hip_module_ctor
	.type	__hip_cuid_39c5098bf0f908ee,@object # @__hip_cuid_39c5098bf0f908ee
	.bss
	.globl	__hip_cuid_39c5098bf0f908ee
__hip_cuid_39c5098bf0f908ee:
	.byte	0                               # 0x0
	.size	__hip_cuid_39c5098bf0f908ee, 1

	.hidden	DW.ref.__gxx_personality_v0
	.weak	DW.ref.__gxx_personality_v0
	.section	.data.DW.ref.__gxx_personality_v0,"awG",@progbits,DW.ref.__gxx_personality_v0,comdat
	.p2align	3, 0x0
	.type	DW.ref.__gxx_personality_v0,@object
	.size	DW.ref.__gxx_personality_v0, 8
DW.ref.__gxx_personality_v0:
	.quad	__gxx_personality_v0
	.ident	"AMD clang version 24.0.0git (https://github.com/ROCm/llvm-project.git d6f6cb691863e9258034ab48c1dfce21689d5606)"
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
	.addrsig_sym __hip_fatbin_39c5098bf0f908ee
	.addrsig_sym __hip_fatbin_wrapper
	.addrsig_sym __hip_cuid_39c5098bf0f908ee

# __CLANG_OFFLOAD_BUNDLE____END__ host-x86_64-unknown-linux-gnu-
