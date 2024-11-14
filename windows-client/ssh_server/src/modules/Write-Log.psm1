function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    $logDir = Split-Path -Path $Global:LogPath -Parent
    try {
        if (-not (Test-Path -Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        # Format timestamp and message
        $timestamp = Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
        $logMessage = "[$timestamp] [$Level] $Message"
    
        # Console output with colors
        switch ($Level) {
            'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
            'Error' { Write-Host $logMessage -ForegroundColor Red }
            default { Write-Host $logMessage }
        }

        # Write to log file
        Add-Content -Path $LogPath -Value $logMessage -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
        Write-Host $logMessage -ForegroundColor Gray
    }
}