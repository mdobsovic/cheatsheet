# Zoznamy s dátumami
**Zoznam používateľov s dátumom posledného prihlásenia na danom DC**
```pwsh
Get-ADUser -SearchBase "OU=Contoso,DC=int,DC=contoso,DC=com" -Filter * -Properties lastLogon | ft SamAccountName,Name,@{n="LastLogon";e={[DateTime]::FromFileTime($_.lastLogon)}}
```

**Zoznam používateľov s dátumom poslednej zmeny hesla**
```pwsh
Get-ADUser -SearchBase "OU=Contoso,DC=int,DC=contoso,DC=com" -Filter * -Properties pwdLastSet | ft SamAccountName,Name,@{n="LastLogon";e={[DateTime]::FromFileTime($_.pwdLastSet)}}
```

**Zoznam počítačov s dátumom posledného prihlásenia na danom DC**
```pwsh
Get-ADComputer-SearchBase "OU=Contoso,DC=int,DC=contoso,DC=com" -Filter * -Properties lastLogon | ft SamAccountName,Name,@{n="LastLogon";e={[DateTime]::FromFileTime($_.lastLogon)}}
```

**Zoznam počítačov s dátumom poslednej zmeny hesla**
```pwsh
Get-ADComputer -SearchBase "OU=Contoso,DC=int,DC=contoso,DC=com" -Filter * -Properties pwdLastSet | ft SamAccountName,Name,@{n="LastLogon";e={[DateTime]::FromFileTime($_.pwdLastSet)}}
```
# Zoznamy s členmi
**Zoznam skupín s členmi oddelenými čiarkou**
```pwsh
Get-ADGroup -SearchBase "OU=Contoso,DC=int,DC=contoso,DC=com" -Filter * | fl Name,@{n="Members";e={(Get-ADGroupMember -Identity $_ | Select -ExpandProperty SamAccountName) -Join ','}}
```

**Zoznam citlivých skupín s členmi oddelenými čiarkou**
```pwsh
$sensitiveGroups = @("Domain Admins","Enterprise Admins","Schema Admins","Key Admins","Enterprise Key Admins","Group Policy Creator Owners","Protected Users")
$sensitiveGroups | ForEach-Object {
    $groupName = $_
    $group = Get-ADGroup -Identity $groupName -ErrorAction SilentlyContinue
    if ($group) {
        $members = Get-ADGroupMember -Identity $groupName -Recursive | Where-Object { $_.objectClass -eq 'user' } | Select-Object -ExpandProperty SamAccountName
        $memberList = $members -join ", "
        [PSCustomObject]@{
            Group  = $groupName
            Members = if ($memberList) { $memberList } else { "No members" }
        }
    } else {
        [PSCustomObject]@{
            Group  = $groupName
            Members = "Group not found"
        }
    }
} | Format-Table -AutoSize
```
