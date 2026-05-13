$ErrorActionPreference = "Stop"

$RequiredFile = "PEOPLE-PROTECTION-NON-NEGOTIABLE.md"

$RequiredTerms = @(
  "human dignity",
  "autonomy",
  "consent",
  "anti-discrimination",
  "forced labor",
  "slavery",
  "human review",
  "appeal",
  "reversible",
  "auditable",
  "social scoring",
  "unlawful surveillance",
  "biometric",
  "children",
  "monetization",
  "data resale",
  "interoperability",
  "vendor exclusivity",
  "lock-in"
)

if (!(Test-Path $RequiredFile)) {
  Write-Host "FAIL: Missing $RequiredFile" -ForegroundColor Red
  exit 1
}

$content = Get-Content $RequiredFile -Raw

$missing = @()

foreach ($term in $RequiredTerms) {
  if ($content -notmatch [regex]::Escape($term)) {
    $missing += $term
  }
}

if ($missing.Count -gt 0) {
  Write-Host "FAIL: People Protection policy is incomplete." -ForegroundColor Red
  Write-Host "Missing terms:" -ForegroundColor Yellow

  $missing | ForEach-Object {
    Write-Host " - $_"
  }

  exit 1
}

Write-Host "PASS: People Protection policy artifact is present and complete." -ForegroundColor Green
exit 0
