Import-Module "$PSScriptRoot/Write-Log.psm1"

function New-SSHKeyPair {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$privateKeyPath,
        [string]$keyType = "rsa",
        [int]$keyBits = 4096
    )

    try {
        Write-Log "Generating SSH key pair at: $privateKeyPath"
        
        $process = Start-Process -FilePath "ssh-keygen" -ArgumentList @(
            "-t", $keyType,
            "-b", $keyBits,
            "-f", $privateKeyPath,
            "-N", '""',
            "-q"
        ) -NoNewWindow -Wait -PassThru

        if ($process.ExitCode -ne 0) {
            throw "ssh-keygen failed with exit code: $($process.ExitCode)"
        }

        if (-not (Test-Path -Path $privateKeyPath)) {
            throw "Private key not generated at: $privateKeyPath" 
        }

        Write-Log "SSH key pair generated successfully"
        return $true
    }
    catch {
        Write-Log "Failed to generate SSH key pair: $_" -Level Error
        throw
    }
}

Export-ModuleMember -Function New-SSHKeyPair