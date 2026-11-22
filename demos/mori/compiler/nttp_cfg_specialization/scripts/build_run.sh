#!/bin/bash
# 构建+运行+ISA 观察（容器内 gfx1030）
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
RES="$HERE/results"
cmake -S "$HERE" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release -G Ninja > "$RES/build.log" 2>&1
cmake --build "$HERE/build" >> "$RES/build.log" 2>&1
"$HERE/build/nttp_cfg_specialization" | tee "$RES/run_gfx1030.log"

# ISA 观察：编译 bundle → 解包 gfx1030 code object → 反汇编各 NTTP 特化
# （ROCm 7 的 hipcc 产物是 __CLANG_OFFLOAD_BUNDLE__，需 clang-offload-bundler 解包）
ISA="$RES/isa"
hipcc --genco --offload-arch=gfx1030 -O2 -std=c++20 "$HERE/src/nttp_cfg_specialization.hip" -o "$ISA/nttp.hsaco" >> "$RES/build.log" 2>&1
BUNDLER=$(command -v clang-offload-bundler || echo /opt/rocm/llvm/bin/clang-offload-bundler)
"$BUNDLER" --type=o --input="$ISA/nttp.hsaco" --output="$ISA/gfx1030.co" \
  --targets=hipv4-amdgcn-amd-amdhsa--gfx1030 --unbundle >> "$RES/build.log" 2>&1
OBJDUMP=$(command -v llvm-objdump || echo /opt/rocm/llvm/bin/llvm-objdump)
"$OBJDUMP" -d --triple=amdgcn-amd-amdhsa "$ISA/gfx1030.co" > "$ISA/nttp.full.s"
# 按入口函数切分，统计每特化的加载指令形态
python3 - "$ISA" <<'PY'
import re, sys, os
isa = sys.argv[1]
text = open(os.path.join(isa, "nttp.full.s"), errors="ignore").read()
funcs = re.split(r'\n(?=[^\t ].*:)', text)
# NTTP 在 mangled name 里的证据形态：_Z16copy_nttp_kernelIXtl7CopyCfgLi<vec>ELi<unroll>[ELb1]E
pats = {
  "cfg_v16_u4_nt ": r"copy_nttp_kernelIXtl7CopyCfgLi16ELi4ELb1",
  "cfg_v8_u4_nt  ": r"copy_nttp_kernelIXtl7CopyCfgLi8ELi4ELb1",
  "cfg_v16_u1    ": r"copy_nttp_kernelIXtl7CopyCfgLi16ELi1E",
  "cfg_v4_u2     ": r"copy_nttp_kernelIXtl7CopyCfgLi4ELi2E",
  "rt_if_version ": r"copy_rt_kernel",
}
keys = [r"global_load_dwordx4", r"global_load_dwordx2", r"global_load_dword\b",
        r" slc", r"s_waitcnt", r"\bds_\w+"]
report = {}
for f in funcs:
    hdr = f.split("\n")[0]
    for w, p in pats.items():
        if re.search(p, hdr):
            report[w] = {k: len(re.findall(k, f)) for k in keys}
with open(os.path.join(isa, "isa_summary.txt"), "w") as fp:
    fp.write("列: [global_load_dwordx4, dwordx2, dword, ' slc'(NT提示), s_waitcnt, ds_*] 计数\n")
    for w, c in report.items():
        line = f"{w}: {c}"
        fp.write(line + "\n"); print("ISA", line)
PY
echo "ISA artifacts in $RES/isa/"
