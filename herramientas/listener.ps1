# =====================================================================
# listener.ps1 - Muestra la petición HTTP cruda que envía el navegador
# Uso:  .\herramientas\listener.ps1          (escucha en el puerto 5000)
#       .\herramientas\listener.ps1 -Puerto 5001
# =====================================================================
param([int]$Puerto = 5000)

# Escucha en localhost por IPv4 (127.0.0.1) y por IPv6 (::1)
$servidores = @()
foreach ($ip in [System.Net.IPAddress]::Loopback, [System.Net.IPAddress]::IPv6Loopback) {
    try {
        $s = [System.Net.Sockets.TcpListener]::new($ip, $Puerto)
        $s.Start()
        $servidores += $s
    }
    catch { }
}
if ($servidores.Count -eq 0) {
    Write-Host "No se pudo usar el puerto $Puerto. ¿La app sigue encendida en otra ventana?" -ForegroundColor Red
    exit 1
}
Write-Host "Escuchando en http://localhost:$Puerto  (Ctrl+C para detener)" -ForegroundColor Cyan

try {
    while ($true) {
        # Espera una conexión sin bloquear Ctrl+C
        $cliente = $null
        foreach ($s in $servidores) {
            if ($s.Pending()) { $cliente = $s.AcceptTcpClient(); break }
        }
        if (-not $cliente) { Start-Sleep -Milliseconds 100; continue }
        $flujo = $cliente.GetStream()
        $flujo.ReadTimeout = 3000

        # Lee la petición completa: encabezados + cuerpo
        $memoria = [System.IO.MemoryStream]::new()
        $buffer  = [byte[]]::new(8192)
        while ($true) {
            try { $leidos = $flujo.Read($buffer, 0, $buffer.Length) } catch { break }
            if ($leidos -le 0) { break }
            $memoria.Write($buffer, 0, $leidos)
            $texto = [System.Text.Encoding]::Latin1.GetString($memoria.ToArray())
            $finEncabezados = $texto.IndexOf("`r`n`r`n")
            if ($finEncabezados -lt 0) { continue }
            $largo = 0
            if ($texto -match "(?im)^Content-Length:\s*(\d+)") { $largo = [int]$Matches[1] }
            if ($memoria.Length - ($finEncabezados + 4) -ge $largo) { break }
        }
        $peticion = [System.Text.Encoding]::UTF8.GetString($memoria.ToArray())

        # Ignora la petición del icono de la pestaña
        if ($peticion -notmatch "^GET /favicon") {
            Write-Host ""
            Write-Host "===== PETICIÓN RECIBIDA $(Get-Date -Format 'HH:mm:ss') =====" -ForegroundColor Yellow
            Write-Host $peticion
            Write-Host "================================================" -ForegroundColor Yellow
        }

        # Responde al navegador para que la página no se quede cargando
        $html = "<!DOCTYPE html><meta charset='utf-8'><p>Recibido. Revisa la ventana de PowerShell.</p>"
        $cuerpo = [System.Text.Encoding]::UTF8.GetBytes($html)
        $encabezados = "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($cuerpo.Length)`r`nConnection: close`r`n`r`n"
        $respuesta = [System.Text.Encoding]::ASCII.GetBytes($encabezados) + $cuerpo
        $flujo.Write($respuesta, 0, $respuesta.Length)
        $cliente.Close()
    }
}
finally {
    foreach ($s in $servidores) { $s.Stop() }
    Write-Host "Listener detenido."
}
