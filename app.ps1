# =====================================================================
# app.ps1 - Servidor web de Data Hunt
# Uso:  .\app.ps1        (Ctrl+C para detener)
# Este archivo no se vuelve a modificar: cada fase agrega archivos en src\
# =====================================================================
$ErrorActionPreference = "Stop"
$Raiz = $PSScriptRoot

# 1. Carga la configuración
. (Join-Path $Raiz "config.ps1")

# 2. Carga las funciones de apoyo (src\*.ps1)
foreach ($archivo in Get-ChildItem (Join-Path $Raiz "src") -Filter *.ps1) {
    . $archivo.FullName
}

# 3. Carga las rutas (src\rutas\*.ps1). Cada archivo agrega sus rutas a $Rutas.
$Rutas = @{}
foreach ($archivo in Get-ChildItem (Join-Path $Raiz "src/rutas") -Filter *.ps1) {
    . $archivo.FullName
}

# 4. Inicia el servidor web
# HALLAZGO H-04: la app se sirve por HTTP; los datos viajan sin cifrar por la red
$servidor = [System.Net.HttpListener]::new()
$servidor.Prefixes.Add("http://$($Direccion):$Puerto/")
$servidor.Start()

Write-Host ""
Write-Host "$Organizacion - $Servicio" -ForegroundColor Cyan
Write-Host "La app está en http://localhost:$Puerto  (Ctrl+C para detener)" -ForegroundColor Cyan
Write-Host "Rutas cargadas: $(($Rutas.Keys | Sort-Object) -join '  ')"

try {
    while ($servidor.IsListening) {
        # Espera una petición sin bloquear Ctrl+C
        $tarea = $servidor.GetContextAsync()
        while (-not $tarea.Wait(300)) { }
        $ctx  = $tarea.Result
        $ruta = $ctx.Request.Url.AbsolutePath
        Write-Host "$(Get-Date -Format 'HH:mm:ss')  $($ctx.Request.HttpMethod) $ruta"

        try {
            if ($Rutas.ContainsKey($ruta)) {
                & $Rutas[$ruta] $ctx
            }
            else {
                Enviar $ctx (Nueva-Pagina "Página no encontrada" "<p>La ruta <code>$(Escapar $ruta)</code> no existe.</p>") 404
            }
        }
        catch {
            Write-Host "[ERROR] $_" -ForegroundColor Red
            try { Enviar $ctx (Nueva-Pagina "Error" "<p>Ocurrió un error. Revisa la ventana de PowerShell.</p>") 500 } catch { }
        }
    }
}
finally {
    $servidor.Stop()
    Write-Host "Servidor detenido."
}