.RECIPEPREFIX := >
.DEFAULT_GOAL := help
SHELL := bash

PYTHON ?= python
ENV ?= dev
TF_DIR := infra/envs/$(ENV)
AWS_PROFILE ?= clw-$(ENV)

.PHONY: help setup fmt lint test test-integration security tf-init tf-plan emulator-build emulator-up emulator-down clean

help: ## Hiển thị danh sách lệnh
> @grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-18s %s\n", $$1, $$2}'

setup: ## Cài dependency Python và pre-commit hooks
> $(PYTHON) -m pip install -r requirements-dev.txt
> pre-commit install --install-hooks

fmt: ## Tự động format code Python và Terraform
> ruff check --fix src tests scripts
> ruff format src tests scripts
> terraform fmt -recursive infra

lint: ## Kiểm tra lint, không sửa file
> ruff check src tests scripts
> ruff format --check src tests scripts
> terraform fmt -check -recursive infra
> $(PYTHON) scripts/run_tflint.py

test: ## Unit test (moto, không cần Docker)
> $(PYTHON) -m pytest -m "not integration"

test-integration: emulator-up ## Integration test với AWS Emulator
> $(PYTHON) -m pytest -m integration

security: ## Quét bảo mật: IaC, secret, dependency
> checkov --config-file .checkov.yaml
> pre-commit run gitleaks --all-files
> pip-audit -r src/requirements.txt

tf-init: ## Terraform init cho ENV (mặc định dev)
> AWS_PROFILE=$(AWS_PROFILE) terraform -chdir=$(TF_DIR) init

tf-plan: ## Terraform plan cho ENV (mặc định dev)
> AWS_PROFILE=$(AWS_PROFILE) terraform -chdir=$(TF_DIR) plan

emulator-build: ## Build image AWS Emulator (không có image dựng sẵn)
> docker compose build emulator

emulator-up: ## Khởi động AWS Emulator (build nếu chưa có image)
> $(PYTHON) -c "from pathlib import Path; (Path.home() / '.aws' / 'emulator').mkdir(parents=True, exist_ok=True)"
> docker compose up -d --build emulator

emulator-down: ## Dừng AWS Emulator (trạng thái trong RAM sẽ mất)
> docker compose down

clean: ## Xóa cache và file build
> rm -rf .pytest_cache .ruff_cache .coverage htmlcov build dist
