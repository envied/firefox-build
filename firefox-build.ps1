#Vars
$FirefoxDL = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
$uBlockDL = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/addon-607454-latest.xpi"
$uBlockAppID = "uBlock0@raymondhill.net"
$req1 = "https://hg.mozilla.org/mozilla-central/raw-file/tip/other-licenses/7zstub/firefox/7zSD.Win32.sfx"
$req2 = "https://hg.mozilla.org/mozilla-central/raw-file/tip/browser/installer/windows/app.tag"

#Use Temporary Dir
$baseFolder = [System.IO.Path]::GetTempPath()
$subfolderName = "firefox-build"

$subfolderPath = [System.IO.Path]::Combine($baseFolder, $subfolderName)

if (Test-Path $subfolderPath) {
    Remove-Item $subfolderPath -Recurse -Force
}

New-Item -ItemType Directory -Path $subfolderPath -Force | Out-Null

$tempDirectory = $subfolderPath
Set-Location $tempDirectory


#Download Firefox
Write-Host "Downloading Firefox..." -ForegroundColor Magenta
try {
    Start-BitsTransfer -Source $FirefoxDL -Destination $tempDirectory\"Firefox.exe" -ErrorAction Stop
}
catch {
    Write-Host "An error occurred while downloading Firefox. Error details: $_" -ForegroundColor Red
}

#7z Firefox
Write-Host "Extracting Firefox..." -ForegroundColor Magenta
7z x "$tempDirectory\Firefox.exe"

#Create extensions directory
$extensionsdir = New-Item -Path $tempDirectory\core\distribution\extensions -ItemType Directory -Force

#Download ublock extension
Write-Host "Downloading uBlock to Extensions Directory"
rclone.exe copyurl $uBlockDL "$extensionsdir\$uBlockAppID.xpi" --progress --stats-one-line -q

#7z Repack
Write-Host "Repacking..." -ForegroundColor Magenta
7z a -r -t7z app.7z -mx -m0=BCJ2 -m1=LZMA:d24 -m2=LZMA:d19 -m3=LZMA:d19 -mb0:1 -mb0s1:2 -mb0s2:3

#Download requirements
Write-Host "Downloading Requirements"
rclone.exe copyurl $req1 $tempDirectory -a --progress --stats-one-line -q
rclone.exe copyurl $req2 $tempDirectory -a --progress --stats-one-line -q

#Final package
Write-Host "Create new install file"
cmd /c "copy /B 7zSD.Win32.sfx+app.tag+app.7z our_new_installer.exe"