Describe 'PoSh Testing' {
    BeforeAll {
        function New-E2evc2023RomeJimPoSh {}
        $function = Get-Command New-E2evc2023RomeJimPoSh
    }
    It 'Must use an PowerShell approved verb.' {
        if (-not ($function.CommandType -eq 'Alias')) {
            $function.Verb | Should -BeIn ((Get-Verb).Verb) 
        }
    }

    It 'Must not use special characters in the name' {
        $function.Name | Should -Not -Match '[#\(\)\{\}\[\]&/\\$\^;:"''<>|\?@`*%+=~]' -Because "Cmdlet names should not contain special characters.`n`nDocumentation link:`nhttps://learn.microsoft.com/en-gb/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#cmdlet-names-characters-that-cannot-be-used-rd02"
    }

    It 'Must not contain two or more hyphens in the name' {
        $function.Name | Should -Not -Match '.*-.*-.*' -Because "Cmdlet names should not contain special characters.`n`nDocumentation link:`nhttps://learn.microsoft.com/en-gb/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#cmdlet-names-characters-that-cannot-be-used-rd02"
    }

    It 'Must use singular cmdlet Name.' {
        $function.Name | Should -Not -Match '.*(?:[^s|Statu|ou])s$' -Because "To enhance the user experience, the noun that you choose for a cmdlet name should be singular. For example, use the name Get-Process instead of Get-Processes. It is best to follow this rule for all cmdlet names, even when a cmdlet is likely to act upon more than one item.`n`nDocumentation link:`nhttps://learn.microsoft.com/en-gb/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-a-specific-noun-for-a-cmdlet-name-sd01"
    }
    
    It 'Must use Pascal Case for cmdlet name.' {
        $function.Name | Should -MatchExactly "^(?:[A-Z]{1,3}(?:[a-z0-9_])+[A-Z]{0,2})+-(?:[A-Z]{1,3}(?:[a-z0-9_])+[A-Z]{0,2})+$" 
    }
}
    