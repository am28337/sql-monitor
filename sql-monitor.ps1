<#
 # Title:       sql-monitor.ps1
 # Author:      Andrew McGimpsey
 # Purpose:     Script to gather Health Check information or Monitoring information.
 # Parameters:  $HealthCheck:   Select which Health Check information you would like returned. Values can be multiple of 
                                    'server-info', 'volume-info', 'sql-info', 'db-info', 'dbfile-info', 'security-info' 
                                    or 'all'. Default is 'none'.  
                $Monitor        Select which Monitor information you would like returned. Values can be multiple of 'service-info', 
                                    'agent-info', 'backup-info', 'error-info', 'space-info', 'ag-info' or 'all'. Default is 'none'.
                $OutputType:    Choose how you want to view the results. Values can be either 'screen', 'log' or 'excel'. 
                                    Default is 'screen'.
                $OutputFilePath:Folder path of 'log' or 'excel' if either is selected.  Default path is the current directory (.).
                $ServerList:    File containing the list of servers to be monitored. Default path is '.\sql-monitor-serverlist.txt' 
                $LogFilePath:   Filepath of log file. File path will be $OutputFilePath + sqlmonitor-YYYYMMDD.log
                $ExcelFilePath: Filepath of excel file. File path will be $OutputFilePath + sqlmonitor-YYYYMM.
                $ComputerName:  List of Server names to be Health Checked or Monitored. List taken from $ServerList file.
                $Email:         Declare if an email should be sent containing the results.  Values can be 'yes' or 'no'.  Default is to not send an email.
                $EmailFrom:     Provide an email address to send the log/excel file from.
                $EmailTo:       Provide an email address to send the log/excel file to.
                $EmailSMTP:     Provide the SMTP server to the email from.
 #> 

[CmdletBinding()]
Param (
    <# $HealthCheck #>
    [Parameter(
        HelpMessage = "Select which Health Check information you would like returned. Values can be multiple of 'server-info', 'volume-info', 'sql-info', 'db-info', 'dbfile-info', 'security-info' or 'all'. Default is 'none'."
    )]
    [ValidateSet("server-info", "volume-info", "sql-info", "db-info", "dbfile-info", "security-info", "all", "none")]
    [String[]] $HealthCheck = "none",

    <# $Monitor #>
    [Parameter(
        HelpMessage = "Select which Monitor information you would like returned. Values can be multiple of 'service-info', 'agent-info', 'backup-info', 'error-info', 'space-info', 'ag-info' or 'all'. Default is 'none'."
    )]
    [ValidateSet("service-info", "agent-info", "backup-info", "error-info", "space-info", "ag-info", "all", "none")]
    [String[]] $Monitor = "none",

    <# $OutputType #>
    [Parameter(
        HelpMessage = "Choose how you want to view the results. Values can be either 'screen', 'log' or 'excel'. Default is 'screen'."
    )]
    [ValidateSet("screen", "log", "excel")]
    [String] $OutputType = "screen",

    <# $OutputFilePath #>
    [Parameter(
        HelpMessage = "Folder path of 'log' or 'excel' if either is selected.  Default path is the current directory (.\). Default file names will be 'sqlmonitor-YYYYMMDD.log' or 'sqlmonitor-YYYYMM.xls'."
    )]
    [String] $OutputFilePath = ".\",

    <# $ServerList #>
    [Parameter(
        HelpMessage = "File containing the list of servers to be monitored. Default path is '.\sql-monitor-serverlist.txt'."
    )]
    [String] $ServerList = ".\sql-monitor-serverlist.txt",

    <# $Email #>
    [Parameter(
        HelpMessage = "Declare if an email should be sent containing the results.  Values can be 'yes' or 'no'.  Default is to not send an email."
    )]
    [String] $Email = "No",

    <# $EmailFrom #>
    [Parameter(
        HelpMessage = "Provide an email address to send the log/excel file from."
    )]
    [String] $EmailFrom = "",

    <# $EmailTo #>
    [Parameter(
        HelpMessage = "Provide an email address to send the log/excel file to."
    )]
    [String] $EmailTo = "",

    <# $EmailSMTP #>
    [Parameter(
        HelpMessage = "Provide the SMTP server to send the email from."
    )]
    [String] $EmailSMTP = ""
)

<# $LogFilePath #>
$LogFilePath = $OutputFilePath + "sqlmonitor-" + (Get-Date).ToString("yyyyMMdd") + ".log"

<# $ExcelFilePath #>
$ExcelFilePath = $OutputFilePath + "sqlmonitor-" + (Get-Date).ToString("yyyyMM") + ".xlsx"

<# ComputerName #>
$ComputerName = Get-Content -Path $ServerList

<# Create screen|log header #>
Function Set-ScreenLog-Header {
    "**************************************************" | Update-ScreenLog
    "sql-monitor.ps1" | Update-ScreenLog
    "Start Time: " + (Get-Date).ToString("dd/MM/yyyy HH:mm:ss") | Update-ScreenLog
    "**************************************************" | Update-ScreenLog
    "Parameter Values:" | Update-ScreenLog
    "HealthCheck: $HealthCheck" | Update-ScreenLog
    "Monitor: $Monitor" | Update-ScreenLog
    "OutputType: $OutputType" | Update-ScreenLog
    "OutputFilePath: $OutputFilePath" | Update-ScreenLog
    "ServerList: $ServerList" | Update-ScreenLog
    "Log Filepath: $LogFilePath" | Update-ScreenLog
    "Excel Filepath: $ExcelFilePath" | Update-ScreenLog
    "Computer Name: $ComputerName" | Update-ScreenLog
    "EmailFrom: $EmailFrom" | Update-ScreenLog
    "EmailTo: $EmailTo" | Update-ScreenLog
    "EmailSMTP: $EmailSMTP" | Update-ScreenLog
    "**************************************************" | Update-ScreenLog
}

<# Update screen|log output #>
Function Update-ScreenLog {
    param (
        [Parameter(ValueFromPipeline=$True)] 
        [string[]]
        $Message
        )

    If ($OutputType -eq "screen") {
        Write-Host $Message
    } ElseIf ($OutputType -eq "log") {
        $Message | Out-File -Append -FilePath $LogFilePath
    }
}

<# Create screen|log footer #>
Function Set-ScreenLog-Footer {
    "**************************************************" | Update-ScreenLog
    "End Time: " + (Get-Date).ToString("dd/MM/yyyy HH:mm:ss") | Update-ScreenLog
    "**************************************************" | Update-ScreenLog
    "" | Update-ScreenLog
}

<# Clear the terminal window if necessary. #>
#Clear-Host

<# Close $ExcelFilePath file if open. If we don't, ImportExcel won't save the new data. #>
If (Test-Path -Path $ExcelFilePath) {
    $ExcelFile = Open-ExcelPackage -Path $ExcelFilePath
    ([Runtime.InteropServices.Marshal]::GetActiveObject('Excel.Application').workbooks | Where-Object {$_.FullNameURLEncoded -eq $ExcelFile.File }).Close($false)
}

<# Create the screen|log file header. #>
Set-ScreenLog-Header

<# $Monitor: service-info #>
If (($Monitor -eq "service-info" ) -or ($Monitor -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check enabled SQL services are running." | Update-ScreenLog

        Get-Service -ComputerName $ComputerName -Name "*SQL*" | `
            Select-Object -Property MachineName,Name,DisplayName,StartType,Status  | `
            Where-Object {$_.StartType -ne 'Disabled'} | `
            Sort-Object MachineName,Name | `
            Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check enabled SQL services are running." | Update-ScreenLog

        Get-Service -ComputerName $ComputerName -Name "*SQL*" | `
            Select-Object -Property MachineName,Name,DisplayName,StartType,Status  | `
            Where-Object {$_.StartType -ne 'Disabled'} | `
            Sort-Object MachineName,Name | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append    
    } ElseIf ($OutputType -eq "excel") {
        Get-Service -ComputerName $ComputerName -Name "*SQL*" | `
            Select-Object -Property @{n='ExecutionDateTime';exp={Get-Date}},MachineName,Name,DisplayName,StartType,Status  | `
            Where-Object {$_.StartType -ne 'Disabled'} | `
            Sort-Object MachineName,Name | `
            Export-Excel -Path $ExcelFilePath -WorksheetName 'SQLMonitor-ServiceInfo' -FreezeTopRow -Append
    }
}

<# $Monitor: agent-info #>
If (($Monitor -eq "agent-info" ) -or ($Monitor -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check SQL job failures in the last day." | Update-ScreenLog

        Get-DbaAgentJobHistory -SqlInstance $ComputerName -OutcomeType Failed -StartDate (Get-Date).Date.AddDays(-1) | `
            Select-Object -Property ComputerName,InstanceName,RunDate,Job,StepName  | `
            Sort-Object RunDate -Descending | `
            Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check SQL job failures in the last day." | Update-ScreenLog

        Get-DbaAgentJobHistory -SqlInstance $ComputerName -OutcomeType Failed -StartDate (Get-Date).Date.AddDays(-1) | `
            Select-Object -Property ComputerName,InstanceName,RunDate,Job,StepName  | `
            Sort-Object RunDate -Descending | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append
    } ElseIf ($OutputType -eq "excel") {
        Get-DbaAgentJobHistory -SqlInstance $ComputerName -OutcomeType Failed -StartDate (Get-Date).Date.AddDays(-1) | `
            Select-Object -Property @{n='ExecutionDateTime';exp={Get-Date}},ComputerName,InstanceName,RunDate,Job,StepName  | `
            Sort-Object RunDate -Descending | `
            Export-Excel -Path $ExcelFilePath -WorksheetName 'SQLMonitor-AgentInfo' -FreezeTopRow -Append
    }
}

<# $Monitor: backup-info #>
If (($Monitor -eq "backup-info" ) -or ($Monitor -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check SQL backup failures in the last day." | Update-ScreenLog

        Get-DbaErrorLog -SqlInstance $ComputerName -Text "backup failed" -After (Get-Date).Date.AddDays(-1) | `
            Select-Object -Property ComputerName,InstanceName,LogDate,Source,Text  | `
            Sort-Object LogDate -Descending | `
            Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check SQL backup failures in the last day." | Update-ScreenLog

        Get-DbaErrorLog -SqlInstance $ComputerName -Text "backup failed" -After (Get-Date).Date.AddDays(-1) | `
            Select-Object -Property ComputerName,InstanceName,LogDate,Source,Text  | `
            Sort-Object LogDate -Descending | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append        
    } ElseIf ($OutputType -eq "excel") {
        Get-DbaErrorLog -SqlInstance $ComputerName -Text "backup failed" -After (Get-Date).Date.AddDays(-1) | `
            Select-Object -Property @{n='ExecutionDateTime';exp={Get-Date}},ComputerName,InstanceName,LogDate,Source,Text  | `
            Sort-Object LogDate -Descending | `
            Export-Excel -Path $ExcelFilePath -WorksheetName 'SQLMonitor-BackupInfo' -FreezeTopRow -Append
    }
}

<# $Monitor: error-info #>
If (($Monitor -eq "error-info" ) -or ($Monitor -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check errors in SQL log file in the last day." | Update-ScreenLog

        Get-DbaErrorLog -SqlInstance $ComputerName -After (Get-Date).Date.AddDays(-1) | `
            Where-Object { `
                ($_.Text -like '*error*' `
                    -or $_.Text -like '*fail*') `
                    -and ($_.Text -notlike '*0 errors*' `
                    -and $_.Text -notlike '*ERRORLOG*' `
                    -and $_.Text -notlike '*without errors*' `
                    -and $_.Text -notlike '*cycle error log*' `
                    -and $_.Text -notlike '*error log has been reinitialized*' `
                    -and $_.Text -notlike '*This is an informational message*' `
                    -and $_.Source -notlike '*Backup*')} | `
            Select-Object -Property ComputerName,InstanceName,LogDate,Source,Text  | `
            Sort-Object LogDate -Descending | `
            Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check errors in SQL log file in the last day." | Update-ScreenLog

        Get-DbaErrorLog -SqlInstance $ComputerName -After (Get-Date).Date.AddDays(-1) | `
            Where-Object { `
                ($_.Text -like '*error*' `
                    -or $_.Text -like '*fail*') `
                    -and ($_.Text -notlike '*0 errors*' `
                    -and $_.Text -notlike '*ERRORLOG*' `
                    -and $_.Text -notlike '*without errors*' `
                    -and $_.Text -notlike '*cycle error log*' `
                    -and $_.Text -notlike '*error log has been reinitialized*' `
                    -and $_.Text -notlike '*This is an informational message*' `
                    -and $_.Source -notlike '*Backup*')} | `
            Select-Object -Property ComputerName,InstanceName,LogDate,Source,Text  | `
            Sort-Object LogDate -Descending | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append      
    } ElseIf ($OutputType -eq "excel") {
        Get-DbaErrorLog -SqlInstance $ComputerName -After (Get-Date).Date.AddDays(-1) | `
            Where-Object { `
                ($_.Text -like '*error*' `
                    -or $_.Text -like '*fail*') `
                    -and ($_.Text -notlike '*0 errors*' `
                    -and $_.Text -notlike '*ERRORLOG*' `
                    -and $_.Text -notlike '*without errors*' `
                    -and $_.Text -notlike '*cycle error log*' `
                    -and $_.Text -notlike '*error log has been reinitialized*' `
                    -and $_.Text -notlike '*This is an informational message*' `
                    -and $_.Source -notlike '*Backup*')} | `
            Select-Object -Property @{n='ExecutionDateTime';exp={Get-Date}},ComputerName,InstanceName,LogDate,Source,Text  | `
            Sort-Object LogDate -Descending | `
            Export-Excel -Path $ExcelFilePath -WorksheetName 'SQLMonitor-ErrorInfo' -FreezeTopRow -Append
    }
}

<# $Monitor: space-info #>
If (($Monitor -eq "space-info" ) -or ($Monitor -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check adequate disk space left." | Update-ScreenLog

        Get-DbaDiskSpace -ComputerName $ComputerName | `
            Select-Object -Property ComputerName,Name,Label,Capacity,Free,PercentFree | `
            Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** SQLMonitor: Check adequate disk space left." | Update-ScreenLog

        Get-DbaDiskSpace -ComputerName $ComputerName | `
            Select-Object -Property ComputerName,Name,Label,Capacity,Free,PercentFree | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append     
    } ElseIf ($OutputType -eq "excel") {
        Get-DbaDiskSpace -ComputerName $ComputerName | `
            Select-Object -Property @{n='ExecutionDateTime';exp={Get-Date}},ComputerName,Name,Label,Capacity,Free,PercentFree | `
            Export-Excel -Path $ExcelFilePath -WorksheetName 'SQLMonitor-SpaceInfo' -FreezeTopRow -Append
    }
}

<# $Monitor: ag-info #>
If (($Monitor -eq "ag-info" ) -or ($Monitor -eq "all")) {
    If ($OutputType -eq "screen") {

    } ElseIf ($OutputType -eq "log") {
        
    } ElseIf ($OutputType -eq "excel") {
        
    }
}

<# $HealthCheck: server-info
   Server name, Internet Protocol (IP) address, Operating System (OS) version, number of Central Processing Unit (CPU) cores, 
   amount of Random Access Memory (RAM) in Gigabytes (GB). #>
If (($HealthCheck -eq "server-info" ) -or ($HealthCheck -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** HealthCheck: server-info ***" | Update-ScreenLog
        "Server name, Internet Protocol (IP) address, Operating System (OS) version, number of Central Processing Unit (CPU) cores," | Update-ScreenLog 
        "amount of Random Access Memory (RAM) in Gigabytes (GB)." | Update-ScreenLog
        Get-DbaComputerSystem -ComputerName "LAPTOP-0001" | `
            Select-Object -Property ComputerName, `
                @{n='IPAddress';exp={(Test-Connection -ComputerName $_.ComputerName -Count 1).IPV4Address.ToString()}}, `
                @{n='OS Version';exp={(Get-WmiObject Win32_OperatingSystem -ComputerName $_.ComputerName).Caption.ToString()}}, `
                NumberLogicalProcessors,NumberProcessors,TotalPhysicalMemory | `
            Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** HealthCheck: server-info ***" | Update-ScreenLog
        "Server name, Internet Protocol (IP) address, Operating System (OS) version, number of Central Processing Unit (CPU) cores," | Update-ScreenLog 
        "amount of Random Access Memory (RAM) in Gigabytes (GB)." | Update-ScreenLog
        Get-DbaComputerSystem -ComputerName "LAPTOP-0001" | `
            Select-Object -Property ComputerName, `
                @{n='IPAddress';exp={(Test-Connection -ComputerName $_.ComputerName -Count 1).IPV4Address.ToString()}}, `
                @{n='OS Version';exp={(Get-WmiObject Win32_OperatingSystem -ComputerName $_.ComputerName).Caption.ToString()}}, `
                NumberLogicalProcessors,NumberProcessors,TotalPhysicalMemory | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append 
    } ElseIf ($OutputType -eq "excel") {
        
    }
}

<# $HealthCheck: volume-info 
   For each disk drive on the server, its drive letter, its size in GB, the amount of free space in GB, the amount of used 
   space in GB, the percentage of space used, the disk format bytes per cluster. #>
If (($HealthCheck -eq "volume-info" ) -or ($HealthCheck -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** HealthCheck: volume-info ***" | Update-ScreenLog 
        "For each disk drive on the server, its drive letter, its size in GB, the amount of free space in GB, the amount of used" | Update-ScreenLog 
        "space in GB, the percentage of space used, the disk format bytes per cluster." | Update-ScreenLog
        
        Get-DbaDiskSpace -ComputerName "LAPTOP-0001" | `
            Select-Object ComputerName,Name,Label,Capacity,Free, `
                @{n='Used';exp={($_.Capacity - $_.Free).ToString()}}, `
                PercentFree,BlockSize | `
            Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** HealthCheck: volume-info ***" | Update-ScreenLog 
        "For each disk drive on the server, its drive letter, its size in GB, the amount of free space in GB, the amount of used" | Update-ScreenLog 
        "space in GB, the percentage of space used, the disk format bytes per cluster." | Update-ScreenLog
        
        Get-DbaDiskSpace -ComputerName "LAPTOP-0001" | `
            Select-Object ComputerName,Name,Label,Capacity,Free, `
                @{n='Used';exp={($_.Capacity - $_.Free).ToString()}}, `
                PercentFree,BlockSize | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append 
        
    } ElseIf ($OutputType -eq "excel") {
        
    }
}

<# $HealthCheck: sql-info 
   SQL Server name, SQL instance name, SQL Server version, installed SQL Server components, installed SQL Server services, 
   the maximum amount of memory set in GB, the modes of authentication enabled, the level of auditing enabled. #>
If (($HealthCheck -eq "sql-info" ) -or ($HealthCheck -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** HealthCheck: sql-info ***" | Update-ScreenLog 
        "SQL Server name, SQL instance name, SQL Server version, installed SQL Server components, installed SQL Server services," | Update-ScreenLog 
        "the maximum amount of memory set in GB, the modes of authentication enabled, the level of auditing enabled." | Update-ScreenLog

        Get-DbaBuild -SqlInstance 'LAPTOP-0001' | Format-Table
        Get-DbaFeature -ComputerName 'LAPTOP-0001' | Format-Table
        Get-DbaService -ComputerName 'LAPTOP-0001' | Format-Table
        Get-DbaInstanceProperty -SqlInstance 'LAPTOP-0001' `
            -InstanceProperty Product,Edition,VersionString,ProductLevel,AuditLevel,LoginMode | `
            Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** HealthCheck: sql-info ***" | Update-ScreenLog 
        "SQL Server name, SQL instance name, SQL Server version, installed SQL Server components, installed SQL Server services," | Update-ScreenLog 
        "the maximum amount of memory set in GB, the modes of authentication enabled, the level of auditing enabled." | Update-ScreenLog
        
        Get-DbaBuild -SqlInstance 'LAPTOP-0001' | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append 
        Get-DbaFeature -ComputerName 'LAPTOP-0001' | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append 
        Get-DbaService -ComputerName 'LAPTOP-0001' | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append 
        Get-DbaInstanceProperty -SqlInstance 'LAPTOP-0001' `
            -InstanceProperty Product,Edition,VersionString,ProductLevel,AuditLevel,LoginMode | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append 
    } ElseIf ($OutputType -eq "excel") {
        
    }
}

<# $HealthCheck: db-info 
   For each database on the server, the database name, the database recovery model, the date and time of last full 
   backup, the date and time of the last differential backup, the date and time of the last transaction log backup. #>
If (($HealthCheck -eq "db-info" ) -or ($HealthCheck -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** HealthCheck: db-info ***" | Update-ScreenLog 
        "For each database on the server, the database name, the database recovery model, the date and time of last full" | Update-ScreenLog 
        "backup, the date and time of the last differential backup, the date and time of the last transaction log backup" | Update-ScreenLog

        Get-DbaDbRecoveryModel -SqlInstance "LAPTOP-0001" | Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** HealthCheck: db-info ***" | Update-ScreenLog 
        "For each database on the server, the database name, the database recovery model, the date and time of last full" | Update-ScreenLog 
        "backup, the date and time of the last differential backup, the date and time of the last transaction log backup" | Update-ScreenLog
        
        Get-DbaDbRecoveryModel -SqlInstance "LAPTOP-0001" | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append 
    } ElseIf ($OutputType -eq "excel") {
        
    }
}

<# $HealthCheck: dbfile-info 
   For each database file, the file name, the file location, the file filegroup, the file size, the file max-size, 
   the file growth setting, and the file usage whether it is for data or log use. #>
If (($HealthCheck -eq "dbfile-info" ) -or ($HealthCheck -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** SQLHealthCheck: dbfile-info ***" | Update-ScreenLog
        "For each database file, the file name, the file location, the file filegroup, the file size, the file max-size," | Update-ScreenLog 
        "the file growth setting, and the file usage whether it is for data or log use." | Update-ScreenLog

        Get-DbaDbFileGrowth -SqlInstance 'LAPTOP-0001' | `
            Select-Object -Property ComputerName,InstanceName,SQLInstance,Database,File, `
                @{n='FileSizeMB';exp={(Get-Item $_.Filename).length/1MB}},MaxSize,GrowthType,Growth,Filename | `
            Format-Table

        Get-DbaDbFile -SqlInstance 'LAPTOP-0001' | `
            Format-Table -AutoSize

    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** SQLHealthCheck: dbfile-info ***" | Update-ScreenLog
        "For each database file, the file name, the file location, the file filegroup, the file size, the file max-size," | Update-ScreenLog 
        "the file growth setting, and the file usage whether it is for data or log use." | Update-ScreenLog

        Get-DbaDbFileGrowth -SqlInstance 'LAPTOP-0001' | `
            Select-Object -Property ComputerName,InstanceName,SQLInstance,Database,File, `
                @{n='FileSizeMB';exp={(Get-Item $_.Filename).length/1MB}}, `
                MaxSize,GrowthType,Growth,Filename | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append 

        Get-DbaDbFile -SqlInstance 'LAPTOP-0001' | `
            Format-Table -AutoSize | `
            Out-File -FilePath $LogFilePath -Append 
    } ElseIf ($OutputType -eq "excel") {
        
    }
}
<# $HealthCheck: security-info 
   Look for users that have weak passwords, or users that have the sysadmin role assigned to them. #>
If (($HealthCheck -eq "security-info" ) -or ($HealthCheck -eq "all")) {
    If ($OutputType -eq "screen") {
        "" | Update-ScreenLog
        "*** SQLHealthCheck: security-info ***" | Update-Screenlog
        "Look for users that have weak passwords, or users that have the sysadmin role assigned to them." | Update-ScreenLog
        
        Test-DbaLoginPassword -SqlInstance 'LAPTOP-0001' | Format-Table

        Get-DbaServerRoleMember -SqlInstance 'LAPTOP-0001' -ServerRole 'sysadmin' | Format-Table
    } ElseIf ($OutputType -eq "log") {
        "" | Update-ScreenLog
        "*** SQLHealthCheck: security-info ***" | Update-Screenlog
        "Look for users that have weak passwords, or users that have the sysadmin role assigned to them." | Update-ScreenLog
        
        Test-DbaLoginPassword -SqlInstance 'LAPTOP-0001' | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append  

        Get-DbaServerRoleMember -SqlInstance 'LAPTOP-0001' -ServerRole 'sysadmin' | `
            Format-Table | `
            Out-File -FilePath $LogFilePath -Append  
    } ElseIf ($OutputType -eq "excel") {
        
    }
}

<# Create the screen|log file footer. #>
Set-ScreenLog-Footer

<# $Email:  Send the chosen $OutputType from $EmailFrom to $EmailTo using the SMTP server $EmailSMTP #>
If ($Email) {
    $anonUser = "anonymous"
    $anonPass = ConvertTo-SecureString "anonymous" -AsPlainText -Force
    $anonCred = New-Object System.Management.Automation.PSCredential($anonUser, $anonPass)
    Send-MailMessage -From $EmailFrom `
        -To $EmailTo `
        -Subject "SQL-Monitor Findings: $DateToday" `
        -Body "See attachment" `
        -Attachments "$LogFilePath" `
        -SmtpServer $EmailSMTP `
        -Credential $anonCred
}