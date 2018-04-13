#Setting Variables
$date = (Get-Date -f yyyy-MM-dd-hh-mm)
$logdir = puppet config print logdir
$(if ($logdir) {$logdir} else {[string](Get-Location)}) | Out-Null
$server = puppet config print server
$supportFolder = $logdir + "/" + $date
$supportFile = $supportFolder + "/systeminfo.log"
$zippedFolder =  $logdir + "/" + $date + ".zip"
$cachedir = "C:\ProgramData\PuppetLabs\puppet\cache\state"
$puppetConf = "C:\ProgramData\PuppetLabs\puppet\etc\puppet.conf"
$global:progressPreference = "silentlyContinue"

$(New-Item -Path $supportFolder -ItemType directory) | Out-Null

# Print Screen. Folder Location, Progress
Write-Host "Support logs are being gathered. This can take a few minutes."

# Getting  system information
$hostname = "Hostname" *>> $supportFile
hostname *>> $supportFile

$date *>> $supportFile
[System.TimeZone]::CurrentTimeZone *>> $supportFile

"puppet --version" *>> $supportFile
puppet --version *>> $supportFile

"hiera --version" *>> $supportFile
hiera --version *>> $supportFile

"facter --version" *>> $supportFile
facter --version *>> $supportFile

"ruby --verison" *>> $supportFile
ruby -v *>> $supportFile

"where puppet" *>> $supportFile
where.exe puppet *>> $supportFile

"where.exe ruby" *>> $supportFile
where.exe ruby *>> $supportFile

"Environment path" *>> $supportFile
$env:path *>> $supportFile

Write-Host  "Testing Puppet Connectivity"

"Testing port 8140 connection to " + $server *>> $supportFile
Test-NetConnection $server -Port 8140 *>> $supportFile

"Testing port 8142 connection to " + $server *>> $supportFile
Test-NetConnection $server -Port 8142 *>> $supportFile

"Testing port 61613 connection to " + $server *>> $supportFile
Test-NetConnection $server -Port 61613 *>> $supportFile

"Puppet, PxP-agent, mcollective service information" *>> $supportFile
Get-WmiObject -Query "SELECT * FROM win32_service where (name = 'puppet' or name = 'pxp-agent' or name = 'mcollective')" | Format-List -Property Name,Pathname, ProcessId, Startmode, State, Status, Startname *>> $supportFile

# Gathering existing logs
Get-Eventlog -source "puppet" -logname "Application" -ErrorAction SilentlyContinue | Format-List Index, Time, EntryType, Message *>> ($supportFolder + "/eventlog_application_puppet.txt")
Get-Eventlog -source "pxp-agent" -logname "Application" -ErrorAction SilentlyContinue | Format-List Index, Time, EntryType, Message *>> ($supportFolder + "/eventlog_application_pxp-agent.txt")
Get-Eventlog -source "mcollective" -logname "Application" -ErrorAction SilentlyContinue | Format-List Index, Time, EntryType, Message *>> ($supportFolder + "/eventlog_application_mcollective.txt")

# Running Puppet and Facter in debug/trace mode
puppet agent -t --debug --trace *>> ($supportFolder + "/puppet.log")
facter --debug --trace *>> ($supportFolder + "/facter.log")

 # Testing for default cahce and puppet.conf locations. If found, then add to $supportFolder and if not state non-standard install in $supportfile
if(!(Test-Path $cachedir))
{
  "Not a standard cachedir path" *>> $supportFile
}
else
{
  Copy-Item $cachedir -Recurse -Destination $supportFolder
}

if(!(Test-Path $puppetConf))
{
  "Not a standard puppet.conf path" *>> $supportFile
}
else
{
  Copy-Item $puppetConf -Destination $supportFolder
}

#Zipping $supportFolder and removing nonzipped folder
Add-Type -Assembly "System.IO.Compression.FileSystem" ;
[System.IO.Compression.ZipFile]::CreateFromDirectory($supportFolder, $zippedFolder);
Remove-Item $supportFolder -Recurse

Write-Host "Your supoprt script has completed and is located at" $zippedFolder
