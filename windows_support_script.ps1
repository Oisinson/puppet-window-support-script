#==========================================================
# Copyright @ 2018 Kael Oisinson
#==========================================================

Write-Host
Write-Host 'Puppet Enterprise Windows Support Script'
Write-Host 'Note: This script can take a few minutes to execute.'
Write-Host

# Script Variables

$run_date_time = [string](Get-Date -Format yyyy-MM-dd-hh-mm)
$time_zone = [System.TimeZone]::CurrentTimeZone
$eventlog_date = (Get-Date).AddDays(-7)

$puppet_conf               = [string](puppet config print --section agent config)
$puppet_server             = [string](puppet config print --section agent server)
$puppet_logdir             = [string](puppet config print --section agent logdir)
$puppet_statedir           = [string](puppet config print --section agent statedir)
$puppet_pxp_logdir         =  [string](facter -p common_appdata) + "\PuppetLabs\pxp-agent\var\log"
$puppet_mcollective_logdir =  [string](facter -p common_appdata) + "\PuppetLabs\mcollective\var\log"

if ($puppet_logdir -eq '') {
  $puppet_logdir = [string](Get-Location)
}

$output_directory = $puppet_logdir + '/' + $run_date_time
$output_file      = $output_directory + '/systeminfo.log'
$output_archive   = $puppet_logdir + '/' + $run_date_time + '.zip'

# PowerShell Variables

$global:progressPreference = 'SilentlyContinue'

# Commands

$(New-Item -Path $output_directory -ItemType directory) | Out-Null

if (!(Test-Path $output_directory)) {
  Write-Host 'Error: could not create output directory:'
  Write-Host $output_directory
  Exit
}

# For more information about *> vs > see:
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_redirection

'Puppet Enterprise Windows Support Script' > $output_file

if (!(Test-Path $output_file)) {
  Write-Host 'Error: could not write to output file:'
  Write-Host $output_file
  Exit
}

Write-Host 'Collecting Diagnostic Information ...'

'Hostname' >> $output_file
hostname *>> $output_file

'Date, Time, Time Zone' >> $output_file
$run_date_time >> $output_file
$time_zone.StandardName *>> $output_file

'puppet --version' >> $output_file
puppet --version *>> $output_file

'hiera --version' >> $output_file
hiera --version *>> $output_file

'facter --version' >> $output_file
facter --version *>> $output_file

'ruby --version' >> $output_file
ruby --version *>> $output_file

'where puppet' >> $output_file
where.exe puppet *>> $output_file

'where ruby' >> $output_file
where.exe ruby *>> $output_file

'Environment Path' >> $output_file
$env:path >> $output_file

Write-Host 'Testing Puppet Server Connectivity ...'

'Test Port 8140 to Puppet Server ' + $puppet_server >> $output_file
Test-NetConnection $puppet_server -Port 8140 *>> $output_file

'Test Port 8142 to Puppet Server ' + $puppet_server >> $output_file
Test-NetConnection $puppet_server -Port 8142 *>> $output_file

'Test Port 61613 to Puppet Server ' + $puppet_server >> $output_file
Test-NetConnection $puppet_server -Port 61613 *>> $output_file

Write-Host 'Querying Puppet Agent Services ...'

'Puppet Agent Services Query: puppet pxp-agent mcollective' >> $output_file
Get-WmiObject -Query "SELECT * FROM win32_service where (name = 'puppet' or name = 'pxp-agent' or name = 'mcollective')" | Format-List -Property Name, Pathname, ProcessId, Startmode, State, Status, Startname *>> $output_file

Write-Host 'Exporting Puppet Agent Services Application Event Logs ...'

Get-Eventlog -Source puppet      -LogName Application -After $eventlog_date -ErrorAction SilentlyContinue | Format-List Index, Time, EntryType, Message *>> ($output_directory + '/eventlog_application_puppet.txt')
Get-Eventlog -Source pxp-agent   -LogName Application -After $eventlog_date -ErrorAction SilentlyContinue | Format-List Index, Time, EntryType, Message *>> ($output_directory + '/eventlog_application_pxp-agent.txt')
Get-Eventlog -Source mcollective -LogName Application -After $eventlog_date -ErrorAction SilentlyContinue | Format-List Index, Time, EntryType, Message *>> ($output_directory + '/eventlog_application_mcollective.txt')

Write-Host 'Running Facter in Debug Mode ...'
facter --debug --trace *>> ($output_directory + '/facter.log')

Write-Host 'Copying Configuration Files and State Directory ...'

if (!(Test-Path $puppet_conf)) {
  'Error: puppet config file not found' >> $output_file
} else {
  Copy-Item $puppet_conf -Destination $output_directory
}

if (!(Test-Path $puppet_statedir)) {
  'Error: puppet state directory not found' >> $output_file
} else {
  Copy-Item $puppet_statedir -Recurse -Destination $output_directory
}

if (!(Test-Path $puppet_pxp_logdir)) {
  'Error: puppet pxp-agent log directory not found' >> $output_file
} else {
  Copy-Item $puppet_pxp_logdir -Recurse -Destination ($output_directory + "\pxp-agent")
}

if (!(Test-Path $puppet_mcollective_logdir)) {
  'Error: puppet mcollective directory not found' >> $output_file
} else {
  Copy-Item $puppet_mcollective_logdir -Recurse -Destination ($output_directory + "\mcollective")
}

Write-Host 'Compressing Data ...'

Add-Type -Assembly 'System.IO.Compression.FileSystem' ;
[System.IO.Compression.ZipFile]::CreateFromDirectory($output_directory, $output_archive);
Remove-Item $output_directory -Recurse

Write-Host
Write-Host 'Done.'
Write-Host
Write-Host 'Puppet Enterprise Windows Support Script output is located in:'
Write-Host $output_archive
Write-Host 'Please submit it to Puppet Enterprise Support.'
Write-Host
