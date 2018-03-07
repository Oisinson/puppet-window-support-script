#Setting Variables
$logdir = puppet config print logdir
$server = puppet config print server

# Creating Folder
$supportfolder = $logdir + "/" + (get-date -f yyyy-MM-dd-hh-mm)
New-Item -Path $folder  -ItemType directory

# Print Screen. Folder Location, Progress
Write-host = "Support logs are being written to" + $supportfolder

# Getting  system information
$hostname = 'Hostname' *>> ($supportfolder + '/systeminfo.log')
hostname *>> ($supportfolder + '/systeminfo.log')

get-date *>> ($supportfolder + '/systeminfo.log')
[System.TimeZone]::CurrentTimeZone *>> ($supportfolder + '/systeminfo.log')

$puppet_version = 'puppet --version' *>> ($supportfolder + '/systeminfo.log')
puppet --version *>> ($supportfolder + '/systeminfo.log')

$hiera_version = 'hiera --version' *>> ($supportfolder + '/systeminfo.log')
hiera --version *>> ($supportfolder + '/systeminfo.log')

$facter_version = 'facter --version' *>> ($supportfolder + '/systeminfo.log')
facter --version *>> ($supportfolder + '/systeminfo.log')

$ruby_version = 'ruby --verison' *>> ($supportfolder + '/systeminfo.log')
ruby -v *>> ($supportfolder + '/systeminfo.log')

$where_puppet = 'where puppet' *>> ($supportfolder + '/systeminfo.log')
where.exe puppet *>> ($supportfolder + '/systeminfo.log')

$where_ruby = 'where.exe ruby' *>> ($supportfolder + '/systeminfo.log')
where.exe ruby *>> ($supportfolder + '/systeminfo.log')

$env_path = 'Environment path' *>> ($supportfolder + '/systeminfo.log')
$env:path *>> ($supportfolder + '/systeminfo.log')



$test_connection = 'Testing Connection to Master' *>> ($supportfolder + '/systeminfo.log')
Test-NetConnection $server -Port 8140 *>> ($supportfolder + '/systeminfo.log')
$service_info = 'Getting Puppet, PxP-agent, mcollective service information' *>> ($supportfolder + '/systeminfo.log')
Get-wmiobject -Query "SELECT * FROM win32_service where (name = 'puppet' or name = 'pxp-agent' or name = 'mcollective')" | Format-List -Property Name,Pathname, ProcessId, Startmode, State, Status, Startname *>> ($supportfolder + '/systeminfo.log')

# Gathering existing logs
Get-Eventlog -source "Puppet" -logname "Application" | Format-List Index, Time, EntryType, Message *>> ($supportfolder + '/pastrunlogs.txt')

# Running Puppet and Facter in debug/trace mode
# puppet agent -t --debug --trace *>> ($supportfolder + '/debugrun.log')
# facter --debug --trace *>> ($supportfolder + '/facterdebug.log')
