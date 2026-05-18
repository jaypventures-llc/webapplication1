
$ErrorActionPreference = "Stop"
$BaseUrl = "https://jpv-os-access-gateway.azurewebsites.net"

# HOMEPAGE CHECK

Write-Host "[2] Checking homepage..."

$Homepage = Invoke-WebRequest `
  "$BaseUrl/" `
  -UseBasicParsing

if ($Homepage.StatusCode -ne 200) {
  throw "Homepage failed."
}

if ($Homepage.Content -notmatch "Welcome to the Venture") {
  throw "Hero text missing."
}

Write-Host "Homepage reachable."
Write-Host ""

# CSS CHECK

Write-Host "[3] Checking homepage styling..."

if ($Homepage.Content -notmatch "init-home.css") {
  throw "Homepage stylesheet missing."
}

Write-Host "Stylesheet binding confirmed."
Write-Host ""

# CTA CHECK
Write-Host "[4] Checking final CTA labels..."
if ($Homepage.Content -notmatch "Enter the Ecosystem") {
  throw "Primary CTA missing: Enter the Ecosystem."
}
if ($Homepage.Content -notmatch "Explore Architecture") {
  throw "Secondary CTA missing: Explore Architecture."
}
Write-Host "CTA validation passed."
Write-Host ""

# FINAL

Write-Host "======================================"
Write-Host "VERIFICATION COMPLETE"
Write-Host "======================================"
Write-Host ""
