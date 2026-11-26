"""Chạy tflint cho toàn bộ thư mục infra với cấu hình ở gốc repo."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / ".tflint.hcl"
INFRA = ROOT / "infra"


def run(cmd: list[str]) -> int:
    """Chạy một lệnh trong thư mục infra và trả về exit code."""
    return subprocess.run(cmd, cwd=INFRA, check=False).returncode


def main() -> int:
    if not INFRA.exists():
        print("Chưa có thư mục infra/, bỏ qua tflint.")
        return 0

    init_code = run(["tflint", "--init", f"--config={CONFIG}"])
    if init_code != 0:
        return init_code

    return run(["tflint", "--recursive", f"--config={CONFIG}"])


if __name__ == "__main__":
    sys.exit(main())
