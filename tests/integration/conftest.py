"""Fixture tích hợp: trỏ boto3 vào AWS Emulator chạy cục bộ."""

from __future__ import annotations

import os
import ssl
import time
import urllib.request
from collections.abc import Iterator
from pathlib import Path

import pytest

PORT = int(os.environ.get("EMULATOR_PORT", "9297"))
REGION = os.environ.get("EMULATOR_REGION", "us-east-1")
ENDPOINT = f"https://127.0.0.1:{PORT}"
EMULATOR_DIR = Path.home() / ".aws" / "emulator" / str(PORT)
HEALTH_TIMEOUT_SECONDS = 90


def pytest_collection_modifyitems(items: list[pytest.Item]) -> None:
    """Tự gắn marker `integration` cho mọi test nằm dưới tests/integration."""
    for item in items:
        if "integration" in Path(str(item.path)).parts:
            item.add_marker(pytest.mark.integration)


def _wait_until_healthy() -> None:
    """Chờ endpoint /__admin/health trả 200 (qua HTTPS, tin cậy ca.pem của emulator)."""
    ca_file = EMULATOR_DIR / "ca.pem"
    deadline = time.monotonic() + HEALTH_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        if ca_file.exists():
            try:
                context = ssl.create_default_context(cafile=str(ca_file))
                url = f"{ENDPOINT}/__admin/health"
                with urllib.request.urlopen(url, context=context, timeout=3) as response:  # noqa: S310
                    if response.status == 200:
                        return
            except OSError:
                pass
        time.sleep(1)
    pytest.exit(
        f"AWS Emulator chưa sẵn sàng tại {ENDPOINT}. "
        "Hãy chạy `make emulator-up` và kiểm tra log container.",
        returncode=2,
    )


@pytest.fixture(scope="session", autouse=True)
def emulator_env() -> Iterator[None]:
    """Đặt biến môi trường trỏ boto3 vào emulator, chỉ trong tiến trình pytest."""
    _wait_until_healthy()

    patch = pytest.MonkeyPatch()
    for name in ("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_PROFILE"):
        patch.delenv(name, raising=False)

    patch.setenv("AWS_ENDPOINT_URL", ENDPOINT)
    patch.setenv("AWS_SHARED_CREDENTIALS_FILE", str(EMULATOR_DIR / "emulator_credentials"))
    patch.setenv("AWS_CONFIG_FILE", str(EMULATOR_DIR / "config"))
    patch.setenv("AWS_CA_BUNDLE", str(EMULATOR_DIR / "ca.pem"))
    patch.setenv("AWS_EC2_METADATA_DISABLED", "true")
    patch.setenv("AWS_DISABLE_HOST_PREFIX_INJECTION", "true")
    patch.setenv("AWS_REGION", REGION)
    patch.setenv("AWS_DEFAULT_REGION", REGION)

    yield

    patch.undo()
