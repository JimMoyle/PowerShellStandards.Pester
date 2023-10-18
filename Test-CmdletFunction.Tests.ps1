Param (
    $Name = 'Get-Content'
)

BeforeDiscovery {
    #Use this region to set up the test environment
    $relativePath = '.\getcontent.txt'
    Remove-Item $relativePath -ErrorAction SilentlyContinue
    1..10 | Add-Content $relativePath

    #Add values for any parameters which do not have defaults
    $TotalCount = 5
    $ReadCount = 2
    $Path = $relativePath
    $LiteralPath = ($relativePath | Get-Item).FullName

    $testArticle = @(
        @{
            ParameterSet    = 'Path'
            GeneratedParams = @{
                Path       = $Path
                TotalCount = $TotalCount
            }
        },
        @{
            ParameterSet    = 'LiteralPath'
            GeneratedParams = @{
                LiteralPath = $LiteralPath
                TotalCount  = $TotalCount
            },
            @{
                LiteralPath = $LiteralPath
                ReadCount   = $ReadCount
            }
        }
    )
}


Describe "Command: <Name>" {

    Context "Testing ParameterSet <ParameterSet>" -ForEach $testArticle {

        AfterEach {
            # Clean up if needed after each test
        }

        it "<Name> -<_.GetEnumerator().Name -join ' -'>" -ForEach $GeneratedParams {

            #{Get-Content @_} | Should -Not -Throw
            Get-Content @_ -ErrorAction Stop
            
        }
    }
    AfterAll {
        #Clean up the test environment
        Remove-Item $relativePath
    }
}