function Get-SystemInfo {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName
    )

    begin {
        Write-Verbose "Начинаю сбор информации о системе для $ComputerName."
    }
    process {
        try {
            # Получаем данные об операционной системе через CIM
            $sysInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop
            Write-Output $sysInfo
        }
        catch {
            Write-Error "Ошибка при получении данных с компьютера $ComputerName: $_"
        }
    }
    end {
        Write-Verbose "Сбор информации завершён для $ComputerName."
    }
}
