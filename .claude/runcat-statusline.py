#!/usr/bin/env python3
"""
RunCat Neo — Claude Code statusLine sample.

Writes ~/.claude/runcat-usage.json shaped like:

    {
      "title": "Claude",
      "symbol": "staroflife",
      "metrics": [
        {"title": "Model", "formattedValue": "Fable 5"},
        {"title": "7d",    "formattedValue": "3%", "normalizedValue": 0.03},
        {"title": "5h",    "formattedValue": "3%", "normalizedValue": 0.03}
      ],
      "lastUpdatedDate": "2026-06-07T05:55:36Z"
    }
"""

import json
import os
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

OUT = Path(os.environ.get("RUNCAT_OUT_FILE", str(Path.home() / ".claude" / "runcat-usage.json")))


def pct(title, value):
    if value is None:
        return None
    return {"title": title, "formattedValue": f"{value:g}%", "normalizedValue": round(value / 100, 4)}


try:
    payload = json.load(sys.stdin)
    if not isinstance(payload, dict):
        payload = {}
except Exception:
    payload = {}

model = (payload.get("model") or {}).get("display_name") or "Fable 5"
if model.startswith("Claude "):
    model = model.removeprefix("Claude ")
rate_limits = payload.get("rate_limits") or {}
five = (rate_limits.get("five_hour") or {}).get("used_percentage")
seven = (rate_limits.get("seven_day") or {}).get("used_percentage")

snapshot = {
    "title": "Claude",
    "symbol": "staroflife",
    "metrics": [m for m in [
        {"title": "Model", "formattedValue": model},
        pct("7d", seven),
        pct("5h", five),
    ] if m is not None],
    "lastUpdatedDate": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}

OUT.parent.mkdir(parents=True, exist_ok=True)
fd, tmp = tempfile.mkstemp(prefix=".runcat-", dir=str(OUT.parent))
with os.fdopen(fd, "w", encoding="utf-8") as f:
    json.dump(snapshot, f, ensure_ascii=False)
os.replace(tmp, OUT)

print(model)
