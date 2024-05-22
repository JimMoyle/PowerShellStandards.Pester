<#
.SYNOPSIS
    Tests a PowerShell cmdlet against a set of standards.

.DESCRIPTION
    The Test-Cmdlet function tests a PowerShell cmdlet against a set of standards to ensure that it meets the best practices for cmdlet development. The function checks the cmdlet's verb, help page URI, parameter names, and other properties to ensure that they meet the recommended guidelines.

.PARAMETER Name
    Specifies the name of the cmdlet to test.

.PARAMETER AddOptionalTest
    Specifies whether to add an optional test to the set of standards.

.PARAMETER Output
    Specifies the type of output to return. The default value is 'Boolean'.

.PARAMETER ParametersMax
    Specifies the maximum number of parameters that the cmdlet can have. The default value is 30.

.OUTPUTS
    The function returns a Boolean value that indicates whether the cmdlet meets the set of standards.

.EXAMPLE
    PS C:\> Test-Cmdlet -Name Get-Process

    This example tests the Get-Process cmdlet against a set of standards to ensure that it meets the recommended guidelines.

.LINK

    https://github.com/JimMoyle/PowerShellStandards.Pester#readme

.NOTES
    Author: Jim Moyle
    Date:   October 2023
#>
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
        [Switch]$AddOptionalTest,

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateSet('Failed', 'Detailed', 'Summary', 'Boolean')]
        [String]$Output = 'Boolean',

        [Parameter(
            ValuefromPipelineByPropertyName = $true
        )]
        [ValidateRange(0, 512)]
        [Int32]$ParametersMax = 30
    )

    begin {
        #requires -Modules @{ModuleName = 'Pester'; ModuleVersion = '5.0.0'}
        #Set-StrictMode -Version Latest

    } # begin
    process {

        foreach ($cmdlet in $Name) {

            $pesterScriptblock = {

                Describe "Test-Cmdlet" {


                    BeforeDiscovery {
                        $function = Get-Command -Name $cmdlet
                        if (($function.ScriptBlock | Measure-Object).Count -eq 0) {
                            $compiled = $true
                        }
                    }


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
                            'PipelineVariable',
                            'UseTransaction'
                        )
                        $parameters = $function.Parameters.Values | Where-Object { $builtinParameters -notcontains $_.Name }
                    }
        
                    Context 'General' {
                        It 'Must use an PowerShell approved verb.' {
                            if (-not ($function.CommandType -eq 'Alias')) {
                                $function.Verb | Should -BeIn $verbs -Because "You must choose an appropriate verb for your cmdlet.`n`nTo ensure consistency between the cmdlets that you create, the cmdlets that are provided by PowerShell, and the cmdlets that are designed by others.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3#verb-naming-recommendations"
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
                        
                        It 'Must use Pascal Case for cmdlet name. https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-pascal-case-for-cmdlet-names-sd02' {
                            $function.Name | Should -MatchExactly "^(?:[A-Z]{1,3}(?:[a-z0-9_])+)+[A-Z]{0,2}-(?:[A-Z]{1,3}(?:[a-z0-9_])+)+[A-Z]{0,2}$" -Because "Use Pascal case for cmdlet names.`nIn other words, capitalize the first letter of verb and all terms used in the noun. For example, `"Clear-ItemProperty`"`n`nDocumentation link:`nhttps://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-pascal-case-for-cmdlet-names-sd02"
                        }

                        It -Skip:$compiled 'Must not use common parameter names as your own' {
                            $badParamNames = $builtinParameters += 'Confirm'
                            $badParamNames = $badParamNames += 'WhatIf'
                            if (-not ($function.CmdletBinding)) {
                                $comparison = Compare-Object -ReferenceObject $badParamNames -DifferenceObject $parameters.Name -IncludeEqual -ExcludeDifferent | Select-Object -ExpandProperty InputObject 
                                $comparison | Should -BeNullOrEmpty -Because "Cmdlet names should not contain special characters.`n`nDocumentation link:`nhttps://learn.microsoft.com/en-gb/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#parameters-names-that-cannot-be-used-rd03"
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

                        It 'Supports Confirmation Requests for operations that modify the system' {
                            if ('Stop', 'Remove', 'Revoke' -contains $function.Verb) {
                                $parameters.Name | Should -Contain 'Confirm' -Because "To make these calls the cmdlet must specify that it supports confirmation requests by setting the SupportsShouldProcess keyword of the Cmdlet attribute.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#support-confirmation-requests-rd04"
                            }
                        }

                        It -Tag WIP 'Support Force Parameter for Interactive Sessions' {
                            #Absolutely no clue how to code this
                            'https://learn.microsoft.com/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#support-force-parameter-for-interactive-sessions-rd05'
                        }
        
                        It 'Must use singular parameter name.' {
                            foreach ($parameter in $parameters) {
                                if ($parameter.ParameterType.FullName -notin 'System.Int16', 'System.UInt16', 'System.Int32', 'System.UInt32', 'System.Int64', 'System.UInt64', 'System.IntPtr', 'System.UIntPtr') {
                                    $parameter.Name -like "*s" -and $parameter.Name -notmatch "(Status)|(ous)|(ss)|(ics)$" | Should -Not -BeTrue -Because "$($parameter.Name) appears to be plural, avoid using plural names for parameters whose value is a single element. This includes parameters that take arrays or lists because the user might supply an array or list with only one element.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-singular-parameter-names"
                                }
                            }
                        }
              
                        It 'Must use Pascal Case for parameter name.' {
                            $parameters.Name | Should -MatchExactly '^(?:[A-Z]{1,3}(?:[a-z0-9_])+)+[A-Z]{0,2}$' -Because "Use Pascal case for parameter names.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-pascal-case-for-parameter-names"
                        }
        
                        It -Tag Optional 'In most cases, Add, Set, and New cmdlets should support a PassThru parameter.' {
                            if ('Add', 'Set', 'New' -contains $function.Verb) {
                                $parameters | Where-Object { $_.Name -eq 'PassThru' } | Should -Not -BeNullOrEmpty -Because "By default, many cmdlets that modify the system, such as the Stop-Process cmdlet, act as `"sinks`" for objects and do not return a result. These cmdlets should implement the PassThru parameter to force the cmdlet to return an object.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-the-passthru-parameter"
                            }
                        }
        
                        It -Tag Optional 'If possible use a standard parameter name.' {
                            $stdParams = Get-Content StandardParameterNames.txt
                            foreach ($param in $parameters) {
                                if ($stdParams -notcontains $param.Name) {
                                    foreach ($stdParam in $stdParams) {
                                        if ($parameters.Name -notcontains $stdParam -and $param.Name -ne "No$stdParam") {
                                            $param.Name | Should -Not -BeLike "??$stdParam" -Because "$($param.Name) seems to be close to the standard parameter name $stdParam. Cmdlet parameter names should be consistent across the cmdlets that you design.`nThe following topics list the parameter names that we recommend you use when you declare cmdlet parameters. The topics also describe the recommended data type and functionality of each parameter.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/standard-cmdlet-parameter-names-and-types?view=powershell-7.3"
                                            $param.Name | Should -Not -BeLike "$stdParam??" -Because "$($param.Name) seems to be close to the standard parameter name $stdParam. Cmdlet parameter names should be consistent across the cmdlets that you design.`nThe following topics list the parameter names that we recommend you use when you declare cmdlet parameters. The topics also describe the recommended data type and functionality of each parameter.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/standard-cmdlet-parameter-names-and-types?view=powershell-7.3"
                                        }
                                    }
                                }
                            }
                        }
        
                        It -Skip:$compiled 'Must have a Force parameter if you set your ConfirmImpact to high' {
                            if ($function.ScriptBlock -match "ConfirmImpact\s*=\s*`[`"|'`]High`[`"|'`]" -and $parameters.Name -contains 'Confirm') {
                                $parameters | Where-Object { $_.Name -eq 'Force' } | Should -Not -BeNullOrEmpty -Because "If you set your ConfirmImpact to high, you should allow your users to suppress it with -Force.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/learn/deep-dives/everything-about-shouldprocess?view=powershell-7.3#shouldprocess--force"
                            }
                        }

                        It 'Should not use the verb Invoke' {
                            if ($function.Noun -ne 'Item' -and $function.Noun -notlike "*script*" -and $function.Noun -notlike "*command*" -and $function.Noun -notlike "*method*") {
                                $function.Verb | Should -Not -Be 'Invoke' -Because "Uses the verb Invoke. Invoke should only be used to perform an action, such as running a command or a method. This action should also only be synchronous, use Start- for async. It is unlikely that there is not a more specific verb to use than Invoke.`n`nDocumentation link:`nhttps://learn.microsoft.com/en-gb/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-7.3#verb-naming-recommendations"
                            }
                        } 
                    }
            
                    Context 'Input' {

                        #TODO Common parmater aliases shouldn't be used for other paramaeters. https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/common-parameter-names?view=powershell-7.4#general-common-parameters

                        It 'Switch parameters should not have a position.' {
                            $switchParams = foreach ($param in $parameters) { 
                                if ($param.ParameterType.Name -eq 'SwitchParameter' -and $param.Attributes.Position -ne -2147483648) { 
                                    Write-Output $param.Name 
                                } 
                            }
                            $switchParams | Should -BeNullOrEmpty -Because "the Switch parameter(s) $switchParams should not have a position.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-7.4#switch-parameter-design-considerations"
                        }
                    
                        #TODO Switch parameters shouldn't be mandatory, unless they are the only mandatory parameter in a parameterset https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-7.4#switch-parameter-design-considerations
        
                        #TODO Must not conflict with existing names https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_modules?view=powershell-7.4#manage-name-conflicts
        
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
                            if ($parameters.attributes.Mandatory -contains $true) {
                                $positionalParams = foreach ($param in $parameters) { 
                                    if ($param.Attributes.Position -ne -2147483648) { 
                                        Write-Output $param.Attributes.Position 
                                    } 
                                }
                                $positionalParams | Should -Not -BeNullOrEmpty -Because "Good cmdlet design recommends that the most-used parameters be declared as positional parameters.`nThe user then does not need to have to enter the parameter name when the cmdlet is run. If the cmdlet has several mandatory parameters consider setting them as positional, up to a maximum of 4.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/types-of-cmdlet-parameters?view=powershell-7.3#positional-and-named-parameters"
                            }
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
                            $pipeParams = foreach ($param in $parameters) { if ($param.attributes.ValueFromPipeline -eq $true -or $param.attributes.ValueFromPipelineByPropertyName -eq $true) { Write-Output $param.Name } }
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
        
                        It -Skip:$compiled 'If Path is a parameter it should have the PSPath alias.' {
                            if ($parameters.Name -contains 'Path') {
                                $pathParam = $parameters | Where-Object { $_.Name -eq 'Path' }
                                $pathParam.Aliases | Should -Contain 'PSPath' -Because "This alias ensures that when working with different PowerSherll providers pipelining works.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-windows-powershell-paths"
                            }
                        }
        
                        It 'If your cmdlet allows the user to specify a path, it should define a parameter of type String.' {
                            if ($parameters.Name -contains 'Path') {
                                $pathParam = $parameters | Where-Object { $_.Name -eq 'Path' }
                                $pathParam.ParameterType.Name | Should -BeLike 'String*' -Because "If your cmdlet allows the user to specify a file or a data source, it should define a parameter of type System.String`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-windows-powershell-paths"
                            }
                        }
        
                        It 'If Uri is a parameter it should have the System.Uri type.' {
                            if ($parameters.Name -contains 'Uri') {
                                $pathParam = $parameters | Where-Object { $_.Name -eq 'Uri' }
                                $pathParam.ParameterType.Name | Should -Be 'Uri' -Because "If Uri is a parameter it should have the System.Uri type.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#use-strongly-typed-net-framework-types"
                            }
                        }
        
                        It -Tag Optional 'Validates input where possible (Validate Range).' {
                            foreach ($param in $parameters) {
                                #Ignoring byte types as range is implied there.
                                #Range needs to be Int64, so can't test 'UInt64', 'IntPtr', 'UIntPtr'
                                $numberTypes = @('Int16', 'UInt16', 'Int32', 'UInt32', 'Int64')
                                if ($numberTypes -contains $param.ParameterType.Name) {
                                    $rangeMin = ($param.ParameterType)::MinValue
                                    $rangeMax = ($param.ParameterType)::MaxValue
                                    $param.Attributes.MinRange | Should -Not -BeNullOrEmpty -Because "$($param.Name) is a $($param.ParameterType.Name) format which gives a range of $rangeMin to $rangeMax. Consider adding a range to this parameter, this ensures the user receives the correct error message as early as possible.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/validating-parameter-input?view=powershell-7.3#validaterange"
                                    $param.Attributes.MaxRange | Should -Not -BeNullOrEmpty -Because "$($param.Name) is a $($param.ParameterType.Name) format which gives very large range. Consider adding a range to this parameter, this ensures the user receives the correct error message as early as possible.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/validating-parameter-input?view=powershell-7.3#validaterange"
                                }
                            }
                        }
        
                        It 'Makes sure that the type described by input object is valid.' {
                            if ($parameters.Name -contains 'InputObject') {
                                $inputObjectParam = $parameters | Where-Object { $_.Name -eq 'InputObject' }
                                { $inputObjectParam.ParameterType } | Should -Not -Throw -Because "`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/advisory-development-guidelines?view=powershell-7.3#support-an-inputobject-parameter-ad01"
                            }
                        }
        
                        It -Tag WIP "A cmdlet should not have too many parameters. For a better user experience, limit the number of parameters." {
                            $parameters.Count | Should -BeLessThan ($ParametersMax + 1) -Because "Cmdlet has $($parameters.Count) parameters.`nThis should be simplified or split into multiple cmdlets. Max Tested was $ParametersMax.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3#remarks"
                        }
        
                        It 'Has no more than 4 positional parameters' {
                            foreach ($set in $function.ParameterSets) {
                                $positionalParams = foreach ($param in $set.Parameters) { 
                                    if ($param.attributes.position -ne -2147483648) { 
                                        Write-Output "Positional Parameter $($param.attributes.position): $($param.Name)"
                                    } 
                                }
                                $positionalParams | Measure-Object | Select-Object -ExpandProperty Count | Should -BeLessThan 5 -Because "When you specify positional parameters, limit the number of positional parameters in a parameter set to less than five.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3#remarks"
                            }
                        }

                        It -Tag Optional 'Each parameter set other than default must have at least one unique mandatory parameter.' {
                            if ($function.ParameterSets.Count -gt 2 -and $parameters.Attributes.Mandatory -contains $true) {

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
                                    $mandatoryParams | Measure-Object | Select-Object -ExpandProperty Count | Should -BeGreaterThan 0 -Because  "If your cmdlet is designed to be run without parameters, the unique parameter cannot be mandatory.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3#remarks"
                                }
                            }
                        }
        
                        It 'No parameter set should contain more than one positional parameter with the same position.' {
                            foreach ($set in $function.ParameterSets) {
                                $positionalParams = foreach ($param in $set.Parameters) { 
                                    if ($param.Attributes.position -ne -2147483648) { 
                                        $param.Attributes.position | Select-Object -First 1
                                    } 
                                }
                        ($positionalParams | Sort-Object -Unique).Count | Should -Be $positionalParams.Count -Because "No parameter set should contain more than one positional parameter with the same position.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3#remarks"
                            }
                        }
        
                        It 'Only one parameter in a parameter set should pipe by value.' {
                            foreach ($set in $function.ParameterSets) {
                                $pipeParams = foreach ($param in $set.Parameters) { 
                                    if ($param.Attributes.ValueFromPipeline -eq $true) { 
                                        Write-Output "$($param.Name)"
                                    } 
                                }
                                $paramList = $pipeParams -join ', '
                                $pipeParams.Count | Should -BeLessThan 2 -Because "Parameter Set `'$($set.Name)`' has multiple parameters that accept pipeline input. The conflicting parameters are: $paramList`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/parameter-attribute-declaration?view=powershell-7.3"
                            }
                        }
        
                        It -Tag WIP 'Support Parameter Sets when necessary. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-parameter-sets' {
                            #$function.ParameterSets.Count | Should -BeGreaterThan 1
                        }

                        It 'Parameter Sets must be unique from each other.' {
                            
                            foreach ($param in $parameters) {
                                if ($param.ParameterSets.Count -gt 2) {
                                    $paramSets = ($param.ParameterSets.GetEnumerator() | Where-Object Key -ne '__AllParameterSets').key
                                }
                            }
                            
                            if ($null -ne $paramSets) {
                                $parameterArrays = foreach ($set in $paramSets) {
                                    $function.ParameterSets | Where-Object { $_.Name -eq $set } | ForEach-Object { 
                                        $paramNamesInSet = $_.Parameters | Where-Object { $builtinParameters -notcontains $_.Name } | Select-Object -ExpandProperty Name
                                        $output = [PSCustomObject]@{
                                            SetName = $set
                                            Params  = $paramNamesInSet
                                        }
                                        Write-Output $output
                                    }
                                }
                            
                                $uniqueParams = $parameterArrays.Params | Group-Object | Where-Object Count -eq 1 | Select-Object -ExpandProperty Name
                            
                                $uniqueParams | Should -Not -BeNullOrEmpty -Because "The Parameter Sets $($paramSets -join ', ') appear to contain the same parameters, parameter sets should contain unique parmaeter combinations.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-parameter-sets?view=powershell-7.3#parameter-set-requirements"
                            }
                        }
        
                        It -Tag Test 'Has a default Parameter set if necessary.' {

                            if (($function.DefaultParameterSet | Measure-Object).Count -eq 0 ) {
                             
                                foreach ($param in $parameters) {
                                    if ($param.ParameterSets.Count -gt 2) {
                                        $paramSets = ($param.ParameterSets.GetEnumerator() | Where-Object Key -ne '__AllParameterSets').key
                                    }
                                }
                                
                                $parameterArrays = foreach ($set in $paramSets) {
                                    $function.ParameterSets | Where-Object { $_.Name -eq $set } | ForEach-Object { 
                                        $paramNamesInSet = $_.Parameters | Where-Object { $builtinParameters -notcontains $_.Name }
                                        $output = [PSCustomObject]@{
                                            SetName = $set
                                            Params  = $paramNamesInSet
                                        }
                                        Write-Output $output
                                    }
                                }
                                
                                $uniqueParams = $parameterArrays.Params.Name | Group-Object | Where-Object Count -lt $paramsets.count
                                
                                foreach ($set1 in $parameterArrays) {
                                    foreach ($set2 in $parameterArrays) {
                                        if ($set1.SetName -ne $set2.SetName) {
                                            $set1Unique = $set1.Params | Where-Object { $uniqueParams.Name -Contains $_.Name }
                                            $set1MandCount = $set1Unique | Where-Object { $_.Attributes.Mandatory -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
                                            $set2Unique = $set2.Params | Where-Object { $uniqueParams.Name -Contains $_.Name }
                                            $set2MandCount = $set2Unique | Where-Object { $_.Attributes.Mandatory -eq $true } | Measure-Object | Select-Object -ExpandProperty Count
                                            if ($set1MandCount -eq 0 -and $set2MandCount -gt 0) {
                                                $needsDefault = $false
                                            }
                                            if ($set1MandCount -eq $set2MandCount) {
                                                $needsDefault = $true
                                            }
                                    
                                            $needsDefault | Should -Be $false -Because "The Parameter Sets $($set1.SetName) and $($set2.SetName) appear to contain the parameters which cannot always be resolved and also doesn't contain a default parameterset.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-parameter-sets?view=powershell-7.3#default-parameter-sets"
                                        }                           
                                    }
                                }
                            }
                        }
        
                        It -Tag WIP 'Supports arrays for Parameters where appropriate. https://learn.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines?view=powershell-7.3#support-arrays-for-parameters' {
                            #TODO no idea how to do this.
                        }
                    }
        
                    Context 'Output' {
        
                        It -Skip:$compiled 'Specify the OutputType Attribute.' {
                            if ($parameters.Name -contains 'PassThru') {
                                $outType = 'PassThru'
                            }
                            else {
                                $outType = $function.OutputType
                            }
                            $outType | Should -Not -BeNullOrEmpty -Because "By specifying the output type of your cmdlets you make the objects returned by your cmdlet more discoverable by other cmdlets.`n`nDocumentation link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#specify-the-outputtype-attribute-rc04"
                        }
        
                        It -Skip:$compiled 'OutputType Attribute must be valid.' {
                            if ($parameters.Name -contains 'PassThru') {
                                $typetest = 'PassThru'
                            }
                            else {
                                $typeTest = foreach ($type in $function.OutputType.Type) {
                                    if ($null -ne $type.BaseType) {
                                        Write-Output $type.ToString()
                                    }
                                }
                            }
                            $typeTest | Should -Not -BeNullOrEmpty -Because "$type is specified as the output and does not exist.`n`nThe OutputType attribute identifies the .NET Framework types returned by a cmdlet, function, or script. By specifying the output type of your cmdlets you make the objects returned by your cmdlet more discoverable by other cmdlets.`n`nDocumention link:`nhttps://learn.microsoft.com/powershell/scripting/developer/cmdlet/required-development-guidelines?view=powershell-7.3#specify-the-outputtype-attribute-rc04"
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
        
            if ($AddOptionalTest) {
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
                        Name   = $cmdlet
                        Passed = $fullResult.PassedCount
                        Failed = $fullResult.FailedCount
                    }
                    break
                }
                Failed {
                    if ($fullResult.FailedCount -gt 0) {
                        $testOutput = [PSCustomObject]@{
                            Name   = $cmdlet
                            Failed = foreach ($test in $fullResult.Failed) {
                                if ($test.ErrorRecord[0].ToString().Split(', but got ')[0] -Match "^Expected .* because ((?:.*\n*)*)") {
                                    $explanation = $Matches[1]
                                }
                                else {
                                    $explanation = $test.ErrorRecord[0].ToString()
                                }
                                [PSCustomObject]@{
                                    Name        = $test.Name
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