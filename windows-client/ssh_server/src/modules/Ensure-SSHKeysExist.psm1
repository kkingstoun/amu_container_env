Import-Module "$PSScriptRoot/Write-Log.psm1" -Force
Import-Module "$PSScriptRoot/Get-UserSID.psm1" -Force

function Ensure-SSHKeysExist {
    param (
        [string]$KeyFolderPath
    )

    function Get-OriginalUserName {
        try {
            $processes = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq "explorer.exe" }
            foreach ($process in $processes) {
                $ownerInfo = $process | Invoke-CimMethod -MethodName GetOwner
                if ($ownerInfo.Domain -ne $null) {
                    return "$($ownerInfo.Domain)\$($ownerInfo.User)"
                }
            }
        } catch {
            return $env:USERNAME
        }
    }    

    Write-Log "Checking for existing SSH keys in $KeyFolderPath..."

    # Ensure the folder exists
    if (-not (Test-Path -Path $KeyFolderPath)) {
        Write-Log "Creating directory $KeyFolderPath..."
        New-Item -ItemType Directory -Path $KeyFolderPath -Force | Out-Null
    }

    $privateKeyPath = Join-Path $KeyFolderPath "id_rsa"
    $publicKeyPath = Join-Path $KeyFolderPath "id_rsa.pub"

    if (-not (Test-Path -Path $privateKeyPath) -or -not (Test-Path -Path $publicKeyPath)) {
        Write-Log "SSH key pair not found. Generating new SSH key pair..."

        # Generate the key pair
        New-SSHKeyPair -privateKeyPath $privateKeyPath

        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to generate SSH keys." -Level Error
            throw "Failed to generate SSH keys."
        }
    } else {
        Write-Log "SSH key pair already exists."
    }

    # Set permissions on the key files
    Write-Log "Setting permissions on SSH key files..."

    # Get the current user
    $currentUserName = Get-OriginalUserName

    # Remove existing ACLs and set new ones
    $keyFiles = @($privateKeyPath, $publicKeyPath)
    foreach ($file in $keyFiles) {
        $acl = Get-Acl $file

        # Remove existing access rules
        $acl.SetAccessRuleProtection($true, $false)
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

        # Add access for current user
        $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUserName,
            'FullControl',
            'Allow'
        )
        $acl.AddAccessRule($userRule)

        # Add access for SYSTEM
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            'NT AUTHORITY\SYSTEM',
            'FullControl',
            'Allow'
        )
        $acl.AddAccessRule($systemRule)

        # Set the updated ACL
        Set-Acl -Path $file -AclObject $acl
    }

    Write-Log "Permissions set on SSH key files."
}

Export-ModuleMember -Function Ensure-SSHKeysExist