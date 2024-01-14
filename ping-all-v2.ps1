# Liste der IP-Adressen
$ipList = @("192.168.1.10", "192.168.1.11", "192.168.1.12", "192.168.1.13", "192.168.1.101", "192.168.1.102", "192.168.1.103", "192.168.1.104", "192.168.1.105", "192.168.1.111", "192.168.1.121", "192.168.1.131", "192.168.1.141", "192.168.1.151")

# Ping-Statistiken
$pingStats = @{}

# Initialisiere Statistiken für jede IP
foreach ($ip in $ipList) {
    $pingStats[$ip] = @{
        TotalPings = 0
        Successes  = 0
        Failures   = 0
    }
}

# Dashboard-Layout initialisieren
function Initialize-Dashboard {
    Clear-Host
    $index = 0
    foreach ($ip in $ipList) {
        Write-Host "$ip - Gesendet: 0, Erfolge: 0, Misserfolge: 0, Erfolgsrate: 0%"
        $index++
    }
}

# Funktion zum Aktualisieren der Konsole
function Update-Console {
    $index = 0
    foreach ($ip in $ipList) {
        $stats = $pingStats[$ip]
        $successRate = if ($stats.TotalPings -gt 0) { ($stats.Successes / $stats.TotalPings) * 100 } else { 0 }

        # Update the line for the current IP
        $CursorTop = $index
        $CursorLeft = 0
        [Console]::SetCursorPosition($CursorLeft, $CursorTop)
        Write-Host "$ip - Gesendet: $($stats.TotalPings), Erfolge: $($stats.Successes), Misserfolge: $($stats.Failures), Erfolgsrate: $($successRate)%     " -NoNewline

        $index++
    }
}

Initialize-Dashboard

# Ping-Schleife
while ($true) {
    foreach ($ip in $ipList) {
        $result = Test-Connection -ComputerName $ip -Count 1 -ErrorAction SilentlyContinue
        $pingStats[$ip].TotalPings++
        if ($result) {
            $pingStats[$ip].Successes++
        } else {
            $pingStats[$ip].Failures++
        }

        Update-Console
        Start-Sleep -Milliseconds 500
    }
}
