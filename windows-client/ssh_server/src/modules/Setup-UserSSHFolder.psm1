Import-Module "$PSScriptRoot/Write-Log.psm1" -Force
Import-Module "$PSScriptRoot/Get-UserSID.psm1" -Force

function Setup-UserSSHFolder {
    param (
        [string]$Username,
        [string]$PublicKeyPath,
        [string]$homeDirectory
    )
    
    Write-Log "Setting up .ssh folder for user $Username..."
        
    # Path to the .ssh folder
    $sshFolderPath = Join-Path $homeDirectory ".ssh"
    
    # Ensure the .ssh folder exists
    if (-not (Test-Path -Path $sshFolderPath)) {
        Write-Log "Creating directory $sshFolderPath..."
        New-Item -ItemType Directory -Path $sshFolderPath -Force | Out-Null
    }
    
    # Create empty files known_hosts and authorized_keys if they don't exist
    $knownHostsPath = Join-Path $sshFolderPath "known_hosts"
    if (-not (Test-Path -Path $knownHostsPath)) {
        New-Item -ItemType File -Path $knownHostsPath -Force | Out-Null
    }
    
    $authorizedKeysPath = Join-Path $sshFolderPath "authorized_keys"
    if (-not (Test-Path -Path $authorizedKeysPath)) {
        New-Item -ItemType File -Path $authorizedKeysPath -Force | Out-Null
    }
    
    #Append the public key to authorized_keys
    Write-Log "Adding public key to $authorizedKeysPath..."
    Get-Content -Path $PublicKeyPath | Add-Content -Path $authorizedKeysPath
    
    # Set permissions on authorized_keys
    Write-Log "Setting permissions on $authorizedKeysPath..."
    
    # Get the user's SID
    $userSID = Get-UserSID -Username $Username
    
    # Convert the SID string to a SecurityIdentifier object
    $userSIDObject = New-Object System.Security.Principal.SecurityIdentifier($userSID)
    
    # Build the ACL
    $acl = New-Object System.Security.AccessControl.FileSecurity
    
    # # Remove existing access rules
    $acl.SetAccessRuleProtection($true, $false)
    $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
    
    # # Add access for the user using the SecurityIdentifier
    $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $userSIDObject,
        'Read,Write',
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
    
    # Set the ACL
    Set-Acl -Path $authorizedKeysPath -AclObject $acl
    
    Write-Log "Permissions set on $authorizedKeysPath."
}
Export-ModuleMember -Function Setup-UserSSHFolder
