#Setting Variables
$date = (get-date -f yyyy-MM-dd-hh-mm)
$logdir = puppet config print logdir
if ($logdir) {$logdir} else {[string](Get-Location)}
$server = puppet config print server
$supportfolder = $logdir + "\" + $date
$supportfile = $supportfolder + "\systeminfo.log"
$zippedfolder = $logdir + "\" + $date.zip

New-Item -Path $supportfolder  -ItemType directory

# Print Screen. Folder Location, Progress
Write-host = "Support logs are being written to gathered. This can take a few minutes"

# Getting  system information
$hostname = "Hostname" *>> $supportfile
hostname *>> $supportfile

get-date *>> $supportfile
[System.TimeZone]::CurrentTimeZone *>> $supportfile

"puppet --version" *>> $supportfile
puppet --version *>> $supportfile

"hiera --version" *>> $supportfile
hiera --version *>> $supportfile

"facter --version" *>> $supportfile
facter --version *>> $supportfile

"ruby --verison" *>> $supportfile
ruby -v *>> $supportfile

"where puppet" *>> $supportfile
where.exe puppet *>> $supportfile

"where.exe ruby" *>> $supportfile
where.exe ruby *>> $supportfile

"Environment path" *>> $supportfile
$env:path *>> $supportfile

Write-host = "Testing Puppet Connectivity"

"Testing Connection to" + $server *>> $supportfile
Test-NetConnection $server -Port 8140 *>> $supportfile

"Puppet, PxP-agent, mcollective service information" *>> $supportfile
Get-wmiobject -Query "SELECT * FROM win32_service where (name = "puppet" or name = "pxp-agent" or name = "mcollective")" | Format-List -Property Name,Pathname, ProcessId, Startmode, State, Status, Startname *>> $supportfile

# Gathering existing logs
Get-Eventlog -source "puppet" -logname "Application" | Format-List Index, Time, EntryType, Message *>> ($supportfolder + "/pastrunlogs.txt")
Get-Eventlog -source "pxp-agent" -logname "Application" | Format-List Index, Time, EntryType, Message *>> ($supportfolder + "/pxp-agent.txt")
Get-Eventlog -source "mcollective" -logname "Application" | Format-List Index, Time, EntryType, Message *>> ($supportfolder + "/mcollective.txt")

# Running Puppet and Facter in debug/trace mode
puppet agent -t --debug --trace *>> ($supportfolder + "/debugrun.log")
facter --debug --trace *>> ($supportfolder + "/facterdebug.log")

$Zips $supportfolder
Add-Type -Assembly "System.IO.Compression.FileSystem" ;
[System.IO.Compression.ZipFile]::CreateFromDirectory($supportfolder, $zippedfolder);

Remove-Item $supportfolder -Recurse

Write-Host = "Your supoprt script has completed and is located at" + $zippedfolder
