-- ======= Locales/deDE.lua =======
-- German localisation for QueueMaster
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Only load if German locale
if GetLocale() ~= "deDE" then return end

local L = QueueMaster.L
if not L then return end

-- German translations
L["QueueMaster"] = "QueueMaster"
L["Enabled"] = "Aktiviert"
L["Disabled"] = "Deaktiviert"

-- Queue states
L["Joined Queue"] = "Warteschlange beigetreten"
L["Left Queue"] = "Warteschlange verlassen"
L["Queue Ready"] = "Warteschlange bereit"
L["In Queue"] = "In Warteschlange"

-- Queue types
L["Dungeon Finder"] = "Dungeonsuche"
L["Raid Finder"] = "Schlachtzugsuche"
L["LFR"] = "SZS"
L["Scenarios"] = "Szenarien"
L["Flexible Raid"] = "Flexibler Schlachtzug"
L["PvP"] = "PvP"
L["Battleground"] = "Schlachtfeld"
L["Arena"] = "Arena"
L["Unknown Queue"] = "Unbekannte Warteschlange"

-- Roles
L["Tank"] = "Tank"
L["Healer"] = "Heiler"
L["DPS"] = "DPS"
L["Tanks"] = "Tanks"
L["Healers"] = "Heiler"

-- Time
L["Elapsed"] = "Vergangen"
L["Wait"] = "Warten"
L["Average Wait"] = "Durchschnittliche Wartezeit"
L["Estimated Wait"] = "Geschätzte Wartezeit"

-- Configuration sections
L["GENERAL"] = "ALLGEMEIN"
L["DISPLAY"] = "ANZEIGE"
L["APPEARANCE"] = "AUSSEHEN"
L["CONTROLS"] = "STEUERUNG"
L["Notifications"] = "Benachrichtigungen"
L["Advanced"] = "Erweitert"

-- Configuration options
L["Show Alert Messages"] = "Warnmeldungen anzeigen"
L["Enable Sound Notifications"] = "Tonbenachrichtigungen aktivieren"
L["Enable Screen Flash"] = "Bildschirm-Flash aktivieren"
L["Enable Debug Mode"] = "Debug-Modus aktivieren"
L["Bar Layout Mode"] = "Balkenlayout-Modus"
L["Compact Mode"] = "Kompaktmodus"
L["Lock Bar Positions"] = "Balkenpositionen sperren"
L["Group Movement Mode"] = "Gruppenbewegungsmodus"
L["Use Movable Anchor"] = "Beweglichen Anker verwenden"
L["Reset Bar Positions"] = "Balkenpositionen zurücksetzen"
L["UI Scale"] = "UI-Skalierung"
L["Bar Height"] = "Balkenhöhe"
L["Bar Width"] = "Balkenbreite"
L["Bar Spacing"] = "Balkenabstand"
L["Frame Transparency"] = "Rahmendurchsichtigkeit"
L["Edge Opacity"] = "Kantendeckkraft"
L["Font Style"] = "Schriftart"
L["Show Instance Name"] = "Instanznamen anzeigen"
L["Show Timer"] = "Timer anzeigen"
L["Show Role Composition"] = "Rollenzusammensetzung anzeigen"
L["Color Theme"] = "Farbschema"

-- Layout modes
L["Vertical"] = "Vertikal"
L["Horizontal"] = "Horizontal"
L["Text-only"] = "Nur Text"

-- Colour themes
L["Default"] = "Standard"
L["Class Colors"] = "Klassenfarben"
L["Custom"] = "Benutzerdefiniert"

-- Descriptions
L["Display popup alert messages for queue events"] = "Popup-Warnmeldungen für Warteschlangen-Ereignisse anzeigen"
L["Play sound effects for queue events"] = "Toneffekte für Warteschlangen-Ereignisse abspielen"
L["Flash the screen for important events"] = "Bildschirm bei wichtigen Ereignissen aufblitzen lassen"
L["Show debug messages in chat"] = "Debug-Nachrichten im Chat anzeigen"
L["Choose how queue timer bars are arranged"] = "Wählen Sie, wie Timer-Balken angeordnet werden"
L["Use smaller fonts for narrow bars"] = "Kleinere Schriftarten für schmale Balken verwenden"
L["Prevent bars from being moved"] = "Verschieben der Balken verhindern"
L["Move all bars together or individually"] = "Alle Balken zusammen oder einzeln verschieben"
L["Show movable anchor point"] = "Beweglichen Ankerpunkt anzeigen"
L["Reset all positions to default"] = "Alle Positionen auf Standard zurücksetzen"

-- Chat messages
L["QueueMaster is now active!"] = "QueueMaster ist jetzt aktiv!"
L["Blizzard queue UI hidden."] = "Blizzard-Warteschlangen-UI ausgeblendet."
L["QueueMaster is handling your queues."] = "QueueMaster verwaltet Ihre Warteschlangen."
L["No active queues detected."] = "Keine aktiven Warteschlangen erkannt."
L["Tip:"] = "Tipp:"
L["Open LFR/LFD and queue for something!"] = "Öffnen Sie SZS/DS und treten Sie einer Warteschlange bei!"

-- Alert messages
L["Joined:"] = "Beigetreten:"
L["Left queue:"] = "Warteschlange verlassen:"
L["Invite declined. You're still in queue."] = "Einladung abgelehnt. Sie sind noch in der Warteschlange."

-- Tooltip headers
L["Queue Information"] = "Warteschlangen-Information"
L["Role Breakdown"] = "Rollenaufteilung"
L["Click to configure"] = "Klicken zum Konfigurieren"
L["Drag to move"] = "Ziehen zum Verschieben"
