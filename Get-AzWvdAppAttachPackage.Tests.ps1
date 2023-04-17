BeforeAll {
    Import-Module "D:\JimM\Az.DesktopVirtualization\Az.DesktopVirtualization.psd1" -Scope Local -Force
}

Describe 'Get-AzWvdAppAttachPackage' {

    BeforeAll {
        $function = Get-Command -Name Get-AzWvdAppAttachPackage
        #$dontShowParams = @('Break','HttpPipelineAppend','HttpPipelinePrepend','Proxy','ProxyCredential','ProxyUseDefaultCredentials')
        #The following Regex should show you all the parameters that OpenAPi has instructed don't be shown 
        #I've found the list produced to match the array above 
        #you can identify them by the text '[Parameter(DontShow)]' in the function definition
        $dontShowParams = $function.Definition | 
            Select-String -AllMatches "\[Parameter\(DontShow\)\]\r\n(.*\r\n){3,4}\s+\$\{(\w*)\}" | 
            ForEach-Object {$_.matches.Groups} | 
            Where-Object {$_.Name -eq 2} | 
            Select-Object -ExpandProperty Value
        #$nonFunctionalParams = @('DefaultProfile')
        #The following Regex should show you all the parameters that the function as extrated from the API has documented as non-functional 
        #I've found the list produced to match the array above 
        #you can identify them by the text 'parameter is not functional'.
        $nonFunctionalParams = $function.Definition |
            Select-String -AllMatches "\s+\#\sThe\s\w+\sparameter\sis\snot\sfunctional\.\r\n.*\r\n\s+\$\{(\w+)\}" | 
            ForEach-Object {$_.matches.Groups} | 
            Where-Object {$_.Name -eq 1} | 
            Select-Object -ExpandProperty Value
        
    }
    Context 'Input' {

        It 'Does not contain do not show based parameters' {
            $matchingParams = Compare-Object -ReferenceObject $function.Parameters.Keys.split('`r`n') -DifferenceObject $dontShowParams -IncludeEqual -ExcludeDifferent
            ($matchingParams | Measure-Object).Count | Should -Be 0
        }

        It 'Does not contain non functional parameters' {
            $matchingParams = Compare-Object -ReferenceObject $function.Parameters.Keys.split('`r`n') -DifferenceObject $nonFunctionalParams -IncludeEqual -ExcludeDifferent
            ($matchingParams | Measure-Object).Count | Should -Be 0
        }

        It 'Can be used without Parameters' {
            {Get-AzWvdAppAttachPackage -ErrorAction Stop} | Should -Not -Throw
        }

    }

    Context 'Output'{
        #$function.OutputType.GetType() | fl *

    }
}