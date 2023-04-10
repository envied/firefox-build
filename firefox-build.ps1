#Vars
$FirefoxDL = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
$uBlockDL = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/addon-607454-latest.xpi"
$uBlockAppID = "uBlock0@raymondhill.net"
$req1 = "https://hg.mozilla.org/mozilla-central/raw-file/tip/other-licenses/7zstub/firefox/7zSD.Win32.sfx"
$req2 = "https://hg.mozilla.org/mozilla-central/raw-file/tip/browser/installer/windows/app.tag"
$workdir = "F:\Installers\FirefoxBuild"

#Use Temporary Dir
$tempDirectory = [System.IO.Path]::GetTempPath()
Set-Location $tempDirectory

#Create Build Directory
try {
    if(Test-Path $workdir) {
        Remove-Item $workdir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $workdir
    Write-Host "Directory '$workdir' deleted and recreated successfully"
} catch {
    Write-Host "An error occurred while deleting or creating the directory. Error details: $_"
}

#Set Working Directory, otherwise last step fails
Set-Location $workdir

#Download Firefox
Write-Host "Downloading Firefox..." -ForegroundColor Magenta
try {
    Start-BitsTransfer -Source $FirefoxDL -Destination $workdir\"Firefox.exe" -ErrorAction Stop
}
catch {
    Write-Host "An error occurred while downloading Firefox. Error details: $_" -ForegroundColor Red
}

#7z Firefox
Write-Host "Extracting Firefox..." -ForegroundColor Magenta
7z x "$workdir\Firefox.exe"

#Create extensions directory
$extensionsdir = New-Item -Path $workdir\core\distribution\extensions -ItemType Directory -Force

#Download ublock extension
Write-Host "Downloading uBlock to Extensions Directory"
rclone.exe copyurl $uBlockDL "$extensionsdir\$uBlockAppID.xpi" --progress --stats-one-line -q

#7z Repack
Write-Host "Repacking..." -ForegroundColor Magenta
7z a -r -t7z app.7z -mx -m0=BCJ2 -m1=LZMA:d24 -m2=LZMA:d19 -m3=LZMA:d19 -mb0:1 -mb0s1:2 -mb0s2:3

#Download requirements
Write-Host "Downloading Requirements"
rclone.exe copyurl $req1 $workdir -a --progress --stats-one-line -q
rclone.exe copyurl $req2 $workdir -a --progress --stats-one-line -q

#Final package
Write-Host "Create new install file"
cmd /c "copy /B 7zSD.Win32.sfx+app.tag+app.7z our_new_installer.exe"

#Copy the new install.exe to installations directory, which will let packer access it
Copy-Item "our_new_installer.exe" "F:\Installers\Firefox.exe" -Force