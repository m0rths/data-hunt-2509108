# =====================================================================
# config.ps1 - Configuración de Data Hunt
# Adapta estos valores a la organización del caso de tu salón.
# =====================================================================

# Organización, servicio que presta la app y departamento dueño de los datos
$Organizacion = "Kivra"
$Servicio     = "Paqueteria"
$Departamento = "Atención a cliente"

# Dirección y puerto donde escucha la app.
# "localhost" = solo tu computadora. En la Fase 11 se explica cómo publicarla en la red.
$Direccion = "localhost"
$Puerto    = 5000

# --- Campos del formulario (Fase 3) ---------------------------------
# Copia aquí los campos de docs\campos.md. Cada campo DEBE tener finalidad.
# Tipo puede ser: text, email, tel, date o number.
# El correo y la contraseña ya están incluidos; no los repitas aquí.
$Campos = @(
    @{ Nombre = "nombre";           Etiqueta = "Nombre completo";     Tipo = "text"; Finalidad = "Identificar al pasajero en su reservación" }
    @{ Nombre = "telefono";         Etiqueta = "Teléfono celular";    Tipo = "tel";  Finalidad = "Avisar cambios de puerta, retrasos o cancelaciones" }
    @{ Nombre = "fecha_nacimiento"; Etiqueta = "Fecha de nacimiento"; Tipo = "date"; Finalidad = "Verificar si el pasajero es menor de edad" }
)
# --- Aviso de privacidad y consentimiento (Fase 6) -------------------
# Cambia la versión cada vez que modifiques el aviso: así sabes qué versión aceptó cada cliente.
$AvisoVersion       = "1.0"
$ContactoPrivacidad = "privacidad@aeropuerto.test"

# Región de residencia del cliente y la ley que aplica a sus datos
$Regiones = [ordered]@{
    "México"               = "LFPDPPP"
    "Unión Europea"        = "GDPR"
    "California (EE. UU.)" = "CCPA"
    "Otro país"            = "LFPDPPP"
}