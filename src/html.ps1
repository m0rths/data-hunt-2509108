# =====================================================================
# src\html.ps1 - Funciones para leer peticiones y armar páginas HTML
# =====================================================================

# Convierte texto a HTML seguro (evita que un dato se interprete como código)
function Escapar([string]$texto) {
    [System.Net.WebUtility]::HtmlEncode($texto)
}

# Arma una página completa con encabezado, menú y contenido
function Nueva-Pagina([string]$titulo, [string]$contenido) {
    @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>$(Escapar $titulo) - $(Escapar $Organizacion)</title>
<style>
  body { font-family: Segoe UI, Arial, sans-serif; margin: 0; color: #1a1a1a; }
  header { background: #4b2a75; color: #fff; padding: 12px 24px; }
  header a { color: #f2c94c; margin-right: 16px; }
  main { max-width: 760px; margin: 24px auto; padding: 0 24px; }
  label { display: block; margin: 12px 0; }
  input, select { display: block; width: 100%; padding: 6px; margin-top: 4px; box-sizing: border-box; }
  input[type=checkbox] { display: inline; width: auto; }
  button { background: #4b2a75; color: #fff; border: 0; padding: 10px 18px; cursor: pointer; }
  table { border-collapse: collapse; width: 100%; font-size: 14px; }
  th, td { border: 1px solid #ccc; padding: 4px 8px; text-align: left; }
  th { background: #f3eefa; }
  .mensaje { background: #fff4d6; border-left: 4px solid #c9a227; padding: 8px 12px; }
  .aviso { background: #f3eefa; padding: 8px 16px; font-size: 14px; }
</style>
</head>
<body>
<header>
  <strong>$(Escapar $Organizacion)</strong> - $(Escapar $Servicio)<br>
  <a href="/">Inicio</a><a href="/registro">Registro</a><a href="/login">Iniciar sesión</a><a href="/aviso">Aviso de privacidad</a><a href="/admin">Administración</a>
</header>
<main>
<h1>$(Escapar $titulo)</h1>
$contenido
</main>
</body>
</html>
"@
}

# Envía una página HTML al navegador
function Enviar($ctx, [string]$html, [int]$estado = 200) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
    $respuesta = $ctx.Response
    $respuesta.StatusCode = $estado
    $respuesta.ContentType = "text/html; charset=utf-8"
    $respuesta.ContentLength64 = $bytes.Length
    $respuesta.OutputStream.Write($bytes, 0, $bytes.Length)
    $respuesta.Close()
}

# Manda al navegador a otra ruta
function Redirigir($ctx, [string]$destino) {
    $ctx.Response.Redirect($destino)
    $ctx.Response.Close()
}

# Lee los datos que el navegador envió en un formulario (POST)
function Leer-Formulario($ctx) {
    $lector = [System.IO.StreamReader]::new($ctx.Request.InputStream, [System.Text.Encoding]::UTF8)
    $cuerpo = $lector.ReadToEnd()
    $lector.Close()

    $datos = @{}
    foreach ($par in $cuerpo -split "&") {
        if ($par -eq "") { continue }
        $partes = $par -split "=", 2
        $clave  = [System.Net.WebUtility]::UrlDecode($partes[0])
        $valor  = ""
        if ($partes.Count -gt 1) { $valor = [System.Net.WebUtility]::UrlDecode($partes[1]) }
        $datos[$clave] = $valor.Trim()
    }
    return $datos
}

# Convierte una lista de registros en una tabla HTML
function Tabla-Html($filas) {
    $filas = @($filas)
    if ($filas.Count -eq 0) { return "<p><em>Sin registros.</em></p>" }

    $columnas = $filas[0].PSObject.Properties.Name
    $html = "<table><tr>"
    foreach ($c in $columnas) { $html += "<th>$(Escapar $c)</th>" }
    $html += "</tr>"
    foreach ($fila in $filas) {
        $html += "<tr>"
        foreach ($c in $columnas) { $html += "<td>$(Escapar $fila.$c)</td>" }
        $html += "</tr>"
    }
    return $html + "</table>"
}
