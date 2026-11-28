# =====================================================================
# src\rutas\login.ps1 - Inicio de sesión y bitácora de accesos
# FASE 8: sesiones y cuentas de empleados con rol
# =====================================================================

function Formulario-Login([string]$mensaje = "") {
    $html = ""
    if ($mensaje) { $html += "<p class='mensaje'>$(Escapar $mensaje)</p>" }
    $html += "<form method='post' action='/login'>"
    $html += "<label>Correo electrónico <input type='email' name='email' required></label>"
    $html += "<label>Contraseña <input type='password' name='password' required></label>"
    $html += "<button>Entrar</button></form>"
    return $html
}

# Guarda un evento en la bitácora de accesos (access_log.csv)
function Registrar-Acceso($ctx, [string]$email, [string]$evento, [bool]$exito) {
    Agregar-Csv $ArchivoAccesos ([ordered]@{
        fecha     = Ahora
        email     = $email
        evento    = $evento
        exito     = [int]$exito
        ip        = $ctx.Request.RemoteEndPoint.Address.ToString()
        navegador = $ctx.Request.UserAgent
    })
}

$Rutas["/login"] = {
    param($ctx)

    if ($ctx.Request.HttpMethod -ne "POST") {
        Enviar $ctx (Nueva-Pagina "Iniciar sesión" (Formulario-Login))
        return
    }

    $form = Leer-Formulario $ctx
    Write-Host "  Intento de inicio de sesión"

    # Busca primero entre los empleados y después entre los clientes
    $cuenta = Leer-Csv $ArchivoEmpleados | Where-Object { $_.email -eq $form["email"] } | Select-Object -First 1
    $rol = $null
    if ($cuenta) { $rol = $cuenta.rol }
    else {
        $cuenta = Leer-Csv $ArchivoUsuarios | Where-Object { $_.email -eq $form["email"] } | Select-Object -First 1
        if ($cuenta) { $rol = "cliente" }
    }

    $correcto = $false
    if ($cuenta) { $correcto = Probar-Contrasena $form["password"] $cuenta.password_hash }

    Registrar-Acceso $ctx $form["email"] "login" $correcto

    if (-not $correcto) {
        Enviar $ctx (Nueva-Pagina "Iniciar sesión" (Formulario-Login "Correo o contraseña incorrectos."))
        return
    }

    Nueva-Sesion $ctx $cuenta.email $rol
    if ($rol -in $RolesAdmin) {
        Redirigir $ctx "/admin"
    }
    else {
        Enviar $ctx (Nueva-Pagina "Bienvenido" "<p>Iniciaste sesión como $(Escapar $cuenta.email).</p><p><a href='/salir'>Cerrar sesión</a></p>")
    }
}