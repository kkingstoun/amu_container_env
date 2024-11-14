# Wymagane uprawnienia administratora
#Requires -RunAsAdministrator
# Parametry konfiguracyjne
param(
    [Parameter(Mandatory=$true)]
    [string]$NewUsername,
    
    [Parameter(Mandatory=$true)]
    [SecureString]$NewUserPassword,

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [switch]$NoConfirm,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "$env:ProgramData\ssh\ssh_setup.log",

    [Parameter(Mandatory=$true)]
    [string]$sshKeyFolderPath = "C:\sshuser"
)
$Global:LogPath = $LogPath
Import-Module "$PSScriptRoot/modules/Write-Log.psm1" -Force
Import-Module "$PSScriptRoot\modules\SSHKeyManagement.psm1" -Force 
Import-Module "$PSScriptRoot\modules\Setup-UserSSHFolder.psm1" -Force
Import-Module "$PSScriptRoot\modules\Ensure-SSHKeysExist.psm1" -Force
Import-Module "$PSScriptRoot\modules\Test-SSHConnection.psm1" -Force
Import-Module "$PSScriptRoot\modules\Get-UserSID.psm1" -Force

function Test-UserExists {
    param([string]$Username)
    
    try {
        $user = Get-LocalUser -Name $Username -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Remove-UserIfExists {
    param([string]$Username)
    
    try {
        if (Test-UserExists -Username $Username) {
            Write-Log "Usuwanie istniejacego uzytkownika $Username..." -Level Warning
            
            # Sprawdź czy uzytkownik jest zalogowany
            $sessions = quser 2>$null | Where-Object { $_ -match $Username }
            if ($sessions) {
                Write-Log "Uzytkownik $Username jest obecnie zalogowany. Wymuszanie wylogowania..." -Level Warning
                logoff ($sessions -split '\s+')[2]
            }

            # Usuń uzytkownika z wszystkich grup
            $groups = Get-LocalGroup | Where-Object {
                $members = $_ | Get-LocalGroupMember -ErrorAction SilentlyContinue
                $members.Name -contains "$env:COMPUTERNAME\$Username"
            }
            
            foreach ($group in $groups) {
                Remove-LocalGroupMember -Group $group.Name -Member $Username -ErrorAction SilentlyContinue
                Write-Log "Usunieto uzytkownika z grupy $($group.Name)" -Level Info
            }

            # Usuń uzytkownika
            Remove-LocalUser -Name $Username -ErrorAction Stop
            Write-Log "Pomyslnie usunieto uzytkownika $Username" -Level Info
            return $true
        }
    }
    catch {
        Write-Log "Blad podczas usuwania uzytkownika: $_" -Level Error
        throw $_
    }
}

# Funkcja sprawdzajaca czy komponenty sa zainstalowane
function Test-OpenSSHInstalled {
    $sshFeatures = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'
    return ($sshFeatures | Where-Object State -eq 'Installed').Count -eq 2
}

function Get-ValidDescription {
    param(
        [string]$Description,
        [int]$MaxLength = 48
    )
    
    if ($Description.Length -gt $MaxLength) {
        return $Description.Substring(0, $MaxLength)
    }
    return $Description
}

function Format-ACL {
    param (
        [System.Security.AccessControl.FileSystemSecurity]$Acl,
        [string]$Title
    )
    
    # Print title with a newline
    Write-Host ""
    Write-Host "$Title" -ForegroundColor Cyan
    Write-Host "- Inheritance: $($Acl.AreAccessRulesProtected -eq $false)" -ForegroundColor Gray
    
    foreach ($ace in $Acl.Access) {
        Write-Host "   - $($ace.IdentityReference)" -ForegroundColor White
        Write-Host "      * Permissions: $($ace.FileSystemRights)" -ForegroundColor Gray
        Write-Host "      * Type: $($ace.AccessControlType)" -ForegroundColor Gray
        Write-Host "      * Inheritance: $($ace.InheritanceFlags)" -ForegroundColor Gray
    }
} # Zamknięcie funkcji Format-ACL


function Normalize-Whitespace {
    param([string]$input)
    return -join ($input -split '\s+')
}

function Show-ConfigComparison {
    param (
        [string[]]$OriginalContent,
        [string[]]$NewContent
    )

    # Maksymalna szerokość kolumny
    $maxWidth = 38

    # Ustalenie maksymalnej liczby wierszy (dla formatowania tabeli)
    $maxLines = [math]::Max($OriginalContent.Count, $NewContent.Count)

    # Nagłówki tabeli
    Write-Host "`n| Original sshd_config".PadRight($maxWidth) + " | New sshd_config".PadRight($maxWidth) + " |"
    Write-Host ("-" * ($maxWidth * 2 + 5))

    # Iteracja przez linie obu wersji i ich wyświetlanie
    for ($i = 0; $i -lt $maxLines; $i++) {
        # Pobierz linie lub pustą wartość, jeśli nie ma więcej linii
        $originalLine = if ($i -lt $OriginalContent.Count) { $OriginalContent[$i] } else { "" }
        $newLine = if ($i -lt $NewContent.Count) { $NewContent[$i] } else { "" }

        # Przycinanie lub łamanie linii do maksymalnej szerokości kolumny
        $originalLineFormatted = $originalLine.Substring(0, [math]::Min($originalLine.Length, $maxWidth))
        $newLineFormatted = $newLine.Substring(0, [math]::Min($newLine.Length, $maxWidth))

        # Wyświetlanie linii w kolumnach obok siebie
        if ($originalLine -eq $newLine) {
            # Linie są identyczne - bez kolorowania
            Write-Host "| $originalLineFormatted".PadRight($maxWidth) + " | $newLineFormatted".PadRight($maxWidth) + " |"
        } else {
            # Linie różnią się - kolorujemy każdą linię osobno
            Write-Host "| " -NoNewline
            Write-Host "$originalLineFormatted".PadRight($maxWidth) -ForegroundColor Yellow -NoNewline
            Write-Host " | " -NoNewline
            Write-Host "$newLineFormatted".PadRight($maxWidth) -ForegroundColor Green -NoNewline
            Write-Host " |"
        }
    }

    Write-Host ("-" * ($maxWidth * 2 + 5))
}

# Function to get the current SSH port from sshd_config or default to 22 if not specified
function Get-SSHPort {
    $config = Get-Content -Path "$env:ProgramData\ssh\sshd_config" -ErrorAction SilentlyContinue | 
              Select-String -Pattern "^Port\s+(\d+)" | 
              ForEach-Object { $_.Matches[0].Groups[1].Value }

    # Return the found port, or default to 22 if none is specified
    if ($config) {
        return [int]$config
    } else {
        return 22
    }
}
function Get-UserHomeDirectory {
    param (
        [string]$Username
    )

    # Pobierz obiekt użytkownika na podstawie pełnej nazwy
    $user = Get-LocalUser | Where-Object { $_.Name -eq $Username }

    if ($null -eq $user) {
        throw "Użytkownik '$Username' nie został znaleziony."
    }

    # Pobierz SID użytkownika
    $sid = $user.SID.Value

    # Ścieżka do klucza rejestru ProfileList dla danego SID
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid"

    if (Test-Path $regPath) {
        # Odczytaj ścieżkę katalogu domowego z rejestru
        $profileImagePath = (Get-ItemProperty -Path $regPath).ProfileImagePath
        return $profileImagePath
    }
    else {
        # Jeśli profil nie istnieje w rejestrze, załóż katalog domowy na podstawie pełnej nazwy użytkownika
        $defaultHomeDir = "C:\Users\$Username"
        return $defaultHomeDir
    }
}

try {
    Write-Log "Starting SSH server installation and configuration..."
    $sshKeyFolderPath = "C:\sshuser"  # Zmień na ścieżkę do docelowego folderu

    # Check if user exists
    if (Test-UserExists -Username $NewUsername) {
        if ($Force) {
            Remove-UserIfExists -Username $NewUsername
        }
        else {
            throw "User $NewUsername already exists. Use -Force to overwrite existing user."
        }
    }

    # 1. Install OpenSSH components
    if (-not (Test-OpenSSHInstalled)) {
        Write-Log "Installing OpenSSH components..."
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    }

    # 2. Configure SSH service
    Write-Log "Configuring SSH service..."
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'

    # 3. Create new user with limited permissions
    Write-Log "Creating new user for SSH access..."
    $userParams = @{
        Name = $NewUsername
        Password = $NewUserPassword
        PasswordNeverExpires = $true
        Description = "SSH access only - $(Get-Date -Format 'yyyyMMdd')"
    }
    $newUser = New-LocalUser @userParams
    
    $homeDirectory = Get-UserHomeDirectory -Username $NewUsername
    Write-Log "Ścieżka katalogu domowego użytkownika ${NewUsername}: ${homeDirectory}"

    # Uruchomienie sesji w celu inicjalizacji katalogu domowego
    try {
        # Utwórz obiekt poświadczeń (PSCredential) dla nowego użytkownika
        $Cred = New-Object System.Management.Automation.PSCredential ("$env:COMPUTERNAME\$NewUsername", $NewUserPassword)
        
        .\Run_As.ps1 -ScriptBlock { $env:USERPROFILE } -Credential $Cred -Wait
      
    } catch {
        Write-Log "Failed to launch session for directory initialization. Error: $_" -Level Error
        throw "Directory initialization failed for user $NewUsername."
    }
    
    if (Test-Path -Path $homeDirectory) {
        Write-Log "Home directory for $NewUsername initialized successfully at $homeDirectory."
    } else {
        Write-Log "Failed to initialize home directory for $NewUsername." -Level Error
        throw "Home directory initialization failed."
    }

    $sshGroup = "SSH Users"
    if (-not (Get-LocalGroup -Name $sshGroup -ErrorAction SilentlyContinue)) {
        New-LocalGroup -Name $sshGroup -Description "Users allowed to connect via SSH"
    }
    Add-LocalGroupMember -Group $sshGroup -Member $NewUsername


#     # 4. SSH folder permissions configuration
    Write-Log "Analyzing security permissions..."
    $sshFolder = "$env:ProgramData\ssh"

    # Show current permissions
    $currentAcl = Get-Acl $sshFolder
    Format-ACL -Acl $currentAcl -Title "CURRENT permissions for $($sshFolder)"

    # Prepare new permissions
    $newAcl = New-Object System.Security.AccessControl.DirectorySecurity
    $newAcl.SetAccessRuleProtection($true, $false)

    # Add permission for SYSTEM
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "NT AUTHORITY\SYSTEM",
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $newAcl.AddAccessRule($systemRule)

    # Add permission for Administrators
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "BUILTIN\Administrators",
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $newAcl.AddAccessRule($adminRule)

    # Show planned permissions
    Format-ACL -Acl $newAcl -Title "PLANNED permissions for $($sshFolder)"

    # Ask for user confirmation unless NoConfirm is specified
    if (-not $NoConfirm) {
        Write-Host "`nDo you want to apply these permission changes? (Y/N)" -ForegroundColor Yellow
        $response = Read-Host
    }

    if ($NoConfirm -or $response.ToUpper() -eq 'Y') {
        Write-Log "Applying new security permissions..."
        Set-Acl -Path $sshFolder -AclObject $newAcl
        Write-Log "Permissions have been updated"
    } else {
        Write-Log "Kept current permissions" -Level Warning
    }


    # 5. Configure sshd_config
    Write-Log "Configuring sshd_config..."
    $sshdConfigPath = "$env:ProgramData\ssh\sshd_config"
    
    # Tworzenie kopii zapasowej konfiguracji i zapisanie jej ścieżki
    if (Test-Path $sshdConfigPath) {
        $backupPath = "$sshdConfigPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item -Path $sshdConfigPath -Destination $backupPath
        Write-Log "Backup created for sshd_config at $backupPath"
    } else {
        Write-Log "No existing sshd_config file found to back up." -Level Warning
        $backupPath = $null
    }    

    # Desired configuration settings as a hashtable
    $desiredConfig = @{
        "PubkeyAuthentication" = "yes"
        "PasswordAuthentication" = "no"
        "PermitRootLogin" = "no"
        "AllowGroups" = "SSH Users"
        "Subsystem" = "sftp sftp-server.exe"
        "MaxAuthTries" = "3"
        "LoginGraceTime" = "60"
        "MaxStartups" = "3:50:10"
        "ClientAliveInterval" = "300"
        "ClientAliveCountMax" = "3"
    }

    # Read the current configuration file into an array of lines
    $currentConfig = @{}
    if (Test-Path $sshdConfigPath) {
        $fileLines = Get-Content -Path $sshdConfigPath
        foreach ($line in $fileLines) {
            if ($line -match '^\s*#' -or $line -match '^\s*$') { continue } # Skip comments and empty lines
            $parts = $line -split '\s+', 2
            if ($parts.Count -eq 2) {
                $currentConfig[$parts[0]] = $parts[1]
            }
        }
    }

    # Prepare new configuration content with user confirmation
    $newConfig = @()
    $configDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $newConfig += "# Secure SSH Server Configuration"
    $newConfig += "# Created: $configDate"
    $newConfig += "# Created by: $env:USERNAME"
    $newConfig += ""

    # Compare and ask for each configuration setting
    foreach ($key in $desiredConfig.Keys) {
        if ($currentConfig.ContainsKey($key)) {
            # Normalize whitespace for comparison
            $currentValue = Normalize-Whitespace $current
            # Setting exists - check if it differs
            if ($currentConfig[$key] -ne $desiredConfig[$key]) {
                Write-Host "`nSetting '$key' is set to '$($currentConfig[$key])', but the desired value is '$($desiredConfig[$key])'." -ForegroundColor Yellow
                $response = Read-Host "Do you want to update '$key' to '$($desiredConfig[$key])'? (Y/N)"
                if ($response -match '^[Yy]') {
                    $newConfig += "$key $($desiredConfig[$key])"
                } else {
                    $newConfig += "$key $($currentConfig[$key])"
                }
            } else {
                # Setting matches desired value
                $newConfig += "$key $($desiredConfig[$key])"
            }
        } else {
            # Setting does not exist, ask to add it
            Write-Host "`nSetting '$key' is missing from the configuration." -ForegroundColor Yellow
            $response = Read-Host "Do you want to add '$key $($desiredConfig[$key])'? (Y/N)"
            if ($response -match '^[Yy]') {
                $newConfig += "$key $($desiredConfig[$key])"
            }
        }
    }

    # Write the final configuration to the file
    $newConfig | Set-Content -Path $sshdConfigPath -Force
    if ($backupPath) {
        $originalContent = Get-Content -Path $backupPath
        $newContent = Get-Content -Path $sshdConfigPath
        Show-ConfigComparison -OriginalContent $originalContent -NewContent $newContent
    } else {
        Write-Log "Comparison skipped as no backup was created." -Level Warning
    }

    # 7. Check and configure SSH port
    Write-Log "Checking SSH port configuration..."

    # Get the current SSH port (default to 22 if not explicitly set in sshd_config)
    $currentPort = Get-SSHPort
    Write-Log "Current SSH port: $currentPort"

    # Check if the port is set to the default value of 22
    if ($currentPort -eq 22) {
        Write-Host "`nWarning: Using default SSH port (22) might be less secure" -ForegroundColor Yellow
        Write-Host "Recommended port range: 1024-65535" -ForegroundColor Cyan
        
        if (-not $NoConfirm) {
            $response = Read-Host "Would you like to change the SSH port? (Y/N)"
            if ($response.ToUpper() -eq 'Y') {
                do {
                    $newPort = Read-Host "Enter new port number (1024-65535)"
                    $validPort = $newPort -match '^\d+$' -and [int]$newPort -ge 1024 -and [int]$newPort -le 65535
                    
                    if (-not $validPort) {
                        Write-Host "Invalid port number. Please use a number between 1024 and 65535" -ForegroundColor Red
                    } else {
                        # Check if the port is already in use
                        $inUse = (Test-NetConnection -Port $newPort -InformationLevel Detailed).TcpTestSucceeded
                        if ($inUse) {
                            Write-Host "The port $newPort is already in use. Please choose another one." -ForegroundColor Red
                            $validPort = $false
                        }
                    }
                } while (-not $validPort)

                # Backup sshd_config before modification
                $backupPath = "$sshdConfigPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Copy-Item -Path $sshdConfigPath -Destination $backupPath -ErrorAction SilentlyContinue
                Write-Log "Backup created for sshd_config at $backupPath"

                # Update sshd_config with the new port
                $content = Get-Content $sshdConfigPath -ErrorAction SilentlyContinue
                $content = $content | ForEach-Object { 
                    if ($_ -match '^Port\s+\d+') {
                        "Port $newPort"
                    } else {
                        $_
                    }
                }
                if (-not ($content | Select-String '^Port')) {
                    $content = @("Port $newPort") + $content
                }
                $content | Set-Content $sshdConfigPath

                # Configure Windows Firewall with a unique rule for the new port
                $ruleName = "SSH Server (port $newPort)"
                $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
                
                if ($existingRule) {
                    Remove-NetFirewallRule -DisplayName $ruleName
                }
                
                New-NetFirewallRule -Name "SSH-Server-In-TCP-$newPort" `
                                -DisplayName $ruleName `
                                -Direction Inbound `
                                -Protocol TCP `
                                -LocalPort $newPort `
                                -Action Allow

                Write-Log "Updated SSH port to $newPort and configured firewall rule"
                Write-Log "Please restart the SSH service for changes to take effect"
            }
        }
    }

    # Restart SSH service if changes were made
    if ($differences.Count -gt 0 -or $currentPort -ne $newPort) {
        Write-Log "Restarting SSH service to apply changes..."
        try {
            Restart-Service sshd -ErrorAction Stop
            Write-Log "SSH service restarted successfully"
        } catch {
            Write-Log "Failed to restart SSH service: $_" -Level Error
        }
        Write-Log "SSH service restarted successfully"
    }

    Write-Log "Installation and configuration completed successfully!"
    Write-Log "IMPORTANT: Remember to add SSH public keys for the new user in the folder: C:\Users\$NewUsername\.ssh\authorized_keys"

        
    #########################################################
    ## 8. Generate SSH key (id_rsa) if it doesn't exist
    #########################################################

    Ensure-SSHKeysExist -KeyFolderPath $sshKeyFolderPath
    # Get the path to the public key
    $publicKeyPath = Join-Path $sshKeyFolderPath "id_rsa.pub"
    $userKeyPath = Join-Path $sshKeyFolderPath "id_rsa"
    $userSID = Get-UserSID -Username $NewUsername
    try {
        $userSIDObject = New-Object System.Security.Principal.SecurityIdentifier($userSID)
        $ntAccount = $userSIDObject.Translate([System.Security.Principal.NTAccount])
        Write-Log "Resolved SID to NTAccount: $($ntAccount.Value)"
    } catch {
        Write-Log "Failed to resolve SID to NTAccount: $_" -Level Error
        throw $_
    }

    # # 8.2 Set up .ssh folder for the new user and add the public key
    Setup-UserSSHFolder -HomeDirectory $homeDirectory -Username $NewUsername -PublicKeyPath $publicKeyPath

    # # 9. Test SSH connection using the generated key
    if (-not (Test-SSHConnection -Username $NewUsername -KeyPath $userKeyPath)) {
        Write-Log "Final SSH connection test failed" -Level Error
        throw "SSH setup validation failed"
    }
    Write-Log "SSH setup completed successfully"

} catch {
    Write-Log "ERROR: $_" -Level Error
    throw $_
}