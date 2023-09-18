function Test-Cmdlet {
    [OutputType([System.Boolean])]
    [CmdletBinding()]

    Param (
        [Parameter(
            Position = 0,
            ValuefromPipelineByPropertyName = $true,
            ValuefromPipeline = $true,
            Mandatory = $true
        )]
        [System.String[]]$Name,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [Switch]$AddOptionalTests,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateSet('Failed', 'Detailed', 'Summary', 'Boolean')]
        [String]$Output = 'Boolean',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateRange(0, 512)]
        [Int32]$MaxParameters = 30
    )

    begin {
        #requires -Modules @{ModuleName = 'Pester'; ModuleVersion = '5.0.0'}
        #Set-StrictMode -Version Latest

    } # begin
    process {

        foreach ($cmdlet in $Name) {

            $pesterScriptblock = {

                Describe "Test-Cmdlet" {

                    BeforeAll {

                        $verbs = (Get-Verb).Verb
                        $function = Get-Command -Name $cmdlet
                        $builtinParameters = @(
                            'Verbose',
                            'Debug',
                            'ErrorAction',
                            'WarningAction',
                            'InformationAction',
                            'ErrorVariable',
                            'WarningVariable',
                            'InformationVariable',
                            'OutVariable',
                            'OutBuffer',
                            'PipelineVariable'
                        )
                        $parameters = $function.Parameters.Values | Where-Object { $builtinParameters -notcontains $_.Name }
                    }
        
                    Context 'General' {
                        It 'Must use an PowerShell approved verb.' {
                            if (-not ($function.CommandType -eq 'Alias')) {
                                $function.Verb | Should -BeIn $verbs -Because "You must choose an appropriate verb for your cmdlet.`n`nTo ensure consistency between the cmdlets that you create, the cmdlets that are provided by PowerShell, and the cmdlets that are designed by others.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3#verb-naming-recommendations"
                            }
                        }
        
                        It 'Must have a help page uri.' {
                            $function.helpuri | Should -Not -BeNullOrEmpty -Because "Every cmdlet should have an online help page`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.3#helpuri"
                        }
        
                        It 'Has a valid help page.' {
                            try {
                                $response = Invoke-WebRequest -Uri $function.helpuri -ErrorAction Stop | Select-Object -ExpandProperty StatusCode
                            }
                            catch {
                                $response = $_.Exception.Response.StatusCode
                            }
                            $response | Should -Be 200 -Because "Every cmdlet should have an online help page`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_cmdletbindingattribute?view=powershell-7.3#helpuri"
                        }
        
                        It 'Must use singular parameter Name.' {
                            $function.Name | Should -Not -Match '.*(?:[^s|statu])s$' -Because "Avoid using plural names for parameters whose value is a single element. This includes parameters that take arrays or lists because the user might supply an array or list with only one element.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-singular-parameter-names"
                        }
        
                        It 'Must use Pascal Case for cmdlet name. https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-pascal-case-for-cmdlet-names-sd02' {
                            $function.Name | Should -MatchExactly "^(?:[A-Z]{1,3}(?:[a-z0-9_])+[A-Z]{0,2})+-(?:[A-Z]{1,3}(?:[a-z0-9_])+[A-Z]{0,2})+$" -Because "Use Pascal case for cmdlet names.`nIn other words, capitalize the first letter of verb and all terms used in the noun. For example, `"Clear-ItemProperty`"`n`nDocumentation link:`nhttps://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-pascal-case-for-cmdlet-names-sd02"
                        }
        
                        It 'Must use Pascal Case for parameter name.' {
                            $parameters.Name | Should -MatchExactly '^(?:[A-Z]{1,3}(?:[a-z0-9_])+[A-Z]{0,2})+$' -Because "Use Pascal case for parameter names.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-pascal-case-for-parameter-names"
                        }
        
                        It -Tag Optional 'In most cases, Add, Set, and New cmdlets should support a PassThru parameter.' {
                            if ('Add', 'Set', 'New' -contains $function.Verb) {
                                $parameters | Where-Object { $_.Name -eq 'PassThru' } | Should -Not -BeNullOrEmpty -Because "By default, many cmdlets that modify the system, such as the Stop-Process cmdlet, act as `"sinks`" for objects and do not return a result. These cmdlets should implement the PassThru parameter to force the cmdlet to return an object.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-the-passthru-parameter"
                            }
                        }
        
                        It -Tag Optional 'Do not use parameters too close to Standard Parameter Names and Types.' {
                            $stdParams = Get-Content StandardParameterNames.txt
                            foreach ($param in $parameters) {
                                if ($stdParams -notcontains $param.Name) {
                                    foreach ($stdParam in $stdParams) {
                                        if ($parameters.Name -notcontains $stdParam) {
                                            $param.Name | Should -Not -BeLike "*$stdParam*" -Because "Cmdlet parameter names should be consistent across the cmdlets that you design.`nThe following topics list the parameter names that we recommend you use when you declare cmdlet parameters. The topics also describe the recommended data type and functionality of each parameter.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/standard-cmdlet-parameter-names-and-types?view=powershell-7.3"
                                        }
                                    }
                                }
                            }
                        }
        
                        It 'Must have a Force parameter if you set your ConfirmImpact to high' {
                            if ($function.CommandType -ne 'cmdlet' -and $function.ScriptBlock -match "ConfirmImpact\s*=\s*`[`"|'`]High`[`"|'`]" -and $parameters.Name -contains 'Confirm') {
                                $parameters | Where-Object { $_.Name -eq 'Force' } | Should -Not -BeNullOrEmpty -Because "If you set your ConfirmImpact to high, you should allow your users to suppress it with -Force.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7.3#shouldprocess--force"
                            }
                        }

                        It 'Should not use the verb Invoke' {
                            $function.Verb | Should -Not -Be 'Invoke' -Because "Uses the verb Invoke. Use the verb to describe the general scope of the action, and use parameters to further refine the action of the cmdlet. It is unlikely that there is not a more specific verb than Invoke.`n`nDocumentation link:`nhttps://learn.microsoft.com/en-gb/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3#verb-naming-recommendations"
                        } 
                    }
            
                    Context 'Input' {
        
                        It -Tag AutoRest 'Parameter must accept input (DontShow).' {
                            $noShowParams = foreach ($param in $parameters) { 
                                if ($null -ne $param.Attributes.DontShow -and $param.Attributes.DontShow -eq $true) {
                                        Write-Output $param.Name
                                }
                            } 
                            $noShowParams | Should -BeNullOrEmpty -Because "Does not contain do not show based parameters. This property should be rarely used, and only for short recursive functions which call itself.`n`nThe Parameters which need fixing are:`n $($noShowParams -Join ', ')`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-parameters?view=powershell-7.3`nhttps://www.oreilly.com/library/view/mastering-windows-powershell/9781789536669/b491800b-4991-471c-a26a-e5db1f68a083.xhtml"
                        }
        
                        It -Tag AutoRest 'Parameter must accept input. Does not contain non functional parameters.' {
                            #The following Regex should show you all the parameters that the function has extrated from the API has documented as non-functional 
                            #I've found the list produced to match the array above 
                            #you can identify them by the text 'parameter is not functional'.
                            $nonFunctionalParams = $function.Definition |
                            Select-String -AllMatches "\s+\#\sThe\s\w+\sparameter\sis\snot\sfunctional\.\r\n.*\r\n\s+\$\{(\w+)\}" | 
                            ForEach-Object { $_.matches.Groups } | 
                            Where-Object { $_.Name -eq 1 } | 
                            Select-Object -ExpandProperty Value
                            $nonFunctionalParams | Should -BeNullOrEmpty -Because "Does not contain non functional parameters.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-parameters?view=powershell-7.3"
                        }
        
                        It 'Do not use mandatory parameters for Get cmdlets.' {
                            if ($function.Verb -eq 'Get') {
                                $defaultParams = foreach ($param in $parameters) {   
                                    $param.ParameterSets.GetEnumerator() | Where-Object { $_.key -eq $function.DefaultParameterSet }
                                    $param.ParameterSets.GetEnumerator() | Where-Object { $_.key -eq '__AllParameterSets' }
                                }
                        
                                $defaultParams | Where-Object { $_.Attributes.Mandatory -eq $true } | Should -BeNullOrEmpty -Because "Get cmdlets should be able to run without any user input.`n`nThis guidance is more of a best practice derived from the nature of Get cmdlets in PowerShell, which are typically used to retrieve information and should be able to run without any user input. However, it is not explicitly stated in the official PowerShell documentation. The closest related information can be found in the Types of Cmdlet Parameters page on Microsoft Learn. It explains how to define mandatory parameters, but does not specifically mention that Get cmdlets should not have them."
                            }
                        }
        
                        It 'Must have positional parameters for the most used inputs' {
                            $positionalParams = foreach ($param in $parameters) { 
                                if ($param.Attributes.Position -ne -2147483648) { 
                                    $param.Attributes.Position 
                                } 
                            }
                            $positionalParams | Should -Not -BeNullOrEmpty -Because "Good cmdlet design recommends that the most-used parameters be declared as positional parameters.`nThe user then does not need to have to enter the parameter name when the cmdlet is run. If the cmdlet has several mandatory parameters consider setting them as positional, up to a maximum of 4.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/types-of-cmdlet-parameters?view=powershell-7.3#positional-and-named-parameters"
                        }
        
                        It -Tag Optional 'Uses Strongly-Typed .NET Framework Types for Parameters.' {
                            $parameters | Where-Object { $_.ParameterType.Name -ne "String" } | Should -Not -BeNullOrEmpty -Because "This cmdlet seems to only take String parameters, string parameters should only be used for free form text entry, anything else should use Types.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-strongly-typed-net-framework-types"
                        }
        
                        It 'Should Not have Parameters That Take True and False (Boolean Version).' {
                            $parameters | Where-Object { $_.ParameterType.Name -eq 'Boolean' } | Where-Object Name -ne 'All' | Should -BeNullOrEmpty -Because "Switch Parameters should be used instead of boolean except in the case of an `"All`" parameter.`n`n$($_.Name)`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#parameters-that-take-true-and-false"
                        }
        
                        It 'Should Not have Parameters That Take True and False (Validate Set Version).' {
                            $notSwitchTest = foreach ($param in $parameters) { 
                                if ($null -ne $param.Attributes.ValidValues) {
                                    if ((Compare-Object $param.Attributes.ValidValues -DifferenceObject $true, $false -IncludeEqual).Count -eq 2) { Write-Output 'NotSwitch' }
                                }
                            }
                            $notSwitchTest | Should -BeNullOrEmpty -Because "Switch Parameters should be used instead of boolean except in the case of an `"All`" parameter.`n`n$($_.Name)`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#parameters-that-take-true-and-false"
                        }
        
                        It 'Supports pipeline input in any way.' {
                            $pipeParams = foreach ($param in $parameters) { if ($param.attributes.ValueFromPipeline -eq $true -or $param.attributes.ValueFromPipelineByPropertyName -eq $true) { 'PipeTrue' } }
                            $pipeParams | Should -Not -BeNullOrEmpty -Because "Powershell cmdlets should be expected to be run in the middle of a pipeline.`nIn each parameter set for a cmdlet, include at least one parameter that supports input from the pipeline. Support for pipeline input allows the user to retrieve data or objects, to send them to the correct parameter set, and to pass the results directly to a cmdlet.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-input-from-the-pipeline"
                        } 
        
                        It -Tag WIP 'Supports an InputObject Parameter.' {
                            $inputObjectParams = foreach ($param in $parameters) { if ($param.Name -eq 'InputObject') { 'InputObject' } }
                            $inputObjectParams | Should -Not -BeNullOrEmpty -Because "Windows PowerShell works directly with Microsoft .NET Framework objects, a .NET Framework object is often available that exactly matches the type the user needs to perform a particular operation. InputObject is the standard name for a parameter that takes such an object as input. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/advisory-development-guidelines?view=powershell-7.3#support-an-inputobject-parameter-ad01"
                        }
        
                        It 'Test Cmdlets Should Return an object of type Boolean.' {
                            if ($function.Verb -eq 'Test') {
                                $function.OutputType.Name | Should -Be 'System.Boolean' -Because "Cmdlets that perform tests against their resources should return a System.Boolean type to the pipeline so that they can be used in conditional expressions.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/advisory-development-guidelines?view=powershell-7.3#test-cmdlets-should-return-a-boolean-ad05"
                            }
                        }
        
                        It 'If Path is a parameter it should have the PSPath alias.' {
                            if ($parameters.Name -contains 'Path') {
                                $pathParam = $parameters | Where-Object { $_.Name -eq 'Path' }
                                $pathParam.Aliases | Should -Contain 'PSPath' -Because "This alias ensures that when working with different PowerSherll providers pipelining works.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-windows-powershell-paths"
                            }
                        }
        
                        It 'If Path is a parameter it should have the string type. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-windows-powershell-paths' {
                            if ($parameters.Name -contains 'Path') {
                                $pathParam = $parameters | Where-Object { $_.Name -eq 'Path' }
                                $pathParam.ParameterType.Name | Should -BeLike 'String*'
                            }
                        }
        
                        It 'If Uri is a parameter it should have the System.Uri type. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-strongly-typed-net-framework-types' {
                            if ($parameters.Name -contains 'Uri') {
                                $pathParam = $parameters | Where-Object { $_.Name -eq 'Uri' }
                                $pathParam.ParameterType.Name | Should -Be 'Uri'
                            }
                        }
        
                        It -Tag Optional 'Validates input where possible (Validate Range).' {
                            foreach ($param in $parameters) {
                                #Ignoring byte types as range is implied there.
                                #Range needs to be Int64, so can't test 'UInt64', 'IntPtr', 'UIntPtr'
                                $numberTypes = @('Int16', 'UInt16', 'Int32', 'UInt32', 'Int64')
                                if ($numberTypes -contains $param.ParameterType.Name) {
                                    $param.Attributes.MinRange | Should -Not -BeNullOrEmpty -Because "This ensures the user receives the correct error message as early as possible.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/validating-parameter-input?view=powershell-7.3#validaterange"
                                    $param.Attributes.MaxRange | Should -Not -BeNullOrEmpty -Because "This ensures the user receives the correct error message as early as possible.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/validating-parameter-input?view=powershell-7.3#validaterange"
                                }
                            }
                        }
        
                        It 'Makes sure that the type described by input object is valid. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/advisory-development-guidelines?view=powershell-7.3#support-an-inputobject-parameter-ad01' {
                            if ($parameters.Name -contains 'InputObject') {
                                $inputObjectParam = $parameters | Where-Object { $_.Name -eq 'InputObject' }
        
                                { $inputObjectParam.ParameterType } | Should -Not -Throw
        
                            }
                        }
        
                        It -Tag Test "A cmdlet should not have too many parameters. For a better user experience, limit the number of parameters." {
                            $parameters.Count | Should -BeLessThan ($MaxParameters + 1) -Because "Cmdlet has $($parameters.Count) parameters.`nThis should be simplified or split into multiple cmdlets. Max Tested was $MaxParameters.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3#remarks"
                        }
        
                        It 'When you specify positional parameters, limit the number of positional parameters in a parameter set to less than five. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3#remarks' {
                            foreach ($set in $function.ParameterSets) {
                                $positionalParams = foreach ($param in $set.Parameters) { 
                                    if ($param.attributes.position -ne -2147483648) { 
                                        Write-Output "Positional Parameter $($param.attributes.position): $($param.Name)"
                                    } 
                                }
                                $positionalParams | Measure-Object | Select-Object -ExpandProperty Count | Should -BeLessThan 5 
                            }
                        }
        
                        It 'Each parameter set other than default must have at least one unique mandatory parameter. If your cmdlet is designed to be run without parameters, the unique parameter cannot be mandatory. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3#remarks' {
                            if ($function.ParameterSets.Count -gt 1 -and $parameters.Attributes.Mandatory -contains $true) {
        
                                $nonDefaultSets = $function.ParameterSets | Where-Object { $_.IsDefault -ne $true }
        
                                foreach ($set in $nonDefaultSets) {
        
                                    $setParams = foreach ($param in $parameters) {
                                        if ($null -ne ($param.ParameterSets.GetEnumerator() | Where-Object { $_.key -eq $set.Name })) {
                                            Write-Output $param
                                        }
                                    }
                         
                                    $mandatoryParams = foreach ($param in $setParams) {
        
                                        if ($param.Attributes.Mandatory) { 
                                            Write-Output "Mandatory Parameter: $($param.Name)"
                                        } 
                                    }
                                    $mandatoryParams | Measure-Object | Select-Object -ExpandProperty Count | Should -BeGreaterThan 0
                                }
                            }
                        }
        
                        It 'No parameter set should contain more than one positional parameter with the same position. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3#remarks' {
                            foreach ($set in $function.ParameterSets) {
                                $positionalParams = foreach ($param in $set.Parameters) { 
                                    if ($param.Attributes.position -ne -2147483648) { 
                                        $param.Attributes.position | Select-Object -First 1
                                    } 
                                }
                        ($positionalParams | Sort-Object -Unique).Count | Should -Be $positionalParams.Count
                            }
                        }
        
                        It 'Only one parameter in a parameter set should declare ValueFromPipeline = true. ' {
                            foreach ($set in $function.ParameterSets) {
                                $pipeParams = foreach ($param in $set.Parameters) { 
                                    if ($param.Attributes.ValueFromPipeline -eq $true) { 
                                        Write-Output "$($param.Name)"
                                    } 
                                }
                                $paramList = $pipeParams -join ', '
                                $pipeParams.Count | Should -BeLessThan 2 -Because "Parameter Set $set has multiple parameters that accept pipeline input. The conflicting parameters are: $paramList`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3"
                            }
                        }
        
                        It -Tag WIP 'Support Parameter Sets when necessary. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-parameter-sets' {
                            #$function.ParameterSets.Count | Should -BeGreaterThan 1
                        }
        
                        It -Tag WIP 'Has a default Parameter set when Powershell does not have enough information to determine which parameter set to use. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#specify-the-cmdlet-attribute-rc02' {
        
                        }
        
                        It -Tag WIP 'Supports arrays for Parameters where appropriate. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-arrays-for-parameters' {
        
                        }
                    }
        
                    Context 'Output' {
        
                        It 'Specify the OutputType Attribute.' {
                            $function.OutputType | Should -Not -BeNullOrEmpty -Because "By specifying the output type of your cmdlets you make the objects returned by your cmdlet more discoverable by other cmdlets.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#specify-the-outputtype-attribute-rc04"
                        }
        
                        It -Tag Test 'OutputType Attribute must be valid. ' {
                            $typeTest = foreach ($type in $function.OutputType.Type) {
                                if ($null -ne $type.BaseType) {
                                    Write-Output $type.ToString()
                                }
                            }
                            $typeTest | Should -Not -BeNullOrEmpty -Because "$type is specified as the output and does not exist.`n`nThe OutputType attribute identifies the .NET Framework types returned by a cmdlet, function, or script. By specifying the output type of your cmdlets you make the objects returned by your cmdlet more discoverable by other cmdlets.`n`nDocumention link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/outputtype-attribute-declaration?view=powershell-7.3"
                        }
        
                        It -Tag WIP 'Displays appropriate output properties by default. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/custom-formatting-files?view=powershell-7.3#format-views' {
        
                        }
                    }
                }
            }

            $pesterConfig = New-PesterConfiguration
            $pesterConfig.Run.ScriptBlock = $pesterScriptblock
            $pesterConfig.Run.Passthru = $true
            $pesterConfig.Output.Verbosity = 'None'
            #$pesterConfig.Filter.Tag = 'Test'
        
            if ($AddOptionalTests) {
                $pesterConfig.Filter.ExcludeTag = 'WIP'
            }
            else {
                $pesterConfig.Filter.ExcludeTag = 'WIP', 'Optional'
            }

            $fullResult = Invoke-Pester -Configuration $pesterConfig

            switch ($Output) {
                Boolean {
                    if ($fullResult.Result -ne 'Passed') {
                        $testOutput = $false
                    }
                    else {
                        $testOutput = $true
                    }
                    break 
                }
                Summary {
                    $testOutput = [PSCustomObject]@{
                        Name        = $cmdlet
                        PassedCount = $fullResult.PassedCount
                        FailedCount = $fullResult.FailedCount
                    }
                    break
                }
                Failed {
                    if ($fullResult.FailedCount -gt 0) {
                        $testOutput = [PSCustomObject]@{
                            Name   = $cmdlet
                            Failed = foreach ($test in $fullResult.Failed) {
                                if ($test.ErrorRecord[0].ToString().Split(', but got ')[0] -Match "^Expected .* because ((?:.*\n*)*)"){
                                    $explanation = $Matches[1]
                                }
                                else {
                                    $explanation = $test.ErrorRecord[0].ToString()
                                }
                                [PSCustomObject]@{
                                    Name    = $test.Name
                                    Explanation = $explanation
                                }
                            }    

                        }
                    }
                    
                    else {
                        $testOutput = $null
                    }
                    break
                }
                Detailed {
                    $fullResult | Add-Member -MemberType NoteProperty -Name Name -Value $cmdlet
                    $testOutput = $fullResult
                    break
                }
                Default {}
            }   
        
            Write-Output $testOutput
        }
    } # process
    end {} # end
}  #function Test-Cmdlet