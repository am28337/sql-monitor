<# P2.3. - Develop a script that writes the information to a file.  #>

<# Variable list. #>
$ComputerName = Get-Content -Path 'C:\Users\Andrew\Documents\_Gups\SQL-Monitor\sql-monitor-serverlist.txt'
$DateToday = Get-Date -Format 'yyyyMMdd-HHmm'
$DateCurrentMonth = Get-Date -Format 'yyyyMM'
$LogFilePath = '.\sql-monitor-'+$DateToday+'.txt'
$ExcelFilePath = '.\sql-monitor.xlsx'

<# Function to create the log file header. #>
function Log-Header {
    $StartDate = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")

    "-======================================================================" | Out-File -FilePath $LogFilePath
    "-                             SQL-MONITOR" | Out-File -Append -FilePath $LogFilePath
    "-" | Out-File -Append -FilePath $LogFilePath
    "- Executed at: $StartDate" | Out-File -Append -FilePath $LogFilePath
    "- Monitored Servers: $ComputerName" | Out-File -Append -FilePath $LogFilePath
    "-======================================================================" | Out-File -Append -FilePath $LogFilePath
}

<# Function to create the log file header. #>
function Log-Footer {
    $FinishDate = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")

    "-======================================================================" | Out-File -Append -FilePath $LogFilePath
    "-                             SQL-MONITOR" | Out-File -Append -FilePath $LogFilePath
    "-" | Out-File -Append -FilePath $LogFilePath
    "- Completed at: $FinishDate" | Out-File -Append -FilePath $LogFilePath
    "- Monitored Servers: $ComputerName" | Out-File -Append -FilePath $LogFilePath
    "-======================================================================" | Out-File -Append -FilePath $LogFilePath
}

<# Function to update the log file. #>
function Update-Log {
    param (
        [Parameter(ValueFromPipeline=$True)] 
        [string[]]
        $Message
        )

    # Output to a file
    $Message | Out-File -Append -FilePath $LogFilePath
}

<# Clear the terminal window. #>
Clear-Host

<# Create the log file header. #>
Log-Header

<# Check to ensure that services enabled for SQL Server are running. #>
Update-Log "-======================================================================"
Update-Log "- Check enabled SQL services are running."
Update-Log "-======================================================================"
Get-Service -ComputerName $ComputerName -Name "*SQL*" | `
    Select-Object -Property MachineName,Name,DisplayName,StartType,Status  | `
    Where-Object {$_.StartType -ne 'Disabled'} | `
    Sort-Object MachineName,Name | `
    Format-Table | `
    Out-File -FilePath $LogFilePath -Append

<# Check for failed automated SQL agent jobs. #>
Update-Log "-======================================================================"
Update-Log "- Check SQL job failures in the last week."
Update-Log "-======================================================================"
Get-DbaAgentJobHistory -SqlInstance $ComputerName -OutcomeType Failed -StartDate (Get-Date).Date.AddDays(-1) | `
    Select-Object -Property ComputerName,InstanceName,RunDate,Job,StepName  | `
    Sort-Object RunDate -Descending | `
    Format-Table | `
    Out-File -FilePath $LogFilePath -Append

<# Check for failed automated database backup jobs. #>
Update-Log "-======================================================================"
Update-Log "- Check SQL backup failures in the last week."
Update-Log "-======================================================================"
Get-DbaErrorLog -SqlInstance $ComputerName -Text "backup failed" -After (Get-Date).Date.AddDays(-1) | `
    Select-Object -Property ComputerName,InstanceName,LogDate,Source,Text  | `
    Sort-Object LogDate -Descending | `
    Format-Table | `
    Out-File -FilePath $LogFilePath -Append

<# Checking for errors in the SQL server log files. #>
Update-Log "-======================================================================"
Update-Log "- Check errors in SQL log file in the last day."
Update-Log "-======================================================================"
Get-DbaErrorLog -SqlInstance $ComputerName -After (Get-Date).Date.AddDays(-1) | `
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
    Format-Table | `
    Out-File -FilePath $LogFilePath -Append

<# Check to ensure that there is adequate disk space left #>
Update-Log "-======================================================================"
Update-Log "- Check adequate disk space left."
Update-Log "-======================================================================"
Get-DbaDiskSpace -ComputerName $ComputerName | `
    Select-Object -Property ComputerName,Name,Label,Capacity,Free,PercentFree | `
    Format-Table | `
    Out-File -FilePath $LogFilePath -Append

<# Create the log file footer. #>
Log-Footer
    