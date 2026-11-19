$ErrorActionPreference = 'Stop'
$toolsFolder = Join-Path $PSScriptRoot 'tools'
$engineName = 'Godot_v4.4.1-stable_win64'
$executables = @("${engineName}_console.exe", "${engineName}.exe")
$missing = @($executables | Where-Object { -not (Test-Path -LiteralPath (Join-Path $toolsFolder $_) -PathType Leaf) })
if ($missing.Count -eq 0) { exit 0 }

$archiveUrl = 'https://downloads.godotengine.org/?version=4.4.1&flavor=stable&slug=win64.exe.zip'
$officialSha512 = '266978B803F7532EDC69BDD5D8C4FDCED0EA97AEF1224A8879616398A2559E135520E186ADD06B532AA92BDFEECF6AC024634024DE4B3ABD69F6C34E6D6D0563'
New-Item -ItemType Directory -Path $toolsFolder -Force | Out-Null
$attemptId = [Guid]::NewGuid().ToString('N')
$download = Join-Path $toolsFolder "godot-$attemptId.zip"

try {
    Write-Host 'First launch: downloading Godot 4.4.1 from the official server (about 66 MB)...'
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing -Uri $archiveUrl -OutFile $download -TimeoutSec 180
    $checksum = [Security.Cryptography.SHA512]::Create()
    $archiveStream = [IO.File]::OpenRead($download)
    try {
        $actualSha512 = [BitConverter]::ToString($checksum.ComputeHash($archiveStream)).Replace('-', '')
    } finally {
        $archiveStream.Dispose()
        $checksum.Dispose()
    }
    if ($actualSha512 -ne $officialSha512) {
        throw 'The downloaded Godot ZIP did not match the official checksum.'
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($download)
    try {
        foreach ($name in $missing) {
            $member = $archive.GetEntry($name)
            if ($null -eq $member) { throw "The official archive is missing $name." }
            $temporaryExe = Join-Path $toolsFolder "$name.$attemptId.part"
            try {
                [IO.Compression.ZipFileExtensions]::ExtractToFile($member, $temporaryExe)
                Move-Item -LiteralPath $temporaryExe -Destination (Join-Path $toolsFolder $name) -Force
            } finally {
                if (Test-Path -LiteralPath $temporaryExe) { Remove-Item -LiteralPath $temporaryExe }
            }
        }
    } finally {
        $archive.Dispose()
    }
    Write-Host 'Godot is ready. The next launch will reuse it.'
} catch {
    Write-Host "Could not prepare Godot: $($_.Exception.Message)"
    exit 1
} finally {
    if (Test-Path -LiteralPath $download) { Remove-Item -LiteralPath $download }
}
