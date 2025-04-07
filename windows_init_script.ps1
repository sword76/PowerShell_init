Get-NetIPInterface -AddressFamily IPv4 | Where-Object { $_.ifAlias -like "Беспроводное*" }

# Получаем интерфейсы с адресным семейством IPv4
$ipInterfaces = Get-NetIPInterface -AddressFamily IPv4

# Получаем текущую версию PowerShell
$psVesrion = host | Where-Object {$_ifAlias -eq "Version"}

# Установка последней версии PS
winget update --id Microsoft.WindowsTerminal -e --accept-source-agreements --source winget; if ($?) { winget update --id Microsoft.AppInstaller -e --source winget };
winget install --id Microsoft.PowerShell -e --source winget


# Фильтруем интерфейсы по имени и сохраняем ifIndex в переменную
$ifIndex = $ipInterfaces | Where-Object { $_.ifAlias -eq "Беспроводное сетевое соединение" } | Select-Object -ExpandProperty ifIndex

# Теперь переменная $ifIndex содержит значение ifIndex для указанного интерфейса
# Write-Output "Значение ifIndex: $ifIndex"

# Установить WSL и включить Hyper-V
wsl --install
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All

<#
Установить приложения по умолчанию
#>
winget install --id Git.Git -e --source winget;   # GitHub Desktop
if ($?) { winget install --id Microsoft.VisualStudioCode -e --source winget --scope user };
if ($?) { winget install --id Python.Python.3.13 -e --Source --source winget };
if ($?) { winget install --id Docker.DockerDesktop -e --source winget };
if ($?) { winget install --id Adobe.Acrobat.Reader.64-bit -e --source winget };
if ($?) { winget install --id qBittorrent.qBittorrent -e --source winget };
if ($?) { winget install --id Google.Chrome -e --source winget };
if ($?) { winget install --id 7zip.7zip -e --source winget };
if ($?) { winget install --id DEVCOM.JetBrainsMonoNerdFont -e --source winget };
if ($?) { winget install --id Telegram.TelegramDesktop -e --source winget --scope user };
if ($?) { winget install --id FarManager.FarManager -e --source winget };

if ($?) { winget install --id OliverSchwendener.ueli -e --source winget }; # Ueli is a cross-platform keystroke launcher
if ($?) { winget install --id 9NLXL1B6J7LW -e --source msstore --scope user }; # Install SafeInCloud
if ($?) { winget install --id IrfanSkiljan.IrfanView -e --source winget --scope user };
if ($?) { winget install --id LiteratureandLatte.Scrivener -e --source winget --scope user };
if ($?) { winget install --id calibre.calibre.portabl -e --source winget --scope user };

# if ($?) { winget install --id 9NKSQGP7F2NH -e --source msstore --scope user }; # Install WhatsApp
# if ($?) { winget install --id Mozilla.Thunderbird -e --source winget };
# if ($?) { winget install --id Obsidian.Obsidian -e --source winget --scope user };
# if ($?) { winget install --id Yandex.Browser -e --source winget --scope user };
# if ($?) { winget install --id gerardog.gsudo -e --source winget }; # sudo for Powershell
# if ($?) { winget install --id ALCPU.CoreTemp --source winget }; # Program to monitor processor temperature and other vital information
# if ($?) { winget install --id Bitwarden.Bitwarden -e --source winget --scope user };

# Вывести список всех установленных программ
winget list
