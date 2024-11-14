Import-Module "$PSScriptRoot/Write-Log.psm1" -Force

function Test-SSHConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Username,
        [Parameter(Mandatory)]
        [string]$KeyPath,
        [string]$Host = "localhost"
    )
    
    try {
        Write-Log "Testing SSH connection for $Username@$Host..."
        
        $tempOutput = Join-Path $env:TEMP "ssh-test-output.txt"
        $tempError = Join-Path $env:TEMP "ssh-test-error.txt"
        
        $sshArgs = @(
            "-o", "StrictHostKeyChecking=no",
            "-i", $KeyPath,
            "$Username@$Host",
            "echo 'Connection successful'"
        )
        
        $process = Start-Process -FilePath "ssh" `
            -ArgumentList $sshArgs `
            -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput $tempOutput `
            -RedirectStandardError $tempError
        
        $output = Get-Content -Path $tempOutput -ErrorAction SilentlyContinue
        $error = Get-Content -Path $tempError -ErrorAction SilentlyContinue
        
        # Cleanup temp files
        Remove-Item -Path $tempOutput, $tempError -ErrorAction SilentlyContinue
        
        if ($process.ExitCode -eq 0) {
            Write-Log "SSH connection test successful"
            return $true
        } else {
            Write-Log "SSH connection failed: $error" -Level Error
            return $false
        }
    }
    catch {
        Write-Log "SSH test failed: $_" -Level Error
        return $false
    }
}


Export-ModuleMember -Function Test-SSHConnection