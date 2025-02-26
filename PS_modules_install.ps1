<#
PowerShell
PowerShell, установка модулей
#>


Install-Module -Name posh-git -Scope CurrentUser; # для работы с Git
if ($?) { Install-Module -Name z -Scope CurrentUser }; # Для быстрого перемещения по папкам
if ($?) { Install-Module -Name PSReadLine -Scope CurrentUser }; # Настройка промпта PowerShell
if ($?) { Install-Module -Name Terminal-Icons -Scope CurrentUser }; # Отображения иконок в темирнале с помощью Nerd Font (в моем случает JeBrainsMonoNerdFont)
