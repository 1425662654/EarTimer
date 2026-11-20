#!/usr/bin/env python3
"""从 simctl 的设备列表里挑一个可用的 iPhone 模拟器 UDID。

注意：GitHub macOS 运行器刚开机时 CoreSimulator 服务可能还没起来，
第一次 `simctl list` 会卡住。所以这里做多轮重试 + 先预热。
"""
import json
import subprocess
import sys
import time

def run(cmd, timeout=180):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)

# 预热：先把 CoreSimulator 服务叫起来
print("预热 CoreSimulator ...", file=sys.stderr)
for attempt in range(1, 4):
    try:
        r = run(["xcrun", "simctl", "list", "devices", "-j"], timeout=180)
        if r.returncode == 0:
            print(f"预热成功（第 {attempt} 次）", file=sys.stderr)
            break
        print(f"预热第 {attempt} 次返回 {r.returncode}", file=sys.stderr)
    except subprocess.TimeoutExpired:
        print(f"预热第 {attempt} 次超时", file=sys.stderr)
        time.sleep(10)
else:
    print("预热失败，继续尝试正式查询", file=sys.stderr)

# 正式查询，多轮重试
data = None
for attempt in range(1, 6):
    try:
        r = run(["xcrun", "simctl", "list", "devices", "available", "-j"], timeout=240)
        if r.returncode == 0 and r.stdout.strip():
            data = json.loads(r.stdout)["devices"]
            print(f"查询成功（第 {attempt} 次）", file=sys.stderr)
            break
        print(f"第 {attempt} 次失败 rc={r.returncode} {r.stderr[:200]}", file=sys.stderr)
    except subprocess.TimeoutExpired:
        print(f"第 {attempt} 次超时", file=sys.stderr)
    except json.JSONDecodeError as e:
        print(f"第 {attempt} 次 JSON 解析失败: {e}", file=sys.stderr)
    time.sleep(15)

if data is None:
    print("无法获取模拟器列表", file=sys.stderr)
    sys.exit(1)

PREFERENCE = ["iPhone 16 Pro", "iPhone 16", "iPhone 15 Pro", "iPhone 15"]

candidates = []
for runtime, devices in data.items():
    if "iOS" not in runtime:
        continue
    for dev in devices:
        if not dev.get("isAvailable"):
            continue
        if "iPhone" not in dev["name"]:
            continue
        candidates.append((runtime, dev["name"], dev["udid"]))

if not candidates:
    print("没有可用的 iPhone 模拟器", file=sys.stderr)
    for runtime, devices in data.items():
        print(f"  {runtime}: {[d['name'] for d in devices]}", file=sys.stderr)
    sys.exit(1)

chosen = None
for want in PREFERENCE:
    for runtime, name, udid in candidates:
        if name == want:
            chosen = (runtime, name, udid)
            break
    if chosen:
        break

if not chosen:
    chosen = candidates[0]

runtime, name, udid = chosen
print(f"选中: {name}  ({runtime})", file=sys.stderr)
print(udid)
