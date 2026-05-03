#!/usr/bin/env python3
"""Print the UDID of an available iPhone iOS Simulator (for xcodebuild -destination)."""

from __future__ import annotations

import json
import subprocess
import sys


def main() -> None:
    raw = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "-j"],
        text=True,
    )
    data = json.loads(raw)
    for runtime in sorted(data.get("devices", {}), reverse=True):
        if "iOS" not in runtime:
            continue
        for dev in data["devices"][runtime]:
            if not dev.get("isAvailable", False):
                continue
            if "iPhone" not in dev.get("deviceTypeIdentifier", ""):
                continue
            print(dev["udid"])
            return
    sys.stderr.write("No available iPhone simulator found.\n")
    raise SystemExit(1)


if __name__ == "__main__":
    main()
