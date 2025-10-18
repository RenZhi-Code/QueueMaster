-- ======= Locales/esES.lua =======
-- Spanish localisation for QueueMaster
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Only load if Spanish locale (esES or esMX)
local locale = GetLocale()
if locale ~= "esES" and locale ~= "esMX" then return end

local L = QueueMaster.L
if not L then return end

-- Spanish translations
L["QueueMaster"] = "QueueMaster"
L["Enabled"] = "Activado"
L["Disabled"] = "Desactivado"

-- Queue states
L["Joined Queue"] = "Cola unida"
L["Left Queue"] = "Cola abandonada"
L["Queue Ready"] = "Cola lista"
L["In Queue"] = "En cola"

-- Queue types
L["Dungeon Finder"] = "Buscador de mazmorras"
L["Raid Finder"] = "Buscador de bandas"
L["LFR"] = "BdB"
L["Scenarios"] = "Escenarios"
L["Flexible Raid"] = "Banda flexible"
L["PvP"] = "JcJ"
L["Battleground"] = "Campo de batalla"
L["Arena"] = "Arena"
L["Unknown Queue"] = "Cola desconocida"

-- Roles
L["Tank"] = "Tanque"
L["Healer"] = "Sanador"
L["DPS"] = "DPS"
L["Tanks"] = "Tanques"
L["Healers"] = "Sanadores"

-- Time
L["Elapsed"] = "Transcurrido"
L["Wait"] = "Espera"
L["Average Wait"] = "Espera promedio"
L["Estimated Wait"] = "Espera estimada"

-- Configuration sections
L["GENERAL"] = "GENERAL"
L["DISPLAY"] = "VISUALIZACIÓN"
L["APPEARANCE"] = "APARIENCIA"
L["CONTROLS"] = "CONTROLES"
L["Notifications"] = "Notificaciones"
L["Advanced"] = "Avanzado"

-- Configuration options
L["Show Alert Messages"] = "Mostrar mensajes de alerta"
L["Enable Sound Notifications"] = "Activar notificaciones de sonido"
L["Enable Screen Flash"] = "Activar destello de pantalla"
L["Enable Debug Mode"] = "Activar modo de depuración"
L["Bar Layout Mode"] = "Modo de diseño de barras"
L["Compact Mode"] = "Modo compacto"
L["Lock Bar Positions"] = "Bloquear posiciones de barras"
L["Group Movement Mode"] = "Modo de movimiento grupal"
L["Use Movable Anchor"] = "Usar ancla móvil"
L["Reset Bar Positions"] = "Restablecer posiciones de barras"
L["UI Scale"] = "Escala de interfaz"
L["Bar Height"] = "Altura de barra"
L["Bar Width"] = "Ancho de barra"
L["Bar Spacing"] = "Espaciado de barras"
L["Frame Transparency"] = "Transparencia del marco"
L["Edge Opacity"] = "Opacidad de bordes"
L["Font Style"] = "Estilo de fuente"
L["Show Instance Name"] = "Mostrar nombre de instancia"
L["Show Timer"] = "Mostrar temporizador"
L["Show Role Composition"] = "Mostrar composición de roles"
L["Color Theme"] = "Tema de color"

-- Layout modes
L["Vertical"] = "Vertical"
L["Horizontal"] = "Horizontal"
L["Text-only"] = "Solo texto"

-- Colour themes
L["Default"] = "Predeterminado"
L["Class Colors"] = "Colores de clase"
L["Custom"] = "Personalizado"

-- Descriptions
L["Display popup alert messages for queue events"] = "Mostrar mensajes de alerta emergentes para eventos de cola"
L["Play sound effects for queue events"] = "Reproducir efectos de sonido para eventos de cola"
L["Flash the screen for important events"] = "Hacer parpadear la pantalla para eventos importantes"
L["Show debug messages in chat"] = "Mostrar mensajes de depuración en el chat"
L["Choose how queue timer bars are arranged"] = "Elegir cómo se organizan las barras de temporizador"
L["Use smaller fonts for narrow bars"] = "Usar fuentes más pequeñas para barras estrechas"
L["Prevent bars from being moved"] = "Evitar que las barras se muevan"
L["Move all bars together or individually"] = "Mover todas las barras juntas o individualmente"
L["Show movable anchor point"] = "Mostrar punto de anclaje móvil"
L["Reset all positions to default"] = "Restablecer todas las posiciones a predeterminadas"

-- Chat messages
L["QueueMaster is now active!"] = "¡QueueMaster está ahora activo!"
L["Blizzard queue UI hidden."] = "Interfaz de cola de Blizzard oculta."
L["QueueMaster is handling your queues."] = "QueueMaster está gestionando tus colas."
L["No active queues detected."] = "No se detectaron colas activas."
L["Tip:"] = "Consejo:"
L["Open LFR/LFD and queue for something!"] = "¡Abre BdB/BdM y únete a una cola!"

-- Alert messages
L["Joined:"] = "Unido:"
L["Left queue:"] = "Cola abandonada:"
L["Invite declined. You're still in queue."] = "Invitación rechazada. Todavía estás en cola."

-- Tooltip headers
L["Queue Information"] = "Información de cola"
L["Role Breakdown"] = "Desglose de roles"
L["Click to configure"] = "Clic para configurar"
L["Drag to move"] = "Arrastra para mover"
