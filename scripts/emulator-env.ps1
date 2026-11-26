<#
.SYNOPSIS
  Trỏ shell PowerShell hiện tại vào AWS Emulator đang chạy cục bộ.
.DESCRIPTION
  Phải chạy bằng dot-source (có dấu chấm và khoảng trắng phía trước) thì biến môi trường
  mới ở lại trong shell. Đóng shell là quay về AWS thật.
.EXAMPLE
  . .\scripts\emulator-env.ps1
  aws sts get-caller-identity
#>
param(
  [int]$Port = 9297,
  [string]$Region = "us-east-1"
)

$dir = Join-Path $env:USERPROFILE ".aws\emulator\$Port"

foreach ($name in @("emulator_credentials", "config", "ca.pem")) {
  if (-not (Test-Path (Join-Path $dir $name))) {
    throw "Không thấy '$name' trong $dir. Emulator đã chạy chưa? Hãy chạy: make emulator-up"
  }
}

Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN, Env:AWS_PROFILE -ErrorAction SilentlyContinue

$env:AWS_ENDPOINT_URL                  = "https://127.0.0.1:$Port"
$env:AWS_SHARED_CREDENTIALS_FILE       = Join-Path $dir "emulator_credentials"
$env:AWS_CONFIG_FILE                   = Join-Path $dir "config"
$env:AWS_CA_BUNDLE                     = Join-Path $dir "ca.pem"
$env:AWS_EC2_METADATA_DISABLED         = "true"
$env:AWS_DISABLE_HOST_PREFIX_INJECTION = "true"
$env:AWS_REGION                        = $Region
$env:AWS_DEFAULT_REGION                = $Region

Write-Host "Shell này đang trỏ vào AWS Emulator tại $($env:AWS_ENDPOINT_URL) (region $Region)."
Write-Host "Đóng shell này để quay về AWS thật. KHÔNG chạy terraform apply trong shell này."
