# =====================================================================
# src\rutas\admin.ps1 - Página de administración
# VERSIÓN LÍNEA BASE: contiene fallas intencionales marcadas como HALLAZGO
# =====================================================================

$Rutas["/admin"] = {
    param($ctx)

    # HALLAZGO H-02: no pide autenticación; cualquiera ve todos los datos
    $usuarios = @(Leer-Csv $ArchivoUsuarios)
    $accesos  = @(Leer-Csv $ArchivoAccesos)
    [array]::Reverse($accesos)   # los más recientes primero

    $contenido  = "<h2>Clientes ($($usuarios.Count))</h2>" + (Tabla-Html $usuarios)
    $contenido += "<h2>Bitácora de accesos</h2>" + (Tabla-Html $accesos)
    Enviar $ctx (Nueva-Pagina "Administración" $contenido)
}
