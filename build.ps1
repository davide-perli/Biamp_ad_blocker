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

function Ensure-Manifest([string]$directory, [switch]$Firefox) {
    $directoryPath = Join-Path $root $directory
    $manifestPath = Join-Path $directoryPath "manifest.json"

    if (Test-Path $manifestPath) {
        return
    }

    $rules = @(Get-ChildItem -Path $directoryPath -Filter "rules_*.json" -File |
        Sort-Object { [int]($_.BaseName -replace "rules_", "") })

    if ($rules.Count -eq 0) {
        throw "No generated rule files found for $manifestPath"
    }

    $ruleResources = ($rules | ForEach-Object {
        '            {"id":  "' + $_.BaseName + '", "enabled":  true, "path":  "' + $_.Name + '"}'
    }) -join ",`r`n"

    if ($Firefox) {
        $manifest = @"
{
    "name":  "Biamp Ad Blocker",
    "version":  "1.7",
    "description":  "DNS adware-malware blocker. Details and source code available at https://github.com/davide-perli/Biamp_ad_blocker.",
    "permissions":  ["declarativeNetRequest"],
    "host_permissions":  ["<all_urls>"],
    "browser_specific_settings":  {
        "gecko":  {
            "id":  "davide-ad-blocker@biamp",
            "strict_min_version":  "142.0",
            "data_collection_permissions":  {"required":  ["none"]}
        }
    },
    "declarative_net_request":  {
        "rule_resources":  [
$ruleResources
        ]
    },
    "icons":  {
        "16":   "icons/logo_16x16.png",
        "32":   "icons/logo_32x32.png",
        "48":   "icons/logo_48x48.png",
        "96":   "icons/logo_96x96.png",
        "128":  "icons/logo_128x128.png"
    },
    "action": {
        "default_icon": {
            "16": "icons/logo_16x16.png",
            "32": "icons/logo_32x32.png"
        },
        "default_title": "Biamp Ad Blocker"
    },
    "manifest_version":  3
}
"@
    } else {
        $manifest = @"
{
    "name":  "Biamp Ad Blocker",
    "version":  "1.7",
    "description":  "DNS adware-malware blocker. Details and source code available at https://github.com/davide-perli/Biamp_ad_blocker.",
    "permissions":  ["declarativeNetRequest", "declarativeNetRequestWithHostAccess"],
    "host_permissions":  ["<all_urls>"],
    "declarative_net_request":  {
        "rule_resources":  [
$ruleResources
        ]
    },
    "icons":  {
        "16":  "icons/logo_16x16.png",
        "32":  "icons/logo_32x32.png",
        "48":  "icons/logo_48x48.png",
        "128": "icons/logo_128x128.png"
    },
    "action": {
        "default_icon": {
            "16": "icons/logo_16x16.png",
            "32": "icons/logo_32x32.png"
        },
        "default_title": "Biamp Ad Blocker"
    },
    "manifest_version":  3
}
"@
    }

    Set-Content -Path $manifestPath -Value $manifest -Encoding utf8
}

function Validate-ManifestRules([string]$directory) {
    $directoryPath = Join-Path $root $directory
    $manifestPath = Join-Path $directoryPath "manifest.json"
    $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
    $rules = @(Get-ChildItem -Path $directoryPath -Filter "rules_*.json" -File |
        Sort-Object { [int]($_.BaseName -replace "rules_", "") })
    $manifestRules = @($manifest.declarative_net_request.rule_resources)

    if ($rules.Count -eq 0) {
        throw "No generated rule files found in $directoryPath"
    }

    if ($manifestRules.Count -ne $rules.Count) {
        throw "Manifest rule count does not match generated rule count in $directoryPath"
    }

    for ($index = 0; $index -lt $rules.Count; $index++) {
        $manifestRule = $manifestRules[$index]
        $generatedRule = $rules[$index]

        if (
            $manifestRule.id -ne $generatedRule.BaseName -or
            $manifestRule.enabled -ne $true -or
            $manifestRule.path -ne $generatedRule.Name
        ) {
            throw "Manifest rule resource does not match generated rule $($generatedRule.Name) in $directoryPath"
        }
    }
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
Ensure-Manifest "chromium-extension"
Ensure-Manifest "firefox-extension" -Firefox
Validate-ManifestRules "chromium-extension"
Validate-ManifestRules "firefox-extension"

if (-not $SkipFirefoxLint) {
    & web-ext lint --source-dir (Join-Path $root "firefox-extension")
    if ($LASTEXITCODE -ne 0) {
        throw "Firefox lint failed with exit code $LASTEXITCODE"
    }
}

New-ExtensionArchive "chromium-extension" "chromium-extension.zip"
New-ExtensionArchive "firefox-extension" "firefox-extension.zip"

Write-Host "Built chromium-extension.zip and firefox-extension.zip"
