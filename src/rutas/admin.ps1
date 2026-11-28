# =====================================================================
# src\rutas\admin.ps1 - Página de administración
# FASE 8: autenticación, control de acceso por rol y enmascaramiento
# =====================================================================

$Rutas["/admin"] = {
    param($ctx)

    # CORREGIDO H-02: hay que iniciar sesión...
    $sesion = Obtener-Sesion $ctx
    if (-not $sesion) {
        Redirigir $ctx "/login"
        return
    }
    # ...y tener un rol autorizado
    if ($sesion.rol -notin $RolesAdmin) {
        Registrar-Acceso $ctx $sesion.email "admin" $false
        Enviar $ctx (Nueva-Pagina "Acceso denegado" "<p>Tu cuenta no tiene permiso para ver esta página.</p>") 403
        return
    }

    # Bitácora: queda registrado quién consultó los datos de los clientes
    Registrar-Acceso $ctx $sesion.email "admin" $true

    # Datos en procesamiento: solo lo indispensable, enmascarado y sin el hash
    $usuarios = @(Leer-Csv $ArchivoUsuarios | ForEach-Object {
        $u = $_
        $fila = [ordered]@{ correo = Enmascarar-Correo $u.email }
        foreach ($campo in $Campos) {
            $fila[$campo.Nombre] = Enmascarar-Texto $u.($campo.Nombre)
        }
        $fila["region"]         = $u.region
        $fila["ley_aplicable"]  = $u.ley_aplicable
        $fila["aviso_version"]  = $u.aviso_version
        $fila["fecha_registro"] = $u.fecha_registro
        [PSCustomObject]$fila
    })

    $todos = @(Leer-Csv $ArchivoAccesos)
    $accesos = @($todos | Select-Object -Last 50 | ForEach-Object {
        [PSCustomObject][ordered]@{
            fecha  = $_.fecha
            correo = Enmascarar-Correo $_.email
            evento = $_.evento
            exito  = $_.exito
            ip     = Enmascarar-Ip $_.ip
        }
    })
    [array]::Reverse($accesos)   # los más recientes primero

    # Indicador de riesgo (KRI): inicios de sesión fallidos en las últimas 24 horas
    $limite   = (Get-Date).AddHours(-24)
    $fallidos = @($todos | Where-Object { $_.evento -eq "login" -and $_.exito -eq "0" -and [datetime]$_.fecha -gt $limite }).Count

    $contenido  = "<p>Sesión: $(Escapar (Enmascarar-Correo $sesion.email)) ($(Escapar $sesion.rol)) · <a href='/salir'>Cerrar sesión</a></p>"
    $contenido += "<p class='mensaje'>Inicios de sesión fallidos en las últimas 24 h: <strong>$fallidos</strong></p>"
    $contenido += "<h2>Clientes ($($usuarios.Count))</h2>" + (Tabla-Html $usuarios)
    $contenido += "<h2>Bitácora de accesos (últimos 50)</h2>" + (Tabla-Html $accesos)
    Enviar $ctx (Nueva-Pagina "Administración" $contenido)
}