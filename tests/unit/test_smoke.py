"""Smoke test: xác nhận pipeline test chạy được và runtime đủ phiên bản."""

import sys


def test_python_version_is_312_or_newer() -> None:
    assert sys.version_info >= (3, 12)
