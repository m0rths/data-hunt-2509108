# =====================================================================
# src\rutas\inicio.ps1 - Página de inicio
# =====================================================================
$Rutas["/"] = {
    param($ctx)
    $contenido = @"
<p>Bienvenido al servicio de <strong>$(Escapar $Servicio)</strong> de $(Escapar $Organizacion).</p>
<p>Área responsable: $(Escapar $Departamento).</p>
<p><a href="/registro">Crear una cuenta</a> o <a href="/login">iniciar sesión</a>.</p>
"@
    Enviar $ctx (Nueva-Pagina "Bienvenido" $contenido)
}
