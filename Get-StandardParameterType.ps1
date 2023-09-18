$c = Get-Content .\StandardParameterNames.txt
$c = 'HostPoolName'
$all = foreach ($Name in $c) {
    try {
        $cmds = Get-Command -ParameterName $Name -ErrorAction Stop
    }
    catch {
        continue
    }
    

    $types = foreach ($cm in $cmds) {
        $cm.Parameters.Values | ForEach-Object {
            if ($_.Name -eq $Name) {
                Write-Output $_.ParameterType.Name
            }
        }
    }

    if (($types | Sort-Object -Unique | Measure-Object).Count -eq 1) {
        $singleType = [PSCustomObject]@{
            Name = $Name
            Type = $types | Sort-Object -Unique
        }
        Write-Output $singleType
    }
}

ConvertTo-Json $all | Out-File .\StandardParameterTypes.json