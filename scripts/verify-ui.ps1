$ErrorActionPreference = "Stop"

# Banned terms for public-facing content
$BannedTerms = @(
  "division",
  "master",
  "control"
)

# File extensions to scan
$FileExtensions = @("*.razor", "*.cshtml", "*.html", "*.md", "*.css")

# Excluded folder patterns
$ExcludeFolders = @("bin", "obj", ".git", "backup", "archive", "reference")

Write-Host "=== UI Verification Script ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Find the active .csproj file
Write-Host "Step 1: Finding active .csproj file..." -ForegroundColor Cyan

$csprojFiles = @()
if (Test-Path "JPVOS.sln") {
  # Look for .csproj files in src/JPVOS directory (primary project)
  $csprojFiles = Get-ChildItem -Path "src" -Recurse -Filter "*.csproj" -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "src[\/\\]JPVOS[\/\\]" }
}

if ($csprojFiles.Count -eq 0) {
  Write-Host "FAIL: No .csproj file found" -ForegroundColor Red
  exit 1
}

$csprojPath = $csprojFiles[0].FullName
$csprojDir = Split-Path -Parent $csprojPath
$projectName = Split-Path -Leaf $csprojDir

Write-Host "  Found: $csprojPath" -ForegroundColor Green

# Step 2: Run dotnet build
Write-Host ""
Write-Host "Step 2: Running dotnet build..." -ForegroundColor Cyan

try {
  $buildOutput = dotnet build JPVOS.sln -c Release 2>&1
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: Build failed" -ForegroundColor Red
    Write-Host $buildOutput
    exit 1
  }
  Write-Host "  Build successful" -ForegroundColor Green
}
catch {
  Write-Host "FAIL: Build error - $_" -ForegroundColor Red
  exit 1
}

# Step 3: Scan for banned terms in public-facing files
Write-Host ""
Write-Host "Step 3: Scanning public-facing files for banned terms..." -ForegroundColor Cyan

$filesWithBannedTerms = @()
$bannedTermsFound = @()

# Build exclusion filter
$excludeFilter = {
  $path = $_.FullName
  foreach ($excludeFolder in $ExcludeFolders) {
    if ($path -match "([\/\\]|^)$excludeFolder([\/\\]|$)") {
      return $false
    }
  }
  return $true
}

foreach ($ext in $FileExtensions) {
  $files = Get-ChildItem -Path "." -Recurse -Filter $ext -ErrorAction SilentlyContinue | Where-Object $excludeFilter
  
  foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { continue }
    
    foreach ($term in $BannedTerms) {
      # Case-insensitive search for whole word matches
      if ($content -match "\b$([regex]::Escape($term))\b") {
        $filesWithBannedTerms += $file.FullName
        $bannedTermsFound += @{
          File = $file.FullName
          Term = $term
        }
      }
    }
  }
}

if ($bannedTermsFound.Count -gt 0) {
  Write-Host "FAIL: Banned terms found in public-facing files" -ForegroundColor Red
  Write-Host ""
  
  $bannedTermsFound | Group-Object { $_.File } | ForEach-Object {
    Write-Host "  File: $($_.Name)" -ForegroundColor Yellow
    $_.Group | ForEach-Object {
      Write-Host "    - Term: '$($_.Term)'" -ForegroundColor Red
    }
  }
  
  Write-Host ""
  exit 1
}

Write-Host "  No banned terms detected" -ForegroundColor Green

# All checks passed
Write-Host ""
Write-Host "PASS: UI verification successful" -ForegroundColor Green
Write-Host "  - Build completed successfully" -ForegroundColor Green
Write-Host "  - No banned terms found in public-facing files" -ForegroundColor Green
exit 0
