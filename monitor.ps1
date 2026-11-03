# Monitor de conexion a internet. Lo lanza iniciar.bat y lo frena detener.bat.
# Registra en internet_log.txt solo los cambios de estado (cortes y vueltas).

$Targets           = '1.1.1.1', '8.8.8.8', '9.9.9.9'  # hay corte solo si fallan TODOS
$IntervalSeconds   = 5     # cada cuanto se comprueba
$TimeoutMs         = 2000  # espera maxima por cada ping
$FailuresToConfirm = 2     # comprobaciones fallidas seguidas para contar como corte
$GapSeconds        = 60    # un hueco mayor entre comprobaciones indica PC suspendida

$logFile  = Join-Path $PSScriptRoot 'internet_log.txt'
$lockFile = Join-Path $PSScriptRoot 'monitor.lock'
$stopFile = Join-Path $PSScriptRoot 'monitor.stop'

# El lock se libera solo si el proceso muere, asi nunca queda "trabado".
try {
    $lock = [IO.File]::Open($lockFile, 'OpenOrCreate', 'ReadWrite', 'None')
} catch {
    exit 1  # ya hay otro monitor corriendo
}

function Write-Log($when, $kind, $message) {
    $line = '{0}  {1,-7}  {2}' -f $when.ToString('yyyy-MM-dd HH:mm:ss'), $kind, $message
    Add-Content -Path $logFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
}

function Format-Duration($from, $to) {
    $d = $to - $from
    '{0:00}:{1:00}:{2:00}' -f [math]::Floor($d.TotalHours), $d.Minutes, $d.Seconds
}

$ping = New-Object System.Net.NetworkInformation.Ping

function Test-Internet {
    foreach ($target in $Targets) {
        try {
            if ($ping.Send($target, $TimeoutMs).Status -eq 'Success') { return $true }
        } catch { }
    }
    return $false
}

$online = Test-Internet
$outageStart = $null
$failures = 0
$firstFailure = $null

if ($online) {
    Write-Log (Get-Date) 'INICIO' 'Monitor iniciado - internet OK'
} else {
    $outageStart = Get-Date
    Write-Log $outageStart 'INICIO' 'Monitor iniciado - SIN internet'
}

$lastCheck = Get-Date

try {
    while ($true) {
        for ($i = 0; $i -lt $IntervalSeconds -and -not (Test-Path $stopFile); $i++) {
            Start-Sleep -Seconds 1
        }
        if (Test-Path $stopFile) { break }

        $now = Get-Date
        if (($now - $lastCheck).TotalSeconds -gt $GapSeconds) {
            Write-Log $now 'AVISO' ('Sin mediciones desde {0} (PC suspendida?)' -f $lastCheck.ToString('yyyy-MM-dd HH:mm:ss'))
        }
        $lastCheck = $now

        $up = Test-Internet
        $checkedAt = Get-Date

        if ($up) {
            $failures = 0
            if (-not $online) {
                Write-Log $checkedAt 'VOLVIO' ('Volvio internet (duracion del corte: {0})' -f (Format-Duration $outageStart $checkedAt))
                $online = $true
            }
        } elseif ($online) {
            $failures++
            if ($failures -eq 1) { $firstFailure = $checkedAt }
            if ($failures -ge $FailuresToConfirm) {
                Write-Log $firstFailure 'CORTE' 'Se corto internet'
                $online = $false
                $outageStart = $firstFailure
                $failures = 0
            }
        }
    }
} finally {
    $now = Get-Date
    if ($online) {
        Write-Log $now 'FIN' 'Monitor detenido - internet OK'
    } else {
        Write-Log $now 'FIN' ('Monitor detenido - internet seguia cortado (hace {0})' -f (Format-Duration $outageStart $now))
    }
    Remove-Item $stopFile -ErrorAction SilentlyContinue
    $lock.Dispose()
}
