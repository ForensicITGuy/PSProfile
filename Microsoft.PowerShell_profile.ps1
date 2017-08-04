Start-Transcript -Path "C:\Users\forensicitguy\Documents\WindowsPowerShell\Transcript\$(get-date -f "yyyyMMddTHHmmss").log"
Set-Location "E:\launchpad"

function prompt
{
    $time = (Get-Date).ToShortTimeString()
    "$time [$env:COMPUTERNAME][$env:USERNAME][$pwd]>"
}

## Common Directories
$launchpad = "E:\launchpad"
$vault = "E:\vault"

function uptime
{
    $cred = Get-Credential
    $computer = read-host "Please type in computer name you would like to check uptime on"
    $lastboottime = (Get-WmiObject -Class Win32_OperatingSystem -computername $computer -Credential $cred).LastBootUpTime
    $sysuptime = (Get-Date) - [System.Management.ManagementDateTimeconverter]::ToDateTime($lastboottime)
    Write-Host "$computer has been up for: " $sysuptime.days "days" $sysuptime.hours "hours" $sysuptime.minutes "minutes" $sysuptime.seconds "seconds"
}

function diskusage
{
    $cred = Get-Credential
    $remotepc = Read-host 'For which computer?'
    Get-WmiObject win32_logicaldisk -ComputerName $remotepc  -Filter "drivetype=3" -Credential $cred `
        | select SystemName,DeviceID,VolumeName,@{Name="Size(GB)";Expression={"0:N1}" -f($_.size/1gb)}},@{Name="FreeSpace(GB)";Expression={"{0:N1}" -f($_.freespace/1gb)}}
}

function Get-File
{
    <#

    .SYNOPSIS
    A simple PowerShell script to retrive files

    .DESCRIPTION
    Retrives one or more files to a directory

    .EXAMPLE
    Get-File -Url "http://mindre.net/Hyper-V_Monitor.gadget" -DestinationPath "C:\Users\Tore\Desktop"

    Retrives the file "Hyper-V_Monitor.gadget" to the folder "C:\Users\Tore\Desktop"

    .EXAMPLE
    Get-File -Url "http://mindre.net/Hyper-V_Monitor.gadget"

    Retrives the file "Hyper-V_Monitor.gadget" to the current directory

    .NOTES
    The script assumes that you'r not behind a web proxy and that the url's end with a filename like "http://my.site.com/logo.jpg".
    If the destination path does not exist the script will create it.

    .LINK
    http://mindre.net/post/PowerShell-profile-and-a-sample-script.aspx

    #>

    Param
  (
    [parameter(Mandatory=$true)]
    [String[]]
    [ValidateNotNullOrEmpty()]
    $Url,

    [String]
    [ValidateNotNullOrEmpty()]
    $DestinationPath = (Get-Location)
  )

    $wClient = New-Object System.Net.WebClient
    [System.Net.GlobalProxySelection]::Select = [System.Net.GlobalProxySelection]::GetEmptyWebProxy()

    $tp = Test-Path $DestinationPath
    if ($tp -eq $false) { New-Item $DestinationPath -ItemType directory -Force | Out-Null }

    $Url | % {
        $regex = [Regex]::Split($_, "/")
        $file = Join-Path $DestinationPath $regex[$regex.Length - 1]

        Write-Host $file -NoNewline
        $wClient.DownloadFile($_, $file)
        Write-Host " 100%"    
    }
}

function Get-ExternalIPAddress
{
    <#

    .SYNOPSIS
    A simple PowerShell script to display external IP address

    .DESCRIPTION
    Queries www.myexternalip.com/raw over HTTPS and returns the externally-available IP address as seen by the site.

    .EXAMPLE
    Get-ExternalIPAddress
    
    Returns external IP address for localhost

    .EXAMPLE
    Get-ExternalIPAddress -ComputerName RemoteComputer.domain
    
    Returns external IP address for remote host
    
    .NOTES
    Script queries www.myexternalip.com/raw to return IP address

    .LINK
    
    #>

    Param
  (
    [parameter(Mandatory=$false)]
    [String[]]
    $ComputerName
  )

  if (!$ComputerName)
  {
    (Invoke-WebRequest -Uri "https://www.myexternalip.com/raw").Content
  }
  else 
  {
      Invoke-Command -ComputerName $ComputerName -ScriptBlock {(Invoke-WebRequest -Uri "https://www.myexternalip.com/raw").Content} -Credential (Get-Credential)
  }
}
