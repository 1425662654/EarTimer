#!/usr/bin/env python3
"""从 simctl 的设备列表里挑一个可用的 iPhone 模拟器 UDID。"""
import json
import subprocess
import sys

out = subprocess.run(
    ["xcrun", "simctl", "list", "devices", "available", "-j"],
    capture_output=True, text=True, timeout=60,
)
if out.returncode != 0:
    print("simctl 调用失败", file=sys.stderr)
    print(out.stderr, file=sys.stderr)
    sys.exit(1)

data = json.loads(out.stdout)["devices"]

# 优先新机型
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
