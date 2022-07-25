<# 0.1. - Develop a proof-of-concept script that shows that the information can be retrieved using the proposed solution. #>

<# Clear the terminal window. #>
Clear-Host

<# Check to ensure that services enabled for SQL Server are running. #>
Get-Service -ComputerName 'LAPTOP-0001' -Name "*SQL*" | `
    Select-Object -Property MachineName,Name,DisplayName,StartType,Status  | `
    Where-Object {$_.StartType -ne 'Disabled'} | `
    Sort-Object MachineName,Name | `
    Format-Table

<# Check for failed automated SQL agent jobs. #>
Get-DbaAgentJobHistory -SqlInstance 'LAPTOP-0001' -OutcomeType Failed -StartDate (Get-Date).Date.AddDays(-1) | `
    Select-Object -Property ComputerName,InstanceName,RunDate,Job,StepName  | `
    Sort-Object RunDate -Descending | `
    Format-Table

<# Check for failed automated database backup jobs. #>
Get-DbaErrorLog -SqlInstance 'LAPTOP-0001' -Text "backup failed" -After (Get-Date).Date.AddDays(-1) | `
    Select-Object -Property ComputerName,InstanceName,LogDate,Source,Text  | `
    Sort-Object LogDate -Descending | `
    Format-Table

<# Checking for errors in the SQL server log files. #>
Get-DbaErrorLog -SqlInstance 'LAPTOP-0001' -After (Get-Date).Date.AddDays(-1) | `
    Where-Object { `
        ($_.Text -like '*error*' `
            -or $_.Text -like '*fail*') `
            -and ($_.Text -notlike '*0 errors*' `
            -and $_.Text -notlike '*ERRORLOG*' `
            -and $_.Text -notlike '*without errors*' `
            -and $_.Text -notlike '*cycle error log*' `
            -and $_.Text -notlike '*error log has been reinitialized*')} | `
    Select-Object -Property ComputerName,InstanceName,LogDate,Source,Text  | `
    Sort-Object LogDate -Descending | `
    Format-Table

<# Check to ensure that there is adequate disk space left #>
Get-DbaDiskSpace -ComputerName 'LAPTOP-0001' | `
    Select-Object -Property ComputerName,Name,Label,Capacity,Free,PercentFree | `
    Format-Table