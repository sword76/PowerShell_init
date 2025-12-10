# ===========================================
# Скрипт настройки Windows и установки ПО
# Версия: 2.0, by Chirva S.
# ===========================================

#region Инициализация и проверки

# Проверка прав администратора
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ОШИБКА: Скрипт требует запуска от имени администратора!" -ForegroundColor Red
    Write-Host "Запустите PowerShell от имени администратора и попробуйте снова." -ForegroundColor Yellow
    exit 1
}

# Начать логирование
$logPath = "$env:TEMP\Windows_Setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logPath -Append
Write-Host "Начало выполнения скрипта. Логирование в: $logPath" -ForegroundColor Green

# Получение информации о системе
Write-Host "`n=== ИНФОРМАЦИЯ О СИСТЕМЕ ===" -ForegroundColor Cyan
$systemInfo = @{
    "Дата" = Get-Date
    "Пользователь" = $env:USERNAME
    "Компьютер" = $env:COMPUTERNAME
    "Версия PowerShell" = $PSVersionTable.PSVersion
    "ОС" = (Get-CimInstance Win32_OperatingSystem).Caption
}
$systemInfo.GetEnumerator() | ForEach-Object { 
    Write-Host ("{0}: {1}" -f $_.Key, $_.Value) 
}

# Проверка наличия winget
Write-Host "`n=== ПРОВЕРКА WINGET ===" -ForegroundColor Cyan
try {
    $wingetPath = Get-Command winget -ErrorAction Stop
    Write-Host "Winget найден: $($wingetPath.Source)" -ForegroundColor Green
}
catch {
    Write-Host "Winget не найден. Установите App Installer из Microsoft Store." -ForegroundColor Red
    Write-Host "Ссылка: https://aka.ms/getwinget" -ForegroundColor Yellow
    Stop-Transcript
    exit 1
}

#endregion

#region Функции

function Test-CommandSuccess {
    param([bool]$Success)
    return $Success
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$PackageName,
        [string]$Source = "winget",
        [string]$Scope = "machine"
    )
    
    Write-Host "Установка: $PackageName" -ForegroundColor Yellow
    try {
        $arguments = @(
            "install",
            "--id", $PackageId,
            "--source", $Source,
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--silent"
        )
        
        if ($Scope -ne "machine") {
            $arguments += "--scope"
            $arguments += $Scope
        }
        
        winget @arguments
        Write-Host "  ✓ $PackageName успешно установлен" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  ✗ Ошибка при установке $PackageName : $_" -ForegroundColor Red
        return $false
    }
}

function Get-NetworkInterfaceInfo {
    Write-Host "`n=== СЕТЕВЫЕ ИНТЕРФЕЙСЫ ===" -ForegroundColor Cyan
    $interfaces = Get-NetIPInterface -AddressFamily IPv4 | Where-Object {$_.ConnectionState -eq "Connected"}
    
    if (-not $interfaces) {
        Write-Host "Не найдено активных интерфейсов IPv4" -ForegroundColor Yellow
        return
    }
    
    foreach ($interface in $interfaces) {
        $ipAddress = Get-NetIPAddress -InterfaceIndex $interface.ifIndex -AddressFamily IPv4 | Select-Object -First 1
        Write-Host ("Интерфейс: {0} (ifIndex: {1})" -f $interface.InterfaceAlias, $interface.ifIndex)
        if ($ipAddress) {
            Write-Host ("  IP адрес: {0}" -f $ipAddress.IPAddress)
        }
    }
    
    # Поиск беспроводного интерфейса
    $wirelessInterface = $interfaces | Where-Object { 
        $_.InterfaceAlias -match "Wi-Fi|Беспроводное|Wireless" 
    } | Select-Object -First 1
    
    if ($wirelessInterface) {
        Write-Host "`nОбнаружен беспроводной интерфейс:" -ForegroundColor Green
        Write-Host ("  Имя: {0}, ifIndex: {1}" -f $wirelessInterface.InterfaceAlias, $wirelessInterface.ifIndex)
        return $wirelessInterface.ifIndex
    }
    else {
        Write-Host "Беспроводной интерфейс не найден" -ForegroundColor Yellow
        return $null
    }
}

#endregion

#region Основная настройка системы

Write-Host "`n=== НАСТРОЙКА СИСТЕМЫ ===" -ForegroundColor Cyan

# Получение информации о сетевых интерфейсах
$wirelessIfIndex = Get-NetworkInterfaceInfo

# Обновление терминала Windows и установщика приложений
Write-Host "`nОбновление системных компонентов..." -ForegroundColor Yellow
try {
    winget upgrade --id Microsoft.WindowsTerminal --silent --accept-package-agreements --accept-source-agreements
    Write-Host "  ✓ Windows Terminal обновлен" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Не удалось обновить Windows Terminal" -ForegroundColor Red
}

try {
    winget upgrade --id Microsoft.AppInstaller --silent --accept-package-agreements --accept-source-agreements
    Write-Host "  ✓ App Installer обновлен" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Не удалось обновить App Installer" -ForegroundColor Red
}

# Установка/обновление PowerShell через winget
Write-Host "`nУстановка последней версии PowerShell..." -ForegroundColor Yellow
Install-WingetPackage -PackageId "Microsoft.PowerShell" -PackageName "PowerShell" -Scope "machine"

# Установка WSL и включение Hyper-V
Write-Host "`nНастройка WSL и Hyper-V..." -ForegroundColor Yellow
try {
    wsl --install --no-distribution
    Write-Host "  ✓ WSL установлен" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Ошибка при установке WSL: $_" -ForegroundColor Red
}

try {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
    Write-Host "  ✓ Hyper-V включен" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Ошибка при включении Hyper-V: $_" -ForegroundColor Red
}

#endregion

#region Установка приложений

Write-Host "`n=== УСТАНОВКА ПРИЛОЖЕНИЙ ===" -ForegroundColor Cyan

# Группы приложений
$appGroups = @{
    "Инструменты разработки" = @(
        @{Id = "Git.Git"; Name = "Git"},
        @{Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code"},
        @{Id = "Python.Python.3.13"; Name = "Python 3.13"},
        @{Id = "Python.Python.3.14"; Name = "Python 3.13"},
        @{Id = "DBeaver.DBeaver.Community"; Name = "DBeaver Community"},
        @{Id = "Docker.DockerDesktop"; Name = "Docker Desktop"},
        @{Id = "PuTTY.PuTTY"; Name = "Putty"}
    )
    
    "Системные утилиты" = @(
        @{Id = "7zip.7zip"; Name = "7-Zip"},
        @{Id = "Insecure.Nmap"; Name = "Nmap"},
        @{Id = "gerardog.gsudo"; Name = "gsudo"}
    )
    
    "Рабочие инструменты" = @(
        @{Id = "Adobe.Acrobat.Reader.64-bit"; Name = "Adobe Acrobat Reader"},
        @{Id = "DEVCOM.JetBrainsMonoNerdFont"; Name = "JetBrains Mono Nerd Font"},
        @{Id = "FarManager.FarManager"; Name = "Far Manager"},
        @{Id = "OliverSchwendener.ueli"; Name = "Ueli"}
    )
    
    "Мультимедиа и коммуникации" = @(
        @{Id = "qBittorrent.qBittorrent"; Name = "qBittorrent"},
        @{Id = "Telegram.TelegramDesktop"; Name = "Telegram Desktop"; Scope = "user"},
        @{Id = "Google.Chrome"; Name = "Google Chrome"},
        @{Id = "IrfanSkiljan.IrfanView"; Name = "IrfanView"; Scope = "user"}
    )
    
    "Дополнительные приложения" = @(
        @{Id = "9NLXL1B6J7LW"; Name = "SafeInCloud"; Source = "msstore"; Scope = "user"},
        @{Id = "LiteratureandLatte.Scrivener"; Name = "Scrivener"; Scope = "user"},
        @{Id = "calibre.calibre"; Name = "Calibre"; Scope = "user"}
    )
}

# Установка приложений по группам
foreach ($group in $appGroups.Keys) {
    Write-Host "`n--- $group ---" -ForegroundColor Magenta
    
    foreach ($app in $appGroups[$group]) {
        $params = @{
            PackageId = $app.Id
            PackageName = $app.Name
        }
        
        if ($app.Source) { $params.Source = $app.Source }
        if ($app.Scope) { $params.Scope = $app.Scope }
        
        Install-WingetPackage @params
    }
}

# Список приложений для ручной установки (раскомментируйте при необходимости)
<#
$manualApps = @(
    @{Id = "Microsoft.VisioViewer"; Name = "Visio Viewer"},
    @{Id = "Project64.Project64"; Name = "Project64"},
    @{Id = "SoftDeluxe.FreeDownloadManager"; Name = "Free Download Manager"; Scope = "user"},
    @{Id = "9NKSQGP7F2NH"; Name = "WhatsApp"; Source = "msstore"; Scope = "user"},
    @{Id = "Mozilla.Thunderbird"; Name = "Thunderbird"},
    @{Id = "Obsidian.Obsidian"; Name = "Obsidian"; Scope = "user"},
    @{Id = "Yandex.Browser"; Name = "Yandex Browser"; Scope = "user"},
    @{Id = "ALCPU.CoreTemp"; Name = "Core Temp"},
    @{Id = "Bitwarden.Bitwarden"; Name = "Bitwarden"; Scope = "user"}
)

Write-Host "`n--- Дополнительные приложения (раскомментировать) ---" -ForegroundColor DarkGray
#>

#endregion

#region Завершение работы

Write-Host "`n=== ЗАВЕРШЕНИЕ ===" -ForegroundColor Cyan

# Вывод списка установленных программ
Write-Host "`nСписок установленных программ:" -ForegroundColor Yellow
try {
    winget list --source winget | Select-String -Pattern "^[a-zA-Z]" | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}
catch {
    Write-Host "Не удалось получить список программ" -ForegroundColor Red
}

# Проверка необходимости перезагрузки
$rebootRequired = $false
$pendingFeatures = Get-WindowsOptionalFeature -Online | Where-Object {$_.State -eq "EnablePending"}

if ($pendingFeatures) {
    Write-Host "`nОбнаружены компоненты, требующие перезагрузки:" -ForegroundColor Yellow
    $pendingFeatures | ForEach-Object {
        Write-Host ("  - {0}" -f $_.FeatureName)
    }
    $rebootRequired = $true
}

# Итоги
Write-Host "`n=== ИТОГИ ===" -ForegroundColor Green
Write-Host "Скрипт выполнен успешно!" -ForegroundColor Green
Write-Host "Лог сохранен в: $logPath" -ForegroundColor Gray

if ($rebootRequired) {
    Write-Host "`nТРЕБУЕТСЯ ПЕРЕЗАГРУЗКА для завершения установки компонентов!" -ForegroundColor Red -BackgroundColor Black
    $answer = Read-Host "Перезагрузить сейчас? (Y/N)"
    if ($answer -eq 'Y' -or $answer -eq 'y') {
        Write-Host "Перезагрузка через 10 секунд..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
}
else {
    Write-Host "Перезагрузка не требуется." -ForegroundColor Green
}

# Остановка логирования
Stop-Transcript

# Информация о дальнейших действиях
Write-Host "`nРекомендуемые действия после установки:" -ForegroundColor Cyan
Write-Host "1. Настройте WSL (wsl --install -d Ubuntu)" -ForegroundColor Gray
Write-Host "2. Настройте Docker Desktop" -ForegroundColor Gray
Write-Host "3. Обновите драйверы через Windows Update" -ForegroundColor Gray
Write-Host "4. Настройте среду разработки (VS Code расширения и т.д.)" -ForegroundColor Gray

# Пауза перед закрытием
if ($Host.Name -eq "ConsoleHost") {
    Write-Host "`nНажмите любую клавишу для выхода..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

#endregion
