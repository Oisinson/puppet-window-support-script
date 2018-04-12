#Setting Variables
$date = (get-date -f yyyy-MM-dd-hh-mm)
$logdir = puppet config print logdir
$server = puppet config print server
$supportfolder = $logdir + "\" + $date
$supportfile = $supportfolder + '\systeminfo.log'
$zippedfolder = $logdir + "\" + $date.zip


New-Item -Path $supportfolder  -ItemType directory

# Print Screen. Folder Location, Progress
Write-host = "Support logs are being written to" + $supportfolder

# Getting  system information
$hostname = 'Hostname' *>> $supportfile
hostname *>> $supportfile

get-date *>> $supportfile
[System.TimeZone]::CurrentTimeZone *>> $supportfile

$puppet_version = 'puppet --version' *>> $supportfile
puppet --version *>> $supportfile

$hiera_version = 'hiera --version' *>> $supportfile
hiera --version *>> $supportfile

$facter_version = 'facter --version' *>> $supportfile
facter --version *>> $supportfile

$ruby_version = 'ruby --verison' *>> $supportfile
ruby -v *>> $supportfile

$where_puppet = 'where puppet' *>> $supportfile
where.exe puppet *>> $supportfile

$where_ruby = 'where.exe ruby' *>> $supportfile
where.exe ruby *>> $supportfile

$env_path = 'Environment path' *>> $supportfile
$env:path *>> $supportfile

Write-host = "Testing Puppet Connectivity"

$test_connection = 'Testing Connection to Master' *>> $supportfile
Test-NetConnection $server -Port 8140 *>> $supportfile
$service_info = 'Getting Puppet, PxP-agent, mcollective service information' *>> $supportfile
Get-wmiobject -Query "SELECT * FROM win32_service where (name = 'puppet' or name = 'pxp-agent' or name = 'mcollective')" | Format-List -Property Name,Pathname, ProcessId, Startmode, State, Status, Startname *>> $supportfile

# Gathering existing logs
Get-Eventlog -source "puppet" -logname "Application" | Format-List Index, Time, EntryType, Message *>> ($supportfolder + '/pastrunlogs.txt')
Get-Eventlog -source "pxp-agent" -logname "Application" | Format-List Index, Time, EntryType, Message *>> ($supportfolder + '/pxp-agent.txt')
Get-Eventlog -source "mcollective" -logname "Application" | Format-List Index, Time, EntryType, Message *>> ($supportfolder + '/mcollective.txt')

# Running Puppet and Facter in debug/trace mode
puppet agent -t --debug --trace *>> ($supportfolder + '/debugrun.log')
facter --debug --trace *>> ($supportfolder + '/facterdebug.log')

$Zips $supportfolder
Add-Type -Assembly "System.IO.Compression.FileSystem" ;
[System.IO.Compression.ZipFile]::CreateFromDirectory("$supportfolder, $zippedfolder);

Write-Host = "Your supoprt script has completed and is located at $zippedfolder"