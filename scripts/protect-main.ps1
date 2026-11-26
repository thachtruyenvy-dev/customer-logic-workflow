<#
.SYNOPSIS
  Bật branch protection cho nhánh main bằng GitHub API.
.PARAMETER Repo
  Tên repo dạng owner/repo, ví dụ: my-user/customer-logic-workflow
.PARAMETER Reviews
  Số approval tối thiểu. Dùng 0 nếu bạn làm một mình (không thể tự approve PR của chính mình).
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$Repo,

  [ValidateRange(0, 6)]
  [int]$Reviews = 1
)

$ErrorActionPreference = "Stop"

$protection = @{
  required_status_checks = @{
    strict   = $true
    contexts = @("lint", "unit-test", "security-scan", "terraform-plan")
  }
  enforce_admins = $true
  required_pull_request_reviews = @{
    required_approving_review_count = $Reviews
    dismiss_stale_reviews           = $true
    require_code_owner_reviews      = ($Reviews -gt 0)
  }
  restrictions                      = $null
  required_linear_history           = $true
  allow_force_pushes                = $false
  allow_deletions                   = $false
  required_conversation_resolution  = $true
}

$json = $protection | ConvertTo-Json -Depth 6

$json | gh api --method PUT "repos/$Repo/branches/main/protection" --input -

Write-Host "Đã bật branch protection cho $Repo (main), reviews tối thiểu = $Reviews"
