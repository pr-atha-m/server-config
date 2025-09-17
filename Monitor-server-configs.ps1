# File: Monitor-And-Send.ps1
param(
    [string]$RootPath = "C:\Users\Pratham\Downloads\12_server_project\servers",  # servers/ folder
    [int]$IntervalSeconds = 10,                                                  # monitoring interval
    [string]$LogFile = "C:\Users\Pratham\Downloads\12_server_project\config_monitor.log",
    [string]$OutputJson = "C:\Users\Pratham\Downloads\12_server_project\configs_snapshot.json",
    [string]$ApiUrl = "http://localhost:5000/llm-drift",  # <-- replace with your LLM endpoint
    [string]$ApiKey = "YOUR_API_KEY"                      # if needed
)

$FileHashes = @{}

function Build-Snapshot {
    param([string]$Path)

    $snapshot = @{}
    Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
        $hash = Get-FileHash -Path $_.FullName -Algorithm SHA256
        $content = Get-Content -Path $_.FullName -Raw
        $snapshot[$_.FullName] = @{
            Hash    = $hash.Hash
            Content = $content.TrimEnd()
        }
    }
    return $snapshot
}

# Logging the start
Write-Output "[$(Get-Date)] Starting monitoring at $RootPath" | Tee-Object -FilePath $LogFile -Append
function Compare-Hashes {
    param($OldSnapshot, $NewSnapshot)

    $changeDetected = $false

    foreach ($file in $NewSnapshot.Keys) {
        if (-not $OldSnapshot.ContainsKey($file)) {
            Write-Output "$(Get-Date) - Change detected in $file (NEW)" | Tee-Object -FilePath $LogFile -Append | Write-Host
            $changeDetected = $true
        }
        elseif ($OldSnapshot[$file].Hash -ne $NewSnapshot[$file].Hash) {
            Write-Output "$(Get-Date) - Change detected in $file (MODIFIED)" | Tee-Object -FilePath $LogFile -Append | Write-Host
            $changeDetected = $true
        }
    }

    foreach ($file in $OldSnapshot.Keys) {
        if (-not $NewSnapshot.ContainsKey($file)) {
            Write-Output "$(Get-Date) - Change detected in $file (DELETED)" | Tee-Object -FilePath $LogFile -Append | Write-Host
            $changeDetected = $true
        }
    }

    return $changeDetected
}


# Initial snapshot
$FileHashes = Build-Snapshot -Path $RootPath
$FileHashes | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputJson -Encoding UTF8

while ($true) {
    Start-Sleep -Seconds $IntervalSeconds
    $NewSnapshot = Build-Snapshot -Path $RootPath
    $changeDetected = Compare-Hashes -OldSnapshot $FileHashes -NewSnapshot $NewSnapshot
    
    if ($changeDetected) {
        $NewSnapshot | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputJson -Encoding UTF8
        $FileHashes = $NewSnapshot
    }
}
