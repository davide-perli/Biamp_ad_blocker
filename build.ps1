[CmdletBinding()]
param(
    [switch]$SkipFirefoxLint
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$python = Join-Path $root "req_libraries\Scripts\python.exe"
if (-not (Test-Path $python)) {
    throw "Python was not found at $python"
}

if (-not $SkipFirefoxLint -and -not (Get-Command web-ext -ErrorAction SilentlyContinue)) {
    throw "web-ext was not found. Install it with: npm install --global web-ext"
}

function Remove-GeneratedRules([string]$directory) {
    Get-ChildItem -Path (Join-Path $root $directory) -Filter "rules_*.json" -File -ErrorAction SilentlyContinue |
        Remove-Item -Force
}

function Update-ManifestRules([string]$directory) {
    $directoryPath = Join-Path $root $directory
    $manifestPath = Join-Path $directoryPath "manifest.json"
    $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
    $rules = @(Get-ChildItem -Path $directoryPath -Filter "rules_*.json" -File |
        Sort-Object { [int]($_.BaseName -replace "rules_", "") })

    if ($rules.Count -eq 0) {
        throw "No generated rule files found in $directoryPath"
    }

    $manifest.declarative_net_request.rule_resources = @(
        foreach ($rule in $rules) {
            [PSCustomObject]@{
                id = $rule.BaseName
                enabled = $true
                path = $rule.Name
            }
        }
    )
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 $manifestPath
}

function Invoke-PythonScript([string]$script) {
    & $python (Join-Path $root $script)
    if ($LASTEXITCODE -ne 0) {
        throw "$script failed with exit code $LASTEXITCODE"
    }
}

function New-ExtensionArchive([string]$directory, [string]$archiveName) {
    $archivePath = Join-Path $root $archiveName
    if (Test-Path $archivePath) {
        Remove-Item $archivePath -Force
    }

    & $python (Join-Path $root "package_extension.py") $directory $archivePath
    if ($LASTEXITCODE -ne 0) {
        throw "Could not create $archiveName"
    }
}

Remove-GeneratedRules "chromium-extension"
Remove-GeneratedRules "firefox-extension"
Invoke-PythonScript "data_fetcher.py"
Invoke-PythonScript "rules_creator.py"
Invoke-PythonScript "rules_creator_firefox.py"
Update-ManifestRules "chromium-extension"
Update-ManifestRules "firefox-extension"

if (-not $SkipFirefoxLint) {
    & web-ext lint --source-dir (Join-Path $root "firefox-extension")
    if ($LASTEXITCODE -ne 0) {
        throw "Firefox lint failed with exit code $LASTEXITCODE"
    }
}

New-ExtensionArchive "chromium-extension" "chromium-extension.zip"
New-ExtensionArchive "firefox-extension" "firefox-extension.zip"

Write-Host "Built chromium-extension.zip and firefox-extension.zip"
