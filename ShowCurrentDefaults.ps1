Get-ChildItem "HKCU:\Software\Classes" |
    Where-Object { $_.PSChildName -like "SFTA.*" } |
    ForEach-Object {
        $command = Join-Path $_.PSPath "shell\open\command"

        if (Test-Path $command) {
            $value = Get-ItemProperty $command
            [PSCustomObject]@{
                ProgID  = $_.PSChildName
                Command = $value.'(default)'
            }
        }
    }