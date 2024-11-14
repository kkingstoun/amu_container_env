function Get-UserSID {
    param (
        [string]$Username
    )

    # Pobierz obiekt użytkownika
    $user = Get-LocalUser -Name $Username

    if ($null -eq $user) {
        throw "Użytkownik '$Username' nie został znaleziony."
    }

    return $user.SID.Value
}

Export-ModuleMember -Function Get-UserSID